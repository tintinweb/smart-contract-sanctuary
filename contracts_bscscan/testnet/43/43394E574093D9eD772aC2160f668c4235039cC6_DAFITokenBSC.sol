/**
 *Submitted for verification at Etherscan.io on 2021-03-16
 */

pragma solidity ^0.5.16;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract Ownable {
    address public owner;
    address public bridge;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BridgeChanged(address indexed previousBridger, address indexed newBridger);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Only Owner can call this function");
        _;
    }
    modifier onlyBridge() {
        require(msg.sender == bridge, "only Bridge can call this function");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"new owner cannot be Address 0");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function changeBridge(address newBridgeAddress) public onlyOwner {
        require(newBridgeAddress != address(0),"new owner cannot be address 0");
        require(Address.isContract(newBridgeAddress) == true, "provided address is not a bridge contract");
        emit BridgeChanged(bridge, newBridgeAddress);
        bridge = newBridgeAddress;
    }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0),"Cannot call transfer with to as ZERO ADDRESS");
        require(_value <= balances[msg.sender],"cannot transfer amount more than your balance");

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0),"To cannot be ZERO ADDRESS");
        require(_from != address(0),"From cannot be Address 0");
        require(_value <= balances[_from],"Insufficient Balance");
        require(_value <= allowed[_from][msg.sender],"msg sender not approved of this amount");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0),"Spender cannot be ZERO ADDRESS");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0),"Spender cannot be ZERO ADDRESS");
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0),"Spender cannot be ZERO ADDRESS");
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract DAFITokenBSC is StandardToken, Ownable {
    string constant _name = "DAFI Token";
    string constant _symbol = "DAFI";
    uint256 constant _decimals = 18;

    uint256 public maxSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _owner) public Ownable(_owner) {
        maxSupply = 2250000000 * 10**_decimals;
    }

    function mint(uint256 _value, address _beneficiary) external onlyBridge {
        require(_beneficiary != address(0),"Beneficiary cannot be ZERO ADDRESS");
        require(_value > 0,"value should be more than 0");
        require(_value.add(_totalSupply) <= maxSupply, "Minting amount exceeding max limit");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);

        emit Transfer(address(0), _beneficiary, _value);
    }

    function burn(uint256 _value, address _beneficiary) external onlyBridge {
        require(_beneficiary != address(0),"Beneficiary cannot be ZERO ADDRESS");
        require(balanceOf(_beneficiary) >= _value, "User does not have sufficient tokens to burn");
        require(_value <= allowed[_beneficiary][msg.sender], "user did not approve the bridge to burn the said amount.");

        _totalSupply = _totalSupply.sub(_value);
        balances[_beneficiary] = balances[_beneficiary].sub(_value);

        emit Transfer(_beneficiary, address(0), _value);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure returns (uint256) {
        return _decimals;
    }
}