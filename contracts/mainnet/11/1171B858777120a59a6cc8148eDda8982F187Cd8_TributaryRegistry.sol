// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {ITributaryRegistry} from "../interface/ITributaryRegistry.sol";
import {Governable} from "../lib/Governable.sol";

/**
 * Allows a registrar contract to register a new proxy as a block
 * that directs Mirror Token distribution to a tributary.
 * Ensures that the tributary is an Mirror DAO, and that only a valid
 * "Mirror Economic Block" created by a registered registrar, can contribute ETH
 * to the treasury. Otherwise, anyone could send ETH to the treasury to mint Mirror tokens.
 * @author MirrorXYZ
 */
contract TributaryRegistry is Governable, ITributaryRegistry {
    // ============ Mutable Storage ============

    // E.g. crowdfund factory. Can register producer => tributary.
    mapping(address => bool) allowedRegistrar;
    // E.g. crowdfund proxy => Mirror DAO.
    mapping(address => address) public override producerToTributary;
    // E.g. auctions house. Can send funds and specify tributary directly.
    mapping(address => bool) public override singletonProducer;

    // ============ Modifiers ============

    modifier onlyRegistrar() {
        require(allowedRegistrar[msg.sender], "sender not registered");
        _;
    }

    constructor(address owner_) Governable(owner_) {}

    // ============ Configuration ============

    function addRegistrar(address registrar) public override onlyGovernance {
        allowedRegistrar[registrar] = true;
    }

    function removeRegistrar(address registrar) public override onlyGovernance {
        delete allowedRegistrar[registrar];
    }

    function addSingletonProducer(address producer)
        public
        override
        onlyGovernance
    {
        singletonProducer[producer] = true;
    }

    function removeSingletonProducer(address producer)
        public
        override
        onlyGovernance
    {
        delete singletonProducer[producer];
    }

    // ============ Tributary Configuration ============

    /**
     * Register a producer's (crowdfund, edition etc) tributary. Can only be called
     * by an allowed registrar.
     */
    function registerTributary(address producer, address tributary)
        public
        override
        onlyRegistrar
    {
        producerToTributary[producer] = tributary;
    }

    /**
     * Allows the current tributary to update to a new tributary.
     */
    function changeTributary(address producer, address newTributary)
        public
        override
        onlyRegistrar
    {
        // Check that the sender of the transaction is the current tributary.
        require(
            msg.sender == producerToTributary[producer],
            "only for current tributary"
        );

        // Allow the current tributary to update to a new tributary.
        producerToTributary[producer] = newTributary;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITributaryRegistry {
    function addRegistrar(address registrar) external;

    function removeRegistrar(address registrar) external;

    function addSingletonProducer(address producer) external;

    function removeSingletonProducer(address producer) external;

    function registerTributary(address producer, address tributary) external;

    function producerToTributary(address producer)
        external
        returns (address tributary);

    function singletonProducer(address producer) external returns (bool);

    function changeTributary(address producer, address newTributary) external;
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

