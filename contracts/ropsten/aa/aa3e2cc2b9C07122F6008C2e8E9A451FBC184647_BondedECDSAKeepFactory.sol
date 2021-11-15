/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./BondedECDSAKeep.sol";
import "./KeepBonding.sol";
import "./api/IBondedECDSAKeepFactory.sol";
import "./KeepCreator.sol";
import "./GroupSelectionSeed.sol";
import "./CandidatesPools.sol";

import "@keep-network/sortition-pools/contracts/api/IStaking.sol";
import "@keep-network/sortition-pools/contracts/api/IBonding.sol";
import "@keep-network/sortition-pools/contracts/BondedSortitionPool.sol";
import "@keep-network/sortition-pools/contracts/BondedSortitionPoolFactory.sol";

import {
    AuthorityDelegator,
    TokenStaking
} from "@keep-network/keep-core/contracts/TokenStaking.sol";
import "@keep-network/keep-core/contracts/utils/AddressArrayUtils.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @title Bonded ECDSA Keep Factory
/// @notice Contract creating bonded ECDSA keeps.
/// @dev We avoid redeployment of bonded ECDSA keep contract by using the clone factory.
/// Proxy delegates calls to sortition pool and therefore does not affect contract's
/// state. This means that we only need to deploy the bonded ECDSA keep contract
/// once. The factory provides clean state for every new bonded ECDSA keep clone.
contract BondedECDSAKeepFactory is
    IBondedECDSAKeepFactory,
    KeepCreator,
    AuthorityDelegator,
    GroupSelectionSeed,
    CandidatesPools
{
    using AddressArrayUtils for address[];
    using SafeMath for uint256;

    // Notification that a new keep has been created.
    event BondedECDSAKeepCreated(
        address indexed keepAddress,
        address[] members,
        address indexed owner,
        address indexed application,
        uint256 honestThreshold
    );

    BondedSortitionPoolFactory sortitionPoolFactory;
    TokenStaking tokenStaking;
    KeepBonding keepBonding;

    // Sortition pool is created with a minimum bond of 20 ETH to avoid
    // small operators joining and griefing future selections before the
    // minimum bond is set to the right value by the application.
    //
    // Anyone can create a sortition pool for an application with the default
    // minimum bond value but the application can change this value later, at
    // any point.
    uint256 public constant minimumBond = 20e18; // 20 ETH

    // Signer candidates in bonded sortition pool are weighted by their eligible
    // stake divided by a constant divisor. The divisor is set to 1 KEEP so that
    // all KEEPs in eligible stake matter when calculating operator's eligible
    // weight for signer selection.
    uint256 public constant poolStakeWeightDivisor = 1e18;

    constructor(
        address _masterBondedECDSAKeepAddress,
        address _sortitionPoolFactory,
        address _tokenStaking,
        address _keepBonding,
        address _randomBeacon
    )
        public
        KeepCreator(_masterBondedECDSAKeepAddress)
        GroupSelectionSeed(_randomBeacon)
    {
        sortitionPoolFactory = BondedSortitionPoolFactory(
            _sortitionPoolFactory
        );
        tokenStaking = TokenStaking(_tokenStaking);
        keepBonding = KeepBonding(_keepBonding);
    }

    /// @notice Sets the minimum bondable value required from the operator to
    /// join the sortition pool of the given application. It is up to the
    /// application to specify a reasonable minimum bond for operators trying to
    /// join the pool to prevent griefing by operators joining without enough
    /// bondable value.
    /// @param _minimumBondableValue The minimum bond value the application
    /// requires from a single keep.
    /// @param _groupSize Number of signers in the keep.
    /// @param _honestThreshold Minimum number of honest keep signers.
    function setMinimumBondableValue(
        uint256 _minimumBondableValue,
        uint256 _groupSize,
        uint256 _honestThreshold
    ) external {
        uint256 memberBond = bondPerMember(_minimumBondableValue, _groupSize);
        BondedSortitionPool(getSortitionPool(msg.sender))
            .setMinimumBondableValue(memberBond);
    }

    /// @notice Opens a new ECDSA keep.
    /// @dev Selects a list of signers for the keep based on provided parameters.
    /// A caller of this function is expected to be an application for which
    /// member candidates were registered in a pool.
    /// @param _groupSize Number of signers in the keep.
    /// @param _honestThreshold Minimum number of honest keep signers.
    /// @param _owner Address of the keep owner.
    /// @param _bond Value of ETH bond required from the keep in wei.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    /// @return Created keep address.
    function openKeep(
        uint256 _groupSize,
        uint256 _honestThreshold,
        address _owner,
        uint256 _bond,
        uint256 _stakeLockDuration
    ) external payable nonReentrant returns (address keepAddress) {
        require(_groupSize > 0, "Minimum signing group size is 1");
        require(_groupSize <= 16, "Maximum signing group size is 16");
        require(
            _honestThreshold > 0,
            "Honest threshold must be greater than 0"
        );
        require(
            _honestThreshold <= _groupSize,
            "Honest threshold must be less or equal the group size"
        );

        address application = msg.sender;
        address pool = getSortitionPool(application);

        uint256 memberBond = bondPerMember(_bond, _groupSize);
        require(memberBond > 0, "Bond per member must be greater than zero");

        require(
            msg.value >= openKeepFeeEstimate(),
            "Insufficient payment for opening a new keep"
        );

        uint256 minimumStake = tokenStaking.minimumStake();

        address[] memory members =
            BondedSortitionPool(pool).selectSetGroup(
                _groupSize,
                bytes32(groupSelectionSeed),
                minimumStake,
                memberBond
            );

        newGroupSelectionSeed();

        // createKeep sets keepOpenedTimestamp value for newly created keep which
        // is required to be set before calling `keep.initialize` function as it
        // is used to determine token staking delegation authority recognition
        // in `__isRecognized` function.
        keepAddress = createKeep();

        BondedECDSAKeep(keepAddress).initialize(
            _owner,
            members,
            _honestThreshold,
            minimumStake,
            _stakeLockDuration,
            address(tokenStaking),
            address(keepBonding),
            address(this)
        );

        for (uint256 i = 0; i < _groupSize; i++) {
            keepBonding.createBond(
                members[i],
                keepAddress,
                uint256(keepAddress),
                memberBond,
                pool
            );
        }

        emit BondedECDSAKeepCreated(
            keepAddress,
            members,
            _owner,
            application,
            _honestThreshold
        );
    }

    /// @notice Verifies if delegates authority recipient is valid address recognized
    /// by the factory for token staking authority delegation.
    /// @param _delegatedAuthorityRecipient Address of the delegated authority
    /// recipient.
    /// @return True if provided address is recognized delegated token staking
    /// authority for this factory contract.
    function __isRecognized(address _delegatedAuthorityRecipient)
        external
        returns (bool)
    {
        return keepOpenedTimestamp[_delegatedAuthorityRecipient] > 0;
    }

    /// @notice Gets a fee estimate for opening a new keep.
    /// @return Uint256 estimate.
    function openKeepFeeEstimate() public view returns (uint256) {
        return newEntryFeeEstimate();
    }

    /// @notice Checks if the specified account has enough active stake to become
    /// network operator and that this contract has been authorized for potential
    /// slashing.
    ///
    /// Having the required minimum of active stake makes the operator eligible
    /// to join the network. If the active stake is not currently undelegating,
    /// operator is also eligible for work selection.
    ///
    /// @param _operator operator's address
    /// @return True if has enough active stake to participate in the network,
    /// false otherwise.
    function hasMinimumStake(address _operator) public view returns (bool) {
        return tokenStaking.hasMinimumStake(_operator, address(this));
    }

    /// @notice Checks if the factory has the authorization to operate on stake
    /// represented by the provided operator.
    ///
    /// @param _operator operator's address
    /// @return True if the factory has access to the staked token balance of
    /// the provided operator and can slash that stake. False otherwise.
    function isOperatorAuthorized(address _operator)
        public
        view
        returns (bool)
    {
        return tokenStaking.isAuthorizedForOperator(_operator, address(this));
    }

    /// @notice Gets the stake balance of the specified operator.
    /// @param _operator The operator to query the balance of.
    /// @return An uint256 representing the amount staked by the passed operator.
    function balanceOf(address _operator) public view returns (uint256) {
        return tokenStaking.balanceOf(_operator);
    }

    function newSortitionPool(address _application) internal returns (address) {
        return
            sortitionPoolFactory.createSortitionPool(
                IStaking(address(tokenStaking)),
                IBonding(address(keepBonding)),
                tokenStaking.minimumStake(),
                minimumBond,
                poolStakeWeightDivisor
            );
    }

    /// @notice Calculates bond requirement per member performing the necessary
    /// rounding.
    /// @param _keepBond The bond required from a keep.
    /// @param _groupSize Number of signers in the keep.
    /// @return Bond value required from each keep member.
    function bondPerMember(uint256 _keepBond, uint256 _groupSize)
        internal
        pure
        returns (uint256)
    {
        // In Solidity, division rounds towards zero (down) and dividing
        // '_bond' by '_groupSize' can leave a remainder. Even though, a remainder
        // is very small, we want to avoid this from happening and memberBond is
        // rounded up by: `(bond + groupSize - 1 ) / groupSize`
        // Ex. (100 + 3 - 1) / 3 = 34
        return (_keepBond.add(_groupSize).sub(1)).div(_groupSize);
    }
}

