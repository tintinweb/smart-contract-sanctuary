pragma solidity ^0.4.13;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ContributorApprover {
    KyberContributorWhitelist public list;
    mapping(address=>uint)    public participated;

    uint                      public cappedSaleStartTime;
    uint                      public openSaleStartTime;
    uint                      public openSaleEndTime;

    using SafeMath for uint;


    function ContributorApprover( KyberContributorWhitelist _whitelistContract,
                                  uint                      _cappedSaleStartTime,
                                  uint                      _openSaleStartTime,
                                  uint                      _openSaleEndTime ) {
        list = _whitelistContract;
        cappedSaleStartTime = _cappedSaleStartTime;
        openSaleStartTime = _openSaleStartTime;
        openSaleEndTime = _openSaleEndTime;

        require( list != KyberContributorWhitelist(0x0) );
        require( cappedSaleStartTime < openSaleStartTime );
        require(  openSaleStartTime < openSaleEndTime );
    }

    // this is a seperate function so user could query it before crowdsale starts
    function contributorCap( address contributor ) constant returns(uint) {
        return list.getCap( contributor );
    }

    function eligible( address contributor, uint amountInWei ) constant returns(uint) {
        if( now < cappedSaleStartTime ) return 0;
        if( now >= openSaleEndTime ) return 0;

        uint cap = contributorCap( contributor );

        if( cap == 0 ) return 0;
        if( now < openSaleStartTime ) {
            uint remainedCap = cap.sub( participated[ contributor ] );

            if( remainedCap > amountInWei ) return amountInWei;
            else return remainedCap;
        }
        else {
            return amountInWei;
        }
    }

    function eligibleTestAndIncrement( address contributor, uint amountInWei ) internal returns(uint) {
        uint result = eligible( contributor, amountInWei );
        participated[contributor] = participated[contributor].add( result );

        return result;
    }

    function saleEnded() constant returns(bool) {
        return now > openSaleEndTime;
    }

    function saleStarted() constant returns(bool) {
        return now >= cappedSaleStartTime;
    }
}

