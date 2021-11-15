pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPrice.sol";
import "../interfaces/IHeart.sol";
import "../interfaces/IRM.sol";
import "../interfaces/IStableCredit.sol";
import "../interfaces/ICollateralAsset.sol";
import "../book-room/LL.sol";
import "../book-room/Hasher.sol";

contract Heart is IHeart {
    using SafeMath for uint256;

    address public drsAddr;
    mapping(bytes32 => IPrice) public prices;
    IRM public reserveManager;

    /*
        collateralRatios is 1/100
        collateralRatios 1000 = require collateral 10x
        collateralRatios 125 = require collateral 1.25x
        collateralRatios 100 = require collateral 1x

        ex. You need 1.6x of Eth as collateral to issue DAI

        collateralAssetCode => ratio, ERC20 token
    */
    mapping(bytes32 => ICollateralAsset) public collateralAssets;
    mapping(bytes32 => uint) public collateralRatios;

    /*
        StableCredit related mapping
        stableCredits map between keccak256(stableCreditOwnerAddress, stableCreditCode) => StableCredit
    */
    mapping(bytes32 => IStableCredit) public stableCredits;
    LL.List public stableCreditsLL;
    using LL for LL.List;

    /*
        creditIssuanceFee is  1/10,000
        creditIssuanceFee 185 = 1.85% = 0.0185x
        creditIssuanceFee 100 = 1% = 0.01x
    */
    uint256 public creditIssuanceFee;
    /*
        collateralAssetCode => collectedFee
    */
    mapping(bytes32 => uint256) public collectedFee;

    /*
        trusted partner address => bool
        governor address => bool
    */
    mapping(address => bool) public trustedPartners;
    mapping(address => bool) public governor;

    /*
        Allowed peggedCurrency - collateralAsset pair
        linkId => bool
    */
    mapping(bytes32 => bool) allowedLinks;
    bool  active;


    modifier onlyGovernor() {
        require(isGovernor(msg.sender), "Heart.onlyGovernor: The message sender is not found or does not have sufficient permission");
        _;
    }

    modifier onlyTrustedPartner() {
        require(isTrustedPartner(msg.sender), "Heart.onlyTrustedPartner: The message sender is not found or does not have sufficient permission");
        _;
    }

    modifier onlyDRS() {
        require(msg.sender == drsAddr, "Heart.onlyDRS: caller must be DRS");
        _;
    }

    /*
        reserveFreeze collateralAssetCode => seconds
    */
    mapping(bytes32 => uint256) public reserveFreeze;


    constructor() public {
        governor[msg.sender] = true;
        stableCreditsLL.init();
        active=false;
    }

    function setReserveManager(address newReserveManager) external onlyGovernor {
        reserveManager = IRM(newReserveManager);
    }

    function getReserveManager() external view returns (IRM) {
        return reserveManager;
    }

    function setReserveFreeze(bytes32 assetCode, uint256 newSeconds) external onlyGovernor{
        reserveFreeze[assetCode] = newSeconds;
    }

    function getReserveFreeze(bytes32 assetCode) external view returns (uint256) {
        return reserveFreeze[assetCode];
    }

    function setDrsAddress(address newDrsAddress) external onlyGovernor {
      if(active==false){
          drsAddr = newDrsAddress;
          active=true;
      }

    }

    function getDrsAddress() external view returns (address) {
        return drsAddr;
    }

    function setCollateralAsset(bytes32 assetCode, address addr, uint ratio) external onlyGovernor {
        collateralAssets[assetCode] = ICollateralAsset(addr);
        collateralRatios[assetCode] = ratio;
    }

    function getCollateralAsset(bytes32 assetCode) external view returns (ICollateralAsset) {
        return collateralAssets[assetCode];
    }

    function setCollateralRatio(bytes32 assetCode, uint ratio) external onlyGovernor {
        require(address(collateralAssets[assetCode]) != address(0x0), "assetCode has not been added");
        collateralRatios[assetCode] = ratio;
    }

    function getCollateralRatio(bytes32 assetCode) external view returns (uint) {
        return collateralRatios[assetCode];
    }

    function setCreditIssuanceFee(uint256 newFee) external onlyGovernor {
        creditIssuanceFee = newFee;
    }

    function getCreditIssuanceFee() external view returns (uint256) {
        return creditIssuanceFee;
    }

    function setTrustedPartner(address addr) external onlyGovernor {
        trustedPartners[addr] = true;
    }

    function setGovernor(address addr) external onlyGovernor {
        governor[addr] = true;
    }

    function isTrustedPartner(address addr) public view returns (bool) {
        return trustedPartners[addr];
    }

    function isGovernor(address addr) public view returns (bool) {
        return governor[addr];
    }

    function addPrice(bytes32 linkId, IPrice newPrice) external onlyGovernor {
        require(address(newPrice) != address(0), "newPrice address must not be 0");
        require(address(prices[linkId]) == address(0), "Price has already existed");
        prices[linkId] = IPrice(newPrice);
    }

    function getPriceContract(bytes32 linkId) external view returns (IPrice) {
        return prices[linkId];
    }

    function collectFee(uint256 fee, bytes32 collateralAssetCode) external {
        require(msg.sender == drsAddr, "only DRSSC can update the collected fee");
        collectedFee[collateralAssetCode] = collectedFee[collateralAssetCode].add(fee);
    }

    function getCollectedFee(bytes32 collateralAssetCode) external view returns (uint256) {
        return collectedFee[collateralAssetCode];
    }

    function withdrawFee(bytes32 collateralAssetCode, uint256 amount) external onlyGovernor {
        require(amount <= collectedFee[collateralAssetCode], "amount must <= to collectedFee");

        collateralAssets[collateralAssetCode].transfer(msg.sender, amount);

        collectedFee[collateralAssetCode] = collectedFee[collateralAssetCode].sub(amount);
    }

    function addStableCredit(IStableCredit newStableCredit) external onlyDRS {
        require(address(newStableCredit) != address(0), "newStableCredit address must not be 0");
        bytes32 stableCreditId = Hasher.stableCreditId(newStableCredit.assetCode());
        require(address(stableCredits[stableCreditId]) == address(0), "stableCredit has already existed");

        stableCredits[stableCreditId] = newStableCredit;
        stableCreditsLL = stableCreditsLL.add(address(newStableCredit));
    }

    function getStableCreditById(bytes32 stableCreditId) external view returns (IStableCredit) {
        return stableCredits[stableCreditId];
    }

    function getRecentStableCredit() external view returns (IStableCredit) {
        address addr = stableCreditsLL.getNextOf(address(1));
        return IStableCredit(addr);
    }

    function getNextStableCredit(bytes32 stableCreditId) external view returns (IStableCredit) {
        address currentAddr = address(stableCredits[stableCreditId]);
        address nextAddr = stableCreditsLL.getNextOf(currentAddr);
        return IStableCredit(nextAddr);
    }

    function getStableCreditCount() external view returns (uint8) {
        return stableCreditsLL.llSize;
    }

    function setAllowedLink(bytes32 linkId, bool enable) external onlyGovernor {
        allowedLinks[linkId] = enable;
    }

    function isLinkAllowed(bytes32 linkId) external view returns (bool) {
        return allowedLinks[linkId];
    }
}

