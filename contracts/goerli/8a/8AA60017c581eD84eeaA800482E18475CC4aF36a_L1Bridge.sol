/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
contract L1Bridge is Ownable {
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
    
    function setL2ContractAddress(uint256 _l2ContractAddress) external onlyOwner {
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

    function withdraw(
        uint256 user,
        uint256 token_id,
        uint256 amount)
        external
    {
        // Update the L1 balance.
        userBalances[user][token_id] -= amount;
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
        payload[1] = token_id;
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