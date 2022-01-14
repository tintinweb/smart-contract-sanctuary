// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IBURNLock} from "./interfaces/IBURNLock.sol";

/// @dev Time-locks tokens according to an unlock schedule.
/// @title BURNLock contract.
/// @author root36x9
contract BURNLock is IBURNLock {
    /// @inheritdoc IBURNLock
    IERC20 public immutable override token;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockBegin;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockCliff;

    /// @inheritdoc IBURNLock
    uint256 public immutable override unlockEnd;

    /// @inheritdoc IBURNLock
    mapping(address => uint256) public override lockedAmounts;

    /// @inheritdoc IBURNLock
    mapping(address => uint256) public override claimedAmounts;

    /// @dev Emitted when the tokens locked to and address.
    /// @param sender The account who is locked.
    /// @param recipient The account the tokens will be claimable by.
    /// @param amount The number of tokens to transfer and lock.
    event Locked(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when the tokens claimed..
    /// @param owner Owner of the tokens..
    /// @param recipient Recipient for the locked tokens.
    /// @param amount The number of tokens to transfer and lock.
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Constructor.
    /// @param _token The token this contract will lock.l
    /// @param _unlockBegin The time at which unlocking of tokens will begin.
    /// @param _unlockCliff The first time at which tokens are claimable.
    /// @param _unlockEnd The time at which the last token will unlock.
    constructor(
        IERC20 _token,
        uint256 _unlockBegin,
        uint256 _unlockCliff,
        uint256 _unlockEnd
    ) {
        require(
            _unlockCliff >= _unlockBegin,
            "BURNLocked: Unlock cliff must not be before unlock begin"
        );
        require(
            _unlockEnd >= _unlockCliff,
            "BURNLocked: Unlock end must not be before unlock cliff"
        );
        token = _token;
        unlockBegin = _unlockBegin;
        unlockCliff = _unlockCliff;
        unlockEnd = _unlockEnd;
    }

    /// @inheritdoc IBURNLock
    function claimableBalance(address owner)
        public
        view
        override
        returns (uint256)
    {
        if (block.timestamp < unlockCliff) {
            return 0;
        }

        uint256 locked = lockedAmounts[owner];
        uint256 claimed = claimedAmounts[owner];
        if (block.timestamp >= unlockEnd) {
            return locked - claimed;
        }
        return
            (locked * (block.timestamp - unlockBegin)) /
            (unlockEnd - unlockBegin) -
            claimed;
    }

    /// @inheritdoc IBURNLock
    function lock(address recipient, uint256 amount) public override {
        require(
            block.timestamp < unlockEnd,
            "TokenLock: Unlock period already complete"
        );
        lockedAmounts[recipient] += amount;
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "TokenLock: Transfer failed"
        );
        emit Locked(msg.sender, recipient, amount);
    }

    /// @inheritdoc IBURNLock
    function claim(address recipient, uint256 amount) public override {
        uint256 claimable = claimableBalance(msg.sender);
        if (amount > claimable) {
            amount = claimable;
        }
        claimedAmounts[msg.sender] += amount;
        require(
            IERC20(token).transfer(recipient, amount),
            "TokenLock: Transfer failed"
        );
        emit Claimed(msg.sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBURNLock {
    /// @dev Timestamp for the begining of the claiming.
    function unlockBegin() external view returns (uint256);

    /// @dev Timestamp for the first time at which tokens are claimable.
    function unlockCliff() external view returns (uint256);

    /// @dev Timestamp for the last unlock.
    function unlockEnd() external view returns (uint256);

    /// @dev Mapping from address to locked amounts.
    function lockedAmounts(address address_) external view returns (uint256);

    /// @dev Mapping from address to claimed amounts.
    function claimedAmounts(address address_) external view returns (uint256);

    /// @dev Locked token address.
    function token() external view returns (IERC20);

    /// @dev Transfers tokens from the caller to the token lock contract and locks them for benefit of `recipient`.
    ///      Requires that the caller has authorised this contract with the token contract.
    /// @param recipient The account the tokens will be claimable by.
    /// @param amount The number of tokens to transfer and lock.
    function lock(address recipient, uint256 amount) external;

    /// @dev Claims the caller's tokens that have been unlocked, sending them to `recipient`.
    /// @param recipient The account to transfer unlocked tokens to.
    /// @param amount The amount to transfer. If greater than the claimable amount, the maximum is transferred.
    function claim(address recipient, uint256 amount) external;

    /// @dev Returns the maximum number of tokens currently claimable by `owner`.
    /// @param owner The account to check the claimable balance of.
    /// @return The number of tokens currently claimable.
    function claimableBalance(address owner) external view returns (uint256);
}