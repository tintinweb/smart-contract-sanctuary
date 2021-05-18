/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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


contract PIKA is Context,Owned,  ERC20 {
    using SafeMath for uint256;
    uint256 public _taxFee;
    uint256 public totalSupply;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _taxFeepercent = 225;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public ContractDeployed;
     bool inSwapAndLiquify;
     bool public swapAndLiquifyEnabled = true;
    uint256 private MinimumSupply = 100000000 *10**9 * 10**9;
     uint256 public _maxTxAmount = 50000000000 * 10**9 * 10**9;   
    uint256 private numTokensSellToAddToLiquidity = 5000000000 * 10**9 * 10**9;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    event TransferFee(address indexed _from, address indexed _to, uint256 _value);
     event SwapAndLiquifyEnabledUpdated(bool enabled);
      event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
      modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
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
        
        if(_isExcludedFromFee[sender]  ||  _isExcludedFromFee[recipient] )
        {
            uint256 senderBalance = balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            balances[sender] = senderBalance - amount;
            balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
        else
        {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        
                uint256 _Fee = calSwapToken(amount,_taxFeepercent);
                _taxFee +=  _Fee;
         
                uint256 senderBalance = balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                balances[sender] = senderBalance - amount;
                balances[recipient] += amount-_Fee;
                balances[address(this)]+=_Fee;
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
    
    
    
    
     
    
    function viewFee() public view  returns(uint256){
       return  _taxFeepercent ;
    } 
         
    function extractfee() external onlyOwner(){
        PIKA(address(this)).transfer(_msgSender(), _taxFee);
        _taxFee = 0;
       }
   
    function calSwapToken(uint256 _tokens, uint256 cust) internal pure returns (uint256) {
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
    
    
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    constructor() public {
       symbol = "PIKA";
       name = "PIKA";
       decimals = 18;
       totalSupply = 50000000000000 * 10**9 * 10**9; 
        owner = _msgSender();
       balances[owner] = totalSupply;
       _isExcludedFromFee[owner] = true;
       _isExcludedFromFee[address(this)] = true;
         ContractDeployed = block.timestamp;
   }

    receive () payable external {
       require(msg.value>0);
       owner.transfer(msg.value);
   }
    
}