pragma solidity ^0.4.17;

contract AcceptJson{
    
    struct Phase{
        string Name;
        string StartDate;
    }
    Phase[] public phases;
    uint no_of_phases;
    
    //some variable initialize
    uint256 ch_uint256;
    bytes c;
    bytes32 x;
    
   constructor(string jsonData, uint phaseCount) public{
        
        bytes memory b = bytes(jsonData);
        uint index_json=0;
        no_of_phases = phaseCount;
        
        //begin storing data of each phase
        for(uint phaseIndex=0; phaseIndex<phaseCount; phaseIndex++){
            
            //initialize fields for phase
            string memory pName = "";
            string memory pStartDate = "";
            
            //read name field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                if(b[index_json]==0x7b)  // ignore {
                    index_json++;
                    
                //pName = pName + b[index_json];
                string memory ch1 = byteToString(b[index_json]);
                pName = string(abi.encodePacked(pName, ch1));    //concat both strings, efficiently in low gas
            }
            
            //read StartDate field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                    
                //StartDate = StartDate + b[index_json];
                string memory ch2 = byteToString(b[index_json]);
                pStartDate = string(abi.encodePacked(pStartDate, ch2));    //concat both strings, efficiently in low gas
            }
            
            Phase memory thisPhase = Phase(pName, pStartDate);
            phases.push(thisPhase);
            
            //ignore } and ,
            index_json +=2;
        }
        
    }
    
        
    function byteToString(byte b) private returns(string){
        
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
        
    }
   
    
     function showPhaseCount() public view returns(uint){
        // string memory name = phases[index].Name;
         //string memory date = phases[index].StartDate;
         return no_of_phases;
     }
     
     function showPhaseInfo(uint phaseNumber) public view returns(string, string){
         return (phases[phaseNumber].Name, phases[phaseNumber].StartDate);
     }
}