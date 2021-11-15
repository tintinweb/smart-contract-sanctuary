pragma solidity ^0.6.12;

import "./libraries/ReflectToken.sol";
import "./libraries/Percent.sol";
import "./libraries/Set.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ILedgity.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/ILedgityPriceOracle.sol";

// SPDX-License-Identifier: Unlicensed
contract Ledgity is ILedgity, ReflectToken {
    using SafeMath for uint256;
    using Percent for Percent.Percent;
    using Set for Set.AddressSet;

    uint256 public constant initialTotalSupply = 2760000000 * 10**18;

    uint256 public numTokensToSwap;
    bool public inSwapAndLiquify;
    enum FeeDestination {
        Liquify,
        Collect
    }
    FeeDestination public feeDestination = FeeDestination.Liquify;
    Percent.Percent public sellAccumulationFee = Percent.encode(6, 100);
    Percent.Percent public initialSellAccumulationFee = sellAccumulationFee;
    Percent.Percent public sellAtSmallPriceAccumulationFee = Percent.encode(6 + 15, 100);
    Percent.Percent public initialSellAtSmallPriceAccumulationFee = sellAtSmallPriceAccumulationFee;
    Percent.Percent public sellReflectionFee = Percent.encode(4, 100);
    Percent.Percent public initialSellReflectionFee = sellReflectionFee;
    Percent.Percent public buyAccumulationFee = Percent.encode(4, 100);
    Percent.Percent public initialBuyAccumulationFee = buyAccumulationFee;
    Set.AddressSet private _dexes;
    Set.AddressSet private _excludedFromDexFee;

    Set.AddressSet private _excludedFromLimits;
    mapping(address => uint256) public soldPerPeriod;
    mapping(address => uint256) public firstSellAt;
    Percent.Percent public maxTransactionSizePercent = Percent.encode(5, 10000);

    IUniswapV2Pair public uniswapV2Pair;
    IReserve public reserve;
    ILedgityPriceOracle public priceOracle;
    uint256 public initialPrice;

    constructor() public ReflectToken("Ledgity", "LTY", initialTotalSupply) {
        numTokensToSwap = totalSupply().mul(15).div(10000);
        setIsExcludedFromDexFee(owner(), true);
        setIsExcludedFromDexFee(address(this), true);
        setIsExcludedFromLimits(owner(), true);
        setIsExcludedFromLimits(address(this), true);
        excludeAccount(address(this));
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function initializeReserve(address reserveAddress) external onlyOwner {
        reserve = IReserve(reserveAddress);
        setIsExcludedFromDexFee(address(reserve), true);
        setIsExcludedFromLimits(address(reserve), true);
        excludeAccount(address(reserve));
        uniswapV2Pair = reserve.uniswapV2Pair();
        setDex(address(uniswapV2Pair), true);
    }

    function initializePriceOracle(address priceOracleAddress) external onlyOwner {
        priceOracle = ILedgityPriceOracle(priceOracleAddress);
        if (initialPrice == 0) {
            initialPrice = _getPrice();
        }
    }

    function totalBurn() external view returns (uint256) {
        return initialTotalSupply - totalSupply();
    }

    function setDex(address target, bool dex) public onlyOwner {
        if (dex) {
            _dexes.add(target);
            if (!isExcluded(target)) {
                excludeAccount(target);
            }
        } else {
            _dexes.remove(target);
            if (isExcluded(target)) {
                includeAccount(target);
            }
        }
    }

    function setFeeDestination(FeeDestination fd) public onlyOwner {
        feeDestination = fd;
    }

    function setIsExcludedFromDexFee(address account, bool isExcluded) public onlyOwner {
        if (isExcluded) {
            _excludedFromDexFee.add(account);
        } else {
            _excludedFromDexFee.remove(account);
        }
    }

    function setIsExcludedFromLimits(address account, bool isExcluded) public onlyOwner {
        if (isExcluded) {
            _excludedFromLimits.add(account);
        } else {
            _excludedFromLimits.remove(account);
        }
    }

    function setNumTokensToSwap(uint256 _numTokensToSwap) external onlyOwner {
        numTokensToSwap = _numTokensToSwap;
    }

    function setMaxTransactionSizePercent(uint128 numerator, uint128 denominator) external onlyOwner {
        maxTransactionSizePercent = Percent.encode(numerator, denominator);
    }

    function setSellAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellAccumulationFee = Percent.encode(numerator, denominator);
        require(sellAccumulationFee.lte(initialSellAccumulationFee), "Ledgity: fee too high");
    }

    function setSellAtSmallPriceAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellAtSmallPriceAccumulationFee = Percent.encode(numerator, denominator);
        require(sellAtSmallPriceAccumulationFee.lte(initialSellAtSmallPriceAccumulationFee), "Ledgity: fee too high");
    }

    function setSellReflectionFee(uint128 numerator, uint128 denominator) external onlyOwner {
        sellReflectionFee = Percent.encode(numerator, denominator);
        require(sellReflectionFee.lte(initialSellReflectionFee), "Ledgity: fee too high");
    }

    function setBuyAccumulationFee(uint128 numerator, uint128 denominator) external onlyOwner {
        buyAccumulationFee = Percent.encode(numerator, denominator);
        require(buyAccumulationFee.lte(initialBuyAccumulationFee), "Ledgity: fee too high");
    }

    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function getDexes() external view returns (address[] memory) {
        return _dexes.values;
    }

    function getExcludedFromDexFee() external view returns (address[] memory) {
        return _excludedFromDexFee.values;
    }

    function getExcludedFromLimits() external view returns (address[] memory) {
        return _excludedFromLimits.values;
    }

    function isDex(address account) public view returns (bool) {
        return _dexes.has(account);
    }

    function isExcludedFromDexFee(address account) public view returns (bool) {
        return _excludedFromDexFee.has(account);
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _excludedFromLimits.has(account);
    }

    function _calculateReflectionFee(address sender, address recipient, uint256 amount) internal override view returns (uint256) {
        if (isDex(recipient) && !isExcludedFromDexFee(sender)) {
            return sellReflectionFee.mul(amount);
        }
        return 0;
    }

    function _calculateAccumulationFee(address sender, address recipient, uint256 amount) internal override view returns (uint256) {
        if (isDex(sender) && !isExcludedFromDexFee(recipient)) {
            return buyAccumulationFee.mul(amount);
        }
        if (isDex(recipient) && !isExcludedFromDexFee(sender)) {
            if (_getPrice() >= initialPrice.mul(10)) {
                return sellAccumulationFee.mul(amount);
            } else {
                return sellAtSmallPriceAccumulationFee.mul(amount);
            }
        }
        return 0;
    }

    function _swapAndLiquifyOrCollect(uint256 contractTokenBalance) private lockTheSwap {
        _transfer(address(this), address(reserve), contractTokenBalance);
        if (feeDestination == FeeDestination.Liquify) {
            reserve.swapAndLiquify(contractTokenBalance);
        } else if (feeDestination == FeeDestination.Collect) {
            reserve.swapAndCollect(contractTokenBalance);
        } else {
            revert("Ledgity: invalid feeDestination");
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!isExcludedFromLimits(sender) && isDex(recipient)) {
            uint256 _sold;
            if (block.timestamp.sub(firstSellAt[sender]) > 10 minutes) {
                // _sold = 0;  // is already 0
                firstSellAt[sender] = block.timestamp;
            } else {
                _sold = soldPerPeriod[sender];
            }
            _sold = _sold.add(amount);
            require(_sold <= maxTransactionSize());
            soldPerPeriod[sender] = _sold;
        }

        if (address(priceOracle) != address(0)) {
            priceOracle.tryUpdate();
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 _numTokensToSwap = numTokensToSwap;
        if (
            contractTokenBalance >= _numTokensToSwap &&
            !inSwapAndLiquify &&
            sender != address(uniswapV2Pair)
        ) {
            if (contractTokenBalance > _numTokensToSwap) {
                contractTokenBalance = _numTokensToSwap;
            }
            _swapAndLiquifyOrCollect(contractTokenBalance);
        }

        super._transfer(sender, recipient, amount);
    }

    function _getPrice() private view returns (uint256) {
        if (address(priceOracle) == address(0)) {
            return 0;
        }
        return priceOracle.consult(address(this), 1e18);
    }

    function maxTransactionSize() public view returns (uint256) {
        return maxTransactionSizePercent.mul(totalSupply());
    }
}

