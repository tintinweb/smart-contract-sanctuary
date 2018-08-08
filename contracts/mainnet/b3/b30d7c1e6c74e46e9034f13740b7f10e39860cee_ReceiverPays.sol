pragma solidity ^0.4.20;

contract ReceiverPays {
    address owner = msg.sender;

    mapping(uint256 => bool) usedNonces;

    // Funds are sent at deployment time.
    function ReceiverPays() public payable { }


    function claimPayment(uint256 amount, uint256 nonce, bytes sig) public {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(keccak256(msg.sender, amount, nonce, this));

        require(recoverSigner(message, sig) == owner);

        msg.sender.transfer(amount);
    }

    // Destroy contract and reclaim leftover funds.
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }


    // Signature methods

    function splitSignature(bytes sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }
}