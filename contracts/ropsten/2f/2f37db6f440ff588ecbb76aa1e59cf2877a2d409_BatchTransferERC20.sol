pragma solidity ^0.4.18;

contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
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

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract BatchTransferERC20 is Ownable {
    function transfer(ERC20 token, address[] tos, uint value) public {
        uint length = tos.length;
        uint total = value * length;
        require(total >= value && token.balanceOf(this) >= total);
        for (uint i = 0; i < length; i++) {
            token.transfer(tos[i], value);
        }
    }

    function transferFrom(ERC20 token, address from, address[] tos, uint value) public {
        uint length = tos.length;
        uint total = value * length;
        require(total >= value && token.balanceOf(from) >= total);
        for (uint i = 0; i < length; i++) {
            token.transferFrom(from, tos[i], value);
        }
    }

    function withdrawERC20(ERC20 token, uint value) public onlyOwner returns (bool success) {
        return token.transfer(owner, value);
    }

    function withdrawETH(uint value) public onlyOwner {
        owner.transfer(value);
    }
}