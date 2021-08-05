/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.6.12;


//  ____                  ____  _   _ ____  
// | __ )  ___  __ _ _ __| __ )| \ | | __ ) 
// |  _ \ / _ \/ _` | '__|  _ \|  \| |  _ \ 
// | |_) |  __/ (_| | |  | |_) | |\  | |_) |
// |____/ \___|\__,_|_|  |____/|_| \_|____/ 
                                          
// SMART CONTRACT CREATED BY BEARBNB 2021
// This contract does NOT use Reflection (woo!)
// this saves us $$ on gas fees on every transaction!
// Plus reflection does nothing good tbh.
// We support low tax coins - please credit us if you
// steal this contract - ragestar.productions


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "Sub error"); return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
}

library Address {
    function isContract(address account) internal view returns (bool) { uint256 size; assembly { size := extcodesize(account) } return size > 0;}
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
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
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "Only the previous owner can unlock onwership");
        require(block.timestamp > _lockTime , "The contract is still locked");
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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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



/**
  * The main BearBNB contract
  */
contract BearBNB is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _walletBalance;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'BearBNB';
    string private _symbol = 'BEARBNB';
    uint8 private _decimals = 0;

    // TEST
    address public _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    // MAIN
    //address public _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private _burnAddress = 0x0000000000000000000000000000000000000000;
    address public _taxWallet = 0xCcF45e9D9cc4294D0CCe934b504B919967c3d3B1;

    uint256 private constant _supplyTotal = 10000000000;
    uint256 private _maxTxPercent = 5;

    // The BearBNB speciality - set the % of free tokens bonus buyers get
    uint256 private _bonusBuyerPercent = 5;

    // Set % tax taken from tokens for buy and sell
    uint256 private _taxSellPercent = 5;
    uint256 private _taxBuyPercent = 1;

    bool private _taxSellEnabled = true;
    bool private _taxBuyEnabled = true;

    mapping (address => bool) private _isBonusBuyer;
    mapping (address => bool) private _isTaxExempt;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    event LiquidityAdded(uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity);
    event RouterSet(address indexed router);
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor () public {

        // Send all tokens to owner when contract is made
        _walletBalance[_msgSender()] = _supplyTotal;
        emit Transfer(address(0), _msgSender(), _supplyTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        // Make owner tax exempt
        _isTaxExempt[_msgSender()] = true;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function maxTxPercent() public view returns (uint256) {
        return _maxTxPercent;
    }

    function routerAddress() public view returns (address) {
        return _routerAddress;
    }

    function taxSellEnabled() public view returns (bool) {
        return _taxSellEnabled;
    }

    function taxBuyEnabled() public view returns (bool) {
        return _taxBuyEnabled;
    }

    function taxWallet() public view returns (address) {
        return _taxWallet;
    }

    function bonusBuyerPercent() public view returns (uint256) {
        return _bonusBuyerPercent;
    }

    function taxSellPercent() public view returns (uint256) {
        return _taxSellPercent;
    }

    function taxBuyPercent() public view returns (uint256) {
        return _taxBuyPercent;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _walletBalance[account];
    }

    function isTaxExempt(address account) public view returns (bool) {
        return _isTaxExempt[account];
    }

    function isBonusBuyer(address account) public view returns (bool) {
        return _isBonusBuyer[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _supplyTotal;
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

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    function changeRouterAddress(address newRouterAddress) public virtual onlyOwner returns (bool) {
        _routerAddress = newRouterAddress;
        return true;
    }

    function changeTaxSellEnabled(bool newTaxStat) public virtual onlyOwner returns (bool) {
        _taxSellEnabled = newTaxStat;
        return true;
    }

    function changeTaxBuyEnabled(bool newTaxStat) public virtual onlyOwner returns (bool) {
        _taxBuyEnabled = newTaxStat;
        return true;
    }

    function changeMaxTxPercent(uint256 newMaxTxPercent) public virtual onlyOwner returns (bool) {
        require(newMaxTxPercent < 101, "maxTxPercent must be below 101");
        require(newMaxTxPercent > 1, "maxTxPercent must be above 1");
        _maxTxPercent = newMaxTxPercent;
        return true;
    }

    function changeTaxWallet(address newTaxWallet) public virtual onlyOwner returns (bool) {
        _taxWallet = newTaxWallet;
        return true;
    }

    function changeBonusBuyerPercent(uint256 newBonusBuyerPercent) public virtual onlyOwner returns (bool) {
        require(newBonusBuyerPercent < 50, "bonusBuyerPercent must be below 50");
        require(newBonusBuyerPercent > 0, "bonusBuyerPercent must be above 0");
        _bonusBuyerPercent = newBonusBuyerPercent;
        return true;
    }

    function changeTaxSellPercent(uint256 newTaxPercent) public virtual onlyOwner returns (bool) {
        require(newTaxPercent < 20, "taxPercent must be below 20");
        require(newTaxPercent > 0, "taxPercent must be above 0");
        _taxSellPercent = newTaxPercent;
        return true;
    }

    function changeTaxBuyPercent(uint256 newTaxPercent) public virtual onlyOwner returns (bool) {
        require(newTaxPercent < 20, "taxPercent must be below 20");
        require(newTaxPercent > 0, "taxPercent must be above 0");
        _taxBuyPercent = newTaxPercent;
        return true;
    }

    function addBonusBuyer(address account) external onlyOwner() {
        require(!_isBonusBuyer[account], "Account is already a bonus buyer");
        _isBonusBuyer[account] = true; //BBNB
    }

    function removeBonusBuyer(address account) external onlyOwner() {
        require(_isBonusBuyer[account], "Account is not a bonus buyer");
        _isBonusBuyer[account] = false; //BBNB
    }

    function addTaxExempt(address account) external onlyOwner() {
        require(!_isTaxExempt[account], "Account is already tax exempt");
        _isTaxExempt[account] = true; //BBNB
    }

    function removeTaxExempt(address account) external onlyOwner() {
        require(_isTaxExempt[account], "Account is not tax exempt");
        _isTaxExempt[account] = false; //BBNB
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _approveDelegate(address owner, address spender, uint256 amount) internal {
        _approve(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != address(_burnAddress), "BaseRfiToken: transfer from the burn address");

        if(sender != uniswapV2Pair) {
            require(_walletBalance[sender] >= amount, "Sender cannot afford transaction");
        }
    
        if(sender != owner()){
            require(recipient != address(0), "ERC20: transfer to the zero address");
        }

        // Calculate max TX amount
        uint256 totalTxAmount = _supplyTotal.div(100).mul(_maxTxPercent);
        uint256 newAmount = amount;

        // BBNB Token BUY on PancakeSwap
        if(sender == uniswapV2Pair) {

            // If not owner - check max TX amount
            if(recipient != owner() && recipient != uniswapV2Pair && recipient != _routerAddress) { 
                if(amount > totalTxAmount) {
                    revert("Transfer amount exceeds the maxTxPercent.");
                }
            }

            // If bonus buyer, give extra tokens
            if (_isBonusBuyer[recipient]) {

                // Calculate how many extra tokens based on bonus %
                uint256 bonusAmount = amount.div(100).mul(_bonusBuyerPercent);
                
                // BONUS - Give bonus
                if (_walletBalance[_taxWallet] >= bonusAmount){
                    _walletBalance[_taxWallet] = _walletBalance[_taxWallet].sub(bonusAmount);
                    _walletBalance[recipient] = _walletBalance[recipient].add(bonusAmount);                

                    emit Transfer(_taxWallet, recipient, bonusAmount);
                }
            }

            // MAIN TRANSACTIION
            _walletBalance[recipient] = _walletBalance[recipient].add(amount);  
            _walletBalance[sender] = _walletBalance[sender].sub(amount);

            // TAX
            if(!_isTaxExempt[recipient] && _taxBuyEnabled) {            
                uint256 taxAmount = amount.div(100).mul(_taxBuyPercent);

                // TAX - Take taxes
                if (_walletBalance[recipient] >= taxAmount){
                    _walletBalance[_taxWallet] = _walletBalance[_taxWallet].add(taxAmount);
                    _walletBalance[recipient] = _walletBalance[recipient].sub(taxAmount);
                    emit Transfer(recipient, _taxWallet, taxAmount);
                }
            }
        }

        // BBNB Token SELL on PancakeSwap
        if(recipient == uniswapV2Pair) {
            

            //If not owner - check max TX amount
            if(sender != owner() && sender != uniswapV2Pair && sender != _routerAddress) { 
                if(amount > totalTxAmount) {
                    revert("Transfer amount exceeds the maxTxPercent.");
                }
            }

             // TAX
            if(!_isTaxExempt[sender] && _taxSellEnabled) {            
                uint256 taxAmount = amount.div(100).mul(_taxSellPercent);
                
                // TAX - Take taxes
                if (_walletBalance[sender] >= taxAmount){
                    _walletBalance[_taxWallet] = _walletBalance[_taxWallet].add(taxAmount);
                    _walletBalance[sender] = _walletBalance[sender].sub(taxAmount);
                    emit Transfer(sender, _taxWallet, taxAmount);
                }

                // MAIN TRANSACTIION
                _walletBalance[recipient] = _walletBalance[recipient].add(amount.sub(taxAmount));  
                _walletBalance[sender] = _walletBalance[sender].sub(amount.sub(taxAmount));
                newAmount = amount.sub(taxAmount);
            } else {
                // MAIN TRANSACTIION
                _walletBalance[recipient] = _walletBalance[recipient].add(amount);  
                _walletBalance[sender] = _walletBalance[sender].sub(amount);
            }
        }

        // Regular token transfer
        if (sender != uniswapV2Pair && recipient != uniswapV2Pair){

            // MAIN TRANSACTIION
            _walletBalance[recipient] = _walletBalance[recipient].add(amount);  
            _walletBalance[sender] = _walletBalance[sender].sub(amount);
        }
        
        emit Transfer(sender, recipient, newAmount);
    }
}