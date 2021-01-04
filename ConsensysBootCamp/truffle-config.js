const path = require("path");

const HDWalletProvider = require('@truffle/hdwallet-provider');
//const infuraKey = "fj4jll3k.....";
//
// const fs = require('fs');
const mnemonic = "secret"


module.exports = {
  
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      port: 8545
    },
    rinkeby: {
      provider: function() { 
       return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/YOUR_API_KEY");
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
  },
},
  compilers: {
    solc: {
      version: "0.6",
    },
  }
};
