// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {ITreasuryConfig} from "../interface/ITreasuryConfig.sol";
import {Governable} from "../lib/Governable.sol";

contract TreasuryConfig is ITreasuryConfig, Governable {
    // ============ Mutable Storage ============

    address payable public override treasury;
    address public override distributionModel;

    // ============ Constructor ============

    constructor(
        address owner_,
        address distributionModel_,
        address payable treasury_
    ) Governable(owner_) {
        treasury = treasury_;
        distributionModel = distributionModel_;
    }

    // ============ Configuration ============

    function setTreasury(address payable newTreasury) public onlyGovernance {
        treasury = newTreasury;
    }

    function setDistributionModel(address newDistributionModel)
        public
        onlyGovernance
    {
        distributionModel = newDistributionModel;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";
import {IGovernable} from "../lib/interface/IGovernable.sol";

contract Governable is Ownable, IGovernable {
    // ============ Mutable Storage ============

    // Mirror governance contract.
    address public override governor;

    // ============ Modifiers ============

    modifier onlyGovernance() {
        require(isOwner() || isGovernor(), "caller is not governance");
        _;
    }

    modifier onlyGovernor() {
        require(isGovernor(), "caller is not governor");
        _;
    }

    // ============ Constructor ============

    constructor(address owner_) Ownable(owner_) {}

    // ============ Administration ============

    function changeGovernor(address governor_) public override onlyGovernance {
        governor = governor_;
    }

    // ============ Utility Functions ============

    function isGovernor() public view override returns (bool) {
        return msg.sender == governor;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

