pragma solidity ^0.5.0;

import "../interfaces/IHeart.sol";
import "../interfaces/IDRS.sol";
import "../interfaces/IRM.sol";
import "../interfaces/IStableCredit.sol";
import "../interfaces/ICollateralAsset.sol";

contract DigitalReserveSystem is IDRS {
    using SafeMath for uint256;
    IHeart public heart;

    event Setup(
        string assetCode,
        bytes32 peggedCurrency,
        uint256 peggedValue,
        bytes32 indexed collateralAssetCode,
        address assetAddress
    );

    event Mint(
        string assetCode,
        uint256 mintAmount,
        address indexed assetAddress,
        bytes32 indexed collateralAssetCode,
        uint256 collateralAmount
    );

    event Redeem(
        string assetCode,
        uint256 stableCreditAmount,
        address indexed collateralAssetAddress,
        bytes32 indexed collateralAssetCode,
        uint256 collateralAmount
    );

    event Rebalance(
        string assetCode,
        bytes32 indexed collateralAssetCode,
        uint256 requiredAmount,
        uint256 presentAmount
    );

    modifier onlyTrustedPartner() {
        require(heart.isTrustedPartner(msg.sender), "DigitalReserveSystem.onlyTrustedPartner: caller must be a trusted partner");
        _;
    }

    constructor(address heartAddr) public {
        heart = IHeart(heartAddr);
    }

    function setup(
        bytes32 collateralAssetCode,
        bytes32 peggedCurrency,
        string calldata assetCode,
        uint256 peggedValue
    ) external onlyTrustedPartner returns (string memory, address) {
        // validate asset code
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem.setup: invalid assetCode format");
        require(peggedValue > 0 , "pegged value is greater than 0");
        bytes32 stableCreditId = Hasher.stableCreditId(assetCode);
        IStableCredit stableCredit = heart.getStableCreditById(stableCreditId);
        require(address(stableCredit) == address(0), "DigitalReserveSystem.setup: assetCode has already been used");

        // validate collateralAssetCode
        ICollateralAsset collateralAsset = heart.getCollateralAsset(collateralAssetCode);
        require(address(collateralAsset) != address(0), "DigitalReserveSystem.setup: collateralAssetCode does not exist");

        // validate collateralAssetCode, peggedCurrency
        bytes32 linkId = Hasher.linkId(collateralAssetCode, peggedCurrency);
        require(heart.isLinkAllowed(linkId), "DigitalReserveSystem.setup: collateralAssetCode - peggedCurrency pair does not exist");

        StableCredit newStableCredit = new StableCredit(
            peggedCurrency,
            msg.sender,
            collateralAssetCode,
            address(collateralAsset),
            assetCode,
            peggedValue,
            address(heart)
        );
        heart.addStableCredit(IStableCredit(address(newStableCredit)));
        emit Setup(
            assetCode,
            peggedCurrency,
            peggedValue,
            collateralAssetCode,
            address(newStableCredit)
        );

        return (assetCode, address(newStableCredit));
    }

    function mintFromCollateralAmount(
        uint256 netCollateralAmount,
        string calldata assetCode
    ) external onlyTrustedPartner  returns (bool) {
        (IStableCredit stableCredit, ICollateralAsset collateralAsset, bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);

        // validate stable credit belong to the message sender
        require(msg.sender == stableCredit.creditOwner(), "DigitalReserveSystem.mintFromCollateralAmount: the stable credit does not belong to you");

        (uint256 mintAmount, uint256 actualCollateralAmount, uint256 reserveCollateralAmount, uint256 fee) = _calMintAmountFromCollateral(
            netCollateralAmount,
            heart.getPriceContract(linkId).get(),
            heart.getCreditIssuanceFee(),
            heart.getCollateralRatio(collateralAssetCode),
            stableCredit.peggedValue(),
            100000
        );

        _mint(collateralAsset, stableCredit, mintAmount, fee, actualCollateralAmount, reserveCollateralAmount);

        // redeclare collateralAmount, this a workaround for StackTooDeep error
        uint256 _netCollateralAmount = netCollateralAmount;
        emit Mint(
            assetCode,
            mintAmount,
            address(stableCredit),
            collateralAssetCode,
            _netCollateralAmount
        );

        return true;
    }

    function mintFromStableCreditAmount(
        uint256 mintAmount,
        string calldata assetCode
    ) external onlyTrustedPartner  returns (bool) {
        (IStableCredit stableCredit, ICollateralAsset collateralAsset, bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);

        // validate stable credit belong to the message sender
        require(msg.sender == stableCredit.creditOwner(), "DigitalReserveSystem.mintFromStableCreditAmount: the stable credit does not belong to you");

        (uint256 netCollateralAmount, uint256 actualCollateralAmount, uint256 reserveCollateralAmount, uint256 fee) = _calMintAmountFromStableCredit(
            mintAmount,
            heart.getPriceContract(linkId).get(),
            heart.getCreditIssuanceFee(),
            heart.getCollateralRatio(collateralAssetCode),
            stableCredit.peggedValue(),
            100000
        );

        _mint(collateralAsset, stableCredit, mintAmount, fee, actualCollateralAmount, reserveCollateralAmount);
        uint256 _mintAmount = mintAmount;
        emit Mint(
            assetCode,
            _mintAmount,
            address(stableCredit),
            collateralAssetCode,
            netCollateralAmount
        );

        return true;
    }

    function _validateAssetCode(string memory assetCode) private view returns (IStableCredit, ICollateralAsset, bytes32, bytes32) {
        IStableCredit stableCredit = heart.getStableCreditById(Hasher.stableCreditId(assetCode));
        require(address(stableCredit) != address(0), "DigitalReserveSystem._validateAssetCode: stableCredit not exist");

        bytes32 collateralAssetCode = stableCredit.collateralAssetCode();
        ICollateralAsset collateralAsset = heart.getCollateralAsset(collateralAssetCode);
        require(collateralAsset == stableCredit.collateral(), "DigitalReserveSystem._validateAssetCode: collateralAsset must be the same");

        bytes32 linkId = Hasher.linkId(collateralAssetCode, stableCredit.peggedCurrency());
        require(heart.getPriceContract(linkId).get() > 0, "DigitalReserveSystem._validateAssetCode: valid price not found");

        return (stableCredit, collateralAsset, collateralAssetCode, linkId);
    }

    function _mint(ICollateralAsset collateralAsset, IStableCredit stableCredit, uint256 mintAmount, uint256 fee, uint256 actualCollateralAmount, uint256 reserveCollateralAmount) private returns (bool) {
        bytes32 collateralAssetCode = stableCredit.collateralAssetCode();
        collateralAsset.transferFrom(msg.sender, address(heart), fee);
        collateralAsset.transferFrom(msg.sender, address(stableCredit), actualCollateralAmount.add(reserveCollateralAmount));
        stableCredit.mint(msg.sender, mintAmount);
        stableCredit.approveCollateral();
        heart.collectFee(fee, collateralAssetCode);
        return true;
    }

    function redeem(
        uint256 stableCreditAmount,
        string calldata assetCode
    ) external returns (bool) {
        require(stableCreditAmount > 0, "DigitalReserveSystem.redeem: redeem amount must be greater than 0");
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem.redeem: invalid assetCode format");

        (IStableCredit stableCredit, ICollateralAsset collateralAsset, bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);
        require(address(collateralAsset) != address(0), "DigitalReserveSystem.redeem: collateralAssetCode does not exist");

        _rebalance(assetCode);

        uint256 collateralAmount = _calExchangeRate(stableCredit, linkId, stableCreditAmount);

        stableCredit.redeem(msg.sender, stableCreditAmount, collateralAmount);
        stableCredit.approveCollateral();

        emit Redeem(
            assetCode,
            stableCreditAmount,
            address(collateralAsset),
            collateralAssetCode,
            collateralAmount
        );

        return true;
    }

    function rebalance(
        string calldata assetCode
    ) external  returns (bool) {
        return _rebalance(assetCode);
    }

    function getExchange(
        string calldata assetCode
    ) external view returns (string memory, bytes32, uint256) {
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem.getExchange: invalid assetCode format");

        (IStableCredit stableCredit, , bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);

        (uint256 priceInCollateralPerAssetUnit) = _calExchangeRate(stableCredit, linkId, 100000);

        return (assetCode, collateralAssetCode, priceInCollateralPerAssetUnit);
    }

    function collateralHealthCheck(
        string calldata assetCode
    ) external view returns (address, bytes32, uint256, uint256) {
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem.collateralHealthCheck: invalid assetCode format");
        (IStableCredit stableCredit, ICollateralAsset collateralAsset, bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);
        require(address(collateralAsset) != address(0), "DigitalReserveSystem.collateralHealthCheck: collateralAssetCode does not exist");
        uint256 requiredAmount = _calCollateral(stableCredit, linkId, stableCredit.totalSupply(), heart.getCollateralRatio(collateralAssetCode)).div(100000);
        uint256 presentAmount = stableCredit.collateral().balanceOf(address(stableCredit));
        return (address(collateralAsset), collateralAssetCode, requiredAmount, presentAmount);
    }

    function getStableCreditAmount(
        string calldata assetCode
    ) external view returns ( uint256) {
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem.getStableCreditAmount: invalid assetCode format");

        (IStableCredit stableCredit,,, ) = _validateAssetCode(assetCode);
        return stableCredit.totalSupply();

    }

    function _rebalance(
        string memory assetCode
    ) private returns (bool) {
        require(bytes(assetCode).length > 0 && bytes(assetCode).length <= 12, "DigitalReserveSystem._rebalance: invalid assetCode format");

        (IStableCredit stableCredit, ICollateralAsset collateralAsset, bytes32 collateralAssetCode, bytes32 linkId) = _validateAssetCode(assetCode);
        require(address(collateralAsset) != address(0), "DigitalReserveSystem._rebalance: collateralAssetCode does not exist");
        uint256 requiredAmount = _calCollateral(stableCredit, linkId, stableCredit.totalSupply(), heart.getCollateralRatio(collateralAssetCode)).div(100000);
        uint256 presentAmount = stableCredit.collateral().balanceOf(address(stableCredit));

        if (requiredAmount == presentAmount) {return false;}

        IRM reserveManager = heart.getReserveManager();

        if (requiredAmount > presentAmount) {
            reserveManager.injectCollateral(collateralAssetCode, address(stableCredit), requiredAmount.sub(presentAmount));
        } else {
            stableCredit.transferCollateralToReserve(presentAmount.sub(requiredAmount));
        }

        emit Rebalance(
            assetCode,
            collateralAssetCode,
            requiredAmount,
            presentAmount
        );

        return true;
    }


    function _calMintAmountFromCollateral(
        uint256 netCollateralAmount,
        uint256 price,
        uint256 issuanceFee,
        uint256 collateralRatio,
        uint256 peggedValue,
        uint256 divider
    ) private pure returns (uint256, uint256, uint256, uint256) {
        // fee = netCollateralAmount * (issuanceFee / divider )
        uint256 fee = netCollateralAmount.mul(issuanceFee).div(divider);

        // collateralAmount = netCollateralAmount - fee
        uint256 collateralAmount = netCollateralAmount.sub(fee);

        // mintAmount = (collateralAmount * priceInCurrencyPerCollateralUnit) / (collateralRatio * peggedValue)
        uint256 mintAmount = collateralAmount.mul(price).mul(divider);
        mintAmount = mintAmount.div(collateralRatio.mul(peggedValue));

        // actualCollateralAmount = collateralAmount / collateralRatio
        uint actualCollateralAmount = collateralAmount.mul(divider).div(collateralRatio);

        // reserveCollateralAmount = collateralAmount - actualCollateralAmount
        uint reserveCollateralAmount = collateralAmount.sub(actualCollateralAmount);

        return (mintAmount, actualCollateralAmount, reserveCollateralAmount, fee);
    }

    function _calMintAmountFromStableCredit(
        uint256 mintAmount,
        uint256 price,
        uint256 issuanceFee,
        uint256 collateralRatio,
        uint256 peggedValue,
        uint256 divider
    ) private pure returns (uint256, uint256, uint256, uint256) {
        // collateralAmount = (mintAmount * collateralRatio * peggedValue) / priceInCurrencyPerCollateralUnit
        uint256 collateralAmount = mintAmount.mul(collateralRatio).mul(peggedValue);
        collateralAmount = collateralAmount.div(price).div(divider);

        // fee = (collateralAmount * issuanceFee) / (divider - issuanceFee)
        uint256 fee = collateralAmount.mul(issuanceFee).div(divider.sub(issuanceFee));

        // netCollateralAmount = collateralAmount + fee
        uint256 netCollateralAmount = collateralAmount.add(fee);

        // actualCollateralAmount = collateralAmount / collateralRatio
        uint actualCollateralAmount = collateralAmount.mul(divider).div(collateralRatio);

        // reserveCollateralAmount = collateralAmount - actualCollateralAmount
        uint reserveCollateralAmount = collateralAmount.sub(actualCollateralAmount);

        return (netCollateralAmount, actualCollateralAmount, reserveCollateralAmount, fee);
    }

    function _calCollateral(IStableCredit credit, bytes32 linkId, uint256 creditAmount, uint256 collateralRatio) private view returns (uint256) {
        // collateral = (creditAmount * peggedValue * collateralRatio) / priceInCurrencyPerAssetUnit
        return creditAmount.mul(credit.peggedValue().mul(collateralRatio)).div(heart.getPriceContract(linkId).get());
    }

    function _calExchangeRate(IStableCredit credit, bytes32 linkId, uint256 stableCreditAmount) private view returns (uint256) {
        // priceInCollateral = (collateralRatio * peggedValue * stableCreditAmount) / priceInCurrencyPerAssetUnit
        uint256 priceInCollateralPerAssetUnit = heart.getCollateralRatio(credit.collateralAssetCode()).mul(credit.peggedValue()).mul(stableCreditAmount).div(heart.getPriceContract(linkId).get()).div(100000);
        return (priceInCollateralPerAssetUnit);
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

interface IDRS {
    function setup(
        bytes32 collateralAssetCode,
        bytes32 peggedCurrency,
        string calldata assetCode,
        uint256 peggedValue
    ) external returns (string memory, address);

    function mintFromCollateralAmount(
        uint256 collateralAmount,
        string calldata assetCode
    ) external  returns (bool);

    function mintFromStableCreditAmount(
        uint256 stableCreditAmount,
        string calldata assetCode
    ) external  returns (bool);

    function redeem(
        uint256 amount,
        string calldata assetCode
    ) external returns (bool);

    function rebalance(
        string calldata assetCode
    ) external  returns (bool);

    function getExchange(
        string calldata assetCode
    ) external view returns (string memory, bytes32, uint256);

    function collateralHealthCheck(
        string calldata assetCode
    ) external view returns (address, bytes32, uint256, uint256);

    function getStableCreditAmount(
        string calldata assetCode
    ) external view returns ( uint256);
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

