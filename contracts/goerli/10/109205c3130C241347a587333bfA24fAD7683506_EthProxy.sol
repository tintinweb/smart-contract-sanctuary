pragma solidity ^0.8.0;

import "./ITerabethiaCore.sol";

contract EthProxy {
    // The StarkNet core contract.
    ITerabethiaCore terabethiaCore;

    // The selector of the "deposit" l1_handler.
    uint256 constant CANISTER_ADDRESS = 0x00000000003000F10101;

    /**
      Initializes the contract state.
    */
    constructor(ITerabethiaCore terabethiaCore_) {
        terabethiaCore = terabethiaCore_;
    }

    function withdraw(uint256 amount) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = uint256(uint160(msg.sender));
        payload[1] = amount;

        // Consume the message from the IC
        // This will revert the (Ethereum) transaction if the message does not exist.
        terabethiaCore.consumeMessage(CANISTER_ADDRESS, payload);

        // withdraw eth
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function deposit(uint256 user) external payable {
        require(msg.value >= 1 gwei, "DepositContract: deposit value too low");
        require(
            msg.value % 1 gwei == 0,
            "DepositContract: deposit value not multiple of gwei"
        );

        uint256 deposit_amount = msg.value / 1 gwei;

        require(
            deposit_amount <= type(uint64).max,
            "DepositContract: deposit value too high"
        );

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = user;
        payload[1] = deposit_amount;

        // Send the message to the IC
        terabethiaCore.sendMessage(CANISTER_ADDRESS, payload);
    }
}

pragma solidity ^0.8.0;

interface ITerabethiaCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessage(uint256 to_address, uint256[] calldata payload)
        external
        returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessage(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}