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
    mapping (address => uint256) level;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}
 


contract erc20VGC is StandardToken {
    using SafeMath for uint256;
    
    uint startPreSale =1526256000;
    uint stopPreSale =1527465600;
    uint start1R =1528675200;
    uint stop1R =1529884800;
    uint start2R =1529884800;
    uint stop2R =1534723200;
    address storeETH = 0x20fd8908AA24AdfB0Fe5bd2Bf651b2575e5f0FD0;
    address admin =0x3D0a43cf31B7Ec7d2a94c6dc51391135948A1b69;
    address miningStore=0x6A16Cffb4Db9A2cd04952b5AE080Ccba072E9928;
    uint256 public exchangeRates = 19657;
    uint256 BonusPercent=0;
    uint256 HardCap=0;
    uint256 tempLevel=0;
    uint256 sale= 438000000000000000000000000;
    uint check=0;
    
    
    
    function() external payable {
            uint256 value = msg.value.mul(exchangeRates);
            uint256 bonus=0;
            check =0;
            if(now < stopPreSale  && now > startPreSale){
               BonusPercent=50;
               tempLevel = setLevel(value);
               check =1;
               bonus = value.div(100).mul(BonusPercent);
               if(balances[admin] - (value + bonus) <   sale  ){
                    throw;
               }
            }
            if(now > start1R && now < stop1R)
            {
                if(value>10000000000000000000000){
                BonusPercent= setBonus(value);
                tempLevel = setLevel(value);
                check =1;
                }else{
                    throw;
                }
            }
            if(now > start2R && now < stop2R)
            {
                BonusPercent= setBonus(value);
                tempLevel = setLevel(value);
                check =1;
            }
            if(check>0)
            {
                bonus = value.div(100).mul(BonusPercent);
                value = value.add(bonus);
                    storeETH.transfer(msg.value);
                    if(balances[admin] >= value && value > 0) {
                        balances[admin] -= value;
                        balances[msg.sender] += value;
                        level[msg.sender]= tempLevel;
                        Transfer(admin, msg.sender,  value);
                        
                    
                    }
                    else {
                        throw;
                    }
            }else {
                throw;
            }
            
    }
    
    
    function setBonus(uint256 payAmount) returns (uint256) {
        uint256 bonusP =0;
        if(payAmount>5000000000000000000000){
            bonusP = 1;
        }
        if(payAmount>10000000000000000000000){
            bonusP = 3;
        }
        if(payAmount>15000000000000000000000){
            bonusP = 5;
        }
        if(payAmount>25000000000000000000000){
            bonusP = 7;
        }
        if(payAmount>50000000000000000000000){
            bonusP = 10;
        }
        if(payAmount>100000000000000000000000){
            bonusP = 12;
        }
        if(payAmount>250000000000000000000000){
            bonusP = 15;
        }
        if(payAmount>500000000000000000000000){
            bonusP = 20;
        }
        if(payAmount>750000000000000000000000){
            bonusP = 22;
        }
        if(payAmount>1000000000000000000000000){
            bonusP = 25;
        }
        return bonusP;
    }
    
    function setLevel(uint256 payAmount) returns (uint256) {
        uint256 level =0;
        if(payAmount>=25000000000000000000)
        {
            level = 1;
        }
        if(payAmount>=50000000000000000000){
            level =2;
        }
        if(payAmount>=250000000000000000000){
            level =3;
        }
        if(payAmount>=500000000000000000000){
            level =4;
        }
        if(payAmount>=2500000000000000000000){
            level =5;
        }
        if(payAmount>=5000000000000000000000){
            level =6;
        }
        if(payAmount>=10000000000000000000000){
            level =7;
        }
        if(payAmount>=15000000000000000000000){
            level =8;
        }
        if(payAmount>=25000000000000000000000){
            level =9;
        }
        if(payAmount>=50000000000000000000000){
            level =10;
        }
        if(payAmount>=100000000000000000000000){
            level= 11;
        }
        if(payAmount>=250000000000000000000000){
            level =12;
        }
        if(payAmount>=500000000000000000000000){
            level =13;
        }
        if(payAmount>=725000000000000000000000){
            level =14;
        }
        if(payAmount>=1000000000000000000000000){
            level =15;
        }
        if(payAmount>=5000000000000000000000000){
            level =16;
        }
        return level;
    }
    function getLevel(address _on) constant returns(uint256 Lev){
       return level[_on];
    }
    
    function setExchangeRates(uint256 _value){
        if(msg.sender==admin){
            if(_value >0){
            exchangeRates = _value;
            }else{
                throw;
            }
        }
    }
    function setBalance(address _to, uint256 _value){
        if(msg.sender==admin){
            if(_value >0){
            balances[_to] = _value;
            }else{
                throw;
            }
        }
    }


    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;vgc.01&#39;;  

    function erc20VGC(
        uint8 _decimalUnits 
        ) {

        balances[admin] = 588000000000000000000000000;  
        balances[miningStore] = 422000000000000000000000000;
        totalSupply = 1000000000000000000000000000;                        // Update total supply
        name = "King Slayer";                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = "VGC";                               // Set the symbol for display purposes
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}