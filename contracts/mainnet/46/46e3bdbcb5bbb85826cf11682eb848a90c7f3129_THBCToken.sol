/**
  * SafeMath Libary
  */
pragma solidity ^0.4.21;
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract EIP20Interface {
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
    function approve(address _spender, uint256 _value) public returns(bool success);

    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,uint256 _value);
}


contract THBCToken is EIP20Interface,Ownable,SafeMath{
    //// Constant token specific fields
    string public constant name ="THBCToken";
    string public constant symbol = "THBC";
    uint8 public constant decimals = 18;
    string  public version  = &#39;v0.1&#39;;
    uint256 public constant initialSupply = 20000000000;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    function THBCToken() public {
        totalSupply = initialSupply*10**uint256(decimals);                        //  total supply
        balances[msg.sender] = totalSupply;             // Give the creator all initial tokens
    }

    function balanceOf(address _account) public view returns (uint) {
        return balances[_account];
    }

    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
        require(_to != address(0x0)&&_value>0);
        require(balances[_from] >= _value);
        require(safeAdd(balances[_to],_value) > balances[_to]);

        uint previousBalances = safeAdd(balances[_from],balances[_to]);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        emit Transfer(_from, _to, _value);
        assert(safeAdd(balances[_from],balances[_to]) == previousBalances);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowances[_from][msg.sender]);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender],_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
 
    function() public payable {
        revert();
    }
}