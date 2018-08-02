pragma solidity ^0.4.13;

contract TokenFaucet {
    /** 
     * Use SafeERC20 to make transactions revert on faulty behaviour rather than
     * having to check for return values on every ERC20 token call
     */
    using SafeERC20 for ERC20;

    /// @dev the token being served by this faucet
    ERC20 public token;

    uint256 public constant tokensPerAddress = 100;

    /// @dev this variables track addresses that already collected from the faucet.
    mapping (address=>bool) recipients;

    /**
     * @notice Creates a TokenFaucet tied to a specific token
     */
    constructor(ERC20 _token) public {
        token = _token;
    }

    /**
     * @dev Transfer `tokensPerAddress` to `msg.sender` and prevent it from collecting more.
     */
    function tap() public {
        require(!recipients[msg.sender], &quot;Address already received faucet payout&quot;);
        recipients[msg.sender] = true;
        token.safeTransfer(msg.sender, tokensPerAddress);
    }

    function debug_is_recipient() public view returns(bool){
        return recipients[msg.sender];
    }

    function debug_token_balanceof_faucet() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function debug_is_dry() public view returns(bool){
        return token.balanceOf(address(this)) < tokensPerAddress;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
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