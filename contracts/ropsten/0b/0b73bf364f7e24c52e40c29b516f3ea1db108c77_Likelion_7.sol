/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

//JinAe Byeon

pragma solidity 0.8.0;

contract Likelion_7 {
    
    function result (uint a) public view returns(uint) {
        if(a>=1&&a<=3){
            return(a**2);
        }else if(a>=4 &&a<=6){
            return(a*2);
        }else if(a>=7&&a<=9){
            return(a%3);
        }else if(a==10){
            return(0);
        }
    }
    function algo() public view returns(bool,uint){
        uint k = 14;
        uint t = 15;
        uint p = 16;
        bytes32 hash = keccak256(abi.encodePacked(k,t));
        for(uint a=0; a<=50; a++){
            bytes32 search = keccak256(abi.encodePacked(p,a,hash));
            if(search == hash){
                return (true,a);
            }
        }
    }
}