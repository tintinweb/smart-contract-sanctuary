/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity >=0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

pragma solidity >=0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
         
     ____                                    ______      __            
   / __ \___  _________ _   _____  _____   /_  __/___  / /_____  ____ 
  / /_/ / _ \/ ___/ __ \ | / / _ \/ ___/    / / / __ \/ //_/ _ \/ __ \
 / _, _/  __/ /__/ /_/ / |/ /  __/ /       / / / /_/ / ,< /  __/ / / /
/_/_|_|\___/\___/\____/|___/\___/_/       /_/  \____/_/|_|\___/_/ /_/ 
  / ___// /_____ _/ /__(_)___  ____ _   _   __   ( __ ) / __ \        
  \__ \/ __/ __ `/ //_/ / __ \/ __ `/  | | / /  / __  |/ / / /        
 ___/ / /_/ /_/ / ,< / / / / / /_/ /   | |/ /  / /_/ // /_/ /         
/____/\__/\__,_/_/|_/_/_/ /_/\__, /    |___/   \____(_)____/          
             ____       ____/____/      __  _                         
  __/|___/|_/ __ \___  / __/ /__  _____/ /_(_)___  ____  __/|___/|_   
 |    /    / /_/ / _ \/ /_/ / _ \/ ___/ __/ / __ \/ __ \|    /    /   
/_ __/_ __/ _, _/  __/ __/ /  __/ /__/ /_/ / /_/ / / / /_ __/_ __|    
 |/   |/ /_/ |_|\___/_/ /_/\___/\___/\__/_/\____/_/ /_/ |/   |/       
                                                                     
/**
 * @title RCVR Token
 * @dev RCVR Token Staking requires some tweaks based off the original concept.
 * 2.0
 * Contains Game protection
 * Disable rebase
 * Remove Stake (Require wallet balance = stake)
 * 3.0
 * Configure reward payouts to treasury address. The treasury address will be
 * the contract which creates the LP
 * 4.0
 * Added safetoken configuration to track tokens on PanceakeSwap
 * Added aggressive stake pruning -> No RCVR in address, remove stake and wipe rewards.
 * Added the management of rewards based on total wallet sizes -> Whale Limiter
 * Added a manual removal of stakeholders if needs be (only triggered by Owner)
 * Added Test Functionalty for migration to block users via virus token
 * 5.0
 * Added the % rewards based on LP % owned.
 * Added compounding of Rewards!
 * Cleaned up up existing code and added getBonus (LP rewards)
 * 6.0
 * Due to the increase of ciculating supply, the community want a burn token feature.
 * Burns will happen at rebase time (24 hours)
 * Burns can be done manually (RCVR Contract by owner/timer)
 * Burn directly to the 0 Address - This does not reduce total supply
 * 8.0 + 7.0
 * Added in ability for token giving to charity
 * Added in refelction of BNB Fees to holders over $ amount of RCVR
 * Consolodated staking pools into a single pool
 * 
 * 
 */

pragma solidity ^0.5.0;


interface RCVR {
    ////Interface to RCVR
  function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address _to, uint256 _tokens) external returns (bool);
}
    ///Interface to retrieve prices from Price Checkers
interface RCVRPriceFeed {
    function getTokenPrice(address tokenAddress) external view returns (uint);
}
interface ChainlinkPriceFeed {
    function getSafeStakePrice() external view returns (int);
}
interface RCVRLP {
    ////Interface to RCVRlp
  function balanceOf(address owner) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}
 


