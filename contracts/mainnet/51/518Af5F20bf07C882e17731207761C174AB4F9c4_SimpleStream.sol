/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/SimpleStream.sol
// https://github.com/austintgriffith/scaffold-eth/tree/simple-stream

//
// 🏰 BuidlGuidl.com
//


pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT

//import "hardhat/console.sol";

contract SimpleStream {

  event Withdraw( address indexed to, uint256 amount, string reason );
  event Deposit( address indexed from, uint256 amount, string reason );

  address payable public toAddress;// = payable(0xD75b0609ed51307E13bae0F9394b5f63A7f8b6A1);
  uint256 public cap;// = 0.5 ether;
  uint256 public frequency;// 1296000 seconds == 2 weeks;
  uint256 public last;//stream starts empty (last = block.timestamp) or full (block.timestamp - frequency)

  constructor(address payable _toAddress, uint256 _cap, uint256 _frequency, bool _startsFull) {
    toAddress = _toAddress;
    cap = _cap;
    frequency = _frequency;
    if(_startsFull){
      last = block.timestamp - frequency;
    }else{
      last = block.timestamp;
    }
  }

  function streamBalance() public view returns (uint256){
    if(block.timestamp-last > frequency){
      return cap;
    }
    return (cap * (block.timestamp-last)) / frequency;
  }

  function streamWithdraw(uint256 amount, string memory reason) public {
     require(msg.sender==toAddress,"this stream is not for you");
     uint256 totalAmountCanWithdraw = streamBalance();
     require(totalAmountCanWithdraw>=amount,"not enough in the stream");
     uint256 cappedLast = block.timestamp-frequency;
     if(last<cappedLast){
       last = cappedLast;
     }
     last = last + ((block.timestamp - last) * amount / totalAmountCanWithdraw);
     emit Withdraw( msg.sender, amount, reason );
     toAddress.transfer(amount);
   }

   function streamDeposit(string memory reason) public payable {
      emit Deposit( msg.sender, msg.value, reason );
   }

   receive() external payable { streamDeposit(""); }
}