pragma solidity ^0.5.0;

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

    constructor () internal {
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
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./ERC20.sol";

/**
 * @dev Extension of `ERC20` that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev See `ERC20._burnFrom`.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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

pragma solidity 0.5.17;

interface IStaking {
    // Gives the amount of KEEP tokens staked by the `operator`
    // eligible for work selection in the specified `operatorContract`.
    //
    // If the operator doesn't exist or hasn't finished initializing,
    // or the operator contract hasn't been authorized for the operator,
    // returns 0.
    function eligibleStake(
        address operator,
        address operatorContract
    ) external view returns (uint256);
}

pragma solidity 0.5.17;

interface IBonding {
    // Gives the amount of ETH
    // the `operator` has made available for bonding by the `bondCreator`.
    // If the operator doesn't exist,
    // or the bond creator isn't authorized,
    // returns 0.
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address authorizedSortitionPool
    ) external view returns (uint256);
}

pragma solidity 0.5.17;

library StackLib {
  function stackPeek(uint256[] storage _array) internal view returns (uint256) {
    require(_array.length > 0, "No value to peek, array is empty");
    return (_array[_array.length - 1]);
  }

  function stackPush(uint256[] storage _array, uint256 _element) public {
    _array.push(_element);
  }

  function stackPop(uint256[] storage _array) internal returns (uint256) {
    require(_array.length > 0, "No value to pop, array is empty");
    uint256 value = _array[_array.length - 1];
    _array.length -= 1;
    return value;
  }

  function getSize(uint256[] storage _array) internal view returns (uint256) {
    return _array.length;
  }
}

pragma solidity 0.5.17;

import "./StackLib.sol";
import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";

contract SortitionTree {
  using StackLib for uint256[];
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 constant POOL_CAPACITY = SLOT_COUNT**LEVELS;
  ////////////////////////////////////////////////////////////////////////////

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 root;
  mapping(uint256 => mapping(uint256 => uint256)) branches;
  mapping(uint256 => uint256) leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 rightmostLeaf;
  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] emptyLeaves;

  constructor() public {
    root = 0;
    rightmostLeaf = 0;
  }

  // checks if operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Sum the number of operators in each trunk
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.getSize();

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  function insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, weight);

    root = setLeaf(position, theLeaf, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  function removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    updateLeaf(unflaggedPosition, weight);
  }

  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    uint256 newRoot = setLeaf(position, 0, _root);

    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.stackPush(position);
    }
    return newRoot;
  }

  function updateLeaf(uint256 position, uint256 weight) internal {
    uint256 oldLeaf = leaves[position];
    if (oldLeaf.weight() != weight) {
      uint256 newLeaf = oldLeaf.setWeight(weight);
      root = setLeaf(position, newLeaf, root);
    }
  }

  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = theLeaf.weight();

    // set leaf
    leaves[position] = theLeaf;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition, uint256 leafFirstIndex)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
    // get the first index of the leaf
    // This works because the last weight returned from `pickWeightedSlot()`
    // equals the "overflow" from getting the current slot.
    leafFirstIndex = index - currentIndex;
  }

  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      bool emptyLeavesInStack = leavesInStack();
      require(emptyLeavesInStack, "Pool is full");
      return emptyLeaves.stackPop();
    }
  }

  function leavesInStack() internal view returns (bool) {
    return emptyLeaves.getSize() > 0;
  }
}

pragma solidity 0.5.17;

import "./Leaf.sol";
import "./Interval.sol";
import "./DynamicArray.sol";

library RNG {
  using DynamicArray for DynamicArray.UintArray;
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant WEIGHT_WIDTH = 256 / SLOT_COUNT;
  ////////////////////////////////////////////////////////////////////////////

  struct State {
    // RNG output
    uint256 currentMappedIndex;
    uint256 currentTruncatedIndex;
    // The random bytes used to derive indices
    bytes32 currentSeed;
    // The full range of indices;
    // generated random numbers are in [0, fullRange).
    uint256 fullRange;
    // The truncated range of indices;
    // how many non-skipped indices are left to consider.
    // Random indices are generated within this range,
    // and mapped to the full range by skipping the specified intervals.
    uint256 truncatedRange;
    DynamicArray.UintArray skippedIntervals;
  }

  function initialize(
    bytes32 seed,
    uint256 range,
    uint256 expectedSkippedCount
  ) internal view returns (State memory self) {
    self = State(
      0,
      0,
      seed,
      range,
      range,
      DynamicArray.uintArray(expectedSkippedCount)
    );
    reseed(self, seed, 0);
    return self;
  }

  function reseed(
    State memory self,
    bytes32 seed,
    uint256 nonce
  ) internal view {
    self.currentSeed = keccak256(
      abi.encodePacked(seed, nonce, address(this), "reseed")
    );
  }

  function retryIndex(State memory self) internal view {
    uint256 truncatedIndex = self.currentTruncatedIndex;
    if (self.currentTruncatedIndex < self.truncatedRange) {
      self.currentMappedIndex = Interval.skip(
        truncatedIndex,
        self.skippedIntervals
      );
    } else {
      generateNewIndex(self);
    }
  }

  function updateInterval(
    State memory self,
    uint256 startIndex,
    uint256 oldWeight,
    uint256 newWeight
  ) internal pure {
    int256 weightDiff = int256(newWeight) - int256(oldWeight);
    uint256 effectiveStartIndex = startIndex + newWeight;
    self.truncatedRange = uint256(int256(self.truncatedRange) + weightDiff);
    self.fullRange = uint256(int256(self.fullRange) + weightDiff);
    Interval.remapIndices(
      effectiveStartIndex,
      weightDiff,
      self.skippedIntervals
    );
  }

  function addSkippedInterval(
    State memory self,
    uint256 startIndex,
    uint256 weight
  ) internal pure {
    self.truncatedRange -= weight;
    Interval.insert(self.skippedIntervals, Interval.make(startIndex, weight));
  }

  /// @notice Generate a new index based on the current seed,
  /// without reseeding first.
  /// This will result in the same truncated index as before
  /// if it still fits in the current truncated range.
  function generateNewIndex(State memory self) internal view {
    uint256 _truncatedRange = self.truncatedRange;
    require(_truncatedRange > 0, "Not enough operators in pool");
    uint256 bits = bitsRequired(_truncatedRange);
    uint256 truncatedIndex = truncate(bits, uint256(self.currentSeed));
    while (truncatedIndex >= _truncatedRange) {
      self.currentSeed = keccak256(
        abi.encodePacked(self.currentSeed, address(this), "generate")
      );
      truncatedIndex = truncate(bits, uint256(self.currentSeed));
    }
    self.currentTruncatedIndex = truncatedIndex;
    self.currentMappedIndex = Interval.skip(
      truncatedIndex,
      self.skippedIntervals
    );
  }

  /// @notice Calculate how many bits are required
  /// for an index in the range `[0 .. range-1]`.
  ///
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    uint256 bits = WEIGHT_WIDTH - 1;

    // Left shift by `bits`,
    // so we have a 1 in the (bits + 1)th least significant bit
    // and 0 in other bits.
    // If this number is equal or greater than `range`,
    // the range [0, range-1] fits in `bits` bits.
    //
    // Because we loop from high bits to low bits,
    // we find the highest number of bits that doesn't fit the range,
    // and return that number + 1.
    while (1 << bits >= range) {
      bits--;
    }

    return bits + 1;
  }

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint256 bits, uint256 input)
    internal
    pure
    returns (uint256)
  {
    return input & ((1 << bits) - 1);
  }

  /// @notice Get an index in the range `[0 .. range-1]`
  /// and the new state of the RNG,
  /// using the provided `state` of the RNG.
  ///
  /// @param range The upper bound of the index, exclusive.
  ///
  /// @param state The previous state of the RNG.
  /// The initial state needs to be obtained
  /// from a trusted randomness oracle (the random beacon),
  /// or from a chain of earlier calls to `RNG.getIndex()`
  /// on an originally trusted seed.
  ///
  /// @dev Calculates the number of bits required for the desired range,
  /// takes the least significant bits of `state`
  /// and checks if the obtained index is within the desired range.
  /// The original state is hashed with `keccak256` to get a new state.
  /// If the index is outside the range,
  /// the function retries until it gets a suitable index.
  ///
  /// @return index A random integer between `0` and `range - 1`, inclusive.
  ///
  /// @return newState The new state of the RNG.
  /// When `getIndex()` is called one or more times,
  /// care must be taken to always use the output `state`
  /// of the most recent call as the input `state` of a subsequent call.
  /// At the end of a transaction calling `RNG.getIndex()`,
  /// the previous stored state must be overwritten with the latest output.
  function getIndex(uint256 range, bytes32 state)
    internal
    view
    returns (uint256, bytes32)
  {
    uint256 bits = bitsRequired(range);
    bool found = false;
    uint256 index = 0;
    bytes32 newState = state;
    while (!found) {
      index = truncate(bits, uint256(newState));
      newState = keccak256(abi.encodePacked(newState, address(this)));
      if (index < range) {
        found = true;
      }
    }
    return (index, newState);
  }

  /// @notice Return an index corresponding to a new, unique leaf.
  ///
  /// @dev Gets a new index in a truncated range
  /// with the weights of all previously selected leaves subtracted.
  /// This index is then mapped to the full range of possible indices,
  /// skipping the ranges covered by previous leaves.
  ///
  /// @param range The full range in which the unique index should be.
  ///
  /// @param state The RNG state.
  ///
  /// @param previousLeaves List of indices and weights
  /// corresponding to the _first_ index of each previously selected leaf,
  /// and the weight of the same leaf.
  /// An index number `i` is a starting index of leaf `o`
  /// if querying for index `i` in the sortition pool returns `o`,
  /// but querying for `i-1` returns a different leaf.
  /// This list REALLY needs to be sorted from smallest to largest.
  ///
  /// @param sumPreviousWeights The sum of the weights of previous leaves.
  /// Could be calculated from `previousLeafWeights`
  /// but providing it explicitly makes the function a bit simpler.
  ///
  /// @return uniqueIndex An index in [0, range) that does not overlap
  /// any of the previousLeaves,
  /// as determined by the range [index, index + weight).
  function getUniqueIndex(
    uint256 range,
    bytes32 state,
    uint256[] memory previousLeaves,
    uint256 sumPreviousWeights
  ) internal view returns (uint256 uniqueIndex, bytes32 newState) {
    // Get an index in the truncated range.
    // The truncated range covers only new leaves,
    // but has to be mapped to the actual range of indices.
    uint256 truncatedRange = range - sumPreviousWeights;
    uint256 truncatedIndex;
    (truncatedIndex, newState) = getIndex(truncatedRange, state);

    // Map the truncated index to the available unique indices.
    uniqueIndex = Interval.skip(
      truncatedIndex,
      DynamicArray.convert(previousLeaves)
    );

    return (uniqueIndex, newState);
  }
}

pragma solidity 0.5.17;

library Position {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_POINTER_MAX = (2**SLOT_BITS) - 1;
  uint256 constant LEAF_FLAG = 1 << 255;

  ////////////////////////////////////////////////////////////////////////////

  // Return the last 3 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint256 a) internal pure returns (uint256) {
    return a & SLOT_POINTER_MAX;
  }

  // Return the parent of a position number
  function parent(uint256 a) internal pure returns (uint256) {
    return a >> SLOT_BITS;
  }

  // Return the location of the child of a at the given slot
  function child(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a << SLOT_BITS) | (s & SLOT_POINTER_MAX); // slot(s)
  }

  // Return the uint p as a flagged position uint:
  // the least significant 21 bits contain the position
  // and the 22nd bit is set as a flag
  // to distinguish the position 0x000000 from an empty field.
  function setFlag(uint256 p) internal pure returns (uint256) {
    return p | LEAF_FLAG;
  }

  // Turn a flagged position into an unflagged position
  // by removing the flag at the 22nd least significant bit.
  //
  // We shouldn't _actually_ need this
  // as all position-manipulating code should ignore non-position bits anyway
  // but it's cheap to call so might as well do it.
  function unsetFlag(uint256 p) internal pure returns (uint256) {
    return p & (~LEAF_FLAG);
  }
}

pragma solidity 0.5.17;

library Leaf {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

  uint256 constant WEIGHT_WIDTH = SLOT_WIDTH;
  uint256 constant WEIGHT_MAX = SLOT_MAX;

  uint256 constant BLOCKHEIGHT_WIDTH = 96 - WEIGHT_WIDTH;
  uint256 constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

  ////////////////////////////////////////////////////////////////////////////

  function make(
    address _operator,
    uint256 _creationBlock,
    uint256 _weight
  ) internal pure returns (uint256) {
    // Converting a bytesX type into a larger type
    // adds zero bytes on the right.
    uint256 op = uint256(bytes32(bytes20(_operator)));
    // Bitwise AND the weight to erase
    // all but the 32 least significant bits
    uint256 wt = _weight & WEIGHT_MAX;
    // Erase all but the 64 least significant bits,
    // then shift left by 32 bits to make room for the weight
    uint256 cb = (_creationBlock & BLOCKHEIGHT_MAX) << WEIGHT_WIDTH;
    // Bitwise OR them all together to get
    // [address operator || uint64 creationBlock || uint32 weight]
    return (op | cb | wt);
  }

  function operator(uint256 leaf) internal pure returns (address) {
    // Converting a bytesX type into a smaller type
    // truncates it on the right.
    return address(bytes20(bytes32(leaf)));
  }

  /// @notice Return the block number the leaf was created in.
  function creationBlock(uint256 leaf) internal pure returns (uint256) {
    return ((leaf >> WEIGHT_WIDTH) & BLOCKHEIGHT_MAX);
  }

  function weight(uint256 leaf) internal pure returns (uint256) {
    // Weight is stored in the 32 least significant bits.
    // Bitwise AND ensures that we only get the contents of those bits.
    return (leaf & WEIGHT_MAX);
  }

  function setWeight(uint256 leaf, uint256 newWeight)
    internal
    pure
    returns (uint256)
  {
    return ((leaf & ~WEIGHT_MAX) | (newWeight & WEIGHT_MAX));
  }
}

pragma solidity 0.5.17;

import "./Leaf.sol";
import "./DynamicArray.sol";

library Interval {
  using DynamicArray for DynamicArray.UintArray;
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

  uint256 constant WEIGHT_WIDTH = SLOT_WIDTH;
  uint256 constant WEIGHT_MAX = SLOT_MAX;

  uint256 constant START_INDEX_WIDTH = WEIGHT_WIDTH;
  uint256 constant START_INDEX_MAX = WEIGHT_MAX;
  uint256 constant START_INDEX_SHIFT = WEIGHT_WIDTH;

  ////////////////////////////////////////////////////////////////////////////

  // Interval stores information about a selected interval
  // inside a single uint256 in a manner similar to Leaf
  // but optimized for use within group selection
  //
  // The information stored consists of:
  // - weight
  // - starting index

  function make(uint256 startingIndex, uint256 weight)
    internal
    pure
    returns (uint256)
  {
    uint256 idx = (startingIndex & START_INDEX_MAX) << START_INDEX_SHIFT;
    uint256 wt = weight & WEIGHT_MAX;
    return (idx | wt);
  }

  function opWeight(uint256 op) internal pure returns (uint256) {
    return (op & WEIGHT_MAX);
  }

  // Return the starting index of the interval
  function index(uint256 a) internal pure returns (uint256) {
    return ((a >> WEIGHT_WIDTH) & START_INDEX_MAX);
  }

  function setIndex(uint256 op, uint256 i) internal pure returns (uint256) {
    uint256 shiftedIndex = ((i & START_INDEX_MAX) << WEIGHT_WIDTH);
    return (op & (~(START_INDEX_MAX << WEIGHT_WIDTH))) | shiftedIndex;
  }

  function insert(DynamicArray.UintArray memory intervals, uint256 interval)
    internal
    pure
  {
    uint256 tempInterval = interval;
    for (uint256 i = 0; i < intervals.array.length; i++) {
      uint256 thisInterval = intervals.array[i];
      // We can compare the raw underlying uint256 values
      // because the starting index is stored
      // in the most significant nonzero bits.
      if (tempInterval < thisInterval) {
        intervals.array[i] = tempInterval;
        tempInterval = thisInterval;
      }
    }
    intervals.arrayPush(tempInterval);
  }

  function skip(uint256 truncatedIndex, DynamicArray.UintArray memory intervals)
    internal
    pure
    returns (uint256 mappedIndex)
  {
    mappedIndex = truncatedIndex;
    for (uint256 i = 0; i < intervals.array.length; i++) {
      uint256 interval = intervals.array[i];
      // If the index is greater than the starting index of the `i`th leaf,
      // we need to skip that leaf.
      if (mappedIndex >= index(interval)) {
        // Add the weight of this previous leaf to the index,
        // ensuring that we skip the leaf.
        mappedIndex += Leaf.weight(interval);
      } else {
        break;
      }
    }
    return mappedIndex;
  }

  /// @notice Recalculate the starting indices of the previousLeaves
  /// when an interval is removed or added at the specified index.
  /// @dev Applies weightDiff to each starting index in previousLeaves
  /// that exceeds affectedStartingIndex.
  /// @param affectedStartingIndex The starting index of the interval.
  /// @param weightDiff The difference in weight;
  /// negative for a deleted interval,
  /// positive for an added interval.
  /// @param previousLeaves The starting indices and weights
  /// of the previously selected leaves.
  /// @return The starting indices of the previous leaves
  /// in a tree with the affected interval updated.
  function remapIndices(
    uint256 affectedStartingIndex,
    int256 weightDiff,
    DynamicArray.UintArray memory previousLeaves
  ) internal pure {
    uint256 nPreviousLeaves = previousLeaves.array.length;

    for (uint256 i = 0; i < nPreviousLeaves; i++) {
      uint256 interval = previousLeaves.array[i];
      uint256 startingIndex = index(interval);
      // If index is greater than the index of the affected interval,
      // update the starting index by the weight change.
      if (startingIndex > affectedStartingIndex) {
        uint256 newIndex = uint256(int256(startingIndex) + weightDiff);
        previousLeaves.array[i] = setIndex(interval, newIndex);
      }
    }
  }
}

pragma solidity 0.5.17;

contract GasStation {
  mapping(address => mapping(uint256 => uint256)) gasDeposits;

  function depositGas(address addr) internal {
    setDeposit(addr, 1);
  }

  function releaseGas(address addr) internal {
    setDeposit(addr, 0);
  }

  function setDeposit(address addr, uint256 val) internal {
    for (uint256 i = 0; i < gasDepositSize(); i++) {
      gasDeposits[addr][i] = val;
    }
  }

  function gasDepositSize() internal pure returns (uint256);
}

pragma solidity 0.5.17;

library DynamicArray {
  // The in-memory dynamic Array is implemented
  // by recording the amount of allocated memory
  // separately from the length of the array.
  // This gives us a perfectly normal in-memory array
  // with all the behavior we're used to,
  // but also makes O(1) `push` operations possible
  // by expanding into the preallocated memory.
  //
  // When we run out of preallocated memory when trying to `push`,
  // we allocate twice as much and copy the array over.
  // With linear allocation costs this would amortize to O(1)
  // but with EVM allocations being actually quadratic
  // the real performance is a very technical O(N).
  // Nonetheless, this is reasonably performant in practice.
  //
  // A dynamic array can be useful
  // even when you aren't dealing with an unknown number of items.
  // Because the array tracks the allocated space
  // separately from the number of stored items,
  // you can push items into the dynamic array
  // and iterate over the currently present items
  // without tracking their number yourself,
  // or using a special null value for empty elements.
  //
  // Because Solidity doesn't really have useful safety features,
  // only enough superficial inconveniences
  // to lull yourself into a false sense of security,
  // dynamic arrays require a bit of care to handle appropriately.
  //
  // First of all,
  // dynamic arrays must not be created or modified manually.
  // Use `uintArray(length)`, or `convert(existingArray)`
  // which will perform a safe and efficient conversion for you.
  // This also applies to storage;
  // in-memory dynamic arrays are for efficient in-memory operations only,
  // and it is unnecessary to store dynamic arrays.
  // Use a regular `uint256[]` instead.
  // The contents of `array` may be written like `dynamicArray.array[i] = x`
  // but never reassign the `array` pointer itself
  // nor mess with `allocatedMemory` in any way whatsoever.
  // If you fail to follow these precautions,
  // dragons inhabiting the no-man's-land
  // between the array as it's seen by Solidity
  // and the next thing allocated after it
  // will be unleashed to wreak havoc upon your memory buffers.
  //
  // Second,
  // because the `array` may be reassigned when pushing,
  // the following pattern is unsafe:
  // ```
  // UintArray dynamicArray;
  // uint256 len = dynamicArray.array.length;
  // uint256[] danglingPointer = dynamicArray.array;
  // danglingPointer[0] = x;
  // dynamicArray.push(y);
  // danglingPointer[0] = z;
  // uint256 surprise = danglingPointer[len];
  // ```
  // After the above code block,
  // `dynamicArray.array[0]` may be either `x` or `z`,
  // and `surprise` may be `y` or out of bounds.
  // This will not share your address space with a malevolent agent of chaos,
  // but it will cause entirely avoidable scratchings of the head.
  //
  // Dynamic arrays should be safe to use like ordinary arrays
  // if you always refer to the array field of the dynamic array
  // when reading or writing values:
  // ```
  // UintArray dynamicArray;
  // uint256 len = dynamicArray.array.length;
  // dynamicArray.array[0] = x;
  // dynamicArray.push(y);
  // dynamicArray.array[0] = z;
  // uint256 notSurprise = dynamicArray.array[len];
  // ```
  // After this code `notSurprise` is reliably `y`,
  // and `dynamicArray.array[0]` is `z`.
  struct UintArray {
    // XXX: Do not modify this value.
    // In fact, do not even read it.
    // There is never a legitimate reason to do anything with this value.
    // She is quiet and wishes to be left alone.
    // The silent vigil of `allocatedMemory`
    // is the only thing standing between your contract
    // and complete chaos in its memory.
    // Respect her wish or face the monstrosities she is keeping at bay.
    uint256 allocatedMemory;
    // Unlike her sharp and vengeful sister,
    // `array` is safe to use normally
    // for anything you might do with a normal `uint256[]`.
    // Reads and loops will check bounds,
    // and writing in individual indices like `myArray.array[i] = x`
    // is perfectly fine.
    // No curse will befall you as long as you obey this rule:
    //
    // XXX: Never try to replace her or separate her from her sister
    // by writing down the accursed words
    // `myArray.array = anotherArray` or `lonelyArray = myArray.array`.
    //
    // If you do, your cattle will be diseased,
    // your children will be led astray in the woods,
    // and your memory will be silently overwritten.
    // Instead, give her a friend with
    // `mySecondArray = convert(anotherArray)`,
    // and call her by her family name first.
    // She will recognize your respect
    // and ward your memory against corruption.
    uint256[] array;
  }

  struct AddressArray {
    uint256 allocatedMemory;
    address[] array;
  }

  /// @notice Create an empty dynamic array,
  /// with preallocated memory for up to `length` elements.
  /// @dev Knowing or estimating the preallocated length in advance
  /// helps avoid frequent early allocations when filling the array.
  /// @param length The number of items to preallocate space for.
  /// @return A new dynamic array.
  function uintArray(uint256 length) internal pure returns (UintArray memory) {
    uint256[] memory array = _allocateUints(length);
    return UintArray(length, array);
  }

  function addressArray(uint256 length)
    internal
    pure
    returns (AddressArray memory)
  {
    address[] memory array = _allocateAddresses(length);
    return AddressArray(length, array);
  }

  /// @notice Convert an existing non-dynamic array into a dynamic array.
  /// @dev The dynamic array is created
  /// with allocated memory equal to the length of the array.
  /// @param array The array to convert.
  /// @return A new dynamic array,
  /// containing the contents of the argument `array`.
  function convert(uint256[] memory array)
    internal
    pure
    returns (UintArray memory)
  {
    return UintArray(array.length, array);
  }

  function convert(address[] memory array)
    internal
    pure
    returns (AddressArray memory)
  {
    return AddressArray(array.length, array);
  }

  /// @notice Push `item` into the dynamic array.
  /// @dev This function will be safe
  /// as long as you haven't scorned either of the sisters.
  /// If you have, the dragons will be released
  /// to wreak havoc upon your memory.
  /// A spell to dispel the curse exists,
  /// but a sacred vow prohibits it from being shared
  /// with those who do not know how to discover it on their own.
  /// @param self The dynamic array to push into;
  /// after the call it will be mutated in place to contain the item,
  /// allocating more memory behind the scenes if necessary.
  /// @param item The item you wish to push into the array.
  function arrayPush(UintArray memory self, uint256 item) internal pure {
    uint256 length = self.array.length;
    uint256 allocLength = self.allocatedMemory;
    // The dynamic array is full so we need to allocate more first.
    // We check for >= instead of ==
    // so that we can put the require inside the conditional,
    // reducing the gas costs of `push` slightly.
    if (length >= allocLength) {
      // This should never happen if `allocatedMemory` isn't messed with.
      require(length == allocLength, "Array length exceeds allocation");
      // Allocate twice the original array length,
      // then copy the contents over.
      uint256 newMemory = length * 2;
      uint256[] memory newArray = _allocateUints(newMemory);
      _copy(newArray, self.array);
      self.array = newArray;
      self.allocatedMemory = newMemory;
    }
    // We have enough free memory so we can push into the array.
    _push(self.array, item);
  }

  function arrayPush(AddressArray memory self, address item) internal pure {
    uint256 length = self.array.length;
    uint256 allocLength = self.allocatedMemory;
    if (length >= allocLength) {
      require(length == allocLength, "Array length exceeds allocation");
      uint256 newMemory = length * 2;
      address[] memory newArray = _allocateAddresses(newMemory);
      _copy(newArray, self.array);
      self.array = newArray;
      self.allocatedMemory = newMemory;
    }
    _push(self.array, item);
  }

  /// @notice Pop the last item from the dynamic array,
  /// removing it and decrementing the array length in place.
  /// @dev This makes the dragons happy
  /// as they have more space to roam.
  /// Thus they have no desire to escape and ravage your buffers.
  /// @param self The array to pop from.
  /// @return item The previously last element in the array.
  function arrayPop(UintArray memory self)
    internal
    pure
    returns (uint256 item)
  {
    uint256[] memory array = self.array;
    uint256 length = array.length;
    require(length > 0, "Can't pop from empty array");
    return _pop(array);
  }

  function arrayPop(AddressArray memory self)
    internal
    pure
    returns (address item)
  {
    address[] memory array = self.array;
    uint256 length = array.length;
    require(length > 0, "Can't pop from empty array");
    return _pop(array);
  }

  /// @notice Allocate an empty array,
  /// reserving enough memory to safely store `length` items.
  /// @dev The array starts with zero length,
  /// but the allocated buffer has space for `length` words.
  /// "What be beyond the bounds of `array`?" you may ask.
  /// The answer is: dragons.
  /// But do not worry,
  /// for `Array.allocatedMemory` protects your EVM from them.
  function _allocateUints(uint256 length)
    private
    pure
    returns (uint256[] memory array)
  {
    // Calculate the size of the allocated block.
    // Solidity arrays without a specified constant length
    // (i.e. `uint256[]` instead of `uint256[8]`)
    // store the length at the first memory position
    // and the contents of the array after it,
    // so we add 1 to the length to account for this.
    uint256 inMemorySize = (length + 1) * 0x20;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Get some free memory
      array := mload(0x40)
      // Write a zero in the length field;
      // we set the length elsewhere
      // if we store anything in the array immediately.
      // When we allocate we only know how many words we reserve,
      // not how many actually get written.
      mstore(array, 0)
      // Move the free memory pointer
      // to the end of the allocated block.
      mstore(0x40, add(array, inMemorySize))
    }
    return array;
  }

  function _allocateAddresses(uint256 length)
    private
    pure
    returns (address[] memory array)
  {
    uint256 inMemorySize = (length + 1) * 0x20;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      array := mload(0x40)
      mstore(array, 0)
      mstore(0x40, add(array, inMemorySize))
    }
    return array;
  }

  /// @notice Unsafe function to copy the contents of one array
  /// into an empty initialized array
  /// with sufficient free memory available.
  function _copy(uint256[] memory dest, uint256[] memory src) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(src)
      let byteLength := mul(length, 0x20)
      // Store the resulting length of the array.
      mstore(dest, length)
      // Maintain a write pointer
      // for the current write location in the destination array
      // by adding the 32 bytes for the array length
      // to the starting location.
      let writePtr := add(dest, 0x20)
      // Stop copying when the write pointer reaches
      // the length of the source array.
      // We can track the endpoint either from the write or read pointer.
      // This uses the write pointer
      // because that's the way it was done
      // in the (public domain) code I stole this from.
      let end := add(writePtr, byteLength)

      for {
        // Initialize a read pointer to the start of the source array,
        // 32 bytes into its memory.
        let readPtr := add(src, 0x20)
      } lt(writePtr, end) {
        // Increase both pointers by 32 bytes each iteration.
        writePtr := add(writePtr, 0x20)
        readPtr := add(readPtr, 0x20)
      } {
        // Write the source array into the dest memory
        // 32 bytes at a time.
        mstore(writePtr, mload(readPtr))
      }
    }
  }

  function _copy(address[] memory dest, address[] memory src) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(src)
      let byteLength := mul(length, 0x20)
      mstore(dest, length)
      let writePtr := add(dest, 0x20)
      let end := add(writePtr, byteLength)

      for {
        let readPtr := add(src, 0x20)
      } lt(writePtr, end) {
        writePtr := add(writePtr, 0x20)
        readPtr := add(readPtr, 0x20)
      } {
        mstore(writePtr, mload(readPtr))
      }
    }
  }

  /// @notice Unsafe function to push past the limit of an array.
  /// Only use with preallocated free memory.
  function _push(uint256[] memory array, uint256 item) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Get array length
      let length := mload(array)
      let newLength := add(length, 1)
      // Calculate how many bytes the array takes in memory,
      // including the length field.
      // This is equal to 32 * the incremented length.
      let arraySize := mul(0x20, newLength)
      // Calculate the first memory position after the array
      let nextPosition := add(array, arraySize)
      // Store the item in the available position
      mstore(nextPosition, item)
      // Increment array length
      mstore(array, newLength)
    }
  }

  function _push(address[] memory array, address item) private pure {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let length := mload(array)
      let newLength := add(length, 1)
      let arraySize := mul(0x20, newLength)
      let nextPosition := add(array, arraySize)
      mstore(nextPosition, item)
      mstore(array, newLength)
    }
  }

  function _pop(uint256[] memory array) private pure returns (uint256 item) {
    uint256 length = array.length;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      // Calculate the memory position of the last element
      let lastPosition := add(array, mul(length, 0x20))
      // Retrieve the last item
      item := mload(lastPosition)
      // Decrement array length
      mstore(array, sub(length, 1))
    }
    return item;
  }

  function _pop(address[] memory array) private pure returns (address item) {
    uint256 length = array.length;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let lastPosition := add(array, mul(length, 0x20))
      item := mload(lastPosition)
      mstore(array, sub(length, 1))
    }
    return item;
  }
}

pragma solidity 0.5.17;

/// @notice The implicit 8-ary trees of the sortition pool
/// rely on packing 8 "slots" of 32-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant LAST_SLOT = SLOT_COUNT - 1;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;

  ////////////////////////////////////////////////////////////////////////////

  /// @notice Calculate the right shift required
  /// to make the 32 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint32[8].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint256 position) internal pure returns (uint256) {
    return position * SLOT_WIDTH;
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint32[32].
  function getSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Doing a bitwise AND with `SLOT_MAX`
    // clears all but the 32 least significant bits.
    // Because of the right shift by `slotShift(position)` bits,
    // those 32 bits contain the 32 bits in the `position`th slot of `node`.
    return (node >> shiftBits) & SLOT_MAX;
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Shifting `SLOT_MAX` left by `slotShift(position)` bits
    // gives us a number where all bits of the `position`th slot are set,
    // and all other bits are unset.
    //
    // Using a bitwise NOT on this number,
    // we get a uint256 where all bits are set
    // except for those of the `position`th slot.
    //
    // Bitwise ANDing the original `node` with this number
    // sets the bits of `position`th slot to zero,
    // leaving all other bits unchanged.
    return node & ~(SLOT_MAX << shiftBits);
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @param weight The weight of of the node.
  /// Safely truncated to a 32-bit number,
  /// but this should never be called with an overflowing weight regardless.
  function setSlot(
    uint256 node,
    uint256 position,
    uint256 weight
  ) internal pure returns (uint256) {
    uint256 shiftBits = position * SLOT_WIDTH;
    // Clear the `position`th slot like in `clearSlot()`.
    uint256 clearedNode = node & ~(SLOT_MAX << shiftBits);
    // Bitwise AND `weight` with `SLOT_MAX`
    // to clear all but the 32 least significant bits.
    //
    // Shift this left by `slotShift(position)` bits
    // to obtain a uint256 with all bits unset
    // except in the `position`th slot
    // which contains the 32-bit value of `weight`.
    uint256 shiftedWeight = (weight & SLOT_MAX) << shiftBits;
    // When we bitwise OR these together,
    // all other slots except the `position`th one come from the left argument,
    // and the `position`th gets filled with `weight` from the right argument.
    return clearedNode | shiftedWeight;
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint256 node) internal pure returns (uint256 sum) {
    sum = node & SLOT_MAX;
    // Iterate through each slot
    // by shifting `node` right in increments of 32 bits,
    // and adding the 32 least significant bits to the `sum`.
    uint256 newNode = node >> SLOT_WIDTH;
    while (newNode > 0) {
      sum += (newNode & SLOT_MAX);
      newNode = newNode >> SLOT_WIDTH;
    }
    return sum;
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint256 node, uint256 index)
    internal
    pure
    returns (uint256 slot, uint256 newIndex)
  {
    newIndex = index;
    uint256 newNode = node;
    uint256 currentSlotWeight = newNode & SLOT_MAX;
    while (newIndex >= currentSlotWeight) {
      newIndex -= currentSlotWeight;
      slot++;
      newNode = newNode >> SLOT_WIDTH;
      currentSlotWeight = newNode & SLOT_MAX;
    }
    return (slot, newIndex);
  }
}

pragma solidity 0.5.17;

import "./BondedSortitionPool.sol";
import "./api/IBonding.sol";
import "./api/IStaking.sol";

/// @title Bonded Sortition Pool Factory
/// @notice Factory for the creation of new bonded sortition pools.
contract BondedSortitionPoolFactory {
  /// @notice Creates a new bonded sortition pool instance.
  /// @return Address of the new bonded sortition pool contract instance.
  function createSortitionPool(
    IStaking stakingContract,
    IBonding bondingContract,
    uint256 minimumStake,
    uint256 initialMinimumBond,
    uint256 poolWeightDivisor
  ) public returns (address) {
    return
      address(
        new BondedSortitionPool(
          stakingContract,
          bondingContract,
          minimumStake,
          initialMinimumBond,
          poolWeightDivisor,
          msg.sender
        )
      );
  }
}

pragma solidity 0.5.17;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
/// The pool should specify a reasonable minimum bondable value for operators
/// trying to join the pool, to prevent griefing the selection.
contract BondedSortitionPool is AbstractSortitionPool {
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  struct PoolParams {
    IStaking stakingContract;
    uint256 minimumStake;
    IBonding bondingContract;
    // Defines the minimum unbounded value the operator needs to have to be
    // eligible to join and stay in the sortition pool. Operators not
    // satisfying minimum bondable value are removed from the pool.
    uint256 minimumBondableValue;
    // Bond required from each operator for the currently pending group
    // selection. If operator does not have at least this unbounded value,
    // it is skipped during the selection.
    uint256 requestedBond;
    // The weight divisor in the pool can differ from the minimum stake
    uint256 poolWeightDivisor;
    address owner;
  }

  PoolParams poolParams;

  constructor(
    IStaking _stakingContract,
    IBonding _bondingContract,
    uint256 _minimumStake,
    uint256 _minimumBondableValue,
    uint256 _poolWeightDivisor,
    address _poolOwner
  ) public {
    require(_minimumStake > 0, "Minimum stake cannot be zero");

    poolParams = PoolParams(
      _stakingContract,
      _minimumStake,
      _bondingContract,
      _minimumBondableValue,
      0,
      _poolWeightDivisor,
      _poolOwner
    );
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed and bonding requirements. All operators
  /// in the group are unique.
  ///
  /// If there are not enough operators in a pool to form a group or not
  /// enough operators are eligible for work selection given the bonding
  /// requirements, the function fails.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @param minimumStake The current minimum stake value
  /// @param bondValue Size of the requested bond per operator
  function selectSetGroup(
    uint256 groupSize,
    bytes32 seed,
    uint256 minimumStake,
    uint256 bondValue
  ) public returns (address[] memory) {
    PoolParams memory params = initializeSelectionParams(
      minimumStake,
      bondValue
    );
    require(msg.sender == params.owner, "Only owner may select groups");
    uint256 paramsPtr;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      paramsPtr := params
    }
    return generalizedSelectGroup(groupSize, seed, paramsPtr, true);
  }

  /// @notice Sets the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool. The pool should specify
  /// a reasonable minimum requirement for operators trying to join the pool
  /// to prevent griefing group selection.
  /// @param minimumBondableValue The minimum bondable value required from the
  /// operator.
  function setMinimumBondableValue(uint256 minimumBondableValue) public {
    require(
      msg.sender == poolParams.owner,
      "Only owner may update minimum bond value"
    );

    poolParams.minimumBondableValue = minimumBondableValue;
  }

  /// @notice Returns the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool.
  function getMinimumBondableValue() public view returns (uint256) {
    return poolParams.minimumBondableValue;
  }

  function initializeSelectionParams(uint256 minimumStake, uint256 bondValue)
    internal
    returns (PoolParams memory params)
  {
    params = poolParams;

    if (params.requestedBond != bondValue) {
      params.requestedBond = bondValue;
    }

    if (params.minimumStake != minimumStake) {
      params.minimumStake = minimumStake;
      poolParams.minimumStake = minimumStake;
    }

    return params;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    address ownerAddress = poolParams.owner;
    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = poolParams.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // Don't query stake if bond is insufficient.
    if (bondableValue < poolParams.minimumBondableValue) {
      return 0;
    }

    uint256 eligibleStake = poolParams.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // but only if eligibleStake >= minimumStake.
    // Ethereum uint256 division performs implicit floor
    // If eligibleStake < poolWeightDivisor, return 0 = ineligible.
    if (eligibleStake < poolParams.minimumStake) {
      return 0;
    }
    return (eligibleStake / poolParams.poolWeightDivisor);
  }

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory, // `selected`, for future use
    uint256 paramsPtr
  ) internal view returns (Fate memory) {
    PoolParams memory params;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      params := paramsPtr
    }
    address operator = leaf.operator();
    uint256 leafWeight = leaf.weight();

    if (!isLeafInitialized(leaf)) {
      return Fate(Decision.Skip, 0);
    }

    address ownerAddress = params.owner;

    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = params.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // If unbonded value is insufficient for the operator to be in the pool,
    // delete the operator.
    if (bondableValue < params.minimumBondableValue) {
      return Fate(Decision.Delete, 0);
    }
    // If unbonded value is sufficient for the operator to be in the pool
    // but it is not sufficient for the current selection, skip the operator.
    if (bondableValue < params.requestedBond) {
      return Fate(Decision.Skip, 0);
    }

    uint256 eligibleStake = params.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // Ethereum uint256 division performs implicit floor
    uint256 eligibleWeight = eligibleStake / params.poolWeightDivisor;

    if (eligibleWeight < leafWeight || eligibleStake < params.minimumStake) {
      return Fate(Decision.Delete, 0);
    }
    return Fate(Decision.Select, 0);
  }
}

pragma solidity 0.5.17;

import "./GasStation.sol";
import "./RNG.sol";
import "./SortitionTree.sol";
import "./DynamicArray.sol";
import "./api/IStaking.sol";

/// @title Abstract Sortition Pool
/// @notice Abstract contract encapsulating common logic of all sortition pools.
/// @dev Inheriting implementations are expected to implement getEligibleWeight
/// function.
contract AbstractSortitionPool is SortitionTree, GasStation {
  using Leaf for uint256;
  using Position for uint256;
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  enum Decision {
    Select, // Add to the group, and use new seed
    Skip, // Retry with same seed, skip this leaf
    Delete, // Retry with same seed, delete this leaf
    UpdateRetry, // Retry with same seed, update this leaf
    UpdateSelect // Select and reseed, but also update this leaf
  }

  struct Fate {
    Decision decision;
    // The new weight of the leaf if Decision is Update*, otherwise 0
    uint256 maybeWeight;
  }

  // Require 10 blocks after joining before the operator can be selected for
  // a group. This reduces the degrees of freedom miners and other
  // front-runners have in conducting pool-bumping attacks.
  //
  // We don't use the stack of empty leaves until we run out of space on the
  // rightmost leaf (i.e. after 2 million operators have joined the pool).
  // It means all insertions are at the right end, so one can't reorder
  // operators already in the pool until the pool has been filled once.
  // Because the index is calculated by taking the minimum number of required
  // random bits, and seeing if it falls in the range of the total pool weight,
  // the only scenarios where insertions on the right matter are if it crosses
  // a power of two threshold for the total weight and unlocks another random
  // bit, or if a random number that would otherwise be discarded happens to
  // fall within that space.
  uint256 constant INIT_BLOCKS = 10;

  uint256 constant GAS_DEPOSIT_SIZE = 1;

  /// @notice The number of blocks that must be mined before the operator who
  // joined the pool is eligible for work selection.
  function operatorInitBlocks() public pure returns (uint256) {
    return INIT_BLOCKS;
  }

  // Return whether the operator is eligible for the pool.
  function isOperatorEligible(address operator) public view returns (bool) {
    return getEligibleWeight(operator) > 0;
  }

  // Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  // Return whether the operator's weight in the pool
  // matches their eligible weight.
  function isOperatorUpToDate(address operator) public view returns (bool) {
    return getEligibleWeight(operator) == getPoolWeight(operator);
  }

  // Returns whether the operator has passed the initialization blocks period
  // to be eligible for the work selection. Reverts if the operator is not in
  // the pool.
  function isOperatorInitialized(address operator) public view returns (bool) {
    require(isOperatorInPool(operator), "Operator is not in the pool");

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 leafPosition = flaggedPosition.unsetFlag();
    uint256 leaf = leaves[leafPosition];

    return isLeafInitialized(leaf);
  }

  // Return the weight of the operator in the pool,
  // which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = leaves[leafPosition].weight();
      return leafWeight;
    }
  }

  // Add an operator to the pool,
  // reverting if the operator is already present.
  function joinPool(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    require(eligibleWeight > 0, "Operator not eligible");

    depositGas(operator);
    insertOperator(operator, eligibleWeight);
  }

  // Update the operator's weight if present and eligible,
  // or remove from the pool if present and ineligible.
  function updateOperatorStatus(address operator) public {
    uint256 eligibleWeight = getEligibleWeight(operator);
    uint256 inPoolWeight = getPoolWeight(operator);

    require(eligibleWeight != inPoolWeight, "Operator already up to date");

    if (eligibleWeight == 0) {
      removeOperator(operator);
      releaseGas(operator);
    } else {
      updateOperator(operator, eligibleWeight);
    }
  }

  function generalizedSelectGroup(
    uint256 groupSize,
    bytes32 seed,
    // This uint256 is actually a void pointer.
    // We can't pass a SelectionParams,
    // because the implementation of the SelectionParams struct
    // can vary between different concrete sortition pool implementations.
    //
    // Whatever SelectionParams struct is used by the concrete contract
    // should be created in the `selectGroup`/`selectSetGroup` function,
    // then coerced into a uint256 to be passed into this function.
    // The paramsPtr is then passed to the `decideFate` implementation
    // which can coerce it back into the concrete SelectionParams.
    // This allows `generalizedSelectGroup`
    // to work with any desired eligibility logic.
    uint256 paramsPtr,
    bool noDuplicates
  ) internal returns (address[] memory) {
    uint256 _root = root;
    bool rootChanged = false;

    DynamicArray.AddressArray memory selected;
    selected = DynamicArray.addressArray(groupSize);

    RNG.State memory rng;
    rng = RNG.initialize(seed, _root.sumWeight(), groupSize);

    while (selected.array.length < groupSize) {
      rng.generateNewIndex();

      (uint256 leafPosition, uint256 startingIndex) = pickWeightedLeaf(
        rng.currentMappedIndex,
        _root
      );

      uint256 leaf = leaves[leafPosition];
      address operator = leaf.operator();
      uint256 leafWeight = leaf.weight();

      Fate memory fate = decideFate(leaf, selected, paramsPtr);

      if (fate.decision == Decision.Select) {
        selected.arrayPush(operator);
        if (noDuplicates) {
          rng.addSkippedInterval(startingIndex, leafWeight);
        }
        rng.reseed(seed, selected.array.length);
        continue;
      }
      if (fate.decision == Decision.Skip) {
        rng.addSkippedInterval(startingIndex, leafWeight);
        continue;
      }
      if (fate.decision == Decision.Delete) {
        // Update the RNG
        rng.updateInterval(startingIndex, leafWeight, 0);
        // Remove the leaf and update root
        _root = removeLeaf(leafPosition, _root);
        rootChanged = true;
        // Remove the record of the operator's leaf and release gas
        removeLeafPositionRecord(operator);
        releaseGas(operator);
        continue;
      }
      if (fate.decision == Decision.UpdateRetry) {
        _root = setLeaf(leafPosition, leaf.setWeight(fate.maybeWeight), _root);
        rootChanged = true;
        rng.updateInterval(startingIndex, leafWeight, fate.maybeWeight);
        continue;
      }
      if (fate.decision == Decision.UpdateSelect) {
        _root = setLeaf(leafPosition, leaf.setWeight(fate.maybeWeight), _root);
        rootChanged = true;
        selected.arrayPush(operator);
        rng.updateInterval(startingIndex, leafWeight, fate.maybeWeight);
        if (noDuplicates) {
          rng.addSkippedInterval(startingIndex, fate.maybeWeight);
        }
        rng.reseed(seed, selected.array.length);
        continue;
      }
    }
    if (rootChanged) {
      root = _root;
    }
    return selected.array;
  }

  function isLeafInitialized(uint256 leaf) internal view returns (bool) {
    uint256 createdAt = leaf.creationBlock();

    return block.number > (createdAt + operatorInitBlocks());
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256);

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory selected,
    uint256 paramsPtr
  ) internal view returns (Fate memory);

  function gasDepositSize() internal pure returns (uint256) {
    return GAS_DEPOSIT_SIZE;
  }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library PercentUtils {
    using SafeMath for uint256;

    // Return `b`% of `a`
    // 200.percent(40) == 80
    // Commutative, works both ways
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(100);
    }

    // Return `a` as percentage of `b`:
    // 80.asPercentOf(200) == 40
    function asPercentOf(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(100).div(b);
    }
}

pragma solidity 0.5.17;

library OperatorParams {
    // OperatorParams packs values that are commonly used together
    // into a single uint256 to reduce the cost functions
    // like querying eligibility.
    //
    // An OperatorParams uint256 contains:
    // - the operator's staked token amount (uint128)
    // - the operator's creation timestamp (uint64)
    // - the operator's undelegation timestamp (uint64)
    //
    // These are packed as [amount | createdAt | undelegatedAt]
    //
    // Staked KEEP is stored in an uint128,
    // which is sufficient because KEEP tokens have 18 decimals (2^60)
    // and there will be at most 10^9 KEEP in existence (2^30).
    //
    // Creation and undelegation times are stored in an uint64 each.
    // Thus uint64s would be sufficient for around 3*10^11 years.
    uint256 constant TIMESTAMP_WIDTH = 64;
    uint256 constant AMOUNT_WIDTH = 128;

    uint256 constant TIMESTAMP_MAX = (2**TIMESTAMP_WIDTH) - 1;
    uint256 constant AMOUNT_MAX = (2**AMOUNT_WIDTH) - 1;

    uint256 constant CREATION_SHIFT = TIMESTAMP_WIDTH;
    uint256 constant AMOUNT_SHIFT = 2 * TIMESTAMP_WIDTH;

    function pack(
        uint256 amount,
        uint256 createdAt,
        uint256 undelegatedAt
    ) internal pure returns (uint256) {
        // Check for staked amount overflow.
        // We shouldn't actually ever need this.
        require(amount <= AMOUNT_MAX, "uint128 overflow");
        // Bitwise OR the timestamps together.
        // The resulting number is equal or greater than either,
        // and tells if we have a bit set outside the 64 available bits.
        require(
            (createdAt | undelegatedAt) <= TIMESTAMP_MAX,
            "uint64 overflow"
        );

        return ((amount << AMOUNT_SHIFT) |
            (createdAt << CREATION_SHIFT) |
            undelegatedAt);
    }

    function unpack(uint256 packedParams)
        internal
        pure
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        amount = getAmount(packedParams);
        createdAt = getCreationTimestamp(packedParams);
        undelegatedAt = getUndelegationTimestamp(packedParams);
    }

    function getAmount(uint256 packedParams) internal pure returns (uint256) {
        return (packedParams >> AMOUNT_SHIFT) & AMOUNT_MAX;
    }

    function setAmount(uint256 packedParams, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            pack(
                amount,
                getCreationTimestamp(packedParams),
                getUndelegationTimestamp(packedParams)
            );
    }

    function getCreationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return (packedParams >> CREATION_SHIFT) & TIMESTAMP_MAX;
    }

    function setCreationTimestamp(
        uint256 packedParams,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }

    function getUndelegationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return packedParams & TIMESTAMP_MAX;
    }

    function setUndelegationTimestamp(
        uint256 packedParams,
        uint256 undelegationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                getCreationTimestamp(packedParams),
                undelegationTimestamp
            );
    }

    function setAmountAndCreationTimestamp(
        uint256 packedParams,
        uint256 amount,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                amount,
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }
}

pragma solidity 0.5.17;

/*
Verison pulled from https://github.com/summa-tx/bitcoin-spv/blob/2535e4edaeaac4b2b095903fce684ae1c05761bc/solidity/contracts/BytesLib.sol
*/

/*
https://github.com/GNSPS/solidity-bytes-utils/
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org>
*/

/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
                case 2 {
                    // Since the new array still fits in the slot, we just need to
                    // update the contents of the slot.
                    // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                    sstore(
                        _preBytes_slot,
                        // all the modifications to the slot are inside this
                        // next block
                        add(
                            // we can just add to the slot contents because the
                            // bytes we want to change are the LSBs
                            fslot,
                            add(
                                mul(
                                    div(
                                        // load the bytes from memory
                                        mload(add(_postBytes, 0x20)),
                                        // zero all bytes to the right
                                        exp(0x100, sub(32, mlength))
                                    ),
                                    // and now shift left the number of bytes to
                                    // leave space for the length in the slot
                                    exp(0x100, sub(32, newlength))
                                ),
                                // increase length by the double of the memory
                                // bytes length
                                mul(mlength, 2)
                            )
                        )
                    )
                }
                case 1 {
                    // The stored value fits in the slot, but the combined value
                    // will exceed it.
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // The contents of the _postBytes array start 32 bytes into
                    // the structure. Our first read should obtain the `submod`
                    // bytes that can fit into the unused space in the last word
                    // of the stored array. To get this, we read 32 bytes starting
                    // from `submod`, so the data we read overlaps with the array
                    // contents by `submod` bytes. Masking the lowest-order
                    // `submod` bytes allows us to add that value directly to the
                    // stored value.

                    let submod := sub(32, slength)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(
                        sc,
                        add(
                            and(
                                fslot,
                                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                            ),
                            and(mload(mc), mask)
                        )
                    )

                    for {
                        mc := add(mc, 0x20)
                        sc := add(sc, 1)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
                default {
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    // Start copying to the last used word of the stored array.
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // Copy over the first `submod` bytes of the new data as in
                    // case 1 above.
                    let slengthmod := mod(slength, 32)
                    let mlengthmod := mod(mlength, 32)
                    let submod := sub(32, slengthmod)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(sc, add(sload(sc), and(mload(mc), mask)))

                    for {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        uint256 _totalLen = _start + 20;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Address conversion out of bounds."
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + 1),
            "Uint8 conversion out of bounds."
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        uint256 _totalLen = _start + 32;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Uint conversion out of bounds."
        );
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
                case 1 {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                    let cb := 1

                    let mc := add(_preBytes, 0x20)
                    let end := add(mc, length)

                    for {
                        let cc := add(_postBytes, 0x20)
                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                    } eq(add(lt(mc, end), cb), 2) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        // if any of these checks fails then arrays are not equal
                        if iszero(eq(mload(mc), mload(cc))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
                case 1 {
                    // slength can contain both the length and contents of the array
                    // if length < 32 bytes so let's prepare for that
                    // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                    if iszero(iszero(slength)) {
                        switch lt(slength, 32)
                            case 1 {
                                // blank the last byte which is the length
                                fslot := mul(div(fslot, 0x100), 0x100)

                                if iszero(
                                    eq(fslot, mload(add(_postBytes, 0x20)))
                                ) {
                                    // unsuccess:
                                    success := 0
                                }
                            }
                            default {
                                // cb is a circuit breaker in the for loop since there's
                                //  no said feature for inline assembly loops
                                // cb = 1 - don't breaker
                                // cb = 0 - break
                                let cb := 1

                                // get the keccak hash to get the contents of the array
                                mstore(0x0, _preBytes_slot)
                                let sc := keccak256(0x0, 0x20)

                                let mc := add(_postBytes, 0x20)
                                let end := add(mc, mlength)

                                // the next line is the loop condition:
                                // while(uint(mc < end) + cb == 2)
                                for {

                                } eq(add(lt(mc, end), cb), 2) {
                                    sc := add(sc, 1)
                                    mc := add(mc, 0x20)
                                } {
                                    if iszero(eq(sload(sc), mload(mc))) {
                                        // unsuccess:
                                        success := 0
                                        cb := 0
                                    }
                                }
                            }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function toBytes32(bytes memory _source)
        internal
        pure
        returns (bytes32 result)
    {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

pragma solidity 0.5.17;

library AddressArrayUtils {
    function contains(address[] memory self, address _address)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++) {
            if (_address == self[i]) {
                return true;
            }
        }
        return false;
    }

    function removeAddress(address[] storage self, address _addressToRemove)
        internal
        returns (address[] storage)
    {
        for (uint256 i = 0; i < self.length; i++) {
            // If address is found in array.
            if (_addressToRemove == self[i]) {
                // Delete element at index and shift array.
                for (uint256 j = i; j < self.length - 1; j++) {
                    self[j] = self[j + 1];
                }
                self.length--;
                i--;
            }
        }
        return self;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../TokenStakingEscrow.sol";
import "../../utils/OperatorParams.sol";

/// @notice TokenStaking contract library allowing to perform two-step stake
/// top-ups for existing delegations.
/// Top-up is a two-step process: it is initiated with a declared top-up value
/// and after waiting for at least the initialization period it can be
/// committed.
library TopUps {
    using SafeMath for uint256;
    using OperatorParams for uint256;

    event TopUpInitiated(address indexed operator, uint256 topUp);
    event TopUpCompleted(address indexed operator, uint256 newAmount);

    struct TopUp {
        uint256 amount;
        uint256 createdAt;
    }

    struct Storage {
        // operator -> TopUp
        mapping(address => TopUp) topUps;
    }

    /// @notice Performs top-up in one step when stake is not yet initialized by
    /// adding the top-up amount to the stake and resetting stake initialization
    /// time counter.
    /// @dev This function should be called only for not yet initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    /// @return New value of parameters. It should be updated for the operator
    /// in the staking contract.
    function instantComplete(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public returns (uint256 newParams) {
        // Stake is not yet initialized so we don't need to check if the
        // operator is not undelegating - initializing and undelegating at the
        // same time is not possible. We do however, need to check whether the
        // operator has not canceled its previous stake for that operator,
        // depositing the stake it in the escrow. We do not want to allow
        // resurrecting operators with cancelled stake by top-ups.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        uint256 newAmount = operatorParams.getAmount().add(value);
        newParams = operatorParams.setAmountAndCreationTimestamp(
            newAmount,
            block.timestamp
        );

        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Initiates top-up of the given value for tokens delegated to
    /// the provided operator. If there is an existing top-up still
    /// initializing, top-up values are summed up and initialization period
    /// is set to the current block timestamp.
    /// @dev This function should be called only for active operators with
    /// initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    function initiate(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public {
        // Stake is initialized, the operator is still active so we need
        // to check if it's not undelegating.
        require(!isUndelegating(operatorParams), "Stake undelegated");
        // We also need to check if the stake for the operator is not already
        // in the escrow because it's been previously cancelled.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        TopUp memory awaiting = self.topUps[operator];
        self.topUps[operator] = TopUp(awaiting.amount.add(value), now);
        emit TopUpInitiated(operator, value);
    }

    /// @notice Commits the top-up if it passed the initialization period.
    /// Tokens are added to the stake once the top-up is committed.
    /// @param operator Operator The operator with a pending stake top-up.
    /// @param initializationPeriod Stake initialization period.
    function commit(
        Storage storage self,
        address operator,
        uint256 operatorParams,
        uint256 initializationPeriod
    ) public returns (uint256 newParams) {
        TopUp memory topUp = self.topUps[operator];
        require(topUp.amount > 0, "No top up to commit");
        require(
            now > topUp.createdAt.add(initializationPeriod),
            "Stake is initializing"
        );

        uint256 newAmount = operatorParams.getAmount().add(topUp.amount);
        newParams = operatorParams.setAmount(newAmount);

        delete self.topUps[operator];
        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Cancels pending, initiating top-up. If there is no initiating
    /// top-up for the operator, function does nothing. This function should be
    /// used when the stake is recovered to return tokens from a pending,
    /// initiating top-up.
    /// @param operator Operator The operator from which the stake is recovered.
    function cancel(Storage storage self, address operator)
        public
        returns (uint256)
    {
        TopUp memory topUp = self.topUps[operator];
        if (topUp.amount == 0) {
            return 0;
        }

        delete self.topUps[operator];
        return topUp.amount;
    }

    /// @notice Returns true if the given operatorParams indicate that the
    /// operator is undelegating its stake or that it completed stake
    /// undelegation.
    /// @param operatorParams Parameters of the operator, as stored in the
    /// staking contract.
    function isUndelegating(uint256 operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @notice MinimumStakeSchedule defines the minimum stake parametrization and
/// schedule. It starts with a minimum stake of 100k KEEP. Over the following
/// 2 years, the minimum stake is lowered periodically using a uniform stepwise
/// function, eventually ending at 10k.
library MinimumStakeSchedule {
    using SafeMath for uint256;

    // 2 years in seconds (seconds per day * days in a year * years)
    uint256 public constant schedule = 86400 * 365 * 2;
    uint256 public constant steps = 10;
    uint256 public constant base = 10000 * 1e18;

    /// @notice Returns the current value of the minimum stake. The minimum
    /// stake is lowered periodically over the course of 2 years since the time
    /// of the shedule start and eventually ends at 10k KEEP.
    function current(uint256 scheduleStart) internal view returns (uint256) {
        if (now < scheduleStart.add(schedule)) {
            uint256 currentStep =
                steps.mul(now.sub(scheduleStart)).div(schedule);
            return base.mul(steps.sub(currentStep));
        }
        return base;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {AuthorityVerifier} from "../../Authorizations.sol";
import "./LockUtils.sol";

library Locks {
    using SafeMath for uint256;
    using LockUtils for LockUtils.LockSet;

    event StakeLocked(
        address indexed operator,
        address lockCreator,
        uint256 until
    );
    event LockReleased(address indexed operator, address lockCreator);
    event ExpiredLockReleased(address indexed operator, address lockCreator);

    uint256 public constant maximumLockDuration = 86400 * 200; // 200 days in seconds

    struct Storage {
        // Locks placed on the operator.
        // `operatorLocks[operator]` returns all locks placed on the operator.
        // Each authorized operator contract can place one lock on an operator.
        mapping(address => LockUtils.LockSet) operatorLocks;
    }

    function lockStake(
        Storage storage self,
        address operator,
        uint256 duration
    ) public {
        require(duration <= maximumLockDuration, "Lock duration too long");
        self.operatorLocks[operator].setLock(
            msg.sender,
            uint96(block.timestamp.add(duration))
        );
        emit StakeLocked(operator, msg.sender, block.timestamp.add(duration));
    }

    function releaseLock(Storage storage self, address operator) public {
        self.operatorLocks[operator].releaseLock(msg.sender);
        emit LockReleased(operator, msg.sender);
    }

    function releaseExpiredLock(
        Storage storage self,
        address operator,
        address operatorContract,
        address authorityVerifier
    ) public {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];

        require(locks.contains(operatorContract), "No matching lock present");

        bool expired = block.timestamp >= locks.getLockTime(operatorContract);
        bool disabled =
            !AuthorityVerifier(authorityVerifier).isApprovedOperatorContract(
                operatorContract
            );

        require(expired || disabled, "Lock still active and valid");

        locks.releaseLock(operatorContract);

        emit ExpiredLockReleased(operator, operatorContract);
    }

    /// @dev AuthorityVerifier is a trusted implementation and not a third-party,
    /// external contract. AuthorityVerifier never reverts on the check and
    /// has a reasonable gas consumption.
    function isStakeLocked(
        Storage storage self,
        address operator,
        address authorityVerifier
    ) public view returns (bool) {
        LockUtils.Lock[] storage _locks = self.operatorLocks[operator].locks;
        LockUtils.Lock memory lock;
        for (uint256 i = 0; i < _locks.length; i++) {
            lock = _locks[i];
            if (block.timestamp < lock.expiresAt) {
                if (
                    AuthorityVerifier(authorityVerifier)
                        .isApprovedOperatorContract(lock.creator)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function isStakeReleased(
        Storage storage self,
        address operator,
        address operatorContract
    ) public view returns (bool) {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];
        // `getLockTime` returns 0 if the lock doesn't exist,
        // thus we don't need to check for its presence separately.
        return block.timestamp >= locks.getLockTime(operatorContract);
    }

    function getLocks(Storage storage self, address operator)
        public
        view
        returns (address[] memory creators, uint256[] memory expirations)
    {
        uint256 lockCount = self.operatorLocks[operator].locks.length;
        creators = new address[](lockCount);
        expirations = new uint256[](lockCount);
        LockUtils.Lock memory lock;
        for (uint256 i = 0; i < lockCount; i++) {
            lock = self.operatorLocks[operator].locks[i];
            creators[i] = lock.creator;
            expirations[i] = lock.expiresAt;
        }
    }
}

pragma solidity 0.5.17;

library LockUtils {
    struct Lock {
        address creator;
        uint96 expiresAt;
    }

    /// @notice The LockSet is like an array of unique `uint256`s,
    /// but additionally supports O(1) membership tests and removals.
    /// @dev Because the LockSet relies on a mapping,
    /// it can only be used in storage, not in memory.
    struct LockSet {
        // locks[positions[lock.creator] - 1] = lock
        Lock[] locks;
        mapping(address => uint256) positions;
    }

    /// @notice Check whether the LockSet `self` contains a lock by `creator`
    function contains(LockSet storage self, address creator)
        internal
        view
        returns (bool)
    {
        return (self.positions[creator] != 0);
    }

    function getLockTime(LockSet storage self, address creator)
        internal
        view
        returns (uint96)
    {
        uint256 positionPlusOne = self.positions[creator];
        if (positionPlusOne == 0) {
            return 0;
        }
        return self.locks[positionPlusOne - 1].expiresAt;
    }

    /// @notice Set the lock of `creator` to `expiresAt`,
    /// overriding the current value if any.
    function setLock(
        LockSet storage self,
        address _creator,
        uint96 _expiresAt
    ) internal {
        uint256 positionPlusOne = self.positions[_creator];
        Lock memory lock = Lock(_creator, _expiresAt);
        // No existing lock
        if (positionPlusOne == 0) {
            self.locks.push(lock);
            self.positions[_creator] = self.locks.length;
            // Existing lock present
        } else {
            self.locks[positionPlusOne - 1].expiresAt = _expiresAt;
        }
    }

    /// @notice Remove the lock of `creator`.
    /// If no lock present, do nothing.
    function releaseLock(LockSet storage self, address _creator) internal {
        uint256 positionPlusOne = self.positions[_creator];
        if (positionPlusOne != 0) {
            uint256 lockCount = self.locks.length;
            if (positionPlusOne != lockCount) {
                // Not the last lock,
                // so we need to move the last lock into the emptied position.
                Lock memory lastLock = self.locks[lockCount - 1];
                self.locks[positionPlusOne - 1] = lastLock;
                self.positions[lastLock.creator] = positionPlusOne;
            }
            self.locks.length--;
            self.positions[_creator] = 0;
        }
    }

    /// @notice Return the locks of the LockSet `self`.
    function enumerate(LockSet storage self)
        internal
        view
        returns (Lock[] memory)
    {
        return self.locks;
    }
}

pragma solidity 0.5.17;

import "../../TokenGrant.sol";
import "../../TokenStakingEscrow.sol";
import "../..//utils/BytesLib.sol";
import "../RolesLookup.sol";

/// @notice TokenStaking contract library allowing to capture the details of
/// delegated grants and offering functions allowing to check grantee
/// authentication for stake delegation management.
library GrantStaking {
    using BytesLib for bytes;
    using RolesLookup for address payable;

    /// @dev Grant ID is flagged with the most significant bit set, to
    /// distinguish the grant ID `0` from default (null) value. The flag is
    /// toggled with bitwise XOR (`^`) which keeps all other bits intact but
    /// flips the flag bit. The flag should be set before writing to
    /// `operatorToGrant`, and unset after reading from `operatorToGrant`
    /// before using the value.
    uint256 constant GRANT_ID_FLAG = 1 << 255;

    struct Storage {
        /// @dev Do not read or write this mapping directly; please use
        /// `hasGrantDelegated`, `setGrantForOperator`, and `getGrantForOperator`
        /// instead.
        mapping(address => uint256) _operatorToGrant;
    }

    /// @notice Tries to capture delegation data if the pending delegation has
    /// been created from a grant. There are only two possibilities and they
    /// need to be handled differently: delegation comes from the TokenGrant
    /// contract or delegation comes from TokenStakingEscrow. In those two cases
    /// grant ID has to be captured in a different way.
    /// @dev In case of a delegation from the escrow, it is expected that grant
    /// ID is passed in extraData bytes array. When the delegation comes from
    /// the TokenGrant contract, delegation data are obtained directly from that
    /// contract using `tryCapturingGrantId` function.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param escrow TokenStakingEscrow contract address.
    /// @param from The owner of the tokens who approved them to transfer.
    /// @param operator The operator tokens are delegated to.
    /// @param extraData Data for stake delegation, as passed to
    /// `receiveApproval` of `TokenStaking`.
    function tryCapturingDelegationData(
        Storage storage self,
        TokenGrant tokenGrant,
        address escrow,
        address from,
        address operator,
        bytes memory extraData
    ) public returns (bool, uint256) {
        if (from == escrow) {
            require(
                extraData.length == 92,
                "Corrupted delegation data from escrow"
            );
            uint256 grantId = extraData.toUint(60);
            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        } else {
            return tryCapturingGrantId(self, tokenGrant, operator);
        }
    }

    /// @notice Checks if the delegation for the given operator has been created
    /// from a grant defined in the passed token grant contract and if so,
    /// captures the grant ID for that delegation.
    /// Grant ID can be later retrieved based on the operator address and used
    /// to authenticate grantee or to fetch the information about grant
    /// unlocking schedule for escrow.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param operator The operator tokens are delegated to.
    function tryCapturingGrantId(
        Storage storage self,
        TokenGrant tokenGrant,
        address operator
    ) internal returns (bool, uint256) {
        (bool success, bytes memory data) =
            address(tokenGrant).call(
                abi.encodeWithSignature(
                    "getGrantStakeDetails(address)",
                    operator
                )
            );
        if (success) {
            (uint256 grantId, , address grantStakingContract) =
                abi.decode(data, (uint256, uint256, address));
            // Double-check if the delegation in TokenGrant has been defined
            // for this staking contract. If not, it means it's an old
            // delegation and the current one does not come from a grant.
            // The scenario covered here is:
            // - grantee delegated to operator A from a TokenGrant using another
            //   staking contract,
            // - someone delegates to operator A using liquid tokens and this
            //   staking contract.
            // Without this check, we'd consider the second delegation as coming
            // from a grant.
            if (address(this) != grantStakingContract) {
                return (false, 0);
            }

            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        }

        return (false, 0);
    }

    /// @notice Returns true if the given operator operates on stake delegated
    /// from a grant. false is returned otherwise.
    /// @param operator The operator to which tokens from a grant are
    /// potentially delegated to.
    function hasGrantDelegated(Storage storage self, address operator)
        public
        view
        returns (bool)
    {
        return self._operatorToGrant[operator] != 0;
    }

    /// @notice Associates operator with the provided grant ID. It means that
    /// the given operator delegates on stake from the grant with this ID.
    /// @param operator The operator tokens are delegate to.
    /// @param grantId Identifier of a grant from which the tokens are delegated
    /// to.
    function setGrantForOperator(
        Storage storage self,
        address operator,
        uint256 grantId
    ) public {
        self._operatorToGrant[operator] = grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns grant ID for the provided operator. If the operator
    /// does not operate on stake delegated from a grant, function reverts.
    /// @dev To avoid reverting in case the grant ID for the operator does not
    /// exist, consider calling hasGrantDelegated before.
    /// @param operator The operator tokens are delegate to.
    function getGrantForOperator(Storage storage self, address operator)
        public
        view
        returns (uint256)
    {
        uint256 grantId = self._operatorToGrant[operator];
        require(grantId != 0, "No grant for the operator");
        return grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns true if msg.sender is grantee eligible to trigger stake
    /// undelegation for this operator. Function checks both standard grantee
    /// and managed grantee case.
    /// @param operator The operator tokens are delegated to.
    /// @param tokenGrant KEEP token grant contract reference.
    function canUndelegate(
        Storage storage self,
        address operator,
        TokenGrant tokenGrant
    ) public returns (bool) {
        // First of all, we need to see if the operator has grant delegated.
        // If not, we don't need to bother about checking grantee or
        // managed grantee and we just return false.
        if (!hasGrantDelegated(self, operator)) {
            return false;
        }

        uint256 grantId = getGrantForOperator(self, operator);
        (, , , , uint256 revokedAt, address grantee) =
            tokenGrant.getGrant(grantId);

        // Is msg.sender grantee of a standard grant?
        if (msg.sender == grantee) {
            return true;
        }

        // If not, we need to dig deeper and see if we are dealing with
        // a grantee from a managed grant.
        if ((msg.sender).isManagedGranteeForGrant(grantId, tokenGrant)) {
            return true;
        }

        // There is only one possibility left - grant has been revoked and
        // grant manager wants to take back delegated tokens.
        if (revokedAt == 0) {
            return false;
        }
        (address grantManager, , , , ) =
            tokenGrant.getGrantUnlockingSchedule(grantId);
        return msg.sender == grantManager;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library UnlockingSchedule {
    using SafeMath for uint256;

    function getUnlockedAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff
    ) internal pure returns (uint256) {
        bool cliffNotReached = _now < cliff;
        if (cliffNotReached) {
            return 0;
        }

        uint256 timeElapsed = _now.sub(start);

        bool unlockingPeriodFinished = timeElapsed >= duration;
        if (unlockingPeriodFinished) {
            return grantedAmount;
        }

        return grantedAmount.mul(timeElapsed).div(duration);
    }
}

pragma solidity 0.5.17;

import "../utils/AddressArrayUtils.sol";
import "../StakeDelegatable.sol";
import "../TokenGrant.sol";
import "../ManagedGrant.sol";

/// @title Roles Lookup
/// @notice Library facilitating lookup of roles in stake delegation setup.
library RolesLookup {
    using AddressArrayUtils for address[];

    /// @notice Returns true if the tokenOwner delegated tokens to operator
    /// using the provided stakeDelegatable contract. Othwerwise, returns false.
    /// This function works only for the case when tokenOwner own those tokens
    /// and those are not tokens from a grant.
    function isTokenOwnerForOperator(
        address tokenOwner,
        address operator,
        StakeDelegatable stakeDelegatable
    ) internal view returns (bool) {
        return stakeDelegatable.ownerOf(operator) == tokenOwner;
    }

    /// @notice Returns true if the grantee delegated tokens to operator
    /// with the provided tokenGrant contract. Otherwise, returns false.
    /// This function works only for the case when tokens were generated from
    /// a non-managed grant, that is, the grantee is a non-contract address to
    /// which the delegated tokens were granted.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isGranteeForOperator(
        address grantee,
        address operator,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        address[] memory operators = tokenGrant.getGranteeOperators(grantee);
        return operators.contains(operator);
    }

    /// @notice Returns true if the grantee from the given managed grant contract
    /// delegated tokens to operator with the provided tokenGrant contract.
    /// Otherwise, returns false. In case the grantee declared by the managed
    /// grant contract does not match the provided grantee, function reverts.
    /// This function works only for cases when grantee, from TokenGrant's
    /// perspective, is a smart contract exposing grantee() function returning
    /// the final grantee. One possibility is the ManagedGrant contract.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isManagedGranteeForOperator(
        address grantee,
        address operator,
        address managedGrantContract,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        require(
            ManagedGrant(managedGrantContract).grantee() == grantee,
            "Not a grantee of the provided contract"
        );

        address[] memory operators =
            tokenGrant.getGranteeOperators(managedGrantContract);
        return operators.contains(operator);
    }

    /// @notice Returns true if grant with the given ID has been created with
    /// managed grant pointing currently to the grantee passed as a parameter.
    /// @dev The function does not revert if grant has not been created with
    /// a managed grantee. This function is not a view because it uses low-level
    /// call to check if the grant has been created with a managed grant.
    /// It does not however modify any state.
    function isManagedGranteeForGrant(
        address grantee,
        uint256 grantId,
        TokenGrant tokenGrant
    ) internal returns (bool) {
        (, , , , , address managedGrant) = tokenGrant.getGrant(grantId);
        (, bytes memory result) =
            managedGrant.call(abi.encodeWithSignature("grantee()"));
        if (result.length == 0) {
            return false;
        }
        address managedGrantee = abi.decode(result, (address));
        return grantee == managedGrantee;
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./libraries/grant/UnlockingSchedule.sol";
import "./utils/BytesLib.sol";
import "./KeepToken.sol";
import "./utils/BytesLib.sol";
import "./TokenGrant.sol";
import "./ManagedGrant.sol";
import "./TokenSender.sol";

/// @title TokenStakingEscrow
/// @notice Escrow lets the staking contract to deposit undelegated, granted
/// tokens and either withdraw them based on the grant unlocking schedule or
/// re-delegate them to another operator.
/// @dev The owner of TokenStakingEscrow is TokenStaking contract and only owner
/// can deposit. This contract works with an assumption that operator is unique
/// in the scope of `TokenStaking`, that is, no more than one delegation in the
/// `TokenStaking` can be done do the given operator ever. Even if the previous
/// delegation ended, operator address cannot be reused.
contract TokenStakingEscrow is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using BytesLib for bytes;
    using UnlockingSchedule for uint256;

    event Deposited(
        address indexed operator,
        uint256 indexed grantId,
        uint256 amount
    );
    event DepositRedelegated(
        address indexed previousOperator,
        address indexed newOperator,
        uint256 indexed grantId,
        uint256 amount
    );
    event DepositWithdrawn(
        address indexed operator,
        address indexed grantee,
        uint256 amount
    );
    event RevokedDepositWithdrawn(
        address indexed operator,
        address indexed grantManager,
        uint256 amount
    );
    event EscrowAuthorized(address indexed grantManager, address escrow);

    IERC20 public keepToken;
    TokenGrant public tokenGrant;

    struct Deposit {
        uint256 grantId;
        uint256 amount;
        uint256 withdrawn;
        uint256 redelegated;
    }

    // operator address -> KEEP deposit
    mapping(address => Deposit) internal deposits;

    // Other escrows authorized by grant manager. Grantee may request to migrate
    // tokens to another authorized escrow.
    // grant manager -> escrow -> authorized?
    mapping(address => mapping(address => bool)) internal authorizedEscrows;

    constructor(KeepToken _keepToken, TokenGrant _tokenGrant) public {
        keepToken = _keepToken;
        tokenGrant = _tokenGrant;
    }

    /// @notice receiveApproval accepts deposits from staking contract and
    /// stores them in the escrow by the operator address from which they were
    /// undelegated. Function expects operator address and grant identifier to
    /// be passed as ABI-encoded information in extraData. Grant with the given
    /// identifier has to exist.
    /// @param from Address depositing tokens - it has to be the address of
    /// TokenStaking contract owning TokenStakingEscrow.
    /// @param value The amount of KEEP tokens deposited.
    /// @param token The address of KEEP token contract.
    /// @param extraData ABI-encoded data containing operator address (32 bytes)
    /// and grant ID (32 bytes).
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        require(IERC20(token) == keepToken, "Not a KEEP token");
        require(msg.sender == token, "KEEP token is not the sender");
        require(extraData.length == 64, "Unexpected data length");

        (address operator, uint256 grantId) =
            abi.decode(extraData, (address, uint256));
        receiveDeposit(from, value, operator, grantId);
    }

    /// @notice Redelegates deposit or part of the deposit to another operator.
    /// Uses the same staking contract as the original delegation.
    /// @param previousOperator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    /// @dev Only grantee is allowed to call this function. For managed grant,
    /// caller has to be the managed grantee.
    /// @param amount Amount of tokens to delegate.
    /// @param extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes)
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes)
    function redelegate(
        address previousOperator,
        uint256 amount,
        bytes memory extraData
    ) public {
        require(extraData.length == 60, "Corrupted delegation data");

        Deposit memory deposit = deposits[previousOperator];

        uint256 grantId = deposit.grantId;
        address newOperator = extraData.toAddress(20);
        require(isGrantee(msg.sender, grantId), "Not authorized");
        require(getAmountRevoked(grantId) == 0, "Grant revoked");
        require(
            availableAmount(previousOperator) >= amount,
            "Insufficient balance"
        );
        require(
            !hasDeposit(newOperator),
            "Redelegating to previously used operator is not allowed"
        );

        deposits[previousOperator].redelegated = deposit.redelegated.add(
            amount
        );

        TokenSender(address(keepToken)).approveAndCall(
            owner(), // TokenStaking contract associated with the escrow
            amount,
            abi.encodePacked(extraData, grantId)
        );

        emit DepositRedelegated(previousOperator, newOperator, grantId, amount);
    }

    /// @notice Returns true if there is a deposit for the given operator in
    /// the escrow. Otherwise, returns false.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function hasDeposit(address operator) public view returns (bool) {
        return depositedAmount(operator) > 0;
    }

    /// @notice Returns the currently available amount deposited in the escrow
    /// that may or may not be currently withdrawable. The available amount
    /// is the amount initially deposited minus the amount withdrawn and
    /// redelegated so far from that deposit.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function availableAmount(address operator) public view returns (uint256) {
        Deposit memory deposit = deposits[operator];
        return deposit.amount.sub(deposit.withdrawn).sub(deposit.redelegated);
    }

    /// @notice Returns the total amount deposited in the escrow after
    /// undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositedAmount(address operator) public view returns (uint256) {
        return deposits[operator].amount;
    }

    /// @notice Returns grant ID for the amount deposited in the escrow after
    /// undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositGrantId(address operator) public view returns (uint256) {
        return deposits[operator].grantId;
    }

    /// @notice Returns the amount withdrawn so far from the value deposited
    /// in the escrow contract after undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositWithdrawnAmount(address operator)
        public
        view
        returns (uint256)
    {
        return deposits[operator].withdrawn;
    }

    /// @notice Returns the total amount redelegated so far from the value
    /// deposited in the escrow contract after undelegating it from the provided
    /// operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositRedelegatedAmount(address operator)
        public
        view
        returns (uint256)
    {
        return deposits[operator].redelegated;
    }

    /// @notice Returns the currently withdrawable amount that was previously
    /// deposited in the escrow after undelegating it from the provided operator.
    /// Tokens are unlocked based on their grant unlocking schedule.
    /// Function returns 0 for non-existing deposits and revoked grants if they
    /// have been revoked before they fully unlocked.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawable(address operator) public view returns (uint256) {
        Deposit memory deposit = deposits[operator];

        // Staked tokens can be only withdrawn by grantee for non-revoked grant
        // assuming that grant has not fully unlocked before it's been
        // revoked.
        //
        // It is not possible for the escrow to determine the number of tokens
        // it should return to the grantee of a revoked grant given different
        // possible staking contracts and staking policies.
        //
        // If the entire grant unlocked before it's been reverted, escrow
        // lets to withdraw the entire deposited amount.
        if (getAmountRevoked(deposit.grantId) == 0) {
            (uint256 duration, uint256 start, uint256 cliff) =
                getUnlockingSchedule(deposit.grantId);

            uint256 unlocked =
                now.getUnlockedAmount(deposit.amount, duration, start, cliff);

            if (deposit.withdrawn.add(deposit.redelegated) < unlocked) {
                return unlocked.sub(deposit.withdrawn).sub(deposit.redelegated);
            }
        }

        return 0;
    }

    /// @notice Withdraws currently unlocked tokens deposited in the escrow
    /// after undelegating them from the provided operator. Only grantee or
    /// operator can call this function. Important: this function can not be
    /// called for a `ManagedGrant` grantee. This may lead to locking tokens.
    /// For `ManagedGrant`, please use `withdrawToManagedGrantee` instead.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdraw(address operator) public {
        Deposit memory deposit = deposits[operator];
        address grantee = getGrantee(deposit.grantId);

        // Make sure this function is not called for a managed grant.
        // If called for a managed grant, tokens could be locked there.
        // Better be safe than sorry.
        (bool success, ) =
            address(this).call(
                abi.encodeWithSignature("getManagedGrantee(address)", grantee)
            );
        require(!success, "Can not be called for managed grant");

        require(
            msg.sender == grantee || msg.sender == operator,
            "Only grantee or operator can withdraw"
        );

        withdraw(deposit, operator, grantee);
    }

    /// @notice Withdraws currently unlocked tokens deposited in the escrow
    /// after undelegating them from the provided operator. Only grantee or
    /// operator can call this function. This function works only for
    /// `ManagedGrant` grantees. For a standard grant, please use `withdraw`
    /// instead.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawToManagedGrantee(address operator) public {
        Deposit memory deposit = deposits[operator];
        address managedGrant = getGrantee(deposit.grantId);
        address grantee = getManagedGrantee(managedGrant);

        require(
            msg.sender == grantee || msg.sender == operator,
            "Only grantee or operator can withdraw"
        );

        withdraw(deposit, operator, grantee);
    }

    /// @notice Migrates all available tokens to another authorized escrow.
    /// Can be requested only by grantee.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    /// @param receivingEscrow Escrow to which tokens should be migrated.
    /// @dev The receiving escrow needs to accept deposits from this escrow, at
    /// least for the period of migration.
    function migrate(address operator, address receivingEscrow) public {
        Deposit memory deposit = deposits[operator];
        require(isGrantee(msg.sender, deposit.grantId), "Not authorized");

        address grantManager = getGrantManager(deposit.grantId);
        require(
            authorizedEscrows[grantManager][receivingEscrow],
            "Escrow not authorized"
        );

        uint256 amountLeft = availableAmount(operator);
        deposits[operator].withdrawn = deposit.withdrawn.add(amountLeft);
        TokenSender(address(keepToken)).approveAndCall(
            receivingEscrow,
            amountLeft,
            abi.encode(operator, deposit.grantId)
        );
    }

    /// @notice Withdraws the entire amount that is still deposited in the
    /// escrow in case the grant has been revoked. Anyone can call this function
    /// and the entire amount is transferred back to the grant manager.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawRevoked(address operator) public {
        Deposit memory deposit = deposits[operator];

        require(
            getAmountRevoked(deposit.grantId) > 0,
            "No revoked tokens to withdraw"
        );

        address grantManager = getGrantManager(deposit.grantId);
        withdrawRevoked(deposit, operator, grantManager);
    }

    /// @notice Used by grant manager to authorize another escrows for
    // funds migration.
    function authorizeEscrow(address anotherEscrow) public {
        require(anotherEscrow != address(0x0), "Escrow address can't be zero");
        authorizedEscrows[msg.sender][anotherEscrow] = true;
        emit EscrowAuthorized(msg.sender, anotherEscrow);
    }

    /// @notice Resolves the final grantee of ManagedGrant contract. If the
    /// provided address is not a ManagedGrant contract, function reverts.
    /// @param managedGrant Address of the managed grant contract.
    function getManagedGrantee(address managedGrant)
        public
        view
        returns (address)
    {
        ManagedGrant grant = ManagedGrant(managedGrant);
        return grant.grantee();
    }

    function receiveDeposit(
        address from,
        uint256 value,
        address operator,
        uint256 grantId
    ) internal {
        // This contract works with an assumption that operator is unique.
        // This is fine as long as the staking contract works with the same
        // assumption so we are limiting deposits to the staking contract only.
        require(from == owner(), "Only owner can deposit");
        require(
            getAmountGranted(grantId) > 0,
            "Grant with this ID does not exist"
        );

        require(
            !hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );

        keepToken.safeTransferFrom(from, address(this), value);
        deposits[operator] = Deposit(grantId, value, 0, 0);

        emit Deposited(operator, grantId, value);
    }

    function isGrantee(address maybeGrantee, uint256 grantId)
        internal
        returns (bool)
    {
        // Let's check the simplest case first - standard grantee.
        // If the given address is set as a grantee for grant with the given ID,
        // we return true.
        address grantee = getGrantee(grantId);
        if (maybeGrantee == grantee) {
            return true;
        }

        // If the given address is not a standard grantee, there is still
        // a chance that address is a managed grantee. We are calling
        // getManagedGrantee that will cast the grantee to ManagedGrant and try
        // to call getGrantee() function. If this call returns non-zero address,
        // it means we are dealing with a ManagedGrant.
        (, bytes memory result) =
            address(this).call(
                abi.encodeWithSignature("getManagedGrantee(address)", grantee)
            );
        if (result.length == 0) {
            return false;
        }
        // At this point we know we are dealing with a ManagedGrant, so the last
        // thing we need to check is whether the managed grantee of that grant
        // is the grantee address passed as a parameter.
        address managedGrantee = abi.decode(result, (address));
        return maybeGrantee == managedGrantee;
    }

    function withdraw(
        Deposit memory deposit,
        address operator,
        address grantee
    ) internal {
        uint256 amount = withdrawable(operator);

        deposits[operator].withdrawn = deposit.withdrawn.add(amount);
        keepToken.safeTransfer(grantee, amount);

        emit DepositWithdrawn(operator, grantee, amount);
    }

    function withdrawRevoked(
        Deposit memory deposit,
        address operator,
        address grantManager
    ) internal {
        uint256 amount = availableAmount(operator);
        deposits[operator].withdrawn = amount;
        keepToken.safeTransfer(grantManager, amount);

        emit RevokedDepositWithdrawn(operator, grantManager, amount);
    }

    function getAmountGranted(uint256 grantId)
        internal
        view
        returns (uint256 amountGranted)
    {
        (amountGranted, , , , , ) = tokenGrant.getGrant(grantId);
    }

    function getAmountRevoked(uint256 grantId)
        internal
        view
        returns (uint256 amountRevoked)
    {
        (, , , amountRevoked, , ) = tokenGrant.getGrant(grantId);
    }

    function getUnlockingSchedule(uint256 grantId)
        internal
        view
        returns (
            uint256 duration,
            uint256 start,
            uint256 cliff
        )
    {
        (, duration, start, cliff, ) = tokenGrant.getGrantUnlockingSchedule(
            grantId
        );
    }

    function getGrantee(uint256 grantId)
        internal
        view
        returns (address grantee)
    {
        (, , , , , grantee) = tokenGrant.getGrant(grantId);
    }

    function getGrantManager(uint256 grantId)
        internal
        view
        returns (address grantManager)
    {
        (grantManager, , , , ) = tokenGrant.getGrantUnlockingSchedule(grantId);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StakeDelegatable.sol";
import "./libraries/staking/MinimumStakeSchedule.sol";
import "./libraries/staking/GrantStaking.sol";
import "./libraries/staking/Locks.sol";
import "./libraries/staking/TopUps.sol";
import "./utils/PercentUtils.sol";
import "./utils/BytesLib.sol";
import "./Authorizations.sol";
import "./TokenStakingEscrow.sol";
import "./TokenSender.sol";

/// @title TokenStaking
/// @notice A token staking contract for a specified standard ERC20Burnable token.
/// A holder of the specified token can stake delegate its tokens to this contract
/// and recover the stake after undelegation period is over.
contract TokenStaking is Authorizations, StakeDelegatable {
    using BytesLib for bytes;
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using SafeERC20 for ERC20Burnable;
    using GrantStaking for GrantStaking.Storage;
    using Locks for Locks.Storage;
    using TopUps for TopUps.Storage;

    event StakeDelegated(address indexed owner, address indexed operator);
    event OperatorStaked(
        address indexed operator,
        address indexed beneficiary,
        address indexed authorizer,
        uint256 value
    );
    event StakeOwnershipTransferred(
        address indexed operator,
        address indexed newOwner
    );
    event TopUpInitiated(address indexed operator, uint256 topUp);
    event TopUpCompleted(address indexed operator, uint256 newAmount);
    event Undelegated(address indexed operator, uint256 undelegatedAt);
    event RecoveredStake(address operator);
    event TokensSlashed(address indexed operator, uint256 amount);
    event TokensSeized(address indexed operator, uint256 amount);
    event StakeLocked(
        address indexed operator,
        address lockCreator,
        uint256 until
    );
    event LockReleased(address indexed operator, address lockCreator);
    event ExpiredLockReleased(address indexed operator, address lockCreator);

    uint256 public deployedAt;
    uint256 public initializationPeriod; // varies between mainnet and testnet

    ERC20Burnable internal token;
    TokenGrant internal tokenGrant;
    TokenStakingEscrow internal escrow;

    GrantStaking.Storage internal grantStaking;
    Locks.Storage internal locks;
    TopUps.Storage internal topUps;

    uint256 internal constant twoWeeks = 1209600; // [sec]
    uint256 internal constant twoMonths = 5184000; // [sec]

    // 2020-04-28; the date of deploying KEEP token.
    // TX:  0xea22d72bc7de4c82798df7194734024a1f2fd57b173d0e065864ff4e9d3dc014
    uint256 internal constant minimumStakeScheduleStart = 1588042366;

    /// @notice Creates a token staking contract for a provided Standard ERC20Burnable token.
    /// @param _token KEEP token contract.
    /// @param _tokenGrant KEEP token grant contract.
    /// @param _escrow Escrow dedicated for this staking contract.
    /// @param _registry Keep contract registry contract.
    /// @param _initializationPeriod To avoid certain attacks on work selection, recently created
    /// operators must wait for a specific period of time before being eligible for work selection.
    constructor(
        ERC20Burnable _token,
        TokenGrant _tokenGrant,
        TokenStakingEscrow _escrow,
        KeepRegistry _registry,
        uint256 _initializationPeriod
    ) public Authorizations(_registry) {
        token = _token;
        tokenGrant = _tokenGrant;
        escrow = _escrow;
        registry = _registry;
        initializationPeriod = _initializationPeriod;
        deployedAt = block.timestamp;
    }

    /// @notice Returns minimum amount of KEEP that allows sMPC cluster client to
    /// participate in the Keep network. Expressed as number with 18-decimal places.
    /// Initial minimum stake is higher than the final and lowered periodically based
    /// on the amount of steps and the length of the minimum stake schedule in seconds.
    function minimumStake() public view returns (uint256) {
        return MinimumStakeSchedule.current(minimumStakeScheduleStart);
    }

    /// @notice Returns the current value of the undelegation period.
    /// The staking contract guarantees that an undelegated operator’s stakes
    /// will stay locked for a period of time after undelegation, and thus
    /// available as collateral for any work the operator is engaged in.
    /// The undelegation period is two weeks for the first two months and
    /// two months after that.
    function undelegationPeriod() public view returns (uint256) {
        return
            block.timestamp < deployedAt.add(twoMonths) ? twoWeeks : twoMonths;
    }

    /// @notice Receives approval of token transfer and stakes the approved
    /// amount or adds the approved amount to an existing delegation (a “top-up”).
    /// In case of a top-up, it is expected that the operator stake is not
    /// undelegated and that the top-up is performed from the same source of
    /// tokens as the initial delegation. That is, if the tokens were delegated
    /// from a grant, top-up has to be performed from the same grant. If the
    /// delegation was done using liquid tokens, only liquid tokens from the
    /// same owner can be used to top-up the stake.
    /// Top-up can not be cancelled so it is important to be careful with the
    /// amount of KEEP added to the stake.
    /// @dev Requires that the provided token contract be the same one linked to
    /// this contract.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and stake.
    /// @param _token Token contract address.
    /// @param _extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes), ignored for a top-up
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes), ignored for a top-up
    /// - Grant ID (32 bytes) - required only when called by TokenStakingEscrow
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory _extraData
    ) public {
        require(ERC20Burnable(_token) == token, "Unrecognized token");
        require(_extraData.length >= 60, "Corrupted delegation data");

        // Transfer tokens to this contract.
        token.safeTransferFrom(_from, address(this), _value);

        address operator = _extraData.toAddress(20);
        // See if there is an existing delegation for this operator...
        if (operators[operator].packedParams.getCreationTimestamp() == 0) {
            // If there is no existing delegation, delegate tokens using
            // beneficiary and authorizer passed in _extraData.
            delegate(_from, _value, operator, _extraData);
        } else {
            // If there is an existing delegation, top-up the stake.
            topUp(_from, _value, operator, _extraData);
        }
    }

    /// @notice Commits pending top-up for the provided operator. If the top-up
    /// did not pass the initialization period, the function fails.
    /// @param _operator The operator with a pending top-up that is getting
    /// committed.
    function commitTopUp(address _operator) public {
        operators[_operator].packedParams = topUps.commit(
            _operator,
            operators[_operator].packedParams,
            initializationPeriod
        );
    }

    /// @notice Cancels stake of tokens within the operator initialization period
    /// without being subjected to the token lockup for the undelegation period.
    /// This can be used to undo mistaken delegation to the wrong operator address.
    /// @param _operator Address of the stake operator.
    function cancelStake(address _operator) public {
        address owner = operators[_operator].owner;
        require(
            msg.sender == owner ||
                msg.sender == _operator ||
                grantStaking.canUndelegate(_operator, tokenGrant),
            "Not authorized"
        );
        uint256 operatorParams = operators[_operator].packedParams;

        require(!_isInitialized(operatorParams), "Initialized stake");

        uint256 amount = operatorParams.getAmount();
        operators[_operator].packedParams = operatorParams.setAmount(0);

        transferOrDeposit(owner, _operator, amount);
    }

    /// @notice Undelegates staked tokens. You will be able to recover your stake by calling
    /// `recoverStake()` with operator address once undelegation period is over.
    /// @param _operator Address of the stake operator.
    function undelegate(address _operator) public {
        undelegateAt(_operator, block.timestamp);
    }

    /// @notice Set an undelegation time for staked tokens.
    /// Undelegation will begin at the specified timestamp.
    /// You will be able to recover your stake by calling
    /// `recoverStake()` with operator address once undelegation period is over.
    /// @param _operator Address of the stake operator.
    /// @param _undelegationTimestamp The timestamp undelegation is to start at.
    function undelegateAt(address _operator, uint256 _undelegationTimestamp)
        public
    {
        require(
            msg.sender == _operator ||
                msg.sender == operators[_operator].owner ||
                grantStaking.canUndelegate(_operator, tokenGrant),
            "Not authorized"
        );
        uint256 oldParams = operators[_operator].packedParams;
        require(
            _undelegationTimestamp >= block.timestamp &&
                _undelegationTimestamp >
                oldParams.getCreationTimestamp().add(initializationPeriod),
            "Invalid timestamp"
        );
        uint256 existingUndelegationTimestamp =
            oldParams.getUndelegationTimestamp();
        require(
            // Undelegation not in progress OR
            existingUndelegationTimestamp == 0 ||
                // Undelegating sooner than previously set time OR
                existingUndelegationTimestamp > _undelegationTimestamp ||
                // We have already checked above that msg.sender is owner, grantee,
                // or operator. Only owner and grantee are eligible to postpone the
                // delegation so it is enough if we exclude operator here.
                msg.sender != _operator,
            "Operator may not postpone"
        );
        operators[_operator].packedParams = oldParams.setUndelegationTimestamp(
            _undelegationTimestamp
        );
        emit Undelegated(_operator, _undelegationTimestamp);
    }

    /// @notice Recovers staked tokens and transfers them back to the owner.
    /// Recovering tokens can only be performed when the operator finished
    /// undelegating.
    /// @param _operator Operator address.
    function recoverStake(address _operator) public {
        uint256 operatorParams = operators[_operator].packedParams;
        require(
            operatorParams.getUndelegationTimestamp() != 0,
            "Not undelegated"
        );
        require(_isUndelegatingFinished(operatorParams), "Still undelegating");
        require(!isStakeLocked(_operator), "Locked stake");

        uint256 amount = operatorParams.getAmount();

        // If there is a pending top-up, force-commit it before returning tokens.
        amount = amount.add(topUps.cancel(_operator));

        operators[_operator].packedParams = operatorParams.setAmount(0);
        transferOrDeposit(operators[_operator].owner, _operator, amount);

        emit RecoveredStake(_operator);
    }

    /// @notice Gets stake delegation info for the given operator.
    /// @param _operator Operator address.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return createdAt The time when the stake has been delegated.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address _operator)
        public
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        return operators[_operator].packedParams.unpack();
    }

    /// @notice Locks given operator stake for the specified duration.
    /// Locked stake may not be recovered until the lock expires or is released,
    /// even if the normal undelegation period has passed.
    /// Only previously authorized operator contract can lock the stake.
    /// @param operator Operator address.
    /// @param duration Lock duration in seconds.
    function lockStake(address operator, uint256 duration)
        public
        onlyApprovedOperatorContract(msg.sender)
    {
        require(
            isAuthorizedForOperator(operator, msg.sender),
            "Not authorized"
        );

        uint256 operatorParams = operators[operator].packedParams;

        require(_isInitialized(operatorParams), "Inactive stake");
        require(!_isUndelegating(operatorParams), "Undelegating stake");

        locks.lockStake(operator, duration);
    }

    /// @notice Removes a lock the caller had previously placed on the operator.
    /// @dev Only for operator contracts.
    /// To remove expired or disabled locks, use `releaseExpiredLocks`.
    /// The authorization check ensures that the caller must have been able
    /// to place a lock on the operator sometime in the past.
    /// We don't need to check for current approval status of the caller
    /// because unlocking stake cannot harm the operator
    /// nor interfere with other operator contracts.
    /// Therefore even disabled operator contracts may freely unlock stake.
    /// @param operator Operator address.
    function unlockStake(address operator) public {
        require(
            isAuthorizedForOperator(operator, msg.sender),
            "Not authorized"
        );
        locks.releaseLock(operator);
    }

    /// @notice Removes the lock of the specified operator contract
    /// if the lock has expired or the contract has been disabled.
    /// @dev Necessary for removing locks placed by contracts
    /// that have been disabled by the panic button.
    /// Also applicable to prevent inadvertent DoS of `recoverStake`
    /// if too many operator contracts have failed to clean up their locks.
    function releaseExpiredLock(address operator, address operatorContract)
        public
    {
        locks.releaseExpiredLock(operator, operatorContract, address(this));
    }

    /// @notice Check whether the operator has any active locks
    /// that haven't expired yet
    /// and whose creators aren't disabled by the panic button.
    function isStakeLocked(address operator) public view returns (bool) {
        return locks.isStakeLocked(operator, address(this));
    }

    /// @notice Get the locks placed on the operator.
    /// @return creators The addresses of operator contracts
    /// that have placed a lock on the operator.
    /// @return expirations The expiration times
    /// of the locks placed on the operator.
    function getLocks(address operator)
        public
        view
        returns (address[] memory creators, uint256[] memory expirations)
    {
        return locks.getLocks(operator);
    }

    /// @notice Slash provided token amount from every member in the misbehaved
    /// operators array and burn 100% of all the tokens.
    /// @param amountToSlash Token amount to slash from every misbehaved operator.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function slash(uint256 amountToSlash, address[] memory misbehavedOperators)
        public
        onlyApprovedOperatorContract(msg.sender)
    {
        uint256 totalAmountToBurn;
        address authoritySource = getAuthoritySource(msg.sender);
        for (uint256 i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(
                authorizations[authoritySource][operator],
                "Not authorized"
            );

            uint256 operatorParams = operators[operator].packedParams;
            require(_isInitialized(operatorParams), "Inactive stake");

            require(
                !_isStakeReleased(operator, operatorParams, msg.sender),
                "Stake is released"
            );

            uint256 currentAmount = operatorParams.getAmount();

            if (currentAmount < amountToSlash) {
                totalAmountToBurn = totalAmountToBurn.add(currentAmount);
                operators[operator].packedParams = operatorParams.setAmount(0);
                emit TokensSlashed(operator, currentAmount);
            } else {
                totalAmountToBurn = totalAmountToBurn.add(amountToSlash);
                operators[operator].packedParams = operatorParams.setAmount(
                    currentAmount.sub(amountToSlash)
                );
                emit TokensSlashed(operator, amountToSlash);
            }
        }

        token.burn(totalAmountToBurn);
    }

    /// @notice Seize provided token amount from every member in the misbehaved
    /// operators array. The tattletale is rewarded with 5% of the total seized
    /// amount scaled by the reward adjustment parameter and the rest 95% is burned.
    /// @param amountToSeize Token amount to seize from every misbehaved operator.
    /// @param rewardMultiplier Reward adjustment in percentage. Min 1% and 100% max.
    /// @param tattletale Address to receive the 5% reward.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) public onlyApprovedOperatorContract(msg.sender) {
        uint256 totalAmountToBurn;
        address authoritySource = getAuthoritySource(msg.sender);
        for (uint256 i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(
                authorizations[authoritySource][operator],
                "Not authorized"
            );

            uint256 operatorParams = operators[operator].packedParams;
            require(_isInitialized(operatorParams), "Inactive stake");

            require(
                !_isStakeReleased(operator, operatorParams, msg.sender),
                "Stake is released"
            );

            uint256 currentAmount = operatorParams.getAmount();

            if (currentAmount < amountToSeize) {
                totalAmountToBurn = totalAmountToBurn.add(currentAmount);
                operators[operator].packedParams = operatorParams.setAmount(0);
                emit TokensSeized(operator, currentAmount);
            } else {
                totalAmountToBurn = totalAmountToBurn.add(amountToSeize);
                operators[operator].packedParams = operatorParams.setAmount(
                    currentAmount.sub(amountToSeize)
                );
                emit TokensSeized(operator, amountToSeize);
            }
        }

        uint256 tattletaleReward =
            (totalAmountToBurn.percent(5)).percent(rewardMultiplier);

        token.safeTransfer(tattletale, tattletaleReward);
        token.burn(totalAmountToBurn.sub(tattletaleReward));
    }

    /// @notice Allows the current staking relationship owner to transfer the
    /// ownership to someone else.
    /// @param operator Address of the stake operator.
    /// @param newOwner Address of the new staking relationship owner.
    function transferStakeOwnership(address operator, address newOwner) public {
        require(msg.sender == operators[operator].owner, "Not authorized");
        operators[operator].owner = newOwner;
        emit StakeOwnershipTransferred(operator, newOwner);
    }

    /// @notice Gets the eligible stake balance of the specified address.
    /// An eligible stake is a stake that passed the initialization period
    /// and is not currently undelegating. Also, the operator had to approve
    /// the specified operator contract.
    ///
    /// Operator with a minimum required amount of eligible stake can join the
    /// network and participate in new work selection.
    ///
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    /// @return an uint256 representing the eligible stake balance.
    function eligibleStake(address _operator, address _operatorContract)
        public
        view
        returns (uint256 balance)
    {
        uint256 operatorParams = operators[_operator].packedParams;
        // To be eligible for work selection, the operator must:
        // - have the operator contract authorized
        // - have the stake initialized
        // - must not be undelegating; keep in mind the `undelegatedAt` may be
        // set to a time in the future, to schedule undelegation in advance.
        // In this case the operator is still eligible until the timestamp
        // `undelegatedAt`.
        if (
            isAuthorizedForOperator(_operator, _operatorContract) &&
            _isInitialized(operatorParams) &&
            !_isUndelegating(operatorParams)
        ) {
            balance = operatorParams.getAmount();
        }
    }

    /// @notice Gets the active stake balance of the specified address.
    /// An active stake is a stake that passed the initialization period,
    /// and may be in the process of undelegation
    /// but has not been released yet,
    /// either because the undelegation period is not over,
    /// or because the operator contract has an active lock on the operator.
    /// Also, the operator had to approve the specified operator contract.
    ///
    /// The difference between eligible stake is that active stake does not make
    /// the operator eligible for work selection but it may be still finishing
    /// earlier work until the stake is released.
    /// Operator with a minimum required
    /// amount of active stake can join the network but cannot be selected to any
    /// new work.
    ///
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    /// @return an uint256 representing the eligible stake balance.
    function activeStake(address _operator, address _operatorContract)
        public
        view
        returns (uint256 balance)
    {
        uint256 operatorParams = operators[_operator].packedParams;
        if (
            isAuthorizedForOperator(_operator, _operatorContract) &&
            _isInitialized(operatorParams) &&
            !_isStakeReleased(_operator, operatorParams, _operatorContract)
        ) {
            balance = operatorParams.getAmount();
        }
    }

    /// @notice Checks if the specified account has enough active stake to become
    /// network operator and that the specified operator contract has been
    /// authorized for potential slashing.
    ///
    /// Having the required minimum of active stake makes the operator eligible
    /// to join the network. If the active stake is not currently undelegating,
    /// operator is also eligible for work selection.
    ///
    /// @param staker Staker's address
    /// @param operatorContract Operator contract's address
    /// @return True if has enough active stake to participate in the network,
    /// false otherwise.
    function hasMinimumStake(address staker, address operatorContract)
        public
        view
        returns (bool)
    {
        return activeStake(staker, operatorContract) >= minimumStake();
    }

    /// @notice Delegates tokens to a new operator using beneficiary and
    /// authorizer passed in _extraData parameter.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and stake.
    /// @param _operator The new operator address.
    /// @param _extraData Data for stake delegation as passed to receiveApproval.
    function delegate(
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _extraData
    ) internal {
        require(_value >= minimumStake(), "Less than the minimum stake");

        address payable beneficiary = address(uint160(_extraData.toAddress(0)));
        address authorizer = _extraData.toAddress(40);

        operators[_operator] = Operator(
            OperatorParams.pack(_value, block.timestamp, 0),
            _from,
            beneficiary,
            authorizer
        );

        grantStaking.tryCapturingDelegationData(
            tokenGrant,
            address(escrow),
            _from,
            _operator,
            _extraData
        );

        emit StakeDelegated(_from, _operator);
        emit OperatorStaked(_operator, beneficiary, authorizer, _value);
    }

    /// @notice Performs top-up to an existing operator. Tokens added during
    /// stake initialization period are immediatelly added to the stake and
    /// stake initialization timer is reset to the current block. Tokens added
    /// in a top-up after the stake initialization period is over are not
    /// included in the operator stake until the initialization period for
    /// a top-up passes and top-up is committed. Operator must not have the stake
    /// undelegated. It is expected that the top-up is done from the same source
    /// of tokens as the initial delegation. That is, if the tokens were
    /// delegated from a grant, top-up has to be performed from the same grant.
    /// If the delegation was done using liquid tokens, only liquid tokens from
    /// the same owner can be used to top-up the stake.
    /// Top-up can not be cancelled so it is important to be careful with the
    /// amount of KEEP added to the stake.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and top-up to
    /// an existing stake.
    /// @param _operator The new operator address.
    /// @param _extraData Data for stake delegation as passed to receiveApproval
    function topUp(
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _extraData
    ) internal {
        // Top-up comes from a grant if it's been initiated from TokenGrantStake
        // contract or if it's been initiated from TokenStakingEscrow by
        // redelegation.
        bool isFromGrant =
            address(tokenGrant.grantStakes(_operator)) == _from ||
                address(escrow) == _from;

        if (grantStaking.hasGrantDelegated(_operator)) {
            // Operator has grant delegated. We need to see if the top-up
            // is performed also from a grant.
            require(isFromGrant, "Must be from a grant");
            // If it is from a grant, we need to make sure it's from the same
            // grant as the original delegation. We do not want to mix unlocking
            // schedules.
            uint256 previousGrantId =
                grantStaking.getGrantForOperator(_operator);
            (, uint256 grantId) =
                grantStaking.tryCapturingDelegationData(
                    tokenGrant,
                    address(escrow),
                    _from,
                    _operator,
                    _extraData
                );
            require(grantId == previousGrantId, "Not the same grant");
        } else {
            // Operator has no grant delegated. We need to see if the top-up
            // is performed from liquid tokens of the same owner.
            require(!isFromGrant, "Must not be from a grant");
            require(operators[_operator].owner == _from, "Not the same owner");
        }

        uint256 operatorParams = operators[_operator].packedParams;
        if (!_isInitialized(operatorParams)) {
            // If the stake is not yet initialized, we add tokens immediately
            // but we also reset stake initialization time counter.
            operators[_operator].packedParams = topUps.instantComplete(
                _value,
                _operator,
                operatorParams,
                escrow
            );
        } else {
            // If the stake is initialized, we do NOT add tokens immediately.
            // We initiate the top-up and will add tokens to the stake only
            // after the initialization period for a top-up passes.
            topUps.initiate(_value, _operator, operatorParams, escrow);
        }
    }

    /// @notice Is the operator with the given params initialized
    function _isInitialized(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        return
            block.timestamp >
            _operatorParams.getCreationTimestamp().add(initializationPeriod);
    }

    /// @notice Is the operator with the given params undelegating
    function _isUndelegating(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }

    /// @notice Has the operator with the given params finished undelegating
    function _isUndelegatingFinished(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return
            (undelegatedAt != 0) &&
            (block.timestamp > undelegatedAt.add(undelegationPeriod()));
    }

    /// @notice Get whether the operator's stake is released
    /// as far as the operator contract is concerned.
    /// If the operator contract has a lock on the operator,
    /// the operator's stake is be released when the lock expires.
    /// Otherwise the stake is released when the operator finishes undelegating.
    function _isStakeReleased(
        address _operator,
        uint256 _operatorParams,
        address _operatorContract
    ) internal view returns (bool) {
        return
            _isUndelegatingFinished(_operatorParams) &&
            locks.isStakeReleased(_operator, _operatorContract);
    }

    function transferOrDeposit(
        address _owner,
        address _operator,
        uint256 _amount
    ) internal {
        if (grantStaking.hasGrantDelegated(_operator)) {
            // For tokens staked from a grant, transfer them to the escrow.
            TokenSender(address(token)).approveAndCall(
                address(escrow),
                _amount,
                abi.encode(
                    _operator,
                    grantStaking.getGrantForOperator(_operator)
                )
            );
        } else {
            // For liquid tokens staked, transfer them straight to the owner.
            token.safeTransfer(_owner, _amount);
        }
    }
}

pragma solidity 0.5.17;

/// @dev Interface of sender contract for approveAndCall pattern.
interface TokenSender {
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) external;
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TokenStaking.sol";
import "./TokenSender.sol";
import "./utils/BytesLib.sol";

/// @dev Interface of sender contract for approveAndCall pattern.
interface tokenSender {
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) external;
}

contract TokenGrantStake {
    using SafeMath for uint256;
    using BytesLib for bytes;

    ERC20Burnable token;
    TokenStaking tokenStaking;

    address tokenGrant; // Address of the master grant contract.

    uint256 grantId; // ID of the grant for this stake.
    uint256 amount; // Amount of staked tokens.
    address operator; // Operator of the stake.

    constructor(
        address _tokenAddress,
        uint256 _grantId,
        address _tokenStaking
    ) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        require(
            _tokenStaking != address(0x0),
            "Staking contract address can't be zero."
        );

        token = ERC20Burnable(_tokenAddress);
        tokenGrant = msg.sender;
        grantId = _grantId;
        tokenStaking = TokenStaking(_tokenStaking);
    }

    function stake(uint256 _amount, bytes memory _extraData) public onlyGrant {
        amount = _amount;
        operator = _extraData.toAddress(20);
        tokenSender(address(token)).approveAndCall(
            address(tokenStaking),
            _amount,
            _extraData
        );
    }

    function getGrantId() public view onlyGrant returns (uint256) {
        return grantId;
    }

    function getAmount() public view onlyGrant returns (uint256) {
        return amount;
    }

    function getStakingContract() public view onlyGrant returns (address) {
        return address(tokenStaking);
    }

    function getDetails()
        public
        view
        onlyGrant
        returns (
            uint256 _grantId,
            uint256 _amount,
            address _tokenStaking
        )
    {
        return (grantId, amount, address(tokenStaking));
    }

    function cancelStake() public onlyGrant returns (uint256) {
        tokenStaking.cancelStake(operator);
        return returnTokens();
    }

    function undelegate() public onlyGrant {
        tokenStaking.undelegate(operator);
    }

    function recoverStake() public onlyGrant returns (uint256) {
        tokenStaking.recoverStake(operator);
        return returnTokens();
    }

    function returnTokens() internal returns (uint256) {
        uint256 returnedAmount = token.balanceOf(address(this));
        amount -= returnedAmount;
        token.transfer(tokenGrant, returnedAmount);
        return returnedAmount;
    }

    modifier onlyGrant {
        require(msg.sender == tokenGrant, "For token grant contract only");
        _;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./libraries/grant/UnlockingSchedule.sol";
import "./utils/BytesLib.sol";
import "./utils/AddressArrayUtils.sol";
import "./TokenStaking.sol";
import "./TokenGrantStake.sol";
import "./GrantStakingPolicy.sol";

/// @title TokenGrant
/// @notice A token grant contract for a specified standard ERC20Burnable token.
/// Has additional functionality to stake delegate/undelegate token grants.
/// Tokens are granted to the grantee via unlocking scheme and can be
/// withdrawn gradually based on the unlocking schedule cliff and unlocking duration.
/// Optionally grant can be revoked by the token grant manager.
contract TokenGrant {
    using SafeMath for uint256;
    using UnlockingSchedule for uint256;
    using SafeERC20 for ERC20Burnable;
    using BytesLib for bytes;
    using AddressArrayUtils for address[];

    event TokenGrantCreated(uint256 id);
    event TokenGrantWithdrawn(uint256 indexed grantId, uint256 amount);
    event TokenGrantStaked(
        uint256 indexed grantId,
        uint256 amount,
        address operator
    );
    event TokenGrantRevoked(uint256 id);

    event StakingContractAuthorized(
        address indexed grantManager,
        address stakingContract
    );

    struct Grant {
        address grantManager; // Token grant manager.
        address grantee; // Address to which granted tokens are going to be withdrawn.
        uint256 revokedAt; // Timestamp at which grant was revoked by the grant manager.
        uint256 revokedAmount; // The number of tokens revoked from the grantee.
        uint256 revokedWithdrawn; // The number of tokens returned to the grant creator.
        bool revocable; // Whether grant manager can revoke the grant.
        uint256 amount; // Amount of tokens to be granted.
        uint256 duration; // Duration in seconds of the period in which the granted tokens will unlock.
        uint256 start; // Timestamp at which the linear unlocking schedule will start.
        uint256 cliff; // Timestamp before which no tokens will be unlocked.
        uint256 withdrawn; // Amount that was withdrawn to the grantee.
        uint256 staked; // Amount that was staked by the grantee.
        GrantStakingPolicy stakingPolicy;
    }

    uint256 public numGrants;

    ERC20Burnable public token;

    // Staking contracts authorized by the given grant manager.
    // grant manager -> staking contract -> authorized?
    mapping(address => mapping(address => bool)) internal stakingContracts;

    // Token grants.
    mapping(uint256 => Grant) public grants;

    // Token grants stakes.
    mapping(address => TokenGrantStake) public grantStakes;

    // Mapping of token grant IDs per particular address
    // involved in a grant as a grantee or as a grant manager.
    mapping(address => uint256[]) public grantIndices;

    // Token grants balances. Sum of all granted tokens to a grantee.
    // This includes granted tokens that are already unlocked and
    // available to be withdrawn to the grantee
    mapping(address => uint256) public balances;

    // Mapping of operator addresses per particular grantee address.
    mapping(address => address[]) public granteesToOperators;

    /// @notice Creates a token grant contract for a provided Standard ERC20Burnable token.
    /// @param _tokenAddress address of a token that will be linked to this contract.
    constructor(address _tokenAddress) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        token = ERC20Burnable(_tokenAddress);
    }

    /// @notice Used by grant manager to authorize staking contract with the given
    /// address.
    function authorizeStakingContract(address _stakingContract) public {
        require(
            _stakingContract != address(0x0),
            "Staking contract address can't be zero"
        );
        stakingContracts[msg.sender][_stakingContract] = true;
        emit StakingContractAuthorized(msg.sender, _stakingContract);
    }

    /// @notice Gets the amount of granted tokens to the specified address.
    /// @param _owner The address to query the grants balance of.
    /// @return An uint256 representing the grants balance owned by the passed address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function stakeBalanceOf(address _address)
        public
        view
        returns (uint256 balance)
    {
        for (uint256 i = 0; i < grantIndices[_address].length; i++) {
            uint256 id = grantIndices[_address][i];
            balance += grants[id].staked;
        }
        return balance;
    }

    /// @notice Gets grant by ID. Returns only basic grant data.
    /// If you need unlocking schedule for the grant you must call `getGrantUnlockingSchedule()`
    /// This is to avoid Ethereum `Stack too deep` issue described here:
    /// https://forum.ethereum.org/discussion/2400/error-stack-too-deep-try-removing-local-variables
    /// @param _id ID of the token grant.
    /// @return amount The amount of tokens the grant provides.
    /// @return withdrawn The amount of tokens that have already been withdrawn
    ///                   from the grant.
    /// @return staked The amount of tokens that have been staked from the grant.
    /// @return revoked A boolean indicating whether the grant has been revoked,
    ///                 which is to say that it is no longer unlocking.
    /// @return grantee The grantee of grant.
    function getGrant(uint256 _id)
        public
        view
        returns (
            uint256 amount,
            uint256 withdrawn,
            uint256 staked,
            uint256 revokedAmount,
            uint256 revokedAt,
            address grantee
        )
    {
        return (
            grants[_id].amount,
            grants[_id].withdrawn,
            grants[_id].staked,
            grants[_id].revokedAmount,
            grants[_id].revokedAt,
            grants[_id].grantee
        );
    }

    /// @notice Gets grant unlocking schedule by grant ID.
    /// @param _id ID of the token grant.
    /// @return grantManager The address designated as the manager of the grant,
    ///                      which is the only address that can revoke this grant.
    /// @return duration The duration, in seconds, during which the tokens will
    ///                  unlocking linearly.
    /// @return start The start time, as a timestamp comparing to `now`.
    /// @return cliff The timestamp, before which none of the tokens in the grant
    ///               will be unlocked, and after which a linear amount based on
    ///               the time elapsed since the start will be unlocked.
    /// @return policy The address of the grant's staking policy.
    function getGrantUnlockingSchedule(uint256 _id)
        public
        view
        returns (
            address grantManager,
            uint256 duration,
            uint256 start,
            uint256 cliff,
            address policy
        )
    {
        return (
            grants[_id].grantManager,
            grants[_id].duration,
            grants[_id].start,
            grants[_id].cliff,
            address(grants[_id].stakingPolicy)
        );
    }

    /// @notice Gets grant ids of the specified address.
    /// @param _granteeOrGrantManager The address to query.
    /// @return An uint256 array of grant IDs.
    function getGrants(address _granteeOrGrantManager)
        public
        view
        returns (uint256[] memory)
    {
        return grantIndices[_granteeOrGrantManager];
    }

    /// @notice Gets operator addresses of the specified grantee address.
    /// @param grantee The grantee address.
    /// @return An array of all operators for a given grantee.
    function getGranteeOperators(address grantee)
        public
        view
        returns (address[] memory)
    {
        return granteesToOperators[grantee];
    }

    /// @notice Gets grant stake details of the given operator.
    /// @param operator The operator address.
    /// @return grantId ID of the token grant.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return stakingContract The address of staking contract.
    function getGrantStakeDetails(address operator)
        public
        view
        returns (
            uint256 grantId,
            uint256 amount,
            address stakingContract
        )
    {
        return grantStakes[operator].getDetails();
    }

    /// @notice Receives approval of token transfer and creates a token grant with a unlocking
    /// schedule where balance withdrawn to the grantee gradually in a linear fashion until
    /// start + duration. By then all of the balance will have unlocked.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _amount Approved amount for the transfer to create token grant.
    /// @param _token Token contract address.
    /// @param _extraData This byte array must have the following values ABI encoded:
    /// grantManager (address) Address of the grant manager.
    /// grantee (address) Address of the grantee.
    /// duration (uint256) Duration in seconds of the unlocking period.
    /// start (uint256) Timestamp at which unlocking will start.
    /// cliffDuration (uint256) Duration in seconds of the cliff;
    ///               no tokens will be unlocked until the time `start + cliff`.
    /// revocable (bool) Whether the token grant is revocable or not (1 or 0).
    /// stakingPolicy (address) Address of the staking policy for the grant.
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes memory _extraData
    ) public {
        require(
            ERC20Burnable(_token) == token,
            "Token contract must be the same one linked to this contract."
        );
        require(
            _amount <= token.balanceOf(_from),
            "Sender must have enough amount."
        );
        (
            address _grantManager,
            address _grantee,
            uint256 _duration,
            uint256 _start,
            uint256 _cliffDuration,
            bool _revocable,
            address _stakingPolicy
        ) =
            abi.decode(
                _extraData,
                (address, address, uint256, uint256, uint256, bool, address)
            );

        require(_grantee != address(0), "Grantee address can't be zero.");
        require(
            _cliffDuration <= _duration,
            "Unlocking cliff duration must be less or equal total unlocking duration."
        );

        require(_stakingPolicy != address(0), "Staking policy can't be zero.");

        uint256 id = numGrants++;
        grants[id] = Grant(
            _grantManager,
            _grantee,
            0,
            0,
            0,
            _revocable,
            _amount,
            _duration,
            _start,
            _start.add(_cliffDuration),
            0,
            0,
            GrantStakingPolicy(_stakingPolicy)
        );

        // Maintain a record to make it easier to query grants by grant manager.
        grantIndices[_from].push(id);

        // Maintain a record to make it easier to query grants by grantee.
        grantIndices[_grantee].push(id);

        token.safeTransferFrom(_from, address(this), _amount);

        // Maintain a record of the unlocked amount
        balances[_grantee] = balances[_grantee].add(_amount);
        emit TokenGrantCreated(id);
    }

    /// @notice Withdraws Token grant amount to grantee.
    /// @dev Transfers unlocked tokens of the token grant to grantee.
    /// @param _id Grant ID.
    function withdraw(uint256 _id) public {
        uint256 amount = withdrawable(_id);
        require(
            amount > 0,
            "Grant available to withdraw amount should be greater than zero."
        );

        // Update withdrawn amount.
        grants[_id].withdrawn = grants[_id].withdrawn.add(amount);

        // Update grantee grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(
            amount
        );

        // Transfer tokens from this contract balance to the grantee token balance.
        token.safeTransfer(grants[_id].grantee, amount);

        emit TokenGrantWithdrawn(_id, amount);
    }

    /// @notice Calculates and returns unlocked grant amount.
    /// @dev Calculates token grant amount that has already unlocked,
    /// including any tokens that have already been withdrawn by the grantee as well
    /// as any tokens that are available to withdraw but have not yet been withdrawn.
    /// @param _id Grant ID.
    function unlockedAmount(uint256 _id) public view returns (uint256) {
        Grant storage grant = grants[_id];
        return
            (grant.revokedAt != 0) // Grant revoked -> return what is remaining
                ? grant.amount.sub(grant.revokedAmount) // Not revoked -> calculate the unlocked amount normally
                : now.getUnlockedAmount(
                    grant.amount,
                    grant.duration,
                    grant.start,
                    grant.cliff
                );
    }

    /// @notice Calculates withdrawable granted amount.
    /// @dev Calculates the amount that has already unlocked but hasn't been withdrawn yet.
    /// @param _id Grant ID.
    function withdrawable(uint256 _id) public view returns (uint256) {
        uint256 unlocked = unlockedAmount(_id);
        uint256 withdrawn = grants[_id].withdrawn;
        uint256 staked = grants[_id].staked;

        if (withdrawn.add(staked) >= unlocked) {
            return 0;
        } else {
            return unlocked.sub(withdrawn).sub(staked);
        }
    }

    /// @notice Allows the grant manager to revoke the grant.
    /// @dev Granted tokens that are already unlocked (releasable amount)
    /// remain in the grant so grantee can still withdraw them
    /// the rest are revoked and withdrawable by token grant manager.
    /// @param _id Grant ID.
    function revoke(uint256 _id) public {
        require(
            grants[_id].grantManager == msg.sender,
            "Only grant manager can revoke."
        );
        require(
            grants[_id].revocable,
            "Grant must be revocable in the first place."
        );
        require(
            grants[_id].revokedAt == 0,
            "Grant must not be already revoked."
        );

        uint256 unlockedAmount = unlockedAmount(_id);
        uint256 revokedAmount = grants[_id].amount.sub(unlockedAmount);
        grants[_id].revokedAt = now;
        grants[_id].revokedAmount = revokedAmount;

        // Update grantee's grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(
            revokedAmount
        );
        emit TokenGrantRevoked(_id);
    }

    /// @notice Allows the grant manager to withdraw revoked tokens.
    /// @dev Will withdraw as many of the revoked tokens as possible
    /// without pushing the grant contract into a token deficit.
    /// If the grantee has staked more tokens than the unlocked amount,
    /// those tokens will remain in the grant until undelegated and returned,
    /// after which they can be withdrawn by calling `withdrawRevoked` again.
    /// @param _id Grant ID.
    function withdrawRevoked(uint256 _id) public {
        Grant storage grant = grants[_id];
        require(
            grant.grantManager == msg.sender,
            "Only grant manager can withdraw revoked tokens."
        );
        uint256 revoked = grant.revokedAmount;
        uint256 revokedWithdrawn = grant.revokedWithdrawn;
        require(revokedWithdrawn < revoked, "All revoked tokens withdrawn.");

        uint256 revokedRemaining = revoked.sub(revokedWithdrawn);

        uint256 totalAmount = grant.amount;
        uint256 staked = grant.staked;
        uint256 granteeWithdrawn = grant.withdrawn;
        uint256 remainingPresentInGrant =
            totalAmount.sub(staked).sub(revokedWithdrawn).sub(granteeWithdrawn);

        require(remainingPresentInGrant > 0, "No revoked tokens withdrawable.");

        uint256 amountToWithdraw =
            remainingPresentInGrant < revokedRemaining
                ? remainingPresentInGrant
                : revokedRemaining;
        token.safeTransfer(msg.sender, amountToWithdraw);
        grant.revokedWithdrawn += amountToWithdraw;
    }

    /// @notice Stake token grant.
    /// @dev Stakable token grant amount is determined
    /// by the grant's staking policy.
    /// @param _id Grant Id.
    /// @param _stakingContract Address of the staking contract.
    /// @param _amount Amount to stake.
    /// @param _extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes)
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes)
    function stake(
        uint256 _id,
        address _stakingContract,
        uint256 _amount,
        bytes memory _extraData
    ) public {
        require(
            grants[_id].grantee == msg.sender,
            "Only grantee of the grant can stake it."
        );
        require(grants[_id].revokedAt == 0, "Revoked grant can not be staked");
        require(
            stakingContracts[grants[_id].grantManager][_stakingContract],
            "Provided staking contract is not authorized."
        );

        // Expecting 60 bytes _extraData for stake delegation.
        require(
            _extraData.length == 60,
            "Stake delegation data must be provided."
        );
        address operator = _extraData.toAddress(20);

        // Calculate available amount. Amount of unlocked tokens minus what user already withdrawn and staked.
        require(
            _amount <= availableToStake(_id),
            "Must have available granted amount to stake."
        );

        // Keep staking record.
        TokenGrantStake grantStake =
            new TokenGrantStake(address(token), _id, _stakingContract);
        grantStakes[operator] = grantStake;
        granteesToOperators[grants[_id].grantee].push(operator);
        grants[_id].staked += _amount;

        token.transfer(address(grantStake), _amount);

        // Staking contract expects 40 bytes _extraData for stake delegation.
        // 20 bytes beneficiary's address + 20 bytes operator's address.
        grantStake.stake(_amount, _extraData);
        emit TokenGrantStaked(_id, _amount, operator);
    }

    ///  @notice Returns the amount of tokens available for staking from the grant.
    /// The stakeable amount is determined by the staking policy of the grant.
    /// If the grantee has withdrawn some tokens
    /// or the policy returns an erroneously high value,
    /// the stakeable amount is limited to the number of tokens remaining.
    /// @param _grantId Identifier of the grant
    function availableToStake(uint256 _grantId) public view returns (uint256) {
        Grant storage grant = grants[_grantId];
        // Revoked grants cannot be staked.
        // If the grant isn't revoked, the number of revoked tokens is 0.
        if (grant.revokedAt != 0) {
            return 0;
        }
        uint256 amount = grant.amount;
        uint256 withdrawn = grant.withdrawn;
        uint256 remaining = amount.sub(withdrawn);
        uint256 stakeable =
            grant.stakingPolicy.getStakeableAmount(
                now,
                amount,
                grant.duration,
                grant.start,
                grant.cliff,
                withdrawn
            );
        // Clamp the stakeable amount to what is left in the grant
        // in the case of a malfunctioning staking policy.
        if (stakeable > remaining) {
            stakeable = remaining;
        }

        return stakeable.sub(grant.staked);
    }

    /// @notice Cancels delegation within the operator initialization period
    /// without being subjected to the stake lockup for the undelegation period.
    /// This can be used to undo mistaken delegation to the wrong operator address.
    /// @param _operator Address of the stake operator.
    function cancelStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            msg.sender == _operator || msg.sender == grants[grantId].grantee,
            "Only operator or grantee can cancel the delegation."
        );

        uint256 returned = grantStake.cancelStake();
        grants[grantId].staked = grants[grantId].staked.sub(returned);
    }

    /// @notice Undelegate the token grant.
    /// @param _operator Operator of the stake.
    function undelegate(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            msg.sender == _operator || msg.sender == grants[grantId].grantee,
            "Only operator or grantee can undelegate."
        );

        grantStake.undelegate();
    }

    /// @notice Force cancellation of a revoked grant's stake.
    /// Can be used by the grant manager
    /// to immediately withdraw tokens back into the grant,
    /// from an operator still within the initialization period.
    /// These tokens can then be withdrawn
    /// if some revoked tokens haven't been withdrawn yet.
    function cancelRevokedStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(grants[grantId].revokedAt != 0, "Grant must be revoked");
        require(
            msg.sender == grants[grantId].grantManager,
            "Only grant manager can force cancellation of revoked grant stake."
        );

        uint256 returned = grantStake.cancelStake();
        grants[grantId].staked = grants[grantId].staked.sub(returned);
    }

    /// @notice Force undelegation of a revoked grant's stake.
    /// @dev Can be called by the grant manager once the grant is revoked.
    /// Has to be done this way, instead of undelegating all operators when the
    /// grant is revoked, because the latter method is vulnerable to DoS via
    /// out-of-gas.
    function undelegateRevoked(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(grants[grantId].revokedAt != 0, "Grant must be revoked");
        require(
            msg.sender == grants[grantId].grantManager,
            "Only grant manager can force undelegation of revoked grant stake"
        );

        grantStake.undelegate();
    }

    /// @notice Recover stake of the token grant.
    /// Recovers the tokens correctly
    /// even if they were earlier recovered directly in the staking contract.
    /// @param _operator Operator of the stake.
    function recoverStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 returned = grantStake.recoverStake();
        uint256 grantId = grantStake.getGrantId();
        grants[grantId].staked = grants[grantId].staked.sub(returned);

        delete grantStakes[_operator];
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./utils/OperatorParams.sol";

