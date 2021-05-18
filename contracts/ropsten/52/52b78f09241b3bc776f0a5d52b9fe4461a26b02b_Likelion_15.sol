/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//yeong hae
pragma solidity 0.8.0;

contract Likelion_15{
    uint[] number;
    uint count;
    
    function Number(uint num) public returns(string memory) {
        
        if(count <= 6){
            number.push(num);
            count ++;
            return "success";
        }
        else{
            return "error";
        }
    }
    
    function getEvenNumber() public view returns(uint){
        uint evenCount = 0;
        for(uint i = 0; i <number.length; i++){
            if(number[i] % 2 == 0){
                evenCount ++;
            }
        }
        return evenCount;
    }
}