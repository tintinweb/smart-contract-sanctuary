// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.1;

contract EtherSwap {
    uint8 constant public version = 1;

    mapping (bytes32 => bool) public swaps;

    event Lockup(
        bytes32 indexed preimageHash,
        uint amount,
        address claimAddress,
        address indexed refundAddress,
        uint timelock
    );

    event Claim(bytes32 indexed preimageHash, bytes32 preimage);
    event Refund(bytes32 indexed preimageHash);

    function hashValues(
        bytes32 preimageHash,
        uint amount,
        address claimAddress,
        address refundAddress,
        uint timelock
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            preimageHash,
            amount,
            claimAddress,
            refundAddress,
            timelock
        ));
    }

    function transferEtherToSender(
        uint amount
    ) private {
        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "EtherSwap: Ether transfer failed");
    }

    function checkSwapExists(bytes32 hash) private view {
        require(swaps[hash] == true, "EtherSwap: swap does not exist");
    }

    function lock(bytes32 preimageHash, address claimAddress, uint timelock) external payable {
        require(msg.value > 0, "EtherSwap: amount must not be zero");

        bytes32 hash = hashValues(
            preimageHash,
            msg.value,
            claimAddress,
            msg.sender,
            timelock
        );

        require(swaps[hash] == false, "EtherSwap: swap exists already");
        swaps[hash] = true;

        emit Lockup(preimageHash, msg.value, claimAddress, msg.sender, timelock);
    }

    function claim(
        bytes32 preimage,
        uint amount,
        address refundAddress,
        uint timelock
    ) external {
        bytes32 preimageHash = sha256(abi.encodePacked(preimage));
        bytes32 hash = hashValues(
            preimageHash,
            amount,
            msg.sender,
            refundAddress,
            timelock
        );

        checkSwapExists(hash);
        delete swaps[hash];

        emit Claim(preimageHash, preimage);

        transferEtherToSender(amount);
    }

    function refund(
        bytes32 preimageHash,
        uint amount,
        address claimAddress,
        uint timelock
    ) external {
        require(timelock <= block.number, "EtherSwap: swap has not timed out yet");

        bytes32 hash = hashValues(
            preimageHash,
            amount,
            claimAddress,
            msg.sender,
            timelock
        );

        checkSwapExists(hash);
        delete swaps[hash];

        emit Refund(preimageHash);

        transferEtherToSender(amount);
    }
}