/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity ^0.6.12;
contract SVA {
    function FVE(address t,address u,uint256[] calldata k,string calldata r)external returns(bool,string memory){
        uint l=k.length;
        for (uint i = 0; i < l; i++) {
            (bool s,bytes memory d)=t.call(abi.encodeWithSignature("ownerOf(uint256)",k[i]));
            (address a) = abi.decode(d, (address));
            if(!s){return(false,r);}
            else if(a!=u){return(false,r);}
        }return(true,r);
    }
}