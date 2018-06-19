pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}


// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
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
    //uint256 public totalSupply;
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


contract ApprovalReceiver {
    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData);
}


contract Rollback is Owned, ApprovalReceiver {

    event onSetCredit(address account , uint256 amount);
    event onReturned(address who, uint256 tokenAmount, uint256 ethAmount);


    using SafeMath for uint256;
    
    Token public token = Token(0xD850942eF8811f2A866692A623011bDE52a462C1);

    uint256 public totalSetCredit;                  //set ven that should be returned
    uint256 public totalReturnedCredit;             //returned ven  

    struct Credit {
        uint128 total;
        uint128 used;
    }

    mapping(address => Credit)  credits;           //public

    function Rollback() {
    }

    function() payable {
    }

    function withdrawETH(address _address,uint256 _amount) onlyOwner {
        require(_address != 0);
        _address.transfer(_amount);
    }

    function withdrawToken(address _address, uint256 _amount) onlyOwner {
        require(_address != 0);
        token.transfer(_address, _amount);
    }

    function setCredit(address _account, uint256 _amount) onlyOwner { 

        totalSetCredit += _amount;
        totalSetCredit -= credits[_account].total;        

        credits[_account].total = _amount.toUINT128();
        require(credits[_account].total >= credits[_account].used);
        onSetCredit(_account, _amount);
    }

    function getCredit(address _account) constant returns (uint256 total, uint256 used) {
        return (credits[_account].total, credits[_account].used);
    }    

    function receiveApproval(address _from, uint256 _value, address /*_tokenContract*/, bytes /*_extraData*/) {
        require(msg.sender == address(token));

        require(credits[_from].total >= credits[_from].used);
        uint256 remainedCredit = credits[_from].total - credits[_from].used;

        if(_value > remainedCredit)
            _value = remainedCredit;  

        uint256 balance = token.balanceOf(_from);
        if(_value > balance)
            _value = balance;

        require(_value > 0);

        require(token.transferFrom(_from, this, _value));

        uint256 ethAmount = _value / 4025;
        require(ethAmount > 0);

        credits[_from].used += _value.toUINT128();
        totalReturnedCredit +=_value;

        _from.transfer(ethAmount);
        
        onReturned(_from, _value, ethAmount);
    }
}