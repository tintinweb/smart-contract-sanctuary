/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity ^0.6.11;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) virtual external;

    /**
      Consumes a message that was sent from an L2 contract.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) virtual external;
}

/**
  Bridge contract for token to be deposited into and withdrawn from L2 contract.
*/
contract L1Bridge {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    // The corresponding L2 contract
    uint256 public l2ContractAddress;

    // Mapping of user => token => balance
    mapping (uint256 => mapping (uint256 => uint256)) public userBalances;

    // The selector of the "deposit" l1_handler.
    uint256 constant DEPOSIT_SELECTOR =
        352040181584456735608515580760888541466059565068553383579463728554843487745;

    /**
      Initializes the contract state.
    */
    constructor(
        IStarknetCore starknetCore_)
        public
    {
        starknetCore = starknetCore_;
    }
    
    function setL2ContractAddress(uint256 _l2ContractAddress) external {
        require(l2ContractAddress == 0, "Already set L2 contract address");
        l2ContractAddress = _l2ContractAddress;
    }

    function deposit(
        uint256 user,
        uint256 token_id,
        uint256 amount)
        external
    {
        // Update the L1 balance.
        userBalances[user][token_id] += amount;
    }

    function withdrawFromL2(
        uint256 user,
        uint256 token_id,
        uint256 amount)
        external
    {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = user;
        payload[0] = token_id;
        payload[2] = amount;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        userBalances[user][token_id] += amount;
    }

    function depositToL2(
        uint256 user,
        uint256 token_id,
        uint256 amount)
        external
    {
        require(amount < 2 ** 64, "Invalid amount.");
        require(amount <= userBalances[user][token_id], "The user's token balance is not large enough.");

        // Update the L1 balance.
        userBalances[user][token_id] -= amount;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = user;
        payload[1] = token_id;
        payload[2] = amount;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }
}