/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: Apache-2.0;

pragma solidity 0.8.0;

contract EIP712 {
   struct Identity {
        address wallet;
        uint256 tokenId;
        uint256 nonce;
    }

    uint256 public chainId;
    address private _cVerify;
    bytes32 public NCS; // NEFTi Content Salt
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 public constant NEFTi_SIGNATURE_TYPEHASH = keccak256("NEFTiSignature(bytes32 r,bytes32 s,uint8 v)");
    bytes32 public constant NEFTi_IDENTITY_SIGNATURE_TYPEHASH = keccak256("NEFTiIdentity(address wallet,uint256 tokenId,uint256 nonce,Signature signature)");
    bytes32 public constant NEFTi_IDENTITY_TYPEHASH = keccak256("NEFTiIdentity(address wallet,uint256 tokenId,uint256 nonce)");
    bytes32 public EIP712_DOMAIN_SEPARATOR;

    function _hashDomain(string memory _name, string memory _version, uint256 _chainId, address _verifyingContract, bytes32 _salt)
        private pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            "\\x19\\x01",
            EIP712_DOMAIN_TYPEHASH,
            keccak256(abi.encodePacked(_name)),
            keccak256(abi.encodePacked(_version)),
            _chainId, _verifyingContract, _salt
        ));
    }

    function _hashIdentity(address _wallet, uint256 _tokenId, uint256 _nonce)
        private pure
        returns (bytes32)
    { return keccak256(abi.encodePacked("\\x19\\x01", NEFTi_IDENTITY_TYPEHASH, _wallet, _tokenId, _nonce)); }
    
    // function hashFnDomainSeparator(
    //     string memory _name,
    //     string memory _version,
    //     uint256 _chainId,
    //     address _verifyingContract,
    //     bytes32 _salt
    // )
    //     public pure
    //     returns (bytes32)
    // { return _hashDomain(_name, _version, _chainId, _verifyingContract, _salt); }
    
    // function hashFnIdentity(
    //     address _signer,
    //     uint256 _tokenId,
    //     uint256 _nonce
    // )
    //     public pure
    //     returns (bytes32)
    // { return _hashIdentity(_signer, _tokenId, _nonce); }

    function verify(
        address _signer,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        view
        returns (bool isOK, address signer)
    {
        // require(_sig.length == 65, "Invalid signature length");
        require(_v >= 27 && _v <= 28, "Invalid signature V");
        require(_r.length == 32, "Invalid signature R");
        require(_s.length == 32, "Invalid signature S");

        address msgSigner = ecrecover(

            keccak256(
                abi.encodePacked(
                // abi.encode(
                    "\x19Ethereum Signed Message:\n32",
                    EIP712_DOMAIN_SEPARATOR
                )
            ),

            _v,
            _r,
            _s
        );

        return (
            msgSigner == _signer,
            msgSigner
        );
    }

    function verifyEIP712(
        address _signer,
        uint256 _tokenId,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        view
        returns (bool isOK, address signer)
    {
        // require(_sig.length == 65, "Invalid signature length");
        require(_v >= 27 && _v <= 28, "Invalid signature V");
        require(_r.length == 32, "Invalid signature R");
        require(_s.length == 32, "Invalid signature S");

        address msgSigner = ecrecover(

            keccak256(
                abi.encodePacked(
                // abi.encode(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            EIP712_DOMAIN_SEPARATOR,
                            _hashIdentity(
                                _signer,
                                _tokenId,
                                _nonce
                            )
                        )
                    )
                )
            ),

            _v,
            _r,
            _s
        );

        return (
            msgSigner == _signer,
            msgSigner
        );
    }

    constructor(uint256 _chainId, bytes32 _ncs) {
        chainId = _chainId;
        NCS = _ncs;
        _cVerify = address(this);

        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encodePacked(
            // abi.encode(
                "\\x19\\x01",
                EIP712_DOMAIN_TYPEHASH,

                keccak256("NEFTi Contents Signature"),
                keccak256("1"),
                _chainId,
                _cVerify,
                _ncs
            )
        );
    }
}