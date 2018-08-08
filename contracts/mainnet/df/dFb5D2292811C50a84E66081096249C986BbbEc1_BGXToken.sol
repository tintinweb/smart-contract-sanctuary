pragma solidity ^0.4.20;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint32 public decimals;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;



    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }



}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require( newOwner != address(0) );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract BGXToken is Ownable, StandardToken{

    address public crowdsaleAddress;
    bool public initialized = false;
    uint256 public totalSupplyTmp = 0;

    uint256 public teamDate;
    address public teamAddress;

    modifier onlyCrowdsale {
        require(
            msg.sender == crowdsaleAddress
        );
        _;
    }

    // fix for short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4);
        _;
    }

    function BGXToken() public
    {
        name                    = "BGX Token";
        symbol                  = "BGX";
        decimals                = 18;
        totalSupply             = 1000000000 ether;
        balances[address(this)] = totalSupply;
    }


    function distribute( address _to, uint256 _value ) public onlyCrowdsale returns( bool )
    {
        require(_to != address(0));
        require(_value <= balances[address(this)]);

        balances[address(this)] = balances[address(this)].sub(_value);
        totalSupplyTmp = totalSupplyTmp.add( _value );

        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function finally( address _teamAddress ) public onlyCrowdsale returns( bool )
    {
        balances[address(this)] = 0;
        teamAddress = _teamAddress;
        teamDate = now + 1 years;
        totalSupply = totalSupplyTmp;

        return true;
    }

    function setCrowdsaleInterface( address _addr) public onlyOwner returns( bool )
    {
        require( !initialized );

        crowdsaleAddress = _addr;
        initialized = true;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32)  returns (bool) {

        if( msg.sender == teamAddress ) require( now >= teamDate );
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;

    }

    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {

        if( msg.sender == teamAddress ) require( now >= teamDate );

        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;

    }
}