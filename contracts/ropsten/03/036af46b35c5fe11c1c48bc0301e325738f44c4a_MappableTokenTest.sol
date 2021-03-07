/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

struct Signature {
    address signatory;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

pragma experimental ABIEncoderV2;

contract MappableTokenTest /*is ERC20UpgradeSafe, AuthQuota, IPermit*/ {
    function recv(/*uint256 fromChainId, address to, uint256 nonce, */uint256 volume, Signature[] memory signatures) virtual external {
        //require(received[fromChainId][to][nonce] == 0, 'withdrawn already');
        //uint N = signatures.length;
        //require(N >= config[_minSignatures_], 'too few signatures');
        //for(uint i=0; i<N; i++) {
        //    bytes32 structHash = keccak256(abi.encode(RECEIVE_TYPEHASH, fromChainId, to, nonce, volume, signatures[i].signatory));
        //    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        //    address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
        //    require(signatory != address(0), "invalid signature");
        //    require(signatory == signatures[i].signatory, "unauthorized");
        //    _decreaseAuthQuota(signatures[i].signatory, volume);
        //    emit Authorize(fromChainId, to, nonce, volume, signatory);
        //}
        //received[fromChainId][to][nonce] = volume;
        //_transfer(address(this), to, volume);
        //emit Receive(fromChainId, to, nonce, volume);
    }
    //event Receive(uint256 indexed fromChainId, address indexed to, uint256 indexed nonce, uint256 volume);
    //event Authorize(uint256 fromChainId, address indexed to, uint256 indexed nonce, uint256 volume, address indexed signatory);
    
    //function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        //require(deadline >= block.timestamp, 'permit EXPIRED');
        //bytes32 digest = keccak256(
        //    abi.encodePacked(
        //        '\x19\x01',
        //        DOMAIN_SEPARATOR,
        //        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        //    )
        //);
        //address recoveredAddress = ecrecover(digest, v, r, s);
        //require(recoveredAddress != address(0) && recoveredAddress == owner, 'permit INVALID_SIGNATURE');
        //_approve(owner, spender, value);
    //}
    
}