const hre = require("hardhat");
const BigNumber = ethers.BigNumber;

const sleep = require('sleep-promise');

// Strategy
const strategy = "0xFb2664aCb25Dc101E8aF4f2f782d90f57a2c1D01";
console.log("Strategy address:", strategy);

async function main() {
    compound();
    setInterval(compound,1800000);
}

async function compound() {
    const [deployer] = await ethers.getSigners();

    // Deploy StrategyQuickSwap
    const StrategyQuickSwapContract = await ethers.getContractFactory("StrategyQuickSwap");
    const StrategyQuickSwap = await StrategyQuickSwapContract.attach(strategy);
    // console.log(StrategyQuickSwap.address);

    // Compound
    try {
        await (await StrategyQuickSwap.compound({gasLimit: 800000})).wait();
        log("Strategy compounded! (Balance: " + ethers.utils.formatEther(await deployer.getBalance()) + " MATIC)");

    } catch (error) {
        console.log(error);
        log("Failed to compound strategy, retrying in 5 minutes...");
        await sleep(300000); // Sleep 5 minutes
        compound();
    }
}

log("Start compounding...");

main();


function log(message) {
    var now     = new Date(); 
    var year    = now.getFullYear();
    var month   = now.getMonth()+1; 
    var day     = now.getDate();
    var hour    = now.getHours();
    var minute  = now.getMinutes();
    var second  = now.getSeconds(); 
    if(month.toString().length == 1) {
         month = '0'+month;
    }
    if(day.toString().length == 1) {
         day = '0'+day;
    }   
    if(hour.toString().length == 1) {
         hour = '0'+hour;
    }
    if(minute.toString().length == 1) {
         minute = '0'+minute;
    }
    if(second.toString().length == 1) {
         second = '0'+second;
    }   
    var dateTime = day+'/'+month+'/'+year+' '+hour+':'+minute+':'+second;   

    console.log("[" + dateTime + "] " + message);
}
