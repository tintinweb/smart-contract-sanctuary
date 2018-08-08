pragma solidity ^0.4.18;


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who)public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)public view  returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value)public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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
 * @title Basic token
 * @dev Contract with the transfer function
 */
contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev Gets the balance of user&#39;s address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view  returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev transfer token for another address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }



}

/**
 * @title Standard ERC20 token
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    function transferFrom(address _from, address _to, uint256 _value)public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)public returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}
/**
 * @title SurrusContract

 */
contract SurrusContract is StandardToken {


    address owner;

    string public constant name = "SurruS";

    string public constant symbol = "SURR";

    uint32 public constant decimals = 18;
    
    string public description="tokens for ico";

    uint256 public INITIAL_SUPPLY = 860000000000000000000000000; //860 000 000, 000 000 000 000 000 000

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Constructor.
     * Generating tokens During the creation of the contract.
     */
    function SurrusContract()  {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        owner = msg.sender;
    }

    /**
     * @dev Function is called at the end of an ICO.
     *cIt sums number of sold tokens and sends 40 percent to separate address. Burns the rest tokens
     *c40% of tokens are sent to the team
     */
    function burnByOwner(address _comandWallet) onlyOwner()  public {
        uint256 soldTokens =totalSupply.sub(balanceOf(owner));
        if(soldTokens>=520000000000000000000000000)
            transfer( _comandWallet, balances[owner]);
        else{
            uint256 tmp = soldTokens.mul(40);
            uint256 tokenTeam = tmp.div(100);
            transfer( _comandWallet, tokenTeam);
            burn(balances[msg.sender]);
        }
    }

    function burn(uint256 _value) internal {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setDescription(string _description) onlyOwner() public{
        description = _description;
    }
    
}