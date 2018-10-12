pragma solidity ^0.4.24;


contract ERC20Interface {
    function name() public view returns(bytes32);
    function symbol() public view returns(bytes32);
    function balanceOf (address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract AppCoins is ERC20Interface{
    // Public variables of the token
    address public owner;
    bytes32 private token_name;
    bytes32 private token_symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        owner = msg.sender;
        token_name = "AppCoins";
        token_symbol = "APPC";
        uint256 _totalSupply = 1000000;
        totalSupply = _totalSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[owner] = totalSupply;                // Give the creator all initial tokens
    }

    function name() public view returns(bytes32) {
        return token_name;
    }

    function symbol() public view returns(bytes32) {
        return token_symbol;
    }

    function balanceOf (address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    function transfer (address _to, uint256 _amount) public returns (bool success) {
        if( balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (uint) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return allowance[_from][msg.sender];
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


contract AppCoinsTimelock {

    // AppCoins token
    AppCoins private appc;

    // beneficiary of tokens
    mapping (address => uint) balances;

    // timestamp when token release is enabled
    uint private releaseTime;

    event NewFundsAllocated(address _address,  uint _amount);
    event FundsReleased(address _address,  uint _amount);

    constructor(
        address _addrAppc,
        uint256 _releaseTime
    )
    public
    {
        appc = AppCoins(_addrAppc);
        releaseTime = _releaseTime;
    }

    function getReleaseTime() public view returns(uint256) {
        return releaseTime;
    }

    function getBalanceOf(address _address) public view returns(uint256){
        return balances[_address];
    }

    function allocateFunds(address _address, uint256 _amount) public {
        require(appc.allowance(msg.sender, address(this)) >= _amount);
        appc.transferFrom(msg.sender, address(this), _amount);
        balances[_address] = balances[_address] + _amount;
        emit NewFundsAllocated(_address, balances[_address]);
    }

    function allocateFundsBulk(address[] _addresses, uint256[] _amounts) public {
        require(_addresses.length == _amounts.length);
        for(uint i = 0; i < _addresses.length; i++){
            allocateFunds(_addresses[i], _amounts[i]);
        }
    }

    function release(address _address) public {
        require(balances[_address] > 0);
        uint nowInMilliseconds = block.timestamp * 1000;
        require(nowInMilliseconds >= releaseTime);
        uint amount = balances[_address];
        balances[_address] = 0;
        appc.transfer(_address, amount);
        emit FundsReleased(_address, amount);
    }
}