pragma solidity ^0.4.24;

/// @dev Controlled
contract Controlled {

    // Controller address
    address public controller;

    /// @notice Checks if msg.sender is controller
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    /// @notice Constructor to initiate a Controlled contract
    constructor() public { 
        controller = msg.sender;
    }

    /// @notice Gives possibility to change the controller
    /// @param _newController Address representing new controller
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }

}

library SafeMath {

    /// @dev Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    /// @dev Integer division of two numbers, truncating the quotient.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /// @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /// @dev Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/// @dev ERC20 Interface
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
  
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @dev Whitelist Interface
contract WhitelistInterface {
    function isWhitelisted(address _address) public view returns (bool);
}

/// @dev Bond EUR Token
contract BondEURToken is ERC20Interface, Controlled {
    using SafeMath for uint256;

    // ERC20 compatible total supply
    uint256 public totalSupply = 0;

    // Name of the token contract
    string public constant name = "Bond EUR Token";

    // Symbol of the token contract
    string public constant symbol = "EUR";

    // Number of token&#39;s decimals
    uint8 public constant decimals = 18;
    
    // Flag indicating if transfers are enabled
    bool public transfersEnabled = true;

    // mapping for balances of addresses
    mapping(address => uint256) balances;

    // allowance mapping
    mapping (address => mapping (address => uint256)) internal allowed;

    // whitelist reference
    WhitelistInterface public whitelist;

    /// @notice Constructor to create a BondEURToken
    constructor(address _whitelist) public {
        require(_whitelist != address(0));
        whitelist = WhitelistInterface(_whitelist);
    }

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }
     
    /// @notice Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transfersEnabled);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Gets the balance of the specified address.
    /// @param _owner The address to query the the balance of.
    /// @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
  
    /// @dev Internal function to transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(whitelist.isWhitelisted(_from) && whitelist.isWhitelisted(_to));
        require(_value <= balances[_from]);
        require(balances[_to] + _value > balances[_to]); // Overflow check

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    /// @return True if transfer successful
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! 
        if (msg.sender != controller) {
            require(transfersEnabled);
            require(_value <= allowed[_from][msg.sender]);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// Beware that changing an allowance with this method brings the risk that someone may use both the old
    /// and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    /// race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @param _spender The address which will spend the funds.
    /// @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner address The address which owns the funds.
    /// @param _spender address The address which will spend the funds.
    /// @return A uint256 specifying the amount of tokens still available for the spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice Increase the amount of tokens that an owner allowed to a spender.
    /// approve should be called when allowed[_spender] == 0. To increment
    /// allowed value is better to use this function to avoid 2 calls (and wait until
    /// the first transaction is mined)
    /// From MonolithDAO Token.sol
    /// @param _spender The address which will spend the funds.
    /// @param _addedValue The amount of tokens to increase the allowance by.
    function increaseApproval (address _spender, uint256 _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// @notice Decrease the amount of tokens that an owner allowed to a spender.
    /// approve should be called when allowed[_spender] == 0. To decrement
    /// allowed value is better to use this function to avoid 2 calls (and wait until
    /// the first transaction is mined)
    /// From MonolithDAO Token.sol
    /// @param _spender The address which will spend the funds.
    /// @param _subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseApproval (address _spender, uint256 _subtractedValue) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// @notice Function to mint tokens
    /// @param _value The amount of tokens to mint.
    /// @param _to The address that will receive the minted tokens.
    /// @return A boolean that indicates if the operation was successful.
    function mint(uint256 _value, address _to) public onlyController returns (bool) {
        totalSupply = totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /// @notice Burns a specific amount of tokens from specified address
    /// @param _value The amount of token to be burned.
    /// @param _from The address from which tokens are burned.
    /// @return A boolean that indicates if the operation was successful.
    function burn(uint256 _value, address _from) public onlyController returns (bool) {
        totalSupply = totalSupply.sub(_value); 
        balances[_from] = balances[_from].sub(_value); 
        emit Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /// @dev fallback function which prohibits payment
    function () public payable {
        revert();
    }

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == address(0)) {
            controller.transfer(address(this).balance);
            return;
        }

        ERC20Interface token = ERC20Interface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }

    event Mint(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
}