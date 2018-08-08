pragma solidity ^0.4.18;

/**
* @title Safemath library taken from openzeppline
*
**/

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
**/
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Contract Ownable
 **/ 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOWner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 *  @title Contract Pauseable
 **/ 
contract Pauseable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

/**
* @title WAVElite Token
**/
contract WAVEliteToken is ERC20, Pauseable {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 _totalSupply;    
    

    string public constant name = "WAVElite";
    string public constant symbol = "WAVELT";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY =  45000000 * (10 ** uint256(decimals));
    
    function WAVEliteToken() public {
        owner = msg.sender;
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _who) external view returns (uint256) {
        return balances[_who];
    }

    function transfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }    

    function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subValue) public whenNotPaused returns (bool) {
        if (_subValue >= allowed[msg.sender][_spender]) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * Burnable
    **/

    event Burn(address indexed burner, uint256 value);
    function burn(uint256 _value) public whenNotPaused {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);      
    }
}