pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

interface ERC777i {
  function operatorSend(address from, address to, uint256 amount, bytes userData, bytes operatorData) public;
}

contract Spacedrop {
  using SafeERC20 for ERC20;

  mapping (bytes32 => bool) used;
  event Sent(address indexed token, address indexed sender, address indexed recipient, uint256 tokensToTransfer, uint256 nonce, uint256 iface);

  function validateAndRegisterClaim(address sender, bytes32 h, uint8 v, bytes32 r, bytes32 s) internal {
    // signer must be sender
    bytes memory prefix = &quot;\x19Ethereum Signed Message:\n32&quot;;
    address signer = ecrecover(keccak256(prefix, h), v, r, s);
    require(signer == sender && signer != address(0));

    // check this claim hasn&#39;t been recorded already, then record it
    require(!used[h]);
    used[h] = true;
  }

  function claimTokensERC20(address token, address sender, address recipient, uint256 tokensToTransfer, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 h = keccak256(token, sender, recipient, tokensToTransfer, nonce);
    validateAndRegisterClaim(sender, h, v, r, s);
    ERC20(token).safeTransferFrom(sender, recipient, tokensToTransfer);
    Sent(token, sender, recipient, tokensToTransfer, nonce, 20);
  }

  function claimTokensERC777(address token, address sender, address recipient, uint256 tokensToTransfer, uint256 nonce, bytes userData, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 h = keccak256(token, sender, recipient, tokensToTransfer, nonce, userData);
    validateAndRegisterClaim(sender, h, v, r, s);
    ERC777i(token).operatorSend(sender, recipient, tokensToTransfer, userData, &quot;spacedrop&quot;);
    Sent(token, sender, recipient, tokensToTransfer, nonce, 777);
  }
}