/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.5.0;



contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() public view returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
contract EtherSwap is SafeMath{
    string public name="EtherSwap Instant Exchange";
    Token public token;
    Token public token1;
    uint public rate=100;

    event TokensPurchased(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokensSold(
        address account,
        address token1,
        uint amount,
        uint rate
    );

    constructor(Token _token, Token token_) public {
        token = _token
        ;
        token1 = token_;
    }

    function buyTokens(uint amount_) public {
        // Calculate the number of tokens to buy
        uint tokenAmount = amount_ * rate;
        token1.transfer(msg.sender,tokenAmount);

      // Require that EthSwap has enough tokens
      require(token1.balanceOf(address(this)) >= tokenAmount);

        //Emit an event
        // emit TokensPurchased(msg.sender,address(token),tokenAmount, rate);
    }

function sellTokens (uint _amount) public{

//User can't sell more tokens than they have

require(token.balanceOf(msg.sender) >= _amount);

//calculate the amount of ether to redeem

uint etherAmount = _amount/rate;


//Require that EtherSwap has enough Ether

require(token1.balanceOf(address(this)) >= etherAmount);

//Perform sale
token1.transferFrom(msg.sender,address(this), etherAmount);
// msg.sender.transfer(etherAmount);

//emit an event

// emit TokensSold(msg.sender,address(token1),_amount,rate);

}
}