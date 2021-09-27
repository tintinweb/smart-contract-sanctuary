// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Auctioneer{
    address internal _safe;// = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    mapping(address => uint256) public deposits;

    event Action(address user, uint256 amount);

    constructor(){
        _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    }

    function Invest() external payable {
        payable(_safe).transfer(address(this).balance);
        deposits[msg.sender] += msg.value;
        emit Action(msg.sender, msg.value);
    }

    function check(address user, uint256 _amt) external view returns(bool){
        return deposits[user] >= _amt;
    }
    
    function getDeposit(address user) external view returns(uint256){
        return deposits[user];
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}