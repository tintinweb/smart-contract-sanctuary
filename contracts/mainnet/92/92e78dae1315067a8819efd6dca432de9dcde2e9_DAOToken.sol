pragma solidity ^0.4.20;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract OwnableWithDAO{

    address public owner;
    address public daoContract;

    function OwnableWithDAO(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyDAO(){
        require(msg.sender == daoContract);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setDAOContract(address newDAO) onlyOwner public {
        require(newDAO != address(0));
        daoContract = newDAO;
    }

}

contract Stoppable is OwnableWithDAO{

    bool public stopped;
    mapping (address => bool) public blackList; // адреса которым запретить покупку токенов

    modifier block{
        require(!blackList[msg.sender]);
        _;
    }

    function addToBlackList(address _address) onlyOwner{
        blackList[_address] = true;
    }

    function removeFromBlackList(address _address) onlyOwner{
        blackList[_address] = false;
    }

    modifier stoppable{
        require(!stopped);
        _;
    }

    function stop() onlyDAO{
        stopped = true;
    }

    function start() onlyDAO{
        stopped = false;
    }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Stoppable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) stoppable block returns (bool) {
        require(msg.sender !=_to);
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
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
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
     * @return A uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}




contract MintableToken is StandardToken {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

}

contract BurnableToken is MintableToken {

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint _value) public {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    event Burn(address indexed burner, uint indexed value);

}

contract DAOToken is BurnableToken{

    string public name = "Veros";

    string public symbol = "VRS";

    uint32 public constant decimals = 6;

    uint public INITIAL_SUPPLY = 100000000 * 1000000;

    uint public coin = 1000000;

    address public StabilizationFund;
    address public MigrationFund;
    address public ProjectFund;
    address public Bounty;
    address public Airdrop;
    address public Founders;



    function DAOToken() {
        mint(msg.sender, INITIAL_SUPPLY);
        //запретить дальнейший минтинг
        finishMinting();

        StabilizationFund = 0x6280A4a4Cb8E589a1F843284e7e2e63edD9E6A4f;
        MigrationFund = 0x3bc441E70bb238537e43CE68763530D4e23901D6;
        ProjectFund = 0xf09D6EE3149bB81556c0D78e95c9bBD12F373bE4;
        Bounty = 0x551d3Cf16293196d82C6DD8f17e522B1C1B48b35;
        Airdrop = 0x396A8607237a13121b67a4f8F1b87A47b1A296BA;
        Founders = 0x63f80C7aF415Fdd84D5568Aeff8ae134Ef0C78c5;

        // отправляем токены на указанные фонды
        transfer(StabilizationFund, 15000000 * coin);
        transfer(MigrationFund, 12000000 * coin);
        transfer(ProjectFund, 40000000 * coin);
        transfer(Bounty, 3000000 * coin);
        transfer(Airdrop, 2000000 * coin);
        transfer(Founders, 3000000 * coin);

    }

    function changeName(string _name, string _symbol) onlyOwner public{
        name = _name;
        symbol = _symbol;
    }
}