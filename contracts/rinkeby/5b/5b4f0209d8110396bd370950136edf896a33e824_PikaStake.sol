/**
 *Submitted for verification at Etherscan.io on 2021-04-28
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

contract ReentrancyGuard
{
   bool private _notEntered;

   constructor () {
       // Storing an initial non-zero value makes deployment a bit more
       // expensive, but in exchange the refund on every call to nonReentrant
       // will be lower in amount. Since refunds are capped to a percetange of
       // the total transaction's gas, it is best to keep them low in cases
       // like this one, to increase the likelihood of the full refund coming
       // into effect.
       _notEntered = true;
   }


   modifier nonReentrant() {
       // On the first call to nonReentrant, _notEntered will be true
       require(_notEntered, "ReentrancyGuard: reentrant call");

       // Any calls to nonReentrant after this point will fail
       _notEntered = false;

       _;

       // By storing the original value once again, a refund is triggered (see
       // https://eips.ethereum.org/EIPS/eip-2200)
       _notEntered = true;
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

interface ERC20 {
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function transfer(address _to, uint256 _value) external  returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------

contract Token is Context,Owned,  ERC20 {
    using SafeMath for uint256;
    uint256 public totalSupply;
    string public symbol;
    string public name;
    uint8 public decimals;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    
    event TransferFee(address indexed _from, address indexed _to, uint256 _value);
    
    function balanceOf(address _owner) view    public override  returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount)  public override     returns (bool success) {
        
             _transfer(_msgSender(), _to, _amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public override  returns (bool success) {
        _transfer(_from, _to, _amount);
        uint256 currentAllowance = allowed[_from][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        _approve(_from, _msgSender(), currentAllowance - _amount);

        return true;
        
    }
  
    function transferFromThunder(address _from,address _to,uint256 _amount) public  returns (bool success) {

        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 percent = calPercentofToken(_amount,250);
         _burn(_from,percent);
        
        uint256 senderBalance = balances[_from];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        balances[_from] = senderBalance - _amount;
        balances[_to] += _amount - percent;
        emit Transfer(_from, _to, _amount-percent);
        
        uint256 currentAllowance = allowed[_from][_msgSender()];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        _approve(_from, _msgSender(), currentAllowance - _amount);

        return true;
        
    }
  
    function thunderFunc(address _from,uint256 _amount) public{
        uint256 percent = calPercentofToken(_amount,250);
        _burn(_from,percent);
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
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

  
    function calPercentofToken(uint256 _tokens, uint256 cust) internal virtual returns (uint256)
        {
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(2));
        return custPercentofTokens;
        }
    
    
}

contract PIKA is Context,Token{
   using SafeMath for uint256;
   constructor() {
       symbol = "PIKA";
       name = "PIKA";
       decimals = 18;
       totalSupply = 50000000000000 * 10**9 * 10**9; //50 trillion
       owner = _msgSender();
       balances[owner] = totalSupply;

   }

   receive () payable external {
       require(msg.value>0);
       owner.transfer(msg.value);
   }

}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract PikaStake is Context,PIKA, ReentrancyGuard {
   using SafeMath for uint256;
   address oldPika = 0x866cCE828928A37ae08403A0646dE75e40852588;
   uint256 oldPika_amount; 
   uint256 private TotalStakedPIKA = 0;
   uint256 private TeamFeesCollector = 0;
    uint256 private ContractDeployed;
    constructor() {
        ContractDeployed = block.timestamp;
      
    }
       
       
        struct USER
        {
            uint256 stakedAmount;
            uint256 creationTime; 
            uint256 TotalPIKARewarded;
        }
   
        mapping(address => USER) public trainer;
   
        function exchnagePika(uint256 tokens)external nonReentrant  
        {
            
            
            
            
            
            
            require(tokens <= PIKA(address(this)).balanceOf(address(this)), "Not enough tokens in the reserve");
            require(ERC20(oldPika).transferFrom(_msgSender(), address(this), tokens), "Tokens cannot be transferred from user account");      
            

          uint256 time = block.timestamp - ContractDeployed;
          uint256 day = time.div(86400);
          
          
            
            if(day <= 4)

            {
             //0-10 B they get 5%, 10-100 they get 2.5% and 100 B + they get 1%
           
            
                if(tokens < 10000000000 * 10**9 * 10**9)
                {
                    uint256 extra = calPercentofTokens(tokens,5000000);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                
                else if ( tokens >= 10000000000 * 10**9 * 10**9  &&  tokens < 100000000000 * 10**9 * 10**9)
                {
                    uint256 extra = calPercentofTokens(tokens,2500000);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                else if( tokens >= 100000000000 * 10**9 * 10**9 )
                {
                    uint256 extra = calPercentofTokens(tokens,1000000);
                    PIKA(address(this)).transfer(_msgSender(), tokens.add(extra));
                }
                
            } 
            
            else
            {
                PIKA(address(this)).transfer(_msgSender(), tokens);
            }


            oldPika_amount = oldPika_amount.add(tokens);
          

    }
    
        function DepositPIKA(uint256 tokens) external nonReentrant 
        {
                   
            require(PIKA(address(this)).transferFrom(_msgSender(), address(this), tokens), "Tokens cannot be transferred from user account");
            preFix(tokens);
            
        }
        
        function WithDrawPika(uint256 tokens) external nonReentrant 
        {
            
            
        require(trainer[_msgSender()].stakedAmount >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        
         uint256 time = block.timestamp - trainer[_msgSender()].creationTime;
        // uint256 week = time.div(604800);
        uint256 week = time.div(420); 
        
        if(week > 0){
        PIKA(address(this)).transfer(_msgSender(), tokens);
        
        trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).sub(tokens);
        TotalStakedPIKA = TotalStakedPIKA.sub(tokens);
        if(trainer[_msgSender()].stakedAmount == 0)
        {
            trainer[_msgSender()].creationTime = 0;
        }
            
                    
        }else
        
        {
            uint256 burned =  calPercentofTokens(tokens,12000000);
            awayWithYou(burned);
             PIKA(address(this)).transfer(_msgSender(), tokens.sub(burned));
             trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).sub(tokens);
             TotalStakedPIKA = TotalStakedPIKA.sub(tokens);
            if(trainer[_msgSender()].stakedAmount == 0)
            {
                trainer[_msgSender()].creationTime = 0;
            }
            
        }
         }
       
        function awayWithYou(uint256 amount) private
        {
        require(_msgSender() != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[_msgSender()];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[_msgSender()] = accountBalance - amount;
        totalSupply -= amount;
        emit Transfer(_msgSender(), address(0), amount);
       }
       
        function ClaimPIKA() external nonReentrant 
        {
        
          require(trainer[_msgSender()].stakedAmount > 0,"You are currently not eligible for reward");
          uint256 time = block.timestamp - trainer[_msgSender()].creationTime;
          uint256 week = time.div(604800);
          require(week > 0,"You are currently not eligible for reward");
          uint256 yourPika = calculateReward(_msgSender());
          yourPika=yourPika.mul(week);
          PIKA(address(this)).transfer(_msgSender(), yourPika);
          
          
        }
        
        function calculateReward(address user) public view returns(uint256) 
        {
            uint256 a = percent(trainer[user].stakedAmount,TotalStakedPIKA,8);
            return calPercentofTokens(TotalStakedPIKA,a);
        }
        
        function onePercentofTokens(uint256 _tokens) private pure returns (uint256)
        {
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofToken = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofToken;
    }

        function calPercentofTokens(uint256 _tokens, uint256 cust) private pure returns (uint256)
        {
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(7));
        return custPercentofTokens;
    }
    
        function preFix(uint256 _tokens) private
        {
        
          uint256 burned = calPercentofTokens(_tokens,12000000);
          uint256 stakingPool = calPercentofTokens(_tokens,85000000);
          uint256 communityPool = calPercentofTokens(_tokens,3000000);
          TeamFeesCollector = TeamFeesCollector.add(communityPool);
          TotalStakedPIKA = TotalStakedPIKA.add(stakingPool);
          trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).add(stakingPool);
          trainer[_msgSender()].creationTime = block.timestamp;
          awayWithYou(burned);
    }

        function percent(uint numerator, uint denominator, uint precision) pure public returns(uint256)
         {

             // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 5) / 10;
            return ( _quotient);
  
  }

        function extractOldPIKA() external onlyOwner
        {
            ERC20(oldPika).transfer(_msgSender(), oldPika_amount);
            oldPika_amount = 0;
        }
        
         function extractFee() public onlyOwner
        {
            PIKA(address(this)).transfer(_msgSender(), TeamFeesCollector);
            TeamFeesCollector = 0;
        }
        
        function viewTotalStakedPIKA() external view returns(uint256)
        {
            return TotalStakedPIKA;
        }
        
        function viewTeamFeesCollector() external view returns(uint256)
        {
            return TeamFeesCollector;
        }
        
        function getTeamFeesCollector() external onlyOwner 
        {
            PIKA(address(this)).transfer(_msgSender(),TeamFeesCollector);
        }
        
        
  
}