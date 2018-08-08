pragma solidity 0.4.24;


contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(
        address newOwner
    )
        public
        onlyOwner
    {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

library SafeMath {
    function mul(
        uint256 a, 
        uint256 b
    )
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    function div(
        uint256 a, 
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a / b;
    }

    function sub(
        uint256 a, 
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        require(b <= a);
        return a - b;
    }

    function add(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function burn(uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function burnFrom(address from, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }

    function transfer(
        address _to, 
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function burn(
        uint256 _value
    )
        public
        returns (bool)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function balanceOf(
        address _owner
    )
        public
        view
        returns (uint256)
    {
        return balances[_owner];
    }
}


contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burnFrom(
        address _from, 
        uint256 _value
    )
        public
        returns (bool)
    {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_from, _value);
        return true;
    }

    function approve(
        address _spender, 
        uint256 _value
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner, 
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender, 
        uint _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender, 
        uint _subtractedValue
    )
        public
        returns (bool)
    {
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

contract CoAlphaToken is StandardToken, Ownable {
    string public name = "CoAlphaToken";
    string public symbol = "CAL";
    uint8 public decimals = 2;
    uint public initialSupply = 2000000000*(10**uint256(decimals));

    constructor() public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply;
    }
}