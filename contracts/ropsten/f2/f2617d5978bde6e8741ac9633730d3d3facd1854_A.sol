/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

struct Signature {
    address signatory;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

contract A {
    uint internal _a = 1;
    
    function a() virtual public view returns (uint) {
        return _a;
    }

    function b() virtual public view returns (uint) {
        return 0;
    }
    
    function c() virtual public view returns (uint) {
        return 0;
    }

    function s(Signature[] memory signature) virtual public view returns (uint) {
        return signature[0].v;
    }
    
    bytes32 public constant RECEIVE_TYPEHASH = keccak256("Receive(uint256 fromChainId,address to,uint256 nonce,uint256 volume,address signatory)");
    bytes32 public DOMAIN_SEPARATOR;

    function recv(uint256 fromChainId, address to, uint256 nonce, uint256 volume, Signature[] memory signatures) virtual external {
        //require(received[fromChainId][to][nonce] == 0, 'withdrawn already');
        uint N = signatures.length;
        //require(N >= config[_minSignatures_], 'too few signatures');
        for(uint i=0; i<N; i++) {
            bytes32 structHash = keccak256(abi.encode(RECEIVE_TYPEHASH, fromChainId, to, nonce, volume, signatures[i].signatory));
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
            address signatory = ecrecover(digest, signatures[i].v, signatures[i].r, signatures[i].s);
            require(signatory != address(0), "invalid signature");
            require(signatory == signatures[i].signatory, "unauthorized");
            //_decreaseAuthQuota(signatures[i].signatory, volume);
            emit Authorize(fromChainId, to, nonce, volume, signatory);
        }
        //received[fromChainId][to][nonce] = volume;
        //_transfer(address(this), to, volume);
        emit Receive(fromChainId, to, nonce, volume);
    }
    event Receive(uint256 indexed fromChainId, address indexed to, uint256 indexed nonce, uint256 volume);
    event Authorize(uint256 fromChainId, address indexed to, uint256 indexed nonce, uint256 volume, address indexed signatory);
}

contract B {
    uint internal _b = 2;
    
    function a() virtual public view returns (uint) {
        return 0;
    }

    function b() virtual public view returns (uint) {
        return _b;
    }
    
    function c() virtual public view returns (uint) {
        return 0;
    }
}

contract C is A, B {
    uint internal _c = 3;

    function a() override(A, B) public view returns (uint) {
        return _a;
    }

    function b() override(A, B) public view returns (uint) {
        return _b;
    }
    
    function c() override(A, B) public view returns (uint) {
        return _c;
    }
}