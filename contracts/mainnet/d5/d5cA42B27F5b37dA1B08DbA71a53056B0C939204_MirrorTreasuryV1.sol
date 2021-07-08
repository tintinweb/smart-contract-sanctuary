/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// ___________________________________
// |#######====================#######|
// |#(1)*   Mirror Treasury V1   *(1)#|
// |#**          /===\             **#|
// |*# {M}      |     |             #*|
// |#*          |     |    O N E    *#|
// |#(1)         \===/            (1)#|
// |##=========VERSION ONE==========##|
// ------------------------------------

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.5;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
}

interface IFeeProducer {
    function updateTreasury(address payable newTreasury) external;

    function queueFeeUpdate(uint16 newFee) external;

    function executeFeeUpdate() external;
}

contract MirrorTreasuryV1 {
    // ============ Mutable Ownership Configuration ============

    address public owner;
    /**
     * @dev Allows for two-step ownership transfer, whereby the next owner
     * needs to accept the ownership transfer explicitly.
     */
    address public nextOwner;

    // ============ Events ============

    event Transfer(address indexed from, address indexed to, uint256 value);
    event ERC20Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    // ============ Ownership ============

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    /**
     * @dev Allows a new account (`newOwner`) to accept ownership.
     * Can only be called by the current owner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel a transfer of ownership to a new account.
     * Can only be called by the current owner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Transfers ownership of the contract to the caller.
     * Can only be called by a new potential owner set by the current owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    // ============ Funds Administration ============

    function transferFunds(address payable to, uint256 value)
        external
        onlyOwner
    {
        _sendFunds(to, value);
        emit Transfer(address(this), to, value);
    }

    function transferERC20(
        address token,
        address payable to,
        uint256 value
    ) external onlyOwner {
        IERC20(token).transfer(to, value);
        emit ERC20Transfer(token, address(this), to, value);
    }

    // ============ Producer Administration ============

    function updateProducerTreasury(
        address producer,
        address payable newTreasury
    ) public {
        IFeeProducer(producer).updateTreasury(newTreasury);
    }

    function queueProducerFeeUpdate(address producer, uint16 newFee) public {
        IFeeProducer(producer).queueFeeUpdate(newFee);
    }

    function executeProducerFeeUpdate(address producer) public {
        IFeeProducer(producer).executeFeeUpdate();
    }

    // ============ Private Utils ============

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }
}