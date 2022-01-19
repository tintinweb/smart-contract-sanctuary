/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/*

PayBolt - The future of crypto payments

Pay expenses, earn $PAY rewards with your crypto tokens in near-instant time. Start spending your tokens at cafe, restaurant and everywhere.

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function customSubOrZero(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = 0; 

        if (b <= a) {
            c = a - b;
        }

        return c;
    }
}

library Address {

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
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
    function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable public teamAddress = payable(0x65DB2b9C8B2a21957c4806fDda4043BFF7C466f4); // Team Address
    address payable public treasuryAddress = payable(0xdc7dc71F7DDDB1d5b4CCdb0682E096793B323012); // Treasury Address
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) internal isBlacklisted;
    mapping (address => bool) internal isWhitelistedMerchant;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isOriginExcludedFromFee;
    mapping (address => bool) private _isDestinationExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;
   
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 10**9 * 10**_decimals;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;

    // payment fee in percentage, 100% = 10000; 1% = 100; 0.1% = 10
    uint256 public paymentFee = 0; 

    // rewards to holder in percentage, 100% = 10000; 1% = 100; 0.1% = 10
    uint256 public taxFee = 300; 
    uint256 private _previousTaxFee = taxFee;

    // in percentage, 100% = 10000; 1% = 100; 0.1% = 10
    uint256 public taxTeamPercent = 400;
    uint256 public taxTreasuryPercent = 100;
    uint256 public taxLPPercent = 200;
    uint256 public liquidityFee = 700;   // Team + Treasury + LP
    uint256 private _previousLiquidityFee = liquidityFee;
    
    uint256 public maxTxAmount = 100 * 10**6 * 10**_decimals;
    uint256 public minimumTokensBeforeSwap = 2 * 10**6 * 10**_decimals; 

    uint256 public holders = 0;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event RouterAddressUpdated(address prevAddress, address newAddress);
    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ApplyTax(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event AddLiquidity(uint256 tokenAmount, uint256 ethAmount);
    event ExcludeFromReward(address account);
    event IncludeInReward(address account);
    event ExcludeFromFee(address account);
    event IncludeInFee(address account);
    event ExcludeOriginFromFee(address account);
    event IncludeOriginInFee(address account);
    event ExcludeDestinationFromFee(address account);
    event IncludeDestinationInFee(address account);
    event BlackList(address account);
    event RemoveFromBlacklist(address account);
    event WhitelistMerchant(address account);
    event RemoveFromWhitelistMerchant(address account);
    event SetTaxFeePercent(uint256 taxFee);
    event SetPaymentFeePercent(uint256 percent);
    event SetMaxTxAmount(uint256 maxTxAmount);
    event SetLiquidityFeePercent(uint256 _iquidityFee);
    event SetTaxTeamPercent(uint256 percent);
    event SetTaxTreasuryPercent(uint256 percent);
    event SetTaxLPPercent(uint256 percent);
    event SetNumTokensSellToAddToLiquidity(uint256 minimumTokensBeforeSwap);
    event SetTeamAddress(address teamAddress);
    event SetTreasuryAddress(address treasuryAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory name_, string memory symbol_, address routerAddress_) {
        _name = name_;
        _symbol = symbol_;
        
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress_);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[teamAddress] = true;
        _isExcludedFromFee[treasuryAddress] = true;

        holders = 1;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

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
        if (_isExcludedFromReward[account]) return _tOwned[account];
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
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
        require(!isBlacklisted[from], "Address is backlisted");
        require(!isBlacklisted[to], "Address is backlisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (!inSwapAndLiquify && swapAndLiquifyEnabled && to == uniswapV2Pair) {
            if (overMinimumTokenBalance) {
                applyTax(minimumTokensBeforeSwap); 
            }
        }

        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        //if origin account belongs to _isOriginExcludedFromFee account then remove the fee
        //if destination account belongs to _isDestinationExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || _isOriginExcludedFromFee[from] || _isDestinationExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    function applyTax(uint256 contractTokenBalance) private lockTheSwap {
        // ethPortion = team + treasury + LP/2
        uint256 halfLP = taxLPPercent / 2;
        uint256 totalEthPortion = taxTeamPercent + taxTreasuryPercent + halfLP;
        uint256 toSwapIntoEth = contractTokenBalance / liquidityFee * totalEthPortion;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(address(this), address(this), toSwapIntoEth);
        uint256 transferredBalance = address(this).balance - initialBalance;

        uint256 teamPortion = transferredBalance / totalEthPortion * taxTeamPercent;
        uint256 treasuryPortion = transferredBalance / totalEthPortion * taxTreasuryPercent;

        // Send to Team address
        transferToAddressETH(teamAddress, teamPortion);

        // Send to Treasury address
        transferToAddressETH(treasuryAddress, treasuryPortion);

        // add liquidity to uniswap
        uint256 leftOverToken = contractTokenBalance - toSwapIntoEth;
        uint256 leftOverEth = transferredBalance - teamPortion - treasuryPortion;
        addLiquidity(leftOverToken, leftOverEth);
        
        emit ApplyTax(toSwapIntoEth, transferredBalance, leftOverToken);
    }

    function swapTokensForEth(
        address tokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();

        IERC20(tokenAddress).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            toAddress, // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        emit AddLiquidity(tokenAmount, ethAmount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        uint256 senderBefore = _rOwned[sender];
        uint256 senderAfter = _rOwned[sender].customSubOrZero(rAmount);
        _rOwned[sender] = senderAfter;

        uint256 recipientBefore = _rOwned[recipient];
        uint256 recipientAfter = _rOwned[recipient] + rTransferAmount;
        _rOwned[recipient] = recipientAfter;

        _updateHolderCount(senderBefore, senderAfter, recipientBefore, recipientAfter);

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 senderBefore = _rOwned[sender];
        uint256 senderAfter = _rOwned[sender].customSubOrZero(rAmount);
        _rOwned[sender] = senderAfter;

        uint256 recipientBefore = _tOwned[recipient];
        uint256 recipientAfter = _tOwned[recipient] + tTransferAmount;
        _tOwned[recipient] = recipientAfter;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 
        
        _updateHolderCount(senderBefore, senderAfter, recipientBefore, recipientAfter);
     
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 senderBefore = _tOwned[sender];
        uint256 senderAfter = _tOwned[sender].customSubOrZero(tAmount);
        _tOwned[sender] = senderAfter;
        _rOwned[sender] = _rOwned[sender].customSubOrZero(rAmount);

        uint256 recipientBefore = _rOwned[recipient];
        uint256 recipientAfter = _rOwned[recipient] + rTransferAmount;
        _rOwned[recipient] = recipientAfter;

        _updateHolderCount(senderBefore, senderAfter, recipientBefore, recipientAfter);

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        
        uint256 senderBefore = _tOwned[sender];
        uint256 senderAfter = _tOwned[sender].customSubOrZero(tAmount);
        _tOwned[sender] = senderAfter;
        _rOwned[sender] = _rOwned[sender].customSubOrZero(rAmount);

        uint256 recipientBefore = _tOwned[recipient];
        uint256 recipientAfter = _tOwned[recipient] + tTransferAmount;
        _tOwned[recipient] = recipientAfter;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 

        _updateHolderCount(senderBefore, senderAfter, recipientBefore, recipientAfter);
     
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excludedFromReward[i]];
            tSupply = tSupply - _tOwned[_excludedFromReward[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }
    
    function _updateHolderCount(uint256 senderBefore, uint256 senderAfter, uint256 recipientBefore, uint256 recipientAfter) private {
        if (recipientBefore == 0 && recipientAfter > 0) {
            holders = holders + 1;
        }

        if (senderBefore > 0 && senderAfter == 0) {
            holders = holders.customSubOrZero(1);
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * taxFee / 10000;
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * liquidityFee / 10000;
    }

    function removeAllFee() private {
        if(taxFee == 0 && liquidityFee == 0) return;
        
        _previousTaxFee = taxFee;
        _previousLiquidityFee = liquidityFee;
        
        taxFee = 0;
        liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);

        emit ExcludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
        emit IncludeInReward(account);
    }

    function setRouterAddress(address routerAddress) external onlyOwner {
        require(
            routerAddress != address(0),
            "routerAddress should not be the zero address"
        );

        address prevAddress = address(uniswapV2Router);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress); 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        emit RouterAddressUpdated(prevAddress, routerAddress);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        require(!_isExcludedFromFee[account], "Account is already excluded");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }
    
    function includeInFee(address account) public onlyOwner {
        require(_isExcludedFromFee[account], "Account is already included");
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }
    
    function isOriginExcludedFromFee(address account) public view returns(bool) {
        return _isOriginExcludedFromFee[account];
    }
    
    function excludeOriginFromFee(address account) public onlyOwner {
        require(!_isOriginExcludedFromFee[account], "Account is already excluded");
        _isOriginExcludedFromFee[account] = true;
        emit ExcludeOriginFromFee(account);
    }
    
    function includeOriginInFee(address account) public onlyOwner {
        require(_isOriginExcludedFromFee[account], "Account is already included");
        _isOriginExcludedFromFee[account] = false;
        emit IncludeOriginInFee(account);
    }
    
    function isDestinationExcludedFromFee(address account) public view returns(bool) {
        return _isDestinationExcludedFromFee[account];
    }
    
    function excludeDestinationFromFee(address account) public onlyOwner {
        require(!_isDestinationExcludedFromFee[account], "Account is already excluded");
        _isDestinationExcludedFromFee[account] = true;
        emit ExcludeDestinationFromFee(account);
    }
    
    function includeDestinationInFee(address account) public onlyOwner {
        require(_isDestinationExcludedFromFee[account], "Account is already included");
        _isDestinationExcludedFromFee[account] = false;
        emit IncludeDestinationInFee(account);
    }

    function isAddressBlacklisted(address account) public view returns(bool) {
        return isBlacklisted[account];
    }
    
    function blackList(address account) public onlyOwner {
        require(!isBlacklisted[account], "User already blacklisted");
        isBlacklisted[account] = true;
        emit BlackList(account);
    }
    
    function removeFromBlacklist(address account) public onlyOwner {
        require(isBlacklisted[account], "User is not blacklisted");
        isBlacklisted[account] = false;
        emit RemoveFromBlacklist(account);
    }
    
    function isAddressWhitelistedMerchant(address account) public view returns(bool) {
        return isWhitelistedMerchant[account];
    }
    
    function whitelistMerchant(address account) public onlyOwner {
        require(!isWhitelistedMerchant[account], "Account is already whitelisted");
        isWhitelistedMerchant[account] = true;
        emit WhitelistMerchant(account);
    }
    
    function removeFromWhitelistMerchant(address account) public onlyOwner {
        require(isWhitelistedMerchant[account], "Account is not whitelisted");
        isWhitelistedMerchant[account] = false;
        emit RemoveFromWhitelistMerchant(account);
    }
    
    function setTaxFeePercent(uint256 _taxFee) external onlyOwner {
        taxFee = _taxFee;
        emit SetTaxFeePercent(_taxFee);
    }
    
    function setPaymentFeePercent(uint256 percent) external onlyOwner {
        paymentFee = percent;
        emit SetPaymentFeePercent(percent);
    }
    
    function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
        emit SetMaxTxAmount(_maxTxAmount);
    }
    
    function setLiquidityFeePercent(uint256 _liquidityFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        emit SetLiquidityFeePercent(_liquidityFee);
    }
    
    function setTaxTeamPercent(uint256 _percent) external onlyOwner {
        taxTeamPercent = _percent;
        emit SetTaxTeamPercent(_percent);
    }
    
    function setTaxTreasuryPercent(uint256 _percent) external onlyOwner {
        taxTreasuryPercent = _percent;
        emit SetTaxTreasuryPercent(_percent);
    }
    
    function setTaxLPPercent(uint256 _percent) external onlyOwner {
        taxLPPercent = _percent;
        emit SetTaxLPPercent(_percent);
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        emit SetNumTokensSellToAddToLiquidity(_minimumTokensBeforeSwap);
    }
    
    function setTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = payable(_teamAddress);
        emit SetTeamAddress(_teamAddress);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = payable(_treasuryAddress);
        emit SetTreasuryAddress(_treasuryAddress);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public view returns (uint256 amountB) {
        return uniswapV2Router.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public view returns (uint256 amountOut) {
        return uniswapV2Router.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) public view returns (uint256 amountIn) {
        return uniswapV2Router.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path) public view returns (uint256[] memory amounts) {
        return uniswapV2Router.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path) public view returns (uint256[] memory amounts) {
        return uniswapV2Router.getAmountsIn(amountOut, path);
    }

    //to receive ETH from uniswapV2Router when swaping
    receive() external payable {}

    fallback() external payable {}
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1363 is IERC20, IERC165 {
    function transferAndCall(address to, uint256 value) external returns (bool);
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);
    function approveAndCall(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
    function transferOtherTokenAndCall(address tokenIn, address to, uint256 value, uint256 minValue) external returns (bool);
    function transferOtherTokenAndCall(address tokenIn, address to, uint256 value, uint256 minValue, bytes memory data) external returns (bool);
}

interface IERC1363Receiver {
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4); // solhint-disable-line  max-line-length
}

interface IERC1363Spender {
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}

library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

contract ERC1363 is ReentrancyGuard, ERC20, IERC1363, ERC165 {
    using SafeMath for uint256;

    event TransferAndCall(address to, uint256 value, bytes data);
    event TransferFromAndCall(address from, address to, uint256 value, bytes data);
    event ApproveAndCall(address spender, uint256 value, bytes data);
    event TransferOtherTokenAndCall(address tokenIn, address to, uint256 value, uint256 minValue, bytes data);

    using Address for address;

    bytes4 internal constant _INTERFACE_ID_ERC1363_TRANSFER = 0x4bbee2df;

    bytes4 internal constant _INTERFACE_ID_ERC1363_APPROVE = 0xfb9ec8ce;

    bytes4 private constant _ERC1363_RECEIVED = 0x88a7ca5c;

    bytes4 private constant _ERC1363_APPROVED = 0x7b04a2d0;

    constructor (string memory name, string memory symbol, address routerAddress) ERC20(name, symbol, routerAddress) {
        // register the supported interfaces to conform to ERC1363 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1363_TRANSFER);
        _registerInterface(_INTERFACE_ID_ERC1363_APPROVE);
    }

    // ERC1363 transferAndCall
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, "");
    }

    // ERC1363 transferAndCall
    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        require(!isBlacklisted[to], "Address is backlisted");
        require(isWhitelistedMerchant[to], "Merchant is not whitelisted");  

        // in percentage, 100% = 10000; 1% = 100; 0.1% = 10
        uint256 txPaymentFee = value / 10000 * paymentFee;
        uint256 valueAfterFee = value - txPaymentFee;

        transfer(to, valueAfterFee);
        require(_checkAndCallTransfer(_msgSender(), to, valueAfterFee, data), "ERC1363: _checkAndCallTransfer reverts");

        if (paymentFee > 0) {
            transfer(teamAddress, txPaymentFee);
        }

        emit TransferAndCall(to, valueAfterFee, data);
        return true;
    }

    // ERC1363 transferFromAndCall
    function transferFromAndCall(address from, address to, uint256 value) public override returns (bool) {
        return transferFromAndCall(from, to, value, "");
    }

    // ERC1363 transferFromAndCall
    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public override returns (bool) {
        require(!isBlacklisted[from], "Address is backlisted");
        require(!isBlacklisted[to], "Address is backlisted");
        require(isWhitelistedMerchant[to], "Merchant is not whitelisted");

        // in percentage, 100% = 10000; 1% = 100; 0.1% = 10
        uint256 txPaymentFee = value / 10000 * paymentFee;
        uint256 valueAfterFee = value - txPaymentFee;

        transferFrom(from, to, valueAfterFee);
        require(_checkAndCallTransfer(from, to, valueAfterFee, data), "ERC1363: _checkAndCallTransfer reverts");
        
        if (paymentFee > 0) {
            transfer(teamAddress, txPaymentFee);
        }

        emit TransferFromAndCall(from, to, valueAfterFee, data);
        return true;
    }

    // ERC1363 approveAndCall
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, "");
    }

    // ERC1363 approveAndCall
    function approveAndCall(address spender, uint256 value, bytes memory data) public override returns (bool) {
        require(!isBlacklisted[spender], "Address is backlisted");
        require(isWhitelistedMerchant[spender], "Merchant is not whitelisted");

        approve(spender, value);
        require(_checkAndCallApprove(spender, value, data), "ERC1363: _checkAndCallApprove reverts");
        emit ApproveAndCall(spender, value, data);
        return true;
    }

    function transferOtherTokenAndCall(address tokenIn, address to, uint256 value, uint256 minValue) public override returns (bool) {
        return transferOtherTokenAndCall(tokenIn, to, value, minValue, "");
    }

    function transferOtherTokenAndCall(address tokenIn, address to, uint256 value, uint256 minValue, bytes memory data) public override returns (bool) {
        require(!isBlacklisted[to], "Address is backlisted");
        require(isWhitelistedMerchant[to], "Merchant is not whitelisted");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), value);

        IERC20(tokenIn).approve(address(uniswapV2Router), value);

        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = uniswapV2Router.WETH(); //WETH
        path[2] = address(this);

        uint256 initialBalance = balanceOf(msg.sender);
        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            value,
            minValue,
            path,
            msg.sender,
            block.timestamp + 120
            );

        uint256 amountReceived = balanceOf(msg.sender) - initialBalance;

        emit TransferOtherTokenAndCall(tokenIn, to, amountReceived, minValue, data);

        return transferAndCall(to, amountReceived, data);
    }

    function _checkAndCallTransfer(address from, address to, uint256 value, bytes memory data) internal nonReentrant returns (bool) {
        if (!to.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(to).onTransferReceived(
            _msgSender(), from, value, data
        );
        return (retval == _ERC1363_RECEIVED);
    }

    function _checkAndCallApprove(address spender, uint256 value, bytes memory data) internal nonReentrant returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
            _msgSender(), value, data
        );
        return (retval == _ERC1363_APPROVED);
    }
}

contract PayBolt is ERC1363 {
    constructor (address routerAddress)
        ERC1363("PayBolt", "PAY", routerAddress) {
    }

    function paySecurelyWithPaybolt(address to, uint256 value) public returns (bool) {
        return transferAndCall(to, value, "");
    }

    function paySecurelyWithPaybolt(address to, uint256 value, bytes memory data) public returns (bool) {
        return transferAndCall(to, value, data);
    }

    function authorizeSecurelyWithPaybolt(address spender, uint256 value) public returns (bool) {
        return approveAndCall(spender, value, "");
    }

    function authorizeSecurelyWithPaybolt(address spender, uint256 value, bytes memory data) public returns (bool) {
        return approveAndCall(spender, value, data);
    }

    function paySecurelyWithAnyToken(address tokenIn, address to, uint256 value, uint256 minValue) public returns (bool) {
        return transferOtherTokenAndCall(tokenIn, to, value, minValue, "");
    }

    function paySecurelyWithAnyToken(address tokenIn, address to, uint256 value, uint256 minValue, bytes memory data) public returns (bool) {
        return transferOtherTokenAndCall(tokenIn, to, value, minValue, data);
    }
}