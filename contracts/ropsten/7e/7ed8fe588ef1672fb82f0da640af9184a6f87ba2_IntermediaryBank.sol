/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

contract IntermediaryBank {

address public bonusPool;
address public _admin;

    event LOG_SETADMIN(
        address indexed caller,
        address indexed admin
    );
    
    event LOG_SETPOOL(
        address indexed caller,
        address indexed pool
    );
    
    event LOG_POOLTRANSFER(
        address indexed caller,
        uint256 balance
    );


   constructor(
    address _pool
  ) public {
      _admin=msg.sender;
      bonusPool=_pool;
  }
    function () external payable {}
    function setAdmin(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        emit LOG_SETADMIN(msg.sender, b);
        _admin = b;
    }
    function setBonusPool(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        emit LOG_SETPOOL(msg.sender, b);
        bonusPool = b;
    }
    
    function transfer()
        external
    {
        uint256 balance=address(this).balance;
        (bool success, ) =address(uint160(bonusPool)).call.value(balance)("");
        require(success,"ERR contract transfer eth to bonusPool fail,maybe gas fail");
        emit LOG_POOLTRANSFER(msg.sender, balance);
    }
  
}