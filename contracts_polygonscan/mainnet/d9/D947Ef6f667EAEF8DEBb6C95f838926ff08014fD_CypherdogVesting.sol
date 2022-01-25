/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

/**
 *  SourceUnit: cypherdog/contracts/Vesting.sol
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    Ownership contract
    Modified https://eips.ethereum.org/EIPS/eip-173
    A confirmation of ownership transfer has been added
     to prevent ownership from being transferred to the wrong address
 */
contract Ownable {
    /// Current contract owner
    address public owner;
    /// New contract owner to be confirmed
    address public newOwner;
    /// Emit on every owner change
    event OwnershipChanged(address indexed from, address indexed to);

    /**
        Set default owner as contract deployer
     */
    constructor() {
        owner = msg.sender;
    }

    /**
        Use this modifier to limit function to contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only for Owner");
        _;
    }

    /**
        Prepare to change ownersip. New owner need to confirm it.
        @param user address delegated to be new contract owner
     */
    function giveOwnership(address user) external onlyOwner {
        require(user != address(0x0), "renounceOwnership() instead");
        newOwner = user;
    }

    /**
        Accept contract ownership by new owner.
     */
    function acceptOwnership() external {
        require(
            newOwner != address(0x0) && msg.sender == newOwner,
            "Only newOwner can accept"
        );
        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    /**
        Renounce ownership of the contract.
        Any function uses "onlyOwner" modifier will be inaccessible.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipChanged(owner, address(0x0));
        owner = address(0x0);
    }
}

/**
 *  SourceUnit: cypherdog/contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
    Full ERC20 interface
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
     * ////////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

/**
 *  SourceUnit: cypherdog/contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "./Ownable.sol";

/**
    ERC20 token and native coin recovery functions
 */
abstract contract Recoverable is Ownable {
    error NothingToRecover();

    /// Recover native coin from contract
    function recoverETH() external onlyOwner {
        uint256 amt = address(this).balance;
        if (amt == 0) revert NothingToRecover();
        payable(owner).transfer(amt);
    }

    /// Recover ERC20 token from contract
    function recoverERC20(address token) external virtual onlyOwner {
        uint256 amt = IERC20(token).balanceOf(address(this));
        if (amt == 0) revert NothingToRecover();
        IERC20(token).transfer(owner, amt);
    }
}

/**
 *  SourceUnit: cypherdog/contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
    Minimal interface for future Stake contract
    Functions needed by Vesting contract
 */
interface IStake {
    /// Vesting contract address
    function vestingAddress() external view returns (address);

    /// Function to call by vesting contract
    function claim2stake(address user, uint256 amount) external returns (bool);

    /// Event emited on successfull stake
    event Staked(address indexed user, uint256 amount);
}

/**
 *  SourceUnit: cypherdog/contracts/Vesting.sol
 */

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.10;

////import "./Ownable.sol";
////import "./IERC20.sol";
////import "./IStake.sol";
////import "./Recovery.sol";

/**
    Vesting contract for Cypherdog
    Contract need to be excluded from fees/rewards
 */
contract CypherdogVesting is Ownable, Recoverable {
    /// address of cypher.dog token
    address public immutable tokenAddress;

    /// amount of vested tokens
    uint256 public vested;

    // Vest struct
    struct Vest {
        uint256 startAmount; // tokens that can be claimed at start date
        uint256 totalAmount; // total tokens to be released
        uint256 startDate; // date from which startAmount can be taken
        uint256 endDate; // date to which all totalAmount will be released
        uint256 claimed; // tokens already claimed from this vesting
    }

    // vesting list per user, can be multiple per user
    mapping(address => Vest[]) private _vestings;

    /// Event on creating vesting
    event VestingAdded(
        address indexed user,
        uint256 startAmount,
        uint256 totalAmount,
        uint256 startDate,
        uint256 endDate
    );

    /// event on caliming coins from vesting
    event Claimed(address indexed user, uint256 amount);

    //
    // Error messages
    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();
    error TimestampsMissconfigured();
    error StartDateBelowCurrentTime();
    error NoLocksForUser();
    error NothingToClaim();
    error IndexOutOfRange();

    //
    // constructor
    //
    /**
        Contract constructor
        @param token address to be used in contract
     */
    constructor(address token) {
        tokenAddress = token;
    }

    /**
        Create vesting for user.
        Owner need to approve contract earlier and have tokens on address.
        @param user address of user that can claim from lock
        @param totalAmount total number of coins to be released
        @param startDate timestamp when user can start caliming and get startAmount
        @param endDate timestamp after which totalAmount can be claimed
     */
    function addLock(
        address user,
        uint256 startAmount,
        uint256 totalAmount,
        uint256 startDate,
        uint256 endDate
    ) external {
        if (
            !IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalAmount
            )
        ) revert TransferFailed(); // will fail in token code on error
        if (user == address(0x0)) revert ZeroAddress();
        if (totalAmount == 0) revert ZeroAmount();
        if (startDate > endDate) revert TimestampsMissconfigured();
        if (block.timestamp > startDate) revert StartDateBelowCurrentTime();
        Vest memory c = Vest(startAmount, totalAmount, startDate, endDate, 0);
        _vestings[user].push(c);
        vested += totalAmount;
        emit VestingAdded(user, startAmount, totalAmount, startDate, endDate);
    }

    /**
        Check how much tokens can be claimed at given moment
        @param user address to calculate
        @return sum number of tokens to claim (with 18 decimals)
    */
    function claimable(address user) external view returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        if (len > 0) {
            uint256 i;
            for (i; i < len; i++) {
                sum += _claimable(_vestings[user][i]);
            }
        }
    }

    /**
        Count number of tokens claimable form given vesting
        @param c Vesting struct data
        @return amt number of tokens possible to claim
     */
    function _claimable(Vest memory c) internal view returns (uint256 amt) {
        uint256 time = block.timestamp;
        if (time > c.startDate) {
            if (time > c.endDate) {
                // all coins can be released
                amt = c.totalAmount;
            } else {
                // we need calculate how much can be released
                uint256 pct = ((time - c.startDate) * 1 ether) /
                    (c.endDate - c.startDate);
                amt =
                    c.startAmount +
                    ((c.totalAmount - c.startAmount) * pct) /
                    1 ether;
            }
            amt -= c.claimed; // some may be already claimed
        }
    }

    /**
       Claim all possible tokens
    */
    function claim() external {
        uint256 sum = _claim(msg.sender);
        if (!IERC20(tokenAddress).transfer(msg.sender, sum))
            revert TransferFailed(); // will revert in token on error
    }

    /**
        Internal claim function
        @param user address to calculate
        @return sum number of tokens claimed
     */
    function _claim(address user) internal returns (uint256 sum) {
        uint256 len = _vestings[user].length;
        if (len == 0) revert NoLocksForUser();

        uint256 i;
        for (i; i < len; i++) {
            Vest storage c = _vestings[user][i];
            uint256 amt = _claimable(c);
            c.claimed += amt;
            sum += amt;
        }
        if (sum == 0) revert NothingToClaim();

        vested -= sum;
        emit Claimed(user, sum);
    }

    /**
        All vestings of given address in one call
        @param user address to check
        @return tuple of all locks
     */
    function vestingsOfUser(address user) public view returns (Vest[] memory) {
        return _vestings[user];
    }

    /**
        Check number of vestings for given user
        @param user address to check
        @return number of vestings for user
     */
    function getVestingsCount(address user) external view returns (uint256) {
        return _vestings[user].length;
    }

    /**
        Return single vesting info
        @param user address to check
        @param index of vesting to show
     */
    function getVesting(address user, uint256 index)
        external
        view
        returns (Vest memory)
    {
        if (index >= _vestings[user].length) revert IndexOutOfRange();
        return _vestings[user][index];
    }

    //
    // Stake/Claim2stake
    //
    /// Address of stake contract
    address public stakeAddress;

    error StakeAlreadyConfigured();
    error WrongStakeAddress();
    error TokenApprovalfailed();

    /**
        Set address of stake contract (once, only owner)
        @param stake contract address
     */
    function setStakeAddress(address stake) external onlyOwner {
        if (stakeAddress != address(0)) revert StakeAlreadyConfigured();
        stakeAddress = stake;
        if (IStake(stakeAddress).vestingAddress() != address(this))
            revert WrongStakeAddress();

        if (!IERC20(tokenAddress).approve(stakeAddress, type(uint256).max))
            revert TokenApprovalfailed(); // on error should throw in token
    }

    error StakeContractNotConfigured();
    error Claim2StakeCallFailed();

    /**
        Claim possible tokens and stake directly to contract
     */
    function claim2stake() external {
        if (stakeAddress == address(0)) revert StakeContractNotConfigured();

        uint256 sum = _claim(msg.sender);
        if (!IStake(stakeAddress).claim2stake(msg.sender, sum))
            revert Claim2StakeCallFailed(); // on error should throw in stake contract
    }

    //
    // Token recovery override, disallow vested tokens withdrawal
    //
    function recoverERC20(address token) external override onlyOwner {
        uint256 amt = IERC20(token).balanceOf(address(this));

        if (token == tokenAddress) {
            amt -= vested;
        }
        if (amt == 0) revert ZeroAmount();
        IERC20(token).transfer(owner, amt);
    }

    //
    // Imitate ERC20 token, show unclaimed tokens
    //

    string public constant name = "vested CYPHER.DOG";
    string public constant symbol = "vCDOG";
    uint8 public constant decimals = 18;

    /**
        Read total unclaimed balance for given user
        @param user address to check
        @return amount of unclaimed tokens locked in contract
     */
    function balanceOf(address user) external view returns (uint256 amount) {
        uint256 len = _vestings[user].length;
        if (len > 0) {
            uint256 i;
            for (i; i < len; i++) {
                Vest memory v = _vestings[user][i];
                amount += (v.totalAmount - v.claimed);
            }
        }
    }

    /**
        Imitation of ERC20 transfer() function to claim from wallet.
        Ignoring parameters, returns true if claim succeed.
     */
    function transfer(address, uint256) external returns (bool) {
        uint256 sum = _claim(msg.sender);
        if (!IERC20(tokenAddress).transfer(msg.sender, sum))
            revert TransferFailed(); // on tranfer error will throw in token
        return true;
    }
}