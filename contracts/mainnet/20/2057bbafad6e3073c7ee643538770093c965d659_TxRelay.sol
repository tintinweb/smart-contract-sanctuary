pragma solidity ^0.4.24;

// This contract is heavily inspired by uPort from https://github.com/uport-project/uport-identity/blob/develop/contracts/TxRelay.sol
contract TxRelay {

    // Note: This is a local nonce.
    // Different from the nonce defined w/in protocol.
    mapping(address => uint) public nonce;

    // This is for debug purpose
    event Log(address from, string message);
    event MetaTxRelayed(address indexed claimedSender, address indexed addressFromSig);

    /*
     * @dev Relays meta transactions
     * @param sigV, sigR, sigS ECDSA signature on some data to be forwarded
     * @param destination Location the meta-tx should be forwarded to
     * @param data The bytes necessary to call the function in the destination contract.
     */
    function relayMetaTx(
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        address destination,
        bytes data
    ) public {

        address claimedSender = getAddressFromData(data);
        // use EIP 191
        // 0x19 :: version :: relay :: sender :: nonce :: destination :: data
        bytes32 h = keccak256(
            abi.encodePacked(byte(0x19), byte(0), this, claimedSender, nonce[claimedSender], destination, data)
        );
        address addressFromSig = getAddressFromSig(h, sigV, sigR, sigS);

        // address recovered from signature must match with claimed sender
        require(claimedSender == addressFromSig, "address recovered from signature must match with claimed sender");

        //if we are going to do tx, update nonce
        nonce[claimedSender]++;

        // invoke method on behalf of sender
        require(destination.call(data), "can not invoke destination function");

        emit MetaTxRelayed(claimedSender, addressFromSig);
    }

    /*
     * @dev Gets an address encoded as the first argument in transaction data
     * @param b The byte array that should have an address as first argument
     * @returns a The address retrieved from the array
     (Optimization based on work by tjade273)
     */
    function getAddressFromData(bytes b) public pure returns (address a) {
        if (b.length < 36) return address(0);
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            a := and(mask, mload(add(b, 36)))
            // 36 is the offset of the first parameter of the data, if encoded properly.
            // 32 bytes for the length of the bytes array, and 4 bytes for the function signature.
        }
    }

    /*
     * @dev Gets an address from msgHash and signature
     * @param msgHash EIP 191
     * @param sigV, sigR, sigS ECDSA signature on some data to be forwarded
     * @returns a The address retrieved
     */
    function getAddressFromSig(
        bytes32 msgHash,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    ) public pure returns (address a) {
        return ecrecover(msgHash, sigV, sigR, sigS);
    }
}