contract KyberNetworkTokenSale is ContributorApprover {
    address             public admin;
    address             public kyberMultiSigWallet;
    KyberNetworkCrystal public token;
    uint                public raisedWei;
    bool                public haltSale;

    mapping(bytes32=>uint) public proxyPurchases;

    function KyberNetworkTokenSale( address _admin,
                                    address _kyberMultiSigWallet,
                                    KyberContributorWhitelist _whilteListContract,
                                    uint _totalTokenSupply,
                                    uint _premintedTokenSupply,
                                    uint _cappedSaleStartTime,
                                    uint _publicSaleStartTime,
                                    uint _publicSaleEndTime )

        ContributorApprover( _whilteListContract,
                             _cappedSaleStartTime,
                             _publicSaleStartTime,
                             _publicSaleEndTime )
    {
        admin = _admin;
        kyberMultiSigWallet = _kyberMultiSigWallet;

        token = new KyberNetworkCrystal( _totalTokenSupply,
                                         _cappedSaleStartTime,
                                         _publicSaleEndTime + 7 days,
                                         _admin );

        // transfer preminted tokens to company wallet
        token.transfer( kyberMultiSigWallet, _premintedTokenSupply );
    }

    function setHaltSale( bool halt ) {
        require( msg.sender == admin );
        haltSale = halt;
    }

    function() payable {
        buy( msg.sender );
    }

    event ProxyBuy( bytes32 indexed _proxy, address _recipient, uint _amountInWei );
    function proxyBuy( bytes32 proxy, address recipient ) payable returns(uint){
        uint amount = buy( recipient );
        proxyPurchases[proxy] = proxyPurchases[proxy].add(amount);
        ProxyBuy( proxy, recipient, amount );

        return amount;
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei );
    function buy( address recipient ) payable returns(uint){
        require( tx.gasprice <= 50000000000 wei );

        require( ! haltSale );
        require( saleStarted() );
        require( ! saleEnded() );

        uint weiPayment = eligibleTestAndIncrement( recipient, msg.value );

        require( weiPayment > 0 );

        // send to msg.sender, not to recipient
        if( msg.value > weiPayment ) {
            msg.sender.transfer( msg.value.sub( weiPayment ) );
        }

        // send payment to wallet
        sendETHToMultiSig( weiPayment );
        raisedWei = raisedWei.add( weiPayment );
        uint recievedTokens = weiPayment.mul( 600 );

        assert( token.transfer( recipient, recievedTokens ) );


        Buy( recipient, recievedTokens, weiPayment );

        return weiPayment;
    }

    function sendETHToMultiSig( uint value ) internal {
        kyberMultiSigWallet.transfer( value );
    }

    event FinalizeSale();
    // function is callable by everyone
    function finalizeSale() {
        require( saleEnded() );
        require( msg.sender == admin );

        // burn remaining tokens
        token.burn(token.balanceOf(this));

        FinalizeSale();
    }

    // ETH balance is always expected to be 0.
    // but in case something went wrong, we use this function to extract the eth.
    function emergencyDrain(ERC20 anyToken) returns(bool){
        require( msg.sender == admin );
        require( saleEnded() );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(kyberMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }

    // just to check that funds goes to the right place
    // tokens are not given in return
    function debugBuy() payable {
        require( msg.value == 123 );
        sendETHToMultiSig( msg.value );
    }
}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract KyberContributorWhitelist is Ownable {
    // cap is in wei. The value of 7 is just a stub.
    // after kyc registration ends, we change it to the actual value with setSlackUsersCap
    uint public slackUsersCap = 7;
    mapping(address=>uint) public addressCap;

    function KyberContributorWhitelist() {}

    event ListAddress( address _user, uint _cap, uint _time );

    // Owner can delist by setting cap = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _cap ) onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _cap ) onlyOwner {
        require(_users.length == _cap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _cap[i] );
        }
    }

    function setSlackUsersCap( uint _cap ) onlyOwner {
        slackUsersCap = _cap;
    }

    function getCap( address _user ) constant returns(uint) {
        uint cap = addressCap[_user];

        if( cap == 1 ) return slackUsersCap;
        else return cap;
    }

    function destroy() onlyOwner {
        selfdestruct(owner);
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  
  // KYBER-NOTE! code changed to comply with ERC20 standard
  event Transfer(address indexed _from, address indexed _to, uint _value);
  //event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  
  // KYBER-NOTE! code changed to comply with ERC20 standard
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  //event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    // KYBER-NOTE! code changed to comply with ERC20 standard
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
  function approve(address _spender, uint256 _value) returns (bool) {

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
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract KyberNetworkCrystal is StandardToken, Ownable {
    string  public  constant name = "Kyber Network Crystal";
    string  public  constant symbol = "KNC";
    uint    public  constant decimals = 18;

    uint    public  saleStartTime;
    uint    public  saleEndTime;

    address public  tokenSaleContract;

    modifier onlyWhenTransferEnabled() {
        if( now <= saleEndTime && now >= saleStartTime ) {
            require( msg.sender == tokenSaleContract );
        }
        _;
    }

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    function KyberNetworkCrystal( uint tokenTotalAmount, uint startTime, uint endTime, address admin ) {
        // Mint all tokens. Then disable minting forever.
        balances[msg.sender] = tokenTotalAmount;
        totalSupply = tokenTotalAmount;
        Transfer(address(0x0), msg.sender, tokenTotalAmount);

        saleStartTime = startTime;
        saleEndTime = endTime;

        tokenSaleContract = msg.sender;
        transferOwnership(admin); // admin could drain tokens that were sent here by mistake
    }

    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) onlyWhenTransferEnabled
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) onlyWhenTransferEnabled
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer( owner, amount );
    }
}