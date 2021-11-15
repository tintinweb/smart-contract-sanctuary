// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../Ownable.sol";

contract Beacon is Ownable {
    /// @notice Logic for this contract.
    address public logic;

    /// @notice Emitted when the logic is updated.
    event Updated(address oldLogic, address newLogic);

    constructor(address owner_) Ownable(owner_) {}

    /**
     * @notice Updates logic address.
     */
    function update(address newLogic) public onlyOwner {
        // Ensure that the newLogic contract is not the null address.
        require(newLogic != address(0), "Must specify logic.");

        // Ensure that the logic contract has code via extcodesize.
        uint256 logicSize;
        assembly {
            logicSize := extcodesize(newLogic)
        }
        require(logicSize > 0, "Logic must have contract code.");

        emit Updated(logic, newLogic);

        // Update logic
        logic = newLogic;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }

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
}