/// @title Stake Delegatable
/// @notice A base contract to allow stake delegation for staking contracts.
contract StakeDelegatable {
    using OperatorParams for uint256;

    mapping(address => Operator) internal operators;

    struct Operator {
        uint256 packedParams;
        address owner;
        address payable beneficiary;
        address authorizer;
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function balanceOf(address _address) public view returns (uint256 balance) {
        return operators[_address].packedParams.getAmount();
    }

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address _operator) public view returns (address) {
        return operators[_operator].owner;
    }

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable)
    {
        return operators[_operator].beneficiary;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address) {
        return operators[_operator].authorizer;
    }
}

pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./TokenGrant.sol";

/// @title ManagedGrant
/// @notice A managed grant acts as the grantee towards the token grant contract,
/// proxying instructions from the actual grantee.
/// The address used by the actual grantee
/// to issue instructions and withdraw tokens
/// can be reassigned with the consent of the grant manager.
contract ManagedGrant {
    using SafeERC20 for ERC20Burnable;

    ERC20Burnable public token;
    TokenGrant public tokenGrant;
    address public grantManager;
    uint256 public grantId;
    address public grantee;
    address public requestedNewGrantee;

    event GranteeReassignmentRequested(address newGrantee);
    event GranteeReassignmentConfirmed(address oldGrantee, address newGrantee);
    event GranteeReassignmentCancelled(address cancelledRequestedGrantee);
    event GranteeReassignmentChanged(
        address previouslyRequestedGrantee,
        address newRequestedGrantee
    );
    event TokensWithdrawn(address destination, uint256 amount);

    constructor(
        address _tokenAddress,
        address _tokenGrant,
        address _grantManager,
        uint256 _grantId,
        address _grantee
    ) public {
        token = ERC20Burnable(_tokenAddress);
        tokenGrant = TokenGrant(_tokenGrant);
        grantManager = _grantManager;
        grantId = _grantId;
        grantee = _grantee;
    }

    /// @notice Request a reassignment of the grantee address.
    /// Can only be called by the grantee.
    /// @param _newGrantee The requested new grantee.
    function requestGranteeReassignment(address _newGrantee)
        public
        onlyGrantee
        noRequestedReassignment
    {
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentRequested(_newGrantee);
    }

    /// @notice Cancel a pending grantee reassignment request.
    /// Can only be called by the grantee.
    function cancelReassignmentRequest()
        public
        onlyGrantee
        withRequestedReassignment
    {
        address cancelledGrantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentCancelled(cancelledGrantee);
    }

    /// @notice Change a pending reassignment request to a different grantee.
    /// Can only be called by the grantee.
    /// @param _newGrantee The address of the new requested grantee.
    function changeReassignmentRequest(address _newGrantee)
        public
        onlyGrantee
        withRequestedReassignment
    {
        address previouslyRequestedGrantee = requestedNewGrantee;
        require(
            previouslyRequestedGrantee != _newGrantee,
            "Unchanged reassignment request"
        );
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentChanged(
            previouslyRequestedGrantee,
            _newGrantee
        );
    }

    /// @notice Confirm a grantee reassignment request and set the new grantee as the grantee.
    /// Can only be called by the grant manager.
    /// @param _newGrantee The address of the new grantee.
    /// Must match the currently requested new grantee.
    function confirmGranteeReassignment(address _newGrantee)
        public
        onlyManager
        withRequestedReassignment
    {
        address oldGrantee = grantee;
        require(
            requestedNewGrantee == _newGrantee,
            "Reassignment address mismatch"
        );
        grantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentConfirmed(oldGrantee, _newGrantee);
    }

    /// @notice Withdraw all unlocked tokens from the grant.
    function withdraw() public onlyGrantee {
        require(
            requestedNewGrantee == address(0),
            "Can not withdraw with pending reassignment"
        );
        tokenGrant.withdraw(grantId);
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(grantee, amount);
        emit TokensWithdrawn(grantee, amount);
    }

    /// @notice Stake tokens from the grant.
    /// @param _stakingContract The contract to stake the tokens on.
    /// @param _amount The amount of tokens to stake.
    /// @param _extraData Data for the stake delegation.
    /// This byte array must have the following values concatenated:
    /// beneficiary address (20 bytes)
    /// operator address (20 bytes)
    /// authorizer address (20 bytes)
    function stake(
        address _stakingContract,
        uint256 _amount,
        bytes memory _extraData
    ) public onlyGrantee {
        tokenGrant.stake(grantId, _stakingContract, _amount, _extraData);
    }

    /// @notice Cancel delegating tokens to the given operator.
    function cancelStake(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.cancelStake(_operator);
    }

    /// @notice Begin undelegating tokens from the given operator.
    function undelegate(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.undelegate(_operator);
    }

    /// @notice Recover tokens previously staked and delegated to the operator.
    function recoverStake(address _operator) public {
        tokenGrant.recoverStake(_operator);
    }

    function _setRequestedNewGrantee(address _newGrantee) internal {
        require(_newGrantee != address(0), "Invalid new grantee address");
        require(_newGrantee != grantee, "New grantee same as current grantee");

        requestedNewGrantee = _newGrantee;
    }

    modifier withRequestedReassignment {
        require(requestedNewGrantee != address(0), "No reassignment requested");
        _;
    }

    modifier noRequestedReassignment {
        require(
            requestedNewGrantee == address(0),
            "Reassignment already requested"
        );
        _;
    }

    modifier onlyGrantee {
        require(msg.sender == grantee, "Only grantee may perform this action");
        _;
    }

    modifier onlyGranteeOr(address _operator) {
        require(
            msg.sender == grantee || msg.sender == _operator,
            "Only grantee or operator may perform this action"
        );
        _;
    }

    modifier onlyManager {
        require(
            msg.sender == grantManager,
            "Only grantManager may perform this action"
        );
        _;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

/// @dev Interface of recipient contract for approveAndCall pattern.
interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title KEEP Token
/// @dev Standard ERC20Burnable token
contract KeepToken is ERC20Burnable, ERC20Detailed {
    string public constant NAME = "KEEP Token";
    string public constant SYMBOL = "KEEP";
    uint8 public constant DECIMALS = 18; // The number of digits after the decimal place when displaying token values on-screen.
    uint256 public constant INITIAL_SUPPLY = 10**27; // 1 billion tokens, 18 decimal places.

    /// @dev Gives msg.sender all of existing tokens.
    constructor() public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Set allowance for other address and notify.
    /// Allows `_spender` to spend no more than `_value` tokens
    /// on your behalf and then ping the contract about it.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }
}

pragma solidity 0.5.17;

/// @title KeepRegistry
/// @notice Governance owned registry of approved contracts and roles.
contract KeepRegistry {
    enum ContractStatus {New, Approved, Disabled}

    // Governance role is to enable recovery from key compromise by rekeying
    // other roles. Also, it can disable operator contract panic buttons
    // permanently.
    address public governance;

    // Registry Keeper maintains approved operator contracts. Each operator
    // contract must be approved before it can be authorized by a staker or
    // used by a service contract.
    address public registryKeeper;

    // Each operator contract has a Panic Button which can disable malicious
    // or malfunctioning contract that have been previously approved by the
    // Registry Keeper.
    //
    // New operator contract added to the registry has a default panic button
    // value assigned (defaultPanicButton). Panic button for each operator
    // contract can be later updated by Governance to individual value.
    //
    // It is possible to disable panic button for individual contract by
    // setting the panic button to zero address. In such case, operator contract
    // can not be disabled and is permanently approved in the registry.
    mapping(address => address) public panicButtons;

    // Default panic button for each new operator contract added to the
    // registry. Can be later updated for each contract.
    address public defaultPanicButton;

    // Each service contract has a Operator Contract Upgrader whose purpose
    // is to manage operator contracts for that specific service contract.
    // The Operator Contract Upgrader can add new operator contracts to the
    // service contract’s operator contract list, and deprecate old ones.
    mapping(address => address) public operatorContractUpgraders;

    // Operator contract may have a Service Contract Upgrader whose purpose is
    // to manage service contracts for that specific operator contract.
    // Service Contract Upgrader can add and remove service contracts
    // from the list of service contracts approved to work with the operator
    // contract. List of service contracts is maintained in the operator
    // contract and is optional - not every operator contract needs to have
    // a list of service contracts it wants to cooperate with.
    mapping(address => address) public serviceContractUpgraders;

    // The registry of operator contracts
    mapping(address => ContractStatus) public operatorContracts;

    event OperatorContractApproved(address operatorContract);
    event OperatorContractDisabled(address operatorContract);

    event GovernanceUpdated(address governance);
    event RegistryKeeperUpdated(address registryKeeper);
    event DefaultPanicButtonUpdated(address defaultPanicButton);
    event OperatorContractPanicButtonDisabled(address operatorContract);
    event OperatorContractPanicButtonUpdated(
        address operatorContract,
        address panicButton
    );
    event OperatorContractUpgraderUpdated(
        address serviceContract,
        address upgrader
    );
    event ServiceContractUpgraderUpdated(
        address operatorContract,
        address keeper
    );

    modifier onlyGovernance() {
        require(governance == msg.sender, "Not authorized");
        _;
    }

    modifier onlyRegistryKeeper() {
        require(registryKeeper == msg.sender, "Not authorized");
        _;
    }

    modifier onlyPanicButton(address _operatorContract) {
        address panicButton = panicButtons[_operatorContract];
        require(panicButton != address(0), "Panic button disabled");
        require(panicButton == msg.sender, "Not authorized");
        _;
    }

    modifier onlyForNewContract(address _operatorContract) {
        require(
            isNewOperatorContract(_operatorContract),
            "Not a new operator contract"
        );
        _;
    }

    modifier onlyForApprovedContract(address _operatorContract) {
        require(
            isApprovedOperatorContract(_operatorContract),
            "Not an approved operator contract"
        );
        _;
    }

    constructor() public {
        governance = msg.sender;
        registryKeeper = msg.sender;
        defaultPanicButton = msg.sender;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceUpdated(governance);
    }

    function setRegistryKeeper(address _registryKeeper) public onlyGovernance {
        registryKeeper = _registryKeeper;
        emit RegistryKeeperUpdated(registryKeeper);
    }

    function setDefaultPanicButton(address _panicButton) public onlyGovernance {
        defaultPanicButton = _panicButton;
        emit DefaultPanicButtonUpdated(defaultPanicButton);
    }

    function setOperatorContractPanicButton(
        address _operatorContract,
        address _panicButton
    ) public onlyForApprovedContract(_operatorContract) onlyGovernance {
        require(
            panicButtons[_operatorContract] != address(0),
            "Disabled panic button cannot be updated"
        );
        require(
            _panicButton != address(0),
            "Panic button must be non-zero address"
        );

        panicButtons[_operatorContract] = _panicButton;

        emit OperatorContractPanicButtonUpdated(
            _operatorContract,
            _panicButton
        );
    }

    function disableOperatorContractPanicButton(address _operatorContract)
        public
        onlyForApprovedContract(_operatorContract)
        onlyGovernance
    {
        require(
            panicButtons[_operatorContract] != address(0),
            "Panic button already disabled"
        );

        panicButtons[_operatorContract] = address(0);

        emit OperatorContractPanicButtonDisabled(_operatorContract);
    }

    function setOperatorContractUpgrader(
        address _serviceContract,
        address _operatorContractUpgrader
    ) public onlyGovernance {
        operatorContractUpgraders[_serviceContract] = _operatorContractUpgrader;
        emit OperatorContractUpgraderUpdated(
            _serviceContract,
            _operatorContractUpgrader
        );
    }

    function setServiceContractUpgrader(
        address _operatorContract,
        address _serviceContractUpgrader
    ) public onlyGovernance {
        serviceContractUpgraders[_operatorContract] = _serviceContractUpgrader;
        emit ServiceContractUpgraderUpdated(
            _operatorContract,
            _serviceContractUpgrader
        );
    }

    function approveOperatorContract(address operatorContract)
        public
        onlyForNewContract(operatorContract)
        onlyRegistryKeeper
    {
        operatorContracts[operatorContract] = ContractStatus.Approved;
        panicButtons[operatorContract] = defaultPanicButton;
        emit OperatorContractApproved(operatorContract);
    }

    function disableOperatorContract(address operatorContract)
        public
        onlyForApprovedContract(operatorContract)
        onlyPanicButton(operatorContract)
    {
        operatorContracts[operatorContract] = ContractStatus.Disabled;
        emit OperatorContractDisabled(operatorContract);
    }

    function isNewOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.New;
    }

    function isApprovedOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.Approved;
    }

    function operatorContractUpgraderFor(address _serviceContract)
        public
        view
        returns (address)
    {
        return operatorContractUpgraders[_serviceContract];
    }

    function serviceContractUpgraderFor(address _operatorContract)
        public
        view
        returns (address)
    {
        return serviceContractUpgraders[_operatorContract];
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

/// @title Keep Random Beacon
///
/// @notice Keep Random Beacon generates verifiable randomness that is resistant
/// to bad actors both in the relay network and on the anchoring blockchain.
interface IRandomBeacon {
    /// @notice Event emitted for each new relay entry generated. It contains
    /// request ID allowing to associate the generated relay entry with relay
    /// request created previously with `requestRelayEntry` function. Event is
    /// emitted no matter if callback was executed or not.
    ///
    /// @param requestId Relay request ID for which entry was generated.
    /// @param entry Generated relay entry.
    event RelayEntryGenerated(uint256 requestId, uint256 entry);

    /// @notice Provides the customer with an estimated entry fee in wei to use
    /// in the request. The fee estimate is only valid for the transaction it is
    /// called in, so the customer must make the request immediately after
    /// obtaining the estimate. Insufficient payment will lead to the request
    /// being rejected and the transaction reverted.
    ///
    /// The customer may decide to provide more ether for an entry fee than
    /// estimated by this function. This is especially helpful when callback gas
    /// cost fluctuates. Any surplus between the passed fee and the actual cost
    /// of producing an entry and executing a callback is returned back to the
    /// customer.
    /// @param callbackGas Gas required for the callback.
    function entryFeeEstimate(uint256 callbackGas)
        external
        view
        returns (uint256);

    /// @notice Submits a request to generate a new relay entry. Executes
    /// callback on the provided callback contract with the generated entry and
    /// emits `RelayEntryGenerated(uint256 requestId, uint256 entry)` event.
    /// Callback contract has to declare public `__beaconCallback(uint256)`
    /// function that is going to be executed with the result, once ready.
    /// It is recommended to implement `IRandomBeaconConsumer` interface to
    /// ensure the correct callback function signature.
    ///
    /// @dev Beacon does not support concurrent relay requests. No new requests
    /// should be made while the beacon is already processing another request.
    /// Requests made while the beacon is busy will be rejected and the
    /// transaction reverted.
    ///
    /// @param callbackContract Callback contract address. Callback is called
    /// once a new relay entry has been generated. Must declare public
    /// `__beaconCallback(uint256)` function. It is recommended to implement
    /// `IRandomBeaconConsumer` interface to ensure the correct callback function
    /// signature.
    /// @param callbackGas Gas required for the callback.
    /// The customer needs to ensure they provide a sufficient callback gas
    /// to cover the gas fee of executing the callback. Any surplus is returned
    /// to the customer. If the callback gas amount turns to be not enough to
    /// execute the callback, callback execution is skipped.
    /// @return An uint256 representing uniquely generated relay request ID
    function requestRelayEntry(address callbackContract, uint256 callbackGas)
        external
        payable
        returns (uint256);

    /// @notice Submits a request to generate a new relay entry. Emits
    /// `RelayEntryGenerated(uint256 requestId, uint256 entry)` event for the
    /// generated entry.
    ///
    /// @dev Beacon does not support concurrent relay requests. No new requests
    /// should be made while the beacon is already processing another request.
    /// Requests made while the beacon is busy will be rejected and the
    /// transaction reverted.
    ///
    /// @return An uint256 representing uniquely generated relay request ID
    function requestRelayEntry() external payable returns (uint256);
}

/// @title Keep Random Beacon Consumer
///
/// @notice Receives Keep Random Beacon relay entries with `__beaconCallback`
/// function. Contract implementing this interface does not have to be the one
/// requesting relay entry but it is the one receiving the requested relay entry
/// once it is produced.
///
/// @dev Use this interface to indicate the contract receives relay entries from
/// the beacon and to ensure the correctness of callback function signature.
interface IRandomBeaconConsumer {
    /// @notice Receives relay entry produced by Keep Random Beacon. This function
    /// should be called only by Keep Random Beacon.
    ///
    /// @param relayEntry Relay entry (random number) produced by Keep Random
    /// Beacon.
    function __beaconCallback(uint256 relayEntry) external;
}

pragma solidity 0.5.17;

/// @title GrantStakingPolicy
/// @notice A staking policy defines the function `getStakeableAmount`
/// which calculates how many tokens may be staked from a token grant.
contract GrantStakingPolicy {
    function getStakeableAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff,
        uint256 withdrawn
    ) public view returns (uint256);
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./KeepRegistry.sol";

/// @title AuthorityDelegator
/// @notice An operator contract can delegate authority to other operator
/// contracts by implementing the AuthorityDelegator interface.
///
/// To delegate authority,
/// the recipient of delegated authority must call `claimDelegatedAuthority`,
/// specifying the contract it wants delegated authority from.
/// The staking contract calls `delegator.__isRecognized(recipient)`
/// and if the call returns `true`,
/// the named delegator contract is set as the recipient's authority delegator.
/// Any future checks of registry approval or per-operator authorization
/// will transparently mirror the delegator's status.
///
/// Authority can be delegated recursively;
/// an operator contract receiving delegated authority
/// can recognize other operator contracts as recipients of its authority.
interface AuthorityDelegator {
    function __isRecognized(address delegatedAuthorityRecipient)
        external
        returns (bool);
}

/// @title AuthorityVerifier
/// @notice An operator contract can delegate authority to other operator
/// contracts. Entry in the registry is not updated and source contract remains
/// listed there as authorized. This interface is a verifier that support verification
/// of contract authorization in case of authority delegation from the source contract.
interface AuthorityVerifier {
    /// @notice Returns true if the given operator contract has been approved
    /// for use. The function never reverts.
    function isApprovedOperatorContract(address _operatorContract)
        external
        view
        returns (bool);
}

contract Authorizations is AuthorityVerifier {
    // Authorized operator contracts.
    mapping(address => mapping(address => bool)) internal authorizations;

    // Granters of delegated authority to operator contracts.
    // E.g. keep factories granting delegated authority to keeps.
    // `delegatedAuthority[keep] = factory`
    mapping(address => address) internal delegatedAuthority;

    // Registry contract with a list of approved operator contracts and upgraders.
    KeepRegistry internal registry;

    modifier onlyApprovedOperatorContract(address operatorContract) {
        require(
            isApprovedOperatorContract(operatorContract),
            "Operator contract unapproved"
        );
        _;
    }

    constructor(KeepRegistry _registry) public {
        registry = _registry;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address);

    /// @notice Authorizes operator contract to access staked token balance of
    /// the provided operator. Can only be executed by stake operator authorizer.
    /// Contracts using delegated authority
    /// cannot be authorized with `authorizeOperatorContract`.
    /// Instead, authorize `getAuthoritySource(_operatorContract)`.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function authorizeOperatorContract(
        address _operator,
        address _operatorContract
    ) public onlyApprovedOperatorContract(_operatorContract) {
        require(
            authorizerOf(_operator) == msg.sender,
            "Not operator authorizer"
        );
        require(
            getAuthoritySource(_operatorContract) == _operatorContract,
            "Delegated authority used"
        );
        authorizations[_operatorContract][_operator] = true;
    }

    /// @notice Checks if operator contract has access to the staked token balance of
    /// the provided operator.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool) {
        return authorizations[getAuthoritySource(_operatorContract)][_operator];
    }

    /// @notice Grant the sender the same authority as `delegatedAuthoritySource`
    /// @dev If `delegatedAuthoritySource` is an approved operator contract
    /// and recognizes the claimant, this relationship will be recorded in
    /// `delegatedAuthority`. Later, the claimant can slash, seize, place locks etc.
    /// on operators that have authorized the `delegatedAuthoritySource`.
    /// If the `delegatedAuthoritySource` is disabled with the panic button,
    /// any recipients of delegated authority from it will also be disabled.
    function claimDelegatedAuthority(address delegatedAuthoritySource)
        public
        onlyApprovedOperatorContract(delegatedAuthoritySource)
    {
        require(
            AuthorityDelegator(delegatedAuthoritySource).__isRecognized(
                msg.sender
            ),
            "Unrecognized claimant"
        );
        delegatedAuthority[msg.sender] = delegatedAuthoritySource;
    }

    /// @notice Checks if the operator contract is authorized in the registry.
    /// If the contract uses delegated authority it checks authorization of the
    /// source contract.
    /// @param _operatorContract address of operator contract.
    /// @return True if operator contract is approved, false if operator contract
    /// has not been approved or if it was disabled by the panic button.
    function isApprovedOperatorContract(address _operatorContract)
        public
        view
        returns (bool)
    {
        return
            registry.isApprovedOperatorContract(
                getAuthoritySource(_operatorContract)
            );
    }

    /// @notice Get the source of the operator contract's authority.
    /// If the contract uses delegated authority,
    /// returns the original source of the delegated authority.
    /// If the contract doesn't use delegated authority,
    /// returns the contract itself.
    /// Authorize `getAuthoritySource(operatorContract)`
    /// to grant `operatorContract` the authority to penalize an operator.
    function getAuthoritySource(address operatorContract)
        public
        view
        returns (address)
    {
        address delegatedAuthoritySource = delegatedAuthority[operatorContract];
        if (delegatedAuthoritySource == address(0)) {
            return operatorContract;
        }
        return getAuthoritySource(delegatedAuthoritySource);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "@keep-network/sortition-pools/contracts/api/IBonding.sol";

contract IBondingManagement is IBonding {
    /// @notice Add the provided value to operator's pool available for bonding.
    /// @param operator Address of the operator.
    function deposit(address operator) public payable;

    /// @notice Withdraws amount from operator's value available for bonding.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public;

    /// @notice Create bond for the given operator, holder, reference and amount.
    /// @param operator Address of the operator to bond.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID used to track the bond by holder.
    /// @param amount Value to bond in wei.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount,
        address authorizedSortitionPool
    ) public;

    /// @notice Returns value of wei bonded for the operator.
    /// @param operator Address of the operator.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID of the bond.
    /// @return Amount of wei in the selected bond.
    function bondAmount(
        address operator,
        address holder,
        uint256 referenceID
    ) public view returns (uint256);

    /// @notice Reassigns a bond to a new holder under a new reference.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param newHolder Address of the new holder of the bond.
    /// @param newReferenceID New reference ID to register the bond.
    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) public;

    /// @notice Releases the bond and moves the bond value to the operator's
    /// unbounded value pool.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    function freeBond(address operator, uint256 referenceID) public;

    /// @notice Seizes the bond by moving some or all of the locked bond to the
    /// provided destination address.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param amount Amount to be seized.
    /// @param destination Address to send the amount to.
    function seizeBond(
        address operator,
        uint256 referenceID,
        uint256 amount,
        address payable destination
    ) public;
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

/// @title Bonded ECDSA Keep Factory
/// @notice Factory for Bonded ECDSA Keeps.
interface IBondedECDSAKeepFactory {
    /// @notice Open a new ECDSA Keep.
    /// @param _groupSize Number of members in the keep.
    /// @param _honestThreshold Minimum number of honest keep members.
    /// @param _owner Address of the keep owner.
    /// @param _bond Value of ETH bond required from the keep.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    /// @return Address of the opened keep.
    function openKeep(
        uint256 _groupSize,
        uint256 _honestThreshold,
        address _owner,
        uint256 _bond,
        uint256 _stakeLockDuration
    ) external payable returns (address keepAddress);

    /// @notice Gets a fee estimate for opening a new keep.
    /// @return Uint256 estimate.
    function openKeepFeeEstimate() external view returns (uint256);

    /// @notice Gets the total weight of operators
    /// in the sortition pool for the given application.
    /// @param _application Address of the application.
    /// @return The sum of all registered operators' weights in the pool.
    /// Reverts if sortition pool for the application does not exist.
    function getSortitionPoolWeight(address _application)
        external
        view
        returns (uint256);

    /// @notice Sets the minimum bondable value required from the operator to
    /// join the sortition pool of the given application. It is up to the
    /// application to specify a reasonable minimum bond for operators trying to
    /// join the pool to prevent griefing by operators joining without enough
    /// bondable value.
    /// @dev The default minimum bond value for each sortition pool created
    /// is 20 ETH.
    /// @param _minimumBondableValue The minimum unbonded value the application
    /// requires from a single keep.
    /// @param _groupSize Number of signers in the keep.
    /// @param _honestThreshold Minimum number of honest keep signers.
    function setMinimumBondableValue(
        uint256 _minimumBondableValue,
        uint256 _groupSize,
        uint256 _honestThreshold
    ) external;
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

/// @title ECDSA Keep
/// @notice Contract reflecting an ECDSA keep.
contract IBondedECDSAKeep {
    /// @notice Returns public key of this keep.
    /// @return Keeps's public key.
    function getPublicKey() external view returns (bytes memory);

    /// @notice Returns the amount of the keep's ETH bond in wei.
    /// @return The amount of the keep's ETH bond in wei.
    function checkBondAmount() external view returns (uint256);

    /// @notice Calculates a signature over provided digest by the keep. Note that
    /// signatures from the keep not explicitly requested by calling `sign`
    /// will be provable as fraud via `submitSignatureFraud`.
    /// @param _digest Digest to be signed.
    function sign(bytes32 _digest) external;

    /// @notice Distributes ETH reward evenly across keep signer beneficiaries.
    /// @dev Only the value passed to this function is distributed.
    function distributeETHReward() external payable;

    /// @notice Distributes ERC20 reward evenly across keep signer beneficiaries.
    /// @dev This works with any ERC20 token that implements a transferFrom
    /// function.
    /// This function only has authority over pre-approved
    /// token amount. We don't explicitly check for allowance, SafeMath
    /// subtraction overflow is enough protection.
    /// @param _tokenAddress Address of the ERC20 token to distribute.
    /// @param _value Amount of ERC20 token to distribute.
    function distributeERC20Reward(address _tokenAddress, uint256 _value)
        external;

    /// @notice Seizes the signers' ETH bonds. After seizing bonds keep is
    /// terminated so it will no longer respond to signing requests. Bonds can
    /// be seized only when there is no signing in progress or requested signing
    /// process has timed out. This function seizes all of signers' bonds.
    /// The application may decide to return part of bonds later after they are
    /// processed using returnPartialSignerBonds function.
    function seizeSignerBonds() external;

    /// @notice Returns partial signer's ETH bonds to the pool as an unbounded
    /// value. This function is called after bonds have been seized and processed
    /// by the privileged application after calling seizeSignerBonds function.
    /// It is entirely up to the application if a part of signers' bonds is
    /// returned. The application may decide for that but may also decide to
    /// seize bonds and do not return anything.
    function returnPartialSignerBonds() external payable;

    /// @notice Submits a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign.
    /// @dev The function expects the signed digest to be calculated as a sha256
    /// hash of the preimage: `sha256(_preimage)`.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, error otherwise.
    function submitSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes calldata _preimage
    ) external returns (bool _isFraud);

    /// @notice Closes keep when no longer needed. Releases bonds to the keep
    /// members. Keep can be closed only when there is no signing in progress or
    /// requested signing process has timed out.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() external;
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./CloneFactory.sol";

contract KeepCreator is CloneFactory {
    // Holds the address of the keep contract that will be used as a master
    // contract for cloning.
    address public masterKeepAddress;

    // Keeps created by this factory.
    address[] public keeps;

    // Maps keep opened timestamp to each keep address
    mapping(address => uint256) keepOpenedTimestamp;

    constructor(address _masterKeepAddress) public {
        masterKeepAddress = _masterKeepAddress;
    }

    /// @notice Gets how many keeps have been opened by this contract.
    /// @dev    Checks the size of the keeps array.
    /// @return The number of keeps opened so far.
    function getKeepCount() external view returns (uint256) {
        return keeps.length;
    }

    /// @notice Gets a specific keep address at a given index.
    /// @return The address of the keep at the given index.
    function getKeepAtIndex(uint256 index) external view returns (address) {
        require(index < keeps.length, "Out of bounds.");
        return keeps[index];
    }

    /// @notice Gets the opened timestamp of the given keep.
    /// @return Timestamp the given keep was opened at or 0 if this keep
    /// was not created by this factory.
    function getKeepOpenedTimestamp(address _keep)
        external
        view
        returns (uint256)
    {
        return keepOpenedTimestamp[_keep];
    }

    /// @notice Creates a new keep instance with a clone factory.
    /// @dev It has to be called by a function implementing a keep opening mechanism.
    function createKeep() internal returns (address keepAddress) {
        keepAddress = createClone(masterKeepAddress);
        keeps.push(keepAddress);

        /* solium-disable-next-line security/no-block-members*/
        keepOpenedTimestamp[keepAddress] = block.timestamp;
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./AbstractBonding.sol";

import "@keep-network/keep-core/contracts/TokenGrant.sol";
import "@keep-network/keep-core/contracts/libraries/RolesLookup.sol";

/// @title Keep Bonding
/// @notice Contract holding deposits from keeps' operators.
contract KeepBonding is AbstractBonding {
    using RolesLookup for address payable;

    // KEEP Token Staking contract.
    TokenStaking internal tokenStaking;

    // KEEP token grant contract.
    TokenGrant internal tokenGrant;

    /// @notice Initializes Keep Bonding contract.
    /// @param registryAddress Keep registry contract address.
    /// @param tokenStakingAddress KEEP token staking contract address.
    /// @param tokenGrantAddress KEEP token grant contract address.
    constructor(
        address registryAddress,
        address tokenStakingAddress,
        address tokenGrantAddress
    ) public AbstractBonding(registryAddress) {
        tokenStaking = TokenStaking(tokenStakingAddress);
        tokenGrant = TokenGrant(tokenGrantAddress);
    }

    /// @notice Withdraws amount from operator's value available for bonding.
    /// Should not be used by grantee of managed grants. For this case,
    /// please use `withdrawAsManagedGrantee`.
    ///
    /// This function can be called only by:
    /// - operator,
    /// - liquid, staked tokens owner (not a grant),
    /// - direct staked tokens grantee (not a managed grant).
    ///
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public {
        require(
            msg.sender == operator ||
                msg.sender.isTokenOwnerForOperator(operator, tokenStaking) ||
                msg.sender.isGranteeForOperator(operator, tokenGrant),
            "Only operator or the owner is allowed to withdraw bond"
        );

        withdrawBond(amount, operator);
    }

    /// @notice Withdraws amount from operator's value available for bonding.
    /// Can be called only by staked tokens managed grantee.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    /// @param managedGrant Address of the managed grant contract.
    function withdrawAsManagedGrantee(
        uint256 amount,
        address operator,
        address managedGrant
    ) public {
        require(
            msg.sender.isManagedGranteeForOperator(
                operator,
                managedGrant,
                tokenGrant
            ),
            "Only grantee is allowed to withdraw bond"
        );

        withdrawBond(amount, operator);
    }

    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool) {
        return
            tokenStaking.isAuthorizedForOperator(_operator, _operatorContract);
    }

    function authorizerOf(address _operator) public view returns (address) {
        return tokenStaking.authorizerOf(_operator);
    }

    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable)
    {
        return tokenStaking.beneficiaryOf(_operator);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "@keep-network/keep-core/contracts/IRandomBeacon.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract GroupSelectionSeed is IRandomBeaconConsumer, ReentrancyGuard {
    using SafeMath for uint256;

    IRandomBeacon randomBeacon;

    // Gas required for a callback from the random beacon. The value specifies
    // gas required to call `__beaconCallback` function in the worst-case
    // scenario with all the checks and maximum allowed uint256 relay entry as
    // a callback parameter.
    uint256 public constant callbackGas = 30000;

    // Random beacon sends back callback surplus to the requestor. It may also
    // decide to send additional request subsidy fee. What's more, it may happen
    // that the beacon is busy and we will not refresh group selection seed from
    // the beacon. We accumulate all funds received from the beacon in the
    // reseed pool and later use this pool to reseed using a public reseed
    // function on a manual request at any moment.
    uint256 public reseedPool;

    uint256 public groupSelectionSeed;

    constructor(address _randomBeacon) public {
        randomBeacon = IRandomBeacon(_randomBeacon);

        // Initial value before the random beacon updates the seed.
        // https://www.wolframalpha.com/input/?i=pi+to+78+digits
        groupSelectionSeed = 31415926535897932384626433832795028841971693993751058209749445923078164062862;
    }

    /// @notice Adds any received funds to the reseed pool.
    function() external payable {
        reseedPool += msg.value;
    }

    /// @notice Sets a new group selection seed value.
    /// @dev The function is expected to be called in a callback by the random
    /// beacon.
    /// @param _relayEntry Beacon output.
    function __beaconCallback(uint256 _relayEntry) external onlyRandomBeacon {
        groupSelectionSeed = _relayEntry;
    }

    /// @notice Gets a fee estimate for a new random entry.
    /// @return Uint256 estimate.
    function newEntryFeeEstimate() public view returns (uint256) {
        return randomBeacon.entryFeeEstimate(callbackGas);
    }

    /// @notice Calculates the fee requestor has to pay to reseed the factory
    /// for signer selection. Depending on how much value is stored in the
    /// reseed pool and the price of a new relay entry, returned value may vary.
    function newGroupSelectionSeedFee() public view returns (uint256) {
        uint256 beaconFee = randomBeacon.entryFeeEstimate(callbackGas);
        return beaconFee <= reseedPool ? 0 : beaconFee.sub(reseedPool);
    }

    /// @notice Reseeds the value used for a signer selection. Requires enough
    /// payment to be passed. The required payment can be calculated using
    /// reseedFee function. Factory is automatically triggering reseeding after
    /// opening a new keep but the reseed can be also triggered at any moment
    /// using this function.
    function requestNewGroupSelectionSeed() public payable nonReentrant {
        reseedPool = reseedPool.add(msg.value);

        uint256 beaconFee = randomBeacon.entryFeeEstimate(callbackGas);
        require(reseedPool >= beaconFee, "Not enough funds to trigger reseed");
        reseedPool = reseedPool.sub(beaconFee);

        (bool success, bytes memory returnData) = requestRelayEntry(beaconFee);
        if (!success) {
            revert(string(returnData));
        }
    }

    /// @notice Updates group selection seed.
    /// @dev The main goal of this function is to request the random beacon to
    /// generate a new random number. The beacon generates the number asynchronously
    /// and will call a callback function when the number is ready. In the meantime
    /// we update current group selection seed to a new value using a hash function.
    /// In case of the random beacon request failure this function won't revert
    /// but add beacon payment to factory's reseed pool.
    function newGroupSelectionSeed() internal {
        // Calculate new group selection seed based on the current seed.
        // We added address of the factory as a key to calculate value different
        // than sortition pool RNG will, so we don't end up selecting almost
        // identical group.
        groupSelectionSeed = uint256(
            keccak256(abi.encodePacked(groupSelectionSeed, address(this)))
        );

        // Call the random beacon to get a random group selection seed.
        (bool success, ) = requestRelayEntry(msg.value);
        if (!success) {
            reseedPool += msg.value;
        }
    }

    /// @notice Requests for a relay entry using the beacon payment provided as
    /// the parameter.
    function requestRelayEntry(uint256 payment)
        internal
        returns (bool, bytes memory)
    {
        return
            address(randomBeacon).call.value(payment)(
                abi.encodeWithSignature(
                    "requestRelayEntry(address,uint256)",
                    address(this),
                    callbackGas
                )
            );
    }

    /// @notice Checks if the caller is the random beacon.
    /// @dev Throws an error if called by any account other than the random beacon.
    modifier onlyRandomBeacon() {
        require(
            address(randomBeacon) == msg.sender,
            "Caller is not the random beacon"
        );
        _;
    }
}

pragma solidity 0.5.17;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

// Implementation of [EIP-1167] based on [clone-factory]
// source code.
//
// EIP 1167: https://eips.ethereum.org/EIPS/eip-1167
// clone-factory: https://github.com/optionality/clone-factory
// Modified to use ^0.5.10; instead of ^0.4.23 solidity version
//
// TODO: This code is copied from tbtc repo. We should consider pulling the code
// and tests to a common repo.
/* solium-disable */

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

pragma solidity 0.5.17;

import "@keep-network/sortition-pools/contracts/AbstractSortitionPool.sol";

contract CandidatesPools {
    // Notification that a new sortition pool has been created.
    event SortitionPoolCreated(
        address indexed application,
        address sortitionPool
    );

    // Mapping of pools with registered member candidates for each application.
    mapping(address => address) candidatesPools; // application -> candidates pool

    /// @notice Creates new sortition pool for the application.
    /// @dev Emits an event after sortition pool creation.
    /// @param _application Address of the application.
    /// @return Address of the created sortition pool contract.
    function createSortitionPool(address _application)
        external
        returns (address)
    {
        require(
            candidatesPools[_application] == address(0),
            "Sortition pool already exists"
        );

        address sortitionPoolAddress = newSortitionPool(_application);

        candidatesPools[_application] = sortitionPoolAddress;

        emit SortitionPoolCreated(_application, sortitionPoolAddress);

        return candidatesPools[_application];
    }

    /// @notice Register caller as a candidate to be selected as keep member
    /// for the provided customer application.
    /// @dev If caller is already registered it returns without any changes.
    /// @param _application Address of the application.
    function registerMemberCandidate(address _application) external {
        AbstractSortitionPool candidatesPool =
            AbstractSortitionPool(getSortitionPool(_application));

        address operator = msg.sender;
        if (!candidatesPool.isOperatorInPool(operator)) {
            candidatesPool.joinPool(operator);
        }
    }

    /// @notice Checks if operator's details in the member candidates pool are
    /// up to date for the given application. If not update operator status
    /// function should be called by the one who is monitoring the status.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function isOperatorUpToDate(address _operator, address _application)
        external
        view
        returns (bool)
    {
        return
            getSortitionPoolForOperator(_operator, _application)
                .isOperatorUpToDate(_operator);
    }

    /// @notice Invokes update of operator's details in the member candidates pool
    /// for the given application
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function updateOperatorStatus(address _operator, address _application)
        external
    {
        getSortitionPoolForOperator(_operator, _application)
            .updateOperatorStatus(_operator);
    }

    /// @notice Gets the sortition pool address for the given application.
    /// @dev Reverts if sortition does not exist for the application.
    /// @param _application Address of the application.
    /// @return Address of the sortition pool contract.
    function getSortitionPool(address _application)
        public
        view
        returns (address)
    {
        require(
            candidatesPools[_application] != address(0),
            "No pool found for the application"
        );

        return candidatesPools[_application];
    }

    /// @notice Checks if operator is registered as a candidate for the given
    /// customer application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    /// @return True if operator is already registered in the candidates pool,
    /// false otherwise.
    function isOperatorRegistered(address _operator, address _application)
        public
        view
        returns (bool)
    {
        if (candidatesPools[_application] == address(0)) {
            return false;
        }

        AbstractSortitionPool candidatesPool =
            AbstractSortitionPool(candidatesPools[_application]);

        return candidatesPool.isOperatorRegistered(_operator);
    }

    /// @notice Checks if given operator is eligible for the given application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    function isOperatorEligible(address _operator, address _application)
        public
        view
        returns (bool)
    {
        if (candidatesPools[_application] == address(0)) {
            return false;
        }

        AbstractSortitionPool candidatesPool =
            AbstractSortitionPool(candidatesPools[_application]);

        return candidatesPool.isOperatorEligible(_operator);
    }

    /// @notice Gets the total weight of operators
    /// in the sortition pool for the given application.
    /// @dev Reverts if sortition does not exits for the application.
    /// @param _application Address of the application.
    /// @return The sum of all registered operators' weights in the pool.
    /// Reverts if sortition pool for the application does not exist.
    function getSortitionPoolWeight(address _application)
        public
        view
        returns (uint256)
    {
        return
            AbstractSortitionPool(getSortitionPool(_application)).totalWeight();
    }

    /// @notice Creates new sortition pool for the application.
    /// @dev Have to be implemented by keep factory to call desired sortition
    /// pool factory.
    /// @param _application Address of the application.
    /// @return Address of the created sortition pool contract.
    function newSortitionPool(address _application) internal returns (address);

    /// @notice Gets bonded sortition pool of specific application for the
    /// operator.
    /// @dev Reverts if the operator is not registered for the application.
    /// @param _operator Operator's address.
    /// @param _application Customer application address.
    /// @return Bonded sortition pool.
    function getSortitionPoolForOperator(
        address _operator,
        address _application
    ) internal view returns (AbstractSortitionPool) {
        require(
            isOperatorRegistered(_operator, _application),
            "Operator not registered for the application"
        );

        return AbstractSortitionPool(candidatesPools[_application]);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./AbstractBondedECDSAKeep.sol";
import "./BondedECDSAKeepFactory.sol";

import "@keep-network/keep-core/contracts/TokenStaking.sol";

/// @title Bonded ECDSA Keep
/// @notice ECDSA keep with additional signer bond requirement.
/// @dev This contract is used as a master contract for clone factory in
/// BondedECDSAKeepFactory as per EIP-1167.
contract BondedECDSAKeep is AbstractBondedECDSAKeep {
    // Stake that was required from each keep member on keep creation.
    // The value is used for keep members slashing.
    uint256 public memberStake;

    // Emitted when KEEP token slashing failed when submitting signature
    // fraud proof. In practice, this situation should never happen but we want
    // to be very explicit in this contract and protect the owner that even if
    // it happens, the transaction submitting fraud proof is not going to fail
    // and keep owner can seize and liquidate bonds in the same transaction.
    event SlashingFailed();

    TokenStaking tokenStaking;

    /// @notice Initialization function.
    /// @dev We use clone factory to create new keep. That is why this contract
    /// doesn't have a constructor. We provide keep parameters for each instance
    /// function after cloning instances from the master contract.
    /// @param _owner Address of the keep owner.
    /// @param _members Addresses of the keep members.
    /// @param _honestThreshold Minimum number of honest keep members.
    /// @param _memberStake Stake required from each keep member.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    /// @param _tokenStaking Address of the TokenStaking contract.
    /// @param _keepBonding Address of the KeepBonding contract.
    /// @param _keepFactory Address of the BondedECDSAKeepFactory that created
    /// this keep.
    function initialize(
        address _owner,
        address[] memory _members,
        uint256 _honestThreshold,
        uint256 _memberStake,
        uint256 _stakeLockDuration,
        address _tokenStaking,
        address _keepBonding,
        address payable _keepFactory
    ) public {
        super.initialize(_owner, _members, _honestThreshold, _keepBonding);

        memberStake = _memberStake;
        tokenStaking = TokenStaking(_tokenStaking);

        tokenStaking.claimDelegatedAuthority(_keepFactory);

        lockMemberStakes(_stakeLockDuration);
    }

    /// @notice Closes keep when owner decides that they no longer need it.
    /// Releases bonds to the keep members. Keep can be closed only when
    /// there is no signing in progress or requested signing process has timed out.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() public onlyOwner onlyWhenActive {
        super.closeKeep();
        unlockMemberStakes();
    }

    /// @notice Terminates the keep.
    function terminateKeep() internal {
        super.terminateKeep();
        unlockMemberStakes();
    }

    function slashForSignatureFraud() internal {
        /* solium-disable-next-line */
        (bool success, ) =
            address(tokenStaking).call(
                abi.encodeWithSignature(
                    "slash(uint256,address[])",
                    memberStake,
                    members
                )
            );

        // Should never happen but we want to protect the owner and make sure the
        // fraud submission transaction does not fail so that the owner can
        // seize and liquidate bonds in the same transaction.
        if (!success) {
            emit SlashingFailed();
        }
    }

    /// @notice Creates locks on members' token stakes.
    /// @param _stakeLockDuration Stake lock duration in seconds.
    function lockMemberStakes(uint256 _stakeLockDuration) internal {
        for (uint256 i = 0; i < members.length; i++) {
            tokenStaking.lockStake(members[i], _stakeLockDuration);
        }
    }

    /// @notice Releases locks the keep had previously placed on the members'
    /// token stakes.
    function unlockMemberStakes() internal {
        for (uint256 i = 0; i < members.length; i++) {
            tokenStaking.unlockStake(members[i]);
        }
    }

    /// @notice Gets the beneficiary for the specified member address.
    /// @param _member Member address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _member)
        internal
        view
        returns (address payable)
    {
        return tokenStaking.beneficiaryOf(_member);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./api/IBondingManagement.sol";

import "@keep-network/keep-core/contracts/KeepRegistry.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @title Abstract Bonding
/// @notice Contract holding deposits from keeps' operators.
contract AbstractBonding is IBondingManagement {
    using SafeMath for uint256;

    // Registry contract with a list of approved factories (operator contracts).
    KeepRegistry internal registry;

    // Unassigned value in wei deposited by operators.
    mapping(address => uint256) public unbondedValue;

    // References to created bonds. Bond identifier is built from operator's
    // address, holder's address and reference ID assigned on bond creation.
    mapping(bytes32 => uint256) internal lockedBonds;

    // Sortition pools authorized by operator's authorizer.
    // operator -> pool -> boolean
    mapping(address => mapping(address => bool)) internal authorizedPools;

    event UnbondedValueDeposited(
        address indexed operator,
        address indexed beneficiary,
        uint256 amount
    );
    event UnbondedValueWithdrawn(
        address indexed operator,
        address indexed beneficiary,
        uint256 amount
    );
    event BondCreated(
        address indexed operator,
        address indexed holder,
        address indexed sortitionPool,
        uint256 referenceID,
        uint256 amount
    );
    event BondReassigned(
        address indexed operator,
        uint256 indexed referenceID,
        address newHolder,
        uint256 newReferenceID
    );
    event BondReleased(address indexed operator, uint256 indexed referenceID);
    event BondSeized(
        address indexed operator,
        uint256 indexed referenceID,
        address destination,
        uint256 amount
    );

    /// @notice Initializes Keep Bonding contract.
    /// @param registryAddress Keep registry contract address.
    constructor(address registryAddress) public {
        registry = KeepRegistry(registryAddress);
    }

    /// @notice Add the provided value to operator's pool available for bonding.
    /// @param operator Address of the operator.
    function deposit(address operator) public payable {
        address beneficiary = beneficiaryOf(operator);
        // Beneficiary has to be set (delegation exist) before an operator can
        // deposit wei. It protects from a situation when an operator wants
        // to withdraw funds which are transfered to beneficiary with zero
        // address.
        require(
            beneficiary != address(0),
            "Beneficiary not defined for the operator"
        );
        unbondedValue[operator] = unbondedValue[operator].add(msg.value);
        emit UnbondedValueDeposited(operator, beneficiary, msg.value);
    }

    /// @notice Withdraws amount from operator's value available for bonding.
    /// @param amount Value to withdraw in wei.
    /// @param operator Address of the operator.
    function withdraw(uint256 amount, address operator) public;

    /// @notice Returns the amount of wei the operator has made available for
    /// bonding and that is still unbounded. If the operator doesn't exist or
    /// bond creator is not authorized as an operator contract or it is not
    /// authorized by the operator or there is no secondary authorization for
    /// the provided sortition pool, function returns 0.
    /// @dev Implements function expected by sortition pools' IBonding interface.
    /// @param operator Address of the operator.
    /// @param bondCreator Address authorized to create a bond.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    /// @return Amount of authorized wei deposit available for bonding.
    function availableUnbondedValue(
        address operator,
        address bondCreator,
        address authorizedSortitionPool
    ) public view returns (uint256) {
        // Sortition pools check this condition and skips operators that
        // are no longer eligible. We cannot revert here.
        if (
            registry.isApprovedOperatorContract(bondCreator) &&
            isAuthorizedForOperator(operator, bondCreator) &&
            hasSecondaryAuthorization(operator, authorizedSortitionPool)
        ) {
            return unbondedValue[operator];
        }

        return 0;
    }

    /// @notice Create bond for the given operator, holder, reference and amount.
    /// @dev Function can be executed only by authorized contract. Reference ID
    /// should be unique for holder and operator.
    /// @param operator Address of the operator to bond.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID used to track the bond by holder.
    /// @param amount Value to bond in wei.
    /// @param authorizedSortitionPool Address of authorized sortition pool.
    function createBond(
        address operator,
        address holder,
        uint256 referenceID,
        uint256 amount,
        address authorizedSortitionPool
    ) public {
        require(
            availableUnbondedValue(
                operator,
                msg.sender,
                authorizedSortitionPool
            ) >= amount,
            "Insufficient unbonded value"
        );

        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(
            lockedBonds[bondID] == 0,
            "Reference ID not unique for holder and operator"
        );

        unbondedValue[operator] = unbondedValue[operator].sub(amount);
        lockedBonds[bondID] = lockedBonds[bondID].add(amount);

        emit BondCreated(
            operator,
            holder,
            authorizedSortitionPool,
            referenceID,
            amount
        );
    }

    /// @notice Returns value of wei bonded for the operator.
    /// @param operator Address of the operator.
    /// @param holder Address of the holder of the bond.
    /// @param referenceID Reference ID of the bond.
    /// @return Amount of wei in the selected bond.
    function bondAmount(
        address operator,
        address holder,
        uint256 referenceID
    ) public view returns (uint256) {
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        return lockedBonds[bondID];
    }

    /// @notice Reassigns a bond to a new holder under a new reference.
    /// @dev Function requires that a caller is the current holder of the bond
    /// which is being reassigned.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param newHolder Address of the new holder of the bond.
    /// @param newReferenceID New reference ID to register the bond.
    function reassignBond(
        address operator,
        uint256 referenceID,
        address newHolder,
        uint256 newReferenceID
    ) public {
        address holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(lockedBonds[bondID] > 0, "Bond not found");

        bytes32 newBondID =
            keccak256(abi.encodePacked(operator, newHolder, newReferenceID));

        require(
            lockedBonds[newBondID] == 0,
            "Reference ID not unique for holder and operator"
        );

        lockedBonds[newBondID] = lockedBonds[bondID];
        lockedBonds[bondID] = 0;

        emit BondReassigned(operator, referenceID, newHolder, newReferenceID);
    }

    /// @notice Releases the bond and moves the bond value to the operator's
    /// unbounded value pool.
    /// @dev Function requires that caller is the holder of the bond which is
    /// being released.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    function freeBond(address operator, uint256 referenceID) public {
        address holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(lockedBonds[bondID] > 0, "Bond not found");

        uint256 amount = lockedBonds[bondID];
        lockedBonds[bondID] = 0;
        unbondedValue[operator] = unbondedValue[operator].add(amount);

        emit BondReleased(operator, referenceID);
    }

    /// @notice Seizes the bond by moving some or all of the locked bond to the
    /// provided destination address.
    /// @dev Function requires that a caller is the holder of the bond which is
    /// being seized.
    /// @param operator Address of the bonded operator.
    /// @param referenceID Reference ID of the bond.
    /// @param amount Amount to be seized.
    /// @param destination Address to send the amount to.
    function seizeBond(
        address operator,
        uint256 referenceID,
        uint256 amount,
        address payable destination
    ) public {
        require(amount > 0, "Requested amount should be greater than zero");

        address payable holder = msg.sender;
        bytes32 bondID =
            keccak256(abi.encodePacked(operator, holder, referenceID));

        require(
            lockedBonds[bondID] >= amount,
            "Requested amount is greater than the bond"
        );

        lockedBonds[bondID] = lockedBonds[bondID].sub(amount);

        (bool success, ) = destination.call.value(amount)("");
        require(success, "Transfer failed");

        emit BondSeized(operator, referenceID, destination, amount);
    }

    /// @notice Authorizes sortition pool for the provided operator.
    /// Operator's authorizers need to authorize individual sortition pools
    /// per application since they may be interested in participating only in
    /// a subset of keep types used by the given application.
    /// @dev Only operator's authorizer can call this function.
    function authorizeSortitionPoolContract(
        address _operator,
        address _poolAddress
    ) public {
        require(authorizerOf(_operator) == msg.sender, "Not authorized");
        authorizedPools[_operator][_poolAddress] = true;
    }

    /// @notice Deauthorizes sortition pool for the provided operator.
    /// Authorizer may deauthorize individual sortition pool in case the
    /// operator should no longer be eligible for work selection and the
    /// application represented by the sortition pool should no longer be
    /// eligible to create bonds for the operator.
    /// @dev Only operator's authorizer can call this function.
    function deauthorizeSortitionPoolContract(
        address _operator,
        address _poolAddress
    ) public {
        require(authorizerOf(_operator) == msg.sender, "Not authorized");
        authorizedPools[_operator][_poolAddress] = false;
    }

    /// @notice Checks if the sortition pool has been authorized for the
    /// provided operator by its authorizer.
    /// @dev See authorizeSortitionPoolContract.
    function hasSecondaryAuthorization(address _operator, address _poolAddress)
        public
        view
        returns (bool)
    {
        return authorizedPools[_operator][_poolAddress];
    }

    /// @notice Checks if operator contract has been authorized for the provided
    /// operator.
    /// @param _operator Operator address.
    /// @param _operatorContract Address of the operator contract.
    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool);

    /// @notice Gets the authorizer for the specified operator address.
    /// @param _operator Operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address);

    /// @notice Gets the beneficiary for the specified operator address.
    /// @param _operator Operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable);

    /// @notice Withdraws the provided amount from unbonded value of the
    /// provided operator to operator's beneficiary. If there is no enough
    /// unbonded value or the transfer failed, function fails.
    function withdrawBond(uint256 amount, address operator) internal {
        require(
            unbondedValue[operator] >= amount,
            "Insufficient unbonded value"
        );

        unbondedValue[operator] = unbondedValue[operator].sub(amount);

        address beneficiary = beneficiaryOf(operator);

        (bool success, ) = beneficiary.call.value(amount)("");
        require(success, "Transfer failed");

        emit UnbondedValueWithdrawn(operator, beneficiary, amount);
    }
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./api/IBondedECDSAKeep.sol";
import "./api/IBondingManagement.sol";

import "@keep-network/keep-core/contracts/utils/AddressArrayUtils.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AbstractBondedECDSAKeep is IBondedECDSAKeep {
    using AddressArrayUtils for address[];
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Status of the keep.
    // Active means the keep is active.
    // Closed means the keep was closed happily.
    // Terminated means the keep was closed due to misbehavior.
    enum Status {Active, Closed, Terminated}

    // Address of the keep's owner.
    address public owner;

    // List of keep members' addresses.
    address[] public members;

    // Minimum number of honest keep members required to produce a signature.
    uint256 public honestThreshold;

    // Keep's ECDSA public key serialized to 64-bytes, where X and Y coordinates
    // are padded with zeros to 32-byte each.
    bytes public publicKey;

    // Latest digest requested to be signed. Used to validate submitted signature.
    bytes32 public digest;

    // Map of all digests requested to be signed. Used to validate submitted
    // signature. Holds the block number at which the signature over the given
    // digest was requested
    mapping(bytes32 => uint256) public digests;

    // The timestamp at which keep has been created and key generation process
    // started.
    uint256 internal keyGenerationStartTimestamp;

    // The timestamp at which signing process started. Used also to track if
    // signing is in progress. When set to `0` indicates there is no
    // signing process in progress.
    uint256 internal signingStartTimestamp;

    // Map stores public key by member addresses. All members should submit the
    // same public key.
    mapping(address => bytes) internal submittedPublicKeys;

    // Map stores amount of wei stored in the contract for each member address.
    mapping(address => uint256) internal memberETHBalances;

    // Map stores preimages that have been proven to be fraudulent. This is needed
    // to prevent from slashing members multiple times for the same fraudulent
    // preimage.
    mapping(bytes => bool) internal fraudulentPreimages;

    // The current status of the keep.
    // If the keep is Active members monitor it and support requests from the
    // keep owner.
    // If the owner decides to close the keep the flag is set to Closed.
    // If the owner seizes member bonds the flag is set to Terminated.
    Status internal status;

    IBondingManagement internal bonding;

    // Flags execution of contract initialization.
    bool internal isInitialized;

    // Notification that the keep was requested to sign a digest.
    event SignatureRequested(bytes32 indexed digest);

    // Notification that the submitted public key does not match a key submitted
    // by other member. The event contains address of the member who tried to
    // submit a public key and a conflicting public key submitted already by other
    // member.
    event ConflictingPublicKeySubmitted(
        address indexed submittingMember,
        bytes conflictingPublicKey
    );

    // Notification that keep's ECDSA public key has been successfully established.
    event PublicKeyPublished(bytes publicKey);

    // Notification that ETH reward has been distributed to keep members.
    event ETHRewardDistributed(uint256 amount);

    // Notification that ERC20 reward has been distributed to keep members.
    event ERC20RewardDistributed(address indexed token, uint256 amount);

    // Notification that the keep was closed by the owner.
    // Members no longer need to support this keep.
    event KeepClosed();

    // Notification that the keep has been terminated by the owner.
    // Members no longer need to support this keep.
    event KeepTerminated();

    // Notification that the signature has been calculated. Contains a digest which
    // was used for signature calculation and a signature in a form of r, s and
    // recovery ID values.
    // The signature is chain-agnostic. Some chains (e.g. Ethereum and BTC) requires
    // `v` to be calculated by increasing recovery id by 27. Please consult the
    // documentation about what the particular chain expects.
    event SignatureSubmitted(
        bytes32 indexed digest,
        bytes32 r,
        bytes32 s,
        uint8 recoveryID
    );

    /// @notice Returns keep's ECDSA public key.
    /// @return Keep's ECDSA public key.
    function getPublicKey() external view returns (bytes memory) {
        return publicKey;
    }

    /// @notice Submits a public key to the keep.
    /// @dev Public key is published successfully if all members submit the same
    /// value. In case of conflicts with others members submissions it will emit
    /// `ConflictingPublicKeySubmitted` event. When all submitted keys match
    /// it will store the key as keep's public key and emit a `PublicKeyPublished`
    /// event.
    /// @param _publicKey Signer's public key.
    function submitPublicKey(bytes calldata _publicKey) external onlyMember {
        require(
            !hasMemberSubmittedPublicKey(msg.sender),
            "Member already submitted a public key"
        );

        require(_publicKey.length == 64, "Public key must be 64 bytes long");

        submittedPublicKeys[msg.sender] = _publicKey;

        // Check if public keys submitted by all keep members are the same as
        // the currently submitted one.
        uint256 matchingPublicKeysCount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (
                keccak256(submittedPublicKeys[members[i]]) !=
                keccak256(_publicKey)
            ) {
                // Emit an event only if compared member already submitted a value.
                if (hasMemberSubmittedPublicKey(members[i])) {
                    emit ConflictingPublicKeySubmitted(
                        msg.sender,
                        submittedPublicKeys[members[i]]
                    );
                }
            } else {
                matchingPublicKeysCount++;
            }
        }

        if (matchingPublicKeysCount != members.length) {
            return;
        }

        // All submitted signatures match.
        publicKey = _publicKey;
        emit PublicKeyPublished(_publicKey);
    }

    /// @notice Calculates a signature over provided digest by the keep.
    /// @dev Only one signing process can be in progress at a time.
    /// @param _digest Digest to be signed.
    function sign(bytes32 _digest) external onlyOwner onlyWhenActive {
        require(publicKey.length != 0, "Public key was not set yet");
        require(!isSigningInProgress(), "Signer is busy");

        /* solium-disable-next-line */
        signingStartTimestamp = block.timestamp;

        digests[_digest] = block.number;
        digest = _digest;

        emit SignatureRequested(_digest);
    }

    /// @notice Checks if keep is currently awaiting a signature for the given digest.
    /// @dev Validates if the signing is currently in progress and compares provided
    /// digest with the one for which the latest signature was requested.
    /// @param _digest Digest for which to check if signature is being awaited.
    /// @return True if the digest is currently expected to be signed, else false.
    function isAwaitingSignature(bytes32 _digest) external view returns (bool) {
        return isSigningInProgress() && digest == _digest;
    }

    /// @notice Submits a signature calculated for the given digest.
    /// @dev Fails if signature has not been requested or a signature has already
    /// been submitted.
    /// Validates s value to ensure it's in the lower half of the secp256k1 curve's
    /// order.
    /// @param _r Calculated signature's R value.
    /// @param _s Calculated signature's S value.
    /// @param _recoveryID Calculated signature's recovery ID (one of {0, 1, 2, 3}).
    function submitSignature(
        bytes32 _r,
        bytes32 _s,
        uint8 _recoveryID
    ) external onlyMember {
        require(isSigningInProgress(), "Not awaiting a signature");
        require(_recoveryID < 4, "Recovery ID must be one of {0, 1, 2, 3}");

        // Validate `s` value for a malleability concern described in EIP-2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order are considered valid.
        require(
            uint256(_s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Malleable signature - s should be in the low half of secp256k1 curve's order"
        );

        // We add 27 to the recovery ID to align it with ethereum and bitcoin
        // protocols where 27 is added to recovery ID to indicate usage of
        // uncompressed public keys.
        uint8 _v = 27 + _recoveryID;

        // Validate signature.
        require(
            publicKeyToAddress(publicKey) == ecrecover(digest, _v, _r, _s),
            "Invalid signature"
        );

        signingStartTimestamp = 0;

        emit SignatureSubmitted(digest, _r, _s, _recoveryID);
    }

    /// @notice Distributes ETH reward evenly across all keep signer beneficiaries.
    /// If the value cannot be divided evenly across all signers, it sends the
    /// remainder to the last keep signer.
    /// @dev Only the value passed to this function is distributed. This
    /// function does not transfer the value to beneficiaries accounts; instead
    /// it holds the value in the contract until withdraw function is called for
    /// the specific signer.
    function distributeETHReward() external payable {
        uint256 memberCount = members.length;
        uint256 dividend = msg.value.div(memberCount);

        require(dividend > 0, "Dividend value must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            memberETHBalances[members[i]] += dividend;
        }

        // Give the dividend to the last signer. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = msg.value.mod(memberCount);
        memberETHBalances[members[memberCount - 1]] += dividend.add(remainder);

        emit ETHRewardDistributed(msg.value);
    }

    /// @notice Distributes ERC20 reward evenly across all keep signer beneficiaries.
    /// @dev This works with any ERC20 token that implements a transferFrom
    /// function similar to the interface imported here from
    /// OpenZeppelin. This function only has authority over pre-approved
    /// token amount. We don't explicitly check for allowance, SafeMath
    /// subtraction overflow is enough protection. If the value cannot be
    /// divided evenly across the signers, it submits the remainder to the last
    /// keep signer.
    /// @param _tokenAddress Address of the ERC20 token to distribute.
    /// @param _value Amount of ERC20 token to distribute.
    function distributeERC20Reward(address _tokenAddress, uint256 _value)
        external
    {
        IERC20 token = IERC20(_tokenAddress);

        uint256 memberCount = members.length;
        uint256 dividend = _value.div(memberCount);

        require(dividend > 0, "Dividend value must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            token.safeTransferFrom(
                msg.sender,
                beneficiaryOf(members[i]),
                dividend
            );
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = _value.mod(memberCount);
        token.safeTransferFrom(
            msg.sender,
            beneficiaryOf(members[memberCount - 1]),
            dividend.add(remainder)
        );

        emit ERC20RewardDistributed(_tokenAddress, _value);
    }

    /// @notice Gets current amount of ETH hold in the keep for the member.
    /// @param _member Keep member address.
    /// @return Current balance in wei.
    function getMemberETHBalance(address _member)
        external
        view
        returns (uint256)
    {
        return memberETHBalances[_member];
    }

    /// @notice Withdraws amount of ether hold in the keep for the member.
    /// The value is sent to the beneficiary of the specific member.
    /// @param _member Keep member address.
    function withdraw(address _member) external {
        uint256 value = memberETHBalances[_member];

        require(value > 0, "No funds to withdraw");

        memberETHBalances[_member] = 0;

        /* solium-disable-next-line security/no-call-value */
        (bool success, ) = beneficiaryOf(_member).call.value(value)("");

        require(success, "Transfer failed");
    }

    /// @notice Submits a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign. If fraud is detected it tries to
    /// slash members' KEEP tokens. For each keep member tries slashing amount
    /// equal to the member stake set by the factory when keep was created.
    /// @dev The function expects the signed digest to be calculated as a sha256
    /// hash of the preimage: `sha256(_preimage))`. The function reverts if the
    /// signature is not fraudulent. The function does not revert if KEEP slashing
    /// failed but emits an event instead. In practice, KEEP slashing should
    /// never fail.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage with sha256.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, error otherwise.
    function submitSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes calldata _preimage
    ) external onlyWhenActive returns (bool _isFraud) {
        bool isFraud =
            checkSignatureFraud(_v, _r, _s, _signedDigest, _preimage);

        require(isFraud, "Signature is not fraudulent");

        if (!fraudulentPreimages[_preimage]) {
            slashForSignatureFraud();

            fraudulentPreimages[_preimage] = true;
        }

        return isFraud;
    }

    /// @notice Gets the owner of the keep.
    /// @return Address of the keep owner.
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @notice Gets the timestamp the keep was opened at.
    /// @return Timestamp the keep was opened at.
    function getOpenedTimestamp() external view returns (uint256) {
        return keyGenerationStartTimestamp;
    }

    /// @notice Returns the amount of the keep's ETH bond in wei.
    /// @return The amount of the keep's ETH bond in wei.
    function checkBondAmount() external view returns (uint256) {
        uint256 sumBondAmount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            sumBondAmount += bonding.bondAmount(
                members[i],
                address(this),
                uint256(address(this))
            );
        }

        return sumBondAmount;
    }

    /// @notice Seizes the signers' ETH bonds. After seizing bonds keep is
    /// closed so it will no longer respond to signing requests. Bonds can be
    /// seized only when there is no signing in progress or requested signing
    /// process has timed out. This function seizes all of signers' bonds.
    /// The application may decide to return part of bonds later after they are
    /// processed using returnPartialSignerBonds function.
    function seizeSignerBonds() external onlyOwner onlyWhenActive {
        terminateKeep();

        for (uint256 i = 0; i < members.length; i++) {
            uint256 amount =
                bonding.bondAmount(
                    members[i],
                    address(this),
                    uint256(address(this))
                );

            bonding.seizeBond(
                members[i],
                uint256(address(this)),
                amount,
                address(uint160(owner))
            );
        }
    }

    /// @notice Returns partial signer's ETH bonds to the pool as an unbounded
    /// value. This function is called after bonds have been seized and processed
    /// by the privileged application after calling seizeSignerBonds function.
    /// It is entirely up to the application if a part of signers' bonds is
    /// returned. The application may decide for that but may also decide to
    /// seize bonds and do not return anything.
    function returnPartialSignerBonds() external payable {
        uint256 memberCount = members.length;
        uint256 bondPerMember = msg.value.div(memberCount);

        require(bondPerMember > 0, "Partial signer bond must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            bonding.deposit.value(bondPerMember)(members[i]);
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = msg.value.mod(memberCount);
        bonding.deposit.value(bondPerMember.add(remainder))(
            members[memberCount - 1]
        );
    }

    /// @notice Closes keep when owner decides that they no longer need it.
    /// Releases bonds to the keep members.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() public onlyOwner onlyWhenActive {
        markAsClosed();
        freeMembersBonds();
    }

    /// @notice Returns true if the keep is active.
    /// @return true if the keep is active, false otherwise.
    function isActive() public view returns (bool) {
        return status == Status.Active;
    }

    /// @notice Returns true if the keep is closed and members no longer support
    /// this keep.
    /// @return true if the keep is closed, false otherwise.
    function isClosed() public view returns (bool) {
        return status == Status.Closed;
    }

    /// @notice Returns true if the keep has been terminated.
    /// Keep is terminated when bonds are seized and members no longer support
    /// this keep.
    /// @return true if the keep has been terminated, false otherwise.
    function isTerminated() public view returns (bool) {
        return status == Status.Terminated;
    }

    /// @notice Returns members of the keep.
    /// @return List of the keep members' addresses.
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    /// @notice Checks a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign.
    /// @dev The function expects the signed digest to be calculated as a sha256 hash
    /// of the preimage: `sha256(_preimage))`. The digest is verified against the
    /// preimage to ensure the security of the ECDSA protocol. Verifying just the
    /// signature and the digest is not enough and leaves the possibility of the
    /// the existential forgery. If digest and preimage verification fails the
    /// function reverts.
    /// Reverts if a public key has not been set for the keep yet.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage with sha256.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, false otherwise.
    function checkSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public view returns (bool _isFraud) {
        require(publicKey.length != 0, "Public key was not set yet");

        bytes32 calculatedDigest = sha256(_preimage);
        require(
            _signedDigest == calculatedDigest,
            "Signed digest does not match sha256 hash of the preimage"
        );

        bool isSignatureValid =
            publicKeyToAddress(publicKey) ==
                ecrecover(_signedDigest, _v, _r, _s);

        // Check if the signature is valid but was not requested.
        return isSignatureValid && digests[_signedDigest] == 0;
    }

    /// @notice Initialization function.
    /// @dev We use clone factory to create new keep. That is why this contract
    /// doesn't have a constructor. We provide keep parameters for each instance
    /// function after cloning instances from the master contract.
    /// Initialization must happen in the same transaction in which the clone is
    /// created.
    /// @param _owner Address of the keep owner.
    /// @param _members Addresses of the keep members.
    /// @param _honestThreshold Minimum number of honest keep members.
    function initialize(
        address _owner,
        address[] memory _members,
        uint256 _honestThreshold,
        address _bonding
    ) internal {
        require(!isInitialized, "Contract already initialized");

        owner = _owner;
        members = _members;
        honestThreshold = _honestThreshold;

        status = Status.Active;
        isInitialized = true;

        /* solium-disable-next-line security/no-block-members*/
        keyGenerationStartTimestamp = block.timestamp;

        bonding = IBondingManagement(_bonding);
    }

    /// @notice Checks if the member already submitted a public key.
    /// @param _member Address of the member.
    /// @return True if member already submitted a public key, else false.
    function hasMemberSubmittedPublicKey(address _member)
        internal
        view
        returns (bool)
    {
        return submittedPublicKeys[_member].length != 0;
    }

    /// @notice Returns true if signing of a digest is currently in progress.
    function isSigningInProgress() internal view returns (bool) {
        return signingStartTimestamp != 0;
    }

    /// @notice Marks the keep as closed.
    /// Keep can be marked as closed only when there is no signing in progress
    /// or the requested signing process has timed out.
    function markAsClosed() internal {
        status = Status.Closed;
        emit KeepClosed();
    }

    /// @notice Marks the keep as terminated.
    /// Keep can be marked as terminated only when there is no signing in progress
    /// or the requested signing process has timed out.
    function markAsTerminated() internal {
        status = Status.Terminated;
        emit KeepTerminated();
    }

    /// @notice Coverts a public key to an ethereum address.
    /// @param _publicKey Public key provided as 64-bytes concatenation of
    /// X and Y coordinates (32-bytes each).
    /// @return Ethereum address.
    function publicKeyToAddress(bytes memory _publicKey)
        internal
        pure
        returns (address)
    {
        // We hash the public key and then truncate last 20 bytes of the digest
        // which is the ethereum address.
        return address(uint160(uint256(keccak256(_publicKey))));
    }

    /// @notice Returns bonds to the keep members.
    function freeMembersBonds() internal {
        for (uint256 i = 0; i < members.length; i++) {
            bonding.freeBond(members[i], uint256(address(this)));
        }
    }

    /// @notice Terminates the keep.
    function terminateKeep() internal {
        markAsTerminated();
    }

    /// @notice Punishes keep members after proving a signature fraud.
    function slashForSignatureFraud() internal;

    /// @notice Gets the beneficiary for the specified member address.
    /// @param _member Member address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _member)
        internal
        view
        returns (address payable);

    /// @notice Checks if the caller is the keep's owner.
    /// @dev Throws an error if called by any account other than owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the keep owner");
        _;
    }

    /// @notice Checks if the caller is a keep member.
    /// @dev Throws an error if called by any account other than one of the members.
    modifier onlyMember() {
        require(members.contains(msg.sender), "Caller is not the keep member");
        _;
    }

    /// @notice Checks if the keep is currently active.
    /// @dev Throws an error if called when the keep has been already closed.
    modifier onlyWhenActive() {
        require(isActive(), "Keep is not active");
        _;
    }
}