pragma solidity ^0.5.0;

contract IPrice {
    function post() external;

    function get() external view returns (uint256);

    function getWithError() external view returns (uint256, bool, bool);

    function void() external;

    function activate() external;
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../interfaces/ICollateralAsset.sol";

interface IStableCredit {
    function mint(address recipient, uint256 amount) external;

    function burn(address tokenOwner, uint256 amount) external;

    function redeem(address redeemer, uint burnAmount, uint256 returnAmount) external;

    function approveCollateral() external;

    function getCollateralDetail() external view returns (uint256, address);

    function getId() external view returns (bytes32);

    function transferCollateralToReserve(uint256 amount) external returns (bool);

    // Getter functions
    function assetCode() external view returns (string memory);

    function peggedValue() external view returns (uint256);

    function peggedCurrency() external view returns (bytes32);

    function creditOwner() external view returns (address);

    function collateral() external view returns (ICollateralAsset);

    function collateralAssetCode() external view returns (bytes32);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

pragma solidity ^0.5.0;

interface IRM {
    function lockReserve(bytes32 assetCode, address from, uint256 amount) external;
    function releaseReserve(bytes32 lockedReserveId, bytes32 assetCode, uint256 amount) external;
    function injectCollateral(bytes32 assetCode, address to, uint256 amount) external;
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
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPrice.sol";
import "./IRM.sol";
import "./IStableCredit.sol";
import "../core/StableCredit.sol";

interface IHeart {
    function setReserveManager(address newReserveManager) external;

    function getReserveManager() external view returns (IRM);

    function setReserveFreeze(bytes32 assetCode, uint256 newSeconds) external;

    function getReserveFreeze(bytes32 assetCode) external view returns (uint256);

    function setDrsAddress(address newDrsAddress) external;

    function getDrsAddress() external view returns (address);

    function setCollateralAsset(bytes32 assetCode, address addr, uint ratio) external;

    function getCollateralAsset(bytes32 assetCode) external view returns (ICollateralAsset);

    function setCollateralRatio(bytes32 assetCode, uint ratio) external;

    function getCollateralRatio(bytes32 assetCode) external view returns (uint);

    function setCreditIssuanceFee(uint256 newFee) external;

    function getCreditIssuanceFee() external view returns (uint256);

    function setTrustedPartner(address addr) external;

    function isTrustedPartner(address addr) external view returns (bool);

    function setGovernor(address addr) external;

    function isGovernor(address addr) external view returns (bool);

    function addPrice(bytes32 linkId, IPrice newPrice) external;

    function getPriceContract(bytes32 linkId) external view returns (IPrice);

    function collectFee(uint256 fee, bytes32 collateralAssetCode) external;

    function getCollectedFee(bytes32 collateralAssetCode) external view returns (uint256);

    function withdrawFee(bytes32 collateralAssetCode, uint256 amount) external;

    function addStableCredit(IStableCredit stableCredit) external;

    function getStableCreditById(bytes32 stableCreditId) external view returns (IStableCredit);

    function getRecentStableCredit() external view returns (IStableCredit);

    function getNextStableCredit(bytes32 stableCreditId) external view returns (IStableCredit);

    function getStableCreditCount() external view returns (uint8);

    function setAllowedLink(bytes32 linkId, bool enable) external;

    function isLinkAllowed(bytes32 linkId) external view returns (bool);
}

pragma solidity ^0.5.0;

interface ICollateralAsset {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../book-room/Hasher.sol";
import "../interfaces/IHeart.sol";
import "../interfaces/ICollateralAsset.sol";

/// @author Velo Team
/// @title A modified ERC20
contract StableCredit is ERC20, ERC20Detailed {
    IHeart public heart;

    ICollateralAsset public collateral;
    bytes32 public collateralAssetCode;

    uint256 public peggedValue;
    bytes32 public peggedCurrency;

    address public creditOwner;
    address public drsAddress;

    modifier onlyDRSSC() {
        require(heart.getDrsAddress() == msg.sender, "caller is not DRSSC");
        _;
    }

    constructor (
        bytes32 _peggedCurrency,
        address _creditOwner,
        bytes32 _collateralAssetCode,
        address _collateralAddress,
        string memory _code,
        uint256 _peggedValue,
        address heartAddr
    )
    public ERC20Detailed(_code, _code, 5) {
        creditOwner = _creditOwner;
        peggedValue = _peggedValue;
        peggedCurrency = _peggedCurrency;
        collateral = ICollateralAsset(_collateralAddress);
        collateralAssetCode = _collateralAssetCode;
        heart = IHeart(heartAddr);
    }

    function mint(address recipient, uint256 amount) external onlyDRSSC {
        _mint(recipient, amount);
    }

    function burn(address tokenOwner, uint256 amount) external onlyDRSSC {
        _burn(tokenOwner, amount);
    }

    function approveCollateral() external onlyDRSSC {
        collateral.approve(msg.sender, collateral.balanceOf(address(this)));
    }

    function redeem(address redeemer, uint burnAmount, uint256 returnAmount) external onlyDRSSC {
        collateral.transfer(redeemer, returnAmount);
        _burn(redeemer, burnAmount);
    }

    function getCollateralDetail() external view returns (uint256, address) {
        return (collateral.balanceOf(address(this)), address(collateral));
    }

    function getId() external view returns (bytes32) {
        return Hasher.stableCreditId(this.name());
    }

    function assetCode() external view returns (string memory) {
        return this.name();
    }

    function transferCollateralToReserve(uint256 amount) external onlyDRSSC returns (bool) {
        ICollateralAsset(collateral).transfer(address(heart.getReserveManager()), amount);
        return true;
    }

}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

library LL {
    address public constant start = address(1);
    address public constant end = address(1);
    address public constant empty = address(0);

    struct List {
        uint8 llSize;
        mapping (address => address) next;
    }

    function init(List storage list) internal returns (List memory) {
        list.next[start] = end;

        return list;
    }

    function has(List storage list, address addr) internal view returns (bool) {
        return list.next[addr] != empty;
    }

    function add(List storage list, address addr) internal returns (List memory) {
        require(!has(list, addr), "addr is already in the list");
        list.next[addr] = list.next[start];
        list.next[start] = addr;
        list.llSize++;

        return list;
    }

    function remove(List storage list, address addr, address prevAddr) internal returns (List memory) {
        require(has(list, addr), "addr not whitelisted yet");
        require(list.next[prevAddr] == addr, "wrong prevConsumer");
        list.next[prevAddr] = list.next[addr];
        list.next[addr] = empty;
        list.llSize--;

        return list;
    }

    function getAll(List storage list) internal view returns (address[] memory) {
        address[] memory addrs = new address[](list.llSize);
        address curr = list.next[start];
        for(uint256 i = 0; curr != end; i++) {
            addrs[i] = curr;
            curr = list.next[curr];
        }
        return addrs;
    }

    function getNextOf(List storage list, address curr) internal view returns (address) {
        return list.next[curr];
    }

}

pragma solidity ^0.5.0;

library Hasher {

    function linkId(bytes32 collateralAssetCode, bytes32 peggedCurrency) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(collateralAssetCode, peggedCurrency));
    }

    function lockedReserveId(address from, bytes32 collateralAssetCode, uint256 collateralAmount, uint blockNumber) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, collateralAssetCode, collateralAmount, blockNumber));
    }

    function stableCreditId(string memory assetCode) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(assetCode));
    }
}

