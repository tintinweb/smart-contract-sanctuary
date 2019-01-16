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