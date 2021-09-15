/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.5.8;


contract Events {
    
    bytes32 txHash;
    address target;
    uint256 value;
    string signature;
    bytes data;
    uint256 eta;
    
    event first2indexed(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event noIndexed(bytes32 txHash, address target, uint256 value, string signature, bytes data, uint256 eta);
    
    function emitEvent() public {

        txHash = 0x1d17354c7ee3631d2dc9fdf7e9360db60afae261d0eb4f6064473a1c52b1ee5c;
        target = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
        value = 0;
        signature = "_setCollateralFactor(address,uint256)";
        data = hex"00000000000000000000000095B4EF2869EBD94BEB4EEE400A99824BF5DC325B00000000000000000000000000000000000000000000000004DB732547630000";
        eta = 1629163129;

        emit first2indexed(txHash, target, value, signature, data, eta);
        emit noIndexed(txHash, target, value, signature, data, eta);

    }


    
}