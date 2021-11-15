pragma solidity ^0.6.12;

import {
    ERC20PausableUpgradeSafe,
    IERC20,
    SafeMath
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Pausable.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {
    ReentrancyGuardUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

import {AddressArrayUtils} from "./library/AddressArrayUtils.sol";

import {ILimaSwap} from "./interfaces/ILimaSwap.sol";
import {ILimaTokenHelper} from "./interfaces/ILimaTokenHelper.sol";

/**
 * @title LimaToken
 * @author Lima Protocol
 *
 * Standard LimaToken.
 */
contract LimaToken is ERC20PausableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using AddressArrayUtils for address[];
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Create(address _from, uint256 _amount, uint16 indexed _referral);
    event Redeem(address _from, uint256 _amount, uint16 indexed _referral);
    event RebalanceExecute(address _oldToken, address _newToken);

    // address public owner;
    ILimaTokenHelper public limaTokenHelper; //limaTokenStorage
    mapping(address => uint256) internal userLastDeposit;

    // new storage
    uint256 public annualizedFee;
    uint256 public lastAnnualizedFeeClaimed;

    event AnnualizedFeeSet(uint256 fee);
    event FeeCharged(uint256 amount);

    /**
     * @dev Initializes contract
     */
    function initialize(
        string memory name,
        string memory symbol,
        address _limaTokenHelper,
        uint256 _underlyingAmount,
        uint256 _limaAmount
    ) public initializer {
        limaTokenHelper = ILimaTokenHelper(_limaTokenHelper);

        __ERC20_init(name, symbol);
        __ERC20Pausable_init();
        __ReentrancyGuard_init();

        if (_underlyingAmount > 0 && _limaAmount > 0) {
            IERC20(limaTokenHelper.currentUnderlyingToken()).safeTransferFrom(
                _msgSender(),
                address(this),
                _underlyingAmount
            );
            _mint(_msgSender(), _limaAmount);
        }
    }

    /* ============ Modifiers ============ */

    modifier onlyUnderlyingToken(address _token) {
        _isOnlyUnderlyingToken(_token);
        _;
    }

    function _isOnlyUnderlyingToken(address _token) internal view {
        // Internal function used to reduce bytecode size
        require(
            limaTokenHelper.isUnderlyingTokens(_token),
            "LM1" //"Only token that are part of Underlying Tokens"
        );
    }

    modifier onlyInvestmentToken(address _investmentToken) {
        // Internal function used to reduce bytecode size
        _isOnlyInvestmentToken(_investmentToken);
        _;
    }

    function _isOnlyInvestmentToken(address _investmentToken) internal view {
        // Internal function used to reduce bytecode size
        require(
            limaTokenHelper.isInvestmentToken(_investmentToken),
            "LM7" //nly token that are approved to invest/payout.
        );
    }

    /**
     * @dev Throws if called by any account other than the limaGovernance.
     */
    modifier onlyLimaGovernanceOrOwner() {
        _isOnlyLimaGovernanceOrOwner();
        _;
    }

    function _isOnlyLimaGovernanceOrOwner() internal view {
        require(
            limaTokenHelper.limaGovernance() == _msgSender() ||
                limaTokenHelper.owner() == _msgSender(),
            "LM2" // "Ownable: caller is not the limaGovernance or owner"
        );
    }

    modifier onlyAmunUsers() {
        _isOnlyAmunUser();
        _;
    }

    function _isOnlyAmunUser() internal view {
        if (limaTokenHelper.isOnlyAmunUserActive()) {
            require(
                limaTokenHelper.isAmunUser(_msgSender()),
                "LM3" //"AmunUsers: msg sender must be part of amunUsers."
            );
        }
    }

    modifier onlyAmunOracles() {
        require(limaTokenHelper.isAmunOracle(_msgSender()), "LM3");
        _;
    }

    /* ============ View ============ */

    function getUnderlyingTokenBalance() public view returns (uint256 balance) {
        return
            IERC20(limaTokenHelper.currentUnderlyingToken()).balanceOf(
                address(this)
            );
    }

    function getUnderlyingTokenBalanceOf(uint256 _amount)
        public
        view
        returns (uint256 balanceOf)
    {
        return getUnderlyingTokenBalance().mul(_amount).div(totalSupply());
    }

    /* ============ Lima Manager ============ */

    function mint(address account, uint256 amount)
        public
        onlyLimaGovernanceOrOwner
    {
        _mint(account, amount);
    }

    // pausable functions
    function pause() external onlyLimaGovernanceOrOwner {
        _pause();
    }

    function unpause() external onlyLimaGovernanceOrOwner {
        _unpause();
    }

    function _approveLimaSwap(address _token, uint256 _amount) internal {
        if (
            IERC20(_token).allowance(
                address(this),
                address(limaTokenHelper.limaSwap())
            ) < _amount
        ) {
            IERC20(_token).safeApprove(address(limaTokenHelper.limaSwap()), 0);
            IERC20(_token).safeApprove(
                address(limaTokenHelper.limaSwap()),
                limaTokenHelper.MAX_UINT256()
            );
        }
    }

    function _swap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minimumReturn
    ) internal returns (uint256 returnAmount) {
        if (address(_from) != address(_to) && _amount > 0) {
            _approveLimaSwap(_from, _amount);

            returnAmount = limaTokenHelper.limaSwap().swap(
                address(this),
                _from,
                _to,
                _amount,
                _minimumReturn
            );
            return returnAmount;
        }
        return _amount;
    }

    function _unwrap(
        address _token,
        uint256 _amount,
        address _recipient
    ) internal {
        if (_amount > 0) {
            _approveLimaSwap(_token, _amount);
            limaTokenHelper.limaSwap().unwrap(_token, _amount, _recipient);
        }
    }

    /**
     * @dev Swaps token to new token
     */
    function swap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minimumReturn
    ) public onlyLimaGovernanceOrOwner returns (uint256 returnAmount) {
        return _swap(_from, _to, _amount, _minimumReturn);
    }

    /**
     * @dev Rebalances LimaToken
     * Will do swaps of potential governancetoken, underlying token to token that provides higher return
     */
    function rebalance(
        address _bestToken,
        uint256 _minimumReturnGov,
        uint256 _minimumReturn
    ) external onlyAmunOracles() {
        require(
            limaTokenHelper.lastRebalance() +
                limaTokenHelper.rebalanceInterval() <
                now,
            "LM5" //"Rebalance only every 24 hours"
        );
        limaTokenHelper.setLastRebalance(now);

        address govToken = limaTokenHelper.getGovernanceToken();

        //swap gov
        if (govToken != address(0)) {
            _swap(
                govToken,
                _bestToken,
                IERC20(govToken).balanceOf(address(this)),
                _minimumReturnGov
            );
        }

        //swap underlying
        _swap(
            limaTokenHelper.currentUnderlyingToken(),
            _bestToken,
            getUnderlyingTokenBalance(),
            _minimumReturn
        );

        emit RebalanceExecute(
            limaTokenHelper.currentUnderlyingToken(),
            _bestToken
        );

        limaTokenHelper.setCurrentUnderlyingToken(_bestToken);
    }

    /**
     * @dev Redeem the value of LimaToken in _payoutToken.
     * @param _payoutToken The address of token to payout with.
     * @param _amount The amount to redeem.
     * @param _recipient The user address to redeem from/to.
     * @param _minimumReturn The minimum amount to return or else revert.
     */
    function forceRedeem(
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn
    ) external onlyLimaGovernanceOrOwner returns (bool) {
        return
            _redeem(
                _recipient,
                _payoutToken,
                _amount,
                _recipient,
                _minimumReturn,
                0 // no referral when forced
            );
    }

    /* ============ User ============ */

    /**
     * @dev Creates new token for holder by converting _investmentToken value to LimaToken
     * Note: User need to approve _amount on _investmentToken to this contract
     * @param _investmentToken The address of token to invest with.
     * @param _amount The amount of investment token to create lima token from.
     * @param _recipient The address to transfer the lima token to.
     * @param _minimumReturn The minimum amount of lending tokens to return or else revert.
     * @param _referral partners may receive referral fees
     */
    function create(
        address _investmentToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    )
        external
        nonReentrant
        onlyInvestmentToken(_investmentToken)
        onlyAmunUsers
        returns (bool)
    {
        require(
            block.number + 2 > userLastDeposit[_msgSender()],
            "cannot withdraw within the same block"
        );
        userLastDeposit[tx.origin] = block.number;
        uint256 balance = getUnderlyingTokenBalance();
        require(balance != 0, "balance cant be zero");
        IERC20(_investmentToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );

        chargeOutstandingAnnualizedFee();

        _amount = _swap(
            _investmentToken,
            limaTokenHelper.currentUnderlyingToken(),
            _amount,
            0
        );

        _amount = totalSupply().mul(_amount).div(balance);

        require(_amount > 0, "zero");
        require(
            _amount >= _minimumReturn,
            "return must reach minimum expected"
        );

        _mint(_recipient, _amount);

        emit Create(_msgSender(), _amount, _referral);
        return true;
    }

    function _redeem(
        address _investor,
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    ) internal nonReentrant onlyInvestmentToken(_payoutToken) returns (bool) {
        require(
            block.number + 2 > userLastDeposit[_msgSender()],
            "cannot withdraw within the same block"
        );

        chargeOutstandingAnnualizedFee();

        userLastDeposit[tx.origin] = block.number;
        uint256 underlyingAmount = getUnderlyingTokenBalanceOf(_amount);
        _burn(_investor, _amount);

        emit Redeem(_msgSender(), _amount, _referral);

        _amount = _swap(
            limaTokenHelper.currentUnderlyingToken(),
            _payoutToken,
            underlyingAmount,
            0
        );
        require(_amount > 0, "zero");

        require(
            _amount >= _minimumReturn,
            "return must reach minimum _amount expected"
        );

        IERC20(_payoutToken).safeTransfer(_recipient, _amount);

        return true;
    }

    /**
     * @dev Redeem the value of LimaToken in _payoutToken.
     * @param _payoutToken The address of token to payout with.
     * @param _amount The amount of lima token to redeem.
     * @param _recipient The address to transfer the payout token to.
     * @param _minimumReturn The minimum amount to return for _payoutToken or else revert.
     * @param _referral partners may receive referral fees
     */
    function redeem(
        address _payoutToken,
        uint256 _amount,
        address _recipient,
        uint256 _minimumReturn,
        uint16 _referral
    ) external returns (bool) {
        return
            _redeem(
                _msgSender(),
                _payoutToken,
                _amount,
                _recipient,
                _minimumReturn,
                _referral
            );
    }

    /**
     * Annual fee
     */

    function calcOutStandingAnnualizedFee() public view returns (uint256) {
        uint256 totalSupply = totalSupply();

        if (
            annualizedFee == 0 ||
            limaTokenHelper.feeWallet() == address(0) ||
            lastAnnualizedFeeClaimed == 0
        ) {
            return 0;
        }

        uint256 timePassed = block.timestamp.sub(lastAnnualizedFeeClaimed);

        return
            totalSupply.mul(annualizedFee).div(10**18).mul(timePassed).div(
                365 days
            );
    }

    function chargeOutstandingAnnualizedFee() public {
        uint256 outStandingFee = calcOutStandingAnnualizedFee();

        lastAnnualizedFeeClaimed = block.timestamp;

        // if there is any fee to mint and the beneficiary is set
        // note: limaTokenHelper.feeWallet() is already checked in calc function
        if (outStandingFee != 0) {
            _mint(limaTokenHelper.feeWallet(), outStandingFee);
        }

        emit FeeCharged(outStandingFee);
    }

    function setAnnualizedFee(uint256 _fee) external onlyLimaGovernanceOrOwner {
        chargeOutstandingAnnualizedFee();
        annualizedFee = _fee;
        emit AnnualizedFeeSet(_fee);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return "Amun Lending Autopilot";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return "DROP";
    }
}

