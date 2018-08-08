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

contract REKTTokenSale {
    using SafeMath for uint;

    address             public admin;
    address             public REKTMultiSigWallet;
    REKT                public token;
    bool                public haltSale;

    function REKTTokenSale( address _admin,
    address _REKTMultiSigWallet,
    uint _totalTokenSupply)
    {
        admin = _admin;
        REKTMultiSigWallet = _REKTMultiSigWallet;

        token = new REKT( _totalTokenSupply, _admin );
    }

    function setHaltSale( bool halt ) {
        require( msg.sender == admin );
        haltSale = halt;
    }

    function() payable {
        buy( msg.sender );
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei );
    function buy( address recipient ) payable returns(uint){
        require( ! haltSale );

        // send payment to wallet
        sendETHToMultiSig( msg.value );
        uint receivedTokens = msg.value.mul( 1000 );

        assert( token.transfer( recipient, receivedTokens ) );


        Buy( recipient, receivedTokens, msg.value );

        return msg.value;
    }

    function sendETHToMultiSig( uint value ) internal {
        REKTMultiSigWallet.transfer( value );
    }

    // ETH balance is always expected to be 0.
    // but in case something went wrong, we use this function to extract the eth.
    function emergencyDrain(ERC20 anyToken) returns(bool){
        require( msg.sender == admin );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(REKTMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }
}

contract REKT is StandardToken, Ownable {
    string  public  constant name = "REKT";
    string  public  constant symbol = "REKT";
    uint    public  constant decimals = 18;

    address public  tokenSaleContract;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    function REKT( uint tokenTotalAmount, address admin ) {
        // Mint all tokens. Then disable minting forever.
        balances[msg.sender] = tokenTotalAmount.div(2);
        balances[admin] = tokenTotalAmount.div(2);
        totalSupply = tokenTotalAmount;
        Transfer(address(0x0), msg.sender, tokenTotalAmount);

        tokenSaleContract = msg.sender;
        transferOwnership(admin); // admin could drain tokens that were sent here by mistake
    }

    function transfer(address _to, uint _value)
    validDestination(_to)
    returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
    validDestination(_to)
    returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value)
    returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value)
    returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer( owner, amount );
    }
}