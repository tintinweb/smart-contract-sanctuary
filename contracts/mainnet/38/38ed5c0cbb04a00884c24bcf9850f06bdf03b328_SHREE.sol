/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.4.20;

library SafeMath { 
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

contract SHREE {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address owner ;

    using SafeMath for uint256;
    
    mapping (address => uint256) public balanceOf;  // array with all balances
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    uint256 initialSupply = 5000000000000;
    string tokenName = 'SHREE';
    string tokenSymbol = 'INRT';
    
     constructor() public {
        owner = 0xe5F476Def377bb655939C4c098902C46444a47C8 ;
        totalSupply = initialSupply * 10 ** uint256(decimals);  //As solidity doesn't support decimals thus - Update total supply with the decimal amount
        balanceOf[owner] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }
    
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent accidentally transfer to 0x0 address. Use burn() instead
        require(_to != address(0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     function burn (uint numTokens) public onlyOwner  returns (bool) {
        require(numTokens <= balanceOf[msg.sender]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(numTokens);
        balanceOf[address(0)] = balanceOf[address(0)].add(numTokens);
        emit Transfer(msg.sender, address(0), numTokens);
        return true;
    }
    
    
}