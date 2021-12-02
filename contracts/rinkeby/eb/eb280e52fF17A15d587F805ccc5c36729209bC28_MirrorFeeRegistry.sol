// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Governable} from "../lib/Governable.sol";

interface IMirrorFeeRegistry {
    function maxFee() external returns (uint256);

    function globalFee() external returns (uint256);

    function waivedFee(address account) external returns (bool);

    function customFee(address account) external returns (uint256);

    function getFee() external view returns (uint256);

    function getProducerFee(address account) external view returns (uint256);

    function updateFee(uint256 newFee) external;

    function waiveFee(address account) external;
}

/**
 * @title MirrorFeeRegistry
 * @author MirrorXYZ
 */
contract MirrorFeeRegistry is IMirrorFeeRegistry, Governable {
    uint256 public override maxFee = 500;

    /// @notice Global fee can be updated by governance
    uint256 public override globalFee = 250;

    /// @notice Map if an account can pay no fee
    mapping(address => bool) public override waivedFee;

    /// @notice Map of account to customFee fee
    mapping(address => uint256) public override customFee;

    constructor(address owner_) Governable(owner_) {}

    function getFee() external view override returns (uint256) {
        return _getFee(msg.sender);
    }

    function getProducerFee(address account)
        external
        view
        override
        returns (uint256)
    {
        return _getFee(account);
    }

    function updateFee(uint256 newFee) external override onlyGovernance {
        require(newFee < maxFee, "must be less than max fee");

        globalFee = newFee;
    }

    function waiveFee(address account) external override onlyGovernance {
        waivedFee[account] = true;
    }

    function _getFee(address account) internal view returns (uint256) {
        if (waivedFee[account]) {
            return 0;
        }

        if (customFee[account] > 0) {
            return customFee[account];
        }

        return globalFee;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Ownable} from "../lib/Ownable.sol";

interface IGovernable {
    function changeGovernor(address governor_) external;

    function isGovernor() external view returns (bool);

    function governor() external view returns (address);
}

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

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

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
        _renounceOwnership();
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

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }
}