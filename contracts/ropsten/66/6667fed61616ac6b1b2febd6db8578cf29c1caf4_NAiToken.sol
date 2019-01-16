pragma solidity 0.4.24;

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

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract TokenRepository is Ownable {

    using SafeMath for uint256;

    // Name of the ERC-20 token.
    string public name;

    // Symbol of the ERC-20 token.
    string public symbol;

    // Total decimals of the ERC-20 token.
    uint256 public decimals;

    // Total supply of the ERC-20 token.
    uint256 public totalSupply;

    // Mapping to hold balances.
    mapping(address => uint256) public balances;

    // Mapping to hold allowances.
    mapping (address => mapping (address => uint256)) public allowed;

    /**
    * @dev Sets the name of ERC-20 token.
    * @param _name Name of the token to set.
    */
    function setName(string _name) public onlyOwner {
        name = _name;
    }

    /**
    * @dev Sets the symbol of ERC-20 token.
    * @param _symbol Symbol of the token to set.
    */
    function setSymbol(string _symbol) public onlyOwner {
        symbol = _symbol;
    }

    /**
    * @dev Sets the total decimals of ERC-20 token.
    * @param _decimals Total decimals of the token to set.
    */
    function setDecimals(uint256 _decimals) public onlyOwner {
        decimals = _decimals;
    }

    /**
    * @dev Sets the total supply of ERC-20 token.
    * @param _totalSupply Total supply of the token to set.
    */
    function setTotalSupply(uint256 _totalSupply) public onlyOwner {
        totalSupply = _totalSupply;
    }

    /**
    * @dev Sets balance of the address.
    * @param _owner Address to set the balance of.
    * @param _value Value to set.
    */
    function setBalances(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = _value;
    }

    /**
    * @dev Sets the value of tokens allowed to be spent.
    * @param _owner Address owning the tokens.
    * @param _spender Address allowed to spend the tokens.
    * @param _value Value of tokens to be allowed to spend.
    */
    function setAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = _value;
    }

    /**
    * @dev Mints new tokens.
    * @param _owner Address to transfer new tokens to.
    * @param _value Amount of tokens to be minted.
    */
    function mintTokens(address _owner, uint256 _value) public onlyOwner {
        require(_value > totalSupply.add(_value), "");
        
        totalSupply = totalSupply.add(_value);
        setBalances(_owner, _value);
    }
    
    /**
    * @dev Burns tokens and decreases the total supply.
    * @param _value Amount of tokens to burn.
    */
    function burnTokens(uint256 _value) public onlyOwner {
        require(_value <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
    }

    /**
    * @dev Increases the balance of the address.
    * @param _owner Address to increase the balance of.
    * @param _value Value to increase.
    */
    function increaseBalance(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = balances[_owner].add(_value);
    }

    /**
    * @dev Increases the tokens allowed to be spent.
    * @param _owner Address owning the tokens.
    * @param _spender Address to increase the allowance of.
    * @param _value Value to increase.
    */
    function increaseAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = allowed[_owner][_spender].add(_value);
    }

    /**
    * @dev Decreases the balance of the address.
    * @param _owner Address to decrease the balance of.
    * @param _value Value to decrease.
    */
    function decreaseBalance(address _owner, uint256 _value) public onlyOwner {
        balances[_owner] = balances[_owner].sub(_value);
    }

    /**
    * @dev Decreases the tokens allowed to be spent.
    * @param _owner Address owning the tokens.
    * @param _spender Address to decrease the allowance of.
    * @param _value Value to decrease.
    */
    function decreaseAllowed(address _owner, address _spender, uint256 _value) public onlyOwner {
        allowed[_owner][_spender] = allowed[_owner][_spender].sub(_value);
    }

    /**
    * @dev Transfers the balance from one address to another.
    * @param _from Address to transfer the balance from.
    * @param _to Address to transfer the balance to.
    * @param _value Value to transfer.
    */
    function transferBalance(address _from, address _to, uint256 _value) public onlyOwner {
        decreaseBalance(_from, _value);
        increaseBalance(_to, _value);
    }
}


contract ERC223Receiver {
    function tokenFallback(address _sender, address _origin, uint _value, bytes _data) public returns (bool);
}

