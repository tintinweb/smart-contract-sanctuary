pragma solidity ^0.4.20;

contract ERC20 {

event Transfer(address indexed _from, address indexed _to, uint256 _value);

event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function totalSupply() external constant returns (uint);

function balanceOf(address _owner) external constant returns (uint256);

function transfer(address _to, uint256 _value) external returns (bool);

function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

function approve(address _spender, uint256 _value) external returns (bool);

function allowance(address _owner, address _spender) external constant returns (uint256);
    
}

library SafeMath {

    /*
        @return sum of a and b
    */
    function ADD (uint256 a, uint256 b) pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    /*
        @return difference of a and b
    */
    function SUB (uint256 a, uint256 b) pure internal returns (uint256) {
        assert(a >= b);
        return a - b;
    }
    
}

contract Ownable {

    address owner;

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    function Ownable() public {
        owner = msg.sender;
        OwnershipTransferred (address(0), owner);
    }

    function transferOwnership(address _newOwner)
        public
        onlyOwner
        notZeroAddress(_newOwner)
    {
        owner = _newOwner;
        OwnershipTransferred(msg.sender, _newOwner);
    }

    //Only owner can call function
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0));
        _;
    }

}

contract StandardToken is ERC20, Ownable{

    using SafeMath for uint256;
    
    //Total amount of SeaCoin
    uint256 _totalSupply = 30000000000; 

    //Balances for each account
    mapping (address => uint256)  balances;
    //Owner of the account approves the transfer of an amount to another account
    mapping (address => mapping (address => uint256)) allowed;

    //Notifies users about the amount burnt
    event Burn(address indexed _from, uint256 _value);

    //return _totalSupply of the Token
    function totalSupply() external constant returns (uint256 totalTokenSupply) {
        totalTokenSupply = _totalSupply;
    }

    //What is the balance of a particular account?
    function balanceOf(address _owner)
        external
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    //Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        external
        notZeroAddress(_to)
        returns (bool success)
    {
        //Require allowance to be not too big
        require(allowed[_from][msg.sender] >= _amount);
        balances[_from] = balances[_from].SUB(_amount);
        balances[_to] = balances[_to].ADD(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)
        external
        notZeroAddress(_spender)
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    //Return how many tokens left that you can spend from
    function allowance(address _owner, address _spender)
        external
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        external
        returns (bool success)
    {
        uint256 increased = allowed[msg.sender][_spender].ADD(_addedValue);
        require(increased <= balances[msg.sender]);
        //Cannot approve more coins then you have
        allowed[msg.sender][_spender] = increased;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        external
        returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.SUB(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        //Subtract from the sender
        balances[msg.sender] = balances[msg.sender].SUB(_value);
        //Update _totalSupply
        _totalSupply = _totalSupply.SUB(_value);
        Burn(msg.sender, _value);
        return true;
    }

}

contract SeaCoin is StandardToken {

    function ()
   	public
    {
    //if ether is sent to this address, send it back.
    revert();
    }

    //Name of the token
    string public constant name = "SeaCoin";
    //Symbol of SeaCoin
    string public constant symbol = "SEA";
    //Number of decimals of SeaCoin
    uint8 public constant decimals = 2;


    //100%
    uint256 private constant SEA_THOUSANDTH = 1000;

    //100%
    uint256 private constant DENOMINATOR = 1000;

    function SeaCoin() public {
        //100% of _totalSupply
        balances[msg.sender] = _totalSupply * SEA_THOUSANDTH / DENOMINATOR;
    

        Transfer (this, msg.sender, balances[msg.sender]);


    
}
}