// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract PaymentChannel {
    address payable public sender; // account sending payment
    address payable public recipient; // account receiving payment
    uint256 public expiration; // timeout

    constructor(address payable _recipientAddress, uint256 _duration) payable {
        sender = payable(msg.sender);
        recipient = _recipientAddress;
        expiration = block.timestamp + _duration;
    }

    // the recipient can close channelt any time by send signed amout from sender
    // the recipient will be receive that amout, and the amout remainder will go back to sender
    function close(uint256 _amount, bytes memory _signature) external {
        require(msg.sender == recipient, "You aren't the recipient");
        require(
            isValidSignature(_amount, _signature),
            "The signature is invalid"
        );

        recipient.transfer(_amount);
        selfdestruct(sender);
    }

    // the sender can extend the expiration at any time
    function extend(uint256 newExpiration) external {
        require(
            msg.sender == sender,
            "Only the sender can extend the expiration"
        );
        require(
            newExpiration > expiration,
            "The new expiration must be after expiration"
        );

        expiration = newExpiration;
    }

    // if the recipient don't close channel before expiration,
    // then the Ether is released back to the sender.
    function claimTimeout() external {
        require(block.timestamp >= expiration);
        selfdestruct(sender);
    }

    function isValidSignature(uint256 _amount, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, _amount)));

        // check that the signature is from the payment sender
        return recoverSigner(message, _signature) == sender;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "Sig's length must be equal to 65");

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

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}