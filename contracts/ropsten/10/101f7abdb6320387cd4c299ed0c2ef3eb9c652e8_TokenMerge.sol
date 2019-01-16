pragma solidity ^0.5.0;

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  event OwnershipTransferred(address indexed oldone, address indexed newone);

  address internal owner;
  constructor () public {
    owner = msg.sender;
  }
  modifier onlyOwner () {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership (address newOwner) public returns (bool);
}



contract TokenMerge is Ownable {
  address internal tokenAddr;
  constructor () public {
    tokenAddr = address(0);
  }

  function babiesComeHome(address[] memory tokenBase, uint256[] memory amounts) public onlyOwner {
    ERC20 token = ERC20(tokenAddr);
    uint tokenBaseLength = tokenBase.length;
    require(tokenBaseLength == amounts.length);
    for(uint i = 0; i < tokenBaseLength; i++) {
      require(token.transferFrom(tokenBase[i], msg.sender, amounts[i]));
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
    tokenAddr = newTokenAddr;
    
    return true;
  }
}