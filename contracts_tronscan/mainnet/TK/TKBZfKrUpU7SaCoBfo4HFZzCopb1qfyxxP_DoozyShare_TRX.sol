//SourceUnit: doozyshare.sol

pragma solidity >=0.4.23 <0.6.0;

contract SafeMath {
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
//////////////////////////////////////////////////
//  Create contract
//  Add minter to token contract
//////////////////////////////////////////////////
contract DoozyShare_TRX is SafeMath {
    struct User {
        uint id;
        address payable referrer;
        uint partnersCount;
        uint256 memberDate;
        uint256 totalCom;
        uint monthlyPaymentCount;               // have to pay monthly fee to keep account active
        bool D6_purchased;
        uint256 D6_expired_date;
        uint256 D6_next_DOZY_reward;
        
        mapping(uint => address) partnerList;        
        mapping(uint => bool) activeLevel;

    }
    //Variables
    uint constant decimals              = 6;
    uint public lastUserId              = 2;
    uint public diamondRankCriteria     = 100;                  //100 active users to be diamond
    uint public maxLevel                = 5;
    uint public D6_duration             = 180;                  //180 days
    uint public D6_DOZY_duration        = 30;                    //every 30 days
    uint public Diamond_Pool_Percent    = 1500;                 // 100 = 1%
    uint day_length                     = 86400;                //1 day is 86400 seconds
    
    TokenContract token;
    uint256 public platform_ref_payout;
    uint256 public D6_DOZY_reward;
    
    //Addresses
    address payable public owner;
    address payable public _mod         = address(0x41C0CB5C609895BF192A1B2797D52C0987F54333DE);    //TTYcMeedtDX9JhXQUHn2XYj7pAAhjNY8oV
    address TokenContractAddress        = address(0x419BA847C074B6664A207A86C1C26847276351A83C);    //TQAFL7RbYWqhntcJZro3ixx8QLBkqZmNZr
    address payable Platform_Pool       = address(0x41C515903BFF9EE43B37DAE931B6924AB2C7866913);    //TTwHx6sGjfqpE4Y216rTnCWfb5aGjqqV9E
    
    uint256 public diamondPool;                         //Pool to pay for diamond Rank users
    mapping(uint => address) public diamondList;        //List of all users has 100+ partners
    uint public diamondCount;                           //lenght of diamond List
    
    mapping(address => User)    public users;              //Platform users
    mapping(uint => address)    public idToAddress;        //convert user ID to address
    mapping(uint8 => uint)      public levelPrice;           //Joining Fee
    mapping(uint8 => uint)      public levelCom;             //Level Commission
    
    uint public freezeCount;                            //Total number of diamond rank payment
    mapping(uint => uint) public freezeHistory;         //History of diamond rank payment with TimeStamp
    
    mapping(uint256 => uint) public Divs;               // timestamp to uint256
    mapping(uint256 => bool) public isPoolfrozen;
    mapping(address => uint) public AvailableToWithdraw;//Diamond Rank User's Reward Balance
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event PackagePurchase(address indexed user, uint8 level);
    event PackageBundlePurchase(address indexed user, uint8 fromLevel, uint8 toLevel);
    event MonthlySubscription(address indexed user,uint months);
    event ClaimDiamondReward(address indexed user,uint amount);
    event SetDiamondReward(address indexed user,uint amount,uint256 timestamp);
    event ComDistributed(address indexed receiver, address indexed buyer, uint256 amount, uint8 level);
    event D6_DOZY_Claim(address indexed user,uint amount);
    constructor() public {
        
        levelPrice[1] = 250 * (10**decimals);
        levelPrice[2] = 500 * (10**decimals);
        levelPrice[3] = 1000 * (10**decimals);
        levelPrice[4] = 1500 * (10**decimals);
        levelPrice[5] = 2500 * (10**decimals);
        levelPrice[6] = 175000 * (10**decimals);
        
        levelCom[1] = 3300;     //33%
        levelCom[2] = 1500;     //15%
        levelCom[3] = 1000;     //10%
        levelCom[4] = 500;      //5%
        levelCom[5] = 500;      //5%
        
        D6_DOZY_reward = 25000 * (10**decimals);        //monthly dozy reward for D6 member
        
        token = TokenContract(TokenContractAddress);
        
        owner = msg.sender;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            memberDate: ZeroTimeStamp(now),
            totalCom: 0,
            monthlyPaymentCount:100000,
            D6_purchased: true,
            D6_expired_date: now + 100000 * day_length,
            D6_next_DOZY_reward: now + D6_DOZY_duration * day_length
        });
        
        users[owner] = user;
        idToAddress[1] = owner;
        
        for (uint8 i = 1; i <= maxLevel; i++) {
            users[owner].activeLevel[i] = true;
        }
    }
    function joinExt(address payable referrerAddress) external payable {
        join(msg.sender, referrerAddress);
    }
    
    function join(address payable userAddress,address payable referrerAddress) private {
        require(msg.value == levelPrice[1] , "registration invalid fee");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            memberDate: ZeroTimeStamp(now),
            totalCom:0,
            monthlyPaymentCount:1,
            D6_purchased: false,
            D6_expired_date: 0,
            D6_next_DOZY_reward: 0
        });
        users[userAddress].activeLevel[1] = true;
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        users[referrerAddress].partnerList[users[referrerAddress].partnersCount] = userAddress;
        
        if (users[referrerAddress].partnersCount == diamondRankCriteria){
            diamondCount++;
            diamondList[diamondCount] = referrerAddress;
        }

        //reward DOZY token
        require(token.mint(userAddress,levelPrice[1]));
        //Pay referrer Level 1
        uint refpaid = payRef(userAddress,levelPrice[1]);
        platform_ref_payout += refpaid;
        
        diamondPool = add(diamondPool,div(mul(Diamond_Pool_Percent,levelPrice[1]),10000));   //15%
        
        //the rest sent to Platform Pool
        require(Platform_Pool.send(levelPrice[1] - div(mul(Diamond_Pool_Percent,levelPrice[1]),10000) - refpaid),'cant send platform fee');
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function buyPackage(uint8 level) external payable{
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(isActive(msg.sender),'user not active');
        require(msg.value == levelPrice[level], "invalid fee");
        require(level > 1 && level <= maxLevel, "invalid level");
        require(!users[msg.sender].activeLevel[level],'level already active');
        require(users[msg.sender].activeLevel[level-1],'previous level must be active');
        
        users[msg.sender].activeLevel[level] = true;
        
        //reward DOZY token
        require(token.mint(msg.sender,levelPrice[level]));
        //Pay referrer Level
        uint refpaid = payRef(msg.sender,levelPrice[level]);
        platform_ref_payout += refpaid;
        
        diamondPool = add(diamondPool,div(mul(Diamond_Pool_Percent,levelPrice[level]),10000));   //5%
        
        //the rest sent to Platform Pool
        require(Platform_Pool.send(levelPrice[level] - div(mul(Diamond_Pool_Percent,levelPrice[level]),10000) - refpaid),'cant send platform fee');
        
        emit PackagePurchase(msg.sender, level);
        
    }
    
    function bundleBuy(uint8 fromLevel,uint8 toLevel) external payable{
        require(fromLevel>1);
        require(fromLevel<=toLevel);
        require(toLevel<=maxLevel);
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        
        //calculate how much to payRef
        uint totalFee = 0;
        for (uint8 i=fromLevel;i<=toLevel;i++){
            totalFee = add(totalFee,levelPrice[i]);
            require(!users[msg.sender].activeLevel[i],'already purchased one of the level');
        }
        require(msg.value >= totalFee, "invalid fee");
        
        //reward DOZY token
        require(token.mint(msg.sender,totalFee));
            
        for (uint8 i=fromLevel;i<=toLevel;i++)
            users[msg.sender].activeLevel[i] = true;
 
        //Pay referrer Level
        uint refpaid = payRef(msg.sender,totalFee);
        platform_ref_payout += refpaid;
        
        diamondPool = add(diamondPool,div(mul(Diamond_Pool_Percent,totalFee),10000));   
        
        //the rest sent to Platform Pool
        require(Platform_Pool.send(totalFee - div(mul(Diamond_Pool_Percent,totalFee),10000) - refpaid),'cant send platform fee');
        
        emit PackageBundlePurchase(msg.sender, fromLevel,toLevel);
    }
    
    function buyD6() external payable{
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(!users[msg.sender].D6_purchased,"already purchased D6");
       
        //Check fee
        uint totalFee = 0;
        for (uint8 i=1;i<=maxLevel;i++){
            
            if (!users[msg.sender].activeLevel[i]){
                totalFee = add(totalFee,levelPrice[i]);
                users[msg.sender].activeLevel[i] = true;
            }
        }
        totalFee = add(totalFee,levelPrice[6]);
        
        require(msg.value >= totalFee, "invalid fee");
        
        users[msg.sender].D6_purchased = true;
        users[msg.sender].D6_expired_date = now + D6_duration * day_length;
        users[msg.sender].D6_next_DOZY_reward = now + D6_DOZY_duration * day_length;
        
        diamondCount++;
        diamondList[diamondCount] = msg.sender;
        
        //How long has been in active:
        uint active_until = activeUntil(msg.sender);
        if (now > active_until) {
            users[msg.sender].memberDate = now;
            users[msg.sender].monthlyPaymentCount = 6;
        }
        else
            users[msg.sender].monthlyPaymentCount = add(users[msg.sender].monthlyPaymentCount,6);
            
        //reward DOZY token
        require(token.mint(msg.sender,totalFee));
        
        //Pay referrer Level
        uint refpaid = payRef(msg.sender,totalFee);
        platform_ref_payout += refpaid;
        
        diamondPool = add(diamondPool,div(mul(Diamond_Pool_Percent,totalFee),10000));   //5%
        
        //the rest sent to Platform Pool
        require(Platform_Pool.send(totalFee - div(mul(Diamond_Pool_Percent,totalFee),10000) - refpaid),'cant send platform fee');
        
        emit PackagePurchase(msg.sender, 6);
    }
    
    function claimD6_DOZY() public {
        require(isActive(msg.sender),'user not active');
        require(users[msg.sender].D6_purchased,'not D6');
        require(users[msg.sender].D6_expired_date>=now);
        
        require(users[msg.sender].D6_next_DOZY_reward<=now);
        
        users[msg.sender].D6_next_DOZY_reward = add(users[msg.sender].D6_next_DOZY_reward,D6_DOZY_duration * day_length);
        require(token.mint(msg.sender,D6_DOZY_reward));
        
        emit D6_DOZY_Claim(msg.sender,D6_DOZY_reward);
        
    }
    
    function payRef(address payable newUser,uint fee) internal returns(uint) {
        uint com = 0;
        address payable ref = newUser;
        for (uint8 activeLevel=1;activeLevel<=5;activeLevel++){
            if (users[ref].referrer == address(0)){
                require(owner.send(div(mul(levelCom[activeLevel],fee),10000)));
                users[owner].totalCom += div(mul(levelCom[activeLevel],fee),10000);
                emit ComDistributed(owner, newUser, div(mul(levelCom[activeLevel],fee),10000), activeLevel);
                
            }
            else
            {
                ref = findValidReferrer(ref,activeLevel);
                require(ref.send(div(mul(levelCom[activeLevel],fee),10000)));
                users[ref].totalCom += div(mul(levelCom[activeLevel],fee),10000);
                emit ComDistributed(ref, newUser, div(mul(levelCom[activeLevel],fee),10000), activeLevel);
            }
            com = add(com,div(mul(levelCom[activeLevel],fee),10000));
 
        }
        return com;
    }
    
    function extendSubscription(uint months) external payable{
        require(months>0,'invalid input');
        require(isUserExists(msg.sender), "user is not exists. Register first.");
        require(msg.value == levelPrice[1]*months, "invalid price"); 
        //How long has been in active:
        uint active_until = activeUntil(msg.sender);
        if (now > active_until) {
            users[msg.sender].memberDate = now;
            users[msg.sender].monthlyPaymentCount = months;
        }
        else
            users[msg.sender].monthlyPaymentCount = add(users[msg.sender].monthlyPaymentCount,months);
        
        //reward DOZY token
        require(token.mint(msg.sender,levelPrice[1]*months));
        //Pay referrer Level
        uint refpaid = payRef(msg.sender,levelPrice[1]*months);
        
        diamondPool = add(diamondPool,div(mul(Diamond_Pool_Percent,levelPrice[1]*months),10000));   //5%
        
        //the rest sent to Platform Pool
        require(Platform_Pool.send(levelPrice[1]*months - div(mul(Diamond_Pool_Percent,levelPrice[1]*months),10000) - refpaid),'cant send platform fee');
        
        emit MonthlySubscription(msg.sender,months);
    }
    ///////////////////////////////////////////    ///////////////////////////////////////////
    //                                  Diamon Pool Distribution functions
    //      Steps by Steps: (1 a month on the 1st of the month)
    //      1. Freeze the Pool to save current Pool
    //      2. Calculate all diamond rank users reward
    //      3. setDividend() for all diamond rank people and let user claim reward themselves
    ///////////////////////////////////////////    ///////////////////////////////////////////
    //freeze current Pool for div immediately
    function freezePool() public onlyMod {
        uint256 timeStamp = ZeroTimeStamp(now);      //one a day
        require(!isPoolfrozen[timeStamp],'already frozen');
        
        isPoolfrozen[timeStamp] = true;
        Divs[timeStamp] = diamondPool;
        diamondPool = 0;
        freezeCount++;
        freezeHistory[freezeCount] = timeStamp;
    }
    //Calculate by Mod from server
    function setDividend(address _user,uint _reward,uint _timeStamp) public onlyMod {
        uint256 timeStamp = ZeroTimeStamp(_timeStamp);      //one a day
        require(isPoolfrozen[timeStamp],'not ready');
        require(isActive(_user),'user not active');
        require(isDiamond(_user),'diamond not active');
        AvailableToWithdraw[_user] = add(AvailableToWithdraw[_user],_reward);
        emit SetDiamondReward(_user,_reward,timeStamp);  
    }
    function generateHash(address _holder,uint256 _timeStamp) public pure returns(bytes32) {
        return  keccak256(abi.encode(_holder,_timeStamp));
    }
    //timeStamp gets from freezeHistory[i]
    function claimDiamondReward() external {
        require(isDiamond(msg.sender),'diamond not active');
        require(AvailableToWithdraw[msg.sender]>0,'nothing to claim');
        
        uint reward = AvailableToWithdraw[msg.sender];
        AvailableToWithdraw[msg.sender] = 0;
        
        require(msg.sender.send(reward),'cannot send');
        emit ClaimDiamondReward(msg.sender,reward);
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    //                                  Getters - Setters
    //////////////////////////////////////////////////////////////////////////////////////
    function getUserID(address _user) public view returns(uint ){
        return users[_user].id;
    }
    function getActiveLevel(address _user,uint _level) public view returns (bool) {
        return users[_user].activeLevel[_level];
    }
    function getPartner(address _user,uint index) public view returns (address) {
        return users[_user].partnerList[index];
    }
    function setLevelPrice(uint8 _level,uint _price) public onlyOwner{
        levelPrice[_level] = _price;
    }
    function setLevelCom(uint8 _level,uint _com) public onlyOwner{
        levelCom[_level] = _com;
    }
    //diamondRankCriteria
    function setDiamondRankCriteria(uint _criteria) public onlyOwner{
        diamondRankCriteria = _criteria;
    }
    //monthlyPaymentCount
    function setMonthlyPaymentCount(address _user,uint _count) public onlyOwner{
        users[_user].monthlyPaymentCount = _count;
    }
    function setD6_DOZY_reward(uint256 reward) public onlyOwner{
        D6_DOZY_reward = reward;
    }
    function setD6_DOZY_duration(uint256 duration) public onlyOwner{
        D6_DOZY_reward = duration;
    }
    function setD6_duration(uint256 duration) public onlyOwner{
        D6_duration = duration;
    }
    //Platform_Pool
    function setPlatform_Pool(address payable _Platform_Pool) public onlyOwner{
        Platform_Pool = _Platform_Pool;
    }
    //Diamond_Pool_Percent
    function setDiamond_Pool_Percent(uint _Diamond_Pool_Percent) public onlyOwner{
        Diamond_Pool_Percent = _Diamond_Pool_Percent;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    //                                  General Functions
    //////////////////////////////////////////////////////////////////////////////////////
    function ZeroTimeStamp(uint256 timeStamp) public view returns (uint256){
        return (timeStamp / day_length) * day_length;
    }
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    function findValidReferrer(address userAddress, uint level) public view returns(address payable) {
        while (true) {
            if (users[users[userAddress].referrer].activeLevel[level] && isActive(users[userAddress].referrer)) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    function activeUntil(address _user) public view returns(uint256){
        if (!isUserExists(_user)) return 0;
        else
        return users[_user].memberDate + users[_user].monthlyPaymentCount * 30 * day_length;
    }
    function isActive(address _user) public view returns(bool){
        
        if (ZeroTimeStamp(now) <= activeUntil(_user))
            return true;
        else
            return false;
    }
    function isDiamond(address _user) public view returns(bool){
        
        if (!isActive(_user))
            return false;
            
        if (users[_user].D6_purchased && users[_user].D6_expired_date >= now){
            return true;
        }
        if (users[_user].partnersCount<diamondRankCriteria)
            return false;
        
        uint countActive=0;
        for (uint i=1;i<=users[_user].partnersCount;i++){
            if (isActive(users[_user].partnerList[i]))
                countActive++;
            if (countActive>=diamondRankCriteria)
                return true;
        }
        return false;
        
    }
    //////////////////////////////////////////////////////////////////////////////////////
    //                                  Admins
    //////////////////////////////////////////////////////////////////////////////////////
    modifier onlyOwner(){
        require(msg.sender==owner,'Not Owner');
        _;
    }
    modifier onlyMod(){
        require(msg.sender==_mod,'Not Mod');
        _;
    }
    //Protect the pool in case of hacking
    function kill() onlyOwner public {
        owner.transfer(address(this).balance);
        require(token.transfer(owner,token.balanceOf(address(this))));
        selfdestruct(owner);
    }
    function transferFund(uint256 amount) onlyOwner public {
        require(amount<=address(this).balance,'exceed contract balance');
        owner.transfer(amount);
    }
    function transferTokenFund(uint256 amount) onlyOwner public {
        require(amount<=token.balanceOf(address(this)),'exceed contract balance');
        require(token.transfer(owner,amount));
    }
    function transferOwnership(address payable _newOwner) onlyOwner external {
        require(_newOwner != address(0) && _newOwner != owner);
        owner = _newOwner;
    }
}
contract TokenContract
{
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function balanceOf(address) external view returns (uint256);
    function allowance(address _owner, address _spender) public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function mint(address account, uint256 amount) public returns (bool);
}