pragma solidity ^0.4.24;
/**
 * Implementation of the basic standard token
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract TokenERC20 {
    // [ERC20] the name of the token - e.g. "Vehicle Owner’s Benefit"
    string public name;
    // [ERC20] the symbol of the token. E.g. "VOB".
    string public symbol;
    // [ERC20] the total token supply
    uint256 public totalSupply;
    // [ERC20] the number of decimals the token uses - e.g. 18
    uint8 public decimals = 18;

    // [ERC20] the account balance of another account with address _owner
    mapping (address => uint256) public balanceOf;

    // [ERC20]the amount which _spender is still allowed to withdraw from _owner.
    mapping(address => mapping(address => uint256)) allowance;


    mapping (address => uint256) public freezeOf;

    // [ERC20] MUST trigger when tokens are transferred, including zero value transfers.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // [ERC20] MUST trigger on any successful call to approve
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    // This notifies clients about the amount frozen
    event Freeze(address indexed from, uint256 value);

    // This notifies clients about the amount unfrozen
    event Unfreeze(address indexed from, uint256 value);

    constructor(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimalUnits) public {
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
    }

    /**
     * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

        // the _to account address is not invalid
        require(_to != 0x0);

        // the _from account balance has enough tokens to spend
        require(balanceOf[_from] >= _value);

        // the _to account balance must not be overflowing after transfer
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // emit event
        emit Transfer(_from, _to, _value);
    }

    /**
     * [ERC20]
     * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the _from account balance does not have enough tokens to spend.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {

        _transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * [ERC20]
     * Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
     * The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
     * This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
     * The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * [ERC20]
     * Allows _spender to withdraw from your account multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     *
     * NOTE: To prevent attack vectors like the one described here and discussed here,
     * clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender.
     * THOUGH The contract itself shouldn&#39;t enforce it, to allow backwards compatibility with contracts deployed before
     *
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function freeze(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        require(_value > 0);
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        freezeOf[msg.sender] += _value;
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) returns (bool success) {
        require(freezeOf[msg.sender]>= _value);            // Check if the sender has enough
        require(_value > 0);
        freezeOf[msg.sender] -= _value;                      // Subtract from the sender
        balanceOf[msg.sender] += _value;
        Unfreeze(msg.sender, _value);
        return true;
    }



}