// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract TLSToken {
    struct Signature {
        uint256 sign_id;
        uint256 cert_id;
        uint64 expiry;
        address signer;
    }

    struct Certificate {
        uint256 id;
        string name;
        string domain_name;
        string state;
        string country;
        uint32 key_size;
        string public_key;
        address cert_owner;
    }

    Signature[] public signatures;
    Certificate[] public certificates;
    mapping(address => bool) cert_issued;
    mapping(address => Certificate) cert_registry;

    function add_certificate(
        string calldata name,
        string calldata domain_name,
        string calldata state,
        string calldata country,
        string calldata public_key,
        uint32 key_size
    ) public returns (uint256) {
        require(key_size == 1024 || key_size == 2048, "KEY SIZE INVALID");
        require(!str_empty(name), "NAME EMPTY");
        require(!str_empty(domain_name), "DOMAIN NAME EMPTY");
        require(!str_empty(state), "STATE EMPTY");
        require(!str_empty(country), "COUNTRY EMPTY");
        require(!str_empty(public_key), "PUBLIC KEY EMPTY");

        Certificate memory certificate;
        certificate.id = certificates.length;
        certificate.name = name;
        certificate.domain_name = domain_name;
        certificate.state = state;
        certificate.country = country;
        certificate.key_size = key_size;
        certificate.public_key = public_key;
        certificate.cert_owner = msg.sender;

        certificates.push(certificate);
        cert_issued[msg.sender] = true;
        cert_registry[msg.sender] = certificate;
        return certificate.id;
    }

    function sign_certificate(uint256 cert_id, uint64 expiry) public {
        require(cert_id < certificates.length, "CERTIFICATE ID INVALID");
        require(expiry > block.timestamp, "EXPIRY INVALID");
        require(
            msg.sender != certificates[cert_id].cert_owner,
            "CANT SIGN OWN CERT"
        );

        Signature memory signature;
        signature.sign_id = signatures.length;
        signature.cert_id = cert_id;
        signature.expiry = expiry;
        signature.signer = msg.sender;
        signatures.push(signature);
    }

    function fetch_certificate(uint256 cert_id)
        public
        view
        returns (
            address cert_owner,
            string memory name,
            string memory domain_name,
            string memory state,
            string memory country,
            string memory public_key,
            uint32 key_size
        )
    {
        require(cert_id < certificates.length, "CERTIFICATE ID INVALID");
        Certificate storage certificate = certificates[cert_id];

        cert_owner = certificate.cert_owner;
        name = certificate.name;
        domain_name = certificate.domain_name;
        state = certificate.state;
        country = certificate.country;
        public_key = certificate.public_key;
        key_size = certificate.key_size;
    }

    function get_signers(uint256 cert_id)
        public
        view
        returns (string memory signers)
    {
        signers = "";
        for (uint256 i = 0; i < signatures.length; i++)
            if (signatures[i].cert_id == cert_id)
                signers = string(
                    abi.encodePacked(
                        signers,
                        "//",
                        string(abi.encodePacked(signatures[i].signer))
                    )
                );
    }

    function str_empty(string memory str) public pure returns (bool) {
        bytes memory str_bytes = bytes(str);
        if (str_bytes.length == 0) return true;
        return false;
    }
}

