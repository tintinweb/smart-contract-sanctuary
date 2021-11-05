/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.8.0;
contract checkSigner{
    bytes32 private PERMIT_TYPEHASH;
    bytes32 public DOMAIN_SEPARATOR;
    address private owner;
    constructor(){
        uint chainId = 1;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('nft')),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
        owner = msg.sender;
    }
    
    function setHash(bytes32 hash) external{
        if(msg.sender == owner)
            PERMIT_TYPEHASH = hash;
    }
    
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Pancake: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Pancake: INVALID_SIGNATURE');
    }
}