// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

import './BridgeBase.sol';

contract BridgeBsc is BridgeBase {
  constructor(address token) public BridgeBase(token) {}
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BridgeBase is Ownable {
  address public unlocker;
  IERC20 public token;
  mapping(address => mapping(uint => bool)) public processedNonces;
  bool public killSwitchEngaged = false;
  uint256 public maxTxAmount = 10000000e9;

  event Lock(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature
  );

  event Unlock(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    bytes signature
  );

  event KillSwitchToggled(
    address toggler,
    bool killSwitchEngaged
  );

  constructor (address _token) public {
    token = IERC20(_token);
    unlocker = msg.sender;
  }

  function killSwitchToggle(bool _engaged) external onlyOwner {
    killSwitchEngaged = _engaged;
    emit KillSwitchToggled(msg.sender, _engaged);
  }

  function updateUnlocker(address _newUnlocker) external onlyOwner {
    unlocker = _newUnlocker;
  }

  function updateMaxTxAmount(uint256 _newMax) external onlyOwner {
    maxTxAmount = _newMax;
  }

  function lock(address to, uint amount, uint nonce, bytes calldata signature) external {
    require(killSwitchEngaged == false, 'bridge killswitch engaged');
    require(amount <= maxTxAmount, 'exceeds max tx amount');
    require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
    processedNonces[msg.sender][nonce] = true;
    token.transferFrom(msg.sender, address(this), amount);
    emit Lock(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      signature
    );
  }

  function unlock(  
    address from, 
    address to, 
    uint amount, 
    uint nonce,
    bytes calldata signature
  ) external {
    bytes32 message = keccak256(abi.encodePacked(
      from, 
      to, 
      amount,
      nonce
    ));
    require(killSwitchEngaged == false, 'bridge killswitch engaged');
    require(msg.sender == unlocker, 'only the unlocker address can call this function');
    require(recoverSigner(message, signature) == from , 'wrong signature');
    require(amount <= maxTxAmount, 'exceeds max tx amount');
    require(processedNonces[from][nonce] == false, 'transfer already processed');
    processedNonces[from][nonce] = true;
    token.transfer(from, amount);
    emit Unlock(
      from,
      to,
      amount,
      block.timestamp,
      nonce,
      signature
    );
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}