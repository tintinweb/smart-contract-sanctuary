contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokensНу 
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

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



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
            if (balances[msg.sender] >= _value && _value > 0) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
            return true;
        } 
        else
         { return false; }

    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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
    uint256 public totalSupply;
}
 


contract erc20GST is StandardToken {
    using SafeMath for uint256;
    
    uint startPreICO =1525338000;
    uint stopPreICO =1525942800;
    uint start1Week =1525942800;
    uint stop1Week =1527411600;
    uint start2Week =1527411600;
    uint stop2Week =1528880400;
    uint start3Week =1528880400;
    uint stop3Week =1530349200;
    address storeETH = 0xcaAc6e94dAEFC3BB81CA692a8AE9d5C73f54A024;
    address admin =0x4eebcc25cD79CDA7845B6aDD99885348bcbFd04A;
    address tokenSaleStore = 0x02d105f68AbF0Cb98416fD018a25230e80974AbF;
    address tokenPreIcoStore = 0x1714bA62AEcD1D0fdc8c3b10e1d6076A97BA4CBc;
    address tokenStore = 0x58258A4cF4514f6379D320ddC5BcB24A315df0d8;
    uint256 public exchangeRates = 19657;
    uint256 BonusPercent=0;
    address storeAddress;
    
    
    
    function() external payable {
        if(msg.value>=10000000000000000)
        {
            
            if(now < stopPreICO  && now > startPreICO){
                if(msg.value<1000000000000000000){
                     throw;
                }
                if(msg.value>1000000000000000000 && msg.value <= 10000000000000000000){
                    BonusPercent =  35;
                }
                if(msg.value>10000000000000000000 && msg.value <= 50000000000000000000){
                    BonusPercent =  40;
                }
                 if(msg.value>50000000000000000000){
                    BonusPercent = 50; 
                }
                storeAddress = tokenPreIcoStore;
            }
            if(now > start1Week && now < stop1Week)
            {
                BonusPercent = 30; 
                storeAddress = tokenSaleStore;
            }
            if(now > start2Week && now < stop2Week)
            {
                BonusPercent = 20; 
                 storeAddress = tokenSaleStore;
            }
            if(now > start3Week && now < stop3Week)
            {
                BonusPercent = 10; 
                 storeAddress = tokenSaleStore;
            }
                uint256 value = msg.value.mul(exchangeRates);
                uint256 bonus = value.div(100).mul(BonusPercent);
                value = value.add(bonus);
            if(balances[storeAddress] >= value && value > 0) {
                storeETH.transfer(msg.value);
                if(balances[storeAddress] >= value && value > 0) {
                    balances[storeAddress] -= value;
                    balances[msg.sender] += value;
                    Transfer(storeAddress, msg.sender,  value);
                }
            }
            else {
                throw;
            }
            
        }
        else {
              throw;
        }
    }
    function setExchangeRates(uint256 _value){
        if(msg.sender==admin){
            if(_value >0){
            exchangeRates = _value;
            }
        }
    }


    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;gst.01&#39;;  

    function erc20GST(
        uint8 _decimalUnits 
        ) {
        balances[tokenSaleStore] = 300000000000000000000000000;               // Give the creator all initial tokens
        balances[tokenPreIcoStore] = 25000000000000000000000000;  
        balances[tokenStore] = 175000000000000000000000000;     
        totalSupply = 500000000000000000000000000;                        // Update total supply
        name = "GAMESTARS TOKEN";                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = "GST";                               // Set the symbol for display purposes
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}