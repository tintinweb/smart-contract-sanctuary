// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ApptifyDIDRegistry {
    mapping(address => address) public owners;
    mapping(address => uint256) public lastBlock;
    mapping(address => uint256) public nonce;

    event PropertieChanged(
        address indexed identity,
        bytes32 key,
        bytes value,
        uint256 exp,
        uint256 previousBlock
    );

    event OwnerChanged(
        address indexed identity,
        address newOwner,
        uint256 previousBlock
    );

    modifier onlyOwner(address identity, address actor) {
        require(
            actor == lastOwner(identity),
            "Only owner can call this function."
        );
        _;
    }

    function verifySignature(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 hash
    ) internal returns (address) {
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer == lastOwner(identity), "signature incorrect");
        nonce[signer]++;
        return signer;
    }

    function lastOwner(address identity) public view returns (address) {
        address owner = owners[identity];
        if (owner != address(0)) {
            return owner;
        }
        return identity;
    }

    function changeOwnerExec(address identity, address sender, address newOwner)
        internal
        onlyOwner(identity, sender)
    {
        owners[identity] = newOwner;
        emit OwnerChanged(identity, newOwner, lastBlock[identity]);
        lastBlock[identity] = block.number;
    }

    function changeOwner(address identity, address newOwner) external {
        changeOwnerExec(identity, msg.sender, newOwner);
    }

    function changeOwnerSigned(
        address identity,
        address newOwner,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) external onlyOwner(identity, msg.sender) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                address(this),
                newOwner,
                identity,
                "changeOwner",
                nonce[lastOwner(identity)]
            )
        );
        changeOwnerExec(
            identity,
            verifySignature(identity, sigV, sigR, sigS, hash),
            newOwner
        );
    }

    function setPropertieExec(
        address identity,
        address sender,
        bytes32 _key,
        bytes memory value,
        uint256 exp
    ) internal onlyOwner(identity, sender) {
        emit PropertieChanged(
            identity,
            _key,
            value,
            exp,
            lastBlock[identity]
        );
        lastBlock[identity] = block.number;
    }

    function setPropertie(
        address identity,
        bytes32 _key,
        bytes memory value,
        uint256 exp
    ) public {
        setPropertieExec(identity, msg.sender, _key, value, exp);
    }

    function setPropertieSigned(
        address identity,
        bytes32 _key,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes memory value,
        uint256 exp
    ) public {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                nonce[lastOwner(identity)],
                identity,
                "setAttribute",
                _key,
                value,
                exp
            )
        );
        setPropertieExec(
            identity,
            verifySignature(identity, sigV, sigR, sigS, hash),
            _key,
            value,
            exp
        );
    }

    function revokePropertieExec(
        address identity,
        address sender,
        bytes32 _key,
        bytes memory value
    ) internal onlyOwner(identity, sender) {
        emit PropertieChanged(
            identity,
            _key,
            value,
            0,
            lastBlock[identity]
        );
        lastBlock[identity] = block.number;
    }

    function revokePropertie(address identity, bytes32 _key, bytes memory value)
        public
    {
        revokePropertieExec(identity, msg.sender, _key, value);
    }

    function revokePropertieSigned(
        address identity,
        bytes32 _key,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes memory value
    ) public {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                this,
                nonce[lastOwner(identity)],
                identity,
                "revokeAttribute",
                _key,
                value
            )
        );
        revokePropertieExec(
            identity,
            verifySignature(identity, sigV, sigR, sigS, hash),
            _key,
            value
        );
    }
}