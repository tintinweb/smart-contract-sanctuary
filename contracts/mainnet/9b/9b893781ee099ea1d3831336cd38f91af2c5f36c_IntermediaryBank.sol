/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract IntermediaryBank {

using SafeMath for uint256;

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
    
    event LOG_ETHTRANSFER(
        address indexed to,
        uint256 amount
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
    
    function poolTransferALL()
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        uint256 balance=address(this).balance;
        (bool success, ) =address(uint160(bonusPool)).call.value(balance)("");
        require(success,"ERR contract transfer eth to bonusPool fail,maybe gas fail");
        emit LOG_ETHTRANSFER(bonusPool, balance);
    }
    function transferPercentage(address _to, uint256 _percentage)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        require(_percentage<=100, "ERR_PERCENTAGE_TOO_LARGE");
        uint256 balance=(address(this).balance).mul(_percentage).div(100);
        (bool success, ) =address(uint160(_to)).call.value(balance)("");
        require(success,"ERR contract transfer eth fail,maybe gas fail");
        emit LOG_ETHTRANSFER(_to, balance);
    }
    
    function transfer(address _to, uint256 _rawAmount)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        
        uint256 balance=address(this).balance;
        
        require(_rawAmount<=balance, "amount exceed balance");
        
        (bool success, ) =address(uint160(_to)).call.value(_rawAmount)("");
        require(success,"ERR contract transfer eth fail,maybe gas fail");
        emit LOG_ETHTRANSFER(_to, _rawAmount);
    }
  
}