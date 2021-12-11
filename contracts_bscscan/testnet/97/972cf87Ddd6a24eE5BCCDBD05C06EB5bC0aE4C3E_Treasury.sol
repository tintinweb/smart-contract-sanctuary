// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Constants.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ICollateralRatioPolicy.sol";
import "./interfaces/ITreasuryPolicy.sol";
import "./interfaces/ICollateralReserve.sol";
import "./interfaces/IPairOracle.sol";
import "./interfaces/IOracle.sol";

contract Treasury is ITreasury, Ownable, Constants, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // addresses
    address public override collateralReserve;
    address public oracleReiParissqm;
    address public oracleBusdParissqm;
    address public oracleLtyBusd;
    address public dollar;
    address public share;
    address public collateral;
    address public collateralRatioPolicy;
    address public treasuryPolicy;
    // XXX
    // address public profitSharingFund;
    // address public profitController;

    // pools
    address[] public pools_array;
    mapping(address => bool) public pools;

    // Constants for various precisions
    // uint256 private constant RATIO_PRECISION = 1e6;

    // Number of decimals needed to get to 18
    uint256 public missing_decimals;

    /* ========== MODIFIERS ========== */

    /**
     * @dev Reverts if `msg.sender` is not a pool.
     */
    modifier onlyPools {
        require(pools[msg.sender], "Only pools can use this function");
        _;
    }

    // XXX
    // modifier onlyProfitController {
    //     require(
    //         msg.sender == profitController || msg.sender == owner(),
    //         "Only profit controller or owner can trigger"
    //     );
    //     _;
    // }

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Initializes contract setting up all necessary addresses.
     * @param _dollar Address of Dollar smart contract.
     * @param _share Address of Share smart contract.
     * @param _collateral Address of Collateral smart contract.
     * @param _treasuryPolicy Address of TreasuryPolicy smart contract.
     * @param _collateralRatioPolicy Address of CollateralRatioPolicy smart contract.
     * @param _collateralReserve Address of CollateralReserve smart contract.
     */
    function initialize(
        address _dollar,
        address _share,
        address _collateral,
        address _treasuryPolicy,
        address _collateralRatioPolicy,
        address _collateralReserve
        // XXX
        // address _profitSharingFund,
        // address _profitController
    ) external initializer onlyOwner {
        require(_dollar != address(0), "invalidAddress");
        require(_share != address(0), "invalidAddress");
        dollar = _dollar;
        share = _share;
        setCollateralAddress(_collateral);
        setTreasuryPolicy(_treasuryPolicy);
        setCollateralRatioPolicy(_collateralRatioPolicy);
        setCollateralReserve(_collateralReserve);
        // XXX
        // setProfitSharingFund(_profitSharingFund);
        // setProfitController(_profitController);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns quantity of PARISSQM that you can buy for 1 REI.
     */
    function dollarPrice() public view returns (uint256) {
        return IOracle(oracleReiParissqm).consult();
    }

    /**
     * @dev Returns quantity of PARISSQM that you can buy for 1 share.
     */
    function sharePrice() public view returns (uint256) {
        return IPairOracle(oracleLtyBusd).consult(share, PRICE_PRECISION);
    }

    /**
     * @dev Checks if `_address` is a pool.
     * @param _address Address that is being checked.
     */
    function hasPool(address _address) external view override returns (bool) {
        return pools[_address] == true;
    }

    /**
     * @dev Returns target collateral ratio.
     */
    function target_collateral_ratio() public view returns (uint256) {
        return ICollateralRatioPolicy(collateralRatioPolicy).target_collateral_ratio();
    }

    /**
     * @dev Returns effective collateral ratio.
     */
    function effective_collateral_ratio() public view returns (uint256) {
        return ICollateralRatioPolicy(collateralRatioPolicy).effective_collateral_ratio();
    }

    /**
     * @dev Returns current minting fee.
     */
    function minting_fee() public view returns (uint256) {
        return ITreasuryPolicy(treasuryPolicy).minting_fee();
    }

    /**
     * @dev Returns current redemption fee.
     */
    function redemption_fee() public view returns (uint256) {
        return ITreasuryPolicy(treasuryPolicy).redemption_fee();
    }

    /**
     * @dev Returns info needed for minting Collateral/Share. It's used in Pool's mint function.
     */
    function infoForMinting() external view override returns (uint256, uint256, uint256) {
        return (sharePrice(), target_collateral_ratio(), minting_fee());
    }

    /**
     * @dev Returns info needed for redeeming Collateral/Share. It's used in Pool's redeem function.
     */
    function infoForRedeeming() external view override returns (uint256, uint256, uint256) {
        return (sharePrice(), effective_collateral_ratio(), redemption_fee());
    }

    /**
     * @dev Returns dollar, share prices and dollar total supply.
     */
    function infoForGlobalValues() external view override returns (uint256, uint256, uint256) {
        return (dollarPrice(), sharePrice(), IERC20(dollar).totalSupply());
    }

    /**
     * @dev Returns every possible information piece you might want to know.
     * @return dollarPrice
     * @return sharePrice
     * @return dollarTotalSupply
     * @return targetCollateralRatio
     * @return effectiveCollateralRatio
     * @return globalCollateralRatio
     * @return mingingFee
     * @return redemptionFee
     */
    // function info()
    //     external
    //     view
    //     override
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return (
    //         dollarPrice(),
    //         sharePrice(),
    //         IERC20(dollar).totalSupply(),
    //         target_collateral_ratio(),
    //         effective_collateral_ratio(),
    //         globalCollateralValue(),
    //         minting_fee(),
    //         redemption_fee()
    //     );
    // }

    /**
     * @dev Returns global collateral balance.
     */
    function globalCollateralBalance() public view override returns (uint256) {
        uint256 _collateralReserveBalance = IERC20(collateral).balanceOf(collateralReserve);
        return _collateralReserveBalance - totalUnclaimedCollateralBalance();
    }

    /**
     * @dev Returns global share balance.
     */
    function globalShareBalance() public view override returns (uint256) {
        uint256 _shareReserveBalance = IERC20(share).balanceOf(collateralReserve);
        return _shareReserveBalance - totalUnclaimedShareBalance();
    }

    /**
     * @dev Returns global collateral value.
     */
    function globalCollateralValue() public view override returns (uint256) {
        return globalCollateralBalance();
    }

    /**
     * @dev Returns global share value.
     */
    function globalShareValue() public view override returns (uint256) {
        return IPairOracle(oracleLtyBusd).consult(share, globalShareBalance());
    }

    function globalDollarValue() public view override returns (uint256) {
        return IERC20(dollar).totalSupply() * PRICE_PRECISION / IOracle(oracleBusdParissqm).consult();
    }

    /**
     * @dev Iterates through all pools and calculate all unclaimed collaterals in all pools globally.
     */
    function totalUnclaimedCollateralBalance() public view returns (uint256) {
        uint256 _totalUnclaimed = 0;
        for (uint256 i = 0; i < pools_array.length; i++) {
            // Exclude null addresses
            if (pools_array[i] != address(0)) {
                _totalUnclaimed =
                    _totalUnclaimed +
                    (IPool(pools_array[i]).unclaimed_pool_collateral());
            }
        }
        return _totalUnclaimed;
    }

    /**
     * @dev Iterates through all pools and calculate all unclaimed shares in all pools globally.
     */
    function totalUnclaimedShareBalance() public view returns (uint256) {
        uint256 _totalUnclaimed = 0;
        for (uint256 i = 0; i < pools_array.length; i++) {
            // Exclude null addresses
            if (pools_array[i] != address(0)) {
                _totalUnclaimed =
                    _totalUnclaimed +
                    (IPool(pools_array[i]).unclaimed_pool_share());
            }
        }
        return _totalUnclaimed;
    }

    /**
     * @dev Returns excess collateral balance.
     */
    // function excessCollateralBalance() public view returns (uint256 _excess) {
    //     uint256 _tcr = target_collateral_ratio();
    //     uint256 _ecr = effective_collateral_ratio();
    //     if (_ecr <= _tcr) {
    //         _excess = 0;
    //     } else {
    //         _excess = ((_ecr - _tcr) * globalCollateralBalance()) / RATIO_PRECISION;
    //     }
    // }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Transfers `_amount` of tokens to `_receiver`. Can be called only by pool.
     * @param _token Address of ERC-20 token.
     * @param _receiver Address of funds receiver.
     * @param _amount Amount of tokens to transfer to `_receiver`.
     *
     * Reverts if `_reciever` is zero address. Also reverts if `_amount` equals to zero.
     */
    function requestTransfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external override onlyPools {
        ICollateralReserve(collateralReserve).transferTo(_token, _receiver, _amount);
    }

        /**
     * @dev Swap `_amount` of `_exchangedToken` tokens to swap for `_receivedToken`. Can be called only by pool.
     * @param _exchangedToken Address of ERC-20 token.
     * @param _receivedToken Address of ERC-20 token.
     * @param _tokenAmount Amount of `_exchangedToken` tokens to swap for `_receivedToken`.
     *
     * Reverts if `_reciever` is zero address. Also reverts if `_amount` equals to zero.
     */
    function requestSwapBeforeMint(
        address _exchangedToken,
        address _receivedToken,
        uint256 _tokenAmount
    ) external override onlyPools {
        ICollateralReserve(collateralReserve).swapBeforeMint(_exchangedToken, _receivedToken, _tokenAmount);
    }

    // XXX
    // function extractProfit(uint256 _amount) external onlyProfitController {
    //     require(_amount > 0, "zero amount");
    //     require(profitSharingFund != address(0), "Invalid profitSharingFund");
    //     uint256 _maxExcess = excessCollateralBalance();
    //     uint256 _maxAllowableAmount =
    //         _maxExcess -
    //             ((_maxExcess * ITreasuryPolicy(treasuryPolicy).excess_collateral_safety_margin()) /
    //                 RATIO_PRECISION);
    //     require(_amount <= _maxAllowableAmount, "Excess allowable amount");
    //     ICollateralReserve(collateralReserve).transferTo(collateral, profitSharingFund, _amount);
    //     emit ProfitExtracted(_amount);
    // }

    /**
     * @dev Marks address as a pool.
     * @param pool_address Address to be marked as a pool.
     */
    function addPool(address pool_address) public onlyOwner {
        require(pools[pool_address] == false, "poolExisted");
        pools[pool_address] = true;
        pools_array.push(pool_address);
        emit PoolAdded(pool_address);
    }

    /**
     * @dev Unmarks address as a pool. Can be called only by the owner.
     * @param pool_address Address to be unmarked.
     */
    function removePool(address pool_address) public onlyOwner {
        require(pools[pool_address] == true, "!pool");
        // Delete from the mapping
        delete pools[pool_address];
        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < pools_array.length; i++) {
            if (pools_array[i] == pool_address) {
                pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
        emit PoolRemoved(pool_address);
    }

    /**
     * @dev Sets TreasuryPolicy smart contract address. Can be called only by the owner.
     * @param _treasuryPolicy Address of TreasuryPolicy smart contract.
     *
     * Reverts if `_treasuryPolicy` is zero address.
     */
    function setTreasuryPolicy(address _treasuryPolicy) public onlyOwner {
        require(_treasuryPolicy != address(0), "invalidAddress");
        treasuryPolicy = _treasuryPolicy;
    }

    /**
     * @dev Sets CollateralRatioPolicy smart contract address. Can be called only by the owner.
     * @param _collateralRatioPolicy Address of CollateralRatioPolicy smart contract.
     *
     * Reverts if `_collateralRatioPolicy` is zero address.
     */
    function setCollateralRatioPolicy(address _collateralRatioPolicy) public onlyOwner {
        require(_collateralRatioPolicy != address(0), "invalidAddress");
        collateralRatioPolicy = _collateralRatioPolicy;
    }

    /**
     * @dev Sets ReiParissqmOracle smart contract address. Can be called only by the owner.
     * @param _oracleReiParissqm Address of ReiParissqmOracle smart contract.
     *
     * Reverts if `_oracleDollar` is zero address.
     */
    function setReiParissqmOracle(address _oracleReiParissqm) external onlyOwner {
        require(_oracleReiParissqm != address(0), "invalidAddress");
        oracleReiParissqm = _oracleReiParissqm;
    }

    function setBusdParissqmOracle(address _oracleBusdParissqm) external onlyOwner {
        require(_oracleBusdParissqm != address(0), "invalidAddress");
        oracleBusdParissqm = _oracleBusdParissqm;
    }

    /**
     * @dev Sets LtyBusdOracle smart contract address. Can be called only by the owner.
     * @param _oracleLtyBusd Address of ShareOracle smart contract.
     *
     * Reverts if `_oracleLtyBusd` is zero address.
     */
    function setLtyBusdOracle(address _oracleLtyBusd) external onlyOwner {
        require(_oracleLtyBusd != address(0), "invalidAddress");
        oracleLtyBusd = _oracleLtyBusd;
    }

    /**
     * @dev Sets Collateral smart contract address. Can be called only by the owner.
     * @param _collateral Address of Collateral smart contract.
     *
     * Reverts if `_collateral` is zero address.
     */
    function setCollateralAddress(address _collateral) public onlyOwner {
        require(_collateral != address(0), "invalidAddress");
        collateral = _collateral;
        missing_decimals = 18 - ERC20(_collateral).decimals();
    }

    /**
     * @dev Sets CollateralReserve smart contract address. Can be called only by the owner.
     * @param _collateralReserve Address of CollateralReserve smart contract.
     *
     * Reverts if `_collateralReserve` is zero address.
     */
    function setCollateralReserve(address _collateralReserve) public onlyOwner {
        require(_collateralReserve != address(0), "invalidAddress");
        collateralReserve = _collateralReserve;
    }

    // XXX
    // function setProfitSharingFund(address _profitSharingFund) public onlyOwner {
    //     require(_profitSharingFund != address(0), "invalidAddress");
    //     profitSharingFund = _profitSharingFund;
    // }

    // XXX
    // function setProfitController(address _profitController) public onlyOwner {
    //     require(_profitController != address(0), "invalidAddress");
    //     profitController = _profitController;
    // }

    /* ========== EVENTS ========== */

    /**
     * @dev Triggered when new poll is added.
     * @param pool Address of a new pool.
     */
    event PoolAdded(address indexed pool);

    /**
     * @dev Triggered when pool is removed.
     * @param pool Address of the removed pool.
     */
    event PoolRemoved(address indexed pool);

    // XXX
    // event ProfitExtracted(uint256 amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor () {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

contract Constants {
    uint256 constant PRICE_PRECISION = 1e12;
    uint256 constant RATIO_PRECISION = 1e6;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITreasury {
    function hasPool(address _address) external view returns (bool);

    function collateralReserve() external view returns (address);

    function globalCollateralBalance() external view returns (uint256);

    function globalShareBalance() external view returns (uint256);

    function globalCollateralValue() external view returns (uint256);

    function globalShareValue() external view returns (uint256);

    function globalDollarValue() external view returns (uint256);

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function infoForMinting() external view returns (uint256, uint256, uint256);

    function infoForRedeeming() external view returns (uint256, uint256, uint256);

    function infoForGlobalValues() external view returns (uint256, uint256, uint256);

    function requestSwapBeforeMint(
        address _exchangedToken,
        address _receivedToken,
        uint256 _tokenAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IOracle {
    function consult() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IPool {
    function getPrice(address _oracle) external view returns (uint256);

    function unclaimed_pool_collateral() external view returns (uint256);

    function unclaimed_pool_share() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ICollateralRatioPolicy {
    function target_collateral_ratio() external view returns (uint256);

    function effective_collateral_ratio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ITreasuryPolicy {
    function minting_fee() external view returns (uint256);

    function redemption_fee() external view returns (uint256);

    function excess_collateral_safety_margin() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ICollateralReserve {
    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;
    function swapBeforeMint(address _exchangedToken,  address _receivedToken, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IPairOracle {
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

    function update() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}