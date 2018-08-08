pragma solidity ^0.4.18;
/*
The Regen Coin

ERC-20 Token Standard Compliant
EIP-621 Compliant

Contract developer: Oyewole Samuel <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5a38332e393f282e1a3d373b333674393537">[email&#160;protected]</a>
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }    
}

/**
 * This contract is administered
 */

contract admined {
    address public admin; //Admin address is public
    address public allowed;//Allowed addres is public

    bool public locked = true; //initially locked
    /**
    * @dev This constructor set the initial admin of the contract
    */
    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-allowed functions
        require(msg.sender == admin || msg.sender == allowed);
        _;
    }

    modifier lock() { //A modifier to lock specific supply functions
        require(locked == false);
        _;
    }


    function allowedAddress(address _allowed) onlyAdmin public {
        allowed = _allowed;
        Allowed(_allowed);
    }
    /**
    * @dev Transfer the adminship of the contract
    * @param _newAdmin The address of the new admin.
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }
    /**
    * @dev Enable or disable lock
    * @param _locked Status.
    */
    function lockSupply(bool _locked) onlyAdmin public {
        locked = _locked;
        LockedSupply(locked);
    }

    //All admin actions have a log for public review
    event TransferAdminship(address newAdmin);
    event Admined(address administrador);
    event LockedSupply(bool status);
    event Allowed(address allow);
}


/**
 * Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


contract ERC20Token is admined, ERC20TokenInterface { //Standar definition of an ERC20Token
    using SafeMath for uint256;
    uint256 totalSupply_;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances

    /**
    * @dev Get the balance of an specified address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }    

    /**
    * @dev transfer token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev transfer token from an address to another specified address using allowance
    * @param _from The address where token comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Assign allowance to an specified address to use the owner balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    *Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DropdCoin is admined, ERC20Token {
    string public name = "Dropd Coin";
    string public symbol = "DPD";
    string public version = "1.0";
    uint8 public decimals = 18;

    function DropdCoin() public {
        totalSupply_ = 500000000 * (10**uint256(decimals));
        balances[0x3C94676FD9D27195895A8D1F4e20719C2cA01069] = totalSupply_; //move all tokens to owners contract
        //balances[this] = totalSupply_;
        
        /**
        *Log Events
        */
        Transfer(0, this, totalSupply_);
        Approval(this, msg.sender, balances[this]);

    }
    /**
    *@dev Function to handle callback calls
    */
    function() public {
        revert();
    }
}