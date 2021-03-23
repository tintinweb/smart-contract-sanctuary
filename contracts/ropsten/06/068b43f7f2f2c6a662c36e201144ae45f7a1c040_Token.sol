/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity 0.6.6;


/* all this file is based on code from open zepplin
 * https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token */

/**
 * Standard ERC20 token
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "divider <= 0");
        uint256 c = a / b;
        require(a == b * c + (a % b), "div failed");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20Basic {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 value) external virtual returns (bool);

    function balanceOf(address who) external view virtual returns (uint256);
}


////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool);

    function approve(address spender, uint256 value) external virtual returns (bool);

    function allowance(address owner, address spender) external view virtual returns (uint256);
}


////////////////////////////////////////////////////////////////////////////////

/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /*
     * Fix for the ERC20 short address attack
     */
    modifier onlyPayloadSize(uint256 size) {
        if (msg.data.length < size + 4) {
            revert("short address");
        }
        _;
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        onlyPayloadSize(2 * 32)
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }
}


////////////////////////////////////////////////////////////////////////////////

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) private allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already revert
        // if this condition is not met
        require(_value <= _allowance, "transfer more then allowed");

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];
    }
}


////////////////////////////////////////////////////////////////////////////////

/*
 * SimpleToken
 *
 * Very simple ERC20 Token example, where all tokens are pre-assigned
 * to the creator. Note they can later distribute these tokens
 * as they wish using `transfer` and other `StandardToken` functions.
 */
contract Token is StandardToken {
    string public name = "Test";
    string public symbol = "TST";
    uint256 public decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10**(50 + 18);

    event Burn(address indexed _burner, uint256 _value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function burn(uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        transferFrom(_from, msg.sender, _value);
        return burn(_value);
    }
}