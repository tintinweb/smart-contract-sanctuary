/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT

// [
// 	{
// 		"inputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "num",
// 				"type": "uint256"
// 			},
// 			{
// 				"internalType": "uint8",
// 				"name": "broj",
// 				"type": "uint8"
// 			},
// 			{
// 				"internalType": "address",
// 				"name": "adresa",
// 				"type": "address"
// 			},
// 			{
// 				"internalType": "string",
// 				"name": "tekst",
// 				"type": "string"
// 			},
// 			{
// 				"internalType": "bool",
// 				"name": "bul",
// 				"type": "bool"
// 			}
// 		],
// 		"stateMutability": "nonpayable",
// 		"type": "constructor"
// 	},
// 	{
// 		"inputs": [],
// 		"name": "retrieve",
// 		"outputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "",
// 				"type": "uint256"
// 			}
// 		],
// 		"stateMutability": "view",
// 		"type": "function"
// 	},
// 	{
// 		"inputs": [
// 			{
// 				"internalType": "uint256",
// 				"name": "num",
// 				"type": "uint256"
// 			}
// 		],
// 		"name": "store",
// 		"outputs": [],
// 		"stateMutability": "nonpayable",
// 		"type": "function"
// 	}
// ]

pragma solidity ^0.8.4;

contract TestStorage {

    uint256 number;
    uint8 broj;
    address adresa;
    string tekst;
    bool bul;

    constructor(uint256 num_, uint8 broj_, address adresa_, string memory tekst_, bool bul_) {
        number = num_;
        broj = broj_;
        adresa = adresa_;
        tekst = tekst_;
        bul = bul_;
    }

    function store(uint256 num_) public {
        number = num_;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}