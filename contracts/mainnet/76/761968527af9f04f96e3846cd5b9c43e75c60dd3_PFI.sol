pragma solidity 0.6.12;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

abstract contract ERC20Basic {
    function totalSupply() external virtual returns (uint);
    function balanceOf(address who) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract TokenRecipient {
    function tokenFallback(address _from, uint _value) public virtual;
}

abstract contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function transfer(address _to, uint _value) public override virtual onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public override virtual view returns (uint balance) {
        return balances[_owner];
    }
}

abstract contract StandardToken is BasicToken, ERC20 {
    mapping (address => mapping (address => uint)) allowed;

    uint constant MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public virtual override onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {
        require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public virtual view override returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract PFI is StandardToken {
    string public name = 'PFI token';
    string public symbol = 'PFI';
    uint public decimals = 18;
    uint public override totalSupply = 21500 * 10 ** 18;
    address public owner;

    constructor () public {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    
    function issue(uint amount) public {
        require(msg.sender == owner);
        balances[owner] = balances[owner].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Issue(amount);
    }

    event Issue(uint amount);
}

// SPDX-License-Identifier: MIT