// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.1;

import "./TransferHelper.sol";

contract ERC20Swap {
    uint8 constant public version = 1;

    mapping (bytes32 => bool) public swaps;

    event Lockup(
        bytes32 indexed preimageHash,
        uint256 amount,
        address tokenAddress,
        address claimAddress,
        address indexed refundAddress,
        uint timelock
    );

    event Claim(bytes32 indexed preimageHash, bytes32 preimage);
    event Refund(bytes32 indexed preimageHash);

    function hashValues(
        bytes32 preimageHash,
        uint256 amount,
        address tokenAddress,
        address claimAddress,
        address refundAddress,
        uint timelock
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            refundAddress,
            timelock
        ));
    }

    function checkSwapExists(bytes32 hash) private view {
        require(swaps[hash] == true, "ERC20Swap: swap does not exist");
    }

    function lock(
        bytes32 preimageHash,
        uint256 amount,
        address tokenAddress,
        address claimAddress,
        uint timelock
    ) external {
        require(amount > 0, "ERC20Swap: amount must not be zero");

        TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amount);

        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            msg.sender,
            timelock
        );

        require(swaps[hash] == false, "ERC20Swap: swap exists already");
        swaps[hash] = true;

        emit Lockup(preimageHash, amount, tokenAddress, claimAddress, msg.sender, timelock);
    }

    function claim(
        bytes32 preimage,
        uint amount,
        address tokenAddress,
        address refundAddress,
        uint timelock
    ) external {
        bytes32 preimageHash = sha256(abi.encodePacked(preimage));
        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            msg.sender,
            refundAddress,
            timelock
        );

        checkSwapExists(hash);
        delete swaps[hash];

        emit Claim(preimageHash, preimage);

        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount);
    }

    function refund(
        bytes32 preimageHash,
        uint amount,
        address tokenAddress,
        address claimAddress,
        uint timelock
    ) external {
        require(timelock <= block.number, "ERC20Swap: swap has not timed out yet");

        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            msg.sender,
            timelock
        );

        checkSwapExists(hash);
        delete swaps[hash];

        emit Refund(preimageHash);

        TransferHelper.safeTransfer(tokenAddress, msg.sender, amount);
    }
}
