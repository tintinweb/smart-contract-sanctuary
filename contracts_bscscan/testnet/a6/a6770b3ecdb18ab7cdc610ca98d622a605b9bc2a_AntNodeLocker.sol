/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract AntNodeLocker {
  using SafeMath for uint256;

  event Lock(string indexed nodeId, address indexed antAddress, uint256 amount, uint256 height);
  event Withdraw(string indexed nodeId, address indexed antAddress, uint256 amount, uint256 height);

  struct NodeLockInfo {
    address antAddress;
    uint256 lockedAmount;
    uint lockedAt;
  }

  mapping (string => NodeLockInfo) public antLockInfos;

  IERC20  public token;
  address public tokenContract;
  address public owner;
  uint256 public totalLockAmount;

  event Withdraw(address indexed tokenOwner, uint256 amount);

  uint public minLockAmount;

  constructor(address _token) {
    tokenContract = _token;
    token = IERC20(_token);
    owner = msg.sender;
    minLockAmount = 10 * 10 ** uint256(token.decimals());
    totalLockAmount = 0;
  }

  function setMinLockAmount(uint amount) public {
    require(msg.sender == owner);
    minLockAmount = amount;
  }

  function lock(string memory nodeId, address antAdress) public {
     require(antLockInfos[nodeId].lockedAmount == 0, "failed to lock");
     require(token.transferFrom(msg.sender, address(this), minLockAmount), "failed to transfer");

     antLockInfos[nodeId] = NodeLockInfo({
       antAddress: antAdress,
       lockedAmount: minLockAmount,
       lockedAt: block.number
     });
     totalLockAmount = totalLockAmount.add(minLockAmount);
     emit Lock(nodeId, antAdress, minLockAmount, block.number);
  }

  function withdraw(string memory nodeId) public {
      NodeLockInfo memory node  = antLockInfos[nodeId];
      require(node.lockedAmount > 0, "invalid nodeId");

      uint oneYearHeight = 7632000;
      
      require(node.lockedAt + oneYearHeight < block.number, "time not reached");
      require(token.transfer(node.antAddress, node.lockedAmount), "failed to transfer");

      delete antLockInfos[nodeId];
      totalLockAmount = totalLockAmount.sub(node.lockedAmount);
      emit Withdraw(nodeId, node.antAddress,  node.lockedAmount,  block.number);
  }
}