pragma solidity ^0.6.12;

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "../interfaces/IERC20.sol";

abstract contract ReflectToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint8 private constant _decimals = 18;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 tTotal_) public {
        _name = name_;
        _symbol = symbol_;
        _tTotal = tTotal_;
        uint256 MAX = type(uint256).max;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
     * @dev Amount of tokens to be charged as a reflection fee. Must be in range 0..amount.
     */
    function _calculateReflectionFee(address sender, address recipient, uint256 amount) internal virtual view returns (uint256);

    /**
     * @dev Amount of tokens to be charged and stored in this contract. Must be in range 0..amount.
     */
    function _calculateAccumulationFee(address sender, address recipient, uint256 amount) internal virtual view returns (uint256);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ReflectToken: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ReflectToken: decreased allowance below zero"));
        return true;
    }

    function getExcluded() external view returns (address[] memory) {
        return _excluded;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "ReflectToken: excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(sender, address(0), tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "ReflectToken: amount must be less than supply");
        address sender = _msgSender();
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(sender, address(0), tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(sender, address(0), tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "ReflectToken: amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner() {
        require(!_isExcluded[account], "ReflectToken: account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) public onlyOwner() {
        require(_isExcluded[account], "ReflectToken: account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ReflectToken: approve from the zero address");
        require(spender != address(0), "ReflectToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint256 tAmount) internal {
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[from] = _rOwned[from].sub(rAmount, "ReflectToken: burn amount is more than the balance");
        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from].sub(tAmount, "ReflectToken: burn amount is more than the balance");
        }
		_rTotal = _rTotal.sub(rAmount);
		_tTotal = _tTotal.sub(tAmount);
        emit Transfer(_msgSender(), address(0), tAmount);
    }

    function _transfer(address sender, address recipient, uint256 tAmount) internal virtual {
        require(sender != address(0), "ReflectToken: transfer from the zero address");
        require(recipient != address(0), "ReflectToken: transfer to the zero address");
        require(tAmount > 0, "ReflectToken: transfer amount must be greater than zero");

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rAccumulation, uint256 tTransferAmount, uint256 tFee, uint256 tAccumulation) = _getValues(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        if (tFee != 0) {
            _reflectFee(rFee, tFee);
        }
        if (tAccumulation != 0) {
            _accumulateFee(rAccumulation, tAccumulation);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _accumulateFee(uint256 rAccumulation, uint256 tAccumulation) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(rAccumulation);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tAccumulation);
        }
    }

    function _getValues(address sender, address recipient, uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tAccumulation) = _getTValues(sender, recipient, tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rAccumulation) = _getRValues(tAmount, tFee, tAccumulation);
        return (rAmount, rTransferAmount, rFee, rAccumulation, tTransferAmount, tFee, tAccumulation);
    }

    function _getTValues(address sender, address recipient, uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = _calculateReflectionFee(sender, recipient, tAmount);
        uint256 tAccumulation = _calculateAccumulationFee(sender, recipient, tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tAccumulation);
        return (tTransferAmount, tFee, tAccumulation);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tAccumulation) private view returns (uint256, uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rAccumulation = tAccumulation.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rAccumulation);
        return (rAmount, rTransferAmount, rFee, rAccumulation);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 len = _excluded.length;
        for (uint256 i = 0; i < len; i++) {
            address account = _excluded[i];
            uint256 rBalance = _rOwned[account];
            uint256 tBalance = _tOwned[account];
            if (rBalance > rSupply || tBalance > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(rBalance);
            tSupply = tSupply.sub(tBalance);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}

pragma solidity ^0.6.12;

import "./SafeMath.sol";


library Percent {
    using SafeMath for uint256;

    struct Percent {
        uint128 numerator;
        uint128 denominator;
    }

    function encode(uint128 numerator, uint128 denominator) internal pure returns (Percent memory) {
        require(numerator <= denominator, "Percent: invalid percentage");
        return Percent(numerator, denominator);
    }

    function mul(Percent memory self, uint256 value) internal pure returns (uint256) {
        return value.mul(uint256(self.numerator)).div(uint256(self.denominator));
    }

    function lte(Percent memory self, Percent memory other) internal pure returns (bool) {
        return uint256(self.numerator).mul(other.denominator) <= uint256(other.numerator).mul(self.denominator);
    }
}

pragma solidity ^0.6.12;


library Set {
    /// @title Set data structure
    /// @dev Supports `add`, `remove` and `has` methods. Use `values` property to iterate over values. Do not edit properties directly.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) _valueIndexPlusOne;
    }

    /// @dev Adds a value to the set.
    /// @return `true` if the value was successfully added; `false` if the value was already in the set.
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (set._valueIndexPlusOne[value] != 0) {
            return false;
        }
		set.values.push(value);
		set._valueIndexPlusOne[value] = set.values.length;  // length == last_index + 1
        return true;
    }

    /// @dev Removes a value from the set.
    /// @return `true` if value was successfully removed; `false` if the value was not in the set.
    function remove(AddressSet storage set, address value) internal returns (bool) {
        if (set._valueIndexPlusOne[value] == 0) {
            return false;
        }
        uint256 valueToRemoveIndexPlusOne = set._valueIndexPlusOne[value];
        uint256 lastValueIndex = set.values.length - 1;

        // Swap indices
        set._valueIndexPlusOne[set.values[lastValueIndex]] = valueToRemoveIndexPlusOne;
        delete set._valueIndexPlusOne[value];

        // Move the last value to the deleted spot
        set.values[valueToRemoveIndexPlusOne - 1] = set.values[lastValueIndex];

        // Delete the duplicated last value
        set.values.pop();
        return true;
    }

    /// @dev Checks if a value is in the set.
    /// @return `true` if the value is in the set; `false` if the value is not in the set.
    function has(AddressSet storage set, address value) internal view returns (bool) {
        return set._valueIndexPlusOne[value] != 0;
    }
}

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.6.12;

