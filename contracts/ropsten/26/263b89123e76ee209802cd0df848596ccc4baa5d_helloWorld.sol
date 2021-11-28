/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract helloWorld {
		// 함수가 실행되는 동안 greeting 변수를 사용할 수 있습니다.
		// 함수가 끝까지 실행되면 greeting 변수의 값을 반환합니다.
    function renderHelloWorld () public pure returns (string memory greeting){
			greeting = "Hello World!"; 
		}
}