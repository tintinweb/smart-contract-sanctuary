pragma solidity ^0.4.24;

// File: contracts/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);


  function burn(uint256 value) external ;

 
  function burnFrom(address from, uint256 value) external;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: openzeppelin-solidity/contracts/access/roles/SignerRole.sol

contract SignerRole {
  using Roles for Roles.Role;

  event SignerAdded(address indexed account);
  event SignerRemoved(address indexed account);

  Roles.Role private signers;

  constructor() internal {
    _addSigner(msg.sender);
  }

  modifier onlySigner() {
    require(isSigner(msg.sender));
    _;
  }

  function isSigner(address account) public view returns (bool) {
    return signers.has(account);
  }

  function addSigner(address account) public onlySigner {
    _addSigner(account);
  }

  function renounceSigner() public {
    _removeSigner(msg.sender);
  }

  function _addSigner(address account) internal {
    signers.add(account);
    emit SignerAdded(account);
  }

  function _removeSigner(address account) internal {
    signers.remove(account);
    emit SignerRemoved(account);
  }
}

// File: contracts/NRTManager.sol

/**
* @title  NRT Distribution Contract
* @dev This contract will be responsible for distributing the newly released tokens to the different pools.
*/




// The contract addresses of different pools
contract NRTManager is Ownable, SignerRole{
    using SafeMath for uint256;

    uint256 releaseNrtTime; // variable to check release date
    IERC20   tokenContract;  // Defining conract address so as to interact with EraswapToken

    // Variables to keep track of tokens released
    uint256 MonthlyReleaseNrt;
    uint256 AnnualReleaseNrt;
    uint256 monthCount;

    // Event to watch token redemption
    event sendToken(
    string pool,
    address indexed sendAddress,
    uint256 value
    );

    // Event To watch pool address change
    event ChangingPoolAddress(
    string pool,
    address indexed newAddress
    );

    // Event to watch NRT distribution
    event NRTDistributed(
        uint256 NRTReleased
    );


    address public newTalentsAndPartnerships;
    address public platformMaintenance;
    address public marketingAndRNR;
    address public kmPards;
    address public contingencyFunds;
    address public researchAndDevelopment;
    address public buzzCafe;
    address public powerToken;

    // balances present in different pools

    uint256 public newTalentsAndPartnershipsBal;
    uint256 public platformMaintenanceBal;
    uint256 public marketingAndRNRBal;
    uint256 public kmPardsBal;
    uint256 public contingencyFundsBal;
    uint256 public researchAndDevelopmentBal;
    uint256 public powerTokenBal;

    // balances timeAlly workpool distribute
    uint256 public curatorsBal;
    uint256 public timeTradersBal;
    uint256 public daySwappersBal;
    uint256 public buzzCafeBal;
    uint256 public stakersBal; 
    uint256 public luckPoolBal;    // Luckpool Balance

    // Total staking balances after NRT release
    uint256 public OneYearStakersBal;
    uint256 public TwoYearStakersBal;
    
    uint256 public burnTokenBal;// tokens to be burned

    address public eraswapToken;  // address of EraswapToken
    address public stakingContract;

   /**
   * @dev Throws if not a valid address
   * @param addr address
   */
    modifier isValidAddress(address addr) {
        require(addr != address(0),"It should be a valid address");
        _;
    }

   /**
   * @dev Throws if the value is zero
   * @param value alue to be checked
   */
    modifier isNotZero(uint256 value) {
        require(value != 0,"It should be non zero");
        _;
    }

    /**
    * @dev Function to initialise NewTalentsAndPartnerships pool address
    * @param pool_addr Address to be set 
    */

    function setNewTalentsAndPartnerships(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        newTalentsAndPartnerships = pool_addr;
        emit ChangingPoolAddress("NewTalentsAndPartnerships",newTalentsAndPartnerships);
    }

     /**
    * @dev Function to send NewTalentsAndPartnerships balance
    */
    function sendNewTalentsAndPartnerships() internal isValidAddress(newTalentsAndPartnerships) 
    returns(bool) {
        uint256 temp = newTalentsAndPartnershipsBal;
        emit sendToken("NewTalentsAndPartnerships",newTalentsAndPartnerships,newTalentsAndPartnershipsBal);
        newTalentsAndPartnershipsBal = 0;
        require(tokenContract.transfer(newTalentsAndPartnerships, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to initialise PlatformMaintenance pool address
    * @param pool_addr Address to be set 
    */

    function setPlatformMaintenance(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        platformMaintenance = pool_addr;
        emit ChangingPoolAddress("PlatformMaintenance",platformMaintenance);
    }
    

     /**
    * @dev Function to send platformMaintenance balance
    */
    function sendPlatformMaintenance() internal isValidAddress(platformMaintenance) 
    returns(bool){
        uint256 temp = platformMaintenanceBal;
        emit sendToken("PlatformMaintenance",platformMaintenance,platformMaintenanceBal);
        platformMaintenanceBal = 0;
        require(tokenContract.transfer(platformMaintenance, temp),"The transfer must not fail");
        return true;    
    }

    /**
    * @dev Function to initialise MarketingAndRNR pool address
    * @param pool_addr Address to be set 
    */

    function setMarketingAndRNR(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        marketingAndRNR = pool_addr;
        emit ChangingPoolAddress("MarketingAndRNR",marketingAndRNR);
    }

    /**
    * @dev Function to send marketingAndRNR balance
    */
    function sendMarketingAndRNR() internal isValidAddress(marketingAndRNR) 
    returns(bool){
        uint256 temp = marketingAndRNRBal;
        emit sendToken("MarketingAndRNR",marketingAndRNR,marketingAndRNRBal);
        marketingAndRNRBal = 0;
        require(tokenContract.transfer(marketingAndRNR, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to initialise setKmPards pool address
    * @param pool_addr Address to be set 
    */

    function setKmPards(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        kmPards = pool_addr;
        emit ChangingPoolAddress("kmPards",kmPards);
    }

    /**
    * @dev Function to send KmPards balance
    */
    function sendKmPards() internal isValidAddress(kmPards) 
    returns(bool){
        uint256 temp = kmPardsBal;
        emit sendToken("MarketingAndRNR",kmPards,kmPardsBal);
        kmPardsBal = 0;
        require(tokenContract.transfer(kmPards, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to initialise ContingencyFunds pool address
    * @param pool_addr Address to be set 
    */

    function setContingencyFunds(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        contingencyFunds = pool_addr;
        emit ChangingPoolAddress("ContingencyFunds",contingencyFunds);
    }

    /**
    * @dev Function to send contingencyFunds balance
    */
    function sendContingencyFunds() internal  isValidAddress(contingencyFunds) 
    returns(bool){
        uint256 temp = contingencyFundsBal;
        emit sendToken("contingencyFunds",contingencyFunds,contingencyFundsBal);
        contingencyFundsBal = 0;
        require(tokenContract.transfer(contingencyFunds, temp),"The transfer must not fail");
        return true;
    }
    /**
    * @dev Function to initialise ResearchAndDevelopment pool address
    * @param pool_addr Address to be set 
    */

    function setResearchAndDevelopment(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        researchAndDevelopment = pool_addr;
        emit ChangingPoolAddress("ResearchAndDevelopment",researchAndDevelopment);
    }

    /**
    * @dev Function to send researchAndDevelopment balance
    */
    function sendResearchAndDevelopment() internal isValidAddress(researchAndDevelopment) 
    returns(bool){
        uint256 temp = researchAndDevelopmentBal;
        emit sendToken("ResearchAndDevelopment",researchAndDevelopment,researchAndDevelopmentBal);
        researchAndDevelopmentBal = 0;
        require(tokenContract.transfer(researchAndDevelopment, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to initialise BuzzCafe pool address
    * @param pool_addr Address to be set 
    */

    function setBuzzCafe(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        buzzCafe = pool_addr;
        emit ChangingPoolAddress("BuzzCafe",buzzCafe);
    }

    /**
    * @dev Function to send buzzCafe balance
    */
    function sendBuzzCafe() internal isValidAddress(buzzCafe) 
    returns(bool){
        uint256 temp = buzzCafeBal;
        emit sendToken("BuzzCafe",buzzCafe,buzzCafeBal);
        buzzCafeBal = 0;
        require(tokenContract.transfer(buzzCafe, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to initialise PowerToken pool address
    * @param pool_addr Address to be set 
    */

    function setPowerToken(address pool_addr) public onlyOwner() isValidAddress(pool_addr){
        powerToken = pool_addr;
        emit ChangingPoolAddress("PowerToken",powerToken);
    }

    /**
    * @dev Function to send powerToken balance
    */
    function sendPowerToken() internal  isValidAddress(powerToken) 
    returns(bool){
        uint256 temp = powerTokenBal;
        emit sendToken("PowerToken",powerToken,powerTokenBal);
        powerTokenBal = 0;
        require(tokenContract.transfer(powerToken, temp),"The transfer must not fail");
        return true;
    }

    /**
    * @dev Function to update staking contract address
    * @param token Address to be set 
    */
    function setStakingContract(address token) external onlyOwner() isValidAddress(token){
        stakingContract = token;
        emit ChangingPoolAddress("stakingContract",stakingContract);
    }

    /**
    * @dev Function to send powerToken balance
    */
    function sendStakingContract() internal  isValidAddress(stakingContract) 
    returns(bool){
        emit sendToken("staking contract",stakingContract,stakersBal);
        require(tokenContract.transfer(stakingContract, stakersBal),"The transfer must not fail");
        return true;
    }

    function resetStaking() external returns(bool) {
        require(msg.sender == stakingContract , "shoul reset staking " );
        stakersBal = 0;
        return true;
    }

    /**
    * @dev Function to trigger the release of monthly NRT to different actors in the system
    * @param amount amount to be updated
    */
    function updateLuckpool(uint256 amount) external onlySigner(){
        require(tokenContract.transfer(address(this), amount), "The token transfer should be done");
        luckPoolBal = luckPoolBal.add(amount);
    }

    /**
    * @dev Function to trigger to update  for burning of tokens
    * @param amount amount to be updated
    */
    function updateBurnBal(uint256 amount) external onlySigner(){
        require(tokenContract.transfer(address(this), amount), "The token transfer should be done");
        burnTokenBal = burnTokenBal.add(amount);
    }


      /**
   * @dev Should burn tokens according to the total circulation
   * @return true if success
   */

function burnTokens() internal returns (bool){
      tokenContract.burn(burnTokenBal);
      return true;
}

        /**
   * @dev To invoke monthly release
   * @return true if success
   */

    function receiveMonthlyNRT() external onlySigner() returns (bool) {
        require(tokenContract.balanceOf(address(this))>0,"NRT_Manger should have token balance");
        require(now >= releaseNrtTime,"NRT can be distributed only after 30 days");
        uint NRTBal = NRTBal.add(MonthlyReleaseNrt);
        require(NRTBal > 0, "It should be Non-Zero");

        require(distribute_NRT(NRTBal));
        if(monthCount == 11){
            monthCount = 0;
            AnnualReleaseNrt = (AnnualReleaseNrt.mul(9)).div(10);
            MonthlyReleaseNrt = AnnualReleaseNrt.div(12);
        }
        else{
            monthCount = monthCount.add(1);
        }     
        return true;   
    }

    /**
   * @dev To invoke monthly release
   * @param NRTBal Nrt balance to distribute
   * @return true if success
   */
    function distribute_NRT(uint256 NRTBal) internal isNotZero(NRTBal) returns (bool){
        require(tokenContract.balanceOf(address(this))>=NRTBal,"NRT_Manger doesn&#39;t have token balance");
        NRTBal = NRTBal.add(luckPoolBal);
        
        // Distibuting the newly released tokens to each of the pools
        
        newTalentsAndPartnershipsBal = newTalentsAndPartnershipsBal.add((NRTBal.mul(5)).div(100));
        platformMaintenanceBal = platformMaintenanceBal.add((NRTBal.mul(10)).div(100));
        marketingAndRNRBal = marketingAndRNRBal.add((NRTBal.mul(10)).div(100));
        kmPardsBal = kmPardsBal.add((NRTBal.mul(10)).div(100));
        contingencyFundsBal = contingencyFundsBal.add((NRTBal.mul(10)).div(100));
        researchAndDevelopmentBal = researchAndDevelopmentBal.add((NRTBal.mul(5)).div(100));
        curatorsBal = curatorsBal.add((NRTBal.mul(5)).div(100));
        timeTradersBal = timeTradersBal.add((NRTBal.mul(5)).div(100));
        daySwappersBal = daySwappersBal.add((NRTBal.mul(125)).div(1000));
        buzzCafeBal = buzzCafeBal.add((NRTBal.mul(25)).div(1000)); 
        powerTokenBal = powerTokenBal.add((NRTBal.mul(10)).div(100));
        stakersBal = stakersBal.add((NRTBal.mul(15)).div(100));

        

        // Reseting NRT

        emit NRTDistributed(NRTBal);
        NRTBal = 0;
        luckPoolBal = 0;
        releaseNrtTime = releaseNrtTime.add(30 days + 6 hours); // resetting release date again


        // sending tokens to respective wallets
        require(sendNewTalentsAndPartnerships(),"Tokens should be succesfully send");
        require(sendPlatformMaintenance(),"Tokens should be succesfully send");
        require(sendMarketingAndRNR(),"Tokens should be succesfully send");
        require(sendKmPards(),"Tokens should be succesfully send");
        require(sendContingencyFunds(),"Tokens should be succesfully send");
        require(sendResearchAndDevelopment(),"Tokens should be succesfully send");
        require(sendBuzzCafe(),"Tokens should be succesfully send");
        require(sendPowerToken(),"Tokens should be succesfully send");
        require(sendStakingContract(),"Tokens should be succesfully send");
        return true;

    }


    /**
    * @dev Constructor
    * @param token Address of eraswaptoken
    * @param pool Array of different pools
    * NewTalentsAndPartnerships(pool[0]);
    * PlatformMaintenance(pool[1]);
    * MarketingAndRNR(pool[2]);
    * KmPards(pool[3]);
    * ContingencyFunds(pool[4]);
    * ResearchAndDevelopment(pool[5]);
    * BuzzCafe(pool[6]);
    * PowerToken(pool[7]);
    */

    constructor (address token, address[] memory pool) public{
        require(token != address(0),"address should be valid");
        eraswapToken = token;
        tokenContract = IERC20(eraswapToken);
         // Setting up different pools
        setNewTalentsAndPartnerships(pool[0]);
        setPlatformMaintenance(pool[1]);
        setMarketingAndRNR(pool[2]);
        setKmPards(pool[3]);
        setContingencyFunds(pool[4]);
        setResearchAndDevelopment(pool[5]);
        setBuzzCafe(pool[6]);
        setPowerToken(pool[7]);
        releaseNrtTime = now.add(30 days + 6 hours);
        AnnualReleaseNrt = 81900000000000000;
        MonthlyReleaseNrt = AnnualReleaseNrt.div(uint256(12));
        monthCount = 0;
    }

}

// File: contracts/Staking.sol

// contract to manage staking of one year and two year stakers



// Database Design based on CRUD by Rob Hitchens . Refer : https://medium.com/@robhitchens/solidity-crud-part-1-824ffa69509a

contract Staking {
    using SafeMath for uint256;
    
    address public NRTManagerAddr;
    NRTManager NRTContract;

    // Event to watch staking creations
    event stakeCreation(
    uint64 orderid,
    address indexed ownerAddress,
    uint256 value
    );


    // Event to watch loans repayed taken
    event loanTaken(
    uint64 orderid
    );

    // Event to watch wind up of contracts
    event windupContract(
    uint64 orderid
    );

    IERC20   tokenContract;  // Defining conract address so as to interact with EraswapToken
    address public eraswapToken;  // address of EraswapToken

    uint256 public luckPoolBal;    // Luckpool Balance

     // Counts of different stakers
    uint256 public  OneYearStakerCount;
    uint256 public TwoYearStakerCount;
    uint256 public TotalStakerCount;

    // Total staked amounts
    uint256 public OneYearStakedAmount;
    uint256 public TwoYearStakedAmount;

    // Burn away token count
    uint256 public burnTokenBal;
    uint64[] public delList;

    // Total staking balances after NRT release
    uint256 public OneYearStakersBal;
    uint256 public TwoYearStakersBal;

   
    uint64 OrderId=100000;  // orderID to uniquely identify the staking order


    struct Staker {
        bool isTwoYear;         // to check whether its one or two year
        bool loan;              // to check whether loan is taken
        uint8 loanCount;      // to check limit of loans that can be taken
        uint64 index;          // index
        uint64 orderID;        // unique orderid to uniquely identify the order
        uint256 stakedAmount;   // amount Staked
        uint256 stakedTime;     // Time at which the user staked
        uint256 windUpTime;     // to check time of windup started
        uint256 loanStartTime;  // to keep a check in loan period

    }

    mapping (uint64 => address) public  StakingOwnership; // orderid ==> address of user
    mapping (uint64 => Staker) public StakingDetails;     //orderid ==> order details
    mapping (uint64 => uint256[]) public cumilativeStakedDetails; // orderid ==> to store the cumilative amount of NRT stored per month
    mapping (uint64 => uint256) public totalNrtMonthCount; // orderid ==> to keep tab on how many times NRT was received

    uint64[] public OrderList;  // to store all active orders in which the state need to be changed monthly
  


   /**
   * @dev Throws if not times up to close a contract
   * @param orderID to identify the unique staking contract
   */
    modifier isWithinPeriod(uint64 orderID) {
        if (StakingDetails[orderID].isTwoYear) {
        require(now <= StakingDetails[orderID].stakedTime + 730 days,"Contract can only be ended after 2 years");
        }else {
        require(now <= StakingDetails[orderID].stakedTime + 365 days,"Contract can only be ended after 1 years");
        }
        _;
    }

   /**
   * @dev To check if loan is initiated
   * @param orderID to identify the unique staking contract
   */
   modifier isNoLoanTaken(uint64 orderID) {
        require(StakingDetails[orderID].loan != true,"Loan is present");
        _;
    }

   /**
   * @dev To check whether its valid staker 
   * @param orderID to identify the unique staking contract
   */
   modifier onlyStakeOwner(uint64 orderID) {
        require(StakingOwnership[orderID] == msg.sender,"Staking owner should be valid");
        _;
    }

       
 
  /**
   * @dev Should delete unwanted orders
   * @return true if success
   */

function deleteList() internal returns (bool){
      for (uint j = delList.length - 1;j > 0;j--)
      {
          deleteRecord(delList[j]);
          delList.length--;
      }
      return true;
}


   /**
   * @dev To create staking contract
   * @param amount Total Est which is to be Staked
   * @return orderId of created 
   */

    function createStakingContract(uint256 amount,bool isTwoYear) external returns (uint64) { 
            OrderId = OrderId + 1;
            StakingOwnership[OrderId] = msg.sender;
            uint64 index = uint64(OrderList.push(OrderId) - 1);
            cumilativeStakedDetails[OrderId].push(amount);
            if (isTwoYear) {
            TwoYearStakerCount = TwoYearStakerCount.add(1);
            TwoYearStakedAmount = TwoYearStakedAmount.add(amount);
            StakingDetails[OrderId] = Staker(true,false,0,index,OrderId,amount, now,0,0);
            }else {
            OneYearStakerCount = OneYearStakerCount.add(1);
            OneYearStakedAmount = OneYearStakedAmount.add(amount);
            StakingDetails[OrderId] = Staker(false,false,0,index,OrderId,amount, now,0,0);
            }
            require(tokenContract.transfer(address(this), amount), "The token transfer should be done");
            emit stakeCreation(OrderId,StakingOwnership[OrderId], amount);
            return OrderId;
        }

    /**
   * @dev Function to check whether a partcicular order exists
   * @param orderId to identify unique staking contract
   * @return true if success
   */

  function isOrderExist(uint64 orderId) public view returns(bool) {
      return OrderList[StakingDetails[orderId].index] == orderId;
 }
 
    /**
   * @dev To check if loan is initiated
   * @param orderId to identify unique staking contract
   * @return orderId of created 
   */
  function takeLoan(uint64 orderId) onlyStakeOwner(orderId) isNoLoanTaken(orderId) isWithinPeriod(orderId) external returns (bool) {
    require(isOrderExist(orderId),"The orderId should exist");
    require((StakingDetails[orderId].stakedTime).sub(now) >= 60 days,"Contract End is near");
    if (StakingDetails[orderId].isTwoYear) {
          require(StakingDetails[orderId].loanCount <= 1,"only one loan per year is allowed");        
          TwoYearStakerCount = TwoYearStakerCount.sub(1);
          TwoYearStakedAmount = TwoYearStakedAmount.sub(StakingDetails[orderId].stakedAmount);
    }else {
          require(StakingDetails[orderId].loanCount == 0,"only one loan per year is allowed");        
          OneYearStakerCount = OneYearStakerCount.sub(1);
          OneYearStakedAmount = OneYearStakedAmount.sub(StakingDetails[orderId].stakedAmount);
    }
          StakingDetails[orderId].loan = true;
          StakingDetails[orderId].loanStartTime = now;
          StakingDetails[orderId].loanCount = StakingDetails[orderId].loanCount + 1;
          // todo: check this transfer, it may not be doing as expected
          require(tokenContract.transfer(msg.sender,(StakingDetails[orderId].stakedAmount).div(2)),"The contract should transfer loan amount");
          emit loanTaken(orderId);
          return true;
      }
      
  /**
   * @dev To repay the leased loan
   * @param orderId to identify unique staking contract
   * @return total repayment
   */

  function calculateTotalPayment(uint64 orderId)  public view returns (uint256) {
          require(isOrderExist(orderId),"The orderId should exist");
          return ((StakingDetails[orderId].stakedAmount).div(200)).mul(101);
      
  }
   /**
   * @dev To check if eligible for repayment
   * @param orderId to identify unique staking contract
   * @return total repayment
   */
  function isEligibleForRepayment(uint64 orderId)  public view returns (bool) {
          require(isOrderExist(orderId),"The orderId should exist");
          require(StakingDetails[orderId].loan == true,"User should have taken loan");
          require((StakingDetails[orderId].loanStartTime).sub(now) < 60 days,"Loan repayment should be done on time");
          return true;
  }
   /**
   * @dev To repay the leased loan
   * @param orderId to identify unique staking contract
   * @return true if success
   */
  function rePayLoan(uint64 orderId) onlyStakeOwner(orderId) isWithinPeriod(orderId) external returns (bool) {
      require(isEligibleForRepayment(orderId),"The user should be eligible for repayment");
      StakingDetails[orderId].loan = false;
      StakingDetails[orderId].loanStartTime = 0;
      luckPoolBal = luckPoolBal.add((StakingDetails[orderId].stakedAmount).div(200));
      if (StakingDetails[orderId].isTwoYear) {  
          TwoYearStakerCount = TwoYearStakerCount.add(1);
          TwoYearStakedAmount = TwoYearStakedAmount.add(StakingDetails[orderId].stakedAmount);
      }else {  
          OneYearStakerCount = OneYearStakerCount.add(1);
          OneYearStakedAmount = OneYearStakedAmount.add(StakingDetails[orderId].stakedAmount);
      }
          // todo: check this transfer, it may not be doing as expected
          require(tokenContract.transfer(address(this),calculateTotalPayment(orderId)),"The contract should receive loan amount with interest");
          return true;
  }



 /**
   * @dev Function to delete a particular order
   * @param orderId to identify unique staking contract
   * @return true if success
   */

  function deleteRecord(uint64 orderId) internal returns (bool) {
      require(isOrderExist(orderId),"The orderId should exist");
      uint64 rowToDelete = StakingDetails[orderId].index;
      uint64 orderToMove = OrderList[OrderList.length-1];
      OrderList[rowToDelete] = orderToMove;
      StakingDetails[orderToMove].index = rowToDelete;
      OrderList.length--; 
      return true;
  }

   /**
   * @dev should send tokens to the user
   * @param orderId to identify unique staking contract
   * @param amount amount to be send
   * @return true if success
   */

  function sendTokens(uint64 orderId, uint256 amount) internal returns (bool) {
      // todo: check this transfer, it may not be doing as expected
      require(tokenContract.transfer(StakingOwnership[orderId], amount),"The contract should send from its balance to the user");
      return true;
  }
  
/**
   * @dev Function to windup an active contact
   * @param orderId to identify unique staking contract
   * @return true if success
   */

  function windUpContract(uint64 orderId) onlyStakeOwner(orderId)  external returns (bool) {
      require(isOrderExist(orderId),"The orderId should exist");
      require(StakingDetails[orderId].loan == false,"There should be no loan currently");
      require(StakingDetails[orderId].windUpTime == 0,"Windup Shouldn&#39;t be initiated currently");
      StakingDetails[orderId].windUpTime = now + 104 weeks; // time at which all the transfer must be finished
      StakingDetails[orderId].stakedTime = now; // to keep track of NRT being distributed out
      if (StakingDetails[orderId].isTwoYear) {      
          TwoYearStakerCount = TwoYearStakerCount.sub(1);
          TwoYearStakedAmount = TwoYearStakedAmount.sub(StakingDetails[orderId].stakedAmount);
    }else {     
          OneYearStakerCount = OneYearStakerCount.sub(1);
          OneYearStakedAmount = OneYearStakedAmount.sub(StakingDetails[orderId].stakedAmount);
    }
      emit windupContract( orderId);
      return true;
  }

function preStakingDistribution() internal returns(bool){
    uint256 temp = NRTContract.stakersBal();
    if(temp == 0)
    {
        return true;
    }
    require(NRTContract.resetStaking(),"It should be successfully reset");
     if(OneYearStakerCount>0)
        {
        OneYearStakersBal = (temp.mul(OneYearStakerCount)).div(TotalStakerCount);
        TwoYearStakersBal = (temp.mul(TwoYearStakerCount)).div(TotalStakerCount);
        luckPoolBal = (OneYearStakersBal.mul(2)).div(15);
        OneYearStakersBal = OneYearStakersBal.sub(luckPoolBal);
        }
        else{
            TwoYearStakersBal = temp;
        }
        return true;
}

    /**
   * @dev Should update all the stakers state
   * @return true if success
   */

  function updateStakers() external returns(bool) {
      uint temp;
      uint temp1;
      require(preStakingDistribution(),"pre staking disribution should be done");
      for (uint i = 0;i < OrderList.length; i++) {
          if (StakingDetails[OrderList[i]].windUpTime > 0) {
                // should distribute 104th of staked amount
                if(StakingDetails[OrderList[i]].windUpTime < now){
                temp = ((StakingDetails[OrderList[i]].windUpTime.sub(StakingDetails[OrderList[i]].stakedTime)).div(104 weeks))
                        .mul(StakingDetails[OrderList[i]].stakedAmount);
                delList.push(OrderList[i]);
                }
                else{
                temp = ((now.sub(StakingDetails[OrderList[i]].stakedTime)).div(104 weeks)).mul(StakingDetails[OrderList[i]].stakedAmount);
                StakingDetails[OrderList[i]].stakedTime = now;
                }
                sendTokens(OrderList[i],temp);
          }else if (StakingDetails[OrderList[i]].loan && (StakingDetails[OrderList[i]].loanStartTime > 60 days) ) {
              burnTokenBal = burnTokenBal.add((StakingDetails[OrderList[i]].stakedAmount).div(2));
              delList.push(OrderList[i]);
          }else if(StakingDetails[OrderList[i]].loan){
              continue;
          }
          else if (StakingDetails[OrderList[i]].isTwoYear) {
                // transfers half of the NRT received back to user and half is staked back to pool
                totalNrtMonthCount[OrderList[i]] = totalNrtMonthCount[OrderList[i]].add(1);
                temp = (((StakingDetails[OrderList[i]].stakedAmount).div(TwoYearStakedAmount)).mul(TwoYearStakersBal)).div(2);
                if(cumilativeStakedDetails[OrderList[i]].length < 24){
                cumilativeStakedDetails[OrderList[i]].push(temp);
                sendTokens(OrderList[i],temp);
                }
                else{
                    temp1 = temp;
                    temp = temp.add(cumilativeStakedDetails[OrderList[i]][totalNrtMonthCount[OrderList[i]] % 24]); 
                    cumilativeStakedDetails[OrderList[i]][totalNrtMonthCount[OrderList[i]] % 24] = temp1; 
                    sendTokens(OrderList[i],temp);
                }
          }else {
              // should distribute the proporsionate amount of staked value for one year
              totalNrtMonthCount[OrderList[i]] = totalNrtMonthCount[OrderList[i]].add(1);
              temp = (((StakingDetails[OrderList[i]].stakedAmount).div(OneYearStakedAmount)).mul(OneYearStakersBal)).div(2);
              if(cumilativeStakedDetails[OrderList[i]].length < 12){
              cumilativeStakedDetails[OrderList[i]].push(temp);
              sendTokens(OrderList[i],temp);
              }
              else{
                    temp1 = temp;
                    temp = temp.add(cumilativeStakedDetails[OrderList[i]][totalNrtMonthCount[OrderList[i]] % 12]); 
                    cumilativeStakedDetails[OrderList[i]][totalNrtMonthCount[OrderList[i]] % 12] = temp1; 
                    sendTokens(OrderList[i],temp);
                }
          }
      }
      return true;
  }

     /**
    * @dev Constructor
    * @param token Address of eraswaptoken
    * @param NRT Address of NRTcontract
    */

    constructor (address token,address NRT) public{
        require(token != address(0),"address should be valid");
        eraswapToken = token;
        tokenContract = IERC20(eraswapToken);
        NRTManagerAddr = NRT;
        NRTContract = NRTManager(NRTManagerAddr);
    }

}