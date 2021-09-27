/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
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

contract LevelUp is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isIncludedInFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000_000 * 10 ** 9;                  // Total Supply 1 Trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tReflectionTotal;

    string private _name = "LevelUp Token";
    string private _symbol = "LEVELUP";
    uint8 private _decimals = 9;

    uint256 public _redistributionFee = 80;                 // 8% ethereum distribution
    uint256 private _previousRedistributionFee = _redistributionFee;    

    uint256 public _walletFee = 40;                         // 4% ethereum distribution                   
    uint256 private _previousWalletFee = _walletFee;

    uint256 public _maxTxAmount = 1 * 10**15 * 10**9;
    uint256 public _maxTrade = 5;   // 0.5 %
    
    uint256 private minimumTokensBeforeSwap = 1 * 10**11 * 10**9;

    address payable public walletAddress;                               // Set wallet address after deployment 0xbB8202f0F4f7aa09fE67Fc8f7613217Ba0acd5eb wallet
    
    IUniswapV2Router02 public router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event Burn(address ctrlBurnWallet, uint256 tokenAmount, uint256 timestamp);
    event UpdateOperationWallet(address previousAddress, address newAddress, string operation);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
    * @dev Deploy the contract, message sender will get the initial total supply minted.
    * Create initial Uniswap V2 pair and router. Can be updated in setRouterAddress()
    *
    * The pair should always be excluded from reward and included in fees.
    *
    */
    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // Start ERC-20 standard functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    // End ERC-20 standart functions

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0){
            emit Transfer(from, to, 0);
            return;
        }
        
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
        // Control Buy/Sell Transaction 
        if(from == address(router) || to == address(router))
            require(amount <= balanceOf(_msgSender()).mul(_maxTrade).div(10**2), "Trade amount exceeds set limit.");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        if (
            overMinimumTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(minimumTokensBeforeSwap);
        }

        bool takeFee = false;

        if(_isIncludedInFee[from] || _isIncludedInFee[to]) {
            takeFee = true;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    /**
    * @dev Handles all autoswap to ETH, adding to LP and distributing ETH shares to the set addresses.
    *
    * @param tokensToSwap the amount that will be swapped, will always be minimumTokensBeforeSwap
    *
    * NOTE: will never be called if swapAndLiquify = false!.
    */
    function swapAndLiquify(uint256 tokensToSwap) private lockTheSwap {
        //uint256 liquidityTokenAmount = tokensToSwap.div(_convertToETHFee).mul(_lpFee);
        reAddLiquidity(tokensToSwap);
        //uint256 ETHDistributionAmount = tokensToSwap.sub(liquidityTokenAmount);
        swapTokensForEth(tokensToSwap);
        
        distributeETHFee(address(this).balance);
    }


    /**
    * @dev Handles distribution of ETH to charity, marketing and equalizer
    *
    * @param amountETH the amount of ETH that will be distributed
    *
    * NOTE: will never be called if swapAndLiquify = false!.
    */
    function distributeETHFee(uint256 amountETH) private {
        uint256 _marketing = amountETH.div(12).mul(_walletFee);
        
        walletAddress.transfer(_marketing);
    }

    /**
    * @dev Handles swaping tokens stored on the contract, half of the {amount} for ETH and adding it with the other hald of tokens to LP
    *
    * @param amount of tokens to swap and add to liquidity
    *
    * NOTE: will never be called if swapAndLiquify = false!.
    */
    function reAddLiquidity (uint256 amount) private {
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
    * @dev Handles selling of {tokenAmount}
    *
    * @param tokenAmount the amount of tokens to swap for ETH
    *
    */
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }


    /**
    * @dev Handles add {tokenAmount} and {ETHAmount} to LP
    *
    * @param tokenAmount, ETHAmount amount of tokens and ETH to be added to LP
    *
    * NOTE: LP tokens will be sent to the owner address.
    *
    */
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }


    /**
    * @dev wrapper for token transfer, will enable the fees on {takefee} = true
    *
    * @param takeFee flag for taking fee - initially no fee on any transfer except when includedInFee
    *
    */
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }


    /**
    * @dev internal function to handle the token transfer, burn, redistribution and ETHtotal-fees
    *
    * NOTE: Rewards will be distributed differently on sending/receiving from/to excludedFromRewards addresses
    */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tRedistributionFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tRedistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
    * @dev internal function to handle the token transfer, burn, redistribution and ETHtotal-fees
    *
    * NOTE: Rewards will be distributed differently on sending/receiving from/to excludedFromRewards addresses
    */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tRedistributionFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tRedistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
    * @dev internal function to handle the token transfer, burn, redistribution and ETHtotal-fees
    *
    * NOTE: Rewards will be distributed differently on sending/receiving from/to excludedFromRewards addresses
    */
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tRedistributionFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tRedistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
    * @dev internal function to handle the token transfer, burn, redistribution and ETHtotal-fees
    *
    * NOTE: Rewards will be distributed differently on sending/receiving from/to excludedFromRewards addresses
    */
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tRedistributionFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tRedistributionFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
    * @dev internal function will hanlde the changing total values for rewards and burn. {_tReflectionTotal} & {_tBurnTotal} are public counters to call the total amounts.
    */
    function _reflectFee(uint256 rFee, uint256 tRedistributionFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tReflectionTotal = _tReflectionTotal.add(tRedistributionFee);
    }

    /**
    * @dev internal function to get the current transfer and reward values to {tAmount}
    */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tRedistributionFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tRedistributionFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tRedistributionFee);
    }

    /**
    * @dev internal function to get the current transfer values to {tAmount}
    */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tRedistributionFee = _takeFeeFromAmount(tAmount, _redistributionFee);
        uint256 tTransferAmount = tAmount.sub(tRedistributionFee);
        
        return (tTransferAmount, tRedistributionFee);
    }

    /**
    * @dev internal function to get the current reward values to {tAmount} and all transfer fees
    */
    function _getRValues(uint256 tAmount, uint256 tRedistributionFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tRedistributionFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
    * @dev internal function to get the current rate between tTotal and rTotal
    */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
    * @dev internal function to retrieve the current supply regarding rewards.
    *
    * @return rSupply - current reflection total
    * @return tSupply - current transfer total
    */
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
    * @dev internal function to stack tokens on the contract itself
    *
    * @param _tConvertToETH the amount of tokens to stack on the contract for later conversion to ETH
    *
    */
    function _stackTokensToContract(uint256 _tConvertToETH) private {
        uint256 currentRate =  _getRate();
        uint256 rConvertToETH = _tConvertToETH.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rConvertToETH);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(_tConvertToETH);
    }

    /**
    * @dev internal function takes {fee} as in % from {_amount}
    *
    * @param _amount to take the fee from
    * @param fee as in % to take from {_amount}
    *
    * @return the delta from taking {fee}% from {_amount}
    */
    function _takeFeeFromAmount(uint256 _amount, uint256 fee) private pure returns (uint256) {
        return _amount.mul(fee).div(
            10**2
        );
    }

    /**
    * @dev internal function that will set all fees to 0
    *
    * NOTE: this will only ever happen for a single transfer, restoreAllFee() will be called after the transfer
    *
    */
    function removeAllFee() private {
        if(_redistributionFee == 0 ) return;

        _redistributionFee = 0;
        
        // _burnFee = 0;
        //_convertToETHFee = 0;
    }

    /**
    * @dev internal function that will restore all fees to their last value
    *
    */
    function restoreAllFee() private {
        _redistributionFee = _previousRedistributionFee;
       // _burnFee = _previousBurnFee;
       // _convertToETHFee = _previousETHFee;
    }

    /**
    * @dev external function allows the owner to exclude addresses from rewards like any trading pair.
    * This function should only be called to addresses that do not hold any tokens.
    *
    * @param account the address to be excluded
    *
    * Requirements:
    * - `account` cannot be excluded already.
    *
    */
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
    * @dev external function allows the owner to include a previously excluded address.
    * This function should only be called to addresses that do not hold any tokens.
    *
    * @param account the address to be included
    *
    * Requirements:
    * - `account` needs to be excluded.
    *
    */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                uint256 currentRate = _getRate();
                _rOwned[account] = _tOwned[account].mul(currentRate);
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    /**
    * @dev public function to read if {account} is excludedFromReward
    *
    */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
    * @dev public function to read if {account} is includedInFee
    *
    */
    function isIncludedInFee(address account) external view returns(bool) {
        return _isIncludedInFee[account];
    }

    /**
    * @dev owner only function to add {account} to addresses that need to pay fee
    *
    */
    function includeInFee(address account) external onlyOwner {
        _isIncludedInFee[account] = true;
    }

    /**
    * @dev owner only function to remove {account} from addresses that need to pay fee
    *
    */
    function excludeFromFee(address account) external onlyOwner {
        _isIncludedInFee[account] = false;
    }

    /**
    * @dev owner only function to set the marketing address
    *
    * Emits an {UpdateOperationWallet} event.
    *
    */
    function setMarketingAddress(address payable _walletAddress) external onlyOwner {
        address prevWarketing = walletAddress;
        walletAddress = _walletAddress;
        emit UpdateOperationWallet(prevWarketing, walletAddress, "wallet");
    }

    /**
    * @dev owner only function to set the redistribution fee
    *
    * @param redistributionFee the fee in %
    *
    * Requirements:
    *
    * - The sum of all fees cannot be higher than 25%
    *
    */
    function setRedistributionFee(uint256 redistributionFee) external onlyOwner() {
        _redistributionFee = redistributionFee;
    }

    /**
    * @dev owner only function to set the wallet fee
    *
    * @param walletFee the fee in %
    *
    * Requirements:
    *
    * - The sum of all fees cannot be higher than 25%
    *
    */
    function setWalletFee(uint256 walletFee) external onlyOwner() {
        _walletFee = walletFee;
    }

    /**
    * @dev public function to read the limiter on when the contract will auto convert to ETH
    *
    */
    function getTokenAutoSwapLimit() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    /**
    * @dev owner only function to set the maximum transfer amount
    *
    * @param maxTxPercent the amount of % of total supply
    *
    * Requirements:
    *
    * - `maxTxPercent` must be more than 0
    *
    */
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Cannot set maximum transfer amount to 0!");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
    
    /**
    * @dev owner only function to set the maximum buy sell
    *
    * @param maxTrade the amount of % of total supply
    *
    * Requirements:
    *
    * - `maxTrade` must be more than 0
    *
    */
    function setTrade(uint256 maxTrade) external onlyOwner() {
        require(maxTrade > 0, "Cannot set maximum transfer amount to 0!");
        _maxTrade = maxTrade;
    }

    /**
    * @dev owner only function to set the limit of tokens to sell for ETH when reached
    *
    * @param _minimumTokensBeforeSwap the amount tokens when to sell from the contract
    *
    */
    function setTokenAutoSwapLimit(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    /**
    * @dev owner only function to control if the autoswap to ETH should happen
    *
    * Emits an {SwapAndLiquifyEnabledUpdated} event.
    *
    */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
    * @dev owner only function to set a new router address and create a new pair.
    *
    */
    function setRouterAddress(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router02 = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory()).createPair(address(this), _uniswapV2Router02.WETH());
        router = _uniswapV2Router02;
    }

    /**
    * @dev public function to read the total amount of reflection reward tokens
    *
    */
    function totalReflectionFees() external view returns (uint256) {
        return _tReflectionTotal;
    }

    receive() external payable {}
}