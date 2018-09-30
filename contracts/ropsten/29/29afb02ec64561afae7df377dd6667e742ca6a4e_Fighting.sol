pragma solidity ^0.4.4;
 
contract Constants{
    string constant TOKEN_NAME = "Fighting";
    string constant TOKEN_SYMBOL = "FIT";
    uint8 constant DECIMALS = 18;
    
    /* Wallet information */
    address constant ICO_WALLET = 0x1a6b383FC382e38a526c9eA96cFA5f7B0FBF63b8;
    address constant DEVELOPER_WALLET = 0xA06cdc2814B311b0DCd13Ef5dCd0243751247Ec8;
    
    address constant FUND_WALLET = 0x5CFA09c9225C618E33BE1eaB44FA20F9083A6108;
    
    uint256 constant DEFAULT_ETH_PRICE = 20612e16;              //$206.12
    
    /* Amount information */
    uint256 constant TOTAL_SUPPLY = 2000000000e18;              //2,000,000,000
    uint256 constant DEVELOPER_AMOUNT = 400000000e18;           //400,000,000
    uint256 constant ICO_AMOUNT = 1600000000e18;                //1,600,000,000
    uint256 constant PRESALE_TOKEN_AMOUNT = 864000000e18;        //864,000,000
    
    uint256 constant PRESALE_PRICE = 35e15;                   //1 token = $0.035
    uint256 constant PRESALE_PREFERENTIAL_PRICE = 25e15;       //1 token = $0.025
    uint256 constant CROWDSALE_PRICE = 55e15;                 //1 token = $0.055
    uint256 constant CROWDSALE_PREFERENTIAL_PRICE = 45e15;    //1 token = $0.045
    
    /*e26: msg.value(wei: 18 decimals) * ETH Price: 600.00000000(18 decimals) = 36 */
    uint256 constant PRESALE_MIN_PURCHASE = 100e36;             //$100
    uint256 constant PRESALE_MAX_PURCHASE = 1000e36;            //$1000
    uint256 constant CROWDSALE_MIN_PURCHASE = 5e36;             //$5
    uint256 constant CROWDSALE_MAX_PURCHASE = 5000e36;          //$5,000
    
    /*
    uint256 constant PRESALE_MIN_PURCHASE = 10000e26;           //$10,000
    uint256 constant PRESALE_MAX_PURCHASE = 100000e26;          //$100,000
    uint256 constant CROWDSALE_MIN_PURCHASE = 50e26;            //$50
    uint256 constant CROWDSALE_MAX_PURCHASE = 50000e26;         //$50,000
    */
    
    /* DateTime information */
    uint256 constant PRESALE_START_DATE = 1536883200;     //Oct 7, 2018
    uint256 constant PRESALE_END_DATE = 1537401599;       //Oct 12, 2018
    
    uint256 constant CROWDSALE_START_DATE = 1537401600;     //Oct 14, 2018
    uint256 constant CROWDSALE_END_DATE = 1540079999;       //Nov 30, 2018
    
    /*
    uint256 constant PRESALE_START_DATE = 1538870400;     //Oct 7, 2018
    uint256 constant PRESALE_END_DATE = 1539388799;       //Oct 12, 2018
    
    uint256 constant CROWDSALE_START_DATE = 1539475200;     //Oct 14, 2018
    uint256 constant CROWDSALE_END_DATE = 1543622399;       //Nov 30, 2018
    */
}