contract RCVRStaking is Context, Ownable {
 
    address public RCVRAddress = 0x26D4552879CdCc32599E2Ff1c1e2A438d5c5323e;
    address public Owner;
    address public liquidtycontract = 0x0E26a3EFDBC7584f791fc9eDebdFD126D6A29507;
    address public burnaddress = 0x000000000000000000000000000000000000dEaD;
    address public USDTAddress = 0x55d398326f99059fF775485246999027B3197955;
    address public stakingaddress;
    address payable public autoLPcontract = 0x0E26a3EFDBC7584f791fc9eDebdFD126D6A29507; //Contract for autpsend of Eth
    address payable public payee;
    address payable public charity = 0x8B99F3660622e21f2910ECCA7fBe51d654a1517D;
    address public rcvrlpcontract = 0x759F4CC99Ab7f2519dD17F681b8bCCfd78C4e1F3;
    uint private safeaccumulatednegetivereabase;
    uint private riskyaccumulatednegetiverebase;
    int private safeoldprice;
    uint256 private riskyoldprice;
    uint public safepercentage = 400; // percentage removed/added from safe bet - Default = 0.25%
    uint public riskypercentage = 400; // percentage removed/added from safe bet - Default = 0.25%
    uint public riskymultiplier = 1; // Multiplication multiplier for addition/removal of RiskyContract
    uint public forcesafecost = 10000000000000000; //0.01 Eth by default in Wei
    uint public treasuryrcvr = 30; //default to 5%
    uint public treasurybnbfee = 2000000000000000; //Default to 0.005
    uint public safeinterval = 75; //Default interval for safe timer
    uint public riskyinterval = 85; //Default interval for risky timer
    bool public rewarddistribution = true; ///Enable/Disable Rewards
    bool public forceriskyenabled; //a Granular Change to break the force distribution at the pool level
    bool public forcesafeenabled;  //a Granular Change to break the force distribution at the pool level
    bool public safestakingenabled = true; ///Enable/Disable Safe Staking
    bool public burntokens; //Default set to disabled
    bool public burnontimer; //Burn on Timer trigger
    bool public autotransfer; //AutoTransfer of ETH balance to LP contract
    bool public directburntozero; //Option to send tokens directly to burn address
    bool public lastrebasewassafe; //bool to notify what the last rebase was to we can get 1 then another getSafeStakePrice
    bool public enablereflect=true;
    uint public burnmode = 1; //Set the burnmode for the tokens themselves /Default burn of once every 24 hours.
    uint public sequentialrisky = 1; //The number of Risky rebases allowed in a row
    uint public burnpercentage = 2; //burn % for tokens
    uint public totalburnt;
    uint public USDTLimit = 100; //This is the amount of RCVR in USDT the user needs to hold
    uint public numhoursforreflect = 24; //Default = 4. Valid options are 2,4,8,12,24
    uint public numreflectors; //number of addresses which BNB was divided by
    uint256 public safestakemaxuserlimit = 200;
    uint256 public riskystakemaximumuserlimit = 150;
    uint public totalsaferewardstaken;  //Accumulated claimed safe rewards
    uint public totalriskyrewardstaken; //Accumulated claimed risky rewards
    uint public amounttotimer;
    uint public amounttoreflectors;
    uint public amounttoliquidty;
    uint public amounttocharity;
    bool private lastriskyrebase;
    bool public whalelimiter = true;  ////Introducing a way to cap the reward if a whale is slowly bleeding off funds///
    uint public whalelimit = 75e18; //Default to 100
    uint public whalereward = 75e18; //Limit the reward payout to 100
    uint public whalelimitrisky = 125e18; //Default to 125
    uint public whalerewardrisky = 125e18; //Limit the reward payout to 125
    bool public aggresivesafe = true; //Used to enable pruning on stake holders to ensure that empty stakeholders are cleared out
    bool public aggresiverisky = true; //Used to enable pruning on stake holders to ensure that empty stakeholders are cleared out
    uint public amountoftokens; //Amount of Tokens needed to qualify for reflection
    bool private lastsaferebase;
    bool private usechainlink; //Default to use Chainlink for Safe Price Feed
    bool private viruscheckenabled;
    bool private rcvrblockenabled;
    bool public safetimerenabled;
    bool public riskytimerenabled;
    bool public classicsaferewardon;
    bool public needtoburn;
    uint public hoursbetweenreflection = 24;
    uint public lastreflection;
    bool public classicriskyrewardon;
    bool public treasurysaferewardon = true; //new trasury based rewards
    bool public treasuryriskyrewardon = true; //new trasury based rewards
    bool public enablesafepruning = true;
    bool public enableriskypruning = true;
    bool public enableLPrewards = true; //enable/disable LP rewards
    bool public enablecompounding = true; //Variable for compounding
    bool public reflectionontimer; //Enable refelction on the timer
    bool public sendtocharity;
    uint public prevriskyrebase;
    uint public prevsaferebase;
    uint public lastburnamount;
    uint public timeoflastburn;
    uint private timergas = 5;
    uint public totalrewards = 0;
    uint public amounttoburn;
    uint public riskyrebasecounter;
    int private requiredsafe = 4;
    int private requiredrisky = 4;
    int public riskystakemultiplier = 3;
    int public numsaferemoved = 0;  //Number of addresses removed from safe stake pool via pruning
    int public numriskyremoved = 0; //Number of addresses removed from risky stake pool via pruning
    bool private rebaseprotection;
    bool public classicsaferebase;
    bool public classicriskyrebase;
    uint private temp;
    uint private temp2;
    uint private temp3;
    //NB Addresses/////////
    address private rcvrpricefeed;
    address private chainlinkfeed;
    address public riskytoken=0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3;
    address payable private timeraddress;
    address public safetoken=0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private rebaseprotectioncontract;
    /////////Mappings ///////////////////////
    mapping(address => uint256) internal rewards; //SafeBet Rewards Collection
    mapping(address => uint256) internal stakes; ///Safe Stake Pool
    mapping(address => uint256) internal originalsafe; ///Original address balance of RCVR at stake time
    mapping(address => uint256) internal originalrisky; ///Original address balance of RCVR at stake time
    mapping(address => bool) internal canreflect; //Users who can reflect
    address payable[] internal stakeholders; //Dynamic array to keep track of users who are staking RCVR in SafeStakePool
    int safetestprice =0;
    uint riskytestprice = 0;
    
    
  using SafeMath for uint;
  
  
  constructor () public {
      Owner = msg.sender; //Owner of Contract
      timeoflastburn = block.timestamp; //Set the inital value
      lastreflection = block.timestamp; //Sets the initial reflection time
      safeoldprice = 1;
      riskyoldprice = 1;
      stakingaddress = address(this);
      
  }
  ///Configure burn/misc options
  function configParams(uint option,bool _onoroff,uint _mode,address payable _sendto) public onlyOwner
  {
      if(option==1)
      {
          burntokens = _onoroff;
      }
      if(option==2)
      {
          burnmode = _mode;
          /*
          1 - Burnmode - once every 24 hours
          2 - Burn(24hr) with percentage
          */
      }
      if(option==3)
      {
          burnpercentage = _mode;
          
      }
      if(option==4)
      {
          burnontimer = _onoroff;
      }
      if(option==5)
      {
          timeoflastburn = _mode;
      }
      if(option==6)
      {
          timeoflastburn = _mode;
      }
      if(option==7)
      {
          directburntozero = _onoroff;
      }
       if(option==8)
      {
          enablereflect = _onoroff;
      }
       if(option==9)
      {
          charity = _sendto;
      }
       if(option==8)
      {
          sendtocharity = _onoroff;
      }
       if(option==9)
      {
          sequentialrisky = _mode;
      }
       if(option==10)
      {
          hoursbetweenreflection = _mode;
      }
      if (option==11)
      {
          reflectionontimer = _onoroff;
      }
      
      
      
  }
  
  function burnTokensTimer() private
  {
     if(now > timeoflastburn + 1 days)
     {
     needtoburn =true;
     uint burntemp =0;
     uint burnpercenttemp =0;
     burntemp = burntemp.add(totalsaferewardstaken);
     burntemp = burntemp.add(totalriskyrewardstaken);
     if (burntemp>0)
     {
     if (burnmode==1)
     {
         
         amounttoburn = burntemp;
     }
     if (burnmode==2)
     {
         burnpercenttemp = burntemp.div(burnpercenttemp);
         amounttoburn = burnpercenttemp;
         
     }
     if (directburntozero==true) //direct burn to zero address - Does not resduce total supply
     {
     RCVR(RCVRAddress).transfer(burnaddress,amounttoburn);
     //reset and set totals//
     needtoburn=false;
     totalriskyrewardstaken = 0;
     totalsaferewardstaken = 0;
     lastburnamount = amounttoburn;
     timeoflastburn = block.timestamp;
     totalburnt = totalburnt.add(amounttoburn);
     amounttoburn =0;
     /////////
     }
     }
  }
  }
  function completeburn(bool _done) public onlyOwner
  {
     if(_done==true)
      {
     //reset and set totals//
     needtoburn=false;
     totalriskyrewardstaken = 0;
     totalsaferewardstaken = 0;
     lastburnamount = amounttoburn;
     timeoflastburn = block.timestamp;
     totalburnt = totalburnt.add(amounttoburn);
     amounttoburn =0;
     /////////
      }
  }
  ///set the RCVR LP reward variables///
  function setLpCOMPRewardParams(uint option,bool _onoroff,uint value,address _lpcontract,address payable _lp) public onlyOwner
  {
      if(option==1)
      {
          enableLPrewards = _onoroff; //Enables the LP rewards
      }
      if(option==2)
      {
          rcvrlpcontract = _lpcontract; //set the LP contract
      }
      if(option==3)
      {
          enablecompounding = _onoroff;
      }
      if(option==4)
      {
          autotransfer = _onoroff;
      }
      if(option==5)
      {
         autoLPcontract = _lp;
      }
      if(option==6)
      {
      liquidtycontract = _lp;
      }
      
  }
  ///Sets the BNB Fee and RCVR fee to be transferred out////
  function setTreasuryFees(int option,uint _value) public onlyOwner
  {
      if (option==1) //set the BNB Fee
      {
          treasurybnbfee = _value;
      }
      if (option==2) //set the rate of RCVR to be pulled out
      {
          treasuryrcvr = _value;
      }
      
  }
  
   //Enables and Manages the Whale Limiter
  function setWhaleParams(uint option,bool _onoroff,uint value) public onlyOwner{
      if (option==1)
      {
          whalelimiter = _onoroff; //Enables the what Limiter
      }
      if (option==2)
      {
          whalelimit = value; //Sets the amount of tokens to be the limit
      }
      if (option==3)
      {
          whalereward = value; //Sets the amount of reward rcvr
      } 
      if (option==4)
      {
          whalerewardrisky = value; //Sets the amount of reward rcvr(risky)
      } 
      if (option==5)
      {
          whalelimitrisky = value; //Sets the amount of reward rcvr(risky)
      } 
      
  }
  
   ///Sets the contract address of the RCVR Token//////
  function setRCVRAddress(address RCVRAddress_) public onlyOwner {
    RCVRAddress = RCVRAddress_;
  }

   ///Method to disable the forced rebase at the pool level//////
  function enableDisableForcedRebase(uint pool,bool onoff) public onlyOwner {
    if (pool==1) //Safe
    {
        forcesafeenabled = onoff;
    }
    if (pool==2) //Risky
    {
        forceriskyenabled = onoff;
    }
  }
  function setRiskyToken(address _newrisky) public onlyOwner{
      riskytoken = _newrisky;
  }
  function setSafeToken(address _newsafe) public onlyOwner{
     safetoken = _newsafe;
  }
  
 
   //Function to set reward percentages
    function setRewardPercentages(uint pool,uint _rewardpercentage) public onlyOwner{
        if (pool ==1) //Safe pool
        {
            safepercentage = _rewardpercentage;
        }
        if (pool ==2) //Risky percentage
        {
            riskypercentage = _rewardpercentage;
        }
    }
    ///Function to set the allowed address to do rebases
    function setTimerAddress(address payable _timeraddress) public onlyOwner{
        timeraddress = _timeraddress;
    }
    
    ///Function to set timer interval
    function setTimerIntervals(uint _minutes) public onlyOwner{
        safeinterval = _minutes;
    }
    ///Function to enable/disable the timers for each pool
    function onoffTimer(bool _enabled) public onlyOwner{
        safetimerenabled = _enabled;
    }
    ////Function to retrieve last time of a rebase with a "change in"
    function NextRebase() public view returns (uint){
        uint temp = 0;
        temp = prevsaferebase;
        
        
        return temp;
    }
    
     ////High Level function to enable each staking pool if required////
    function EnabledDisableStaking(bool EnableDisable_) public onlyOwner{
                    safestakingenabled = EnableDisable_;
       }
    ///Function to set the max user limit of each pool////////
    ///This is done to ensure that the arrays do not get too large
    function setStakeUserLimits(uint256 _maxusers) public onlyOwner
    {
        safestakemaxuserlimit == _maxusers;
        
        
    }
    
    ///////////////////////////
    function SetRCVRPriceFeed(address pricefeedaddress_) public onlyOwner{
        ////Set the pricefeed address for the Riksy Token Stake Pool////
        rcvrpricefeed = pricefeedaddress_;
        ////set the inital old pricefeedaddress_// Should only be done at contract initialization for start price of RCVR or a Token tracking change
        riskyoldprice = RCVRPriceFeed(rcvrpricefeed).getTokenPrice(riskytoken);  //Sets the base starting price
        
    }
    function SetSafePriceFeed(address pricefeedaddress_,bool _usechainlink) public onlyOwner{
        if (_usechainlink == true) //Use Chainlink for price feed for SafeStakePool
        {
        ////Set the pricefeed address for the Safe Token Stake Pool////
        chainlinkfeed = pricefeedaddress_;
        usechainlink = _usechainlink;
        ////set the inital old pricefeedaddress_// Should only be done at contract initialization for start price of RCVR
        safeoldprice = ChainlinkPriceFeed(chainlinkfeed).getSafeStakePrice();  //Sets the base starting price
        }
        if (_usechainlink == false) //Use Uniswap and a community selected token for price feed
        {
        usechainlink = _usechainlink;
        safetoken = pricefeedaddress_; //Set the Token to be used for price feed for Safe Pool via Uniswap
        safeoldprice = int(RCVRPriceFeed(rcvrpricefeed).getTokenPrice(safetoken));
        }
        
    }
    ///function to enable or disable pruning of the stake Pool
    function pruningEnableDisable(bool _onoroff) public onlyOwner{
        enablesafepruning = _onoroff;
        
        
    }
     //////Function to set the Cost of the forced "Distribution"//////////////
   /////Convert to Wei first!////////////////////
   function setForceCost(uint costinwei) public onlyOwner{
          forcesafecost = costinwei;
       
   }
  
  ////////////STAKING FUNCTIONS//////////
    //Stake pools are community driven and besides the normal safe pools, the riskier pools will be tied to high risk tokens///
    //The users of the high risk pool can decide to trigger a "Rewards Distribution", which costs the user 0.02 ETH and 0.01 ETH (safe), this will then be shared by the people in both pools % of what they have staked//
    //A Distribution causes a burn or decrease in the stake pool at that moment in time and sets the baseline back to 0//
    
    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
    
   function isStakeholder(address _address) public view returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }
   

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address payable _stakeholder) private
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }
   

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder) private
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }
  
   /////Admin functions to manage the users if needs be//
   /////This is one step further to prune the number of stakers///
   function forceRemoveStakeholder(address _stakeholder) public onlyOwner
   {
       
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
           rewards[_stakeholder]=0; //Set the reward to 0
       }
      
   }
   
   /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of RCVR staked.
    */
   function stakeOf(address _stakeholder) public view returns(uint256) 
   {
       uint256 temp = 0;
       temp = stakes[_stakeholder];
       return temp;
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes() public view returns(uint256){ ///pool 1 = Safe pool 2 = Risky
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
       
       
       return _totalStakes;
   }
   
   /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stake The size of the stake to be created.
    */
   function createSafeStake(uint256 _stake) public
   {
       (bool currentstakeholder,) = isStakeholder(msg.sender);
       require(safestakingenabled == true, "SS(X))");
       require(stakeholders.length < safestakemaxuserlimit, "MS(X))");
       require(RCVR(RCVRAddress).balanceOf(msg.sender) >= _stake,"2LittleRCVRtoCoverStake(S)");
       if (currentstakeholder==true)
       {
       require(_stake + stakes[msg.sender] <= RCVR(RCVRAddress).balanceOf(msg.sender),"CompleteStakeTooLarge(s)");
       ////Gaming protection//
       originalsafe[msg.sender] = originalsafe[msg.sender].add(_stake);
       ///////////////////////////////////////////////////////////////
       }
       if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
       
   }
   
    /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
   function removeStake(uint256 _stake) public
   {
       require (RCVR(RCVRAddress).balanceOf(msg.sender) >= stakes[msg.sender],"SRemoveFailed-WMES");
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) //Remove entire stake and rewards
       {
           removeStakeholder(msg.sender);
           //Frictionless staking///
           _stake = rewards[msg.sender]; ///Only do the rewards//
           rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
           RCVR(RCVRAddress).transfer(msg.sender,_stake);
           
           
          
        }
       
       
   }
   
    function withdrawTreasuryRewards()
       public payable
   {
       
       uint reward;
       uint tempreward;
       uint bonus;
       
       require(msg.value >= treasurybnbfee,"F2Low");
       require(treasurysaferewardon==true,"TSR(X)");
       reward = rewards[msg.sender];
       require (RCVR(RCVRAddress).balanceOf(msg.sender) >= stakes[msg.sender],"B2lo4R(s)");
       rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
       tempreward = reward.div(treasuryrcvr);
        reward = reward.sub(tempreward);
     
      if(enableLPrewards==true)
      {
          bonus = getBonus(reward);
          if (bonus > 0)
          {
      reward = reward.add(bonus); //Add the final figure
          }
          }
          
      
      RCVR(RCVRAddress).transfer(msg.sender,reward);
      //Setup Autotransfer for ETH/BNB and RCVR for AutoLP Creation
      if (autotransfer==true)
      {
          if(address(this).balance > 0)
          {
          autoLPcontract.transfer(address(this).balance); //transfer BNB blance out
          }
          RCVR(RCVRAddress).transfer(autoLPcontract,tempreward); //transfer small amount to liquidty contract
          
      }
      else{
      RCVR(RCVRAddress).transfer(liquidtycontract,tempreward); //transfer small amount to liquidty contract
      }
      totalsaferewardstaken += reward; //Total for burn function
       
   }
   function getBonus(uint _reward) private returns (uint) //function to get the LP Bonus
   {
       uint bonus = 0;
       uint templpbalance = RCVRLP(rcvrlpcontract).balanceOf(msg.sender);
          if (templpbalance > 0)
          {
          
      uint temptotalsupply = RCVRLP(rcvrlpcontract).totalSupply();
      /////Reward calculation///
      uint temptotal = temptotalsupply.div(100); //break the total supply into 10% chunks
      bonus = _reward.div(100);
      if (templpbalance > 0 && templpbalance < temptotal.mul(1))  //1%
      {
          bonus = bonus.mul(1);
      }
      if (templpbalance > temptotal.mul(1) && templpbalance < temptotal.mul(2))  //2%
      {
         bonus = bonus.mul(2);
      }
      if (templpbalance > temptotal.mul(2) && templpbalance < temptotal.mul(3))  //3%
      {
          bonus = bonus.mul(3);
      }
      if (templpbalance > temptotal.mul(3) && templpbalance < temptotal.mul(4))  //4%
      {
          bonus = bonus.mul(4);
      }
      if (templpbalance > temptotal.mul(4) && templpbalance < temptotal.mul(5))  //5%
      {
          bonus = bonus.mul(5);
      }
      if (templpbalance > temptotal.mul(5) && templpbalance < temptotal.mul(6))  //6%
      {
          bonus = bonus.mul(6);
      }
      if (templpbalance > temptotal.mul(6) && templpbalance < temptotal.mul(7))  //7%
      {
          bonus = bonus.mul(7);
      }
      if (templpbalance > temptotal.mul(7) && templpbalance < temptotal.mul(8))  //8%
      {
          bonus = bonus.mul(8);
      }
      if (templpbalance > temptotal.mul(8) && templpbalance < temptotal.mul(9))  //9%
      {
          bonus = bonus.mul(9);
      }
      if (templpbalance > temptotal.mul(9) && templpbalance <= temptotal.mul(10))  //10%
      {
          bonus = bonus.mul(10);
      }
      if (templpbalance > temptotal.mul(10) && templpbalance <= temptotal.mul(20))  //15%
      {
          bonus = bonus.mul(15);
      }
      if (templpbalance > temptotal.mul(20) && templpbalance <= temptotal.mul(30))  //25%
      {
          bonus = bonus.mul(20);
      }
      if (templpbalance > temptotal.mul(30) && templpbalance <= temptotal.mul(40))  //35%
      {
          bonus = bonus.mul(30);
      }
      if (templpbalance > temptotal.mul(40) && templpbalance <= temptotal.mul(50))  //45%
      {
          bonus = bonus.mul(40);
      }
      if (templpbalance > temptotal.mul(50) && templpbalance <= temptotal.mul(60))  //55%
      {
          bonus = bonus.mul(50);
      }
      if (templpbalance > temptotal.mul(60) && templpbalance <= temptotal.mul(70))  //65%
      {
          bonus = bonus.mul(60);
      }
      if (templpbalance > temptotal.mul(70) && templpbalance <= temptotal.mul(80))  //75%
      {
          bonus = bonus.mul(70);
      }
      if (templpbalance > temptotal.mul(80) && templpbalance < temptotal.mul(100))  //90%
      {
          bonus = bonus.mul(80);
      }
      return bonus;
   }
   }
  
   function withdrawCompReward()
       public payable
   {
       require(enablecompounding==true,"CompOff");
       require(msg.value >= treasurybnbfee,"F2Low");
       uint temptotalsupply; //temp variable to hold totalsupply
       uint templpbalance; //temp to hold users LP balance
       uint tempstake;
       uint tempreward;
       uint reward;
       uint bonus;
       uint temptotal;
       require(treasurysaferewardon==true,"TSRC(X)");
       reward = rewards[msg.sender];
       require (RCVR(RCVRAddress).balanceOf(msg.sender) >= stakes[msg.sender],"B2lo4R(s)");
       rewards[msg.sender] = 0; //Clear balance to ensure correct accounting
      ////Perform a check to ensure that balance is equal to original stak
      tempreward = reward.div(treasuryrcvr);
      reward = reward.sub(tempreward);
      templpbalance = RCVR(rcvrlpcontract).balanceOf(msg.sender);
      
     if(enableLPrewards==true)
      {
          bonus = getBonus(reward);
          if (bonus > 0)
          {
      reward = reward.add(bonus); //Add the final figure
          }
          }
          
      RCVR(RCVRAddress).transfer(msg.sender,reward);
      /////Compounding Feature!///////
      tempstake = stakes[msg.sender];
      tempstake = tempstake.add(reward);
      stakes[msg.sender] = tempstake;
      //Setup Autotransfer for ETH/BNB and RCVR for AutoLP Creation
      if (autotransfer==true)
      {
          if(address(this).balance > 0)
          {
          autoLPcontract.transfer(address(this).balance); //transfer BNB blance out
          }
          RCVR(RCVRAddress).transfer(autoLPcontract,tempreward); //transfer small amount to liquidty contract
          
      }
      else{
      RCVR(RCVRAddress).transfer(liquidtycontract,tempreward); //transfer small amount to liquidty contract
      }
      totalriskyrewardstaken += reward; //Total for burn function
       
       
   }
  
   //Function to move funds back out to Token Contract//
  //This is put in place to manage funds in the migration contract and be able to remove funds if needed///
  function returnRCVRTokens(bool _returnall,uint _amountOfRCVR) public onlyOwner{
     RCVR(RCVRAddress).transfer(RCVRAddress,_amountOfRCVR);
  }
 
    ///Function for user to check the amount of Staking rewards
    function rewardOf(address _stakeholder) public view returns(uint256)
   {
       return rewards[_stakeholder];
   }
    /////Functions to Verify total rewards for safe and Risky rewards
   function totalRewards() public view returns(uint256)  ////Safe Staking
   {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
       }
       return _totalRewards;
   }
   /////Function to correct the stake of a user if they need assistance -> The stake can ONLY be lowered not increased
   /////Due to the nature of frictionless, a user may sell their RCVR and then attempt to lower their stake, this could cause issues when withdrawing rewards
   
   function adjustTotalStaked(address _User,uint _newstake) public onlyOwner
   {
           require(stakes[_User] > _newstake, "Only-");
           stakes[_User] = _newstake;
       
   }
   /////////////////////NB Function to calculate rewards//////////////////
   /////////Calculation will be done on an hourly basis via the website/timer//////////////
   /////////Users can FORCE a reward calculation at any given time////////////////////////
   /////////When forced reward calculation is done, funds sent are then distributed//////
   function calculateReward(address _stakeholder)   ////Safe Bet
       public view
       returns(uint256)
   {
       return stakes[_stakeholder].div(safepercentage); // Returns value based at 1% by default
   }
   
   function calculateRiskyReward(address _stakeholder)  ////Risky Bet
       public view
       returns(uint256)
   {
       
       return (stakes[_stakeholder].div(riskypercentage)).mul(riskymultiplier); // Returns Value based at x% * multiplier
   }
   ////High Level Enable/Disable to stop distribution of rewards if needed/////
    function EnableDisableRewards(bool OnOrOff_) public onlyOwner
    {
        rewarddistribution = OnOrOff_;
    }
    
    ///Revised Rebase in order to implement gaming of the pools credit
   function rebase(bool _fromforced,bool _isRisky) private {
       bool negrebase = false;
       bool safesame = false;
       bool riskysame = false;
       bool RiskyReward;
       int safeprice = 0;
       
       
       if (_fromforced ==true)
       {
           RiskyReward = _isRisky;
       }
       //////logic to determine the last rebase
       //If last rebase was a safe one, then the next one will be a Risky one//
       if (lastrebasewassafe==true)
       {
           RiskyReward=true;
       }
       
       
       
       //////////////SafeBet//////////
       if (RiskyReward == false){
           if (usechainlink==true) ///Use Chainlink or Uniswap price feed.
           {
        safeprice = ChainlinkPriceFeed(chainlinkfeed).getSafeStakePrice();
       
        
           
           }
           if (usechainlink==false)
           {
         safeprice = int(RCVRPriceFeed(rcvrpricefeed).getTokenPrice(safetoken));
    
    
           }
         if (safeprice < safeoldprice){
             ////Negative rebase
             negrebase = true;
            
         }
         else if (safeprice == safeoldprice ){
             safesame = true;
         }
         ////Set the old price = to the new price
         safeoldprice = safeprice;
       }
       /////////////RiskyBEt//////////
       if (RiskyReward == true){
         uint riskyprice = RCVRPriceFeed(rcvrpricefeed).getTokenPrice(riskytoken);
       
        
         
         if (riskyprice < riskyoldprice){
             ////Negative rebase
             negrebase = true;
         }
         if (riskyprice == riskyoldprice){
             ////Positive rebase
             riskysame = true;
         }
         riskyoldprice = riskyprice;
       }
       /////////////////////Rewards calculation////////
       if (RiskyReward == false)  //////SafeBet Rewards
       {
           if (safesame == false) ///////Only proceed if the price has changed////
           {
            for (uint256 s = 0; s < stakeholders.length; s += 1){
             address stakeholder = stakeholders[s];
             uint256 reward;
             bool saferemoved = false; //Bool to handle if a stakeholder has been removed.
             ///////////////////////////////////////////////////////////////////
             ////IMPLEMENT GAME PROTECTION/////////////////////////////////////
             uint tempbalance = (RCVR(RCVRAddress).balanceOf(stakeholder)); //Get current balance of the wallet
             temp = stakes[stakeholder]; // Get current Stake
             temp2 = stakes[stakeholder]; // Get current Stake
             if (classicsaferebase==true) ///Use old style rebase
             {
               reward = calculateReward(stakeholder);
               if (whalelimiter==true)
               {
                   if(reward>=whalelimit)
                   {
                       reward = whalereward; //sets the reward at a cap!
                   }
               }
             }
             if (classicsaferebase==false) //// Use new style with game protection///
             {
             if(tempbalance >= stakes[stakeholder]) // Full 100% reward
             {
             reward = calculateReward(stakeholder);
             if (whalelimiter==true)
               {
                   if(reward>=whalelimit)
                   {
                       reward = whalereward; //sets the reward at a cap!
                   }
               }
             }
             temp = temp.div(5); //Due to there being no decimals in Solidty be divide the number equally
             temp = temp.mul(4); // Then multiplt to get 20/40/60/80 percent
             //90%
             if (tempbalance < stakes[stakeholder] && tempbalance >= temp)
             {
             reward = calculateReward(stakeholder);
             reward = reward.div(10);
             reward = reward.mul(9);
             if (whalelimiter==true)
               {
                   if(reward>=whalelimit)
                   {
                       reward = whalereward; //sets the reward at a cap!
                   }
               }
             }
             ///80% This is the threshold to remove stakes
             temp2 = temp2.div(5); //Due to there being no decimals in Solidty be divide the number equally
             temp2 = temp2.mul(4); // Then multiplt to get 20/40/60/80 percent
             if (tempbalance < temp2) // remove the user and zero rewards
             {
             rewards[stakeholder] =0; //Zero the reward
             removeStakeholder(stakeholder); //Remove the user
             stakes[stakeholder]=0; //Remove stakes entirely
             saferemoved = true; //Flag to ensure user reward is not processed;
             numsaferemoved += 1;
             }
             
             }
            ////////////////////////////////////////////////////////////////////
             if(saferemoved==false)
             {
               if (negrebase == true)
               {
                lastsaferebase = true; //Value for feedback to website
                if (rewards[stakeholder] >= reward) { //ensure that the users balance can ammodate the subtraction
                  rewards[stakeholder] = rewards[stakeholder].sub(reward); //subtract for negative rebase
                } else {
                  rewards[stakeholder] = 0;
                }
                safeaccumulatednegetivereabase += reward; ///accumulate the tokens for a manual burn!
               }
               if (negrebase == false)
               {
                    lastsaferebase = false; //Value for feedback to website
               rewards[stakeholder] = rewards[stakeholder].add(reward); //add for positive rebase
               }
             }
           
       }
       prevsaferebase = block.timestamp;
       lastrebasewassafe = true; ///Sets the rebase value to be Risky
           }
      }
      if (RiskyReward == true)  //////Risky Bet
       {
           if (riskysame == false) ///ensures no actions are done if price remains the same
           {
          for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
           uint256 reward;
           uint tempbalance;
           bool riskyremoved = false;
           if (classicriskyrebase==true) ///Use old style rebase
             {
               reward = calculateReward(stakeholder);
               if (whalelimiter==true)
               {
                   if(reward>=whalelimit)
                   {
                       reward = whalereward; //sets the reward at a cap!
                   }
               }
             }
            if (classicriskyrebase==false) // Use new style with Game protection
            {
            //// Use new style with game protection///
           ///////////////////////////////////////////////////////////////////
             ////IMPLEMENT GAME PROTECTION/////////////////////////////////////
             tempbalance = (RCVR(RCVRAddress).balanceOf(stakeholder)); //Get current balance of the wallet
             temp = stakes[stakeholder]; // Get current Stake
             temp = temp.div(5); //Due to there being no decimals in Solidty be divide the number equally
             //////Calculate the % for the requirement////
             if (riskystakemultiplier == 4)
             {
             temp = temp.mul(4); // Then multiplt to get 20/40/60/80 percent
             }
             if (riskystakemultiplier == 3)
             {
             temp = temp.mul(3); // Then multiplt to get 20/40/60/80 percent
             }
             if (riskystakemultiplier == 2)
             {
             temp = temp.mul(2); // Then multiplt to get 20/40/60/80 percent
             }
             if (riskystakemultiplier == 1)
             {
             temp = temp.mul(1); // Then multiplt to get 20/40/60/80 percent
             }
             ///////////////////////////////////////////
             if(tempbalance >= temp)
             {
             reward = calculateRiskyReward(stakeholder);
             if (whalelimiter==true)
               {
                   if(reward>=whalelimitrisky)
                   {
                       reward = whalerewardrisky; //sets the reward at a cap!
                   }
               }
             }
             else{
                rewards[stakeholder] =0; //Zero the reward
             removeStakeholder(stakeholder); //Remove the user
             stakes[stakeholder]=0; //Remove stakes entirely
             riskyremoved = true; //Flag to ensure user reward is not processed;
             numriskyremoved += 1;
                
             }
            }
            if (riskyremoved==false)
            {
           
               if (negrebase == true)
               {
                   lastriskyrebase = true;
                if (rewards[stakeholder] >= reward) { //ensure that the users balance can ammodate the subtraction
                  rewards[stakeholder] = rewards[stakeholder].sub(reward); //subtract for negative rebase
                } else {
                  rewards[stakeholder] = 0;
                }
                riskyaccumulatednegetiverebase += reward; ///accumulate the tokens for a manual burn!
               }
               if (negrebase == false)
               {
                   lastriskyrebase = false;
               rewards[stakeholder] = rewards[stakeholder].add(reward); //add for positive rebase
               }
            }
           
        } 
         
        //Set the last Risky rebase timestamp 
        prevriskyrebase = block.timestamp;
        if (_fromforced==false)  //to ensure rebase system is not affected by the rebase
        {
        riskyrebasecounter +=1; 
        if (riskyrebasecounter >= sequentialrisky)
        {
            lastrebasewassafe = false; //Reset the loop to use the safe rebase next rounded
            riskyrebasecounter = 0;
        }
        
        }
        
       }
       }
    }
  ///Function to set riskystakemultiplier
  function setRiskyStakeMultiplier(int _muliplier) public onlyOwner{
      riskystakemultiplier = _muliplier;
  }
  ///Function for Timer to trigger a safe rebase
  function autoTriggerRebase() public{
      require(msg.sender == timeraddress || msg.sender==Owner,"NotTimer");
      rebase(false,false);
      if(reflectionontimer==true)
      {
      //determine if a reflect needs to happen
      if (hoursbetweenreflection==2)
      {
          if (block.timestamp > lastreflection + 2 hours)
          {
              reflectBNB();
          }
      }
      if (hoursbetweenreflection==4)
      {
          if (block.timestamp > lastreflection + 4 hours)
          {
              reflectBNB();
          }
      }
      if (hoursbetweenreflection==8)
      {
          if (block.timestamp > lastreflection + 8 hours)
          {
              reflectBNB();
          }
      }
      if (hoursbetweenreflection==12)
      {
          if (block.timestamp > lastreflection + 12 hours)
          {
              reflectBNB();
          }
      }
      if (hoursbetweenreflection==24)
      {
          if (block.timestamp > lastreflection + 24 hours)
          {
              reflectBNB();
          }
      }
      ////New function to burn on rebase///
      if (burnontimer==true)
      {
          if (now > timeoflastburn + 1 days)
          {
              burnTokensTimer();
          }
      }
      }
  }
  //Function to enable/Disable rebase at a granular Level
  function enableRebase(bool _onoroff) public onlyOwner
  {
      forcesafeenabled == _onoroff; //Enables or disables risky
      
  }
  
   //////////Function which user can trigger to force a rebase. This costs xx amount of Ether//////
   /// 0.01 -> SafeStake pool
      function Forcedistribute(bool _isRisky) public payable
   {
       require(rewarddistribution == true, "RewOff");
       uint ethercost = 0;
       require(forcesafeenabled==true,"FSD(x))");
       ethercost = forcesafecost;
       /////Require statement to ensure user can afford it////
       require(msg.value >= ethercost);
       //Perform the rebase
       //Now with a single pool we only need one TX
       
       rebase(true,_isRisky);
   }
   ///Function to get the number of stakeholders in the main pool
   function getnumStakers() public view returns(uint) 
   {
       return stakeholders.length;
       
       
   }
   ////Returns true if risky
   function getNextRebase() public view returns(bool)
   {
       bool temp;
       if (lastrebasewassafe==true)
       {
        temp = true;
       }
       if (riskyrebasecounter < sequentialrisky && lastrebasewassafe==true)
       {
           temp = true;
       }
   }
   ////Function to handle the refelction of BNB
   //Refectlion is done via havin 100USDT in RCVR
   function reflectBNB() public {
       require(msg.sender==address(this) || msg.sender==Owner || msg.sender==timeraddress,"Not Auth for Reflect!" );
       ///Get the amounts of RCVR required for reflectBNB
       numreflectors = 0; //Reset the divider
       uint inflatedprice;
       uint walletbalance;
       uint amountoftokens;
       uint RCVRwalletinUSDT;
       uint shareofBNB;
       uint BNBsplit;
       uint USDTPrice = RCVRPriceFeed(rcvrpricefeed).getTokenPrice(USDTAddress); //GEt Price of USDTAddress
       uint RCVRPrice = RCVRPriceFeed(rcvrpricefeed).getTokenPrice(RCVRAddress);
         inflatedprice = USDTPrice.mul(USDTLimit); //Sets the amount of $$$$ in for the limit
       ///check that the user has the required RCVR
       //Only proceed if BNB is in wallet
       if (stakingaddress.balance > 0)
       {
       //STEP 1 =>
       for (uint256 s = 0; s < stakeholders.length; s += 1){
          address stakeholder = stakeholders[s];
           walletbalance = (RCVR(RCVRAddress).balanceOf(stakeholder)); //Get current balance of the wallet
           amountoftokens = inflatedprice.div(RCVRPrice);
           amountoftokens = amountoftokens.mul(1000000000000000000); // Get Correct amount of tokens in 18 Decimals
           if (walletbalance >= amountoftokens)
           {
               canreflect[stakeholder] = true;
               numreflectors +=1;
           }
           if (walletbalance < amountoftokens) //ensure the user doesnt stay being able to reflect
           {
              canreflect[stakeholder] = false;
           }
           
       }
       //STEP 2 => Divide the BNB amongst the numreflectors
       BNBsplit = stakingaddress.balance;
       BNBsplit = BNBsplit.div(100); //divides it into 1% splits
       if (sendtocharity==false)
       {
       amounttoreflectors = BNBsplit.mul(40);
       amounttotimer = BNBsplit.mul(50);
       amounttoliquidty = BNBsplit.mul(10);
       }
       if (sendtocharity==true)
       {
       amounttoreflectors = BNBsplit.mul(40);
       amounttotimer = BNBsplit.mul(50);
       amounttoliquidty = BNBsplit.mul(8); 
       amounttocharity = BNBsplit.mul(2);
       }
       if (numreflectors > 0)
       {
       shareofBNB = amounttoreflectors.div(numreflectors);
       for (uint256 s = 0; s < stakeholders.length; s += 1){
          payee = stakeholders[s];
         if (canreflect[payee]==true)
         {
          payee.transfer(shareofBNB);
           
         }
       }
       }
       /////Payput to functions//////
       autoLPcontract.transfer(amounttoliquidty);
       timeraddress.transfer(amounttotimer);
       if (sendtocharity==true)
       {
           charity.transfer(amounttocharity);
       }
       //////////////////////////////
       lastreflection = block.timestamp;
      
       }
       }
       
       
      
   
   
  
}///////////////////Contract END//////////////////////