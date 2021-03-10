/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

contract TestSig {

    uint256 private constant _WORD_SIZE = 32;

    // bytes32 public constant EIP712DOMAIN_HASH =
    //      keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712DOMAIN_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 public constant NAME_HASH =
    //      keccak256("Hermez Network")
    bytes32 public constant NAME_HASH =
        0xbe287413178bfeddef8d9753ad4be825ae998706a6dabff23978b59dccaea0ad;
    // bytes32 public constant VERSION_HASH =
    //      keccak256("1")
    bytes32 public constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    // bytes32 public constant AUTHORISE_TYPEHASH =
    //      keccak256("Authorise(string Provider,string Authorisation,bytes32 BJJKey)");
    bytes32 public constant AUTHORISE_TYPEHASH =
        0xafd642c6a37a2e6887dc4ad5142f84197828a904e53d3204ecb1100329231eaa;
    // bytes32 public constant HERMEZ_NETWORK_HASH = keccak256(bytes("Hermez Network")),
    bytes32 public constant HERMEZ_NETWORK_HASH =
        0xbe287413178bfeddef8d9753ad4be825ae998706a6dabff23978b59dccaea0ad;
    // bytes32 public constant ACCOUNT_CREATION_HASH = keccak256(bytes("Account creation")),
    bytes32 public constant ACCOUNT_CREATION_HASH =
        0xff946cf82975b1a2b6e6d28c9a76a4b8d7a1fd0592b785cb92771933310f9ee7;

    address public constant ROLLUP_ADDR = 0x2EA58Bf4818242700F508082D8cBc45355c594E4;

    /**
     * @dev Retrieve the DOMAIN_SEPARATOR hash
     * @return domainSeparator hash used for sign messages
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32 domainSeparator) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_HASH,
                    NAME_HASH,
                    VERSION_HASH,
                    getChainId(),
                    ROLLUP_ADDR
                )
            );
    }

    /**
     * @return chainId The current chainId where the smarctoncract is executed
     */
    function getChainId() public pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev Retrieve ethereum address from a (defaultMessage + babyjub) signature
     * @param babyjub Public key babyjubjub represented as point: sign + (Ay)
     * @param r Signature parameter
     * @param s Signature parameter
     * @param v Signature parameter
     * @return Ethereum address recovered from the signature
     */
    function _checkSig(
        bytes32 babyjub,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public view returns (address) {
        // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L46
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "HermezHelpers::_checkSig: INVALID_S_VALUE"
        );

        bytes32 encodeData =
            keccak256(
                abi.encode(
                    AUTHORISE_TYPEHASH,
                    HERMEZ_NETWORK_HASH,
                    ACCOUNT_CREATION_HASH,
                    babyjub
                )
            );

        bytes32 messageDigest =
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), encodeData)
            );

        address ethAddress = ecrecover(messageDigest, v, r, s);

        require(
            ethAddress != address(0),
            "HermezHelpers::_checkSig: INVALID_SIGNATURE"
        );

        return ethAddress;
    }
    
}