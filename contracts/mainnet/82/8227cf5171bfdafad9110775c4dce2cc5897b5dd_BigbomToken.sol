/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  
  event Transfer(address indexed _from, address indexed _to, uint _value);
  //event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  //event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    //balances[_from] = balances[_from].sub(_value); // this was removed
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
contract BigbomPrivateSaleList is Ownable {
    mapping(address=>uint) public addressCap;

    function BigbomPrivateSaleList() public  {}

    event ListAddress( address _user, uint _amount, uint _time );

    // Owner can delist by setting amount = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _amount ) public onlyOwner {
        require(_user != address(0x0));

        addressCap[_user] = _amount;
        ListAddress( _user, _amount, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _amount ) public onlyOwner {
        require(_users.length == _amount.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _amount[i] );
        }
    }

    function getCap( address _user ) public constant returns(uint) {
        return addressCap[_user];
    }

}

contract BigbomToken is StandardToken, Ownable {
    
    string  public  constant name = "Bigbom";
    string  public  constant symbol = "BBO";
    uint    public  constant decimals = 18;
    uint    public   totalSupply = 2000000000 * 1e18; //2,000,000,000

    uint    public  constant founderAmount = 200000000 * 1e18; // 200,000,000
    uint    public  constant coreStaffAmount = 60000000 * 1e18; // 60,000,000
    uint    public  constant advisorAmount = 140000000 * 1e18; // 140,000,000
    uint    public  constant networkGrowthAmount = 600000000 * 1e18; //600,000,000
    uint    public  constant reserveAmount = 635000000 * 1e18; // 635,000,000
    uint    public  constant bountyAmount = 40000000 * 1e18; // 40,000,000
    uint    public  constant publicSaleAmount = 275000000 * 1e18; // 275,000,000

    address public   bbFounderCoreStaffWallet ;
    address public   bbAdvisorWallet;
    address public   bbAirdropWallet;
    address public   bbNetworkGrowthWallet;
    address public   bbReserveWallet;
    address public   bbPublicSaleWallet;

    uint    public  saleStartTime;
    uint    public  saleEndTime;

    address public  tokenSaleContract;
    BigbomPrivateSaleList public privateSaleList;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint) public frozenTime;
    mapping (address => uint) public maxAllowedAmount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen, uint _seconds);
   

    function checkMaxAllowed(address target)  public constant  returns (uint) {
        var maxAmount  = balances[target];
        if(target == bbFounderCoreStaffWallet){
            maxAmount = 10000000 * 1e18;
        }
        if(target == bbAdvisorWallet){
            maxAmount = 10000000 * 1e18;
        }
        if(target == bbAirdropWallet){
            maxAmount = 40000000 * 1e18;
        }
        if(target == bbNetworkGrowthWallet){
            maxAmount = 20000000 * 1e18;
        }
        if(target == bbReserveWallet){
            maxAmount = 6350000 * 1e18;
        }
        return maxAmount;
    }

    function selfFreeze(bool freeze, uint _seconds) public {
        // selfFreeze cannot more than 7 days
        require(_seconds <= 7 * 24 * 3600);
        // if unfreeze
        if(!freeze){
            // get End time of frozenAccount
            var frozenEndTime = frozenTime[msg.sender];
            // if now > frozenEndTime
            require (now >= frozenEndTime);
            // unfreeze account
            frozenAccount[msg.sender] = freeze;
            // set time to 0
            _seconds = 0;           
        }else{
            frozenAccount[msg.sender] = freeze;
            
        }
        // set endTime = now + _seconds to freeze
        frozenTime[msg.sender] = now + _seconds;
        FrozenFunds(msg.sender, freeze, _seconds);
        
    }

    function freezeAccount(address target, bool freeze, uint _seconds) onlyOwner public {
        
        // if unfreeze
        if(!freeze){
            // get End time of frozenAccount
            var frozenEndTime = frozenTime[target];
            // if now > frozenEndTime
            require (now >= frozenEndTime);
            // unfreeze account
            frozenAccount[target] = freeze;
            // set time to 0
            _seconds = 0;           
        }else{
            frozenAccount[target] = freeze;
            
        }
        // set endTime = now + _seconds to freeze
        frozenTime[target] = now + _seconds;
        FrozenFunds(target, freeze, _seconds);
        
    }

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        require(!frozenAccount[to]);                       // Check if recipient is frozen
        _;
    }
    modifier validFrom(address from){
        require(!frozenAccount[from]);                     // Check if sender is frozen
        _;
    }
    modifier onlyWhenTransferEnabled() {
        if( now <= saleEndTime && now >= saleStartTime ) {
            require( msg.sender == tokenSaleContract );
        }
        _;
    }
    modifier onlyPrivateListEnabled(address _to){
        require(now <= saleStartTime);
        uint allowcap = privateSaleList.getCap(_to);
        require (allowcap > 0);
        _;
    }
    function setPrivateList(BigbomPrivateSaleList _privateSaleList)   onlyOwner public {
        require(_privateSaleList != address(0x0));
        privateSaleList = _privateSaleList;

    }
    
    function BigbomToken(uint startTime, uint endTime, address admin, address _bbFounderCoreStaffWallet, address _bbAdvisorWallet,
        address _bbAirdropWallet,
        address _bbNetworkGrowthWallet,
        address _bbReserveWallet, 
        address _bbPublicSaleWallet
        ) public {

        require(admin!=address(0x0));
        require(_bbAirdropWallet!=address(0x0));
        require(_bbAdvisorWallet!=address(0x0));
        require(_bbReserveWallet!=address(0x0));
        require(_bbNetworkGrowthWallet!=address(0x0));
        require(_bbFounderCoreStaffWallet!=address(0x0));
        require(_bbPublicSaleWallet!=address(0x0));

        // Mint all tokens. Then disable minting forever.
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);
        // init internal amount limit
        // set address when deploy
        bbAirdropWallet = _bbAirdropWallet;
        bbAdvisorWallet = _bbAdvisorWallet;
        bbReserveWallet = _bbReserveWallet;
        bbNetworkGrowthWallet = _bbNetworkGrowthWallet;
        bbFounderCoreStaffWallet = _bbFounderCoreStaffWallet;
        bbPublicSaleWallet = _bbPublicSaleWallet;
        
        saleStartTime = startTime;
        saleEndTime = endTime;
        transferOwnership(admin); // admin could drain tokens that were sent here by mistake
    }

    function setTimeSale(uint startTime, uint endTime) onlyOwner public {
        require (now < saleStartTime || now > saleEndTime);
        require (now < startTime);
        require ( startTime < endTime);
        saleStartTime = startTime;
        saleEndTime = endTime;
    }

    function setTokenSaleContract(address _tokenSaleContract) onlyOwner public {
        // check address ! 0
        require(_tokenSaleContract != address(0x0));
        // do not allow run when saleStartTime <= now <= saleEndTime
        require (now < saleStartTime || now > saleEndTime);

        tokenSaleContract = _tokenSaleContract;
    }
    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        validFrom(msg.sender)
        public 
        returns (bool) {
        if (msg.sender == bbFounderCoreStaffWallet || msg.sender == bbAdvisorWallet|| 
            msg.sender == bbAirdropWallet|| msg.sender == bbNetworkGrowthWallet|| msg.sender == bbReserveWallet){

            // check maxAllowedAmount
            var withdrawAmount =  maxAllowedAmount[msg.sender]; 
            var defaultAllowAmount = checkMaxAllowed(msg.sender);
            var maxAmount = defaultAllowAmount - withdrawAmount;
            // _value transfer must <= maxAmount
            require(maxAmount >= _value); // 

            // if maxAmount = 0, need to block this msg.sender
            if(maxAmount==_value){
               
                var isTransfer = super.transfer(_to, _value);
                 // freeze account
                selfFreeze(true, 24 * 3600); // temp freeze account 24h
                maxAllowedAmount[msg.sender] = 0;
                return isTransfer;
            }else{
                // set max withdrawAmount
                maxAllowedAmount[msg.sender] = maxAllowedAmount[msg.sender].add(_value); // 
                
            }
        }
        return  super.transfer(_to, _value);
            
    }

    function transferPrivateSale(address _to, uint _value)
        onlyOwner
        onlyPrivateListEnabled(_to) 
        public 
        returns (bool) {
         return transfer( _to,  _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        validFrom(_from)
        public 
        returns (bool) {
            if (_from == bbFounderCoreStaffWallet || _from == bbAdvisorWallet|| 
                _from == bbAirdropWallet|| _from == bbNetworkGrowthWallet|| _from == bbReserveWallet){

                  // check maxAllowedAmount
                var withdrawAmount =  maxAllowedAmount[_from]; 
                var defaultAllowAmount = checkMaxAllowed(_from);
                var maxAmount = defaultAllowAmount - withdrawAmount; 
                // _value transfer must <= maxAmount
                require(maxAmount >= _value); 

                // if maxAmount = 0, need to block this _from
                if(maxAmount==_value){
                   
                    var isTransfer = super.transfer(_to, _value);
                     // freeze account
                    selfFreeze(true, 24 * 3600); 
                    maxAllowedAmount[_from] = 0;
                    return isTransfer;
                }else{
                    // set max withdrawAmount
                    maxAllowedAmount[_from] = maxAllowedAmount[_from].add(_value); 
                    
                }
            }
            return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) onlyWhenTransferEnabled
        public 
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) onlyWhenTransferEnabled
        public 
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner public {
        token.transfer( owner, amount );
    }
}