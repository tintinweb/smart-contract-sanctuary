/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

//Jinseon Moon
pragma solidity 0.8.0;

contract Lion_10_2 {
  /*  
  
  
/////////////////VARIANT 1/////////////////////////////  
    uint[] num;
    
    function generatehNum() public {
        for(uint i = 0; i < 1000; i++){
            num.push(i);
        }
        
        
    }
    
    function matching() public view returns(bool, uint, uint, uint, uint) {
        
        bytes32 hash = keccak256(abi.encodePacked(uint(0), uint(4), uint(2), uint(9)));
        
        
        uint _num;
        uint a = 0;
        uint b = 0;
        uint c = 0;
        uint d = 0;
        
        
        for(uint i = 0; i < 1000; i++){
        _num = num[i];
        d = _num % 10;
        _num = uint(_num / 10);
        if(_num != 0){
            c = _num % 10;
            _num = uint(_num / 10);
            
            if(_num != 0){
                b = _num % 10;
                _num = uint(_num / 10);
                
                if(_num != 0){
                    a = _num % 10;   
                }
            }
        }
        
        
        bytes32 password = keccak256(abi.encodePacked(a, b, c, d));
        
        if(hash == password){
            return(true, a, b, c, d);
        }
        
        
        }
        
        return(false, 404, 404, 404, 404);
    }
    
////////////////////////////VARIANT 2 ///////////////////////////////////////////   
    
       function matching() public view returns(bool, uint, uint, uint, uint) {
        
        bytes32 hash = keccak256(abi.encodePacked(uint(0), uint(4), uint(2), uint(9)));
        
        
        for(uint a = 0; a < 10; a++){
            for(uint b = 0; b < 10; b++){
                for(uint c = 0; c < 10; c++){
                    for(uint d = 0; d < 10; d++){
                        bytes32 password = keccak256(abi.encodePacked(a, b, c, d));
                        
                        if(hash == password){
                            return(true, a, b, c, d);
                        }
                    }
                }
            }
        }
        
        
        return(false, 404, 404, 404, 404);
    
}
    
    
    
    
    */
    
        
        
    }