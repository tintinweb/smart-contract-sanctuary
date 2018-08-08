pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization
 *      control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the
     *      sender account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



/**
 * @title ERC223
 * @dev ERC223 contract interface with ERC20 functions and events
 *      Fully backward compatible with ERC20
 *      Recommended implementation used at https://github.com/Dexaran/ERC223-token-standard/tree/Recommended
 */
contract ERC223 {
    uint public totalSupply;

    // ERC223 and ERC20 functions and events
    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    // ERC223 functions
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

    // ERC20 functions and events
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
 * @title ContractReceiver
 * @dev Contract that is working with ERC223 tokens
 */
 contract ContractReceiver {

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

        /*
         * tkn variable is analogue of msg variable of Ether transaction
         * tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
         * tkn.value the number of tokens that were sent   (analogue of msg.value)
         * tkn.data is data of token transaction   (analogue of msg.data)
         * tkn.sig is 4 bytes signature of function if data of token transaction is a function execution
         */
    }
}

/**
 * @title SKILL COIN
 * @author tsk
 * @dev Skill COIN is an ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract SkillCoin is ERC223, Ownable {
    using SafeMath for uint256;

    string public name = "SKILLCOIN";
    string public symbol = "SKILL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 30e9 * 1e18;

    address public projectMemberAddress = 0x1Ea27b073Bb648fae5a8ec81E3460146BE8D0763;
    address public developmentAddress = 0xabC0196253cd173c448A50edc991E041F49d5ee6;
    address public operatingAddress = 0xD399ca463154F410Db104FC976129De7d1e78126;
    address public initialSupplyAddress = 0x3a411e42c6ab79aDCCf10946646A6A6a458f6cB2;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);

    /**
     * @dev Constructor is called only once and can not be called again
     */
    function SkillCoin() public {
        owner = msg.sender;

        balanceOf[msg.sender] = totalSupply.mul(25).div(100);
        balanceOf[projectMemberAddress] = totalSupply.mul(10).div(100);
        balanceOf[developmentAddress] = totalSupply.mul(30).div(100);
        balanceOf[operatingAddress] = totalSupply.mul(10).div(100);
        balanceOf[initialSupplyAddress] = totalSupply.mul(25).div(100);
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    /**
     * @dev Prevent targets from sending or receiving tokens
     * @param targets Addresses to be frozen
     * @param isFrozen either to freeze it or not
     */
    function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(targets[j] != 0x0);
            frozenAccount[targets[j]] = isFrozen;
            FrozenFunds(targets[j], isFrozen);
        }
    }

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix times
     * @param targets Addresses to be locked funds
     * @param unixTimes Unix times when locking up will be finished
     */
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);

        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] < unixTimes[j]);
            unlockUnixTime[targets[j]] = unixTimes[j];
            LockedFunds(targets[j], unixTimes[j]);
        }
    }

    /**
     * @dev Standard function transfer similar to ERC20 transfer with no _data
     *      Added due to backwards compatibility reasons
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
     * @dev Function that is called when a user or another contract wants to transfer funds
     */
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        if (isContract(_to)) {
            require(balanceOf[msg.sender] >= _value);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     *      Added due to backwards compatibility with ERC20
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && frozenAccount[_from] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[_from]
                && now > unlockUnixTime[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Allows _spender to spend no more than _value tokens in your behalf
     *      Added due to backwards compatibility with ERC20
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     *      Added due to backwards compatibility with ERC20
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _from The address that will burn the tokens.
     * @param _unitAmount The amount of token to be burned.
     */
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
                && balanceOf[_from] >= _unitAmount);

        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        totalSupply = totalSupply.sub(_unitAmount);
        Burn(_from, _unitAmount);
    }

    /**
     * @dev Function to distribute tokens to the list of addresses by the provided amount
     */
    function bulkTransfer(address[] addresses, uint256 amount) public returns (bool) {
        require(amount > 0
                && addresses.length > 0
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);

        for (uint j = 0; j < addresses.length; j++) {
            require(addresses[j] != 0x0
                    && frozenAccount[addresses[j]] == false
                    && now > unlockUnixTime[addresses[j]]);

            balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amount);
            Transfer(msg.sender, addresses[j], amount);
        }
        return true;
    }

    function bulkTransfer(address[] addresses, uint256[] amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && addresses[j] != 0x0
                    && frozenAccount[addresses[j]] == false
                    && now > unlockUnixTime[addresses[j]]);

            totalAmount = totalAmount.add(amounts[j]);
        }
        require(balanceOf[msg.sender] >= totalAmount);

        for (j = 0; j < addresses.length; j++) {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(amounts[j]);
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]);
            Transfer(msg.sender, addresses[j], amounts[j]);
        }
        return true;
    }

    function() payable public {
    }
}