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
    /// @param _spender The address of the account able to transfer the tokens
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
    uint256 perventValue = 1;
    using SafeMath for uint256;
    address burnaddr =0x0000000000000000000000000000000000000000;
    address tokenStore1=0xeb62d677cDFCCe9607744A1B7F63F54310b7AE4d;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    
    
    function transfer(address _to, uint256 _value) returns (bool success) {

 
            if (balances[msg.sender] >= _value && _value > 0) {
                uint256 tax =0;
                tax=_value.div(100).mul(perventValue);
                balances[msg.sender] -= _value;
                _value=_value.sub(tax);
                tax=tax.div(2);
                totalSupply=totalSupply.sub(tax);
                balances[burnaddr]+=tax;
                balances[tokenStore1]+=tax;
                balances[_to] += _value;
                emit Transfer(msg.sender, _to, _value);
                emit Transfer(msg.sender, burnaddr, tax);
                emit Transfer(msg.sender, tokenStore1, tax);
            return true;
        } 
        else
         { return false; }

    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {


        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            uint256 tax =0;
            tax=_value.div(100).mul(perventValue);
            
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            _value=_value.sub(tax);
            balances[_to] += _value;
            tax=tax.div(2);
            totalSupply=totalSupply.sub(tax);
            balances[burnaddr]+=tax;
            balances[tokenStore1]+=tax;
            emit Transfer(_from, _to, _value);
            emit Transfer(msg.sender, burnaddr, tax);
            emit Transfer(msg.sender, tokenStore1, tax);
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

    
}



contract erc20KGS is StandardToken {
    using SafeMath for uint256;
    
      string public name;                   //
    uint8 public decimals;                //
    string public symbol;                 //
    string public version = &#39;x0.01&#39;;       //
    address confAddr1=0xF5bEC430576fF1b82e44DDB5a1C93F6F9d0884f3;
    address confAddr2=0x876EabF441B2EE5B5b0554Fd502a8E0600950cFa;
    address confAddr3;
    address confAddr4=0x5Dcd3d3FA68E01FcD4B4962E1f214630D9a3755C;
    address admin1=0x51587A275254aE80980CB282EeD1e4fb668bF054;
    address admin2=0x534Bd9594A2f038eDe268f7554722d1daec0615F;
    address admin3=0xeb62d677cDFCCe9607744A1B7F63F54310b7AE4d;
    address tokenStore1=0xb97510A71C5Dc248f1B81861C23ea3F8771EDC10;
    address tokenStore2=0x745b29Bd95Bb84F5CaCD4960775B02bC02E62e76;
    address tokenStore3=0x1Cf597cc7004680E457A9B8D3c789a28632c1997;
    address tokenStore4=0x29333C31d8cbe63Dc5567609d8D81Ccc328735Ae;
    address tokenStore5=0x4d9a53B549C0c59B72C358E6C02183a2610Cf6D6;
    address tokenStore6=0xD46915F3f2E54FAeA6A7fe91f052Bc16189B0862;
    address storeETH =0x3Dd8DB94bBC30bb2CB3eA5622A65D5eE6d7ecC10;
    address burnaddr =0x0000000000000000000000000000000000000000;  
    address payAddr;
    uint public Round1Time = 1539129600;
    uint public Round2Time = 1540944000;
    uint public Round3Time = 1541894400;
    uint public Round4Time = 1542758400;
    uint public SaleStartTime = 1543622400;
    uint public SaleFinishTime = 1546300800;
    uint public BonusRound1 = 75;
    uint public BonusRound2 = 65;
    uint public BonusRound3 = 55;
    uint public BonusRound4 = 45;
    uint public BonusSale = 0; 
    uint public MinAmount1Round =49988;
    uint public MinAmount2Round =39988;
    uint public MinAmount3Round =29988;
    uint public MinAmount4Round =19988;
    uint public MinAmountSale =99;
    uint256 public ExchangeRate = 48543689320388;
    uint256 public PriceOfToken = 10;
    
    function () external payable {
        uint256 amoutD =0;
        uint256 amoutT = 0;
        amoutD=amoutD.add(msg.value.div(ExchangeRate));
        if(now < Round2Time  && now > Round1Time){
            payAddr=tokenStore1;
            amoutT=amoutT.add(amoutD.mul(PriceOfToken));
            if (amoutD>MinAmount1Round){
                amoutT=amoutT.add(amoutT.mul(BonusRound1).div(100));
                amoutT=amoutT.mul(10000000000000000);
            }
            else{
                amoutT=amoutT.mul(10000000000000000);
            }
        }else
        if(now < Round3Time  && now > Round2Time){
            payAddr=tokenStore2;
            amoutT=amoutT.add(amoutD.mul(PriceOfToken));
            if(amoutD>MinAmount2Round){
                amoutT=amoutT.add(amoutT.mul(BonusRound2).div(100));
                amoutT=amoutT.mul(10000000000000000);
            } else{
                amoutT=amoutT.mul(10000000000000000);
            }
        }else
        if(now < Round4Time  && now > Round3Time){
            payAddr=tokenStore3;
            amoutT=amoutT.add(amoutD.mul(PriceOfToken));
            if(amoutD>MinAmount3Round){
                amoutT=amoutT.add(amoutT.mul(BonusRound3).div(100));
                amoutT=amoutT.mul(10000000000000000);
            } else{
                amoutT=amoutT.mul(10000000000000000);
            }
        }else
        if(now < SaleStartTime  && now > Round4Time){
            payAddr=tokenStore4;
            amoutT=amoutT.add(amoutD.mul(PriceOfToken));
            if(amoutD>MinAmount4Round){
                amoutT=amoutT.add(amoutT.mul(BonusRound4).div(100));
                amoutT=amoutT.mul(10000000000000000);
            }  else{
                amoutT=amoutT.mul(10000000000000000);
            }
        }else
        if(now < SaleFinishTime  && now > SaleStartTime){
            payAddr=tokenStore4;
            amoutT=amoutT.add(amoutD.mul(PriceOfToken));
            if(amoutD>MinAmountSale){
                amoutT=amoutT.add(amoutT.mul(BonusSale).div(100));
                amoutT=amoutT.mul(10000000000000000);
            }
            else{
                revert();
            }
        }else{
            revert();
        }
        if(balances[payAddr] >= amoutT && amoutT > 0) {
                storeETH.transfer(msg.value);
                if(balances[payAddr] >= amoutT && amoutT > 0) {
                    if(msg.sender==confAddr1 || msg.sender == confAddr2 ){
                        balances[payAddr] -= amoutT;
                        balances[confAddr4] += amoutT;
                        emit Transfer(payAddr, confAddr4,  amoutT);
                    }else{
                    balances[payAddr] -= amoutT;
                    balances[msg.sender] += amoutT;
                    emit Transfer(payAddr, msg.sender,  amoutT);
                    }
                }
           }
            else {
               revert();
            }
    }


  
    
    
    
    

    function erc20KGS(
        uint8 _decimalUnits 
        ) {
        totalSupply = 500000000000000000000000000;                        // Update total supply
        name = "KING SLAYER TOKEN";                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = "KGS";                               // Set the symbol for display purposes
        balances[tokenStore1]= 21000000000000000000000000;
        balances[tokenStore2]= 13200000000000000000000000;
        balances[tokenStore3]= 9300000000000000000000000;
        balances[tokenStore4]= 5800000000000000000000000;
        balances[tokenStore5]= 220000000000000000000000000;
        balances[tokenStore6]= 230700000000000000000000000;
    }
    function set1RoundTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 Round1Time = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function set2RoundTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 Round2Time = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function set3RoundTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 Round3Time = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function set4RoundTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 Round4Time = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function setSaleStartTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 SaleStartTime = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function setSaleFinishTime(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >0){
                 SaleFinishTime = _timeValue;
             }
        }else{
            revert();
        }     
    }
    
    function setBonusRound1(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >=0){
                 BonusRound1 = _Value;
             }
        }else{
            revert();
        }     
    }
    function setBonusRound2(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >=0){
                 BonusRound2 = _Value;
             }
        }else{
            revert();
        }     
    }
    function setBonusRound3(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >=0){
                 BonusRound3 = _Value;
             }
        }else{
            revert();
        }     
    }
    function setBonusRound4(uint _timeValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_timeValue >=0){
                 BonusRound4 = _timeValue;
             }
        }else{
            revert();
        }     
    }
    function setBonusSale(uint256 _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >=0){
                 BonusSale = _Value;
             }
        }else{
            revert();
        }     
    }
    function setExchangeRate(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 ExchangeRate = _Value;
             }
        }else{
            revert();
        }     
    }
    function setPriceOfToken(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 PriceOfToken = _Value;
             }
        }else{
            revert();
        }     
    }
    function burn(uint256 _value, address _addrValue){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
                if(balances[_addrValue] >= _value && _value > 0) {
                    balances[_addrValue] -= _value;
                    balances[burnaddr] += _value;
                    totalSupply-=_value;
                   emit Transfer(_addrValue, burnaddr,  _value);
                }

        }else{
            revert();
        }     
    }
    function setMinAmount1Round(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 MinAmount1Round = _Value;
             }
        }else{
            revert();
        }     
    }
    function setMinAmount2Round(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 MinAmount2Round = _Value;
             }
        }else{
            revert();
        }     
    }
    function setMinAmount3Round(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 MinAmount3Round = _Value;
             }
        }else{
            revert();
        }     
    }
    function setMinAmount4Round(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 MinAmount4Round = _Value;
             }
        }else{
            revert();
        }     
    }
    function setMinAmountSale(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >0){
                 MinAmountSale = _Value;
             }
        }else{
            revert();
        }     
    }
     function setPerventValue(uint _Value){
        if(msg.sender==admin1 || msg.sender==admin2 || msg.sender==admin3){
            if(_Value >=0){
                 perventValue = _Value;
             }
        }else{
            revert();
        }     
    }



    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}