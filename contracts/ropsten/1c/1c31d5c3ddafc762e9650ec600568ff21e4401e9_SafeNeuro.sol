/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.4.20;
// blaze it fgt ^

contract ERC20Interface {

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

contract SafeNeuro is ERC20Interface {
    
    // Standard ERC20
    string public name = "SafeNeuro";
    uint8 public decimals = 18;                
    string public symbol = "SNO";

    
    // Default balance
    uint256 public stdBalance;
    mapping (address => uint256) public bonus;
    
    // Owner
    address public owner;
    bool public JUSTed;
    
    // PSA
    event Message(string message);
    

    function SafeNeuro() public {
        owner = msg.sender;
        totalSupply = 1000000000000000 * 1e18;
        stdBalance = 1000000 * 1e18;
        JUSTed = true;

    }
    

   function transfer(address _to, uint256 _value) public returns (bool success) {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token has been deposited in your account.");
        return true;
    }
    

   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        bonus[msg.sender] = bonus[msg.sender] + 1e18;
        Message("+1 token has been deposited in your account");
        return true;
    }
    
    
    function UnNeuro(string _name, string _symbol, uint256 _stdBalance, uint256 _totalSupply, bool _JUSTed) public {
        require(owner == msg.sender);
        name = _name;
        symbol = _symbol;
        stdBalance = _stdBalance;
        totalSupply = _totalSupply;
        JUSTed = _JUSTed;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        if(JUSTed){
            if(bonus[msg.sender] > 0){
                return stdBalance + bonus[msg.sender];
            } else {
                return stdBalance;
            }
        } else {
            return 0;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return 0;
    }
    
    // in case someone accidentally sends ETH to this contract.
    function() public payable {
        owner.transfer(this.balance); 
        Message("Thanks for your donation.");
    }
    
    // in case some accidentally sends other tokens to this contract.
    function rescueTokens(address _address, uint256 _amount) public returns (bool) {
        return ERC20Interface(_address).transfer(owner, _amount);
    }
}