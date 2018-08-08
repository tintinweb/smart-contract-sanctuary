pragma solidity 0.4.24;


// @title SafeMath
// @dev Math operations with safety checks that throw on error
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}


// @title Ownable
// @dev The Ownable contract has an owner address, and provides basic authorization control
// functions, this simplifies the implementation of "user permissions".
contract Ownable {
    address public owner;

    // @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    constructor() public {
        owner = msg.sender;
    }

    // @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // @dev Allows the current owner to transfer control of the contract to a newOwner.
    // @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


// @title ERC20Basic
// @dev Simpler version of ERC20 interface
// @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20Basic {
    event Transfer(address indexed from, address indexed to, uint value);

    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address who) public view returns (uint256 balance);

    function transfer(address to, uint256 value) public returns (bool success);
}


// @title ERC20 interface
// @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256 remaining);

    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value) public returns (bool success);
}


// @title Basic token
// @dev Basic version of StandardToken, with no allowances.
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

    // @dev Fix for the ERC20 short address attack.
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    // @dev transfer token for a specified address
    // @param _to The address to transfer to.
    // @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @dev Gets the balance of the specified address.
    // @param _owner The address to query the the balance of.
    // @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}


// @title Standard ERC20 token
// @dev Implementation of the basic standard token.
// @dev https://github.com/ethereum/EIPs/issues/20
// @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public constant MAX_UINT256 = 2 ** 256 - 1;

    // @dev Transfer tokens from one address to another
    // @param _from address The address which you want to send tokens from
    // @param _to address The address which you want to transfer to
    // @param _value uint256 the amount of tokens to be transferred
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        uint256 _allowance = allowed[_from][msg.sender];
        require(_value <= _allowance);

        // @dev Treat 2^256-1 means unlimited allowance
        if (_allowance < MAX_UINT256)
            allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    // Beware that changing an allowance with this method brings the risk that someone may use both the old
    // and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    // race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    // @param _spender The address which will spend the funds.
    // @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @dev approve should be called when allowed[_spender] == 0. To increment allowed value is better to use
    // @dev this function to avoid 2 calls (and wait until the first transaction is mined)
    // @param _spender The address which will spend the funds.
    // @param _addedValue The amount of tokens to be added to the allowance.
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // @dev Function to check the amount of tokens than an owner allowed to a spender.
    // @param _owner address The address which owns the funds.
    // @param _spender address The address which will spend the funds.
    // @return A uint256 specifying the amount of tokens still available for the spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


// @title Upgraded standard token
// @dev Contract interface that the upgraded contract has to implement
// @dev Methods to be called by the legacy contract
// @dev They have to ensure msg.sender to be the contract address
contract UpgradedStandardToken is StandardToken {
    function transferByLegacy(address from, address to, uint256 value) public returns (bool success);

    function transferFromByLegacy(address sender, address from, address spender, uint256 value) public returns (bool success);

    function approveByLegacy(address from, address spender, uint256 value) public returns (bool success);

    function increaseApprovalByLegacy(address from, address spender, uint256 value) public returns (bool success);

    function decreaseApprovalByLegacy(address from, address spender, uint256 value) public returns (bool success);
}


// @title Upgradeable standard token
// @dev The upgradeable contract interface
// @dev
// @dev They have to ensure msg.sender to be the contract address
contract UpgradeableStandardToken is StandardToken {
    address public upgradeAddress;
    uint256 public upgradeTimestamp;

    //  The contract is initialized with an upgrade timestamp close to the heat death of the universe.
    constructor() public {
        upgradeAddress = address(0);
        //  Set the timestamp of the upgrade to some time close to the heat death of the universe.
        upgradeTimestamp = MAX_UINT256;
    }

    // Forward ERC20 methods to upgraded contract after the upgrade timestamp has been reached
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract after the upgrade timestamp has been reached
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract after the upgrade timestamp has been reached
    function balanceOf(address who) public view returns (uint256 balance) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract after the upgrade timestamp has been reached
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).increaseApprovalByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).decreaseApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }

    // Forward ERC20 methods to upgraded contract after the upgrade timestamp has been reached
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (now > upgradeTimestamp) {
            return StandardToken(upgradeAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // Upgrade this contract with a new one, it will auto-activate 12 weeks later
    function upgrade(address _upgradeAddress) public onlyOwner {
        require(now < upgradeTimestamp);
        require(_upgradeAddress != address(0));

        upgradeAddress = _upgradeAddress;
        upgradeTimestamp = now.add(12 weeks);
        emit Upgrading(_upgradeAddress, upgradeTimestamp);
    }

    // Called when contract is upgrading
    event Upgrading(address newAddress, uint256 timestamp);
}


// @title The AVINOC Token contract
contract AVINOCToken is UpgradeableStandardToken {
    string public constant name = "AVINOC Token";
    string public constant symbol = "AVINOC";
    uint8 public constant decimals = 18;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant TOTAL_SUPPLY = 1000000000 * decimalFactor;

    constructor() public {
        balances[owner] = TOTAL_SUPPLY;
    }

    // @dev Don&#39;t accept ETH
    function() public payable {
        revert();
    }

    // @dev return the fixed total supply
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }
}