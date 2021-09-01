/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity 0.8.0;

contract changeName{
string name;
address dst;
bytes4 sel;
bytes32 hash;
uint de;
int256 neg;
bool e;
uint[] no;
address[] ben;
constructor(string memory _name,address _dst,bytes4  _functionSel,bytes32 _hashName,uint8 _dec,int256 _negNum,bool _exists,uint[] memory _nos,address[] memory _beneficiaries){
 name=_name;
  dst=_dst;
 sel=_functionSel;
 hash=_hashName;
 de=_dec;
 neg=_negNum;
 e=_exists;
no=_nos;
 ben=_beneficiaries;
}    


function see() public view returns(bytes memory){
    
    return(abi.encodePacked(name,dst,sel,hash,de,neg,e,no,ben));
}
    
}