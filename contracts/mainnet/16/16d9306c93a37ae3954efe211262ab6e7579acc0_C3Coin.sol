pragma solidity ^0.4.24;


/**
 * @title ERC223
 * @dev Interface for ERC223
 */
interface ERC223 {

    // functions
    function balanceOf(address _owner) external constant returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
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
}


/**
 * @notice A contract will throw tokens if it does not inherit this
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

    function tokenFallback(address _from, uint256 _value, bytes _data) external pure {
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

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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
 * @title C3Coin
 * @dev C3Coin is an ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract C3Coin is ERC223, Ownable {
    using SafeMath for uint;


    string public name = "C3coin";
    string public symbol = "CCC";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10e10 * 1e18;


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
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @notice This function is modified for erc223 standard
     * @dev ERC20 transfer function added for backward compatibility.
     * @param _to Address of token receiver
     * @param _value Number of tokens to send
     */
    function transfer(address _to, uint _value) public returns (bool success) {
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
     * @param _data Data equivalent to tx.data from ethereum transaction
     */
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {

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
     */
    function multiTransfer(address[] _addresses, uint256 _amount) public returns (bool) {

        uint256 totalAmount = _amount.mul(_addresses.length);
        require(balances[msg.sender] >= totalAmount);

        for (uint j = 0; j < _addresses.length; j++) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_addresses[j]] = balances[_addresses[j]].add(_amount);
            emit Transfer(msg.sender, _addresses[j], _amount);
        }
        return true;
    }


    /**
     * @dev Function to distribute tokens to the list of addresses by the provided various amount
     * @param _addresses List of addresses
     * @param _amounts List of token amounts
     */
    function multiTransfer(address[] _addresses, uint256[] _amounts) public returns (bool) {

        uint256 totalAmount = 0;

        for(uint j = 0; j < _addresses.length; j++){

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
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) onlyOwner public {
        _burn(msg.sender, _value);
    }

    function _burn(address _owner, uint256 _value) internal {
        require(_value <= balances[_owner]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_owner] = balances[_owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_owner, _value);
        emit Transfer(_owner, address(0), _value);
    }

    /**
     * @dev Default payable function executed after receiving ether
     */
    function () public payable {
        // does not accept ether
    }
}