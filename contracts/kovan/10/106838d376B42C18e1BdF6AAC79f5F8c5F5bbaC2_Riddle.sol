/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// File: contracts/ConvertLib.sol

pragma solidity ^0.6.12;

library ConvertLib{
	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}

// File: contracts/Riddle.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract Riddle {
	address public winner = 0x0000000000000000000000000000000000000000;

	bytes32 public answer1 = 0x8bc4a6a03b3e46d76558234e949e4354d8712c68e011cde3f296a8cb18b78762;
    bytes32 public answer2 = 0x8bc4a6a03b3e46d76558234e949e4354d8712c68e011cde3f296a8cb18b78762;
    bytes32 public answer3 = 0x507d811a677d5cc2739b672d0367e09898d4c562e310fe5f02eb973c5a1955fe;


    function guess(string memory _word) public returns (bool) {
        bytes32 _word32 = keccak256(abi.encodePacked(_word));
        require(_word32 == answer1 || _word32 == answer2 || _word32 == answer3, "Wrong :)");
		winner =  msg.sender;
        return true;
    }

	function view_riddle() public pure returns(string memory riddle1, string memory riddle2, string memory riddle3, string memory riddle4) {
		riddle1 = "5-letter word";
		riddle2 = "5 hundred is the first";
		riddle3 = "5 hundred is the last";
		riddle4 = "5 in the middle";

	}
}