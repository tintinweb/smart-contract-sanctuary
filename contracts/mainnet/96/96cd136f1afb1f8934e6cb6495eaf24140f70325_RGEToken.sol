contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
contract RGEToken is EIP20 {
    
    /* ERC20 */
    string public name = &#39;Rouge&#39;;
    string public symbol = &#39;RGE&#39;;
    uint8 public decimals = 6;
    
    /* RGEToken */
    address owner; 
    address public crowdsale;
    uint public endTGE;
    string public version = &#39;v1&#39;;
    uint256 public totalSupply = 1000000000 * 10**uint(decimals);
    uint256 public   reserveY1 =  300000000 * 10**uint(decimals);
    uint256 public   reserveY2 =  200000000 * 10**uint(decimals);

    modifier onlyBy(address _address) {
        require(msg.sender == _address);
        _;
    }
    
    constructor(uint _endTGE) EIP20 (totalSupply, name, decimals, symbol) public {
        owner = msg.sender;
        endTGE = _endTGE;
        crowdsale = address(0);
        balances[owner] = 0;
        balances[crowdsale] = totalSupply;
    }
    
    function startCrowdsaleY0(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(now < endTGE);
        crowdsale = _crowdsale;
        balances[crowdsale] = totalSupply - reserveY1 - reserveY2;
        balances[address(0)] -= balances[crowdsale];
        emit Transfer(address(0), crowdsale, balances[crowdsale]);
    }

    function startCrowdsaleY1(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(reserveY1 > 0);
        require(now >= endTGE + 31536000); /* Y+1 crowdsale can only start after a year */
        crowdsale = _crowdsale;
        balances[crowdsale] = reserveY1;
        balances[address(0)] -= reserveY1;
        emit Transfer(address(0), crowdsale, reserveY1);
        reserveY1 = 0;
    }

    function startCrowdsaleY2(address _crowdsale) onlyBy(owner) public {
        require(_crowdsale != address(0));
        require(crowdsale == address(0));
        require(reserveY2 > 0);
        require(now >= endTGE + 63072000); /* Y+2 crowdsale can only start after 2 years */
        crowdsale = _crowdsale;
        balances[crowdsale] = reserveY2;
        balances[address(0)] -= reserveY2;
        emit Transfer(address(0), crowdsale, reserveY2);
        reserveY2 = 0;
    }

    // in practice later than end of TGE to let people withdraw
    function endCrowdsale() onlyBy(owner) public {
        require(crowdsale != address(0));
        require(now > endTGE);
        reserveY2 += balances[crowdsale];
        emit Transfer(crowdsale, address(0), balances[crowdsale]);
        balances[address(0)] += balances[crowdsale];
        balances[crowdsale] = 0;
        crowdsale = address(0);
    }

    /* coupon campaign factory */

    address public factory;

    function setFactory(address _factory) onlyBy(owner) public {
        factory = _factory;
    }

    function newCampaign(uint32 _issuance, uint256 _value) public {
        transfer(factory,_value);
        require(factory.call(bytes4(keccak256("createCampaign(address,uint32,uint256)")),msg.sender,_issuance,_value));
    }

    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
        emit Burn(msg.sender, _value);
        return true;
    }

}