import "./IUniswapV2Router01.sol";


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.6.12;

import "./IERC20.sol";


interface ILedgity is IERC20 {
    function burn(uint256 amount) external returns (bool);
}

pragma solidity ^0.6.12;

import "./IUniswapV2Pair.sol";


interface IReserve {
    function uniswapV2Pair() external returns (IUniswapV2Pair);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function swapAndCollect(uint256 tokenAmount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function swapAndLiquify(uint256 tokenAmount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function buyAndBurn(uint256 usdcAmount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event BuyAndBurn(uint256 tokenAmount, uint256 usdcAmount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event SwapAndCollect(uint256 tokenAmount, uint256 usdcAmount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event SwapAndLiquify(
        uint256 tokenSwapped,
        uint256 usdcReceived,
        uint256 tokensIntoLiqudity
    );
}

pragma solidity ^0.6.12;

interface ILedgityPriceOracle {
    /**
     * @dev Update average price.
     * @return `true` if update successful; `false` if period has not yet elapsed.
     */
    function tryUpdate() external returns (bool);

    /**
     * @dev Update average price. Reverts if period has not yet elapsed.
     */
    function update() external;

    /**
     * @dev Returns the price of tokens.
     */
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.12;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

pragma solidity ^0.6.12;

import "./Context.sol";


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

