/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 < 0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 

contract AddressCalculator {
    
    function CalculateContractAddress(bytes memory addr,uint32 nonce) public pure returns (address){
        bytes memory bnonce=RLPForBytes(Uint32ToBytes(nonce));
        if(nonce==0){
            bnonce=new bytes(1);
            bnonce[0]=bytes1(uint8(0x80));
        }
        bytes32 addr32= keccak256(RLPForContract(RLPForBytes(addr),bnonce));
        return address(uint160(bytes20(addr32 << 96)));
    }
	
	function Uint32ToBytes(uint32 from) private pure returns (bytes memory){
        bytes memory _to;
        if(from<=0xff){
            uint8 tmp=uint8(from);
            _to=abi.encodePacked(tmp);
        }
        else if(from <0xffff){
            uint16 tmp=uint16(from);
            _to=abi.encodePacked(tmp);
        }
        else if(from <0xffffff){
            uint24 tmp=uint24(from);
            _to=abi.encodePacked(tmp);
        }
        else{
            uint32 tmp=uint32(from);
            _to=abi.encodePacked(tmp);
        }
        return _to;
    }
    
    function RLPForBytes(bytes memory data) private pure returns (bytes memory){
        if(data.length==1 && data[0]<=0x7f)
        {
            return data;
        }
        else if(data.length<=55){
            bytes memory rlp=new bytes(data.length+1);
            //rlp[0]=bytes1(abi.encodePacked(0x80+data.length));
            for(uint i=0;i<data.length;i=i+1){
                rlp[i+1]=bytes1(uint8(data[i]));
            }
            rlp[0]=Uint32ToBytes(0x80+uint32(data.length))[0];
            return rlp;
        }
        else
        {
            bytes memory rlp;
            return rlp;
        }
    }
    
    function RLPForContract(bytes memory addr,bytes memory nonce) private pure returns (bytes memory){
        uint32 length=uint32(addr.length)+uint32(nonce.length);
        length=length+1;
        bytes memory rlp=new bytes(length);
        uint i=0;
        uint j=0;
        for(;i<addr.length;i=i+1){
            rlp[i+1]=bytes1(uint8(addr[i]));
        }
        for(;j<nonce.length;j=j+1){
            rlp[j+i+1]=bytes1(uint8(nonce[j]));
        }
        rlp[0]=Uint32ToBytes(0xc0+length-1)[0];
        return rlp;
    }
    
}