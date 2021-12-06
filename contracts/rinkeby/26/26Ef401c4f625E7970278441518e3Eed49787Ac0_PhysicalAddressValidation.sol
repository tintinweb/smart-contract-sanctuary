// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PhysicalAddressValidation {
    string public neighborhood;
    address owner;

    struct tokenInfo {
        uint256 nonce;
        address ethAddress;
    }

    modifier _ownerOnly() {
      require(msg.sender == owner);
      _;
    }

    address public myaddress;

    // String for now, but maybe USPS has an abstract unique ID for address. In which case we should use that
    mapping(address => string) public onChainToPhysicalAddresses;

    mapping(string => tokenInfo) public oneTimeUseTokens;

    constructor(string memory _neighborhood) {
        neighborhood = _neighborhood;
        owner = msg.sender;
    }

    function getMessageHash(
        string memory physicalAddressHash,
        uint256 notsecurenonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(physicalAddressHash, notsecurenonce));
    }

    function getNonceForAddress(
        string memory physicalAddressHash,
        address ethAddress
    ) public _ownerOnly returns (uint256) {
        // for prod apps you want to use a verifiable randomness oracle rather than use previous block number
        uint256 notsecurenonce = uint256(blockhash(block.number-1));
        // currently it just overrides the old address hash for the user
        // so only one user at the address can generate a nonce
        oneTimeUseTokens[physicalAddressHash] = tokenInfo(notsecurenonce, ethAddress);
        return notsecurenonce;
    }

    // copied from here https://solidity-by-example.org/signature/
     function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

     function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

     function verify(
        address _signer,
        string memory physicalAddressHash,
        uint256 notsecurenonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(physicalAddressHash,notsecurenonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function registerAddress(
        string memory physicalAddressHash,
        uint256 notsecurenonce
    ) public {
        // ensure that the token has not already been used, and that it matches up with the physical address provided as an arg to this function
        tokenInfo memory _tokInfo = oneTimeUseTokens[physicalAddressHash];
        // TODO: figure out why this doesn't work, maybe needs casting
        // require(
        //     msg.sender == _tokInfo.ethAddress,
        //     "Sender not associated with the physical address."
        // );
        require (
            notsecurenonce == _tokInfo.nonce,
            "Nonce supplied doesn't match."
        );
        // TODO: this isn't strictly needed
        // // if verify succeeded, store the sender address on chain
        // if (verify(msg.sender, physicalAddressHash, notsecurenonce, proofOfAddressSignature) == true) {
        //     onChainToPhysicalAddresses[msg.sender] = physicalAddressHash;
        // }

        delete oneTimeUseTokens[physicalAddressHash];
    }
    // external function to add one-time use token, BUT make sure that to validate it can only be called by the contract creator.
}