const hre = require("hardhat");
const BigNumber = ethers.BigNumber;

const sleep = require('sleep-promise');

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    console.log("Account balance:", (await deployer.getBalance()).toString());
    console.log("");

    // stakingRewardsContract
    // const stakingRewardsContract = "0x4A73218eF2e820987c59F838906A82455F42D98b"; // ETH-USDC
    const stakingRewardsContract = "0x6C6920aD61867B86580Ff4AfB517bEc7a499A7Bb"; // MATIC-USDC

    // reward token
    const QUICK = "0x831753DD7087CaC61aB5644b308642cc1c33Dc13";

    // token0
    const USDC = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";

    // token1
    const WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
    const WMATIC = "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270";

    // Deploy StrategyQuickSwap
    const StrategyQuickSwapContract = await ethers.getContractFactory("StrategyQuickSwap");
    const StrategyQuickSwap = await StrategyQuickSwapContract.deploy(
        stakingRewardsContract, // stakingRewardsContract
        [QUICK, USDC], // rewardToToken0Path
        [QUICK, WMATIC], // rewardToToken1Path
        [USDC, QUICK], // token0ToRewardPath
        [WMATIC, QUICK] // token1ToRewardPath
    );
    console.log("StrategyQuickSwap Address:", StrategyQuickSwap.address);

    console.log("\nWaiting for 1 minute before verification");
    await sleep(60000);

    await hre.run("verify:verify", {
        address: StrategyQuickSwap.address,
        constructorArguments: [
            stakingRewardsContract, // stakingRewardsContract
            [QUICK, USDC], // rewardToToken0Path
            [QUICK, WMATIC], // rewardToToken1Path
            [USDC, QUICK], // token0ToRewardPath
            [WMATIC, QUICK] // token1ToRewardPath
        ],
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});