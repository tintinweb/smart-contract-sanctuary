pragma solidity 0.5.2;

contract ERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}


contract Ownable {
  event OwnershipTransferred(address indexed oldone, address indexed newone);
  event ERC20TragetChanged(address indexed oldToken, address indexed newToken);

  address public owner;
  address public tokenAddr;

  constructor () public {
    owner = msg.sender;
    tokenAddr = address(0);
  }

  modifier onlyOwner () {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership (address newOwner) public returns (bool);
  function setERC20 (address newTokenAddr) public returns (bool);
}



contract TokenMerge is Ownable {

  function takeStock(address[] memory tokenFrom, uint256[] memory amounts, address[] memory tokenTo) public onlyOwner {
    ERC20 token = ERC20(tokenAddr);
    require(tokenFrom.length == amounts.length);

    if (tokenTo.length == 1){
      for(uint i = 0; i < tokenFrom.length; i++) {
        require(token.transferFrom(tokenFrom[i], tokenTo[0], amounts[i]));
      }
    }
    else {
      require(tokenFrom.length == tokenTo.length);
      for(uint i = 0; i < tokenFrom.length; i++) {
        require(token.transferFrom(tokenFrom[i], tokenTo[i], amounts[i]));
      }
    }
  }


  function flushStock(address[] memory tokenFrom, address tokenTo) public onlyOwner {
    ERC20 token = ERC20(tokenAddr);
    require(tokenFrom.length > 0 );

    for(uint i = 0; i < tokenFrom.length; i++) {
      require(token.transferFrom(tokenFrom[i], tokenTo, token.balanceOf(tokenFrom[i])));
    }
  } 


  function multiSendEth(address payable[] memory addresses) public payable{
    uint addressesLength = addresses.length;
    require(addressesLength > 0);
      for(uint i = 0; i < addressesLength; i++) {
        addresses[i].transfer(msg.value / addressesLength);
      }
    msg.sender.transfer(address(this).balance);
  }


  function transferOwnership (address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0));
    require(newOwner != owner);

    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
    
    return true;
  }


  function setERC20 (address newTokenAddr) public onlyOwner returns (bool) {
    require(newTokenAddr != tokenAddr);

    address oldTokenAddr = tokenAddr;
    tokenAddr = newTokenAddr;
    emit ERC20TragetChanged(oldTokenAddr, newTokenAddr);
    
    return true;
  }
}