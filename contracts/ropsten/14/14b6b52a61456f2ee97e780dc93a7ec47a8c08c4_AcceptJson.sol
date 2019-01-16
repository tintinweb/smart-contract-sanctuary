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
    
        
    /*
    function convertByteToStr(byte b) public view returns(string){
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
        string memory str = string(s);
        return str;
    }*/
    
    function byteToString(byte b) private returns(string){
        //uint256 number1;
        ch_uint256 = ch_uint256 + uint256(b[0])*(2**(8*(b.length-(0+1))));
        //return ch_uint256;
        
        //uint to bytes
       // bytes c;
        bytes32 b1 = bytes32(ch_uint256);
    
        c= new bytes(32);
        for(uint i=0;i<32;i++){
            c[i]=b1[i];
        }
        //return c; //return type bytes
    
        //convert bytes32 to string
        string memory str1 = string(c); //bytes to string
        x= stringToBytes32(str1);   // string to byte32
        
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    
    
    function stringToBytes32(string memory source) private returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    
     function showPhaseCount() public view returns(uint){
        // string memory name = phases[index].Name;
         //string memory date = phases[index].StartDate;
         return no_of_phases;
     }
     
     function showPhaseInfo(uint index) public view returns(string, string){
         return (phases[index].Name, phases[index].StartDate);
     }
}