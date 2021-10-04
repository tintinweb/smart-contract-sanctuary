/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


contract Contract {
    struct Purchase {
        bytes32 receivePublicKey;
        bytes encryptedSymmetricKey;
        bytes baitIdSignature;
    }

    struct Sale {
        address sellerAddress;
        uint256 price;
        mapping(address => Purchase) purchases;
        bytes32[] checksums;
    }

    address private contractCreator;

    mapping(bytes16 => Sale) public sales;
    mapping(address => uint) public balances;
    mapping(address => uint) public nonces;

    // ========================= Only for test purpose =========================

    mapping(address => bool) private testBonus;

    function syncTestBonus(address userAddress) private {
        if (!testBonus[userAddress]) {
            balances[userAddress] += 100;
            testBonus[userAddress] = true;
        }
    }

    // =========================================================================

    constructor () {
        contractCreator = msg.sender;
    }

    function sell(
        address sellerAddress,
        bytes16 baitId,
        uint256 price,
        bytes32[] memory checksums,
        uint256 expirationTimeSeconds,
        bytes memory dataHashSignature
    ) public
    {
        syncTestBonus(sellerAddress);

        require(msg.sender == contractCreator, "You are not authorized to perform this action.");
        require(price > 0, "Price must be positive.");
        require(sales[baitId].price == 0, "Sale for this bait already exist.");
        require(checksums.length < 1 + 5, "Too many checksums.");
        require(block.timestamp < expirationTimeSeconds, "Transaction is expired.");

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                price, checksums, expirationTimeSeconds, nonces[sellerAddress]
            )
        );
        require(getSigner(dataHash, dataHashSignature) == sellerAddress, "Incorrect signature.");

        sales[baitId].sellerAddress = sellerAddress;
        sales[baitId].price = price;
        sales[baitId].checksums = checksums;
        nonces[sellerAddress] += 1;
    }

    function buy(
        address buyerAddress,
        bytes16 baitId,
        bytes32 receivePublicKey,
        uint256 expirationTimeSeconds,
        bytes memory dataHashSignature
    ) public
    {
        syncTestBonus(buyerAddress);

        require(msg.sender == contractCreator, "You are not authorized to perform this action.");
        require(sales[baitId].price != 0, "Sale for this bait does not exist.");
        require(sales[baitId].sellerAddress != buyerAddress, "You cannot purchase your baits.");
        require(sales[baitId].purchases[buyerAddress].receivePublicKey == bytes32(0), "You already purchased this baits.");
        require(balances[buyerAddress] >= sales[baitId].price, "Insufficient balance.");

        require(block.timestamp < expirationTimeSeconds, "Transaction is expired.");

        bytes32 dataHash = keccak256(abi.encodePacked(baitId, receivePublicKey, expirationTimeSeconds, nonces[buyerAddress]));
        require(getSigner(dataHash, dataHashSignature) == buyerAddress, "Incorrect signature.");


        sales[baitId].purchases[buyerAddress].receivePublicKey = receivePublicKey;

        balances[buyerAddress] -= sales[baitId].price;
        balances[contractCreator] += sales[baitId].price;
        nonces[buyerAddress] += 1;
    }

    function supply(
        address sellerAddress,
        bytes16 baitId,
        address buyerAddress,
        bytes memory encryptedSymmetricKey,
        uint256 expirationTimeSeconds,
        bytes memory dataHashSignature
    ) public
    {
        require(msg.sender == contractCreator, "You are not authorized to perform this action.");
        require(sales[baitId].price != 0, "Sale for this bait does not exist.");
        require(sales[baitId].purchases[buyerAddress].receivePublicKey != bytes32(0), "This user did not purchased your bait.");
        require(sales[baitId].purchases[buyerAddress].encryptedSymmetricKey.length == 0, "You already supplied this purchase.");
        require(encryptedSymmetricKey.length == 72, "Encrypted symmetric key must be 72 bytes value.");

        require(block.timestamp < expirationTimeSeconds, "Transaction is expired.");

        bytes32 dataHash = keccak256(abi.encodePacked(baitId, buyerAddress, encryptedSymmetricKey, expirationTimeSeconds, nonces[sellerAddress]));
        require(getSigner(dataHash, dataHashSignature) == buyerAddress, "Incorrect signature.");

        sales[baitId].purchases[buyerAddress].encryptedSymmetricKey = encryptedSymmetricKey;
        balances[contractCreator] -= sales[baitId].price;
        balances[sales[baitId].sellerAddress] += sales[baitId].price;
        nonces[sellerAddress] += 1;
    }

    function getSigner(bytes32 dataHash, bytes memory dataHashSignature) private pure returns (address) {
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(dataHashSignature);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory signature) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length.");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }


    //    event Sent(address from, address to, uint amount);
    //    error InsufficientBalance(uint requested, uint available);
    //
    //    function send(address receiver, uint amount) public {
    //        if (amount > balances[msg.sender])
    //            revert InsufficientBalance({
    //                requested: amount,
    //                available: balances[msg.sender]
    //            });
    //
    //        balances[msg.sender] -= amount;
    //        balances[receiver] += amount;
    //        emit Sent(msg.sender, receiver, amount);
    //    }
    //
    //    function verify_signature(address user_address, uint8 v, bytes32 r, bytes32 s, bytes32 hash) external {
    //        require(ecrecover(hash, v, r, s) == user_address, "Invalid signature.");
    //    }
    //
    //     function getSale(address account_address) public view returns (bytes16, uint256, bytes memory) {
    //         return (
    //             sales[account_address].bait_id,
    //             sales[account_address].price,
    //             sales[account_address].symmetric_key_hash
    //         );
    //     }
}