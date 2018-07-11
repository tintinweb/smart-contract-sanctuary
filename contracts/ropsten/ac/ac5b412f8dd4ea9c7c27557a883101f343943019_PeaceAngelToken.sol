pragma solidity ^0.4.24;


library SafeMath{
    
    function mul256(uint256 a,uint256 b) pure internal returns(uint256){
        uint256 c = a * b;
        assert(a == 0 || c/a == b);
        return c;
    }
    
    function div256(uint256 a, uint256 b) pure internal returns(uint256){
        require(b > 0); //Solidity automatically revert() when dividing by 0
        uint256 c = a/b;
        return c;
    }
    
    function sub256(uint256 a, uint256 b) pure internal returns(uint256){
        require(b <= a);
        return a -b;
    }
    
    function add256(uint256 a,uint256 b) pure internal returns(uint256){
        uint256 c= a+b;
        assert(c>=a);
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simple version of ERC20 interface
 * 
 **/ 
contract ERC20Basic{
    function totalSupply() public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public;
    
    event Transfer(address indexed from,address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic{
    function allowance(address owner, address spender) view public returns(uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender,uint256 value) public;
    
    event Approval(address indexed owner,address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic{
    using SafeMath for uint256;
    
    bool tradeable = false;
    
    
    modifier isTradeable(){
        require(tradeable);_;
    }
    
    
    mapping(address=>uint256) balances;

    /**
    * @dev Fix for the ERC20 short address attack.
    **/
    modifier onlyPayloadSixe(uint size){
        require(msg.data.length >= size+4);_;
    }
    
    
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     **/
    function transfer(address _to, uint256 _value) onlyPayloadSixe(2*32) isTradeable() public{
        balances[msg.sender] = balances[msg.sender].sub256(_value);
        balances[_to] = balances[_to].add256(_value);
        emit Transfer(msg.sender,_to,_value);
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the balance of.
     * @return An uint representing the amount owned by the passed address.
     **/
    function balanceOf(address _owner) constant public returns(uint256 balance){
         return balances[_owner];
    }
}

contract StarndardToken is BasicToken, ERC20{
    mapping(address => mapping(address=>uint256)) allowed;
    address public owner;
    address issuer;
    
    function unlockToken() onlyOwner public{
        tradeable = true;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);_;
    }
    
    function setIssuer(address _issuer, uint256 _value) onlyOwner() public {
        allowed[msg.sender][_issuer] = _value;
        emit Approval(msg.sender, _issuer, _value);
    }
    
    modifier isIssuer(){
        require(msg.sender == issuer);_;
    }
    
    /**
     * Function allow give token to a specific account, because tokens can&#39;t be tradeable,
     * until de ICO ends.
     **/
    function issuerGuiveToken(address _to,uint256 _value) isIssuer() public{
        uint256 _allowance = allowed[owner][msg.sender];
         
        balances[_to] = balances[_to].add256(_value);
        balances[owner] = balances[owner].sub256(_value);
        allowed[owner][msg.sender] = _allowance.sub256(_value);
         
        emit Transfer(owner,_to,_value);
    }
    
    /**
     * @dev Transder tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint The amount of tokens to be transfered
     **/
    function transferFrom(address _from, address _to, uint256 _value) isTradeable() public{
        uint256 _allowance = allowed[_from][msg.sender];
         
        balances[_to] = balances[_to].add256(_value);
        balances[_from] = balances[_from].sub256(_value);
        allowed[_from][msg.sender] = _allowance.sub256(_value);
         
        emit Transfer(_from,_to,_value);
     }
     
    /**
      * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
      * @param _spender address The address which will spend the funds.
      * @param _value uint The amount of tokens to be spent.
      **/
    function approve(address _spender, uint256 _value) public {
        // if ((_value != 0) && (allowed[msg.sender][_spender]!=0)) revert();
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
      
}

contract PeaceAngelToken is StarndardToken {
    string public name=&quot;Peace Angel Token&quot;;
    string public symbol=&quot;PATO&quot;;
    uint8 public decimals = 0;
    uint256 public totalSupply=60000000;
    event TokenBurned(uint256 value);
    
    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    /**
     * @dev Allows the owner to burn the token.
     * @param _value uint256 number of tokens to be burned.
     **/
    function burn(uint256 _value) onlyOwner() public{
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub256(_value);
        totalSupply = totalSupply.sub256(_value);
        emit TokenBurned(_value);
    }
    
    /**
     * @dev Allows get the Total Currently Suppply.
     * uint Amount of tokens avaliable in circulation.
     **/
    function totalSupply() public view returns(uint256){
        return totalSupply;
    }
    
    function allowance(address _owner,address _spender) view public returns (uint256){
        return allowed[_owner][_spender];
    }
}