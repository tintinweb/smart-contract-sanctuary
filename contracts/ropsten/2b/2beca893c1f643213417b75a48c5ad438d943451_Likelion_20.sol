/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

//Sungrae park

pragma solidity 0.8.0;

contract Likelion_20 {
    function MakeKey(string memory s1, string memory s2) public pure returns(bytes20) {
        bytes32 s1H = keccak256(abi.encodePacked(s1));
        bytes32 s2H = keccak256(abi.encodePacked(s2));
        
        uint256 temp1 = uint256(s1H);
        bytes16 s1Hash = bytes16(uint128(temp1 >> 128));
        
        uint256 temp2 = uint256(s2H);
        bytes16 s2Hash = bytes16(uint128(temp2));
        
        bytes32 Wallet_32 = keccak256(abi.encodePacked(s1Hash,s2Hash));
        
        uint256 temp3 = uint256(Wallet_32);
        bytes20 WalletAddress = bytes20(uint160(temp3 >> (256-160)));
        
        return WalletAddress;
        
    } 
    
}