pragma solidity ^0.6.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";
import "../../Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeSafe is Initializable, ERC20UpgradeSafe, PausableUpgradeSafe {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {


    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

    }


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.12;


library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove     
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }
}

pragma solidity ^0.6.12;

import {
    IERC20
} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface ILimaSwap {
    function getGovernanceToken(address token) external view returns (address);

    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount
    ) external view returns (uint256 returnAmount);

    function swap(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minReturnAmount
    ) external returns (uint256 returnAmount);

    function unwrap(
        address interestBearingToken,
        uint256 amount,
        address recipient
    ) external;

    function getUnderlyingAmount(address token, uint256 amount)
        external
        returns (uint256 underlyingAmount);
}

pragma solidity ^0.6.12;

import {ILimaTokenStorage} from "./ILimaTokenStorage.sol";
import {IInvestmentToken} from "./IInvestmentToken.sol";
import {IAmunUser} from "./IAmunUser.sol";

/**
 * @title ILimaTokenHelper
 * @author Lima Protocol
 *
 * Standard ILimaTokenHelper.
 */
interface ILimaTokenHelper is IInvestmentToken, IAmunUser, ILimaTokenStorage {
    function getNetTokenValue(address _targetToken)
        external
        view
        returns (uint256 netTokenValue);

    function getNetTokenValueOf(address _targetToken, uint256 _amount)
        external
        view
        returns (uint256 netTokenValue);

