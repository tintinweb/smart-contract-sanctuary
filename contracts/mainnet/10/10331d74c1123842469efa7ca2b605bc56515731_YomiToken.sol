/*
 *  The Yomi Token contract complies with the ERC20 standard (see https://github.com/ethereum/EIPs/issues/20).
 *  All tokens not being sold during the crowdsale but the reserved token for tournaments future financing are burned.
 *  Author: Plan B.
 */
pragma solidity ^0.4.24;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Owned {
    address public ownerAddr;
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        ownerAddr = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == ownerAddr);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != 0x0);
        ownerAddr = _newOwner;
        emit TransferOwnership(ownerAddr, _newOwner);
    }
}

contract ERC20 {
    // Base function
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    // Public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract YomiToken is Owned, ERC20{
    using SafeMath for uint256;
    
    // Public variables of the token
    string constant public name = "YOMI Token";
    string constant public symbol = "YOMI";
    uint8 constant public decimals = 18;
    uint256 total_supply = 1000000000e18; // Total supply of 1 billion Yomi Tokens
    uint256 constant public teamReserve = 100000000e18; //10%
    uint256 constant public foundationReserve = 200000000e18; //20%
    uint256 constant public startTime = 1533110400; // Good time:2018-08-01 08:00:00  GMT
    uint256 public lockReleaseDate6Month; // 6 month = 182 days
    uint256 public lockReleaseDate1Year; // 1 year = 365 days
    address public teamAddr;
    address public foundationAddr;
    
    // Array
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccounts;
    
    // This generates a public event on the blockchain that will notify clients
    event FrozenFunds(address _target, bool _freeze);
    
    /**
     * Constrctor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address _teamAddr, address _foundationAddr) public {
        teamAddr = _teamAddr;
        foundationAddr = _foundationAddr;
        lockReleaseDate6Month = startTime + 182 days;
        lockReleaseDate1Year = startTime + 365 days;
        balances[ownerAddr] = total_supply; // Give the creator all initial tokens
    }
    
    /**
     * `freeze? Prevent | Allow` `_target` from sending & receiving tokens
     * @param _freeze either to freeze it or not
     */
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccounts[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }
    
    /**
     * Get the total supply
     */
    function totalSupply() public view returns (uint256 _totalSupply) {
        _totalSupply = total_supply;
    }
    
    /**
     * What is the balance of a particular account?
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    /**
     * Returns the amount which _spender is still allowed to withdraw from _owner
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
     * Internal transfer,only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        
        // Lock tokens of team
        if (_from == teamAddr && now < lockReleaseDate6Month) {
            require(balances[_from].sub(_value) >= teamReserve);
        }
        // Lock tokens of foundation        
        if (_from == foundationAddr && now < lockReleaseDate1Year) {
            require(balances[_from].sub(_value) >= foundationReserve);
        }
        
        // Check if the sender has enough
        require(balances[_from] >= _value); 
        // Check for overflows
        require(balances[_to] + _value > balances[_to]); 
        //Check if account is frozen
        require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]);
        
        // Save this for an assertion in the future
        uint256 previousBalances = balances[_from].add(balances[_to]);
        // Subtract from the sender
        balances[_from] = balances[_from].sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
    /**
     * Transfer tokens
     * Send `_value` tokens to `_to` from your account.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * Transfer tokens from other address
     * Send `_value` tokens to `_to` on behalf of `_from`.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check allowance
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * Set allowance for other address
     * Allows `_spender` to spend no more than `_value` tokens on your behalf.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}