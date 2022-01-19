/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT                                                                                                                                                             
                                                    
pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUSV2Pair {
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

interface IUSV2Factory {
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

interface IUSV2Router01 {
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

interface IUSV2Router02 is IUSV2Router01 {
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

contract hostileZone is ERC20, Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _totalSupply = 100 * 1e6 * 1e18;

    IUSV2Router02 private usV2Router;
    address public usV2Pair;

    bool private inTheZone; //swap
    bool private misa = true; 

    address public hostileBank;
    address public liqOwner; //this is where the auto LP created will go - set to go to 0xDEAD at launch
    
    uint256 public maxTx;
    uint256 public tokenToEth;
    uint256 public maxWallet;
    
    // bot, snipe and whale control protections
    bool public restrictions = true;
    bool public tradesPermit = false;
    bool public waxOn = false;

    mapping (address => bool) private bots;
    mapping(address => uint256) private _lastTrans; 
    bool public timeRugEnabled = true;
    bool private boughtEarly = true;
    uint256 private _firstBlock;
    uint256 private _botBlocks;

    uint256 public buyTotalFees;
    uint256 public buyHostileBankFee;
    uint256 public buyLiqFee;
    
    uint256 public sellTotalFees;
    uint256 public sellHostileBankFee;
    uint256 public sellLiqFee;
    
    uint256 private tokensForBank;
    uint256 private tokensForLiq;

    uint256 _buyHostileBankFee = 8;
    uint256 _buyLiqFee = 5;

    uint256 _sellHostileBankFee = 8;
    uint256 _sellLiqFee = 10;


    // exlcusions
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTx;
    event ExcludeFromFees(address indexed account, bool isExcluded);

    event hostileBankUpdated(address indexed newWallet, address indexed oldWallet);
    event liqOwnerUpdated(address indexed newWallet, address indexed oldWallet);
    
    event EndedBoughtEarly(bool boughtEarly);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );


    constructor() ERC20("Hostle Zone", "HZONE") {
        
        IUSV2Router02 _usV2Router = IUSV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTx(address(_usV2Router), true);
        usV2Router = _usV2Router;
        
        _approve(address(this), address(usV2Router), _totalSupply);

        usV2Pair = IUSV2Factory(_usV2Router.factory()).createPair(address(this), _usV2Router.WETH());
        IERC20(usV2Pair).approve(address(usV2Router),type(uint256).max);

        excludeFromMaxTx(address(usV2Pair), true);      

        maxTx = 250000 * 1e18; // 0.25% of supply max transaction allowed at launch
        maxWallet = 2 * 1e6 * 1e18; // 2% of supply max wallet
        tokenToEth = 50000 * 1e18; // 0.05% is the amount of tokens collected before selling for eth

        buyHostileBankFee = _buyHostileBankFee;
        buyLiqFee = _buyLiqFee;
        buyTotalFees = buyHostileBankFee + buyLiqFee;
        
        sellHostileBankFee = _sellHostileBankFee;
        sellLiqFee = _sellLiqFee;
        sellTotalFees = sellHostileBankFee + sellLiqFee;
        
        //update this or you are going to donate all your fees to 0xDead
        hostileBank = payable(0x7292D1D1DE3e7D6cC39905743b3488fb8633ad8f); 
        liqOwner = payable(0x000000000000000000000000000000000000dEaD);
        
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(hostileBank), true);
        excludeFromFees(address(liqOwner), true);
        
        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(hostileBank), true);
        excludeFromMaxTx(address(liqOwner), true);
       
       _mint(msg.sender, _totalSupply); //internal transfer to be called once
    }

    receive() external payable {

  	}
    
    // disable Transfer delay - cannot be reenabled
    function disableTimeRug() external onlyOwner returns (bool){
        timeRugEnabled = false;
        return true;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateTokensToEth(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    tokenToEth = newAmount;
  	    return true;
  	}
    
    function updateMaxTxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxTx lower than 0.1%");
        maxTx = newNum * (1e18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (1e18);
    }
    
    function excludeFromMaxTx(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTx[updAds] = isEx;
    }
    
    function updateBuyFees(uint256 _hostileBankFee, uint256 _liqFee) external onlyOwner {
        buyHostileBankFee = _hostileBankFee;
        buyLiqFee = _liqFee;
        buyTotalFees = buyHostileBankFee + buyLiqFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _hostileBankFee, uint256 _liqFee) external onlyOwner {
        sellHostileBankFee = _hostileBankFee;
        sellLiqFee = _liqFee;
        sellTotalFees = sellHostileBankFee + sellLiqFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateHostileBankWallet(address newHostileBankWallet) external onlyOwner {
        emit hostileBankUpdated(newHostileBankWallet, hostileBank);
        hostileBank = newHostileBankWallet;
    }

    function updateLiqOwner(address newLiqOwner) external onlyOwner {
        emit liqOwnerUpdated(newLiqOwner, liqOwner);
        liqOwner = newLiqOwner;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if(restrictions){
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inTheZone
            ){
                if (from == usV2Pair && to != address(usV2Router)) {
                
                    if (block.number <= _firstBlock.add(_botBlocks)) {
                        bots[to] = true;
                    }                        

                }

                if(!tradesPermit){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                if (timeRugEnabled){
                    if (to != owner() && to != address(usV2Router) && to != address(usV2Pair)){
                        require(_lastTrans[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _lastTrans[tx.origin] = block.number;
                    }
                }
                 
                //when buy
                if (from == usV2Pair) {
                        require(amount <= maxTx, "Buy transfer amount exceeds the maxTx.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (to == usV2Pair && !_isExcludedMaxTx[from] && !bots[from] && !bots[to]) {
                        require(amount <= maxTx, "Sell transfer amount exceeds the maxTx.");
        
                }
                else if(!_isExcludedMaxTx[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= tokenToEth;

        if (canSwap && waxOn && !inTheZone && from != usV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            inTheZone = true;
            switchIt();
            inTheZone = false;
        }

        bool takeFee = !inTheZone;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        //transfers are free
        if(takeFee){
            // on sell
            if (to == usV2Pair && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiq += fees * sellLiqFee / sellTotalFees;
                tokensForBank += fees * sellHostileBankFee / sellTotalFees;
            }
            // on buy
            else if(from == usV2Pair && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(100);
        	    tokensForLiq += fees * buyLiqFee / buyTotalFees;
                tokensForBank += fees * buyHostileBankFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the us pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usV2Router.WETH();

        _approve(address(this), address(usV2Router), tokenAmount);

        // make the swap
        usV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(usV2Router), tokenAmount);

        // add the liquidity
        usV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(liqOwner),
            block.timestamp
        );
    }

    function switchIt() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiq + tokensForBank;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > tokenToEth * 20){
          contractBalance = tokenToEth * 20;
        }
        
        uint256 liqTokens = contractBalance * tokensForLiq / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liqTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForHostileBank = ethBalance.mul(tokensForBank).div(totalTokensToSwap);
        uint256 ethForLiq = ethBalance - ethForHostileBank;
        
        tokensForLiq = 0;
        tokensForBank = 0;
        
        if(liqTokens > 0 && ethForLiq > 0){
            addLiquidity(liqTokens, ethForLiq);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiq, tokensForLiq);
        }
        
        (success,) = address(hostileBank).call{value: address(this).balance}("");
    }

    function badBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
 
    function notaBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function warBegins(uint256 botBlocks) private {
        _firstBlock = block.number;
        _botBlocks = botBlocks;
        tradesPermit = true;
    }

    // this begins the contract and once enabled, it cannot be disabled
    function startHostileZone(uint256 botBlocks) external onlyOwner() {
        require(botBlocks <= 1, "don't catch humans");
        waxOn = true;
        require(boughtEarly == true, "done");
        boughtEarly = false;
        warBegins(botBlocks);
        emit EndedBoughtEarly(boughtEarly);
    }

    // airdrop tokens to max 200 wallets at a time
    function airdrop(address[] memory airdropWallets, uint256[] memory amounts) external onlyOwner {
        require(airdropWallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits"); // allows for airdrop
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 amount = amounts[i];
            _transfer(msg.sender, wallet, amount);
        }
    }

}