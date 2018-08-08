pragma solidity ^0.4.11;
// Dr. Sebastian Buergel, Validity Labs AG

// from https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;


  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



// from https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/Token.sol
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
    uint256 public totalSupply;

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

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



// from https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/StandardToken.sol
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



// wraps non-ERC20-conforming fundraising contracts (aka pure IOU ICO) in a standard ERC20 contract that is immediately tradable and usable via default tools.
// this is again a pure IOU token but now having all the benefits of standard tokens.
contract ERC20nator is StandardToken, Ownable {

    address public fundraiserAddress;
    bytes public fundraiserCallData;

    uint constant issueFeePercent = 2; // fee in percent that is collected for all paid in funds

    event requestedRedeem(address indexed requestor, uint amount);
    
    event redeemed(address redeemer, uint amount);

    // fallback function invests in fundraiser
    // fee percentage is given to owner for providing this service
    // remainder is invested in fundraiser
    function() payable {
        uint issuedTokens = msg.value * (100 - issueFeePercent) / 100;

        // pay fee to owner
        if(!owner.send(msg.value - issuedTokens))
            throw;
        
        // invest remainder into fundraiser
        if(!fundraiserAddress.call.value(issuedTokens)(fundraiserCallData))
            throw;

        // issue tokens by increasing total supply and balance
        totalSupply += issuedTokens;
        balances[msg.sender] += issuedTokens;
    }

    // allow owner to set fundraiser target address
    function setFundraiserAddress(address _fundraiserAddress) onlyOwner {
        fundraiserAddress = _fundraiserAddress;
    }

    // allow owner to set call data to be sent along to fundraiser target address
    function setFundraiserCallData(string _fundraiserCallData) onlyOwner {
        fundraiserCallData = hexStrToBytes(_fundraiserCallData);
    }

    // this is just to inform the owner that a user wants to redeem some of their IOU tokens
    function requestRedeem(uint _amount) {
        requestedRedeem(msg.sender, _amount);
    }

    // this is just to inform the investor that the owner redeemed some of their IOU tokens
    function redeem(uint _amount) onlyOwner{
        redeemed(msg.sender, _amount);
    }

    // helper function to input bytes via remix
    // from https://ethereum.stackexchange.com/a/13658/16
    function hexStrToBytes(string _hexString) constant returns (bytes) {
        //Check hex string is valid
        if (bytes(_hexString)[0]!=&#39;0&#39; ||
            bytes(_hexString)[1]!=&#39;x&#39; ||
            bytes(_hexString).length%2!=0 ||
            bytes(_hexString).length<4) {
                throw;
            }

        bytes memory bytes_array = new bytes((bytes(_hexString).length-2)/2);
        uint len = bytes(_hexString).length;
        
        for (uint i=2; i<len; i+=2) {
            uint tetrad1=16;
            uint tetrad2=16;

            //left digit
            if (uint(bytes(_hexString)[i])>=48 &&uint(bytes(_hexString)[i])<=57)
                tetrad1=uint(bytes(_hexString)[i])-48;

            //right digit
            if (uint(bytes(_hexString)[i+1])>=48 &&uint(bytes(_hexString)[i+1])<=57)
                tetrad2=uint(bytes(_hexString)[i+1])-48;

            //left A->F
            if (uint(bytes(_hexString)[i])>=65 &&uint(bytes(_hexString)[i])<=70)
                tetrad1=uint(bytes(_hexString)[i])-65+10;

            //right A->F
            if (uint(bytes(_hexString)[i+1])>=65 &&uint(bytes(_hexString)[i+1])<=70)
                tetrad2=uint(bytes(_hexString)[i+1])-65+10;

            //left a->f
            if (uint(bytes(_hexString)[i])>=97 &&uint(bytes(_hexString)[i])<=102)
                tetrad1=uint(bytes(_hexString)[i])-97+10;

            //right a->f
            if (uint(bytes(_hexString)[i+1])>=97 &&uint(bytes(_hexString)[i+1])<=102)
                tetrad2=uint(bytes(_hexString)[i+1])-97+10;

            //Check all symbols are allowed
            if (tetrad1==16 || tetrad2==16)
                throw;

            bytes_array[i/2-1]=byte(16*tetrad1 + tetrad2);
        }

        return bytes_array;
    }

}