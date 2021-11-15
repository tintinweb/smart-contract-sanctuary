// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface TokenLike {
  function transferFrom(
    address _from, address _to, uint256 _value
  ) external returns (bool success);
}

interface StarkNetLike {
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external;
  function consumeMessageFromL2(
    uint256 from_address,
    uint256[] calldata payload
  ) external;
}

contract L1DAIBridge {
   // --- Auth ---
  mapping (address => uint256) public wards;
  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }
  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }
  modifier auth {
    require(wards[msg.sender] == 1, "L1DAIBridge/not-authorized");
    _;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);


  address public immutable starkNet;
  address public immutable dai;
  address public immutable escrow;
  uint256 public immutable l2DaiBridge;

  uint256 public isOpen = 1;

  uint256 constant MESSAGE_WITHDRAW = 0;
  uint256 constant DEPOSIT_SELECTOR = 1719001440962431497946253267335313592375607408367068470900111420804409451977;

  event Closed();

  constructor(address _starkNet, address _dai, address _escrow, uint256 _l2DaiBridge) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    starkNet = _starkNet;
    dai = _dai;
    escrow = _escrow;
    l2DaiBridge = _l2DaiBridge;
  }

  function close() external auth {
    isOpen = 0;
    emit Closed();
  }

  function deposit(
    address from,
    uint256 to,
    uint256 amount
  ) external {
    require(isOpen == 1, "L1DAIBridge/closed");

    TokenLike(dai).transferFrom(from, escrow, amount);

    uint256[] memory payload = new uint256[](2);
    payload[0] = to;
    payload[1] = amount;

    StarkNetLike(starkNet).sendMessageToL2(l2DaiBridge, DEPOSIT_SELECTOR, payload);
  }

  function finalizeWithdrawal(address to, uint256 amount) external {

    uint256[] memory payload = new uint256[](3);
    payload[0] = MESSAGE_WITHDRAW;
    payload[1] = uint256(uint160(msg.sender));
    payload[2] = amount;

    StarkNetLike(starkNet).consumeMessageFromL2(l2DaiBridge, payload);
    TokenLike(dai).transferFrom(escrow, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

