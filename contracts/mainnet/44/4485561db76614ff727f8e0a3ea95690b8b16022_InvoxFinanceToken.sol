pragma solidity 0.4.24;

interface ERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

/**
 * @title ERC223Basic additions to ERC20Basic
 * @dev see also: https://github.com/ethereum/EIPs/issues/223               
 *
*/
contract ERC223 is ERC20 {

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes indexed _data);

    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
    function contractFallback(address _to, uint _value, bytes _data) internal returns (bool success);
    function isContract(address _addr) internal view returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private owner_;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner_ = msg.sender;
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return owner_;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner_, "Only the owner can call this function.");
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner_);
        owner_ = address(0);
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
        require(_newOwner != address(0), "Cannot transfer ownership to zero address.");
        emit OwnershipTransferred(owner_, _newOwner);
        owner_ = _newOwner;
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
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract Generic223Receiver {
    uint public sentValue;
    address public tokenAddr;
    address public tokenSender;
    bool public calledFoo;

    bytes public tokenData;
    bytes4 public tokenSig;

    Tkn private tkn;

    bool private __isTokenFallback;

    struct Tkn {
        address addr;
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }

    modifier tokenPayable {
        assert(__isTokenFallback);
        _;
    }

    function tokenFallback(address _sender, uint _value, bytes _data) public returns (bool success) {

        tkn = Tkn(msg.sender, _sender, _value, _data, getSig(_data));
        __isTokenFallback = true;
        address(this).delegatecall(_data);
        __isTokenFallback = false;
        return true;
    }

    function foo() public tokenPayable {
        saveTokenValues();
        calledFoo = true;
    }

    function getSig(bytes _data) private pure returns (bytes4 sig) {
        uint lngth = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < lngth; i++) {
            sig = bytes4(uint(sig) + uint(_data[i]) * (2 ** (8 * (lngth - 1 - i))));
        }
    }

    function saveTokenValues() private {
        tokenAddr = tkn.addr;
        tokenSender = tkn.sender;
        sentValue = tkn.value;
        tokenSig = tkn.sig;
        tokenData = tkn.data;
    }
}

contract InvoxFinanceToken is ERC223, Ownable {

    using SafeMath for uint256;

    string private name_ = "Invox Finance Token";
    string private symbol_ = "INVOX";
    uint256 private decimals_ = 18;
    uint256 public totalSupply = 464000000 * (10 ** decimals_);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping (address => uint256) internal balances_;
    mapping (address => mapping (address => uint256)) private allowed_;

    constructor() public {
        balances_[msg.sender] = balances_[msg.sender].add(totalSupply);
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function() public payable { revert("Cannot send ETH to this address."); }
    
    function name() public view returns(string) {
        return name_;
    }

    function symbol() public view returns(string) {
        return symbol_;
    }

    function decimals() public view returns(uint256) {
        return decimals_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function safeTransfer(address _to, uint256 _value) public {
        require(transfer(_to, _value), "Transfer failed.");
    }

    function safeTransferFrom(address _from, address _to, uint256 _value) public {
        require(transferFrom(_from, _to, _value), "Transfer failed.");
    }

    function safeApprove( address _spender, uint256 _currentValue, uint256 _value ) public {
        require(allowed_[msg.sender][_spender] == _currentValue, "Current allowance value does not match.");
        approve(_spender, _value);
    }

    // ERC20
    function balanceOf(address _owner) public view returns (uint256) {
        return balances_[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed_[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances_[msg.sender], "Value exceeds balance of msg.sender.");
        require(_to != address(0), "Cannot send tokens to zero address.");

        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= balances_[_from], "Value exceeds balance of msg.sender.");
        require(_value <= allowed_[_from][msg.sender], "Value exceeds allowance of msg.sender for this owner.");
        require(_to != address(0), "Cannot send tokens to zero address.");

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed_[msg.sender][_spender] = allowed_[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed_[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed_[msg.sender][_spender] = 0;
        } else {
            allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

    // ERC223
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_to != address(0), "Cannot transfer token to zero address.");
        require(_value <= balanceOf(msg.sender), "Value exceeds balance of msg.sender.");
        
        transfer(_to, _value);

        if (isContract(_to)) {
            return contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes _data) internal returns (bool success) {
        Generic223Receiver receiver = Generic223Receiver(_to);
        return receiver.tokenFallback(msg.sender, _value, _data);
    }

    // Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) internal view returns (bool) {
        // retrieve the size of the code on target address, this needs assembly
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}