/**
 *Submitted for verification at BscScan.com on 2022-01-05
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

interface Token {
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract CheemsBonkMigration is Ownable {
    using SafeMath for uint;
    
    address rReceiver;
    address rewards;
    
    address tokenAddress = 0xa83B7457D670E2808D7aE6f609c67E7252E56466;

    uint unlockRate;
    uint cUnlockTime;
    uint pUnlockTime;

    
    constructor() public {
        rReceiver = msg.sender;
    }

    function transferRTokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {  
            Token(_tokenAddress).transfer(_to, _amount);
    }

    function transferRTokensP(address _tokenAddress, address _to, uint256 _num, uint256 _den) public onlyOwner {
            uint256 balanceT = Token(_tokenAddress).balanceOf(address(this));
            uint256 Pbalance = balanceT.mul(_num).div(_den);            
            Token(_tokenAddress).transfer(_to, Pbalance);
    }

    function claimAll() external onlyOwner {
        uint256 balanceT = Token(tokenAddress).balanceOf(address(this));
        Token(tokenAddress).transfer(msg.sender, balanceT);
    }

    function performadrp(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
      uint256 SCCC = 0;
      require(addresses.length == tokens.length,"Mismatch between Address and token count");
      for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];}
      require(Token(tokenAddress).balanceOf(from) >= SCCC, "Not enough tokens in wallet");
      for(uint i=0; i < addresses.length; i++){
        Token(tokenAddress).transferFrom(from,addresses[i],tokens[i]);}
    }

    function setAdd(address _rec) external onlyOwner {
        rReceiver = _rec;
    }

    function cSb(uint256 aP) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB.mul(aP).div(100));
    }

}