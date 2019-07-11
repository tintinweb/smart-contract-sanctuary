/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-25
*/

pragma solidity ^0.5.1;

/*
    email 
    <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5e373038311e2c3b3f322a702a31">[email&#160;protected]</a>

    Facebbok 
    https://www.facebook.com/Real-T-323544031677341/

    Twitter 
    https://twitter.com/realtstable
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
        require(msg.sender == owner, "Sender is not the owner.");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4), "Payload size is incorrect.");
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        require(_to != address(0), "_to address is invalid.");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        require(_from != address(0), "_from address is invalid.");
        require(_to != address(0), "_to address is invalid.");

        uint _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)), "Invalid function arguments.");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Token is paused.");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Token is unpaused.");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract REALT is Pausable, StandardToken {

    string public name;
    string public symbol;
    uint public decimals;

    mapping(address => bool) public authorized;
    mapping(address => bool) public blacklisted;

    //  The contract can be initialized with a number of tokens
    //  All the tokens are deposited to the owner address
    //
    // @param _balance Initial supply of the contract
    // @param _name Token Name
    // @param _symbol Token symbol
    // @param _decimals Token decimals
    constructor() public {
        name = "REAL-T";
        symbol = "REALT";
        decimals = 4;
        setAuthorization(0x4E3BC31fF1cD79ffeeC9088762bf42dA9C095809);
        transferOwnership(0x4E3BC31fF1cD79ffeeC9088762bf42dA9C095809);
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "msg.sender is not authorized");
        _;
    }

    event AuthorizationSet(address _address);
    function setAuthorization(address _address) public onlyOwner {
        require(_address != address(0), "Provided address is invalid.");
        require(!authorized[_address], "Address is already authorized.");
        
        authorized[_address] = true;

        emit AuthorizationSet(_address);
    }

    event AuthorizationRevoked(address _address);
    function revokeAuthorization(address _address) public onlyOwner {
        require(_address != address(0), "Provided address is invalid.");
        require(authorized[_address], "Address is already unauthorized.");

        authorized[_address] = false;

        emit AuthorizationRevoked(_address);
    }

    modifier NotBlacklisted(address _address) {
        require(!blacklisted[_address], "The provided address is blacklisted.");
        _;
    }
    
    event BlacklistAdded(address _address);
    function addBlacklist(address _address) public onlyAuthorized {
        require(_address != address(0), "Provided address is invalid.");
        require(!blacklisted[_address], "The provided address is already blacklisted");
        blacklisted[_address] = true;
        
        emit BlacklistAdded(_address);
    }

    event BlacklistRemoved(address _address);
    function removeBlacklist(address _address) public onlyAuthorized {
        require(_address != address(0), "Provided address is invalid.");
        require(blacklisted[_address], "The provided address is already not blacklisted");
        blacklisted[_address] = false;
        
        emit BlacklistRemoved(_address);
    }
    
    function transfer(address _to, uint _value) public NotBlacklisted(_to) NotBlacklisted(msg.sender) whenNotPaused {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public NotBlacklisted(_to) NotBlacklisted(_from) NotBlacklisted(msg.sender) whenNotPaused {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address who) public view returns (uint) {
        return super.balanceOf(who);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        return super.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return super.allowance(_owner, _spender);
    }


    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyAuthorized {
        _totalSupply = _totalSupply.add(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        
        emit Transfer(address(0), msg.sender, amount);
        emit Issue(amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyAuthorized {
        require(_totalSupply >= amount, "Redeem amount is greater than total supply.");
        require(balances[msg.sender] >= amount, "Redeem amount is greater than sender&#39;s balance.");

        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        
        emit Transfer(msg.sender, address(0), amount);
        emit Redeem(amount);
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

}