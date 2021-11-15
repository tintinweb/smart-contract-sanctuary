//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
 

contract LootGenome{
     
    constructor( ) {
       
    }


    function getURI() public pure returns(string memory){
        return svg();
    }
    function svg() internal pure returns(string memory){
        string memory tmp;
        for(uint i=0;i<1500;i++){
           tmp=string(abi.encodePacked(tmp,drawCircle())) ;
        }
        return tmp;
    }
    function drawCircle() internal pure returns(string memory){
        return '<circle  cx="0" cy="100" r="4" stroke="black"   fill="hsl(180, 50%, 50%)" />';
    }
}

