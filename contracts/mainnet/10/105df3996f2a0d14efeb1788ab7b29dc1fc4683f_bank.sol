/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity >=0.5.0 <0.7.0;

contract bank {
      
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    event deployed(address owner, uint id);
    
    event userDetails (address user_address,
        uint id, 
        uint asset_value_USD,
        BankAsssetType v_asset,
        BankState v_state,
        uint cycle,         //In months
        uint rate,
        uint amount,        // this amount is in actual currency
        uint intrest,
        BankAsssetType withdrawl,
        uint withdrawState);
        
    event rates (uint rate_AGCoin,
        uint rate_ETH,
        uint rate_BTC,
        uint rate_LTC,
        uint rate_XRP,
        uint rate_USD);
        
    address public owner;
    uint public id;

    enum BankAsssetType{ 
        AGCoin, ETH, BTC, LTC, XRP, USD
    }
    enum BankState { 
        none, in_process, mature
    }
    
    struct Bank { 
        address user;
        uint id;
        uint asset_value_USD;
        BankAsssetType v_asset;
        BankState v_state;
        uint cycle;
        uint rate;
        uint amount;    // this is in actual currency
        uint intrest;
        BankAsssetType withdrawl;
        uint withdrawState;
    }
    
    mapping(uint=>Bank) public user_details;
    mapping(uint  => uint) rate;
    constructor() public {
        owner = msg.sender; 
        id=1;
        emit deployed(owner , id);
    }
    
    function setUser (uint _cycle , uint _asset_value_USD, BankAsssetType _v_asset, uint _amount) public returns(uint){
        require (_asset_value_USD >=100 , "Amount should be atleast 100 USD");
        require (_cycle >=1,"it should be for atleast 1 month");
        uint _rate = rate[uint(_v_asset)];
        //uint id = uint256(keccak256(abi.encodePacked(msg.sender,_cycle,_amount,_asset_value_USD)));
        //user_details[msg.sender].push(_asset_value_USD,_v_asset, 1,_cycle);
        user_details[id].user = msg.sender;
        user_details[id].id = id;
        user_details[id].cycle =_cycle;
        user_details[id].asset_value_USD =_asset_value_USD;
        user_details[id].v_asset=_v_asset;
        user_details[id].v_state=BankState.in_process;
        user_details[id].rate=_rate;
        user_details[id].amount=_amount;
        user_details[id].withdrawl=BankAsssetType.AGCoin;
        emit userDetails (user_details[id].user,
        user_details[id].id,
        user_details[id].asset_value_USD,
        user_details[id].v_asset,
        user_details[id].v_state,
        user_details[id].cycle,
        user_details[id].rate,
        user_details[id].amount,    // this is in actual currency
        user_details[id].intrest,
        user_details[id].withdrawl,
        user_details[id].withdrawState);
        id +=1;
   }

    //rate should be provided as int
    function setRate (uint agcoin_rate, uint eth_rate, uint btc_rate, uint ltc_rate,  uint xrp_rate, uint usd_rate) onlyOwner public{
        rate[uint(BankAsssetType.AGCoin)]=uint(agcoin_rate);
        rate[uint(BankAsssetType.ETH)]=uint(eth_rate);
        rate[uint(BankAsssetType.BTC)]=uint(btc_rate);
        rate[uint(BankAsssetType.LTC)]=uint(ltc_rate);
        rate[uint(BankAsssetType.XRP)]=uint(xrp_rate);
        rate[uint(BankAsssetType.USD)]=uint(usd_rate);
        emit rates (rate[uint(BankAsssetType.AGCoin)],
        rate[uint(BankAsssetType.ETH)],
        rate[uint(BankAsssetType.BTC)],
        rate[uint(BankAsssetType.LTC)],
        rate[uint(BankAsssetType.XRP)],
        rate[uint(BankAsssetType.USD)]);
    }
    
    function withdraw(uint _id, BankAsssetType withdrawAsset) onlyOwner public{
        uint _rate = user_details[_id].rate;
        user_details[_id].intrest = _rate*user_details[_id].cycle*user_details[_id].amount/(100*12);
        user_details[_id].v_state = BankState.mature;
        user_details[_id].withdrawl = withdrawAsset;
        user_details[_id].withdrawState = 1;
        emit userDetails (user_details[_id].user,
        user_details[_id].id,
        user_details[_id].asset_value_USD,
        user_details[_id].v_asset,
        user_details[_id].v_state,
        user_details[_id].cycle,
        user_details[_id].rate,
        user_details[_id].amount,   // this is in actual currency
        user_details[_id].intrest,
        user_details[_id].withdrawl,
        user_details[_id].withdrawState);
    }

    function cal_intrest(uint _id) onlyOwner public {
        uint _rate = user_details[_id].rate;
        user_details[_id].intrest = _rate*user_details[_id].cycle*user_details[_id].amount/(100*12);
        emit userDetails (user_details[_id].user,
        user_details[_id].id,
        user_details[_id].asset_value_USD,
        user_details[_id].v_asset,
        user_details[_id].v_state,
        user_details[_id].cycle,
        user_details[_id].rate,
        user_details[_id].amount,       // this is in actual currency
        user_details[_id].intrest,
        user_details[_id].withdrawl,
        user_details[_id].withdrawState);
    }
}