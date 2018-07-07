pragma solidity 0.4.24;

/*
* SafeMath to avoid data overwrite
*/
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

/*
 * 
 * find in https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function balanceOf(address _owner) view public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner validAddress public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Lockable is Ownable {
    bool public lockStatus = false;
    
    event Lock(address);    
    event UnLock(address);
    
    modifier unLocked() {
        assert(!lockStatus);
        _;
    }

    modifier inLocked() {
        assert(lockStatus);
        _;
    }
    
    function lock() onlyOwner unLocked public returns (bool) {
        lockStatus = true;
        emit Lock(msg.sender);
        return true;
    }

    function unlock() onlyOwner inLocked public returns (bool) {
        lockStatus = false;
        emit UnLock(msg.sender);
        return true;
    }

}

/* 
 * @title Standard ERC20 token
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, Lockable {
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    function balanceOf(address _owner) view public returns (uint256 balance){
        require(address(0) != _owner);
        return balanceOf[_owner];
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        require(address(0) != _owner);
        require(address(0) != _spender);
        return allowance[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) unLocked public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) unLocked public returns (bool success) {
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(address(0) != _spender);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}

contract TokenTemp is StandardToken {
    constructor (uint256 _supply, string _name, string _symbol, uint8 _decimals) public {
        totalSupply = _supply * 10 ** uint256(_decimals); 
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = totalSupply;
    }
}