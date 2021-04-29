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

interface pika {
    
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function transfer(address _to, uint256 _value) external  returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   function transferFromThunder(address _from, address _to, uint256 _value) external  returns (bool success);
   function thunderFunc(address _from, uint256 _value) external;
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
}

interface thunder {
    
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


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract PIKA2Thunder is Context, ReentrancyGuard,Owned {
   using SafeMath for uint256;
   address PIKA = 0x5b4f0209D8110396bD370950136eDF896A33e824;
   address Thunder = 0x61C2A5B456779c94B431967aa57C4e3682435B5D;
   uint256 private TotalStakedPIKA = 0;
   uint256 private TeamFeesCollector = 0;
   uint256 private LiqPool = 0;
       
        struct USER
        {
            uint256 stakedAmount;
            uint256 creationTime; 
            uint256 TotalThunderRewarded;
        }
   
        mapping(address => USER) public trainer;
   
        function DepositPIKA(uint256 tokens) external nonReentrant 
        {
                   
            require(pika(PIKA).transferFromThunder(_msgSender(), address(this), tokens), "Tokens cannot be transferred from user account");
            preFix(tokens);
            
        }
        
        function WithDrawPika(uint256 tokens) external nonReentrant 
        {
            
            
        require(trainer[_msgSender()].stakedAmount >= tokens && tokens > 0, "Invalid token amount to withdraw");
        
        
         uint256 time = block.timestamp - trainer[_msgSender()].creationTime;
        // uint256 week = time.div(604800);
        uint256 week = time.div(420); 
        
        if(week > 0){
        thunder(Thunder).transfer(_msgSender(), tokens);
        
        trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).sub(tokens);
        TotalStakedPIKA = TotalStakedPIKA.sub(tokens);
        if(trainer[_msgSender()].stakedAmount == 0)
        {
            trainer[_msgSender()].creationTime = 0;
        }
            
                    
        }else
        
        {
            uint256 burned =  calPercentofTokens(tokens,25000000);
            thunder(Thunder).transfer(_msgSender(), tokens.sub(burned));
            trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).sub(tokens);
            TotalStakedPIKA = TotalStakedPIKA.sub(tokens);
            if(trainer[_msgSender()].stakedAmount == 0)
            {
                trainer[_msgSender()].creationTime = 0;
            }
            
        }
         }
       
     
        function ClaimPIKA() external nonReentrant 
        {
        
          require(trainer[_msgSender()].stakedAmount > 0,"You are currently not eligible for reward");
          uint256 time = block.timestamp - trainer[_msgSender()].creationTime;
          uint256 week = time.div(604800);
          require(week > 0,"You are currently not eligible for reward");
          uint256 yourThunder = calculateReward(_msgSender());
          yourThunder=yourThunder.mul(week);
          thunder(Thunder).transfer(_msgSender(), yourThunder);
          
        }
        
        function calculateReward(address user) public view returns(uint256) 
        {
            uint256 a = percent(trainer[user].stakedAmount,TotalStakedPIKA,8);
            
            uint256 yourThunder= calPercentofTokens(TotalStakedPIKA,a);
            yourThunder = yourThunder.div(10000);
            return yourThunder;
        }
        
        function calPercentofTokens(uint256 _tokens, uint256 cust) private pure returns (uint256)
        {
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(7));
        return custPercentofTokens;
    }
    
        function preFix(uint256 _tokens) private
        {
          uint256 stakingPool = calPercentofTokens(_tokens,93333333);
          uint256 liqPools = calPercentofTokens(_tokens,1333333);
          uint256 TeamChar = calPercentofTokens(_tokens,666666);
          TeamFeesCollector = TeamFeesCollector.add(TeamChar);
          LiqPool = LiqPool.add(liqPools);
          TotalStakedPIKA = TotalStakedPIKA.add(stakingPool);
          trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).add(stakingPool);
          trainer[_msgSender()].creationTime = block.timestamp;
    }

        function percent(uint numerator, uint denominator, uint precision) pure public returns(uint256)
         {

             // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 5) / 10;
            return ( _quotient);
  
  }

         function extractFee() public onlyOwner
        {
            pika(PIKA).transfer(_msgSender(), TeamFeesCollector);
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
            pika(PIKA).transfer(_msgSender(),TeamFeesCollector);
        }
        
        function viewLiqPoolFunds() external view returns(uint256)
        {
            return LiqPool;        }
        
        function getLiqPoolFunds() external onlyOwner 
        {
            pika(PIKA).transfer(_msgSender(),LiqPool);
        }
  
}