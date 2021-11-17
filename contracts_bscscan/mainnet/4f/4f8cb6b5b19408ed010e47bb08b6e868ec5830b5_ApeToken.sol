/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ApeToken is IERC20, Ownable {
    using Address for address;

    string      public name         = "Ape Token";      // Token name
    string      public symbol       = "APE";            // Token symbol
    uint8       public decimals     = 18;               // Token decimals
    uint256     public taxFee       = 40;               // The reflection tax rate
    uint256     public liquidityFee = 50;               // The liquidity tax rate
    uint256     public marketingTax = 10;               // The marketing tax rate
    bool        public transferTaxEnabled = true;       // Flag for if the transfer tax is enabled
    bool        public inSwap;                          // Flag for preventing swap loops
    address     public treasury;                        // The treasury for sending marketing tax to
    address     public lpstore;                         // The LP storage wallet
    address     public dexPair;                         // The address of the dex pair

    uint256     public pendingLiquidity;                // Amount pending to be sent for liquidity
    uint256     public pendingMarketing;                // Amount pending to be sent for marketing

    address[]   private excluded;                       // Array of addresses excluded from rewards

    uint256 public maxTxAmount = 90000000 * 10 ** uint256(decimals);// The maximum transfer amount
    uint256 private constant MAX = ~uint256(0);         // uint256 maximum
    uint256 private tTotal = 90000000 * 10 ** uint256(decimals); // Total supply of the token
    uint256 private rTotal = (MAX - (MAX % tTotal));    // Total reflections
    uint256 private tFeeTotal;                          // The total fees

    IERC20              public pairToken;               // The LP paired token
    IUniswapV2Router02  public dexRouter;               // The DEX router for performing swaps

    // Variables to store tax rates while doing notax operations
    uint256 private previousTaxFee = taxFee;
    uint256 private previousLiquidityFee = liquidityFee;
    uint256 private previousMarketingTax = marketingTax;

    // Balance mappings
    mapping (address => uint256) private rOwned;
    mapping (address => uint256) private tOwned;
    mapping (address => mapping (address => uint256)) private allowances;

    // Exclusion mappings
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isExcluded;

    // Events for sending stuff
    event MinTokensBeforeSwapUpdated(uint256 _minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool _enabled);
    event SwapAndLiquify(uint256 _tokensSwapped, uint256 _ethReceived, uint256 _tokensIntoLiqudity);
    event Debug(string _data1, uint256 _data2);

    // Constructor for constructing things
    constructor (address _dexRouter, address _pairToken, address _treasury, address _lpstore) {
        pairToken = IERC20(_pairToken);
        treasury = _treasury;
        lpstore = _lpstore;

        rOwned[msg.sender] = rTotal;

        dexRouter = IUniswapV2Router02(_dexRouter);
        dexPair = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), _pairToken);

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasury] = true;
        isExcludedFromFee[lpstore] = true;

        emit Transfer(address(0), msg.sender, tTotal);
    }

    receive() external payable {}

    // Function to set the DEX router
    function setDex(address _dexRouter, address _dexPair) public onlyOwner() {
        dexRouter = IUniswapV2Router02(_dexRouter);
        dexPair = _dexPair;
    }

    // Function to set the paired token
    function setPairedToken(address _pairedToken) public onlyOwner() {
        pairToken = IERC20(_pairedToken);
    }

    // Function to set the LP Maker
    function setLPStore(address _lpstore) public onlyOwner() {
        lpstore = _lpstore;
    }

    // Function to set the treasury address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = _treasury;
    }

    // Function to set if the transfer tax is enabled
    function setTransferTaxEnabled(bool _enabled) public onlyOwner() {
        transferTaxEnabled = _enabled;
    }

    // Function to exclude an address from fee
    function excludeFromFee(address _account) public onlyOwner() {
        isExcludedFromFee[_account] = true;
    }

    // Function to include an address for the fee
    function includeInFee(address _account) public onlyOwner() {
        isExcludedFromFee[_account] = false;
    }

    // Function to set the tax percent
    function setTaxFeePercent(uint256 _taxFee) public onlyOwner() {
        taxFee = _taxFee;
    }

    // Function to set the liquidity percentage
    function setLiquidityFeePercent(uint256 _liquidityFee) public onlyOwner() {
        liquidityFee = _liquidityFee;
    }

    // Function to set the marketing tax percentage
    function setMarketingTax(uint256 _marketingTax) public onlyOwner() {
        marketingTax = _marketingTax;
    }

    // Function to set the max transfer size
    function setMaxTxPercent(uint256 _maxTxPercent) public onlyOwner() {
        maxTxAmount = tTotal * _maxTxPercent / (10**2);
    }

    // Function to exclude an address from getting rewards
    function excludeFromReward(address _account) public onlyOwner() {
        require(!isExcluded[_account], "Account is already excluded");
        if(rOwned[_account] > 0) {
            tOwned[_account] = tokenFromReflection(rOwned[_account]);
        }
        isExcluded[_account] = true;
        excluded.push(_account);
    }

    // Function to include an address in getting rewards
    function includeInReward(address _account) public onlyOwner() {
        require(isExcluded[_account], "Account is not excluded");
        for (uint256 i = 0; i < excluded.length; i++) {
            if (excluded[i] == _account) {
                excluded[i] = excluded[excluded.length - 1];
                tOwned[_account] = 0;
                isExcluded[_account] = false;
                excluded.pop();
                break;
            }
        }
    }

    // Function to get the total supply
    function totalSupply() public view override returns (uint256) { return tTotal; }

    // Function to get the balance of an account
    function balanceOf(address _account) public view override returns (uint256) {
        if (isExcluded[_account]) return tOwned[_account];
        return tokenFromReflection(rOwned[_account]);
    }

    // Function for initiating a transfer
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    // Function for getting the allowance of a spender
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    // Function for initiating an approval
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    // Function for initiating a transfer from
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender] - _amount);
        return true;
    }

    // Function to increase the allowance for a spender
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    // Function to decrease the allowance for a spender
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender]- _subtractedValue);
        return true;
    }

    // Function to check if an address is excluded from rewards
    function isExcludedFromReward(address _account) public view returns (bool) {
        return isExcluded[_account];
    }

    // Function to get the total fees
    function totalFees() public view returns (uint256) {
        return tFeeTotal;
    }

    // Deliver function
    function deliver(uint256 _tAmount) public {
        address sender = msg.sender;
        require(!isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(_tAmount);
        rOwned[sender] = rOwned[sender] - rAmount;
        rTotal = rTotal - rAmount;
        tFeeTotal = tFeeTotal + _tAmount;
    }

    // Function to get the reflections for an amount
    function reflectionFromToken(uint256 _tAmount, bool _deductTransferFee) public view returns(uint256) {
        require(_tAmount <= tTotal, "Amount must be less than supply");
        if (!_deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(_tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(_tAmount);
            return rTransferAmount;
        }
    }

    // Function to get the tokens from reflections
    function tokenFromReflection(uint256 _rAmount) public view returns(uint256) {
        require(_rAmount <= rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return _rAmount / currentRate;
    }

    // Function to get the reflection fee
    function _reflectFee(uint256 _rFee, uint256 _tFee) private {
        rTotal = rTotal - _rFee;
        tFeeTotal = tFeeTotal + _tFee;
    }

    // Function to calculate the values
    function _getValues(uint256 _tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing) = _getTValues(_tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(_tAmount, tFee, tLiquidity, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    // Function to calculate the 't' values
    function _getTValues(uint256 _tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = _calculateTaxFee(_tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(_tAmount);
        uint256 tMarketing = _calculateMarketingTax(_tAmount);
        uint256 tTransferAmount = _tAmount - tFee - tLiquidity - tMarketing;
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    // Function to calculate the 'r' values
    function _getRValues(uint256 _tAmount, uint256 _tFee, uint256 _tLiquidity, uint256 _tMarketing, uint256 _currentRate)
            private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _tAmount * _currentRate;
        uint256 rFee = _tFee * _currentRate;
        uint256 rLiquidity = _tLiquidity * _currentRate;
        uint256 rMarketing = _tMarketing * _currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rMarketing;
        return (rAmount, rTransferAmount, rFee);
    }

    // Function to get the current rate
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    // Function to get the current supply
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        for (uint256 i = 0; i < excluded.length; i++) {
            if (rOwned[excluded[i]] > rSupply || tOwned[excluded[i]] > tSupply) return (rTotal, tTotal);
            rSupply = rSupply - rOwned[excluded[i]];
            tSupply = tSupply - tOwned[excluded[i]];
        }
        if (rSupply < rTotal / tTotal) return (rTotal, tTotal);
        return (rSupply, tSupply);
    }

    // Function to take liquidity
    function _takeLiquidity(uint256 _tLiquidity) private {
        uint256 startBalance = balanceOf(address(this));
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = _tLiquidity * currentRate;

        uint256 rHalf = rLiquidity / 2;
        uint256 rRemain = rLiquidity - rHalf;

        rOwned[address(this)] = rOwned[address(this)] + rHalf;
        rOwned[lpstore] = rOwned[lpstore] + rRemain;

        if(isExcluded[address(this)] && isExcluded[lpstore]) {
            uint256 tHalf = _tLiquidity / 2;
            uint256 tRemain = _tLiquidity - tHalf;
            tOwned[address(this)] = tOwned[address(this)] + tHalf;
            tOwned[lpstore] = tOwned[lpstore] + tRemain;
        }

        uint256 newTokens = balanceOf(address(this)) - startBalance;

        if (newTokens > 0) {
            pendingLiquidity += newTokens;
        }
    }

    // Function to tax marketing tax
    function _takeMarketing(uint256 _tMarketing) private {
        uint256 startBalance = balanceOf(address(this));
        uint256 currentRate =  _getRate();
        uint256 rMarketing = _tMarketing * currentRate;
        rOwned[address(this)] = rOwned[address(this)] + rMarketing;
        if (isExcluded[address(this)]) {
            tOwned[address(this)] = tOwned[address(this)] + _tMarketing;
        }

        uint256 newTokens = balanceOf(address(this)) - startBalance;

        if (newTokens > 0) {
            pendingMarketing += newTokens;
        }
    }

    // Function to handle swapping tokens for CAKE
    function _swapTokensForPaired(uint256 _tokenAmount, address _target) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(pairToken);

        _approve(address(this), address(dexRouter), _tokenAmount);

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _target,
            block.timestamp
        );
    }

    // Function to calculate the tax fee
    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * taxFee / (10 ** 3);
    }

    // Function to calculate the liquidity fee
    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * liquidityFee / (10 ** 3);
    }

    // Function to calculate the marketing tax
    function _calculateMarketingTax(uint256 _amount) private view returns (uint256) {
        return _amount * marketingTax / (10 ** 3);
    }

    // Function to set all tax rates to zero
    function _removeAllFee() private {
        if(taxFee == 0 && liquidityFee == 0 && marketingTax == 0) return;

        previousTaxFee = taxFee;
        previousLiquidityFee = liquidityFee;
        previousMarketingTax = marketingTax;

        taxFee = 0;
        liquidityFee = 0;
        marketingTax = 0;
    }

    // Function to restore the tax rates
    function _restoreAllFee() private {
        taxFee = previousTaxFee;
        liquidityFee = previousLiquidityFee;
        marketingTax = previousMarketingTax;
    }

    // Function to handle approvals
    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // Function to handle transfers
    function _transfer(address _from, address _to, uint256 _amount) private {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        if(_from != owner() && _to != owner()) {
            require(_amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (balanceOf(address(this)) > 0 && !inSwap && _from != dexPair) {
            inSwap = true;

            if (pendingMarketing > 0) {
                _swapTokensForPaired(pendingMarketing, treasury);
                pendingMarketing = 0;
            }

            pendingLiquidity = balanceOf(address(this));

            if (pendingLiquidity > 0) {
                _swapTokensForPaired(pendingLiquidity, lpstore);
                pendingLiquidity = 0;
            }

            inSwap = false;
        }

        bool takeFee = true;

        if(!transferTaxEnabled || isExcludedFromFee[_from] || isExcludedFromFee[_to]){
            takeFee = false;
        }

        _tokenTransfer(_from, _to, _amount, takeFee);
    }

    // Function to handle transfers based on fees
    function _tokenTransfer(address _sender, address _recipient, uint256 _amount, bool _takeFee) private {
        if(!_takeFee)
            _removeAllFee();

        if (isExcluded[_sender] && !isExcluded[_recipient]) {
            _transferFromExcluded(_sender, _recipient, _amount);
        } else if (!isExcluded[_sender] && isExcluded[_recipient]) {
            _transferToExcluded(_sender, _recipient, _amount);
        } else if (!isExcluded[_sender] && !isExcluded[_recipient]) {
            _transferStandard(_sender, _recipient, _amount);
        } else if (isExcluded[_sender] && isExcluded[_recipient]) {
            _transferBothExcluded(_sender, _recipient, _amount);
        } else {
            _transferStandard(_sender, _recipient, _amount);
        }

        if(!_takeFee)
            _restoreAllFee();
    }

    // Function for handling standard transfers
    function _transferStandard(address _sender, address _recipient, uint256 _tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,
            uint256 tLiquidity, uint256 tMarketing) = _getValues(_tAmount);

        rOwned[_sender] = rOwned[_sender] - rAmount;
        rOwned[_recipient] = rOwned[_recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeMarketing(tMarketing);
        emit Transfer(_sender, _recipient, tTransferAmount);
    }

    // Function for handling transferring to an excluded address
    function _transferToExcluded(address _sender, address _recipient, uint256 _tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,
            uint256 tLiquidity, uint256 tMarketing) = _getValues(_tAmount);
        rOwned[_sender] = rOwned[_sender] - rAmount;
        tOwned[_recipient] = tOwned[_recipient] + tTransferAmount;
        rOwned[_recipient] = rOwned[_recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeMarketing(tMarketing);
        emit Transfer(_sender, _recipient, tTransferAmount);
    }

    // Function for handling transferring from and excluded address
    function _transferFromExcluded(address _sender, address _recipient, uint256 _tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,
            uint256 tLiquidity, uint256 tMarketing) = _getValues(_tAmount);
        tOwned[_sender] = tOwned[_sender] - _tAmount;
        rOwned[_sender] = rOwned[_sender] - rAmount;
        rOwned[_recipient] = rOwned[_recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeMarketing(tMarketing);
        emit Transfer(_sender, _recipient, tTransferAmount);
    }

    // Function for performing a transfer when both parties are excluded
    function _transferBothExcluded(address _sender, address _recipient, uint256 _tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee,
            uint256 tLiquidity, uint256 tMarketing) = _getValues(_tAmount);
        tOwned[_sender] = tOwned[_sender] - _tAmount;
        rOwned[_sender] = rOwned[_sender] - rAmount;
        tOwned[_recipient] = tOwned[_recipient] + tTransferAmount;
        rOwned[_recipient] = rOwned[_recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _takeMarketing(tMarketing);
        emit Transfer(_sender, _recipient, tTransferAmount);
    }
}