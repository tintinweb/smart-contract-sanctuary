pragma solidity ^0.4.19;

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

contract BigbomTokenExtended is BigbomToken {
    BigbomToken public  bigbomToken;
    function BigbomTokenExtended(uint startTime, uint endTime, address admin, address _bbFounderCoreStaffWallet, address _bbAdvisorWallet,
        address _bbAirdropWallet,
        address _bbNetworkGrowthWallet,
        address _bbReserveWallet, 
        address _bbPublicSaleWallet,
        BigbomToken _bigbomToken
        ) public BigbomToken(startTime, endTime, admin, _bbFounderCoreStaffWallet, _bbAdvisorWallet,
         _bbAirdropWallet,
         _bbNetworkGrowthWallet,
         _bbReserveWallet, 
         _bbPublicSaleWallet
        ){
            bigbomToken = _bigbomToken;
    }
        
    
    event TokenDrop( address receiver, uint amount );
    function airDrop(address[] recipients) public onlyOwner {
        for(uint i = 0 ; i < recipients.length ; i++){
            uint amount = bigbomToken.balanceOf(recipients[i]);
            if (amount > 0){
                //
                transfer(recipients[i], amount);
                TokenDrop( recipients[i], amount );
            }
        }
    }

    modifier validFrozenAccount(address target) {
        if(frozenAccount[target]){
            require(now >= frozenTime[target]);
        }
        _;
    }

    function selfFreeze(bool freeze, uint _seconds) 
    validFrozenAccount(msg.sender) 
    public {
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

    function freezeAccount(address target, bool freeze, uint _seconds) 
    onlyOwner
    validFrozenAccount(target)
    public {
        
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

    
}

contract BigbomContributorWhiteList is Ownable {
    mapping(address=>uint) public addressMinCap;
    mapping(address=>uint) public addressMaxCap;

    function BigbomContributorWhiteList() public  {}

    event ListAddress( address _user, uint _mincap, uint _maxcap, uint _time );

    // Owner can delist by setting cap = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _mincap, uint _maxcap ) public onlyOwner {
        require(_mincap <= _maxcap);
        require(_user != address(0x0));

        addressMinCap[_user] = _mincap;
        addressMaxCap[_user] = _maxcap;
        ListAddress( _user, _mincap, _maxcap, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _mincap, uint[] _maxcap ) public  onlyOwner {
        require(_users.length == _mincap.length );
        require(_users.length == _maxcap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _mincap[i], _maxcap[i] );
        }
    }

    function getMinCap( address _user ) public constant returns(uint) {
        return addressMinCap[_user];
    }
    function getMaxCap( address _user ) public constant returns(uint) {
        return addressMaxCap[_user];
    }

}

contract BigbomCrowdSale{
    address             public admin;
    address             public bigbomMultiSigWallet;
    BigbomTokenExtended         public token;
    uint                public raisedWei;
    bool                public haltSale;
    uint                public openSaleStartTime;
    uint                public openSaleEndTime;
    
    uint                public minGasPrice;
    uint                public maxGasPrice;

    BigbomContributorWhiteList public list;

    mapping(address=>uint)    public participated;
    mapping(string=>uint)     depositTxMap;
    mapping(string=>uint)     erc20Rate;

    using SafeMath for uint;

    function BigbomCrowdSale( address _admin,
                              address _bigbomMultiSigWallet,
                              BigbomContributorWhiteList _whilteListContract,
                              uint _publicSaleStartTime,
                              uint _publicSaleEndTime,
                              BigbomTokenExtended _token) public       
    {
        require (_publicSaleStartTime < _publicSaleEndTime);
        require (_admin != address(0x0));
        require (_bigbomMultiSigWallet != address(0x0));
        require (_whilteListContract != address(0x0));
        require (_token != address(0x0));

        admin = _admin;
        bigbomMultiSigWallet = _bigbomMultiSigWallet;
        list = _whilteListContract;
        openSaleStartTime = _publicSaleStartTime;
        openSaleEndTime = _publicSaleEndTime;
        token = _token;
    }
    
    function saleEnded() public constant returns(bool) {
        return now > openSaleEndTime;
    }

    function setMinGasPrice(uint price) public {
        require (msg.sender == admin);
        minGasPrice = price;
    }
    function setMaxGasPrice(uint price) public {
        require (msg.sender == admin);
        maxGasPrice = price;
    }

    function saleStarted() public constant returns(bool) {
        return now >= openSaleStartTime;
    }

    function setHaltSale( bool halt ) public {
        require( msg.sender == admin );
        haltSale = halt;
    }
    // this is a seperate function so user could query it before crowdsale starts
    function contributorMinCap( address contributor ) public constant returns(uint) {
        return list.getMinCap( contributor );
    }
    function contributorMaxCap( address contributor, uint amountInWei ) public constant returns(uint) {
        uint cap = list.getMaxCap( contributor );
        if( cap == 0 ) return 0;
        uint remainedCap = cap.sub( participated[ contributor ] );
        if( remainedCap > amountInWei ) return amountInWei;
        else return remainedCap;
    }

    function checkMaxCap( address contributor, uint amountInWei ) internal returns(uint) {
        if( now > ( openSaleStartTime + 2 * 24 * 3600))
            return 100e18;
        else{
            uint result = contributorMaxCap( contributor, amountInWei );
            participated[contributor] = participated[contributor].add( result );
            return result;
        }
        
    }

    function() payable public {
        buy( msg.sender );
    }



    function getBonus(uint _tokens) public pure returns (uint){
        return _tokens.mul(10).div(100);
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei, uint _bonus );
    function buy( address recipient ) payable public returns(uint){
        require( tx.gasprice <= maxGasPrice );
        require( tx.gasprice >= minGasPrice );

        require( ! haltSale );
        require( saleStarted() );
        require( ! saleEnded() );

        uint mincap = contributorMinCap(recipient);

        uint maxcap = checkMaxCap(recipient, msg.value );
        uint allowValue = msg.value;
        require( mincap > 0 );

        require( maxcap > 0 );
        // fail if msg.value < mincap
        require (msg.value >= mincap);
        // send to msg.sender, not to recipient if value > maxcap
        if(now <= openSaleStartTime + 2 * 24 * 3600) {
            if( msg.value > maxcap ) {
                allowValue = maxcap;
                //require (allowValue >= mincap);
                msg.sender.transfer( msg.value.sub( maxcap ) );
            }
        }
       

        // send payment to wallet
        sendETHToMultiSig(allowValue);
        raisedWei = raisedWei.add( allowValue );
        // 1ETH = 20000 BBO
        uint recievedTokens = allowValue.mul( 20000 );
        // TODO bounce
        uint bonus = getBonus(recievedTokens);
        
        recievedTokens = recievedTokens.add(bonus);
        assert( token.transfer( recipient, recievedTokens ) );
        //

        Buy( recipient, recievedTokens, allowValue, bonus );

        return msg.value;
    }

    function sendETHToMultiSig( uint value ) internal {
        bigbomMultiSigWallet.transfer( value );
    }

    event FinalizeSale();
    // function is callable by everyone
    function finalizeSale() public {
        require( saleEnded() );
        //require( msg.sender == admin );

        // burn remaining tokens
        token.burn(token.balanceOf(this));

        FinalizeSale();
    }

    // ETH balance is always expected to be 0.
    // but in case something went wrong, we use this function to extract the eth.
    function emergencyDrain(ERC20 anyToken) public returns(bool){
        require( msg.sender == admin );
        require( saleEnded() );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(bigbomMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }

    // just to check that funds goes to the right place
    // tokens are not given in return
    function debugBuy() payable public {
        require( msg.value > 0 );
        sendETHToMultiSig( msg.value );
    }

    function getErc20Rate(string erc20Name) public constant returns(uint){
        return erc20Rate[erc20Name];
    }

    function setErc20Rate(string erc20Name, uint rate) public{
        require (msg.sender == admin);
        erc20Rate[erc20Name] = rate;
    }

    function getDepositTxMap(string _tx) public constant returns(uint){
        return depositTxMap[_tx];
    }
    event Erc20Buy( address _buyer, uint _tokens, uint _payedWei, uint _bonus, string depositTx );

    event Erc20Refund( address _buyer, uint _erc20RefundAmount, string _erc20Name );
    function erc20Buy( address recipient, uint erc20Amount, string erc20Name, string depositTx )  public returns(uint){
        require (msg.sender == admin);
        //require( tx.gasprice <= 50000000000 wei );

        require( ! haltSale );
        require( saleStarted() );
        require( ! saleEnded() );
        uint ethAmount = getErc20Rate(erc20Name) * erc20Amount / 1e18;
        uint mincap = contributorMinCap(recipient);

        uint maxcap = checkMaxCap(recipient, ethAmount );
        require (getDepositTxMap(depositTx) == 0);
        require (ethAmount > 0);
        uint allowValue = ethAmount;
        require( mincap > 0 );
        require( maxcap > 0 );
        // fail if msg.value < mincap
        require (ethAmount >= mincap);
        // send to msg.sender, not to recipient if value > maxcap
        if(now <= openSaleStartTime + 2 * 24 * 3600) {
            if( ethAmount > maxcap  ) {
                allowValue = maxcap;
                //require (allowValue >= mincap);
                // send event refund
                // msg.sender.transfer( ethAmount.sub( maxcap ) );
                uint erc20RefundAmount = ethAmount.sub( maxcap ).mul(1e18).div(getErc20Rate(erc20Name));
                Erc20Refund(recipient, erc20RefundAmount, erc20Name);
            }
        }

        raisedWei = raisedWei.add( allowValue );
        // 1ETH = 20000 BBO
        uint recievedTokens = allowValue.mul( 20000 );
        // TODO bounce
        uint bonus = getBonus(recievedTokens);
        
        recievedTokens = recievedTokens.add(bonus);
        assert( token.transfer( recipient, recievedTokens ) );
        // set tx
        depositTxMap[depositTx] = ethAmount;
        //

        Erc20Buy( recipient, recievedTokens, allowValue, bonus, depositTx);

        return allowValue;
    }

}