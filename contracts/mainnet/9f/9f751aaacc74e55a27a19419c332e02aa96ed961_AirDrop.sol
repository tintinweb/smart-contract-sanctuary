pragma solidity ^0.4.18;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract ERC20Basic {
  function transfer(address _to, uint256 _value)external returns (bool);
  function balanceOf(address _owner)external constant returns (uint256 balance);
}

contract AirDrop is Ownable {

  ERC20Basic token;

  event TransferredToken(address indexed to, uint256 value);

  function AirDrop (address _tokenAddr) public {
      token = ERC20Basic(_tokenAddr);
  }

  // Function given below is used when you want to send same number of tokens to all the recipients
  function sendTokens(address[] recipient, uint256 value) onlyOwner external {
    for (uint256 i = 0; i < recipient.length; i++) {
        token.transfer(recipient[i],value * 10**8);
        emit TransferredToken(recipient[i], value);
    }
  }


  function tokensAvailable()public constant returns (uint256) {
    return token.balanceOf(this);
  }


  function destroy() public onlyOwner {
    uint256 balance = tokensAvailable();
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}