    function getExpectedReturn(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256 returnAmount);

    function getUnderlyingTokenBalance()
        external
        view
        returns (uint256 balance);

    function getUnderlyingTokenBalanceOf(uint256 _amount)
        external
        view
        returns (uint256 balanceOf);

    function getPayback(uint256 gas) external view returns (uint256);

    function getGovernanceToken() external view returns (address token);

    function getFee(uint256 _amount, uint256 _fee)
        external
        view
        returns (uint256 feeAmount);

    function getExpectedReturnRedeem(uint256 _amount, address _to)
        external
        view
        returns (uint256 minimumReturn);

    function getExpectedReturnCreate(uint256 _amount, address _from)
        external
        view
        returns (uint256 minimumReturn);

    function getExpectedReturnRebalance(address _bestToken)
        external
        view
        returns (uint256 minimumReturnGov, uint256 minimumReturn);

    function addAmunOracle(address _amunOracle) external;

    function isAmunOracle(address _amunOracle) external view returns (bool);
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

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

pragma solidity ^0.6.12;

import {ILimaSwap} from "./ILimaSwap.sol";

/**
 * @title LimaToken
 * @author Lima Protocol
 *
 * Standard LimaToken.
 */
interface ILimaTokenStorage {
    function MAX_UINT256() external view returns (uint256);

