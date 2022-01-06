// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TestLib {
    function isEqual(uint256 a, uint256 b) public pure returns (bool) {
        return a == b;
    }

    function xor(bytes32[] memory _proof) public pure returns (bytes32) {
        bytes32 x = 0;
        for (uint256 i = 0; i < _proof.length; i++) {
            x = x ^ _proof[i];
        }
        return x;
    }

    function simpleAppend(
        uint256 _len,
        bytes32 _oldRoot,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) public pure returns (bytes32 _newRoot) {
        bytes32 x = bytes32(_len) ^ _oldRoot ^ _leafHash;
        for (uint256 i = 0; i < _proof.length; i++) {
            x = x ^ _proof[i];
        }
        return x;
    }

    function calcRootHash(
        uint256 _idx,
        uint256 _len,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) public pure returns (bytes32 _rootHash) {
        if (_len == 0) {
            return bytes32(0);
        }

        uint256 _proofIdx = 0;
        bytes32 _nodeHash = _leafHash;

        while (_len > 1) {
            uint256 _peerIdx = (_idx / 2) * 2;
            bytes32 _peerHash = bytes32(0);
            if (_peerIdx == _idx) {
                _peerIdx += 1;
            }
            if (_peerIdx < _len) {
                _peerHash = _proof[_proofIdx];
                _proofIdx += 1;
            }

            bytes32 _parentHash = bytes32(0);
            if (_peerIdx >= _len && _idx >= _len) {
                // pass, _parentHash = bytes32(0)
            } else if (_peerIdx > _idx) {
                _parentHash = keccak256(abi.encodePacked(_nodeHash, _peerHash));
            } else {
                _parentHash = keccak256(abi.encodePacked(_peerHash, _nodeHash));
            }

            _len = (_len - 1) / 2 + 1;
            _idx = _idx / 2;
            _nodeHash = _parentHash;
        }

        return _nodeHash;
    }

    function verify(
        uint256 _idx,
        uint256 _len,
        bytes32 _root,
        bytes32 _oldLeafHash,
        bytes32[] memory _proof
    ) public pure returns (bool) {
        return calcRootHash(_idx, _len, _oldLeafHash, _proof) == _root;
    }

    function append(
        uint256 _len,
        bytes32 _oldRoot,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) public pure returns (bytes32 _newRoot) {
        if (_len > 0) {
            if ((_len & (_len - 1)) == 0) {
                // 2^n, a new layer will be added.
                require(_proof[0] == _oldRoot, "ERR_PROOF");
            } else {
                require(
                    verify(_len, _len, _oldRoot, bytes32(0), _proof),
                    "ERR_PROOF"
                );
            }
        }

        return calcRootHash(_len, _len + 1, _leafHash, _proof);
    }

}

contract LibTest {
    uint256 public v;

    bytes32 public root;
    uint256 public len;

    function set(uint256 prev, uint256 next) public returns (bool) {
        if (TestLib.isEqual(v, prev)) {
            v = next;
            return true;
        }

        return false;
    }

    function checkXor(bytes32[] memory _proof) public {
        v = uint256(TestLib.xor(_proof));
    }

    function checkSimpleAppend(bytes32[] memory _proof) public {
        v = uint256(TestLib.simpleAppend(0, 0, 0, _proof));
    }

    function append(bytes32[] memory _proof, bytes32 leaf) public {
        root = TestLib.append(len, root, leaf, _proof);
        len = len + 1;
    }
    
}