/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/*
88888888888 .d8888b.  888    888 8888888 888888b.   
    888    d88P  Y88b 888    888   888   888  "88b  
    888    Y88b.      888    888   888   888  .88P  
    888     "Y888b.   8888888888   888   8888888K.  
    888        "Y88b. 888    888   888   888  "Y88b 
    888          "888 888    888   888   888    888 
    888    Y88b  d88P 888    888   888   888   d88P 
    888     "Y8888P"  888    888 8888888 8888888P" 

http://tungstenshiba.com
https://twitter.com/TungstenShiba
https://t.me/tungstenshib
https://discord.gg/rAKrQprQSu
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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
}

// pragma solidity >=0.5.0;

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

contract TSHIBA is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable public marketingAddress =   payable(0x759130a5781D866Ac3cfaE3800cfe32C22B3C6Bc); // marketing address
    address payable public developmentAddress = payable(0x4E08834eB2cc0CA60b28fc70732AAD329DAE210F); // dev address
    address payable public charityWallet =      payable(0x50AeFc84469f3e28aEb28Bbe2E6612b6C452C076); // charity wallet   
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public marketingShare;
    uint256 public devShare;
    uint256 public charityShare;
    uint256 public burnShare;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping (address => uint256) bnbSent; // Amount owed from mint event
    mapping (address => bool) private frenzyEligible; // Tells if account if eligible for Frenzy
   
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    string private _name = "Tungsten Shiba";
    string private _symbol = "TSHIB";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 0 * (10 ** decimals());

    uint256 public price = 0.0001 ether; // 0.0001 BNB
    uint256 public tshibToMint = 0;
    uint256 public bnbRequiredToDouble = 10 ether; // BNB Required before price decreased
    uint256 constant public DEFAULT_TIMER = 1 days;
    uint256 public MINT_OPEN;
    uint256 public mintTimer;
    uint256 public lpUnlockDate;
    bool    public frenzyModeOpen = false;
    bool    private mintConcluded = false;

    event MintOpen(uint256 timeOpened);
    event MintConcluded(uint256 timeEnded);
    event LiquidityLocked(uint256 unlockDate);
    event FrenzyModeOpen();

    uint256 public _sellFee = 10;
    uint256 public _buyFee = 5;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwap;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor () {
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwap Router
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // Testnet Pancakeswap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);   // Testnet Pancake Fork
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function removeAllFee() private {
        if(_liquidityFee == 0) return;
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = 0;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = payable(_marketingAddress);
    }

    function setDevelopmentAddress(address _devAddress) external onlyOwner {
        developmentAddress = payable(_devAddress);
    }

    function setCharityAddress(address _charityAddress) external onlyOwner {
        charityWallet = payable(_charityAddress);
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferBuy(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _liquidityFee = _buyFee;
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        uint fee = calculateLiquidityFee(amount);
        _balances[to] += amount.sub(fee);
        _balances[address(this)] += fee;
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth();
        uint256 balanceDelta = address(this).balance.sub(balanceBefore);
        marketingShare  += balanceDelta.mul(5).div(50);
        devShare        += balanceDelta.mul(5).div(50);
        burnShare       += balanceDelta.mul(40).div(50);
        emit Transfer(from, to, amount - fee);
    }

    function _transferSell(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _liquidityFee = _sellFee;
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        uint fee = calculateLiquidityFee(amount);
        _balances[to] += amount.sub(fee);
        _balances[address(this)] += fee;
        uint256 balanceBefore = address(this).balance;
        swapTokensForEth();
        uint256 balanceDelta = address(this).balance.sub(balanceBefore);
        marketingShare  += balanceDelta.mul(15).div(100);
        devShare        += balanceDelta.mul(15).div(100);
        charityShare    += balanceDelta.mul(30).div(100);
        burnShare       += balanceDelta.mul(40).div(100);
        emit Transfer(from, to, amount - fee);
    }

    function _transferNormal(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        _liquidityFee = 0;
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if((from == uniswapV2Pair) && !_isExcludedFromFee[to] && to != address(uniswapV2Router)) {
            _transferBuy(from, to, amount);
        }
        else if (!inSwap && !_isExcludedFromFee[from] && to == uniswapV2Pair) {
            _transferSell(from, to, amount);
        } else {
            _transferNormal(from, to, amount);
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function collectAccumulated() public {
        marketingAddress.transfer(marketingShare);
        developmentAddress.transfer(devShare);
        charityWallet.transfer(charityShare);
        payable(address(deadAddress)).transfer(burnShare);
        marketingShare = 0;
        devShare = 0;
        charityShare = 0;
        burnShare = 0;
    }

    function swapTokensForEth() private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        uint tokenAmount = _balances[address(this)];
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
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
            address(this),
            block.timestamp
        );
    }

    // // // // // // // // // // T S H I B // // // // // // // // // // // //

    /**
     * Internal function that automatically withdraws BNB post mint
     * Called after lockLiquidity()
     **/
    function withdraw() public onlyOwner {
        require(mintConcluded, "Mint event must be finished");
        require(address(this).balance > 0, "Balance must be more than 0");
        uint balanceHalf = address(this).balance.div(2);
        marketingAddress.transfer(balanceHalf);
        developmentAddress.transfer(balanceHalf);
    }

    /**
     * Function allowing owner to sweep contract of non-TSHIB or non-BNB tokens (including remove LP)
     * Permitted after 1 year from mint event ending (so that LP is locked)
     */
    function withdrawOtherToken(address _tokenContract, uint256 _amount) public onlyOwner {
        require(block.timestamp > lpUnlockDate, "You can't withdraw before the unlock date!");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
    /**
     * 
     **/
    function claimPostMint() public {
        require(mintConcluded == true, "Sale is still active!");
        require(getOwedTshib(_msgSender()) > 0, "You have nothing to claim!");
        uint owed = getOwedTshib(_msgSender());
        _mint(_msgSender(), owed);
        bnbSent[msg.sender] = 0;
    }
    
    /**
     * Begins the Mint Phase
     * Can only be called once, by Owner.
     * Caller can specify time in minutes for length of sale, or leave 0 for 24 hours
     **/
    function openMint(uint256 timeMinutes) public onlyOwner {
        require(mintConcluded == false, "Sale has concluded!");
        MINT_OPEN = block.timestamp;
        if(timeMinutes == 0) {
            mintTimer = MINT_OPEN + DEFAULT_TIMER;
        } else {
            mintTimer = timeMinutes.mul(1 minutes).add(MINT_OPEN);
        }
        setFrenzyEligible(_msgSender());
        emit MintOpen(MINT_OPEN);
    }
    
    /**
     * Concludes the mint event, withdraws
     **/
    function closeMintEvent() public onlyOwner {
        require(!mintConcluded, "Mint event is not open!");
        tshibToMint = getTotalToMint();
        mintConcluded = true;
        mintTimer = 0;
        uint _liqToAdd = tshibToMint.mul(50).div(100);

        _mint(address(this), _liqToAdd);

        emit Transfer(address(0), address(this), _liqToAdd);
        addLiquidity(_liqToAdd, address(this).balance/2);
        lpUnlockDate = MINT_OPEN + 365 days; // Lock liquidity for 1 year from mint open
        emit LiquidityLocked(lpUnlockDate);
        //withdraw();
        emit MintConcluded(block.timestamp);
    }
    
    /**
     * Every time minted TSHIB doubles, decrease price 10%
     * Begins at 10 BNB
     **/
    function checkMultiplier() internal {
        if(address(this).balance >= bnbRequiredToDouble) {
            bnbRequiredToDouble = bnbRequiredToDouble.mul(2);
            price = price.mul(9).div(10); // Multiply price by 0.9 every time BNB in doubles
        }
    }

    function setFrenzyEligible(address user) public onlyOwner {
        frenzyEligible[user] = true;
    }

    function checkFrenzyEligibility(address user) internal {
        // If user has minted 5 BNB of TSHIB, allow in frenzy
        if (bnbSent[user] >= 5 ether) {
            frenzyEligible[user] = true;
        }
    }

    function isFrenzyEligible(address user) public view returns (bool) {
        return frenzyEligible[user];
    }

    // TESTING FUNCTIONS
    function setBnbRequiredToDouble() public {
        bnbRequiredToDouble = 0.01 ether;
    } // remove

    function getBnbRequiredToDouble() public view returns (uint256) {
        return bnbRequiredToDouble;
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    } // Remove after testing

    function getValueBnb(address addr) public view returns (uint256) {
        return bnbSent[addr];
    }

    // END TESTING

    /**
     * Returns the amount of TSHIB owed to the sender
     * Takes amount owed
     **/
    function getOwedTshib(address addr) public view returns (uint256) {
        return (bnbSent[addr] / price) * (10 ** decimals());
    }
    
    function getTotalToMint() public view returns (uint256) {
        if (mintConcluded)
            return tshibToMint;
        else
            return (tshibToMint / price) * (10 ** decimals());
    }

    function getCurrentPrice() public view returns (uint256) {
        return price;
    }

    /**
     * Bumps the timer by 10 minutes. Called at each Frenzy Mode mint
     **/
    function bumpTimer() internal {
        mintTimer += 10 minutes;
    }
    
    /**
     * If the mint event has begun and not expired, mint TSHIB based on the transaction paid. 
     **/
    function mintTshib() public payable {
        require(block.timestamp < mintTimer, "Mint event is not open!");
        require(msg.value > 0, "You must send some BNB!");
        // Checks if its time to enter Frenzy Mode, and if Frenzy mode has been enabled
        if((mintTimer - block.timestamp) < 30 minutes) {
            bumpTimer();
            if(!frenzyModeOpen) frenzyModeOpen = true;
        }
        uint bnbValue = msg.value;
        if(frenzyModeOpen) {
            require(frenzyEligible[msg.sender], "You are not eligible for Frenzy mode!");
            bnbValue = bnbValue.mul(11).div(10); // Adds 10% 
        }
        checkMultiplier();
        bnbSent[msg.sender] = bnbSent[msg.sender].add(bnbValue);
        checkFrenzyEligibility(msg.sender);
        tshibToMint = tshibToMint.add(bnbValue);
    }
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}