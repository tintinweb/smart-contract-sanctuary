// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ApptifyDigitalSign {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH =
        0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
    // keccak256("Apptify Digital Signature")
    bytes32 constant NAME_HASH =
        0x93d2994426767c652e8de61af7808a4330bb40b7c3e7ef60b2d3dff440fb2193;
    // keccak256("1")
    bytes32 constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    bytes32 constant SALT =
        0xfc1f31bc592dd4ffb182ea2672b161503a37437ab30afa2518639eff272e263a;
    //=======================================================================================================================
    // keccak256("ApptifyDigitalSign(address docSender,address docSigner,address blockchainExecutor,bytes32 docHash,uint256 signingTime,uint256 nonce)")
    bytes32 constant TXTYPE_HASH =
        0xf090942ec390f99294503a3b5ac9633fe2eb1e1c40f17e58f0d66dd3b92e7151;

    struct DocSigner {
        address identity;
        uint8 sigV;
        bytes32 sigR;
        bytes32 sigS;
        uint256 signingTime;
    }

    struct SignerAnchored {
        address identity;
        uint256 signingTime;
    }

    event DocumentAnchored(
        bytes32 indexed dochash,
        address blockchainExecutor,
        address docSender,
        SignerAnchored[] docSigner,
        uint256 blockTimestamp,
        uint256 nonce,
        uint256 previousBlock
    );

    bytes32 DOMAIN_SEPARATOR;
    mapping(bytes32 => uint256) public lastBlock;
    mapping(bytes32 => uint256) public nonce;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAINTYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                block.chainid,
                address(this),
                SALT
            )
        );
    }

    function execute(
        address docSender,
        DocSigner[] memory docSigner,
        address blockchainExecutor,
        bytes32 docHash
    ) public {
        require(
            blockchainExecutor == msg.sender || blockchainExecutor == address(0), "blockchainExecutor != sender or blockchainExecutor = address 0"
        );
        SignerAnchored[] memory signers = new SignerAnchored[](
            docSigner.length
        );
        address lastAdd = address(0); // cannot have address(0) as an signer
        for (uint256 i = 0; i < docSigner.length; i++) {
            // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
            // keccak256("ApptifyDigitalSign(address docSender,address docSigner,address blockchainExecutor,bytes32 docHash,uint256 signingTime,uint256 nonce,uint256 gasLimit)")
            bytes32 txInputHash = keccak256(
                abi.encode(
                    TXTYPE_HASH,
                    docSender,
                    docSigner[i].identity,
                    blockchainExecutor,
                    docHash,
                    docSigner[i].signingTime,
                    nonce[docHash]
                )
            );
            bytes32 totalHash = keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash)
            );
            address recovered = ecrecover(
                totalHash,
                docSigner[i].sigV,
                docSigner[i].sigR,
                docSigner[i].sigS
            );
            require(recovered > lastAdd && recovered == docSigner[i].identity, "Signatures does not match check nonce and try again");
            signers[i].identity = recovered;
            signers[i].signingTime = docSigner[i].signingTime;
        }
        require(signers.length == docSigner.length, "The number of people signing does not match.");
        emit DocumentAnchored(
            docHash,
            blockchainExecutor,
            docSender,
            signers,
            block.timestamp,
            nonce[docHash],
            lastBlock[docHash]
        );
        nonce[docHash] = nonce[docHash] + 1;
        lastBlock[docHash] = block.number;
    }
}