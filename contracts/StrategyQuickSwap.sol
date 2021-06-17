// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IStakingRewards.sol";
import "./interfaces/IUniPair.sol";
import "./interfaces/IUniRouter02.sol";

contract StrategyQuickSwap is Ownable {

	using SafeMath for uint;
	using SafeERC20 for IERC20;

	// Addresses
	address public router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
	address public token0;
	address public token1;
	address public pair;
	address public stakingRewardsContract;
	address public rewardsToken;

	// Paths
	address[] public rewardToToken0Path;
	address[] public rewardToToken1Path;
	address[] public token0ToRewardPath;
	address[] public token1ToRewardPath;

	// Configs
	uint public slippageFactor = 950; // 5% default slippage tolerance

	constructor(
		address _stakingRewardsContract,
		address[] memory _rewardToToken0Path,
		address[] memory _rewardToToken1Path,
		address[] memory _token0ToRewardPath,
		address[] memory _token1ToRewardPath
	) {
		stakingRewardsContract = _stakingRewardsContract;

		pair = IStakingRewards(stakingRewardsContract).stakingToken();
		token0 = IUniPair(pair).token0();
		token1 = IUniPair(pair).token1();

		rewardsToken = IStakingRewards(stakingRewardsContract).rewardsToken();

		rewardToToken0Path = _rewardToToken0Path;
		rewardToToken1Path = _rewardToToken1Path;
		token0ToRewardPath = _token0ToRewardPath;
		token1ToRewardPath = _token1ToRewardPath;
	}

	// External Functions

	function deposit(uint _amount) external onlyOwner {
		IERC20(pair).safeTransferFrom(msg.sender, address(this), _amount);

		_startFarm();
	}

	function compound() external onlyOwner {
		// Harvest reward tokens
        IStakingRewards(stakingRewardsContract).getReward();

        uint rewardAmount = IERC20(rewardsToken).balanceOf(address(this));

        if (rewardAmount > 0) {
        	if (rewardsToken != token0) {
                // Swap half earned to token0
                _safeSwap(
                    rewardAmount.div(2),
                    rewardToToken0Path,
                    address(this)
                );
            }
    
            if (rewardsToken != token1) {
                // Swap half earned to token1
                _safeSwap(
                    rewardAmount.div(2),
                    rewardToToken1Path,
                    address(this)
                );
            }

            uint256 token0Amount = IERC20(token0).balanceOf(address(this));
            uint256 token1Amount = IERC20(token1).balanceOf(address(this));

            if (token0Amount > 0 && token1Amount > 0) {
                IUniRouter02(router).addLiquidity(
                    token0,
                    token1,
                    token0Amount,
                    token1Amount,
                    0,
                    0,
                    address(this),
                    block.timestamp.add(600)
                );
            }

            _startFarm();
    	}
	}

	function startFarm() external onlyOwner {
		_startFarm();
	}

	function stopFarm() external onlyOwner {
		_stopFarm();
	}

	function withdrawTokens(address[] memory _token) external onlyOwner {
		// Withdraws any token
		for (uint i = 0; i < _token.length; i++) {
			uint balance = IERC20(_token[i]).balanceOf(address(this));
			IERC20(_token[i]).safeTransfer(msg.sender, balance);
		}
	}

	function withdrawPairToUnderlying() external onlyOwner {
		// Remove liquidity
		uint lpBalance = IERC20(pair).balanceOf(address(this));

		if (lpBalance > 0) {
			IUniRouter02(router).removeLiquidity(
				token0,
				token1,
				lpBalance,
				0,
				0,
				address(this),
				block.timestamp.add(600)
			);
		}

		uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));

        IERC20(token0).safeTransfer(msg.sender, token0Amount);
        IERC20(token1).safeTransfer(msg.sender, token1Amount);
	}

	function convertDustToEarned() external onlyOwner {
        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amount = IERC20(token0).balanceOf(address(this));
        if (token0Amount > 0 && token0 != rewardsToken) {
            // Swap all dust tokens to earned tokens
            _safeSwap(
                token0Amount,
                token0ToRewardPath,
                address(this)
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amount = IERC20(token1).balanceOf(address(this));
        if (token1Amount > 0 && token1 != rewardsToken) {
            // Swap all dust tokens to earned tokens
            _safeSwap(
                token1Amount,
                token1ToRewardPath,
                address(this)
            );
        }
    }

	// View Functions

	function amountInFarm() public view returns (uint256) {
        return IStakingRewards(stakingRewardsContract).balanceOf(address(this));
    }

    // Helper Functions
    function setPaths(
    	address[] memory _rewardToToken0Path,
		address[] memory _rewardToToken1Path,
		address[] memory _token0ToRewardPath,
		address[] memory _token1ToRewardPath
    ) external onlyOwner {
    	rewardToToken0Path = _rewardToToken0Path;
		rewardToToken1Path = _rewardToToken1Path;
		token0ToRewardPath = _token0ToRewardPath;
		token1ToRewardPath = _token1ToRewardPath;
    }

	function setSlippageFactor(uint _slippageFactor) external onlyOwner {
		require(_slippageFactor < 999, "StrategyQuickSwap: MIN_SLIPPAGE_SUBCEEDED");
		slippageFactor = _slippageFactor;
	}

	function resetAllowance() external onlyOwner {
		_resetAllowance();
	}

	// Internal Functions

	function _startFarm() internal {
		uint lpBalance = IERC20(pair).balanceOf(address(this));

		IStakingRewards(stakingRewardsContract).stake(lpBalance);
	}

	function _stopFarm() internal {
		IStakingRewards(stakingRewardsContract).exit();
	}

	function _resetAllowance() internal {
		IERC20(pair).safeApprove(stakingRewardsContract, uint(0));
		IERC20(pair).safeIncreaseAllowance(stakingRewardsContract, uint(-1));

		IERC20(pair).safeApprove(router, uint(0));
		IERC20(pair).safeIncreaseAllowance(router, uint(-1));

		IERC20(token0).safeApprove(router, uint(0));
		IERC20(token0).safeIncreaseAllowance(router, uint(-1));

		IERC20(token1).safeApprove(router, uint(0));
		IERC20(token1).safeIncreaseAllowance(router, uint(-1));

		IERC20(rewardsToken).safeApprove(router, uint(0));
		IERC20(rewardsToken).safeIncreaseAllowance(router, uint(-1));
	}

	function _safeSwap(
        uint256 _amountIn,
        address[] memory _path,
        address _to
    ) internal {
        uint256[] memory amounts = IUniRouter02(router).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IUniRouter02(router).swapExactTokensForTokens(
            _amountIn,
            amountOut.mul(slippageFactor).div(1000),
            _path,
            _to,
            block.timestamp.add(600)
        );
    }
}