contract ERC20Token {

    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
 
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

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

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract EthereumInfo is Ownable, Constants{
    uint256 public ethPrice;                //divide: 10^18
    
    constructor() public {
        ethPrice = DEFAULT_ETH_PRICE;
    }
    
    //API to update ETH Price
    function updateETHPrice(uint256 price) public onlyOwner returns (bool){
       ethPrice =  price;
       
       emit UpdateETHPrice(price, "success");
       return true;
    }
    
    event UpdateETHPrice(uint256 price, string message);
}

contract User is Ownable{
    enum EUserStatus{NonActive, Active, KYCVerified, Blocked}
    enum EBuyType{Normal, Preferential}

    struct UserStruct{
        address userAddress;
        EUserStatus userStatus;
        EBuyType userBuyType;                //store last buy type
        address referralUser;
    }
    
    UserStruct[] users;
    
    function getUser(address _address) public view returns(bool existed, uint256 index){
        existed = false;
        for(uint256 i = 0; i < users.length; i++){
            if(users[i].userAddress == _address){
                existed = true;
                index = i;
                break;
            }
        }
        
        return (existed, index);
    }
    
    /*API*/
    function register(address _address, address _referralAddress) public onlyOwner returns(bool){
        //User can not is self referral
        require(_address != _referralAddress, "Referral Address is not valid.");
        
        bool existed = false;
        bool isValidReferral = true;
        for(uint256 i = 0; i < users.length; i++){
            UserStruct memory user = users[i];
            address userAddress = user.userAddress;
            //Check exist
            if(userAddress == _address){
                existed = true;
                break;
            }
            
            //Make sure referralUser is not F1 of user
            if(userAddress == _referralAddress){
                if(user.referralUser == _address){
                    isValidReferral = false;
                    break;
                }
            }
        }
        
        require(!existed, "Address has been existed.");
        require(isValidReferral, "Referral user is not valid.");
        
        UserStruct memory userStruct = UserStruct(_address, EUserStatus.NonActive, EBuyType.Normal, _referralAddress);
        users.push(userStruct);
        emit Response(true, "OK");
        
        return true;
    }
    
    function changeStatus(address _address, EUserStatus userStatus) private returns (bool){
        bool userExisted;
        uint256 userIndex;
        (userExisted, userIndex) = getUser(_address);
        require(userExisted,"User is not existed");
        
        users[userIndex].userStatus = userStatus;
        
        emit Response(true, "OK");
        return true;
    }
    
    function activateUser(address _address) public onlyOwner returns (bool){
        return changeStatus(_address, EUserStatus.Active);
    }
    
    function blockUser(address _address) public onlyOwner returns (bool){
        return changeStatus(_address, EUserStatus.Blocked);
    }
    
    function updateBuyType(address _address, int userBuyType) public onlyOwner returns (bool){
        bool userExisted;
        uint256 userIndex;
        (userExisted, userIndex) = getUser(_address);
        require(userExisted,"User is not existed");
        
        if(userBuyType == 0){
            users[userIndex].userBuyType = EBuyType.Normal;
        }else{
            users[userIndex].userBuyType = EBuyType.Preferential;
        }
        
        emit Response(true, "OK");
        return true;
    }
    
    function verifyKYC(address _address) public onlyOwner returns (bool){
        return changeStatus(_address, EUserStatus.KYCVerified);
    }
    
    /*Events*/
    event Response(bool success, string message);
}

/*
Store and process locked token bought in preferential price
*/
contract LockedToken{
    using SafeMath for uint256;
    struct LockedTokenHistory{
        uint256 amount;
        uint256 validTime;
    }
    
    //Store locked token histories
    mapping (address => LockedTokenHistory[]) lockedTokens;
    
    //Create locked token histories
    function createLockTokenHistory(address ownerAddress, uint256 tokenAmount){
        //Validate
        assert(tokenAmount > 0);          //amount > 0
        
        uint256 validTime = now.add(180 days);      //Lock for 180 days
        LockedTokenHistory memory lockedTokenHistory = LockedTokenHistory(tokenAmount,validTime);
        
        //Store histories
        LockedTokenHistory[] storage userLockedTokens = lockedTokens[ownerAddress];
        userLockedTokens.push(lockedTokenHistory);
        lockedTokens[ownerAddress] = userLockedTokens;
        
        //Nofity
        emit LockToken(ownerAddress,tokenAmount,now,validTime);
    }
    
    //Get locked token amount from lockedTokens
    function getLockedAmount(address ownerAddress) returns (uint256){
        LockedTokenHistory[] memory userLockedTokens = lockedTokens[ownerAddress];
        
        if(userLockedTokens.length == 0){
            return 0;    
        }
        
        uint256 currentTime = now;
        uint256 lockedAmount = 0;
        for(uint32 index = 0; index < userLockedTokens.length; index++){
            LockedTokenHistory memory userLockedToken = userLockedTokens[index];
            if(userLockedToken.validTime > now)
            {
                lockedAmount = lockedAmount.add(userLockedToken.amount);
            }
        }
        
        return lockedAmount;
    }
    
    event LockToken(address owner, uint256 amount, uint256 lockedTime, uint256 validTime);
}

contract StageSale is User, Constants, EthereumInfo{
    using SafeMath for uint;
    
    uint256 public preSaleTokenRemain;
    
    uint public tokenPrice;
    
    function isPresale() public view returns (bool){
        return now >= PRESALE_START_DATE && now <= PRESALE_END_DATE;
    }
    
    function isCrowdsale() public view returns (bool){
         return now >= CROWDSALE_START_DATE && now <= CROWDSALE_END_DATE;
    }
    
    function isBountyPayStage() public view returns(bool){
        return now > CROWDSALE_END_DATE && now <= CROWDSALE_END_DATE.add(10 days);
    }
    
    /*Validate amount valid limit range stage*/
    function validateAmount(uint256 weiAmount) public returns(bool){
        //Get total usdAmount by ETH Amount and ETH Price
        uint256 usdAmount = weiAmount.mul(ethPrice);
        if(isPresale()){
            if(usdAmount >= PRESALE_MIN_PURCHASE && usdAmount <= PRESALE_MAX_PURCHASE){
                return true;    
            }
        }else if(isCrowdsale()){
           if(usdAmount>= CROWDSALE_MIN_PURCHASE && usdAmount <= CROWDSALE_MAX_PURCHASE){
                return true;    
            }
        }
        
        return false;
    }
    
    /*Get current remain token amount*/
    function getTokenRemain() public returns(uint256){
        if(isPresale()){
            return preSaleTokenRemain;
        }else if(isCrowdsale()){
            return ICO_AMOUNT.sub(preSaleTokenRemain);
        }
        
        return 0;
    }
    
    /*Get token current price by user*/
    function getTokenPrice(address _address)public returns(uint256){
        bool existed;
        uint256 userIndex;
        (existed, userIndex) = getUser(_address);
        UserStruct memory user;
        if(isPresale()){
            if(!existed){
                return PRESALE_PRICE;
            }else{
                user = users[userIndex];
                if(user.userBuyType == EBuyType.Normal){
                    return PRESALE_PRICE;
                }else{
                    return PRESALE_PREFERENTIAL_PRICE;
                }
            }
        }else if(isCrowdsale()){
            if(!existed){
                return CROWDSALE_PRICE;
            }else{
                user = users[userIndex];
                if(user.userBuyType == EBuyType.Normal){
                    return CROWDSALE_PRICE;
                }else{
                    return CROWDSALE_PREFERENTIAL_PRICE;
                }
            }
        }
        return 0;
    }
}

contract Fighting is StandardToken, StageSale, LockedToken {
    using SafeMath for uint256;
    /* Public variables of the token */

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;1.0&#39;;
    uint256 public totalEthInWei;         

    /* Constructor */
    constructor() public {
        //Initialize token information
        name = TOKEN_NAME;
        symbol = TOKEN_SYMBOL;
        decimals = DECIMALS;
        
        totalSupply = TOTAL_SUPPLY;                         //Total supply: 2,000,000,000 tokens
        
        //Send tokens to system wallets
        balances[ICO_WALLET] = ICO_AMOUNT;                  //Send 1,600,000,000 tokens to ICO wallet
        balances[DEVELOPER_WALLET] = DEVELOPER_AMOUNT;       //Send 400,000,000 tokens to developer wallet
        
        //Log PreSale Token remaining
        preSaleTokenRemain = PRESALE_TOKEN_AMOUNT;
        
        owner = msg.sender;
    }

     /* Fire when user sends ETH to Smart Contract */
    function() public payable{
        //ICO wallet cannot buy token
        require(msg.sender != ICO_WALLET,"ICO Wallet can not be used to buy token.");
        
        //Only buy token in ICO: PreSale and CrowdSale
        require(isPresale() || isCrowdsale(),"Can only buy token in ICO.");
        
        //Check limit buy token amount per buy time in presale and CrowdSale
        uint256 weiAmount = msg.value;
        require(validateAmount(weiAmount),"ETH value is not valid.");
        
        //Calculate token will be send to user
        bool userExisted;
        uint256 userIndex;
        address userAddress = msg.sender;
        (userExisted, userIndex) = getUser(userAddress);
        
        if(userExisted && users[userIndex].userStatus == EUserStatus.Blocked){
            //For blocked user, get ETH without paying Token    
        }else{
            //Check remain token is enough
            require(getTokenRemain() > 0, "Not enough token to pay.");
        
            uint256 tokenPrice = getTokenPrice(userAddress);
            require(tokenPrice > 0);
            
            require(ethPrice > 0);
            
            //1ETH = ethPrice / tokenPrice; temp: 10^18 to get decimals
            uint256 ethToTokenPrice = ethPrice.mul(1e18).div(tokenPrice);
            uint256 tokenAmount = ethToTokenPrice.mul(weiAmount).div(1e18);
            require(tokenAmount > 0, "Token amount should be greater than 0.");
            
            uint256 requiredToken = tokenAmount;
            uint256 referralToken = requiredToken.mul(3).div(100);
            //Make sure token enough for current user and refferal user
            if(userExisted){
                requiredToken = requiredToken.add(referralToken);
            }
            
            //IF: PRESALE: Check tokenAmount <= remainToken
            if(isPresale()){
                require(tokenAmount <= preSaleTokenRemain);
            }
            
            //Check balance of ICO wallet
            require(balances[ICO_WALLET] >= requiredToken);
            
            //Reduce token in ICO wallet
            balances[ICO_WALLET] = balances[ICO_WALLET].sub(tokenAmount);
            
            //Pay token for user
            balances[userAddress] = balances[userAddress].add(tokenAmount);
            emit Transfer(ICO_WALLET, userAddress, tokenAmount);
            
            if(isPresale()){
                preSaleTokenRemain = preSaleTokenRemain.sub(tokenAmount);
            }
            
            //Increase ETH Raised
            totalEthInWei= totalEthInWei.add(weiAmount);
            
            if(userExisted){
                UserStruct memory user = users[userIndex];
                
                //Pay for referral user
                address referralAddress = user.referralUser;
               
                balances[ICO_WALLET] = balances[ICO_WALLET].sub(referralToken);
                    
                balances[referralAddress] = 
                    balances[referralAddress].add(referralToken);
                    
                emit Transfer(ICO_WALLET, referralAddress, referralToken);
                
                //Check to lock user token
                if(user.userBuyType == EBuyType.Preferential){
                    createLockTokenHistory(userAddress, tokenAmount);
                }
            }
        }
        
        //Transfer ether to storedETHWallet
        FUND_WALLET.transfer(msg.value);                               
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
    
    /* Override transfer function */
    function transfer(address _to, uint256 _value) returns (bool success) {
        address sender = msg.sender;
        
        //ICO Wallet can only transfer on ICO
        if(sender == ICO_WALLET){
            require(isPresale() || isCrowdsale() || isBountyPayStage(),"ICO wallet can only transfer in ICO stage.");
        }
        
        uint256 lockedToken = getLockedAmount(sender);
        uint256 tokenBalance = balances[sender].sub(lockedToken);
        
        //Check locked token when user transfer token
        if (tokenBalance >= _value && _value > 0) {
            balances[sender] = balances[sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //ICO Wallet can only transfer on ICO
        if(_from == ICO_WALLET){
            require(isPresale() || isCrowdsale() || isBountyPayStage(), "ICO wallet can only transfer in ICO stage.");
        }
        
        uint256 lockedToken = getLockedAmount(_from);
        uint256 tokenBalance = balances[_from].sub(lockedToken);
        
        if (tokenBalance >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
}