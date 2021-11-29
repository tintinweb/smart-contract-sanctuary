// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Extended.sol";
import "./interfaces/ILockManager.sol";
import "./lib/Initializable.sol";

/**
 * @title EdenNetwork
 * @dev It is VERY IMPORTANT that modifications to this contract do not change the storage layout of the existing variables.  
 * Be especially careful when importing any external contracts/libraries.
 * If you do not know what any of this means, BACK AWAY FROM THE CODE NOW!!
 */
contract EdenNetwork is Initializable {

    /// @notice Slot bid details
    struct Bid {
        address bidder;
        uint16 taxNumerator;
        uint16 taxDenominator;
        uint64 periodStart;
        uint128 bidAmount;
    }

    /// @notice Expiration timestamp of current bid for specified slot index
    mapping (uint8 => uint64) public slotExpiration;
    
    /// @dev Address to be prioritized for given slot
    mapping (uint8 => address) private _slotDelegate;

    /// @dev Address that owns a given slot and is able to set the slot delegate
    mapping (uint8 => address) private _slotOwner;

    /// @notice Current bid for given slot
    mapping (uint8 => Bid) public slotBid;

    /// @notice Staked balance in contract
    mapping (address => uint128) public stakedBalance;

    /// @notice Balance in contract that was previously used for bid
    mapping (address => uint128) public lockedBalance;

    /// @notice Token used to reserve slot
    IERC20Extended public token;

    /// @notice Lock Manager contract
    ILockManager public lockManager;

    /// @notice Admin that can set the contract tax rate
    address public admin;

    /// @notice Numerator for tax rate
    uint16 public taxNumerator;

    /// @notice Denominator for tax rate
    uint16 public taxDenominator;

    /// @notice Minimum bid to reserve slot
    uint128 public MIN_BID;

    /// @dev Reentrancy var used like bool, but with refunds
    uint256 private _NOT_ENTERED;

    /// @dev Reentrancy var used like bool, but with refunds
    uint256 private _ENTERED;

    /// @dev Reentrancy status
    uint256 private _status;

    /// @notice Only admin can call
    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    /// @notice Only slot owner can call
    modifier onlySlotOwner(uint8 slot) {
        require(msg.sender == slotOwner(slot), "not slot owner");
        _;
    }

    /// @notice Reentrancy prevention
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /// @notice Event emitted when admin is updated
    event AdminUpdated(address indexed newAdmin, address indexed oldAdmin);

    /// @notice Event emitted when the tax rate is updated
    event TaxRateUpdated(uint16 newNumerator, uint16 newDenominator, uint16 oldNumerator, uint16 oldDenominator);

    /// @notice Event emitted when slot is claimed
    event SlotClaimed(uint8 indexed slot, address indexed owner, address indexed delegate, uint128 newBidAmount, uint128 oldBidAmount, uint16 taxNumerator, uint16 taxDenominator);
    
    /// @notice Event emitted when slot delegate is updated
    event SlotDelegateUpdated(uint8 indexed slot, address indexed owner, address indexed newDelegate, address oldDelegate);

    /// @notice Event emitted when a user stakes tokens
    event Stake(address indexed staker, uint256 stakeAmount);

    /// @notice Event emitted when a user unstakes tokens
    event Unstake(address indexed staker, uint256 unstakedAmount);

    /// @notice Event emitted when a user withdraws locked tokens
    event Withdraw(address indexed withdrawer, uint256 withdrawalAmount);

    /**
     * @notice Initialize EdenNetwork contract
     * @param _token Token address
     * @param _lockManager Lock Manager address
     * @param _admin Admin address
     * @param _taxNumerator Numerator for tax rate
     * @param _taxDenominator Denominator for tax rate
     */
    function initialize(
        IERC20Extended _token,
        ILockManager _lockManager,
        address _admin,
        uint16 _taxNumerator,
        uint16 _taxDenominator
    ) public initializer {
        token = _token;
        lockManager = _lockManager;
        admin = _admin;
        emit AdminUpdated(_admin, address(0));

        taxNumerator = _taxNumerator;
        taxDenominator = _taxDenominator;
        emit TaxRateUpdated(_taxNumerator, _taxDenominator, 0, 0);

        MIN_BID = 10000000000000000;
        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Get current owner of slot
     * @param slot Slot index
     * @return Slot owner address
     */
    function slotOwner(uint8 slot) public view returns (address) {
        if(slotForeclosed(slot)) {
            return address(0);
        }
        return _slotOwner[slot];
    }

    /**
     * @notice Get current slot delegate
     * @param slot Slot index
     * @return Slot delegate address
     */
    function slotDelegate(uint8 slot) public view returns (address) {
        if(slotForeclosed(slot)) {
            return address(0);
        }
        return _slotDelegate[slot];
    }

    /**
     * @notice Get current cost to claim slot
     * @param slot Slot index
     * @return Slot cost
     */
    function slotCost(uint8 slot) external view returns (uint128) {
        if(slotForeclosed(slot)) {
            return MIN_BID;
        }

        Bid memory currentBid = slotBid[slot];
        return currentBid.bidAmount * 110 / 100;
    }

    /**
     * @notice Claim slot
     * @param slot Slot index
     * @param bid Bid amount
     * @param delegate Delegate for slot
     */
    function claimSlot(
        uint8 slot, 
        uint128 bid, 
        address delegate
    ) external nonReentrant {
        _claimSlot(slot, bid, delegate);
    }

    /**
     * @notice Claim slot using permit for approval
     * @param slot Slot index
     * @param bid Bid amount
     * @param delegate Delegate for slot
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function claimSlotWithPermit(
        uint8 slot, 
        uint128 bid, 
        address delegate, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), bid, deadline, v, r, s);
        _claimSlot(slot, bid, delegate);
    }

    /**
     * @notice Get untaxed balance for current slot bid
     * @param slot Slot index
     * @return balance Slot balance
     */
    function slotBalance(uint8 slot) public view returns (uint128 balance) {
        Bid memory currentBid = slotBid[slot];
        if (currentBid.bidAmount == 0 || slotForeclosed(slot)) {
            return 0;
        } else if (block.timestamp == currentBid.periodStart) {
            return currentBid.bidAmount;
        } else {
            return uint128(uint256(currentBid.bidAmount) - (uint256(currentBid.bidAmount) * (block.timestamp - currentBid.periodStart) * currentBid.taxNumerator / (uint256(currentBid.taxDenominator) * 86400)));
        }
    }

    /**
     * @notice Returns true if a given slot bid has expired
     * @param slot Slot index
     * @return True if slot is foreclosed
     */
    function slotForeclosed(uint8 slot) public view returns (bool) {
        if(slotExpiration[slot] <= block.timestamp) {
            return true;
        }
        return false;
    }

    /**
     * @notice Stake tokens
     * @param amount Amount of tokens to stake
     */
    function stake(uint128 amount) external nonReentrant {
        _stake(msg.sender, amount);
    }

    /**
     * @notice Stake tokens using permit for approval
     * @param amount Amount of tokens to stake
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function stakeWithPermit(
        uint128 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(msg.sender, amount);
    }

    /**
     * @notice Stake tokens on behalf of recipient
     * @param recipient Recipient of staked tokens
     * @param amount Amount of tokens to stake
     */
    function stakeFor(address recipient, uint128 amount) external nonReentrant {
        _stake(recipient, amount);
    }

    /**
     * @notice Stake tokens on behalf of recipient using permit for approval
     * @param recipient Recipient of staked tokens
     * @param amount Amount of tokens to stake
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function stakeForWithPermit(
        address recipient,
        uint128 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(recipient, amount);
    }

    /**
     * @notice Unstake tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint128 amount) external nonReentrant {
        require(stakedBalance[msg.sender] >= amount, "amount > unlocked balance");
        lockManager.removeVotingPower(msg.sender, address(token), amount);
        stakedBalance[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    /**
     * @notice Withdraw locked tokens
     * @param amount Amount of tokens to withdraw
     */
    function withdraw(uint128 amount) external nonReentrant {
        require(lockedBalance[msg.sender] >= amount, "amount > unlocked balance");
        lockedBalance[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Allows slot owners to set a new slot delegate
     * @param slot Slot index
     * @param delegate Delegate address
     */
    function setSlotDelegate(uint8 slot, address delegate) external onlySlotOwner(slot) {
        require(delegate != address(0), "cannot delegate to 0 address");
        emit SlotDelegateUpdated(slot, msg.sender, delegate, slotDelegate(slot));
        _slotDelegate[slot] = delegate;
    }

    /**
     * @notice Set new tax rate
     * @param numerator New tax numerator
     * @param denominator New tax denominator
     */
    function setTaxRate(uint16 numerator, uint16 denominator) external onlyAdmin {
        require(denominator > numerator, "denominator must be > numerator");
        emit TaxRateUpdated(numerator, denominator, taxNumerator, taxDenominator);
        taxNumerator = numerator;
        taxDenominator = denominator;
    }

    /**
     * @notice Set new admin
     * @param newAdmin Nex admin address
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminUpdated(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @notice Internal implementation of claimSlot
     * @param slot Slot index
     * @param bid Bid amount
     * @param delegate Delegate address
     */
    function _claimSlot(uint8 slot, uint128 bid, address delegate) internal {
        require(delegate != address(0), "cannot delegate to 0 address");
        Bid storage currentBid = slotBid[slot];
        uint128 existingBidAmount = currentBid.bidAmount;
        uint128 existingSlotBalance = slotBalance(slot);
        uint128 taxedBalance = existingBidAmount - existingSlotBalance;
        require((existingSlotBalance == 0 && bid >= MIN_BID) || bid >= existingBidAmount * 110 / 100, "bid too small");

        uint128 bidderLockedBalance = lockedBalance[msg.sender];
        uint128 bidIncrement = currentBid.bidder == msg.sender ? bid - existingSlotBalance : bid;
        if (bidderLockedBalance > 0) {
            if (bidderLockedBalance >= bidIncrement) {
                lockedBalance[msg.sender] -= bidIncrement;
            } else {
                lockedBalance[msg.sender] = 0;
                token.transferFrom(msg.sender, address(this), bidIncrement - bidderLockedBalance);
            }
        } else {
            token.transferFrom(msg.sender, address(this), bidIncrement);
        }

        if (currentBid.bidder != msg.sender) {
            lockedBalance[currentBid.bidder] += existingSlotBalance;
        }
        
        if (taxedBalance > 0) {
            token.burn(taxedBalance);
        }

        _slotOwner[slot] = msg.sender;
        _slotDelegate[slot] = delegate;

        currentBid.bidder = msg.sender;
        currentBid.periodStart = uint64(block.timestamp);
        currentBid.bidAmount = bid;
        currentBid.taxNumerator = taxNumerator;
        currentBid.taxDenominator = taxDenominator;

        slotExpiration[slot] = uint64(block.timestamp + uint256(taxDenominator) * 86400 / uint256(taxNumerator));

        emit SlotClaimed(slot, msg.sender, delegate, bid, existingBidAmount, taxNumerator, taxDenominator);
    }

    /**
     * @notice Internal implementation of stake
     * @param amount Amount of tokens to stake
     */
    function _stake(address recipient, uint128 amount) internal {
        token.transferFrom(msg.sender, address(this), amount);
        lockManager.grantVotingPower(recipient, address(token), amount);
        stakedBalance[recipient] += amount;
        emit Stake(recipient, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./IERC20Mintable.sol";
import "./IERC20Burnable.sol";
import "./IERC20Permit.sol";
import "./IERC20TransferWithAuth.sol";
import "./IERC20SafeAllowance.sol";

interface IERC20Extended is 
    IERC20Metadata, 
    IERC20Mintable, 
    IERC20Burnable, 
    IERC20Permit,
    IERC20TransferWithAuth,
    IERC20SafeAllowance 
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address dst, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Permit is IERC20 {
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address) external view returns (uint);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20SafeAllowance is IERC20 {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20TransferWithAuth is IERC20 {
    function transferWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function receiveWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockManager {
    struct LockedStake {
        uint256 amount;
        uint256 votingPower;
    }

    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getStake(address staker, address stakedToken) external view returns (LockedStake memory);
    function calculateVotingPower(address token, uint256 amount) external view returns (uint256);
    function grantVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerGranted);
    function removeVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerRemoved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}