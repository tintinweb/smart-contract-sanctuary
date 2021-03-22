/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.7.5;

library Address {
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// ┏━━━┓━┏┓━┏┓━━┏━━━┓━━┏━━━┓━━━━┏━━━┓━━━━━━━━━━━━━━━━━━━┏┓━━━━━┏━━━┓━━━━━━━━━┏┓━━━━━━━━━━━━━━┏┓━
// ┃┏━━┛┏┛┗┓┃┃━━┃┏━┓┃━━┃┏━┓┃━━━━┗┓┏┓┃━━━━━━━━━━━━━━━━━━┏┛┗┓━━━━┃┏━┓┃━━━━━━━━┏┛┗┓━━━━━━━━━━━━┏┛┗┓
// ┃┗━━┓┗┓┏┛┃┗━┓┗┛┏┛┃━━┃┃━┃┃━━━━━┃┃┃┃┏━━┓┏━━┓┏━━┓┏━━┓┏┓┗┓┏┛━━━━┃┃━┗┛┏━━┓┏━┓━┗┓┏┛┏━┓┏━━┓━┏━━┓┗┓┏┛
// ┃┏━━┛━┃┃━┃┏┓┃┏━┛┏┛━━┃┃━┃┃━━━━━┃┃┃┃┃┏┓┃┃┏┓┃┃┏┓┃┃━━┫┣┫━┃┃━━━━━┃┃━┏┓┃┏┓┃┃┏┓┓━┃┃━┃┏┛┗━┓┃━┃┏━┛━┃┃━
// ┃┗━━┓━┃┗┓┃┃┃┃┃┃┗━┓┏┓┃┗━┛┃━━━━┏┛┗┛┃┃┃━┫┃┗┛┃┃┗┛┃┣━━┃┃┃━┃┗┓━━━━┃┗━┛┃┃┗┛┃┃┃┃┃━┃┗┓┃┃━┃┗┛┗┓┃┗━┓━┃┗┓
// ┗━━━┛━┗━┛┗┛┗┛┗━━━┛┗┛┗━━━┛━━━━┗━━━┛┗━━┛┃┏━┛┗━━┛┗━━┛┗┛━┗━┛━━━━┗━━━┛┗━━┛┗┛┗┛━┗━┛┗┛━┗━━━┛┗━━┛━┗━┛
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┃┃━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┗┛━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// SPDX-License-Identifier: CC0-1.0

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * from https://github.com/FriendlyUser/solidity-smart-contracts//blob/v0.2.0/contracts/other/CredVert/Pausable.sol
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Pausable: Contract is paused and requires !paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Pausable: Contract is not paused but requires paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

interface ISharedDeposit {
    function donate(uint256 shares) external payable;
}

interface IBETH {
    function setMinter(address minter_) external;

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint256 rawAmount) external;

    function burn(address src, uint256 rawAmount) external;

    function mintingAllowedAfter() external view returns (uint256);

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool);

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool);
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

