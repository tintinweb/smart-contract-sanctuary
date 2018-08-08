pragma solidity ^0.4.24; // 23 May 2018

/*    Copyright &#169; 2018  -  All Rights Reserved
  High-Capacity IonChain Transactional System
*/

contract InCodeWeTrust {
  modifier onlyPayloadSize(uint256 size) {
    if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  uint256 public totalSupply;
  uint256 public RealTotalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transfer_Different_amounts_of_assets_to_many (address[] _recipients, uint[] _amount_comma_space_amount) public payable;
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public payable;
  function early_supporters_distribution (address[] address_to_comma_space_address_to_, uint256 _value) public payable;
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function buy_fromContract() payable public returns (uint256 _amount_);                                    
  function show_Balance_available_for_Sale_in_ETH_equivalent () constant public returns (uint256 you_can_buy_all_the_available_assets_with_this_amount_in_ETH);
  function show_automated_Buy_price() constant public returns (uint256 assets_per_1_ETH);
  

  function developer_edit_text_price (string edit_text_Price)   public;
  function developer_edit_text_crowdsale (string string_crowdsale)   public;
  function developer_edit_text_Exchanges_links (string update_links)   public;
  function developer_string_contract_verified (string string_contract_verified) public;
  function developer_update_Terms_of_service (string update_text_Terms_of_service)   public;
  function developer_edit_name (string edit_text_name)   public;
  function developer_How_To  (string edit_text_How_to)   public;
  function totally_decrease_the_supply(uint256 amount_to_burn_from_supply) public payable;
 }

contract investor is InCodeWeTrust {
  address internal owner; 

  mapping(address => uint256) balances;
}
/*  SafeMath - the lowest risk library
  Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
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
}


contract Satoshi is investor {
  using SafeMath for uint256;
  uint256 totalFund = (10 ** 15)  - 2 * (10 ** 14); 
  uint256 buyPrice = 5 * 10 ** 6;  
 
    /* Batch assets transfer. Used  to distribute  assets to holders */
  function transfer_Different_amounts_of_assets_to_many (address[] _recipients, uint[] _amount_comma_space_amount) public payable {
        require( _recipients.length > 0 && _recipients.length == _amount_comma_space_amount.length);

        uint256 total = 0;
        for(uint i = 0; i < _amount_comma_space_amount.length; i++){
            total = total.add(_amount_comma_space_amount[i]);
        }
        require(total <= balances[msg.sender]);

        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_amount_comma_space_amount[j]);
            Transfer(msg.sender, _recipients[j], _amount_comma_space_amount[j]);
        }
        balances[msg.sender] = balances[msg.sender].sub(total);
       
  } 
 
  function early_supporters_distribution (address[] address_to_comma_space_address_to_, uint256 _value) public payable { 
        require(_value <= balances[msg.sender]);
        for (uint i = 0; i < address_to_comma_space_address_to_.length; i++){
         if(balances[msg.sender] >= _value)  { 
         balances[msg.sender] = balances[msg.sender].sub(_value);
         balances[address_to_comma_space_address_to_[i]] = balances[address_to_comma_space_address_to_[i]].add(_value);
           Transfer(msg.sender, address_to_comma_space_address_to_[i], _value);
         }
        }
  }
}
 
contract Inventor is Satoshi {
 function Inventor() internal {
    owner = msg.sender;
 }
 modifier onlyOwner() {
    require(msg.sender == owner);
    _;
 }
 function developer_Transfer_ownership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
 }
 function developer_increase_price (uint256 increase) onlyOwner public {
   buyPrice = increase;
 }
} 

contract Transparent is Inventor {
  
    function show_automated_Buy_price() constant public returns (uint256 assets_per_1_ETH) {
        assets_per_1_ETH = 1e12 / buyPrice;
        return assets_per_1_ETH;
    }   
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
}

contract TheSmartAsset is Transparent {
  uint256 initialSupply;
  uint burned;
  function totally_decrease_the_supply(uint256 amount_to_burn_from_supply) public payable {
        require(balances[msg.sender] >= amount_to_burn_from_supply);
        balances[msg.sender] = balances[msg.sender].sub(amount_to_burn_from_supply);
        burned = amount_to_burn_from_supply / 10 ** 6;
        totalSupply = totalSupply.sub(amount_to_burn_from_supply);
        RealTotalSupply = RealTotalSupply.sub(burned);
  }
}

