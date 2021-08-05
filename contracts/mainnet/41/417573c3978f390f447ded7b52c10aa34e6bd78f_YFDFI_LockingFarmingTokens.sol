/**
 *Submitted for verification at Etherscan.io on 2020-12-25
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface YfDFI {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract YFDFI_LockingFarmingTokens is Ownable {
    using SafeMath for uint;
    
    address public constant tokenAddress = 0x4F4F0Ef7978737ce928BFF395529161b44e27ad9;
    
    uint public constant tokensLocked = 5000e18;   // 5000 YFD Tokens
    uint public constant unlockRate = 5000;       
    uint public constant lockDuration = 6 days;   // Farming Platform Release
    uint public lastClaimedTime;
    uint public deployTime;

    
    constructor() public {
        deployTime = now;
        lastClaimedTime = now;
    }
    
    function claim() public onlyOwner {
        uint pendingUnlocked = getPendingUnlocked();
        uint contractBalance = YfDFI(tokenAddress).balanceOf(address(this));
        uint amountToSend = pendingUnlocked;
        if (contractBalance < pendingUnlocked) {
            amountToSend = contractBalance;
        }
        require(YfDFI(tokenAddress).transfer(owner, amountToSend), "Could not transfer Tokens.");
        lastClaimedTime = now;
    }
    
    function getPendingUnlocked() public view returns (uint) {
        uint timeDiff = now.sub(lastClaimedTime);
        uint pendingUnlocked = tokensLocked
                                    .mul(unlockRate)
                                    .mul(timeDiff)
                                    .div(lockDuration)
                                    .div(1e4);
        return pendingUnlocked;
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != tokenAddress, "Cannot transfer out reward tokens");
        YfDFI(_tokenAddr).transfer(_to, _amount);
    }

}