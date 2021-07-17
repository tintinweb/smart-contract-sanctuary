/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract sign {
    uint256 public constant BORROWING_MASK =  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    
     uint256 internal constant BORROWING_MASK2 =
    0x5555555555555555555555555555555555555555555555555555555555555555;
    
    function viewOf() public pure returns(uint256){
        return ~BORROWING_MASK;
    }
    
    function viewOf2() public pure returns(uint256){
        return ~BORROWING_MASK2;
    }
    
    function opr(uint256 one,uint256 two) public pure returns(uint256){
        return (one & two );
    }
}
























// // We require the Hardhat Runtime Environment explicitly here. This is optional
// // but useful for running the script in a standalone fashion through `node <script>`.
// //
// // When running the script with `npx hardhat run <script>` you'll find the Hardhat
// // Runtime Environment's members available in the global scope.
// const hre = require("hardhat");

// async function main() {
//   // Hardhat always runs the compile task when running scripts with its command
//   // line interface.
//   //
//   // If this script is run directly using `node` you may want to call compile
//   // manually to make sure everything is compiled
//   // await hre.run('compile');

//   //We get the contract to deploy




//   // const depolyAddr = await hre.ethers.getContractFactory("AaveEcosystemReserve");
//   // const AaveEcosystemReserve = await depolyAddr.deploy();

//   // await AaveEcosystemReserve.deployed();

//   // console.log("AaveEcosystemReserve:", AaveEcosystemReserve.address);

//   await hre.run("verify:verify", {
//     address: "0x6661cd22fD8E2Af3789aDB93650E3Dc993A55808",
//     constructorArguments: [
//     ],
//   });
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });


// //npx hardhat run --network ropsten scripts/mainStake.js




// require("@nomiclabs/hardhat-waffle");
// require("@nomiclabs/hardhat-etherscan");
// require('@nomiclabs/hardhat-ethers');

// let sec = require('./secret.json');

// // This is a sample Hardhat task. To learn how to create your own go to
// // https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async () => {
//   const accounts = await ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// // You need to export an object to set up your config
// // Go to https://hardhat.org/config/ to learn more

// /**
//  * @type import('hardhat/config').HardhatUserConfig
//  */

// module.exports = {
//   defaultNetwork: "ropsten",
//   networks: {
//     hardhat: {
//     },
//     kovan: {
//       url: "https://kovan.infura.io/v3/4f4bdd30bfd2499788db641570ed3124",
//       accounts: ["99748c4d7a2391052aade492dee9a4ff8b3810522aa9a862d207d29e7e7476c9"]
//       //apiKey: "https://kovan.etherscan.io/XYV9VVFBFXJWD7YDZQTSBA7KHINTIYZ8XY"
//     },
//     ropsten: {
//       url: "https://ropsten.infura.io/v3/4f4bdd30bfd2499788db641570ed3124",
//       accounts: ["99748c4d7a2391052aade492dee9a4ff8b3810522aa9a862d207d29e7e7476c9"]
//       //apiKey: "https://kovan.etherscan.io/XYV9VVFBFXJWD7YDZQTSBA7KHINTIYZ8XY"
//     },
//     testnet: {
//       url: "https://data-seed-prebsc-1-s1.binance.org:8545",
//       chainId: 97,
//       gasPrice: 200000000000,
//       accounts: {mnemonic :"game gossip auto kingdom clock rule abandon hospital tissue elevator rug woman"}
//     },
//     mainnet: {
//       url: "https://bsc-dataseed.binance.org/",
//       chainId: 56,
//       gasPrice: 20000000000,
//       accounts: {mnemonic :"game gossip auto kingdom clock rule abandon hospital tissue elevator rug woman"}
//     }
//   },
//   etherscan: {
//     // Your API key for Etherscan
//     // Obtain one at https://etherscan.io/
//     apiKey: "XYV9VVFBFXJWD7YDZQTSBA7KHINTIYZ8XY" // ethereum
//     //apiKey: "ZHQXNYI5N94CT8592UPJI7Z4AH55THCTF2" // binance
//   },
//   solidity: {

//     compilers: [
//       {
//         version: "0.6.12",
//         settings: {
//           optimizer: {enabled: true,runs: 200},
//           evmVersion: 'istanbul'
//         }
//       },
//       {
//         version: "0.7.5",
//         settings: {
//           optimizer: {enabled: true,runs: 200},
//           evmVersion: 'istanbul'
//         }
//       },
//       {
//         version: "0.7.6",
//         settings: {
//           optimizer: {enabled: true,runs: 200},
//           evmVersion: 'istanbul'
//         }
//       },
//       {
//         version: "0.5.14",
//         settings: {
//           optimizer: {enabled: true,runs: 200},
//           evmVersion: 'istanbul'
//         }
//       },
//       // {
//       //   version: "0.7.6",
//       //   settings: {
//       //     optimizer: {
//       //       enabled: true,
//       //       runs: 200
//       //     }
//       //   }
//       // },
//     ],

//   },
//   paths: {
//     sources: "./contracts",
//     tests: "./test",
//     cache: "./cache",
//     artifacts: "./artifacts"
//   },
//   mocha: {
//     timeout: 30000
//   }
// }













// {

//     "url": "https://kovan.infura.io/v3/4f4bdd30bfd2499788db641570ed3124",
//     "accounts": "99748c4d7a2391052aade492dee9a4ff8b3810522aa9a862d207d29e7e7476c9"

// }

//99748c4d7a2391052aade492dee9a4ff8b3810522aa9a862d207d29e7e7476c9