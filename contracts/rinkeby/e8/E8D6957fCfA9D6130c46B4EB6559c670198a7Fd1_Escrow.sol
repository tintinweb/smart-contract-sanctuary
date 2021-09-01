/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// File: Escrow.sol

contract Escrow {
    // Escrow State Variable
    enum State {
        DEFAULT,
        ALLOWED,
        COMPLETE
    }

    // Sets whether anyone can complete Escrow or if it's private
    enum Visibility {
        PRIVATE,
        PUBLIC
    }

    // The visibility of the Escrow
    Visibility public visibility;

    // States of the current escrow
    mapping(address => State) public stateOfGivenAddress;

    // Owner of the Escrow trade
    address public owner;

    // Price of the escrow asset
    uint256 public price;

    // Events
    event UserWhitelisted(address indexed receiver);
    event EscrowComplete(address indexed receiver, uint256 indexed amountPaid);

    /**
     * @dev Initiates the contract with a specified owner.
     * @notice This differs from regular contract owners as the owner may not
     * always be `msg.sender` unless explicity specified.
     * @param _owner             Owner of the Escrow asset
     * @param _public            Sets whether the Escrow is public or private
     * @param initialPriceInWei  Initial price of the Escrow asset (in Wei)
     */
    constructor(
        address _owner,
        bool _public,
        uint256 initialPriceInWei
    ) {
        owner = _owner;
        visibility = _public ? Visibility.PUBLIC : Visibility.PRIVATE;
        price = initialPriceInWei;
    }

    /**
     * @dev Modifier for functions that only the contract owner may call.
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract may call this function"
        );
        _;
    }

    /**
     * @dev Checks whether the receiver is allowed to purchase the escrow
     * asset depending on if either the escrow is public or the reciever has
     * been added to the whitelist.
     */
    modifier receiverAllowed() {
        require(
            visibility == Visibility.PUBLIC ||
                stateOfGivenAddress[address(msg.sender)] == State.ALLOWED,
            "The receiver is not allowed to complete this Escrow"
        );
        _;
    }

    /**
     * @dev Allows the specified address to fulfill Escrow.
     * @notice This is usually only used when the contract's `visibility` is
     * set to `Private`, but can be used regardless. This function cannot be
     * called if the Escrow is complete.
     * @param receiver  The address of the receiver that's allowed to complete
     * the escrow.
     */
    function whitelistReceiver(address receiver) public onlyOwner {
        require(stateOfGivenAddress[address(receiver)] != State.COMPLETE);
        stateOfGivenAddress[address(receiver)] = State.ALLOWED;
        emit UserWhitelisted(receiver);
    }

    /**
     * @dev Sets the price for the asset being stored in Escrow.
     * @param priceInWei    The price (in Wei) of the asset.
     */
    function setEscrowPrice(uint256 priceInWei) public onlyOwner {
        price = priceInWei;
    }

    /**
     * @dev Fulfills the payment requirement for the escrow asset.
     * @notice The payment is allowed to be GREATER than the actual set price.
     */
    function completePayment() public payable receiverAllowed {
        require(
            msg.value >= price,
            "The payment is not sufficient to complete the Escrow"
        );
        setCompleteForAddress(msg.sender);
    }

    /**
     * @dev Forces the completion of the escrow for a specific address.
     * @notice Can only be called by the contract owner.
     */
    function forceCompletionForAddress(address _address) public onlyOwner {
        setCompleteForAddress(_address);
    }

    /**
     * @dev Sets the state of the escrow for a particular address to
     * "Complete".
     * @param _address  The address of the receiver.
     */
    function setCompleteForAddress(address _address) private {
        stateOfGivenAddress[_address] = State.COMPLETE;
        emit EscrowComplete(_address, msg.value);
    }

    /**
     * @dev Withdraws all funds from the contract.
     * @param receiver  The address that will receive all of the contract's
     * funds.
     */
    function withdrawAllFunds(address receiver) external onlyOwner {
        payable(receiver).transfer(payable(address(this)).balance);
    }
}