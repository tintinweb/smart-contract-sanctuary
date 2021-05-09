/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

library SafeMath
{

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

   function ceil(uint a, uint m) internal pure returns (uint r) {
       return (a + m - 1) / m * m;
   }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Owned is Context
{
   modifier onlyOwner() virtual{
       require(_msgSender()==owner);
       _;
   }
   address payable owner;
   address payable newOwner;
   function changeOwner(address payable _newOwner) external onlyOwner {
       require(_newOwner!=address(0));
       newOwner = _newOwner;
   }
   function acceptOwnership() external {
       if (_msgSender()==newOwner) {
           owner = newOwner;
       }
   }
}

interface ERC20 
{
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function transfer(address _to, uint256 _value) external  returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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

contract PIKA is Context,Owned,  ERC20 {
    using SafeMath for uint256;
    uint256 public _taxFee;
    uint256 public totalSupply;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _taxFeepercent = 225;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public ContractDeployed;
    address oldPika = 0xE09fB60E8D6e7E1CEbBE821bD5c3FC67a40F86bF;
    uint256 public oldPika_amount;
    uint256 private minamountTakenOut = 1000000 *10**9 * 10 **9;  
    uint256 private MinimumSupply = 100000000 *10**9 * 10**9;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    event TransferFee(address indexed _from, address indexed _to, uint256 _value);
    
    function balanceOf(address _owner) view    public override  returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount)  public override     returns (bool success) {
        _transfer(_msgSender(), _to, _amount);
        return true;
    }
  
    function transferFrom(address sender, address recipient, uint256 amount) public override  returns (bool success) {
        
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowed[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;

        
    }
  
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(_isExcludedFromFee[sender]  ||  _isExcludedFromFee[recipient])
        {
            uint256 senderBalance = balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            balances[sender] = senderBalance - amount;
            balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
        else
        {
            uint256 _Fee = calSwapToken(amount,_taxFeepercent);
            _taxFee +=  _Fee;
            if(_taxFee >= minamountTakenOut )
            {
                swapTokensForEth(_taxFee);
            }
            
                uint256 senderBalance = balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                balances[sender] = senderBalance - amount;
                balances[recipient] += amount-_Fee ;
                emit Transfer(sender, recipient, amount-_Fee);
            
        }


      
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
  
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address _owner, address _spender) view public override  returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        
        
            require(account != address(0), "ERC20: burn from the zero address");
            uint256 accountBalance = balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            balances[account] = accountBalance - amount;
            totalSupply -= amount;
            emit Transfer(account, address(0), amount);
        
            
        }
    

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            owner,
            block.timestamp
        );
        
        _taxFee =0;
    }

    function viewMinExtractAmt() public view returns(uint256){
         return minamountTakenOut;
     }    
        
    function setMinExtractAmt(uint256 _amount) public onlyOwner() {
         minamountTakenOut = _amount;
     }
    
    function viewFee() public view  returns(uint256){
       return  _taxFeepercent ;
    } 
    
    function exchnagePika(uint256 tokens)external{
            
        require(tokens <= PIKA(address(this)).balanceOf(address(this)), "Not enough tokens in the reserve");
        require(ERC20(oldPika).transferFrom(_msgSender(), address(this), tokens), "Tokens cannot be transferred from user account");      
            

               uint256 time = block.timestamp - ContractDeployed;
               uint256 day = time.div(86400);
               require(day <= 4, "Sorry Swaping Time Period is finished");

                if(tokens < 10000000000 * 10**9 * 10**9)
                {
                    uint256 extra = calSwapToken(tokens,500);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                
                else if ( (tokens >= 10000000000 * 10**9 * 10**9)  &&  (tokens < 100000000000 * 10**9 * 10**9))
                {
                    uint256 extra = calSwapToken(tokens,250);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                else if( tokens >= 100000000000 * 10**9 * 10**9 )
                {
                    uint256 extra = calSwapToken(tokens,100);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                
            
            oldPika_amount = oldPika_amount.add(tokens);

    }
    
    function extractOldPIKA() external onlyOwner(){
            ERC20(oldPika).transfer(_msgSender(), oldPika_amount);
            oldPika_amount = 0;
        }
        
    function extractfee() external onlyOwner(){
        PIKA(address(this)).transfer(_msgSender(), _taxFee);
        _taxFee = 0;
       }
   
    function calSwapToken(uint256 _tokens, uint256 cust) internal virtual returns (uint256) {
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(2));
        return custPercentofTokens;
        }

    function burn(uint256 value) public returns(bool flag) {
     if(totalSupply >= MinimumSupply)         
     {
      _burn(_msgSender(), value);
      return true;
     } 
     else
     return false;

    }
    
    function viewMinSupply()public view  returns(uint256) {
            return MinimumSupply;
    }
    
    function changeMinSupply(uint256 newMinSupply)onlyOwner() public{
            MinimumSupply = newMinSupply;
    }
    
    function addLiquidity(uint256 tokenAmount) public payable onlyOwner() {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0, // slippage is unavoidable
           owner,
            block.timestamp
        );
    }
    
    constructor() {
       symbol = "PIKA";
       name = "PIKA";
       decimals = 18;
       totalSupply = 50000000000000 * 10**9 * 10**9; //50 trillion
        owner = _msgSender();
       balances[owner] = totalSupply;
       _isExcludedFromFee[owner] = true;
       _isExcludedFromFee[address(this)] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
    ContractDeployed = block.timestamp;
   }

    receive () payable external {
       require(msg.value>0);
       owner.transfer(msg.value);
   }
    
}