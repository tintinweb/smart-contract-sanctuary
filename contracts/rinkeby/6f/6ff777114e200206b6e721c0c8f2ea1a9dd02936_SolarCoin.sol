/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.4.21;

//import "./Interface.sol";

// Abstract contract for the full SolarCoin Token standard

pragma solidity ^0.4.21; 

contract Interface {
    
    //  total amount of PowerGenerated_MWatth
    uint256 public PowerGenerated_Watth;

/*  _owner is the address from which the balance will be retrieved
    "returns" returns the balance
*/  
    function balanceOf(address _owner) public view returns (uint256 balance);

/*  send "_value" token to "_to" from "msg.sender"
    _to is the address of the recipient
    _value is the amount of tokens to be transferred
    returns will return Whether the transfer was successful or not 
*/
    function transfer(address _to, uint256 _value) public returns (bool success);

/* send "_value" token to "_to" from "_from" on the condition it is approved by "_from"
    _from is the address of the sender
    _to is the address of the recipient
    _value is the amount of token to be transferred
    return Whether the transfer was successful or not
*/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

/*  "msg.sender" approves "_spender" to spend "_value" tokens
    _spender is the address of the account able to transfer the tokens
    _value is the amount of tokens to be approved for transfer
    return Whether the approval was successful or not
*/ 
    function approve(address _spender, uint256 _value) public returns (bool success);

/*  _owner is the address of the account owning tokens
    _spender is the address of the account able to transfer the tokens
    return Amount of remaining tokens allowed to spent
*/
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract SolarCoin is Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balance;
    mapping (address => mapping (address => uint256)) public allowed;
   
    string public Crypto_Currency;  // variable to store crypto Crypto_Currency type
    uint8 public decimals;           //How many decimals to show.
    string public symbol;            //An identifier: eg Ethers = ETH
    // §SLR
    
    
    function SolarCoin(
        uint256 _PowerGenerated,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balance[msg.sender] = _PowerGenerated/1000000;   // Give the creator all initial tokens
        PowerGenerated_Watth = _PowerGenerated;          // total _Power Generated on whatts
        Crypto_Currency = _tokenName;                    // name for display purposes
        decimals = _decimalUnits;                        // decimals for display purposes
        symbol = _tokenSymbol;                           // symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balance[msg.sender] >= _value);
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balance[_from] >= _value && allowance >= _value);
        balance[_to] += _value;
        balance[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balances) {
        return balance[ _owner];
    }

 /*
    what allowance and approve are doing really?
    
    Let's assume we have user A and user B. A has 1000 tokens and want to give permission to B to spend 100 of them.
    
    A will call approve(address(B), 100)
    B will check how many tokens A gave him permission to use by calling allowance(address(A), address(B))
    B will send to his account these tokens by calling transferFrom(address(A), address(B), 100)
    
*/
    

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    

}