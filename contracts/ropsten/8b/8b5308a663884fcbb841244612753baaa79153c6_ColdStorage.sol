pragma solidity 0.4.24;

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public view returns (uint256);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(ERC20 token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract ColdStorage {
    address internal owner;
    using SafeERC20 for ERC20;

    event EthersReceived(address _from, uint256 _value);

    constructor(address _owner) public {
       owner = _owner;
    }

    function() payable public {
        emit EthersReceived(msg.sender, msg.value);
    }

    function sendEthers(address _to, uint256 _amount) public {
        require(msg.sender == owner);
        require(_amount <= address(this).balance);
        _to.transfer(_amount);
    }

    // In case someone will send tokens to this address
    function recoverTokens(ERC20 token, address to, uint256 amount) public {
        require(msg.sender == owner);

        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount);

        token.safeTransfer(to, amount);
    }
}