contract SharedDeposit is Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint256;
    /* ========== STATE VARIABLES ========== */
    address public constant mainnetDepositContractAddress =
        0x00000000219ab540356cBB839Cbe05303d7705Fa;

    IDepositContract private depositContract;

    uint256 public adminFee;
    uint256 public numValidators;
    uint256 public costPerValidator;

    // The validator shares created by this shared stake contract. 1 share costs >= 1 eth
    uint256 public curValidatorShares; //initialized to 0

    // The number of times the deposit to eth2 contract has been called to create validators
    uint256 public validatorsCreated; //initialized to 0

    // Total accrued admin fee
    uint256 public adminFeeTotal; //initialized to 0

    // Its hard to exactly hit the max deposit amount with small shares. this allows a small bit of overflow room
    // Eth in the buffer cannot be withdrawn by an admin, only by burning the underlying token via a user withdraw
    uint256 public buffer;

    // Flash loan tokenomic protection in case of changes in admin fee with future lots
    bool public disableWithdrawRefund; //initialized to false

    address public BETHTokenAddress;
    IBETH private BETHToken;

    constructor(
        uint256 _numValidators,
        uint256 _adminFee,
        address _BETHTokenAddress
    ) public {
        depositContract = IDepositContract(mainnetDepositContractAddress);

        adminFee = _adminFee; // Admin and infra fees
        numValidators = _numValidators; // The number of validators to create in this lot. Sets a max limit on deposits

        // Eth in the buffer cannot be withdrawn by an admin, only by burning the underlying token
        buffer = uint256(10).mul(1e18); // roughly equal to 10 eth.

        BETHTokenAddress = _BETHTokenAddress;
        BETHToken = IBETH(BETHTokenAddress);

        costPerValidator = uint256(32).mul(1e18).add(adminFee);
    }

    // VIEW FUNCTIONS
    function mintingAllowedAfter() external view returns (uint256) {
        return BETHToken.mintingAllowedAfter();
    }

    function workable() public view returns (bool) {
        // similiar to workable on KP3R contracts
        // used to check if we can call deposit to eth2
        uint256 amount = 32 ether;
        bool validatorLimitReached =
            (curValidatorShares >= maxValidatorShares());
        bool balanceEnough = (address(this).balance >= amount);
        return validatorLimitReached && balanceEnough;
    }

    function maxValidatorShares() public view returns (uint256) {
        return uint256(32).mul(1e18).mul(numValidators);
    }

    function remainingSpaceInEpoch() external view returns (uint256) {
        // Helpful view function to gauge how much the user can send to the contract when it is near full
        uint256 remainingShares =
            (maxValidatorShares()).sub(curValidatorShares);
        uint256 valBeforeAdmin =
            remainingShares.mul(1e18).div(
                uint256(1).mul(1e18).sub(
                    adminFee.mul(1e18).div(costPerValidator)
                )
            );
        return valBeforeAdmin;
    }

    // USER INTERACTIONS
    /*
    Shares minted = Z
    Principal deposit input = P
    AdminFee = a
    costPerValidator = 32 + a
    AdminFee as percent in 1e18 = a% =  (a / costPerValidator) * 1e18
    AdminFee on tx in 1e18 = (P * a% / 1e18)

    on deposit:
    P - (P * a%) = Z

    on withdraw with admin fee refund:
    P = Z / (1 - a%)
    P = Z - Z*a%
    */

    function deposit() external payable nonReentrant whenNotPaused {
        // input is whole, not / 1e18 , i.e. in 1 = 1 eth send when from etherscan
        uint256 value = msg.value;

        uint256 myAdminFee =
            value.mul(adminFee).div(costPerValidator);
        uint256 valMinusAdmin = value.sub(myAdminFee);
        uint256 newShareTotal = curValidatorShares.add(valMinusAdmin);

        require(
            newShareTotal <= buffer.add(maxValidatorShares()),
            "Eth2Staker:deposit:Amount too large, not enough validators left"
        );
        curValidatorShares = newShareTotal;
        adminFeeTotal = adminFeeTotal.add(myAdminFee);
        BETHToken.mint(msg.sender, valMinusAdmin);
    }

    function withdraw(uint256 amount) external nonReentrant whenNotPaused {
        uint256 valBeforeAdmin;
        if (disableWithdrawRefund) {
            valBeforeAdmin = amount;
        } else {
            valBeforeAdmin = amount.mul(1e18).div(
                uint256(1).mul(1e18).sub(
                   adminFee.mul(1e18).div(costPerValidator)
                )
            );
        }
        uint256 newShareTotal = curValidatorShares.sub(amount);
        
        require(
            address(this).balance > amount,
            "Eth2Staker:withdraw:Not enough balance in contract"
        );
        require(
            BETHToken.balanceOf(msg.sender) >= amount,
            "Eth2Staker: Sender balance not enough"
        );

        curValidatorShares = newShareTotal;
        adminFeeTotal = adminFeeTotal.sub(valBeforeAdmin.sub(amount));
        BETHToken.burn(msg.sender, amount);
        address payable sender = msg.sender;
        Address.sendValue(sender, valBeforeAdmin);
    }

    // migration function to accept old monies and copy over state
    // users should not use this as it just donates the money without minting veth or tracking donations
    function donate(uint256 shares) external payable nonReentrant {

    }

    // OWNER ONLY FUNCTIONS

    // Used to migrate state over to new contract
    function migrateShares(uint256 shares) external onlyOwner nonReentrant {
        curValidatorShares = shares;
    }

    // This needs to be called once per validator    
    function depositToEth2(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external onlyOwner nonReentrant {
        uint256 amount = 32 ether;
        require(
            address(this).balance >= amount,
            "Eth2Staker:depositToEth2: Not enough balance"
        ); //need at least 32 ETH

        validatorsCreated = validatorsCreated.add(1);

        depositContract.deposit{value: amount}(
            pubkey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
    }

    function setNumValidators(uint256 _numValidators) external onlyOwner {
        require(_numValidators != 0, "Minimum 1 validator");
        numValidators = _numValidators;
    }

    function toggleWithdrawAdminFeeRefund() external onlyOwner {
        // in case the pool of tokens gets too large it will attract flash loans if the price of the pool token dips below x-admin fee
        // in that case or if the admin fee changes in cases of 1k+ validators
        // we may need to disable the withdraw refund

        // We also need to toggle this on if post migration we want to allow users to withdraw funds
        disableWithdrawRefund = !disableWithdrawRefund;
    }

    // Recover ownership of token supply and mint for upgrading the contract
    // When we want to upgrade this contract the plan is to:
    // - Limit the num validators. This disables deposits when the limit is reached
    // - Create the set of validators trasfering contract value to eth2
    // - Migrate the minter to a new contract
    // - migrate dust in the buffer to the new contract
    function setMinter(address payable minter_)
        external
        onlyOwner
        nonReentrant
    {
        require(minter_ != address(0), "Minter cannot be zero address");
        BETHToken.setMinter(minter_);

        uint256 amount = address(this).balance;
        ISharedDeposit newContract = ISharedDeposit(minter_);
        if (amount > 0) {
            newContract.donate{value: amount}(curValidatorShares);
        }
    }

    function setAdminFee(uint256 amount) external onlyOwner {
        adminFee = amount;
        costPerValidator = uint256(32).mul(1e18).add(adminFee);
    }

    function withdrawAdminFee(uint256 amount) external onlyOwner nonReentrant {
        address payable sender = msg.sender;
        if (amount == 0) {
            amount = adminFeeTotal;
        }
        require(
            amount <= adminFeeTotal,
            "Eth2Staker:withdrawAdminFee: More than adminFeeTotal cannot be withdrawn"
        );
        adminFeeTotal = adminFeeTotal.sub(amount);
        Address.sendValue(sender, amount);
    }
}