    function WETH() external view returns (address);

    function LINK() external view returns (address);

    function currentUnderlyingToken() external view returns (address);

    // address external owner;
    function limaSwap() external view returns (ILimaSwap);

    function rebalanceBonus() external view returns (uint256);

    function rebalanceGas() external view returns (uint256);

    //Fees
    function feeWallet() external view returns (address);

    function burnFee() external view returns (uint256);

    function mintFee() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function requestId() external view returns (bytes32);

    //Rebalance
    function lastUnderlyingBalancePer1000() external view returns (uint256);

    function lastRebalance() external view returns (uint256);

    function rebalanceInterval() external view returns (uint256);

    function limaGovernance() external view returns (address);

    function owner() external view returns (address);

    function governanceToken(uint256 _protocoll)
        external
        view
        returns (address);

    /* ============ Setter ============ */

    function addUnderlyingToken(address _underlyingToken) external;

    function removeUnderlyingToken(address _underlyingToken) external;

    function setCurrentUnderlyingToken(address _currentUnderlyingToken)
        external;

    function setFeeWallet(address _feeWallet) external;

    function setBurnFee(uint256 _burnFee) external;

    function setMintFee(uint256 _mintFee) external;

    function setLimaToken(address _limaToken) external;

    function setPerformanceFee(uint256 _performanceFee) external;

    function setLastUnderlyingBalancePer1000(
        uint256 _lastUnderlyingBalancePer1000
    ) external;

    function setLastRebalance(uint256 _lastRebalance) external;

    function setLimaSwap(address _limaSwap) external;

    function setRebalanceInterval(uint256 _rebalanceInterval) external;

    /* ============ View ============ */

    function isUnderlyingTokens(address _underlyingToken)
        external
        view
        returns (bool);
}

pragma solidity ^0.6.12;

interface IInvestmentToken {
    function isInvestmentToken(address _investmentToken)
        external
        view
        returns (bool);

    function removeInvestmentToken(address _investmentToken) external;

    function addInvestmentToken(address _investmentToken) external;
}

pragma solidity ^0.6.12;

interface IAmunUser {
    function isAmunUser(address _amunUser) external view returns (bool);
    function isOnlyAmunUserActive() external view returns (bool);
}

