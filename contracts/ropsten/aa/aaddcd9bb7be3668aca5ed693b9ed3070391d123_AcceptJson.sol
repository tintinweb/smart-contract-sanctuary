pragma solidity ^0.4.17;

contract AcceptJson{
    
    struct Phase{
        string Name;
        string StartDate;
    }
    Phase[] phases;
    
   constructor(string jsonData, uint phaseCount) public{
        
        bytes memory b = bytes(jsonData);
        uint index_json=0;
        
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
                string memory ch1 = convertByteToStr(b[index_json]);
                pName = string(abi.encodePacked(pName, ch1));    //concat both strings, efficiently in low gas
            }
            
            //read StartDate field
            for(index_json+=1; b[index_json]!=0x2c && b[index_json]!=0x7d; index_json++){
                    
                //StartDate = StartDate + b[index_json];
                string memory ch2 = convertByteToStr(b[index_json]);
                pStartDate = string(abi.encodePacked(pStartDate, ch2));    //concat both strings, efficiently in low gas
            }
            
            Phase memory thisPhase = Phase(pName, pStartDate);
            phases.push(thisPhase);
            
            //ignore } and ,
            index_json +=2;
        }
        
    }
    
        
    
    function convertByteToStr(byte b) public pure returns(string str){
        uint256 number1;
        number1 = number1 + uint256(b[0])*(2**(8*(b.length-(0+1))));
       
        uint number = number1;
       
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (number != 0) {
            uint remainder = number % 10;
            number = number / 10;
            reversed[i++] = byte(48 + remainder);
        }
        
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        str = string(s);
    }
    
    
     function showPhaseInfo(uint index) public view returns(string, string){
         string memory name = phases[index].Name;
         string memory date = phases[index].StartDate;
         return (name, date);
     }
}