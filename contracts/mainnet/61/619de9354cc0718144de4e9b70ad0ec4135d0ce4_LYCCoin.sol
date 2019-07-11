/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity >=0.4.22 <0.6.0;

contract IERC20 {
    function totalSupply() constant public returns (uint256);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remianing);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*
CREATED BY ANDRAS SZEKELY, SaiTech (c) 2019

*/ 

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
	uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract LYCCoin is IERC20, Ownable {

    using SafeMath for uint256;

    uint public _totalSupply = 0;
    uint public constant INITIAL_SUPPLY = 175000000000000000000000000;
    uint public MAXUM_SUPPLY =            175000000000000000000000000;
    uint256 public _currentSupply = 0;

    string public constant symbol = "LYC";
    string public constant name = "LYCCoin";
    uint8 public constant decimals = 18;

    uint256 public RATE;

    bool public mintingFinished = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
	mapping (address => uint256) public freezeOf;
    mapping(address => bool) whitelisted;
    mapping(address => bool) blockListed;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event LogUserAdded(address user);
    event LogUserRemoved(address user);




    constructor() public {
        setRate(1);
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);

        owner = msg.sender;
    }

    function () public payable {
        revert();
    }

    function createTokens() payable public {
        require(msg.value > 0);
        require(whitelisted[msg.sender]);

        uint256 tokens = msg.value.mul(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);

        owner.transfer(msg.value);
    }

    function totalSupply() constant public returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);

        require(
            balances[msg.sender] >= _value
            && _value > 0
            && !blockListed[_to]
            && !blockListed[msg.sender]
        );

        // Save this for an assertion in the future
        uint previousBalances = balances[msg.sender] + balances[_to];
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);                     // Subtract from the sender
        balances[_to] = SafeMath.add(balances[_to], _value);                            // Add the same to the recipient

        emit Transfer(msg.sender, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender] + balances[_to] == previousBalances);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(
            balances[msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            && whitelisted[msg.sender]
            && !blockListed[_to]
            && !blockListed[msg.sender]
        );
        balances[_from] = SafeMath.sub(balances[_from], _value);                           // Subtract from the sender
        balances[_to] = SafeMath.add(balances[_to], _value);                             // Add the same to the recipient
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        whitelisted[_spender] = true;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remianing) {
        return allowed[_owner][_spender];
    }

    function getRate() public constant returns (uint256) {
        return RATE;
    }

    function setRate(uint256 _rate) public returns (bool success) {
        RATE = _rate;
        return true;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        uint256 tokens = _amount.mul(RATE);
        require(
            _currentSupply.add(tokens) < MAXUM_SUPPLY
            && whitelisted[msg.sender]
            && !blockListed[_to]
        );

        if (_currentSupply >= INITIAL_SUPPLY) {
            _totalSupply = _totalSupply.add(tokens);
        }

        _currentSupply = _currentSupply.add(tokens);
        balances[_to] = balances[_to].add(tokens);
        emit Mint(_to, tokens);
        emit Transfer(address(0), _to, tokens);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    // Add a user to the whitelist
    function addUser(address user) onlyOwner public {
        whitelisted[user] = true;
        emit LogUserAdded(user);
    }

    // Remove an user from the whitelist
    function removeUser(address user) onlyOwner public {
        whitelisted[user] = false;
        emit LogUserRemoved(user);
    }

    function getCurrentOwnerBallence() constant public returns (uint256) {
        return balances[msg.sender];
    }

    function addBlockList(address wallet) onlyOwner public {
        blockListed[wallet] = true;
    }

    function removeBlockList(address wallet) onlyOwner public {
        blockListed[wallet] = false;
    }

 
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);           // Subtract from the sender
        _totalSupply = SafeMath.sub(_totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        _totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }


	function freeze(uint256 _value) onlyOwner public returns (bool success) {
        if (balances[msg.sender] < _value) revert();            // Check if the sender has enough
		if (_value <= 0) revert(); 
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);                        // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) onlyOwner public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert();            // Check if the sender has enough
		if (_value <= 0) revert(); 
        freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

}