/**
 * @title ERC223 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC223Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

/**
 * @title Standard ERC20 token.
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC223Token is ERC223Interface, Pausable {

    TokenRepository public tokenRepository;

    /**
    * @dev Constructor function.
    */
    constructor() public {
        tokenRepository = new TokenRepository();
    }

    /**
    * @dev Name of the token.
    */
    function name() public view returns (string) {
        return tokenRepository.name();
    }

    /**
    * @dev Symbol of the token.
    */
    function symbol() public view returns (string) {
        return tokenRepository.symbol();
    }

    /**
    * @dev Total decimals of tokens.
    */
    function decimals() public view returns (uint256) {
        return tokenRepository.decimals();
    }

    /**
    * @dev Total number of tokens in existence.
    */
    function totalSupply() public view returns (uint256) {
        return tokenRepository.totalSupply();
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return tokenRepository.balances(_owner);
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return tokenRepository.allowed(_owner, _spender);
    }

    /**
    * @dev Function to execute transfer of token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        return transfer(_to, _value, new bytes(0));
    }

    /**
    * @dev Function to execute transfer of token from one address to another.
    * @param _from address The address which you want to send tokens from.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 the amount of tokens to be transferred.
    */
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
        return transferFrom(_from, _to, _value, new bytes(0));
    }

    /**
    * @dev Internal function to execute transfer of token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Data to be passed.
    */
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
        //filtering if the target is a contract with bytecode inside it
        if (!_transfer(_to, _value)) revert(); // do a normal token transfer
        if (_isContract(_to)) return _contractFallback(msg.sender, _to, _value, _data);
        return true;
    }

    /**
    * @dev Internal function to execute transfer of token from one address to another.
    * @param _from address The address which you want to send tokens from.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 the amount of tokens to be transferred.
    * @param _data Data to be passed.
    */
    function transferFrom(address _from, address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
        if (!_transferFrom(_from, _to, _value)) revert(); // do a normal token transfer
        if (_isContract(_to)) return _contractFallback(_from, _to, _value, _data);
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
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        tokenRepository.setAllowed(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * Approve should be called when allowed[_spender] == 0. To increment
    * Allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined).
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        tokenRepository.increaseAllowed(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, tokenRepository.allowed(msg.sender, _spender));
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * Approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined).
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        uint256 oldValue = tokenRepository.allowed(msg.sender, _spender);
        if (_value >= oldValue) {
            tokenRepository.setAllowed(msg.sender, _spender, 0);
        } else {
            tokenRepository.decreaseAllowed(msg.sender, _spender, _value);
        }
        emit Approval(msg.sender, _spender, tokenRepository.allowed(msg.sender, _spender));
        return true;
    }

    /**
    * @dev Internal function to execute transfer of token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function _transfer(address _to, uint256 _value) internal returns (bool) {
        require(_value <= tokenRepository.balances(msg.sender));
        require(_to != address(0));

        tokenRepository.transferBalance(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Internal function to execute transfer of token from one address to another.
    * @param _from address The address which you want to send tokens from.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 the amount of tokens to be transferred.
    */
    function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value <= tokenRepository.balances(_from));
        require(_value <= tokenRepository.allowed(_from, msg.sender));
        require(_to != address(0));

        tokenRepository.transferBalance(_from, _to, _value);
        tokenRepository.decreaseAllowed(_from, msg.sender, _value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Private function that is called when target address is a contract.
    * @param _from address The address which you want to send tokens from.
    * @param _to address The address which you want to transfer to.
    * @param _value uint256 the amount of tokens to be transferred.
    * @param _data Data to be passed.
    */
    function _contractFallback(address _from, address _to, uint _value, bytes _data) private returns (bool) {
        ERC223Receiver reciever = ERC223Receiver(_to);
        return reciever.tokenFallback(msg.sender, _from, _value, _data);
    }

    /**
    * @dev Private function that differentiates between an external account and contract account.
    * @param _address Address of contract/account.
    */
    function _isContract(address _address) private view returns (bool) {
        // Retrieve the size of the code on target address, this needs assembly.
        uint length;
        assembly { length := extcodesize(_address) }
        return length > 0;
    }
}

contract NAiToken is ERC223Token {

    constructor() public {
        tokenRepository.setName("NAiToken");
        tokenRepository.setSymbol("NAi");
        tokenRepository.setDecimals(6);
        tokenRepository.setTotalSupply(20000000 * 10 ** uint(tokenRepository.decimals()));

        tokenRepository.setBalances(msg.sender, tokenRepository.totalSupply());
    }

    /**
    * @dev Owner of the storage contract.
    */
    function storageOwner() public view returns(address) {
        return tokenRepository.owner();
    }
    
    /**
    * @dev Burns tokens and decreases the total supply.
    * @param _value Amount of tokens to burn.
    */
    function burnTokens(uint256 _value) public onlyOwner {
        tokenRepository.burnTokens(_value);
        emit Transfer(msg.sender, address(0), _value);
    }

    /**
    * @dev Transfers the ownership of storage contract.
    * @param _newContract The address to transfer to.
    */
    function transferStorageOwnership(address _newContract) public onlyOwner {
        tokenRepository.transferOwnership(_newContract);
    }

    /**
    * @dev Kills the contract and renders it useless.
    * Can only be executed after transferring the ownership of storage.
    */
    function killContract() public onlyOwner {
        require(storageOwner() != address(this));
        selfdestruct(owner);
    }
}