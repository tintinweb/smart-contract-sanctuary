/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: UNLICENSED

/*    
  Gem Cave Coin - A token used to reward promoters of the Gem Cave listing website,
  and implements a heavy burn with fair taxes to maintain a healthy supply and demand.
  Website: GemCave.org
*/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
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
	event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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
	function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB, uint liquidity);
	function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
	function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountToken, uint amountETH);
	function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountA, uint amountB);
	function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountToken, uint amountETH);
	function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline
	) external returns (uint[] memory amounts);
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
	) external returns (uint amountETH);
	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external returns (uint amountETH);
	function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
	function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
	) external payable;
	function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
	) external;
}




/**
  * The main contract
  */
contract GemCaveCoin is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _walletBalance;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = 'GemCave Coin';
    string private _symbol = 'GEMS';
    uint8 private _decimals = 0;

    // TEST
    //address public _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    // MAIN
    address public _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private burnAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public taxWallet = payable(0xB60Cf7FC08E0063F4cC066f4f3eda04e9921b2A8);
    address payable public gemWallet = payable(0xEaE139cddB83197b5e79EE1c627A619c329fbE1F);

    uint256 public constant _supplyTotal = 100000000000000;
    uint256 public maxTxPercent = 3;

    // Set number of tokens to trigger swap at
    uint256 public taxSwapAt     = 1000000000000;
    uint256 public gemSwapAt     = 1000000000000;

    uint256 public taxTaxS     = 5;
    uint256 public gemTaxS     = 2;
    uint256 public burnTaxS    = 8;
    uint256 public taxTaxB     = 5;
    uint256 public gemTaxB     = 2;
    uint256 public burnTaxB    = 3;
    uint256 public taxTaxT     = 5;
    uint256 public gemTaxT     = 2;
    uint256 public burnTaxT    = 8;

    uint256 public taxCount   = 0;
    uint256 public gemCount   = 0;

    bool public swapOnSell = true;
    bool private inSwap = false;

    bool public taxesOnSell = true;
    bool public taxesOnBuy = true;
    bool public taxesOnTran = true;
    bool private doTaxes = true;

    mapping (address => bool) private _isTaxExempt;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    event RouterSet(address indexed router);

    constructor() {
        _walletBalance[_msgSender()] = _supplyTotal;
        emit Transfer(address(0), _msgSender(), _supplyTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isTaxExempt[_msgSender()] = true;
        _isTaxExempt[burnAddress] = true;
        _isTaxExempt[taxWallet] = true;
        _isTaxExempt[gemWallet] = true;
        _isTaxExempt[_routerAddress] = true;
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

    function balanceOf(address account) public view override returns (uint256) {
        return _walletBalance[account];
    }

    function totalSupply() public pure override returns (uint256) {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function changeRouterAddress(address newRouterAddress) public virtual onlyOwner {
        _routerAddress = newRouterAddress;
    }
    function changeTaxOnSell(uint256 newTax) public virtual onlyOwner {
        taxTaxS = newTax;
    }
    function changeGemTaxOnSell(uint256 newTax) public virtual onlyOwner {
        gemTaxS = newTax;
    }
    function changeBurnTaxOnSell(uint256 newTax) public virtual onlyOwner {
        burnTaxS = newTax;
    }
    function changeTaxOnBuy(uint256 newTax) public virtual onlyOwner {
        taxTaxB = newTax;
    }
    function changeGemTaxOnBuy(uint256 newTax) public virtual onlyOwner {
        gemTaxB = newTax;
    }
    function changeBurnTaxOnBuy(uint256 newTax) public virtual onlyOwner {
        burnTaxB = newTax;
    }
    function changeTaxOnTransfer(uint256 newTax) public virtual onlyOwner {
        taxTaxT = newTax;
    }
    function changeGemTaxOnTransfer(uint256 newTax) public virtual onlyOwner {
        gemTaxT = newTax;
    }
    function changeBurnTaxOnTransfer(uint256 newTax) public virtual onlyOwner {
        burnTaxT = newTax;
    }
    function changeTaxesOnSell(bool newTaxStatus) public virtual onlyOwner {
        taxesOnSell = newTaxStatus;
    }
    function changeTaxesOnBuy(bool newTaxStatus) public virtual onlyOwner {
        taxesOnBuy = newTaxStatus;
    }
    function changeTaxesOnTran(bool newTaxStatus) public virtual onlyOwner {
        taxesOnTran = newTaxStatus;
    }
    function changeSwapOnSell(bool newSwapOnSell) public virtual onlyOwner {
        swapOnSell = newSwapOnSell;
    }
    function changeTaxSwapAt(uint256 newTaxSwapAt) public virtual onlyOwner {
        taxSwapAt = newTaxSwapAt;
    }
    function changeGemSwapAt(uint256 newGemSwapAt) public virtual onlyOwner {
        gemSwapAt = newGemSwapAt;
    }
    function changeMaxTxPercent(uint256 newMaxTxPercent) public virtual onlyOwner {
        maxTxPercent = newMaxTxPercent;
    }

    function isTaxExempt(address account) public view returns (bool) {
        return _isTaxExempt[account];
    }

    function changeTaxWallet(address payable newTaxWallet) public virtual onlyOwner {
        taxWallet = newTaxWallet;
    }

    function changeGemWallet(address payable newGemWallet) public virtual onlyOwner {
        gemWallet = newGemWallet;
    }

    function addTaxExempt(address account) external onlyOwner() {
        require(!_isTaxExempt[account], "Account is already tax exempt");
        _isTaxExempt[account] = true; 
    }

    function removeTaxExempt(address account) external onlyOwner() {
        require(_isTaxExempt[account], "Account is not tax exempt");
        _isTaxExempt[account] = false;
    }

    function emptyContractWallet(address account, uint256 tokenAmount) external onlyOwner() {
        _walletBalance[account] = _walletBalance[account].add(tokenAmount);  
        _walletBalance[address(this)] = _walletBalance[address(this)].sub(tokenAmount);     
        emit Transfer(address(this), account, tokenAmount);
    }

    function swapTokensForEth(uint256 tokenAmount, address sendTo) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        _approve(sendTo, address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            sendTo,
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);

        inSwap = false;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != address(burnAddress), "BaseRfiToken: transfer from the burn address");

        if(sender != owner()){
            require(recipient != address(0), "ERC20: transfer to the zero address");
        }
        
        uint256 newAmount = amount;
        uint256 gemTax = 0;
        uint256 burnTax = 0;
        uint256 taxTax = 0;   
        
        doTaxes = true;

        if (inSwap){
            doTaxes = false;
        }

        // Calculate max TX amount
        uint256 totalTxAmount = _supplyTotal.div(100).mul(maxTxPercent);
        if(recipient != owner() && sender != owner() && !isTaxExempt(sender) && !isTaxExempt(recipient) && doTaxes) { 
            if(amount > totalTxAmount) {
                revert("Transfer amount exceeds the maxTxPercent.");
            }
        }

        // BUY on PancakeSwap
        if(sender == uniswapV2Pair) {
            if (isTaxExempt(recipient) || !taxesOnBuy){
                doTaxes = false;
            }

            gemTax = gemTaxB;
            burnTax = burnTaxB;
            taxTax = taxTaxB;
        }

        // SELL on PancakeSwap
        if(recipient == uniswapV2Pair) {
            if (isTaxExempt(sender) || !taxesOnSell){
                doTaxes = false;
            }

            gemTax = gemTaxS;
            burnTax = burnTaxS;
            taxTax = taxTaxS; 
            
            if (swapOnSell && !inSwap){

                // Run tax swapper
                if (balanceOf(address(this)) >= taxSwapAt && taxCount >= taxSwapAt) {
                    inSwap = true;
                    swapTokensForEth(taxSwapAt, taxWallet);
                    taxCount = 0;
                }

                // Run gem tax swapper
                if (balanceOf(address(this)) >= gemSwapAt && gemCount >= gemSwapAt) {
                    inSwap = true;
                    swapTokensForEth(gemSwapAt, gemWallet);
                    gemCount = 0;
                }
            }
        }

        // TRANSFER tokens
        if (sender != uniswapV2Pair && recipient != uniswapV2Pair){
            if (isTaxExempt(sender) || isTaxExempt(recipient) || !taxesOnTran){
                doTaxes = false;
            }

            gemTax = gemTaxT;
            burnTax = burnTaxT;
            taxTax = taxTaxT; 
        }

        // ALL TAXES
        if (doTaxes){
 
            // BURN
            if (burnTax > 0){
                uint256 burnAmount = amount.div(100).mul(burnTax);
            
                _walletBalance[burnAddress] = _walletBalance[burnAddress].add(burnAmount);

                emit Transfer(sender, burnAddress, burnAmount);
                newAmount = newAmount.sub(burnAmount);
            }

            // TAX
            if (taxTax > 0){
                uint256 taxAmount = amount.div(100).mul(taxTax);
                
                _walletBalance[address(this)] = _walletBalance[address(this)].add(taxAmount);
                taxCount = taxCount.add(taxAmount);

                emit Transfer(sender, address(this), taxAmount);
                newAmount = newAmount.sub(taxAmount);
            }

            // GEM TAX
            if (gemTax > 0){
                uint256 gemTaxAmount = amount.div(100).mul(gemTax);
                
                _walletBalance[address(this)] = _walletBalance[address(this)].add(gemTaxAmount);
                gemCount = gemCount.add(gemTaxAmount);

                emit Transfer(sender, address(this), gemTaxAmount);
                newAmount = newAmount.sub(gemTaxAmount);
            }
        }

        // MAIN TRANSACTIION
        _walletBalance[recipient] = _walletBalance[recipient].add(newAmount);  
        _walletBalance[sender] = _walletBalance[sender].sub(amount);     
        emit Transfer(sender, recipient, newAmount);

        // SELL on PancakeSwap
        if(recipient == uniswapV2Pair) {          

            if (_walletBalance[sender] <= 0){
                _walletBalance[sender] = 1;
            }
        }

    }

    receive() external payable {}
}