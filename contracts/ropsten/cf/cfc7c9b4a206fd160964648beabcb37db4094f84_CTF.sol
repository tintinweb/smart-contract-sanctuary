/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity 0.5.1;
 
//
//Tarbiat_Modares_Universit CTF
//
//Made by bloodseeker
//

contract CTF{
    bytes encoded_flag_lvl1;
    bytes encoded_flag_lvl2;
    bytes encoded_flag_lvl3;
    bytes encoded_flag_lvl4;
    
    function encoder(string memory str) public returns(bytes memory) {
        
        
        bytes memory flag = bytes(str);
        for(uint i=0; i < flag.length  ; i++){
            if (i <1 ){
                encoded_flag_lvl1.push(flag[i]);
            }
            else{
                encoded_flag_lvl1.push((flag[i] ^ flag [i-1]));
            }
        }
            
        for(uint i=0; i < flag.length  ; i++){
            if (i <1 ){
                encoded_flag_lvl2.push(encoded_flag_lvl1[i]);
            }
            else{
                encoded_flag_lvl2.push((encoded_flag_lvl1[i] ^ encoded_flag_lvl1 [i-1]));
            }
        }
        
        for(uint i=0; i < flag.length  ; i++){
            
            encoded_flag_lvl3.push((encoded_flag_lvl2[i] ^ 0xff));
        }
        for(uint i=0; i < flag.length  ; i++){
        
            encoded_flag_lvl4.push(encoded_flag_lvl3[flag.length - i -1 ]);
        }
        
        return encoded_flag_lvl4;
    }
    
    
    
    function decoder() pure  public returns(string memory) {
        return "Develop it";
    }
    
    function flag() pure public returns(string memory) {
        return "bbeaf78d91cd95b89e939fffb291e8fecefa91959a91d088d0fafef1feb2ab";
    }
    
    function about() pure public returns(string memory) {
        return "Decode flag";
    }
}