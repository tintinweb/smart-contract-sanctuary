/*
*******
*******


██████╗ ██╗  ██╗ ██████╗ ███████╗███╗   ██╗██╗██╗  ██╗████████╗██╗ ██████╗ ███████╗██████╗ 
██╔══██╗██║  ██║██╔═══██╗██╔════╝████╗  ██║██║╚██╗██╔╝╚══██╔══╝██║██╔════╝ ██╔════╝██╔══██╗
██████╔╝███████║██║   ██║█████╗  ██╔██╗ ██║██║ ╚███╔╝    ██║   ██║██║  ███╗█████╗  ██████╔╝
██╔═══╝ ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║██║ ██╔██╗    ██║   ██║██║   ██║██╔══╝  ██╔══██╗
██║     ██║  ██║╚██████╔╝███████╗██║ ╚████║██║██╔╝ ██╗   ██║   ██║╚██████╔╝███████╗██║  ██║
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                           
copyright@2020 PHOENIXTIGER.IO

-Developed by Kryptual Team

****                                                          
*/

pragma solidity >=0.4.23 <0.6.0;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    function Ownable() public {
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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(msg.sender, owner, fee);
        }
        Transfer(msg.sender, _to, sendAmount);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(_from, owner, fee);
        }
        Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external constant returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}

