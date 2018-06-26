pragma solidity ^0.4.24;

// File: contracts/Authorizable.sol

contract Authorizable {
    
    constructor() internal {}

    event AuthorizationSet(address indexed addressAuthorized,bool indexed authorization);

    function isAuthorized(address addr) public view returns (bool);

    function setAuthorized(address addressAuthorized, bool authorization) public;
}

// File: contracts/BaseAuthorizable.sol

contract BaseAuthorizable is Authorizable{
    mapping(address => bool) internal authorized;

    event AuthorizationSet(address indexed addressAuthorized,bool indexed authorization);

    constructor () internal {
        authorized[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], &quot;Only authorized addresses&quot;);
        _;
    }

    function isAuthorized(address addr) public view returns (bool) {
        return authorized[addr] == true;
    }

    function setAuthorized(address addressAuthorized, bool authorization) public {
        require(addressAuthorized != address(0));
        emit AuthorizationSet(addressAuthorized, authorization);
        authorized[addressAuthorized] = authorization;
    }

}

// File: contracts/ERC223.sol

contract ERC223 {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);

    constructor() internal {}

    // Checks if the address refers to a contract
    // returns true if to is a contract false otherwise
    function _isContract(address to) internal view returns (bool) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(to)
        }
        return codeLength > 0;
    }

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data) public returns (bool ok);
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns (bool ok);
}

// File: contracts/ERC223TokenReceiver.sol

contract ERC223TokenReceiver {

    constructor () internal {}

    function tokenFallback(address from, uint256 value, bytes data) public;
}

// File: contracts/SafeMath.sol

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a  == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256 c) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256 c) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}

// File: contracts/BaseERC223Token.sol

contract BaseERC223Token is ERC223 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    constructor (uint256 _totalSupply, string _name, string _symbol, uint8 _decimals) internal {
        decimals = _decimals;
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        _balances[msg.sender] = totalSupply;
    }

    function balanceOf(address who) public view returns (uint256){
        return _balances[who];
    }


    function transfer(address to, uint256 value) public returns(bool) {
        require(to != address(0));
        require(to != address(this));
        require(_balances[msg.sender] >= value);
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transfer(address to, uint256 value, bytes data) public returns(bool) {
        return _transferInternal(msg.sender,to, value, data);
    }


    function transfer(address to, uint256 value, bytes data, string custom_fallback) public returns(bool) {
        return _transferInternal(msg.sender, to, value, data, custom_fallback);
    }

    function _transferInternal(address from, address to, uint256 value, bytes data) internal returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        require(_balances[from] >= value);
        if (_isContract(to)) {
            return _transferToContract(from, to, value, data);
        } else {
            return _transferToAddress(from, to, value, data);
        }
    }

    function _transferInternal(address from, address to, uint256 value, bytes data, string custom_fallback) internal returns(bool) {
        require(from != address(0));
        require(to != address(0));
        require(to != address(this));
        require(_balances[from] >= value);
        if (_isContract(to)) {
            _balances[from] = _balances[from].sub(value);
            _balances[to] = _balances[to].add(value);

            assert(to.call.value(0)(bytes4(keccak256(custom_fallback)), from, value, data));
            emit Transfer(from, to, value, data);
            return true;
        } else {
            return _transferToAddress(from, to, value, data);
        }
    }

    function _transferToContract(address from,address to, uint256 value, bytes data) private returns(bool) {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        ERC223TokenReceiver receiver = ERC223TokenReceiver(to);
        receiver.tokenFallback(from, value, data);
        emit Transfer(from, to, value, data);
        return true;
    }

    function _transferToAddress(address from, address to, uint256 value, bytes data) private returns(bool) {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value, data);
        return true;
    }

}

// File: contracts/CoinShareVoucherInterface.sol

contract CoinShareVoucherInterface is ERC223, Authorizable {

    // function transferFrom(address from, address to, uint256 value) public returns(bool);
}

// File: contracts/Ownable.sol

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, &quot;Only owner can call this function.&quot;);
        _;
    }

    function isOwner(address who) internal view returns(bool) {
        return who == owner;
    }

   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/Startable.sol

