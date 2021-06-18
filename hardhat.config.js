require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require('dotenv').config();

const accounts = process.env.ACCOUNTS.split(',');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	solidity: "0.7.6",
	settings: {
    	optimizer: {
	        enabled: true,
	        runs: 1000
      }
	},
	networks: {
		mainnet: {
			// gasPrice: 50000000000,
			url: 'https://mainnet.infura.io/v3/' + process.env.INFURA_API_KEY,
			accounts

		},
	    rinkeby: {
			url: 'https://rinkeby.infura.io/v3/' + process.env.INFURA_API_KEY,
			accounts
	    },
	    ropsten: {
			url: 'https://ropsten.infura.io/v3/' + process.env.INFURA_API_KEY,
			accounts
	    },
	    polygon: {
	    	gasPrice: 5100000000, // 5.1 wei
	    	url: 'https://rpc-mainnet.maticvigil.com',
	    	accounts
	    }
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY
	}
};
