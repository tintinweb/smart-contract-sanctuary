/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity >=0.5.0 <0.7.0;

contract mortgage {
      modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    // USDValue = 1000,
    // security = 300,
    // securityAmount = 0.246,
    // securityCurrency = ETH,
    // scurityRate = 0.00082
    // lended = 700,
    // lendedCurrency = AGCoin,
    // lendedRate = 1,
   
    // event newrate(uint rate);
    
    event deployed(address owner , uint id);
    
    event userDetails1 (address user_address,
        uint id,
        uint asset_value_USD,
        AsssetType deposited_asset,
        AsssetType lend_asset,
        mortgage_state m_state,
        uint lended_value,
        uint time,
        uint rate,
        uint interestrate,
        uint max_mortgage);
        // uint security_value);
        
    event userDetails2(uint absolute_mortgage,
        uint security_rate,
        uint lended_Rate,
        // uint absolute_mortgage,
        uint mortgage_amount,
        uint deposited_value,  //initial deposited value
        AsssetType withdrawl,
        uint withdrawState,
        uint deposited_asset_rate,
        uint lended_asset_rate,
        uint interest);
        
    event userDetails3(AsssetType extra_asset,
        uint extraamount);
    
    address public owner;
    uint public id ;
    uint public rate;
    uint public interestrate;
    
    enum AsssetType{
        AGCoin, ETH, BTC, LTC, USDT
    }

    enum mortgage_state {
        none, asked, provided
    } 
    
    struct Mortgage1 { 
        address  user;
        uint id ;
        uint asset_value_USD;
        AsssetType deposited_asset;
        AsssetType lend_asset;
        mortgage_state m_state;
        uint lended_value;
        uint time;
        uint rate;
        uint interestrate;
        uint max_mortgage;
        
    }
    mapping(uint  => uint) ratess;
        
    struct Mortgage2 {
        uint absolute_mortgage;
        uint security_rate;
        uint lended_Rate;
        uint mortgage_amount;
        uint deposited_value;
        AsssetType withdrawl;
        uint withdrawState;
        uint deposited_asset_rate;
        uint lended_asset_rate;
        uint interest;
    }
    
    struct Mortgage3 {
        AsssetType extra_asset;
        uint extraamount;
    }
    
    
     event rates (uint rate_AGCoin,
        uint rate_ETH,
        uint rate_BTC,
        uint rate_LTC,
        uint rate_XRP,
        uint rate_USD);
        
     mapping(uint=>Mortgage1) public user_details1;
     mapping(uint=>Mortgage2) public user_details2;
     mapping(uint=>Mortgage3) public user_details3;

     constructor() public {
        owner = msg.sender;
        id=1;
        emit deployed(owner, id);
    }
    
    
    function setrate(uint _rate) onlyOwner public {
        rate = _rate;
        // emit newrate(rate);
    }
    
     function setinterestrate(uint _interestrate) onlyOwner public {
        interestrate = _interestrate;
        // emit newrate(rate);
    }
   
    
    function settingUser(uint asset_value_USD, AsssetType _deposited_asset, AsssetType _lend_asset, uint _time, uint _deposited_value,uint _deposited_asset_rate, uint _lended_asset_rate,uint _lended_value) public {
        require(_time>= 3 , "Mortgage should be for atleast 3 months");
        require(_deposited_value >=500, "security should be greater than 500 USD");
        uint _rate = rate;
        uint _interestrate = interestrate;
        uint calculateInterest = (asset_value_USD * _interestrate * _time)/(100 * 12);
        
        user_details1[id].user = msg.sender;
        user_details1[id].id = id;
        user_details2[id].deposited_value = _deposited_value;
        user_details1[id].lended_value = _lended_value;
        user_details1[id].asset_value_USD = asset_value_USD;
        user_details2[id].lended_asset_rate = _lended_asset_rate;
        user_details2[id].deposited_asset_rate = _deposited_asset_rate;
        user_details2[id].absolute_mortgage = _deposited_value;
        user_details1[id].lend_asset = _lend_asset;
        user_details1[id].deposited_asset = _deposited_asset;
        user_details2[id].withdrawl=AsssetType.AGCoin;
        user_details3[id].extra_asset = _deposited_asset;
        // user_details2[msg.sender][id].extraamount = extraamount;
        user_details1[id].m_state = mortgage_state.provided;
        user_details1[id].time =_time;
        user_details1[id].rate= _rate;
        user_details1[id].interestrate= _interestrate;
        user_details2[id].interest= calculateInterest;
        
        emit userDetails1(user_details1[id].user,
        user_details1[id].id,
        user_details1[id].asset_value_USD,
        user_details1[id].deposited_asset,
        user_details1[id].lend_asset,
        user_details1[id].m_state,
        user_details1[id].lended_value,
        user_details1[id].time,
        user_details1[id].rate,
        user_details1[id].interestrate,
        user_details1[id].max_mortgage);
        
        emit userDetails2(user_details2[id].absolute_mortgage,
        user_details2[id].security_rate,
        user_details2[id].lended_Rate,
        user_details2[id].mortgage_amount,
        user_details2[id].deposited_value,
        user_details2[id].withdrawl,
        user_details2[id].withdrawState,
        user_details2[id].deposited_asset_rate,
        user_details2[id].lended_asset_rate,
        user_details2[id].interest);
        
        emit userDetails3(user_details3[id].extra_asset,
        user_details3[id].extraamount);
        
        id=id+1;
    }
    
    
    function addExtra (uint _id, uint extraAmount )  public {
        // uint oldExtra = user_details2[_id].extraamount;
        uint newExtra = user_details3[_id].extraamount + extraAmount;
        user_details3[_id].extraamount = newExtra;
        
        emit userDetails1(user_details1[_id].user,
        user_details1[_id].id,
        user_details1[_id].asset_value_USD,
        user_details1[_id].deposited_asset,
        user_details1[_id].lend_asset,
        user_details1[_id].m_state,
        user_details1[_id].lended_value,
        user_details1[_id].time,
        user_details1[_id].rate,
        user_details1[_id].interestrate,
        user_details1[_id].max_mortgage);
        
        emit userDetails2(user_details2[_id].absolute_mortgage,
        user_details2[_id].security_rate,
        user_details2[_id].lended_Rate,
        user_details2[_id].mortgage_amount,
        user_details2[_id].deposited_value,
        user_details2[_id].withdrawl,
        user_details2[_id].withdrawState,
        user_details2[_id].deposited_asset_rate,
        user_details2[_id].lended_asset_rate,
        user_details2[_id].interest);
        
        emit userDetails3(user_details3[_id].extra_asset,
        user_details3[_id].extraamount);
        
    } 
    
    
    function cal_mortgage (uint _id )  public {
        if (user_details1[_id].deposited_asset == AsssetType.AGCoin ) {
            user_details1[_id].max_mortgage =  user_details2[_id].deposited_value*80/100;
        }
        else {
            user_details1[_id].max_mortgage =  (user_details2[_id].deposited_value*rate)/100;
        }
        require(user_details2[_id].mortgage_amount >= user_details1[_id].max_mortgage, "");
        
        emit userDetails1(user_details1[_id].user,
        user_details1[_id].id,
        user_details1[_id].asset_value_USD,
        user_details1[_id].deposited_asset,
        user_details1[_id].lend_asset,
        user_details1[_id].m_state,
        user_details1[_id].lended_value,
        user_details1[_id].time,
        user_details1[_id].rate,
        user_details1[_id].interestrate,
        user_details1[_id].max_mortgage);
        
        emit userDetails2(user_details2[_id].absolute_mortgage,
        user_details2[_id].security_rate,
        user_details2[_id].lended_Rate,
        user_details2[_id].mortgage_amount,
        user_details2[_id].deposited_value,
        user_details2[_id].withdrawl,
        user_details2[_id].withdrawState,
        user_details2[_id].deposited_asset_rate,
        user_details2[_id].lended_asset_rate,
        user_details2[_id].interest);
        
        emit userDetails3(user_details3[_id].extra_asset,
        user_details3[_id].extraamount);
        
    } 
    
    function withdraw(uint _id) onlyOwner public{
        user_details1[_id].m_state = mortgage_state.provided;
        user_details2[_id].withdrawState = 1;
        
        emit userDetails1(user_details1[_id].user,
        user_details1[_id].id,
        user_details1[_id].asset_value_USD,
        user_details1[_id].deposited_asset,
        user_details1[_id].lend_asset,
        user_details1[_id].m_state,
        user_details1[_id].lended_value,
        user_details1[_id].time,
        user_details1[_id].rate,
        user_details1[_id].interestrate,
        user_details1[_id].max_mortgage);
        
        emit userDetails2(user_details2[_id].absolute_mortgage,
        user_details2[_id].security_rate,
        user_details2[_id].lended_Rate,
        user_details2[_id].mortgage_amount,
        user_details2[_id].deposited_value,
        user_details2[_id].withdrawl,
        user_details2[_id].withdrawState,
        user_details2[_id].deposited_asset_rate,
        user_details2[_id].lended_asset_rate,
        user_details2[_id].interest);
        
        emit userDetails3(user_details3[_id].extra_asset,
        user_details3[_id].extraamount);
    }
}