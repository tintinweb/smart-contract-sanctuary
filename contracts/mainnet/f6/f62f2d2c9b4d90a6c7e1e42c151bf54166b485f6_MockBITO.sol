pragma solidity ^0.4.23;

/**
 * @title SafeMath
 */
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
 * @title ERC20 interface
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Owned
 */
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title ERC20 token
 */
contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalToken;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title BitoProToken
 */
contract MockBITO is ERC20Token, Owned {

    string  public constant name     = "Mock BITO";
    string  public constant symbol   = "MBITO";
    uint256 public constant decimals = 18;

    uint256 public constant initialToken = 500000000 * (10 ** decimals);

    address public rescueAddress;

    constructor() public {
        rescueAddress = msg.sender;

        totalToken = initialToken;

        balances[msg.sender] = totalToken;

        emit Transfer(0x0, msg.sender, totalToken);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return super.approve(_spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
        return ERC20(_tokenAddress).transfer(rescueAddress, _value);
    }
}