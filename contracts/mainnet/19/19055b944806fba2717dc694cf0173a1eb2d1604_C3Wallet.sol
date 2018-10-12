pragma solidity ^0.4.24;


/**
 * @title ERC223
 * @dev New Interface for ERC223
 */
contract ERC223 {

    // functions
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);



    // Getters
    function name() external constant returns  (string _name);
    function symbol() external constant returns  (string _symbol);
    function decimals() external constant returns (uint8 _decimals);
    function totalSupply() external constant returns (uint256 _totalSupply);


    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event Burn(address indexed burner, uint256 value);
    event FrozenAccount(address indexed targets);
    event UnfrozenAccount(address indexed target);
    event LockedAccount(address indexed target, uint256 locked);
    event UnlockedAccount(address indexed target);
}


/**
 * @notice The contract will throw tokens if it does not inherit this
 * @title ERC223ReceivingContract
 * @dev Contract for ERC223 token fallback
 */
contract ERC223ReceivingContract {

    TKN internal fallback;

    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
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
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



/**
 * @title C3Wallet
 * @dev C3Wallet is a ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract C3Wallet is ERC223, Ownable {
    using SafeMath for uint;


    string public name = "C3Wallet";
    string public symbol = "C3W";
    uint8 public decimals = 8;
    uint256 public totalSupply = 5e10 * 1e8;
    
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;


    constructor() public {
        balances[msg.sender] = totalSupply;
    }


    mapping (address => uint256) public balances;

    mapping(address => mapping (address => uint256)) public allowance;


    /**
     * @dev Getters
     */
    // Function to access name of token .
    function name() external constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }


    /**
     * @dev Get balance of a token owner
     * @param _owner The address which one owns tokens
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @notice This function is modified for erc223 standard
     * @dev ERC20 transfer function added for backward compatibility.
     * @param _to Address of token receiver
     * @param _value Number of tokens to send
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]
                && _to != address(this));
        bytes memory empty = hex"00000000";
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }


    /**
     * @dev ERC223 transfer function
     * @param _to Address of token receiver
     * @param _value Number of tokens to send
     * @param _data data equivalent to tx.data from ethereum transaction
     */
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_value > 0
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]
                && _to != address(this));
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }


    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    /**
     * @dev Prevent targets from sending or receiving tokens
     * @param _targets Addresses to be frozen
     */
    function freezeAccounts(address[] _targets) onlyOwner public {
        require(_targets.length > 0);

        for (uint j = 0; j < _targets.length; j++) {
            require(_targets[j] != 0x0 && _targets[j] != Ownable.owner);
            frozenAccount[_targets[j]] = true;
            emit FrozenAccount(_targets[j]);
        }
    }
    
    /**
     * @dev Enable frozen targets to send or receive tokens
     * @param _targets Addresses to be unfrozen
     */
    function unfreezeAccounts(address[] _targets) onlyOwner public {
        require(_targets.length > 0);

        for (uint j = 0; j < _targets.length; j++) {
            require(_targets[j] != 0x0 && _targets[j] != Ownable.owner);
            frozenAccount[_targets[j]] = false;
            emit UnfrozenAccount(_targets[j]);
        }
    }
    
    

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix times.
     * @param _targets Addresses to be locked funds
     * @param _unixTimes Unix times when locking up will be finished
     */
    function lockAccounts(address[] _targets, uint[] _unixTimes) onlyOwner public {
        require(_targets.length > 0
                && _targets.length == _unixTimes.length);

        for(uint j = 0; j < _targets.length; j++){
            require(_targets[j] != Ownable.owner);
            require(unlockUnixTime[_targets[j]] < _unixTimes[j]);
            unlockUnixTime[_targets[j]] = _unixTimes[j];
            emit LockedAccount(_targets[j], _unixTimes[j]);
        }
    }
    
     /**
     * @dev Enable locked targets to send or receive tokens.
     * @param _targets Addresses to be locked funds
     */
    function unlockAccounts(address[] _targets) onlyOwner public {
        require(_targets.length > 0);
         
        for(uint j = 0; j < _targets.length; j++){
            unlockUnixTime[_targets[j]] = 0;
            emit UnlockedAccount(_targets[j]);
        }
    }


    // function which is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    // function which is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit ERC223Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * @dev Transfer tokens from one address to another
     *      Added due to backwards compatibility with ERC20
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balances[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && frozenAccount[_from] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[_from]
                && now > unlockUnixTime[_to]);


        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = 0; // mitigate the race condition
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner Address The address which owns the funds.
     * @param _spender Address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }


    /**
     * @dev Function to distribute tokens to the list of addresses by the provided uniform amount
     * @param _addresses List of addresses
     * @param _amount Uniform amount of tokens
     * @return A bool specifying the result of transfer
     */
    function multiTransfer(address[] _addresses, uint256 _amount) public returns (bool) {
        require(_amount > 0
                && _addresses.length > 0
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = _amount.mul(_addresses.length);
        require(balances[msg.sender] >= totalAmount);

        for (uint j = 0; j < _addresses.length; j++) {
            require(_addresses[j] != 0x0
                    && frozenAccount[_addresses[j]] == false
                    && now > unlockUnixTime[_addresses[j]]);
                    
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_addresses[j]] = balances[_addresses[j]].add(_amount);
            emit Transfer(msg.sender, _addresses[j], _amount);
        }
        return true;
    }


    /**
     * @dev Function to distribute tokens to the list of addresses by the provided various amount
     * @param _addresses list of addresses
     * @param _amounts list of token amounts
     */
    function multiTransfer(address[] _addresses, uint256[] _amounts) public returns (bool) {
        require(_addresses.length > 0
                && _addresses.length == _amounts.length
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint j = 0; j < _addresses.length; j++){
            require(_amounts[j] > 0
                    && _addresses[j] != 0x0
                    && frozenAccount[_addresses[j]] == false
                    && now > unlockUnixTime[_addresses[j]]);

            totalAmount = totalAmount.add(_amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);

        for (j = 0; j < _addresses.length; j++) {
            balances[msg.sender] = balances[msg.sender].sub(_amounts[j]);
            balances[_addresses[j]] = balances[_addresses[j]].add(_amounts[j]);
            emit Transfer(msg.sender, _addresses[j], _amounts[j]);
        }
        return true;
    }
    
    
    /**
     * @dev Burns a specific amount of tokens.
     * @param _from The address that will burn the tokens.
     * @param _tokenAmount The amount of token to be burned
     */
    function burn(address _from, uint256 _tokenAmount) onlyOwner public {
        require(_tokenAmount > 0
                && balances[_from] >= _tokenAmount);
        
        
        balances[_from] = balances[_from].sub(_tokenAmount);
        totalSupply = totalSupply.sub(_tokenAmount);
        emit Burn(_from, _tokenAmount);
    }


    /**
     * @dev default payable function executed after receiving ether
     */
    function () public payable {
        // does not accept ether
    }
}