// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStakingRewards {
    function rewardRate() external view returns (uint256);
    
    function rewardsDuration() external view returns (uint256);
    
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    function stakingToken() external returns (address);

    function rewardsToken() external returns (address);
}