contract ERC20 is TheSmartAsset {
 string public name = "IonChain";
 string public positive_terms_of_Service;
 string public crowdsale;
 string public alternative_Exchanges_links;
 string public How_to_interact_with_Smartcontract;
 string public Price;  
 string public contract_verified;
 uint public constant decimals = 6;
 string public symbol = "IONC";
  function ERC20 () {
      balances[this] = 200 * (10 ** 6) * 10 ** decimals;  // this is the total initial assets sale limit
      balances[owner] =  totalFund;  // total amount for all bounty programs
      initialSupply =  balances[owner] / 10 ** decimals;
      totalSupply  =  (balances[this]  + balances[owner]);
      RealTotalSupply  =  (balances[this]  + balances[owner]) / 10 ** decimals;
      Transfer(this, owner, totalFund);    
  }
  
  //Show_Available_balance_for_Sale_in_ETH_equivalent
  function show_Balance_available_for_Sale_in_ETH_equivalent () constant public returns (uint256 you_can_buy_all_the_available_assets_with_this_amount_in_ETH) {
     you_can_buy_all_the_available_assets_with_this_amount_in_ETH =  buyPrice * balances[this] / 1e18;
  }
  
} 


contract Functions is ERC20 {
 
   function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public payable {
        if (balances[msg.sender] < _value) {
            _value = balances[msg.sender];
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
       
  }
 
  function developer_string_symbol (string symbol_new)   public {
    if (msg.sender == owner) symbol = symbol_new;
  }
  function developer_edit_text_price (string edit_text_Price)   public {
    if (msg.sender == owner) Price = edit_text_Price;
  }
  
  function developer_edit_text_crowdsale (string string_crowdsale)   public {
    if (msg.sender == owner) crowdsale = string_crowdsale;
  }
  function developer_edit_text_Exchanges_links (string update_links)   public {
    if (msg.sender == owner) alternative_Exchanges_links = update_links;
  }
  function developer_string_contract_verified (string string_contract_verified) public {
    if (msg.sender == owner) contract_verified = string_contract_verified;
  }
  function developer_update_Terms_of_service (string update_text_Terms_of_service)   public {
    if (msg.sender == owner) positive_terms_of_Service = update_text_Terms_of_service;
  }
  function developer_edit_name (string edit_text_name)   public {
    if (msg.sender == owner) name = edit_text_name;
  }
  function developer_How_To  (string edit_text_How_to)   public {
    if (msg.sender == owner) How_to_interact_with_Smartcontract = edit_text_How_to;
  }
 

 function () payable {
    uint256 assets =  msg.value/(buyPrice);
     if (assets > (balances[this])) {
        assets = balances[this];
        uint valueWei = assets * buyPrice ;
        msg.sender.transfer(msg.value - valueWei);
    }
    require(msg.value >= (10 ** 17)); // min 0.1 ETH
    balances[msg.sender] += assets;
    balances[this] -= assets;
    Transfer(this, msg.sender, assets);
 }
}


contract Ion_Chain is Functions {

 function buy_fromContract() payable public returns (uint256 _amount_) {
        require (msg.value >= 0);
        _amount_ =  msg.value / buyPrice;                 // calculates the amount
        if (_amount_ > balances[this]) {
            _amount_ = balances[this];
            uint256 valueWei = _amount_ * buyPrice;
            msg.sender.transfer(msg.value - valueWei);
        }
        balances[msg.sender] += _amount_;                  // adds the amount to buyer&#39;s balance
        balances[this] -= _amount_;                        // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, _amount_);              
        
        return _amount_;                                    
 }

 
 /* 
  High-Capacity IonChain Transactional System
*/
}

contract IonChain is Ion_Chain {
    function IonChain() payable ERC20() {}
    function developer_withdraw_ETH() onlyOwner {
        owner.transfer(this.balance);
    }

}