contract Startable {
    
    event Start();
    
    bool internal _started = false;

    constructor (bool initiallyStarted) internal {
        _started = initiallyStarted;
    }

    modifier whenStarted() {
        require(_started, &quot;This function can only be called when the contract is started.&quot;);
        _;
    }

    function started() public view returns (bool) {
        return _started;
    }

    function start() public {
        _started = true;
        emit Start();
    }

}

// File: contracts/Stoppable.sol

contract Stoppable is Startable {
    
    event Stop();

    constructor(bool initiallyStarted) Startable(initiallyStarted) internal {

    }

    modifier whenStopped() {
        require(!_started,&quot;This function can be called only when contract is stopped.&quot;);
        _;
    }

    function stop() public {
        _started = false;
        emit Stop();
    }

}

// File: contracts/CoinShareVoucher.sol

/**
  *
  * CoinShare Voucher is a token, that can be spent to claim future released
  * CoinShare tokens.
  * The token in not tradable, and the owner of the contract can start and stop the ability
  * to claim final tokens at will.
  */
contract CoinShareVoucher is CoinShareVoucherInterface, BaseERC223Token, BaseAuthorizable, Ownable, Stoppable {

    /**
     * Address of the contract that will allow to exchange vouchers with final tokens.
     */
    address public validTransferAddress;

    event TargetAddressChanged(address indexed previousTarget, address indexed newTarget);

    constructor (uint256 _totalSupply,string _name, string _symbol,uint8 _decimals) 
        BaseERC223Token(_totalSupply,_name,_symbol,_decimals) 
        Stoppable(false) 
        public {
        validTransferAddress = address(0);
    }

    function _isAuthorizedOrOwner(address _addr) private view returns(bool) {
        return isAuthorized(_addr) || isOwner(_addr);
    }

    function _isValidAddress(address to) private view returns(bool) {
        return validTransferAddress != address(0) && validTransferAddress == to;
    }

    modifier whenAuthorizedOrStartedAndAddressValid(address to) {
        require(_isAuthorizedOrOwner(msg.sender)||(started() && _isValidAddress(to)),
            &quot;This function may be called only if tranferring to a valid address, or you are otherwise authorized.&quot;);
        _;
    }

    /*
     * This function can be used by the owner only to set the address of
     * the contract that will exchange vouchers for final tokens.
     * 
     */
    function setValidTransferAddress(address _addr) public onlyOwner{
        require(_addr != address(this));
        emit TargetAddressChanged(validTransferAddress, _addr);
        validTransferAddress = _addr;
    }

    /**
     * Once the exchange window is open anyone holding vouchers can send tokens to a valid address
     * and receive back final tokens.
     */
    function transfer(address to, uint256 value)  public whenAuthorizedOrStartedAndAddressValid(to) returns(bool) {
        return super.transfer(to, value);
    }


    /**
     * Once the exchange window is open anyone holding vouchers can send tokens to a valid address
     * and receive back final tokens.
     */
    function transfer(address to, uint256 value, bytes data) public whenAuthorizedOrStartedAndAddressValid(to) returns(bool) {
        require(isAuthorized(msg.sender) || isOwner(msg.sender) || (to == validTransferAddress));
        return super.transfer(to, value, data);
    }


    /**
     * Once the exchange window is open anyone holding vouchers can send tokens to a valid address
     * and receive back final tokens.
     */
    function transfer(address to, uint256 value, bytes data, string custom_fallback) public whenAuthorizedOrStartedAndAddressValid(to) returns(bool) {
        require(isAuthorized(msg.sender) || isOwner(msg.sender) || (to == validTransferAddress));
        return super.transfer(to, value, data, custom_fallback);
    }

    /**
     * This function allows the onwer only to open the exchange window.
     */
    function start() public onlyOwner {
        super.start();
    }


    /**
     * This function allows the onwer only to close the exchange window.
     */
    function stop() public onlyOwner {
        super.stop();
    }

    /**
     * This function allows the owner only to authorize another address to tranfer tokens freely, even
     * outside of the exchange window.
     */
    function setAuthorized(address addressAuthorized, bool authorization) public onlyOwner {
         super.setAuthorized(addressAuthorized, authorization);
     }

}