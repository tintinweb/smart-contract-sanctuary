// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// import "./lib/FixidityLib.sol";
// import "./lib/LogarithmLib.sol";
// import "./lib/ExponentLib.sol";

contract FortubeDao is ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // using FixidityLib for FixidityLib.Fixidity;
    // using ExponentLib for FixidityLib.Fixidity;
    // using LogarithmLib for FixidityLib.Fixidity;

    // FixidityLib.Fixidity public fixidity;

    ///@notice token address
    address public reservedToken;

    ///@notice 1e18 level
    uint256 public slope;

    ///@notice 1e18 level
    uint256 public intercept;

    ///@notice total token amount in the contract
    uint256 public totalToken;

    ///@notice 出售延迟时间 3d
    uint256 public sellDelay;

    ///@notice operator
    address public operator;

    ///@notice multiSig
    address public multiSig;

    //卖出限制：系统将在用户执行卖出$fDAO操作时，检测用户上次的买入时间距离本次卖出时间是否小于72小时，小于则收取卖出$fDAO获得的FOR的5%作为手续费。
    mapping(address => uint256) public lastBoughtTime;

    ///@notice 国库账户，用于收取提前退出手续费
    address public treasury;

    ///@notice 提前卖出罚金
    uint256 public penalty; // 500/10000 for 0.05, max % is 10%

    uint256 public gasPriceCap;// tx.gasprice cap

    event Bought(address user, uint256 forAmount, uint256 daoAmount, uint256 timestamp);

    // userForAmount: 用户扣除罚金后，实际得到的FOR数量
    // penaltyForAmount: 扣除的罚金数量
    event Sold(address user, uint256 userForAmount, uint256 penaltyForAmount, uint256 daoAmount, uint256 timestamp);

    event SponsorIn(uint256 totalToken, uint256 inAmount);

    event SponsorOut(uint256 totalToken, address sponsorTo, uint256 outAmount);

    event SellDelayChanged(uint256 oldSellDelay, uint256 newSellDelay);

    event OperatorChanged(address oldOperator, address newOperator);

    event MultiSigChanged(address oldMultiSig, address newMultiSig);

    event TreasuryChanged(address oldTreasury, address newTreasury);

    event PenaltyChanged(uint256 oldPenalty, uint256 newPenalty);

    event Synced(uint256 oldSlope, uint256 newSlope);

    event GasPriceCapChanged(uint256 oldGasPriceCap, uint256 newGasPriceCap);

    modifier onlyOperator {
        require(msg.sender == operator, "Operator required");
        _;
    }

    modifier onlyMultiSig {
        require(msg.sender == multiSig, "MultiSig required");
        _;
    }

    modifier onlyValidGasPrice {
        require(tx.gasprice <= gasPriceCap, "exceed max gas price");
        _;
    }

    function initialize(
        uint256 _slope,
        uint256 _intercept,
        address _reservedToken,
        address _multiSig,
        uint256 _gasPriceCap // 20 gwei
    ) public initializer {
        __ERC20_init("ForTube DAO", "FDAO");
        slope = _slope;
        intercept = _intercept;
        reservedToken = _reservedToken;
        sellDelay = 3 days;
        operator = msg.sender;
        multiSig = _multiSig;
        penalty = 500;//0.05

        gasPriceCap = _gasPriceCap;
    }

    // remember to init this
    // function init(uint8 digits) external onlyOperator {
    //     fixidity.init(digits);
    // }

    ///@notice 用 for 购买 dao
    ///@param amount 购买付出的 for 的数量
    ///@param amountOutMin 获得的可接受的最小的fDAO的数量
    function buy(uint256 amount, uint256 amountOutMin) external onlyValidGasPrice {
        require(amount > 0, "Invalid amount");
        require(
            IERC20Upgradeable(reservedToken).balanceOf(msg.sender) >= amount,
            "Insufficient token"
        );

        uint256 daoAmount = calculatePurchaseReturn(amount);
        require(daoAmount >= amountOutMin, "ForTubeDAO: INSUFFICIENT_OUTPUT_FDAO_AMOUNT");
        require(daoAmount > 0, "Zero DAO amount");
        _mint(msg.sender, daoAmount);
        totalToken = totalToken.add(amount);
        
        // T+n limit
        lastBoughtTime[msg.sender] = block.timestamp;

        IERC20Upgradeable(reservedToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit Bought(msg.sender, amount, daoAmount, block.timestamp);
    }

    ///@notice 用 for 购买 dao
    ///@param daoAmount 购买得到的 fDAO 的数量
    ///@param amountInMax 付出的最大的for的数量
    function buyExactDAO(uint256 daoAmount, uint256 amountInMax) external onlyValidGasPrice {
        require(daoAmount > 0, "Invalid daoAmount");
        // require(daoAmount <= totalSupply(), "exceed max DAO supply");

        uint256 amount = calculateBuyReturn(daoAmount);
        require(amount <= amountInMax, "ForTubeDAO: INPUT_FOR_AMOUNT");
        require(
            IERC20Upgradeable(reservedToken).balanceOf(msg.sender) >= amount,
            "Insufficient token"
        );

        _mint(msg.sender, daoAmount);
        totalToken = totalToken.add(amount);
        
        // T+n limit
        lastBoughtTime[msg.sender] = block.timestamp;

        IERC20Upgradeable(reservedToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit Bought(msg.sender, amount, daoAmount, block.timestamp);
    }

    ///@notice 出售
    ///@param daoAmount 出售的 daoToken 的数量
    ///@param amountOutMin 获得的可接受的最小的FOR的数量
    function sell(uint256 daoAmount, uint256 amountOutMin) external onlyValidGasPrice {
        require(daoAmount > 0, "Invalid daoAmount");
        require(daoAmount <= balanceOf(msg.sender), "Insufficient daoAmount");

        uint256 amount = calculateSaleReturn(daoAmount);
        require(amount >= amountOutMin, "ForTubeDAO: INSUFFICIENT_OUTPUT_FOR_AMOUNT");// 在扣除罚金之前算滑点
        require(amount > 0, "Zero FOR amount");

        uint256 _penaltyAmount = 0;
        _burn(msg.sender, daoAmount);

        amount = min(totalToken, amount);
        totalToken = totalToken.sub(amount);

        if (block.timestamp < lastBoughtTime[msg.sender] + sellDelay) {
            _penaltyAmount = amount.mul(penalty).div(10000);
            amount = amount.sub(_penaltyAmount);
            IERC20Upgradeable(reservedToken).safeTransfer(treasury, _penaltyAmount);
        }

        IERC20Upgradeable(reservedToken).safeTransfer(msg.sender, amount);

        emit Sold(msg.sender, amount, _penaltyAmount, daoAmount, block.timestamp);
    }


    ///@notice 出售
    ///@param amount 想要获得的FOR的数量
    ///@param amountInMax 最大可接受付出的fDAO的数量
    function sellExactDAO(uint256 amount, uint256 amountInMax) external onlyValidGasPrice {
        require(amount > 0, "Invalid daoAmount");

        uint256 daoAmount = calculateSaleExactReturn(amount);
        require(amountInMax >= daoAmount, "ForTubeDAO: INSUFFICIENT_OUTPUT_FOR_AMOUNT");// 在扣除罚金之前算滑点
        require(daoAmount > 0, "Zero FOR amount");
        require(daoAmount <= balanceOf(msg.sender), "Insufficient daoAmount");

        uint256 _penaltyAmount = 0;
        _burn(msg.sender, daoAmount);

        amount = min(totalToken, amount);
        totalToken = totalToken.sub(amount);

        if (block.timestamp < lastBoughtTime[msg.sender] + sellDelay) {
            _penaltyAmount = amount.mul(penalty).div(10000);
            amount = amount.sub(_penaltyAmount);
            IERC20Upgradeable(reservedToken).safeTransfer(treasury, _penaltyAmount);
        }

        IERC20Upgradeable(reservedToken).safeTransfer(msg.sender, amount);

        emit Sold(msg.sender, amount, _penaltyAmount, daoAmount, block.timestamp);
    }


    ///@notice 向合约打入收益
    ///@param amount for 的数量
    function sponsorIn(uint256 amount) external onlyValidGasPrice {
        require(amount > 0, "Invalid amount");
        require(totalSupply() > 0, "Cannot sponsor when totalSupply is 0");

        totalToken = totalToken.add(amount);
        sync();
        IERC20Upgradeable(reservedToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit SponsorIn(totalToken, amount);
    }

    ///@notice take token out
    ///@param sponsorTo recipient
    ///@param amount token amount
    function sponsorOut(address sponsorTo, uint256 amount)
        external
        onlyValidGasPrice
        onlyMultiSig
    {
        require(amount > 0 && amount <= calcMaxSponsorOut(), "Invalid amount");
        require(sponsorTo != address(0), "Invalid address");

        totalToken = totalToken.sub(amount);
        sync();
        assert(slope > 0);
        IERC20Upgradeable(reservedToken).safeTransfer(sponsorTo, amount);

        emit SponsorOut(totalToken, sponsorTo, amount);
    }

    function sync() internal {
        uint256 oldSlope = slope;
        slope = calcNewSlope(totalToken, totalSupply());

        emit Synced(oldSlope, slope);
    }

    ///@notice 计算购买可得 dao 的数量
    ///@param _amount 购买付出的 for 数量
    ///@param daoAmount 获得的 daoToken 数量
    /// 假设用M个FOR购买fDAO，获得的fDAO为x。此时已知系统中已供给a个fDAO（被买走的fDAO），已存入T个FOR，模型斜率为k。截距为n
    /// 则M为梯形面积（梯形面积公式为：[（上底+下底）×高]÷2
    /// m = [(ak+n)+[(a+x)k+n]]*x/2 = [2(ak+n)x+kx^2]/2
    /// 解二元一次方程舍去负值可到x
    /// x = (sqrt((ak+n)^2+2km)-(ak+n))/k
    function calculatePurchaseReturn(uint256 _amount)
        public
        view
        returns (uint256 daoAmount)
    {
        uint256 supply = totalSupply();

        uint256 a = slope.mul(supply).div(1e18).add(intercept); // ak+n
        a = a.mul(a).div(1e18);//(ak+n)^2
        int256 radicand = int256(a.add(slope.mul(_amount).mul(2).div(1e18)));//(ak+n)^2+2km
        // uint256 b =
        //     uint256(fixidity.root_n(radicand, 2)).sub(
        //         slope.mul(supply).div(1e18).add(intercept)
        //     );
        uint256 b =
            uint256(sqrt(uint256(radicand * 1e18))).sub(
                slope.mul(supply).div(1e18).add(intercept)
            );      //sqrt((ak+n)^2+2km)-(ak+n)

        daoAmount = b.mul(1e18).div(slope);
    }

    ///@notice 计算出售可得 for 的数量
    ///@param _sellAmount 出售的 daoToken 数量
    ///@param amount 出售获得的 for 数量
    // 假设卖掉b个fDAO，获得的FOR为x. 此时已知系统中已供给a个fDAO（被买走的fDAO）,已存入T个FOR，模型斜率为k。截距为n
    // x = [(ak+n)+[(a-b)k+n]]*b/2 = (ak-bk/2+n)*b
    function calculateSaleReturn(uint256 _sellAmount)
        public
        view
        returns (uint256 amount)
    {
        uint256 a =
            slope
                .mul(totalSupply())
                .div(1e18)
                .sub(slope.mul(_sellAmount).div(2e18))
                .add(intercept);
        amount = a.mul(_sellAmount).div(1e18);
    }

    ///@notice 计算购买for 的数量
    ///@param _buyFdaoAmount 购买的 daoToken 数量
    ///@param amount 购买需要付出的 for 数量
    // 假设购买b个fDAO，付出的FOR为x. 此时已知系统中已供给a个fDAO（被买走的fDAO）,已存入T个FOR，模型斜率为k。截距为n
    // x = [(ak+n)+[(a+b)k+n]]*b/2 = (ak+bk/2+n)*b
    function calculateBuyReturn(uint256 _buyFdaoAmount) public view returns (uint256 amount) {
        uint256 a =
            slope
                .mul(totalSupply())
                .div(1e18)
                .add(slope.mul(_buyFdaoAmount).div(2e18))
                .add(intercept);
        amount = a.mul(_buyFdaoAmount).div(1e18);
    }


    ///@notice 根据可获得的FOR的数量计算需要卖出的fDAO的数量.
    ///@param _amount 要获得的FOR的数量
    ///@param daoAmount 需要卖出的 fDAO 数量
    // 假设要获得x个FOR, 需要卖出b个fDAO, 此时已知系统中已供给a个fDAO(被买走的fDAO), 已存入T个FOR, 模型斜率为k。
    /// x = [[(ak+n)+[(a-b)k+n]]*b]/2 = [2(ak+n)b-kb^2]/2
    /// 解得 b = [(ak+n)-sqrt[(ak+n)^2-2kx]]/k
    function calculateSaleExactReturn(uint256 _amount)
        public
        view
        returns (uint256 daoAmount)
    {
        uint256 supply = totalSupply();

        uint256 a = slope.mul(supply).div(1e18).add(intercept); // ak+n
        uint256 p = a.mul(a).div(1e18);//(ak+n)^2
        int256 radicand = int256(p.sub(slope.mul(_amount).mul(2).div(1e18)));//(ak+n)^2-2kx
        uint256 b = a.sub(sqrt(uint256(radicand * 1e18))); //(ak+n)-sqrt[(ak+n)^2-2kx]
        daoAmount = b.mul(1e18).div(slope);// [(ak+n)-sqrt[(ak+n)^2-2kx]] / k
    }


    ///@notice 计算新斜率
    ///@param 合约中的 for 数量
    ///@param 当前 dao 的 supply
    /// 根据梯形面积算出斜率
    /// 上底：intercept
    /// 下底：kx+b => k * supply + intercept
    /// 面积为：_totalToken
    /// 解得：k = (2 * _totalToken/supply - 2 * intercept)/supply
    function calcNewSlope(uint256 _totalToken, uint256 supply)
        public
        view
        returns (uint256)
    {
        uint256 dividend =
            _totalToken.mul(2e18).div(supply).sub(intercept.mul(2));
        return dividend.mul(1e18).div(supply);
    }

    ///@notice 获取管理员最大可提取的数量
    /// fDAO兜底的最大金额为 ax^2/2
    function calcMaxSponsorOut() public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply.mul(supply).mul(slope).div(2e36);
    }

    ///@notice set new sell delay
    ///@param _sellDelay set new delay
    function setSellDelay(uint256 _sellDelay) external onlyOperator {
        uint256 oldDelay = sellDelay;
        sellDelay = _sellDelay;

        emit SellDelayChanged(oldDelay, sellDelay);
    }

    function setPenalty(uint256 _newPenalty) external onlyMultiSig {
        require(_newPenalty <= 1000, "Penalty rate exceed max 10% limit");

        uint256 oldPenalty = penalty;
        penalty = _newPenalty;

        emit PenaltyChanged(oldPenalty, _newPenalty);
    }

    ///@notice set new operator
    ///@param _operator new operator
    function setOperator(address _operator) external onlyMultiSig {
        address oldOperator = operator;
        operator = _operator;

        emit OperatorChanged(oldOperator, operator);
    }

    ///@notice set new multi sig
    ///@param _multiSig new multi sig
    function setMultiSig(address _multiSig) external onlyMultiSig {
        address oldMultiSig = multiSig;
        multiSig = _multiSig;

        emit MultiSigChanged(oldMultiSig, multiSig);
    }

    ///@notice 设置新的国库地址
    ///@param _treasury 新的国库地址
    function setTreasury(address _treasury) external onlyMultiSig {
        require(_treasury != address(0), "treasury should not address(0)");

        address oldTreasury = treasury;
        treasury = _treasury;

        emit TreasuryChanged(oldTreasury, treasury);
    }

    function setGasPriceGap(uint256 _gasPriceCap) external onlyOperator {
        require(_gasPriceCap > 0, "zero gas price cap");

        uint256 oldGasPriceCap = gasPriceCap;
        gasPriceCap = _gasPriceCap;

        emit GasPriceCapChanged(oldGasPriceCap, _gasPriceCap);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? b : a;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    // https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/master/contracts/utils/HomoraMath.sol
    function sqrt(uint x) public pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * Requirements:
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
     * Requirements:
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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