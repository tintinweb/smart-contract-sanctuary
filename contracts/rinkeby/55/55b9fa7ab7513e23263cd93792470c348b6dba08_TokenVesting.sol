/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

pragma solidity 0.8.7;

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract TokenVesting is Ownable, ReentrancyGuard {
    struct Vestings {
        bool initiated;
        uint8 periods;
        uint256 initialAmount;
        uint256 startsAt;
        uint256 claimedAmount;
        uint8 claimedPeriods;
    }
    uint256 public totalFunds;
    uint256 public vestedFunds;
    uint256 public unVestedFunds;
    uint256 public claimedFunds;
    uint256 public constant vestingPeriodDuration = 356 days;

    IERC20 immutable vestingToken;
    address public immutable token;

    address[] public beneficiaries;

    mapping(address => Vestings) public vestings;

    constructor(address tokenArg) {
        require(tokenArg != address(0), "Vesting:: token cant be dead address");
        vestingToken = IERC20(tokenArg);
        token = tokenArg;
    }

    function addBeneficiary(
        address beneficiaryArg,
        uint256 amountArg,
        uint8 vestingDurationInYearsArg,
        uint256 startsAtArg
    ) external onlyOwner {
        require(
            !vestings[beneficiaryArg].initiated,
            "Vesting:: holder already have vesting record"
        );
        require(
            beneficiaryArg != address(0),
            "Vesting:: holder cant be dead address"
        );
        require(amountArg > 0, "Vesting:: insufficient amount");

        require(
            startsAtArg >= block.timestamp,
            "Vesting:: must be future date"
        );
        require(
            vestingDurationInYearsArg > 0,
            "VEsting:: vestingDuration cant be null"
        );
        require(
            amountArg <= unVestedFunds,
            "Vesting:: amount exceeded non vested funds"
        );

        beneficiaries.push(beneficiaryArg);

        Vestings memory beneficiaryVesting = Vestings({
            initiated: true,
            periods: vestingDurationInYearsArg,
            initialAmount: amountArg,
            startsAt: startsAtArg,
            claimedAmount: 0,
            claimedPeriods: 0
        });

        vestings[beneficiaryArg] = beneficiaryVesting;

        vestedFunds += amountArg;
        unVestedFunds -= amountArg;
    }

    function addFunds(uint256 amountArg) external onlyOwner returns (uint256) {
        require(amountArg > 0, "Vesting:: amount cant be null");

        vestingToken.transferFrom(_msgSender(), address(this), amountArg);

        totalFunds += amountArg;
        unVestedFunds += amountArg;
        return amountArg;
    }

    function claim()
        external
        nonReentrant
        returns (uint256 claimedTokens, uint8 claimedPeriods)
    {
        address beneficiary = _msgSender();

        (
            uint256 claimableTokens,
            uint8 claimablePeriods
        ) = getBeneficiaryClaimableTokens(beneficiary);

        require(claimableTokens > 0, "Vesting:: tokens not released");
        require(claimablePeriods > 0, "Vesting:: periods not reached");

        vestingToken.transfer(beneficiary, claimableTokens);
        vestings[beneficiary].claimedAmount += claimableTokens;
        vestings[beneficiary].claimedPeriods += claimablePeriods;

        vestedFunds -= claimableTokens;
        claimedFunds += claimableTokens;
        return (claimableTokens, claimablePeriods);
    }

    function getBeneficiaryClaimableTokens(address beneficiaryArg)
        public
        view
        returns (uint256 claimableAmount, uint8 claimablePeriods)
    {
        Vestings memory beneficiaryVesting = vestings[beneficiaryArg];

        uint256 remainingTokens = beneficiaryVesting.initialAmount -
            beneficiaryVesting.claimedAmount;

        // beneficiary already claimed all vested tokens
        if (remainingTokens == 0) {
            return (0, 0);
        }

        uint256 beneficiaryVestedDuration = block.timestamp -
            beneficiaryVesting.startsAt;

        // beneficiary didn't vest for at least 1 year {vestingPeriodDuration}
        if (beneficiaryVestedDuration < vestingPeriodDuration) {
            return (0, 0);
        }

        // beneficiary vesting periods since start, including claimed periods
        uint8 beneficiaryVestedPeriods = uint8(
            beneficiaryVestedDuration / vestingPeriodDuration
        );

        // beneficiary claimable periods, all periods since start excluding claimed ones
        uint8 beneficiaryClaimableVestingPeriods = beneficiaryVestedPeriods -
            beneficiaryVesting.claimedPeriods;

        bool isLastClaim = (beneficiaryClaimableVestingPeriods +
            beneficiaryVesting.claimedPeriods) == beneficiaryVesting.periods;

        // prevent token dusting, allow beneficiary to claim all remaining tokens if all periods are claimable
        if (isLastClaim) {
            return (remainingTokens, beneficiaryClaimableVestingPeriods);
        }

        uint256 beneficiaryClaimableTokensPerPeriod = beneficiaryVesting
            .initialAmount / beneficiaryVesting.periods;

        uint256 beneficiaryClaimableVestingTokens = beneficiaryClaimableTokensPerPeriod *
                beneficiaryClaimableVestingPeriods;

        return (
            beneficiaryClaimableVestingTokens,
            beneficiaryClaimableVestingPeriods
        );
    }
}