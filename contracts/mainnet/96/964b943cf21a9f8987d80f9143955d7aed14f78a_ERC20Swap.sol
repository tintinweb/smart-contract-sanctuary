// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.6;

import "./TransferHelper.sol";

// @title Hash timelock contract for ERC20 tokens
contract ERC20Swap {
    // State variables

    /// @dev Version of the contract used for compatibility checks
    uint8 constant public version = 2;

    /// @dev Mapping between value hashes of swaps and whether they have Ether locked in the contract
    mapping (bytes32 => bool) public swaps;

    // Events

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

    // Functions

    // External functions

    /// Locks tokens for a swap in the contract and forwards a specified amount of Ether to the claim address
    /// @notice The amount of Ether forwarded to the claim address is the amount sent in the transaction and the refund address is the sender of the transaction
    /// @dev Make sure to set a reasonable gas limit for calling this function, else a malicious contract at the claim address could drain your Ether
    /// @param preimageHash Preimage hash of the swap
    /// @param amount Amount that should be locked in the contract in the smallest denomination of the token
    /// @param tokenAddress Address of the token that should be locked in the contract
    /// @param claimAddress Address that can claim the locked tokens
    /// @param timelock Block height after which the locked tokens can be refunded
    function lockPrepayMinerfee(
        bytes32 preimageHash,
        uint256 amount,
        address tokenAddress,
        address payable claimAddress,
        uint timelock
    ) external payable {
        lock(preimageHash, amount, tokenAddress, claimAddress, timelock);

        // Forward the amount of Ether sent in the transaction to the claim address
        TransferHelper.transferEther(claimAddress, msg.value);
    }

    /// Claims tokens locked in the contract
    /// @dev To query the arguments of this function, get the "Lockup" event logs for the SHA256 hash of the preimage
    /// @param preimage Preimage of the swap
    /// @param amount Amount locked in the contract for the swap in the smallest denomination of the token
    /// @param tokenAddress Address of the token locked for the swap
    /// @param refundAddress Address that locked the tokens in the contract
    /// @param timelock Block height after which the locked tokens can be refunded
    function claim(
        bytes32 preimage,
        uint amount,
        address tokenAddress,
        address refundAddress,
        uint timelock
    ) external {
        // If the preimage is wrong, so will be its hash which will result in a wrong value hash and no swap being found
        bytes32 preimageHash = sha256(abi.encodePacked(preimage));

        // Passing "msg.sender" as "claimAddress" to "hashValues" ensures that only the destined address can claim
        // All other addresses would produce a different hash for which no swap can be found in the "swaps" mapping
        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            msg.sender,
            refundAddress,
            timelock
        );

        // Make sure that the swap to be claimed has tokens locked
        checkSwapIsLocked(hash);

        // Delete the swap from the mapping to ensure that it cannot be claimed or refunded anymore
        // This *HAS* to be done before actually sending the tokens to avoid reentrancy
        // Reentrancy is a bigger problem when sending Ether but there is no real downside to deleting from the mapping first
        delete swaps[hash];

        // Emit the "Claim" event
        emit Claim(preimageHash, preimage);

        // Transfer the tokens to the claim address
        TransferHelper.safeTransferToken(tokenAddress, msg.sender, amount);
    }

    /// Refunds tokens locked in the contract
    /// @dev To query the arguments of this function, get the "Lockup" event logs for your refund address and the preimage hash if you have it
    /// @dev For further explanations and reasoning behind the statements in this function, check the "claim" function
    /// @param preimageHash Preimage hash of the swap
    /// @param amount Amount locked in the contract for the swap in the smallest denomination of the token
    /// @param tokenAddress Address of the token locked for the swap
    /// @param claimAddress Address that that was destined to claim the funds
    /// @param timelock Block height after which the locked Ether can be refunded
    function refund(
        bytes32 preimageHash,
        uint amount,
        address tokenAddress,
        address claimAddress,
        uint timelock
    ) external {
        // Make sure the timelock has expired already
        // If the timelock is wrong, so will be the value hash of the swap which results in no swap being found
        require(timelock <= block.number, "ERC20Swap: swap has not timed out yet");

        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            msg.sender,
            timelock
        );

        checkSwapIsLocked(hash);
        delete swaps[hash];

        emit Refund(preimageHash);

        TransferHelper.safeTransferToken(tokenAddress, msg.sender, amount);
    }

    // Public functions

    /// Locks tokens in the contract
    /// @notice The refund address is the sender of the transaction
    /// @dev This function is "public" so that it can be called from the outside and "lockPrepayMinerfee" function
    /// @param preimageHash Preimage hash of the swap
    /// @param amount Amount to be locked in the contract
    /// @param tokenAddress Address of the token to be locked
    /// @param claimAddress Address that can claim the locked tokens
    /// @param timelock Block height after which the locked tokens can be refunded
    function lock(
        bytes32 preimageHash,
        uint256 amount,
        address tokenAddress,
        address claimAddress,
        uint timelock
    ) public {
        // Locking zero tokens in the contract is pointless
        require(amount > 0, "ERC20Swap: locked amount must not be zero");

        // Transfer the specified amount of tokens from the sender of the transaction to the contract
        TransferHelper.safeTransferTokenFrom(tokenAddress, msg.sender, address(this), amount);

        // Hash the values of the swap
        bytes32 hash = hashValues(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            msg.sender,
            timelock
        );

        // Make sure no swap with this value hash exists yet
        require(swaps[hash] == false, "ERC20Swap: swap exists already");

        // Save to the state that funds were locked for this swap
        swaps[hash] = true;

        // Emit the "Lockup" event
        emit Lockup(preimageHash, amount, tokenAddress, claimAddress, msg.sender, timelock);
    }

    /// Hashes all the values of a swap with Keccak256
    /// @param preimageHash Preimage hash of the swap
    /// @param amount Amount the swap has locked in the smallest denomination of the token
    /// @param tokenAddress Address of the token of the swap
    /// @param claimAddress Address that can claim the locked tokens
    /// @param refundAddress Address that locked the tokens and can refund them
    /// @param timelock Block height after which the locked tokens can be refunded
    /// @return Value hash of the swap
    function hashValues(
        bytes32 preimageHash,
        uint256 amount,
        address tokenAddress,
        address claimAddress,
        address refundAddress,
        uint timelock
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            preimageHash,
            amount,
            tokenAddress,
            claimAddress,
            refundAddress,
            timelock
        ));
    }

    // Private functions

    /// Checks whether a swap has tokens locked in the contract
    /// @dev This function reverts if the swap has no tokens locked in the contract
    /// @param hash Value hash of the swap
    function checkSwapIsLocked(bytes32 hash) private view {
        require(swaps[hash] == true, "ERC20Swap: swap has no tokens locked in the contract");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// Copyright 2020 Uniswap team
// Based on: https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/TransferHelper.sol

pragma solidity 0.7.6;

library TransferHelper {
    /// Transfers Ether to an address
    /// @dev This function reverts if transferring the Ether fails
    /// @dev Please note that ".call" forwards all leftover gas which means that sending Ether to accounts and contract is possible but also that you should specify or sanity check the gas limit
    /// @param to Address to which the Ether should be sent
    /// @param amount Amount of Ether to send in WEI
    function transferEther(address payable to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "TransferHelper: could not transfer Ether");
    }

    /// Transfers token to an address
    /// @dev This function reverts if transferring the tokens fails
    /// @dev This function supports non standard ERC20 tokens that have a "transfer" method that does not return a boolean
    /// @param token Address of the token
    /// @param to Address to which the tokens should be transferred
    /// @param value Amount of token that should be transferred in the smallest denomination of the token
    function safeTransferToken(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: could not transfer ERC20 tokens"
        );
    }

    /// Transfers token from one address to another
    /// @dev This function reverts if transferring the tokens fails
    /// @dev This function supports non standard ERC20 tokens that have a "transferFrom" method that does not return a boolean
    /// @dev Keep in mind that "transferFrom" requires an allowance of the "from" address for the caller that is equal or greater than the "value"
    /// @param token Address of the token
    /// @param from Address from which the tokens should be transferred
    /// @param to Address to which the tokens should be transferred
    /// @param value Amount of token that should be transferred in the smallest denomination of the token
    function safeTransferTokenFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: could not transferFrom ERC20 tokens"
        );
    }
}