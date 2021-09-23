/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.6.0;



contract Payable {

    address payable public owner;
    uint Blkhour;
    uint DataHourCreate;




  
    function DaysLeft()private view returns (uint)
    {
          uint _hours = (DataHourCreate+Blkhour)-block.timestamp/60;
      
          if(_hours<=Blkhour)
          {
            return _hours;
          }
          else
          {
              return 0; 
          }
     
    }

    function uintToStr(uint value) private view returns (string memory _uintAsString) {
        if (value == 0) {
            return "0";
        }
        uint j = value;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (value != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(value - value / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            value /= 10;
        }
        return string(bstr);
    }
    
 
 
     
     function strConcat(string memory  stA, string memory stB) private view returns (string memory){
        bytes memory _ba = bytes(stA);
        bytes memory _bb = bytes(stB);
        
        uint alldata=_ba.length +  _bb.length ;
        
        string memory ret = new string(alldata) ;
        
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
    

    



   
    function GetNeckit()public view returns (string memory){
        
        string memory StrBalanse="Алексе́й Анато́льевич Нава́льный — российский оппозиционный лидер, юрист, политический и общественный деятель, получвш ий известность своими расследованиями о коррупции в России. Позиционирует себя как главного оппонента руководству России во главе с Владимиром Путиным.";
        
        
       
       
        
   
        
        
        return  StrBalanse;     
    }
    
   
    function DaysCheck() public view returns(uint){

    return DaysLeft();

    } 
    
}