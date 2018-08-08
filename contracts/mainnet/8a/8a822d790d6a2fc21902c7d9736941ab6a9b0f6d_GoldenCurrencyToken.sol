/*
1. All rights to the smart contract, the PGCT tokens and the receipts are owned by the Golden Currency Group. 

2. The PGCT token is a transitional token of the crowdfunding campaign. 
Token is not a security and does not provide any profit payment for its owners or any rights similar to shareholders rights. 
The PGCT Token is to be exchanged for the future Golden Currency token, 
which will be released as part of the main round of the ICO campaign. 
Future Golden Currency token is planned to become a security token, providing additional incentives for project contributors (like dividends and buyback), 
yet it will be realized only in case all legal procedures are fulfilled, 
Golden Currency Group does not ensure it becoming a security token and disclaims all liability relating thereto. 

3. The PGCT-future Golden Currency token exchange procedure will include the mandatory KYC process, 
the exchange will be refused for those who do not pass the KYC procedure. 
The exchange will be refused for residents of countries who are legally prohibited from participating in such crowdfunding campaigns.
*/

pragma solidity ^0.4.21;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
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
 

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => bool   ) isInvestor;
  address[] public arrInvestors;
  
  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function addInvestor(address _newInvestor) internal {
    if (!isInvestor[_newInvestor]){
       isInvestor[_newInvestor] = true;
       arrInvestors.push(_newInvestor);
    }  
      
  }
    function getInvestorsCount() public view returns(uint256) {
        return arrInvestors.length;
        
    }

/*
minimun one token to transfer
or only all rest
*/
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (balances[msg.sender] >= 1 ether){
        require(_value >= 1 ether);     // minimun one token to transfer
    } else {
        require(_value == balances[msg.sender]); //only all rest
    }
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    addInvestor(_to);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


    function transferToken(address _to, uint256 _value) public returns (bool) {
        return transfer(_to, _value.mul(1 ether));
    }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


contract GoldenCurrencyToken is BurnableToken {
  string public constant name = "Pre-ICO Golden Currency Token";
  string public constant symbol = "PGCT";
  uint32 public constant decimals = 18;
  uint256 public INITIAL_SUPPLY = 7600000 * 1 ether;

  function GoldenCurrencyToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;      
  }
}