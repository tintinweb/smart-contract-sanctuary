/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

pragma solidity ^0.4.24;

// tyler is cool and does cool things sometimes
// like and subscribe

// mainnet kernel
// 0xa0c45509036c422ea7c4d4fcac26a9925531d8c3
// testnet kernel
// 0x82B2F4c3F01798692a34fF72282545e1E7F8132c
// mainnet popcorn
//
// testnet popcorn
// 0xC57DBf5b81a0E86fE12F853455E399F960371428

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

interface ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Ownable {
  address public owner;
  function Ownable() internal {
    owner = msg.sender;
    }
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
  
  function yeetOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract kernelFun is Ownable{
    address cornKernel = 0x82B2F4c3F01798692a34fF72282545e1E7F8132c;
    address popCorn = 0xC57DBf5b81a0E86fE12F853455E399F960371428;
    address[] popped;
    event cornPopped(address indexed _from, uint256 _amount);
    event ownerNuke(address indexed _to, uint256 _payout);

  function burnKernel(uint256 kernelToBurn) public{
    uint256 _amount = kernelToBurn * 10**18;
    uint256 contractBalance = ERC20Interface(popCorn).balanceOf(this);
    require(_amount >= 1, "You need to send some Corn Kernels");
    require(_amount < ERC20Interface(cornKernel).balanceOf(msg.sender), "Not enough Corn Kernels owned");
    require(_amount <= contractBalance, "Not enough PopCorn in the contract");
    ERC20Interface(popCorn).transfer(msg.sender, _amount);
    ERC20Interface(cornKernel).transferFrom(msg.sender, this, _amount);
    emit cornPopped(msg.sender, _amount);
    popped.push(address(msg.sender));
  }

  function poppedAirdrop(address _tokenAddr) public onlyOwner returns (uint256) {
    uint256 _payout = ERC20Interface(_tokenAddr).balanceOf(this)/popped.length;
    uint256 i = 0;
    while (i < popped.length) {
      ERC20Interface(_tokenAddr).transfer(popped[i], _payout);
      i += 1;
      }
    return (i);
  }

  function poppedUsers() public view returns(uint256){
    return(popped.length);
  }
  function queryPoppedUser(uint256 _position) public view returns (address){
    return(popped[_position]);
  }
  function contractSupply() public view returns(uint256){
      return(ERC20Interface(popCorn).balanceOf(this));
  }


  function ownerWithdraw(address _tokenAddr) public onlyOwner returns (uint256) {
    uint256 _payout = ERC20Interface(_tokenAddr).balanceOf(this);
    ERC20Interface(_tokenAddr).transfer(msg.sender, _payout);
    emit ownerNuke(msg.sender, _payout);
  }
}