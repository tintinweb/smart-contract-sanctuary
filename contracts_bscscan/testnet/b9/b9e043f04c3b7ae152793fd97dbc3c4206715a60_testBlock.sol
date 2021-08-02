/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.8.0;

contract testBlock {
    
    function getKeccak256(uint256 blocknumber,uint256 gaslimit, uint256 inTicket,uint256 salt)
        public view returns (bytes32,uint256){
        bytes32 kec = keccak256(abi.encode(blocknumber,gaslimit,inTicket,salt));
        uint256 value = uint(kec);
        return (kec,value);
    }
}