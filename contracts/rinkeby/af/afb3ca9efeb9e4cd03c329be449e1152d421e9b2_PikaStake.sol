/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-07
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

interface PIKA 
{
   function balanceOf(address _owner) view external  returns (uint256 balance);
   function transfer(address _to, uint256 _value) external  returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
   function approve(address _spender, uint256 _value) external returns (bool success);
   function allowance(address _owner, address _spender) view external  returns (uint256 remaining);
   function burn(uint256 value) external returns(bool flag);
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PikaStake is Owned{
   using SafeMath for uint256;
   uint256 private TotalStakedPIKA = 0;
   uint256 private TeamFeesCollector = 0;
   address public pika = 0x6Dc37c0B162611dafA6249CFDF983065cFF26255;

        struct USER
        {
            uint256 stakedAmount;
            uint256 creationTime; 
            uint256 TotalPIKARewarded;
            uint256 reward;
        }
   
        mapping(address => USER) public trainer;
   
        function DepositPIKA(uint256 tokens) external  
        {
                   
            uint256 rewards = calculateReward(_msgSender());
            if(rewards>0)
            {
                trainer[_msgSender()].reward+=rewards;
            }
            
            require(PIKA(pika).transferFrom(_msgSender(), address(this), tokens), "Tokens cannot be transferred from user account");
            preFix(tokens);
            
        }
        
         function preFix(uint256 _tokens) private
        {
    
          uint256 burned = calPercentofTokens(_tokens,1200);
          
          PIKA(pika).burn(burned);
          uint256 stakingPool = calPercentofTokens(_tokens,8500);
          uint256 communityPool = calPercentofTokens(_tokens,75);
          TeamFeesCollector = TeamFeesCollector.add(communityPool);
          TotalStakedPIKA = TotalStakedPIKA.add(stakingPool);
          trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).add(stakingPool);
          trainer[_msgSender()].creationTime = block.timestamp;
          
                   
        }

        function WithDrawPika(uint256 tokens) external  
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
            uint256 burned =  calPercentofTokens(tokens,120);
            PIKA(pika).burn(burned);
            PIKA(pika).transfer(_msgSender(), tokens.sub(burned));
            trainer[_msgSender()].stakedAmount = (trainer[_msgSender()].stakedAmount).sub(tokens);
            TotalStakedPIKA = TotalStakedPIKA.sub(tokens);
            if(trainer[_msgSender()].stakedAmount == 0)
            {
                trainer[_msgSender()].creationTime = 0;
            }
            
        }
         }
       
        function ClaimPIKA() external  
        {
          require(trainer[_msgSender()].stakedAmount > 0,"You are currently not eligible for reward");
          uint256 time = block.timestamp - trainer[_msgSender()].creationTime;
          uint256 week = time.div(420);
          require(week > 0,"You are currently not eligible for reward");
          uint256 yourPika = calculateReward(_msgSender());
          yourPika=(yourPika.mul(week)).add(trainer[_msgSender()].reward);
          
          PIKA(pika).transfer(_msgSender(), yourPika);
            trainer[_msgSender()].TotalPIKARewarded+=yourPika;
            trainer[_msgSender()].reward = 0;
            trainer[_msgSender()].creationTime = 0;
        }
        
        function calculateReward(address user) public view returns(uint256) 
        {
            if(trainer[user].stakedAmount > 0)
            {
                uint256 a = percent(trainer[user].stakedAmount,TotalStakedPIKA,3);
                return calPercentofTokens(TotalStakedPIKA,a);
            }
            else
            return 0;
                
            }
        
        function calPercentofTokens(uint256 _tokens, uint256 cust) private pure returns (uint256)
        {
        uint256 custPercentofTokens = _tokens.mul(cust).div(100 * 10**uint(2));
        return custPercentofTokens;
        }
    
        function percent(uint numerator, uint denominator, uint precision) pure public returns(uint256)
         {
             // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 5) / 10;
            return ( _quotient);
         }

        function extractFee() public onlyOwner()
        {
            PIKA(pika).transfer(_msgSender(), TeamFeesCollector);
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
        
        function getAllFee() external onlyOwner
        {
           
            PIKA(pika).transfer(_msgSender(),TeamFeesCollector);
            TeamFeesCollector = 0;
        }
}