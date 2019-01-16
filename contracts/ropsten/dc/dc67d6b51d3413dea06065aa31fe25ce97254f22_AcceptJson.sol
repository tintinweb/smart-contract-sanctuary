pragma solidity ^0.4.17;

contract AcceptJson{
    
    //tab 1 variable initialization begins
    uint token_type;
    uint decimal_point;
    uint token_price;
    uint funding_method;
    uint total_supply;
    uint tokens_available_sale;
    uint min_cap;
    
    uint ICO_endDate = 0;
    uint ICO_endTime = 0;
    
    
    string ico_name;
    string token_name;
    string symbol;
    
    address wallet_address;
    //tab1 section end
    
    
    // tab 2 section begins
    struct Phase{
        string Name;
        string StartDate;
        string StartTime;
        uint MaxCap;
        uint BonusPercent;
        uint MinInvest;
        uint TokenLockupPeriod;
    }
    Phase[] public phases;
    uint no_of_phases;
    // tab 2 section ends
    
    bytes b;
    
    
   constructor(string jsonICOData, uint[9] tokenDetails, address Wallet, string jsonData, uint phaseCount) public{
        
        // tab 1 section
        
        //read the uint values
        token_type = tokenDetails[0];
        decimal_point = tokenDetails[1];
        token_price = tokenDetails[2];
        funding_method = tokenDetails[3];
        total_supply = tokenDetails[4];
        tokens_available_sale = tokenDetails[5];
        min_cap = tokenDetails[6];
        ICO_endDate = tokenDetails[7];
        ICO_endTime = tokenDetails[8];
        
        
        //convert json data to bytes
        b = bytes(jsonICOData);
        uint index_json1=0;
        
        //read ico_name field
        for(index_json1+=1; b[index_json1]!=0x2c && b[index_json1]!=0x7d; index_json1++){
            if(b[index_json1]==0x7b)  // ignore {
                index_json1++;
            ico_name = string(abi.encodePacked(ico_name, byteToString(b[index_json1])));    //concat both strings, efficiently in low gas
        }
        
        //read token_name field
        for(index_json1+=1; b[index_json1]!=0x2c && b[index_json1]!=0x7d; index_json1++){
            token_name = string(abi.encodePacked(token_name, byteToString(b[index_json1])));    //concat both strings, efficiently in low gas
        }
        
        //read symbol field
        for(index_json1+=1; b[index_json1]!=0x2c && b[index_json1]!=0x7d; index_json1++){
            symbol = string(abi.encodePacked(symbol, byteToString(b[index_json1])));    //concat both strings, efficiently in low gas
        }

        //wallet address
        wallet_address = Wallet;
        
        
        // tab 2 section
        b = bytes(jsonData);
        uint index_json=0;
        no_of_phases = phaseCount;
        
        //begin storing data of each phase
        for(uint phaseIndex=0; phaseIndex<phaseCount; phaseIndex++){
            
            //initialize fields for phase
            string memory pName = "";
            string memory pStartDate = "";
            string memory pStartTime = "";
            uint pMaxCap = 0;
            uint pBonusPercent = 0;
            uint pMinInvest = 0;
            uint pTokenLockupPeriod = 0;
            
            //read name field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if(b[index_json]==0x7b)  // ignore {
                    index_json++;
                pName = string(abi.encodePacked(pName, byteToString(b[index_json])));    //concat both strings, efficiently in low gas
            }
            
            //read StartDate field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                pStartDate = string(abi.encodePacked(pStartDate, byteToString(b[index_json])));    //concat both strings, efficiently in low gas
            }
            
            //read StartTime field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                pStartTime = string(abi.encodePacked(pStartTime, byteToString(b[index_json])));    //concat both strings, efficiently in low gas
            }
            
            //read MaxCap field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if (b[index_json]==0x24)
                    index_json++;   //skip $
                pMaxCap = (pMaxCap*10)+byteToUint(b[index_json]);
            }
            
            //read BonusPercent field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if (b[index_json]==0x24)
                    index_json++;   //skip $
                pBonusPercent = (pBonusPercent*10)+byteToUint(b[index_json]);
            }
            
            //read MinInvest field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if (b[index_json]==0x24)
                    index_json++;   //skip $
                pMinInvest = (pMinInvest*10)+byteToUint(b[index_json]);
            }
            
            //read TokenLockupPeriod field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if (b[index_json]==0x24)
                    index_json++;   //skip $
                pTokenLockupPeriod = (pTokenLockupPeriod*10)+byteToUint(b[index_json]);
            }
            
            Phase memory thisPhase = Phase(pName, pStartDate, pStartTime, pMaxCap, pBonusPercent, pMinInvest, pTokenLockupPeriod);
            phases.push(thisPhase);
            
            //ignore } and ,
            index_json +=2;
        }
        
    }
    
    
    //post construct, tab 1 sectiotab
    function ICO_details() public view returns(string, string, string, uint, uint, address){
        return (ico_name, token_name, symbol, ICO_endDate, ICO_endTime, wallet_address);
    }
    
    function tokenInitialDetails() public view returns(uint, uint, uint, uint, uint, uint, uint){
        return (token_type, decimal_point, token_price, funding_method, total_supply, tokens_available_sale, min_cap);
    }
    
    
    //post construct, tab 2 section
    function showPhaseCount() public view returns(uint){
         return no_of_phases;
     }
     
     function showPhaseInfo(uint phaseNumber) public view returns(string, string, string, uint, uint, uint, uint){
         return (phases[phaseNumber].Name, phases[phaseNumber].StartDate, phases[phaseNumber].StartTime, phases[phaseNumber].MaxCap, phases[phaseNumber].BonusPercent, phases[phaseNumber].MinInvest, phases[phaseNumber].TokenLockupPeriod);
     }
    
        
    function byteToString(byte b) private pure returns(string){
        
        if(b==0x61)
            return "a";
        else if(b==0x62)
            return "b";
        else if(b==0x63)
            return "c";
        else if(b==0x64)
            return "d";
        else if(b==0x65)
            return "e";
        else if(b==0x66)
            return "f";
        else if(b==0x67)
            return "g";
        else if(b==0x68)
            return "h";
        else if(b==0x69)
            return "i";
        else if(b==0x6a)
            return "j";
        else if(b==0x6b)
            return "k";
        else if(b==0x6c)
            return "l";
        else if(b==0x6d)
            return "m";
        else if(b==0x6e)
            return "n";
        else if(b==0x6f)
            return "o";
        else if(b==0x70)
            return "p";
        else if(b==0x71)
            return "q";
        else if(b==0x72)
            return "r";
        else if(b==0x73)
            return "s";
        else if(b==0x74)
            return "t";
        else if(b==0x75)
            return "u";
        else if(b==0x76)
            return "v";
        else if(b==0x77)
            return "w";
        else if(b==0x78)
            return "x";
        else if(b==0x79)
            return "y";
        else if(b==0x7a)
            return "z";
        else if(b==0x30)
            return "0";
        else if(b==0x31)
            return "1";
        else if(b==0x32)
            return "2";
        else if(b==0x33)
            return "3";
        else if(b==0x34)
            return "4";
        else if(b==0x35)
            return "5";
        else if(b==0x36)
            return "6";
        else if(b==0x37)
            return "7";
        else if(b==0x38)
            return "8";
        else if(b==0x39)
            return "9";
        else if(b==0x7b)
            return "{";
        else if(b==0x7d)
            return "}";
        else if(b==0x2c)
            return ",";
        else
            return "";      // :P cunning ri8!! 
            
    }
    
    function byteToUint(byte b) private pure returns(uint){
        if(b==0x30)
            return 0;
        else if(b==0x31)
            return 1;
        else if(b==0x32)
            return 2;
        else if(b==0x33)
            return 3;
        else if(b==0x34)
            return 4;
        else if(b==0x35)
            return 5;
        else if(b==0x36)
            return 6;
        else if(b==0x37)
            return 7;
        else if(b==0x38)
            return 8;
        else if(b==0x39)
            return 9;
        else
            return;
    }
   
}