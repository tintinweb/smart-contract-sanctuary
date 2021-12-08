/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract helloWorld {
    function renderHelloWorld () public pure returns (string memory greeting){
        greeting = 'Hello World!';
    }
}

// [
// 	{
// 		"inputs": [],
// 		"name": "renderHelloWorld",
// 		"outputs": [
// 			{
// 				"internalType": "string",
// 				"name": "greeting",
// 				"type": "string"
// 			}
// 		],
// 		"stateMutability": "pure",
// 		"type": "function"
// 	}
// ]