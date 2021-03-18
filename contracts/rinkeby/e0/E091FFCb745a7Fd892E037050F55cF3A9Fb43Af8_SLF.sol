/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface SLC_CONTRACT{
     function InitiateTransaction(uint256,string memory) external returns(bool);
     function  _owners(address) external returns(bool);
}


contract SLF{
    
    /*Structure to store Property Details*/
    struct PROPERTY_DETAILS  {
        uint origValue;
        uint currValue;
        uint coins_issued;
        uint equity_at_issuance;
        uint Total_Current_Value;
        uint Varriation;
        uint Current_Coin_Value;
        uint Original_Issuance_Rate;
        uint Next_Schedule_Revaluation;
    }
    
    /*Address of SLF contract deployer*/
    address CONTRACT_OWNER;
    
    /*Deployed Address of SLC contract*/
    address SLC_DEPLOYED_ADDRESS;
    
    /*To store property info according to minted NFT TOKEN_ID*/
    mapping(string => PROPERTY_DETAILS) public PROP_INFO;
    
    event PROPERTY_TOKENS_MINTED(string ID);
    
    constructor() public{
        CONTRACT_OWNER = msg.sender;
    }
    
    /*To check whether a function is call by contract owner or not*/
    modifier onlyOwner{
        require(msg.sender == CONTRACT_OWNER,"caller is not contract owner");
        _;
    }
    
    /*To check whether caller is an Admin or not*/
    modifier onlyMinter{
        require(SLC_CONTRACT(SLC_DEPLOYED_ADDRESS)._owners(msg.sender),"INVALID MINTER!!");
        _;
    }
    
    /*To store SLC contract deployed Address in SLC_DEPLOYED_ADDRESS*/
    function SET_SLC_DEPLOYED_ADDRESS(address SLC_CONTRACT_DEPLOYED_ADDRESS) public onlyOwner returns(bool){
        SLC_DEPLOYED_ADDRESS = SLC_CONTRACT_DEPLOYED_ADDRESS;
        return true;
    }
    
    /*Only an Admin can call this function to List property details to mint tokens*/
    function ListProperty_details(uint _origValue,
                                  uint _currValue,
                                  uint _coins_issued,
                                  uint _equity_at_issuance,
                                  uint _varriation,
                                  uint _current_coin_value,
                                  uint _orig_issue_rate,
                                  uint _next_schedule_reevaluation,
                                  string memory token_uri,
                                  string memory propertyID) public onlyMinter returns(bool){
        
        bool SUCCESS = SLC_CONTRACT(SLC_DEPLOYED_ADDRESS).InitiateTransaction(_origValue,token_uri);
        require(SUCCESS,"TOKENS NOT MINTED");
        PROPERTY_DETAILS memory info = PROPERTY_DETAILS({
        origValue:_origValue,
        currValue:_currValue,
        coins_issued:_coins_issued,
        equity_at_issuance:_equity_at_issuance,
        Total_Current_Value:_currValue,
        Varriation:_varriation,
        Current_Coin_Value:_current_coin_value,
        Original_Issuance_Rate:_orig_issue_rate,
        Next_Schedule_Revaluation:_next_schedule_reevaluation
        });
        PROP_INFO[propertyID] = info;
        emit PROPERTY_TOKENS_MINTED(propertyID);
        return true;
    } 
}