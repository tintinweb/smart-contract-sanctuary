/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;


contract HI001 {
    
    struct Worry {

        string  Title;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;

    }
    
    mapping(uint => Worry) public WORRY_AllByID;
    
    mapping(string => Worry) public WORRY_Popular;
    
    uint public TOTAL_Worries;
    
    function NEW_Worry(string memory Im_worried_about, string memory because) public {

        TOTAL_Worries++;

        Worry storage worry = WORRY_AllByID[TOTAL_Worries];
        worry.Title         = string(bytes.concat(bytes(": "), bytes(Im_worried_about)));
        worry.Description   = string(bytes.concat(bytes(": "), bytes(because)));
        worry.ID            = TOTAL_Worries;
        worry.Posted_By     = msg.sender;
        
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
        
    }
    fallback() external payable {}
    
    function FILL_Worry(string memory title, uint _ID) payable public {
        
        Worry storage worry = WORRY_AllByID[_ID];
        
        require(keccak256(abi.encodePacked(string(bytes.concat(bytes(": "), bytes(title))))) == keccak256(abi.encodePacked(worry.Title)));
        
        payable(address(this)).transfer(msg.value);
        worry.Weis = worry.Weis + msg.value;
        
        uint i;
        uint weis;
        
        for (i=1; i<=TOTAL_Worries; i++) {
            
            Worry storage _worry = WORRY_AllByID[i];
        
            require(keccak256(abi.encodePacked(_worry.Title)) == keccak256(abi.encodePacked(worry.Title)) && _worry.Weis > weis);
                
                Worry storage __worry = WORRY_Popular[title];
                __worry.Title        = _worry.Title;
                __worry.Description  = _worry.Description;
                __worry.ID           = _worry.ID;
                __worry.Posted_By    = _worry.Posted_By;
                __worry.Weis         = _worry.Weis;
                
                weis = _worry.Weis;
                    
        }
                
    }
    
    struct Advice {
        
        string  Title;
        string  Description;
        uint    ID;
        address Posted_By;
        uint    Weis;
        
    }
    
    // TESTING  -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   
    
    function balance() view public returns (uint){
        return address(this).balance;
    }
    
    function GET_ETHERS(uint amount) public {
        payable(address(msg.sender)).transfer(amount);
    }

}