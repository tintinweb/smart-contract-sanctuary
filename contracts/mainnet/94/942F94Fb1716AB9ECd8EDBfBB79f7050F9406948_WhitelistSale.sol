// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";

import {IERC20} from "../token/IERC20.sol";

contract WhitelistSale is Ownable {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== Struct ========== */

    struct Participant {
        uint256 allocation;
        uint256 spent;
    }

    /* ========== Variables ========== */

    IERC20 public currency;

    mapping (address => Participant) public participants;

    bool public saleOpen;

    /* ========== Events ========== */

    event AllocationClaimed(address user, uint256 amount);

    event AllocationSet(address user, uint256 amount);

    event SaleStatusUpdated(bool status);

    /* ========== Constructor ========== */

    constructor(address currencyAddress) public {
        currency = IERC20(currencyAddress);
        saleOpen = false;
    }

    /* ========== Public Functions ========== */

    function claimAllocation(
        uint256 amount
    )
        external
    {
        // Get their total spend till date
        uint256 participantSpent = participants[msg.sender].spent.add(amount);

        require(
            participantSpent <= participants[msg.sender].allocation,
            "You cannot spend more than your allocation"
        );

        require(
            saleOpen,
            "The sale is not currently open"
        );

        // Increase the user's spend amount otherwise they can keep purchasing
        participants[msg.sender].spent = participantSpent;

        // Transfer the funds to the owner, no funds will be stored in this contract directly.
        currency.safeTransferFrom(
            msg.sender,
            owner(),
            amount
        );

        emit AllocationClaimed(msg.sender, amount);
    }

    function getParticipant(
        address participant
    )
        public
        view
        returns (Participant memory)
    {
        return participants[participant];
    }

    /* ========== Admin Functions ========== */

    function setAllocation(
        address[] calldata users,
        uint256[] calldata allocations
    )
        external
        onlyOwner
    {
        // If there is a mismatch something hasn't been done correctly
        require(
            users.length == allocations.length,
            "The users and amounts do not match"
        );

        for (uint256 i = 0; i < users.length; i++) {
            participants[users[i]].allocation = allocations[i];

            emit AllocationSet(users[i], allocations[i]);
        }
    }

    function updateSaleStatus(
        bool status
    )
        external
        onlyOwner
    {
        require(
            saleOpen != status,
            "Cannot re-set the same status"
        );

        saleOpen = status;

        emit SaleStatusUpdated(status);
    }
}