contract TetherToken is Pausable, StandardToken, BlackList {

    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    function TetherToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public constant returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public constant returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        Issue(amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        Params(basisPointsRate, maximumFee);
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
}



contract PhoenixTiger {
    TetherToken tether;
    
    /*-----------Public Variables---------------
    -----------------------------------*/
    address public owner;
    address public expenseAddress;
    uint public totalGpv  ;
    uint public orgEli = 100000000000000000000000;
    uint public millEli = 1000000000000000000000000;
    uint public gloEli = 250000000000000000000000;
    uint public countEli = 100000000000000000000000;
    uint public orgDownEli = 100000000000000000000000;
    uint public millDownEli = 1000000000000000000000000; 

    /*-----------Private Varibales---------------
    -----------------------------------*/
    uint private total_packs = 15;
    uint private totalcountry = 200;
    uint private countrycommissionprice = 2;
    uint private globalcommissionprice = 1;
   

    /*-----------Mapping---------------
    -----------------------------------*/
    mapping(address => bool) public nonEcoUser;
    mapping(address => User) public users;
    mapping(address => bool) public userExist;
    mapping(uint => uint) public totalCountryGpv;
    mapping(address => uint[]) private userPackages;
    mapping(uint=>address[]) private countrypool;
    mapping(address => bool) public orgpool;
    mapping(address=> bool) public millpool;
    mapping(address => bool) public globalpool;
    mapping(address=>address[]) public userDownlink;
    mapping(address => bool) public isRegistrar;
    mapping(address=> uint) public userLockTime;
    mapping(address =>bool) public isCountryEli;    
    
    /*-----------Arrays--------------
    -----------------------------------0x0000000000000000000000000000000000000000*/
    
    uint[12] public Packs;
    
    
    /*-----------enums---------------
    -----------------------------------*/
    enum Status {CREATED, ACTIVE }

    /*----------Modifier-------------
    -----------------------------------*/
    modifier onlyOwner(){
      require(msg.sender == owner,"only owner");
      _;
    }

    /*-----------Structures---------------
    -----------------------------------*/
    struct User {
        uint countrycode;
        uint pbalance;
        uint rbalance;
        uint rank;
        uint gHeight;
        uint gpv;
        uint[2] lastBuy;   //0- time ; 1- pack;
        uint[7] earnings;  // 0 - team earnings; 1 - family earnings; 2 - match earnings; 3 - country earnings, 4- organisation, 5 - global, 6 - millionaire
        bool isbonus;
        bool isKyc;
        address teamaddress;
        address familyaddress;
        Status status;
        uint traininglevel;
        mapping(uint=>TrainingLevel) trainingpackage;
    }
    
    struct TrainingLevel {
        uint package;
        bool purchased;

    }
    /*-----------EVENTS---------------
    -----------------------------------*/
    event Registration(
                
                address useraddress,
                uint countrycode,
                uint gHeight,
                bool isBonus,
                address teamaddress,
                address familyaddress
    );

    event Buypackage (
                address useraddress,
                uint pack,
                uint gpv,
		        uint lastBuy,
		        uint rank,
		        uint teamDisbursed,
		        uint familyDisbursed,
		        uint MatchDisbursed,
		        uint countryDisbursed,
		        uint OmgDisbursed
            );

    event RaiseTrainingLevel(
            
                address useraddress,
                uint tlevel,
                uint gpv,
                uint rank
            );

    event RedeemEarning(
            
                address useraddress,
                uint pbalance,
                uint redeemedAmount,
                uint rbalance,
                uint gpv
            );
            
    event LockTimeUpdate(
                address useraddress,
                uint locktime
            );
 
    event KycDone(
                address useraddress
            );
            
    /*-----------Constructor---------------
    -----------------------------------*/

    constructor(address ownerAddress,address _expenseAddress) public {

        tether = TetherToken(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        Packs = [0,500, 1000, 2000, 5000, 10000, 20000,50000,100000,250000, 500000, 1000000];

        owner = ownerAddress;
        expenseAddress = _expenseAddress;
        isRegistrar[owner] = true;
  
        address master = 0x3417F6448eeDbf8737af2cef9Ca2d2dd2Ee3d543;
        
        userExist[master] = true;
        User memory user;
        user= User({
            
            teamaddress : address(0),
            countrycode: 192,
            isbonus : false,
            familyaddress : address(0),
            pbalance: 0,
            rbalance : 0,
            rank : 0,
            gHeight: 1,
            status : Status.ACTIVE,
            traininglevel : 0,
            gpv : 0,
            isKyc:false,
            lastBuy:[uint(0),0],
            earnings:[uint(0),0,0,0,0,0,0]
        });
        nonEcoUser[master] = true;
        users[master] = user; //Master
    }
    
    /*-----------Main functions---------------
    -------------------------------------------*/
    
    function superRegister(address useraddress,address referrerAddress,uint usercountry,uint pack) external onlyOwner{
        require(!isUserExists(useraddress) && isUserExists(referrerAddress), "user exists");
        require(checkCountry(usercountry), "country must be from 0 to 200");
        require(isAddress(useraddress), "cannot be a contract");
       
        totalCountryGpv[usercountry] += Packs[pack]*1000000000000000000;
        totalGpv += Packs[pack]*1000000000000000000;
       
        userExist[useraddress] = true;
        nonEcoUser[useraddress] = true;
        User memory user = User({
            
            teamaddress : referrerAddress,
            countrycode: usercountry,
            isbonus : false,
            familyaddress : getFamilyFromReferral(referrerAddress),
            pbalance: 0,
            rbalance : 0,
            rank : pack,
            gHeight: users[referrerAddress].gHeight+1,
            status : Status.ACTIVE,
            gpv :0,
            isKyc : false,
            lastBuy:[uint(0),0],
            traininglevel :0,
            earnings:[uint(0),0,0,0,0,0,0]
        });
        
        isCountryEli[useraddress] = true;
        globalpool[useraddress] = true;
        millpool[useraddress] =true;
        orgpool[useraddress] = true;
        
        users[useraddress].trainingpackage[pack].package=pack;
        users[useraddress].traininglevel=0;
        users[useraddress].trainingpackage[pack].purchased=true;     
      
        userLockTime[useraddress] = 0;
        userPackages[useraddress].push(pack);
        countrypool[usercountry].push(useraddress);
        users[useraddress] = user;
        userDownlink[referrerAddress].push(useraddress);
        /*-------------------Emitter--------------*/
        emit Registration(
            
            useraddress,
            users[useraddress].countrycode,
            users[useraddress].gHeight,
            users[useraddress].isbonus,
            users[useraddress].teamaddress,
            users[useraddress].familyaddress
        );        
    }
    
    function registration(address useraddress, address referrerAddress, uint usercountry,uint locktime) external {
        require(!isUserExists(useraddress) && isUserExists(referrerAddress), "user exists");
        require(msg.sender == useraddress);
        require(referrerAddress != address(0),"referrerAddress cannot be zero address");
        require(checkCountry(usercountry), "country must be from 0 to 200");
        require(isAddress(useraddress) && isAddress(referrerAddress), "cannot be a contract");
        
        address teamaddress = referrerAddress;
    
        userExist[useraddress] = true;
        User memory user = User({
            
            teamaddress : teamaddress,
            // packlevel : 0,
            countrycode: usercountry,
            isbonus : false,
            familyaddress : getFamilyFromReferral(teamaddress),
            pbalance: 0,
            rbalance : 0,
            rank : 0,
            gHeight: getHeight(teamaddress),
            status : Status.CREATED,
            gpv :0,
            isKyc : false,
            lastBuy:[uint(0),0],
            traininglevel :0,
            earnings:[uint(0),0,0,0,0,0,0]
        });
        
        userLockTime[useraddress] = locktime;
        
        countrypool[usercountry].push(useraddress);

        userDownlink[teamaddress].push(useraddress);
        users[useraddress] = user;

        /*-------------------Emitter--------------*/
        emit Registration(
            
            useraddress,
            users[useraddress].countrycode,
            users[useraddress].gHeight,
            users[useraddress].isbonus,
            users[useraddress].teamaddress,
            users[useraddress].familyaddress
        );

    }

    function buypackage( uint pack ,uint amount) public {
        
        uint _amount = amount/1000000000000000000;
        require(isUserExists(msg.sender), "user not exists");
        require(pack > users[msg.sender].lastBuy[1] && pack < total_packs, "check pack purchase");
        require(Packs[pack]<= _amount, "invalid amount of wholesale package purchase");
        require(tether.allowance(msg.sender,address(this)) >= amount,"set allowance");
        
        tether.transferFrom(msg.sender,address(this),amount); 
        
        if(discountValid(msg.sender,pack)){
            uint newAmount = (Packs[pack] - Packs[users[msg.sender].lastBuy[1]])*1000000000000000000;
            tether.transfer(msg.sender,Packs[users[msg.sender].lastBuy[1]]*1000000000000000000);    
            disburse(msg.sender, newAmount, pack);            
        }else{
            disburse(msg.sender, amount, pack);
        }
        userPackages[msg.sender].push(pack);

        users[msg.sender].lastBuy = [now,pack];
    }
    
    function raiseTrainingLevel(address [] useraddress, uint[] pack) external  payable {
        require(isRegistrar[msg.sender],"Not a registrar");
        require(useraddress.length == pack.length,"useraddress length not equal to packs length");
       for(uint i=0;i<useraddress.length;i++){
        require(isUserExists(useraddress[i]), "user not exists");
        require(total_packs >= pack[i], "invalid pack");

        require(users[useraddress[i]].trainingpackage[pack[i]].purchased, "Pack is not purchased.");
        users[useraddress[i]].isbonus = true;
        users[useraddress[i]].traininglevel= ++users[useraddress[i]].traininglevel;

        emit RaiseTrainingLevel(
            
            useraddress[i],
            users[useraddress[i]].traininglevel,
            users[useraddress[i]].gpv,
            users[useraddress[i]].rank
        );   
       }
        

    }

    function redeemEarning(address useraddress, uint amount) public{
        require(isUserExists(useraddress), "user not exists");
        require(users[useraddress].pbalance >= amount, "Insufficient balance for withdrawl");

        users[useraddress].pbalance = users[useraddress].pbalance - amount;
        tether.transfer(useraddress,amount);
        users[useraddress].rbalance = users[useraddress].rbalance + amount;

        emit RedeemEarning(
            
            useraddress,
            users[useraddress].pbalance,
            amount,
            users[useraddress].rbalance,
            users[useraddress].gpv
        );
    }

    /*-----------non-payable functions---------------
    -----------------------------------*/

    function addRegistrar(address registrar) public onlyOwner{
        isRegistrar[registrar] = true;
    }
    
    function removeRegistrar(address registrar) public onlyOwner{
        isRegistrar[registrar] = false;
    } 
    
    function updateLockTime(address useraddress ,uint locktime ) public{
        require(useraddress==msg.sender);
        require(locktime> 6,"must be greater than 6 months");
        require(isUserExists(useraddress),"user not exist");
        userLockTime[useraddress] = locktime;
        
        emit LockTimeUpdate(
            useraddress, 
            locktime
        );
    }
    
    function discountValid(address useraddress,uint pack) public view returns(bool _bool){
       uint  _lastPack =  users[useraddress].lastBuy[1] ;
       uint  _lastTime =  users[useraddress].lastBuy[0];
       
       if(_lastPack==0 || pack<= _lastPack || now - _lastTime >= 30 days){
           return false;
       }else{
           return true;
       }
    }
    
    function getEarnings(address useraddress) public view returns(uint[7] memory _earnings){
        return users[useraddress].earnings;
    }
    
    function getCountryUsersCount(uint country) public view returns (uint count){
        return countrypool[country].length;
    }

    function getTrainingLevel(address useraddress, uint pack) public view returns (uint tlevel, uint upack) {
        return (users[useraddress].traininglevel, pack);

    }

    function getUserDownLink(address useraddress) public view  returns (address[] memory addr) {
        if(userDownlink[useraddress].length != 0){
            return userDownlink[useraddress];
        }
        else{
            address[] memory pack;
            return pack ;
        }
    }

    /*-----------Helper functions---------------
    -----------------------------------*/
    function disburseTether(address useraddress) private{
        if(users[useraddress].pbalance >= 250000000000000000000){
           
            tether.transfer(useraddress,users[useraddress].pbalance);
            users[useraddress].rbalance += users[useraddress].pbalance;
            users[useraddress].pbalance = 0;
            
        }
    }
    
    function getAllPacksofUsers(address useraddress) public view returns(uint[] memory pck) {
        return userPackages[useraddress];
    }

    function getAllLevelsofUsers(address useraddress,uint pack) public view returns(uint lvl) {
        
        if(users[useraddress].trainingpackage[pack].purchased){
            return users[useraddress].traininglevel;
        }
        
        return 0;
    }

    function isAddress(address _address) private view returns (bool value){
        uint32 size;
        assembly {
                size := extcodesize(_address)
        }
        return(size==0);
    }

    function isUserExists(address user) public view returns (bool) {
        return userExist[user];
    }

    function checkCountry(uint country) private pure returns (bool) {
        return (country <= 200);
    }

    function getFamilyFromReferral(address referrerAddres) private view returns (address addr) {
        if (users[referrerAddres].teamaddress != address(0)){
            return users[referrerAddres].teamaddress;
        }
        else {
            return address(0);
        }
    }

    function getFamilyFromUser(address useraddress) private view returns (address addr) {
        if (users[users[useraddress].teamaddress].teamaddress != address(0)){
            return users[users[useraddress].teamaddress].teamaddress;
        }
        else {
            return address(0);
        }
    }

    function getTeam(address useraddress) private view returns (address addr) {
        return users[useraddress].teamaddress;
    }

    function getGminus2(address useraddress) private view returns (address gaddr) {

        if(users[useraddress].teamaddress == address(0)){
            return address(0);
        }
        else{
            return users[users[useraddress].teamaddress].familyaddress;
        }
    }
    
    function getHeight(address referrerAddres) private view returns (uint ghgt) {
        return users[referrerAddres].gHeight +1;
    }

    function disburse(address useraddress, uint amount, uint pack) private {

      uint leftamount;
      uint disbursedamount;

      
      //disburse 10% to the team
      disbursedamount = disburseTeam(useraddress, amount);
      uint teamDisbursed = disbursedamount;
      leftamount = amount - disbursedamount;

      //disburse 3% to family
      disbursedamount = disburseFamily(useraddress,  amount);
      uint familyDisbursed = disbursedamount;
      leftamount = leftamount - disbursedamount;

      //disbruse 4% to match and +1% +2% +3% to higher rank users
      disbursedamount = disburseMatch(useraddress,amount);
      uint MatchDisbursed = disbursedamount;
      leftamount = leftamount - disbursedamount;

      //disburse 2% to country
      disbursedamount = disburseCountryPool(useraddress, amount);
      uint countryDisbursed = disbursedamount;
      leftamount = leftamount - disbursedamount;

      //disburse 1% to Global
      disbursedamount = disburseOMGPool(useraddress, amount);
      uint OmgDisbursed = disbursedamount;
      leftamount = leftamount - disbursedamount;
      
      payoutGpv(useraddress,amount);
      tether.transfer(expenseAddress,leftamount);
      /* address(uint160(owner)).transfer(leftamount); */
      
      users[useraddress].status = Status.ACTIVE;
      // users[msg.sender].packlevel = pack;
      users[useraddress].rank = pack;
      //users[msg.sender].trainingpackage[0].traininglevel[pack]=0;

      users[useraddress].trainingpackage[pack].package=pack;
      users[useraddress].traininglevel=0;
      users[useraddress].trainingpackage[pack].purchased=true;     
      emit Buypackage (
          msg.sender,
          pack,
          users[msg.sender].gpv,
          users[msg.sender].lastBuy[0],
          users[msg.sender].rank,
          teamDisbursed,
          familyDisbursed,
          MatchDisbursed,
          countryDisbursed,
          OmgDisbursed
      );
    }

    function disburseTeam(address useraddress, uint amount) private  returns (uint amnt) {
        address teamaddress = getTeam(useraddress);
        if(teamaddress == address(0)){
            return 0;
        }
        else if(users[teamaddress].status == Status.CREATED) {
            return amount;
        }
        else{
            users[teamaddress].pbalance = users[teamaddress].pbalance+ (amount * 10)/100;
            disburseTether(teamaddress);
            users[teamaddress].earnings[0] += (amount * 10)/100;
            // gpvUpdater(useraddress,teamaddress);
            return (amount * 10)/100;
        }
    }

    function disburseFamily(address useraddress, uint amount) private  returns (uint amnt) {
        address familyaddress = getFamilyFromUser(useraddress);
        if(familyaddress != address(0)){
            if(users[familyaddress].status == Status.CREATED){
                return 0;
            }
            else{
                users[familyaddress].pbalance = users[familyaddress].pbalance+ (amount * 30)/1000;
                disburseTether(familyaddress);
                users[familyaddress].earnings[1] += (amount * 30)/1000;
                
                return (amount * 30)/1000;
            }
        }
        else {
            return 0;
        }
    }

    function disburseMatch(address useraddress, uint amount) private  returns (uint amnt) {
        
        address familyaddress = getFamilyFromUser(useraddress);
        if(familyaddress != address(0)){
            users[familyaddress].earnings[2] += (amount * 4)/1000;
        }else{
            return 0;
        }

        address teamaddress = getTeam(familyaddress);
        if(teamaddress != address(0)){
            users[teamaddress].earnings[2] += (amount * 136)/100000;
            amount = (amount * 136)/100000;
        }else{
            return 0;
        }

        address matchaddress = getGminus2(useraddress);
        
        uint commissionamount;
        uint disbursed ;
        
        uint gold_due;
        uint diamond_due;
        uint plat_due;
        
        if(matchaddress==address(0)){
            return 0;
        }
        else{
            while(matchaddress != address(0)){

                if(users[matchaddress].status == Status.CREATED){
                    matchaddress = users[matchaddress].teamaddress;
                    // disbursed = disbursed + amount;
                    return disbursed;
                }
                else{
                    
                    commissionamount = (amount *4 )/100; //comission = 4%
                    
                    gold_due = gold_due +commissionamount;
                    diamond_due = diamond_due + commissionamount;
                    plat_due = plat_due + commissionamount;
                    
                    if( users[useraddress].trainingpackage[11].purchased){//PlatinumFounder
                        commissionamount += (plat_due*3)/100;
                        
                        plat_due = 0;
                       
                    }
                    else if( users[useraddress].trainingpackage[10].purchased){//DiamondFounder
                        commissionamount += (diamond_due*2)/100;
                        
                        diamond_due = 0;
                      
                    }
                    else if( users[useraddress].trainingpackage[9].purchased ){  // Gold-founder
                        commissionamount += (gold_due)/100;
                        
                        gold_due = 0;
                        
                    }
                 
                    users[matchaddress].pbalance = users[matchaddress].pbalance+ commissionamount;
                    disburseTether(matchaddress);
                    users[matchaddress].earnings[2] += commissionamount;
                    matchaddress = users[matchaddress].teamaddress;
                    amount = commissionamount;
                    disbursed = disbursed + amount;
                }
            }
            return disbursed;
        }
    }

    function disburseCountryPool(address useraddress, uint amount) private  returns (uint amnt) {
        uint country = users[useraddress].countrycode;
        uint disbursed;

        for(uint i=0; i < countrypool[country].length ; i++){
            if(users[countrypool[country][i]].status == Status.CREATED  && isCountryEli[countrypool[country][i]] == false ){
                continue;
            }
            else{
                
                uint gpv = users[countrypool[country][i]].gpv;
                users[countrypool[country][i]].pbalance = users[countrypool[country][i]].pbalance+ (amount * countrycommissionprice*gpv)/(100*totalCountryGpv[users[useraddress].countrycode]);
                disburseTether(countrypool[country][i]);
                users[countrypool[country][i]].earnings[3] += (amount * countrycommissionprice*gpv)/(100*totalCountryGpv[users[useraddress].countrycode]);
                disbursed = disbursed + (amount * countrycommissionprice*gpv)/(100*totalCountryGpv[users[useraddress].countrycode]);
                i++;
            }
        }
        return disbursed;
    }

    function disburseOMGPool(address useraddress, uint amount) private  returns (uint amnt) {
        uint disbursed;
        for(uint i= 0 ; i<=totalcountry; i++){
            for (uint j=0 ; j < countrypool[i].length ; j++){
                if(users[countrypool[i][j]].status == Status.CREATED  && countrypool[i][j] == useraddress){
                    continue;
                }
                else{
                    uint gpv = users[countrypool[i][j]].gpv;
                    if(orgpool[countrypool[i][j]] ){
                        users[countrypool[i][j]].earnings[4] += (amount * globalcommissionprice*gpv)/(100*totalGpv);
                        disbursed = disbursed + (amount * globalcommissionprice*gpv)/(100*totalGpv);
                    }
                    if(globalpool[countrypool[i][j]] ){
                        users[countrypool[i][j]].earnings[5] += (amount * globalcommissionprice*gpv)/(100*totalGpv);
                        disbursed = disbursed + (amount * globalcommissionprice*gpv)/(100*totalGpv);
                    }
                    if(millpool[countrypool[i][j]] ){
                        users[countrypool[i][j]].earnings[6] += (amount * globalcommissionprice*gpv)/(100*totalGpv);
                        disbursed = disbursed + (amount * globalcommissionprice*gpv)/(100*totalGpv);
                    }
                    users[countrypool[i][j]].pbalance = users[countrypool[i][j]].pbalance+ disbursed;
                    disburseTether(countrypool[i][j]);
                }
            }
        }

        return disbursed;
    }

    function checkPackPurchased(address useraddress, uint pack) public view returns (uint userpack, uint usertraininglevel, bool packpurchased){
        if(users[useraddress].trainingpackage[pack].purchased){
            return (pack, users[useraddress].traininglevel, users[useraddress].trainingpackage[pack].purchased);
        }
    }

    function payoutGpv(address useraddress,uint amount) private{

        totalGpv = totalGpv + (amount*(users[useraddress].gHeight-1));  
        totalCountryGpv[users[useraddress].countrycode] = totalCountryGpv[users[useraddress].countrycode] + (amount*users[useraddress].gHeight-1);
        address _Address = users[useraddress].teamaddress;
        for(uint i = users[useraddress].gHeight-1 ; i>0 ;i--){
            users[_Address].gpv += amount;
            _Address = users[_Address].teamaddress;
            
            if(users[_Address].gpv > orgEli  && checkEligible(_Address,orgDownEli)){
                orgpool[_Address] = true;
            }
            if(users[_Address].gpv > millEli && checkEligible(_Address,millDownEli)){
                millpool[_Address] = true;
            }
            if(users[_Address].gpv > gloEli){
                globalpool[_Address] = true;
            }
            if(users[_Address].gpv > countEli && users[_Address].isKyc == true){
                isCountryEli[_Address] =true;
            }
         }
    }
    
    function checkEligible(address useraddress,uint amount) private view returns(bool){
        uint a = 0 ;
        address [] memory _addresses = getUserDownLink(useraddress);
        if(_addresses.length < 5){
                return false;
        }
        for(uint i =0;i< _addresses.length;i++){
            if(users[_addresses[i]].gpv > amount){
                a += 1;
             }
            if(a>=5){
              return true;
            }
        }
        return false;
        
    }
    
    function setKyc(address useraddress) public onlyOwner{
        users[useraddress].isKyc = true;
        
        emit KycDone(
            useraddress
            );
    } 
    
    function updateEligibilty(uint _orgEli,uint _millEli,uint _gloEli,uint _countEli,uint _orgDownEli,uint _millDownEli ) public onlyOwner{
         uint i;
         uint j;
        millDownEli = _millDownEli;
        orgDownEli = _orgDownEli;
    
      if(orgEli != _orgEli){
         orgEli = _orgEli;
         for(  i= 0; i<totalcountry;i++){
             for( j=0; j<countrypool[i].length; j++){
                 orgpool[countrypool[i][j]] = false;
                if(checkEligible(countrypool[i][j],orgEli)){
                     orgpool[countrypool[i][j]] = true;
                } 
             }
         }
     }
     if(millEli != _millEli){
         millEli = _millEli;
         for(  i= 0; i<totalcountry;i++){
             for( j=0; j<countrypool[i].length; j++){
                 millpool[countrypool[i][j]] = false;
                if(checkEligible(countrypool[i][j],orgEli)){
                     millpool[countrypool[i][j]] = true;
                } 
             }
         }
     }     
     if(gloEli != _gloEli){
         gloEli = _gloEli;
         for(  i= 0; i<totalcountry;i++){
             for( j=0; j<countrypool[i].length; j++){
                globalpool[countrypool[i][j]] = false;
                if(users[countrypool[i][j]].gpv > gloEli){
                    globalpool[countrypool[i][j]] = true;
                }
             }
         }
     }
     if(countEli != _countEli){
         countEli = _countEli;
         for(  i= 0; i<totalcountry;i++){
             for( j=0; j<countrypool[i].length; j++){
                 isCountryEli[countrypool[i][j]] = false;
                if(users[countrypool[i][j]].gpv > countEli && users[countrypool[i][j]].isKyc == true){
                    isCountryEli[countrypool[i][j]] =true;
                }               
             }
         }
     }
    }
    
    
}