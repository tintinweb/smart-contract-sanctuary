// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {Governable} from "../../lib/Governable.sol";
import {BeaconStorage} from "../../lib/upgradable/BeaconStorage.sol";
import {IBeacon} from "../../lib/upgradable/interface/IBeacon.sol";
import {ITreasuryConfig} from "../../interface/ITreasuryConfig.sol";
import {IMirrorTokenLogic} from "./interface/IMirrorTokenLogic.sol";
import {MirrorTokenStorage} from "./MirrorTokenStorage.sol";

/**
 * @title MirrorGovernanceToken
 * @author MirrorXYZ
 *
 *  An ERC20 that grants access to the ENS namespace through a
 *  burn-and-register model.
 */
contract MirrorTokenLogic is
    BeaconStorage,
    Governable,
    MirrorTokenStorage,
    IMirrorTokenLogic
{
    /// @notice Logic version
    uint256 public constant override version = 0;

    // ============ Events ============

    /// @notice Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ============ Modifiers ============

    modifier onlyMinter() {
        require(
            msg.sender == ITreasuryConfig(treasuryConfig).distributionModel() ||
                msg.sender == governor,
            "only active distribution model can mint"
        );
        _;
    }

    constructor(address beacon_, address owner_)
        BeaconStorage(beacon_)
        Governable(owner_)
    {}

    // ============ ERC20 Spec ============

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            // value == 0 || allowance[from][msg.sender] >= value,
            "transfer amount exceeds spender allowance"
        );

        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

    // ============ Minting ============

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);

        emit Mint(to, amount);
    }

    function setTreasuryConfig(address newTreasuryConfig)
        public
        override
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    // ============ Upgradability Utils ============
    function getLogic() public view returns (address proxyLogic) {
        proxyLogic = IBeacon(beacon).logic();
    }

    // ============ Private Utils ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(balanceOf[from] >= value, "transfer amount exceeds balance");

        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;

        emit Transfer(from, to, value);
    }
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

contract BeaconStorage {
    /// @notice Holds the address of the upgrade beacon
    address internal immutable beacon;

    constructor(address beacon_) {
        beacon = beacon_;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IBeacon {
    /// @notice Logic for this contract.
    function logic() external view returns (address);

    /// @notice Emitted when the logic is updated.
    event Update(address oldLogic, address newLogic);

    /// @notice Updates logic address.
    function update(address newLogic) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ITreasuryConfig {
    function treasury() external returns (address payable);

    function distributionModel() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;
import {IGovernable} from "../../../lib/interface/IGovernable.sol";

interface IMirrorTokenLogic is IGovernable {
    function version() external returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function setTreasuryConfig(address newTreasuryConfig) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IENS} from "../../interface/IENS.sol";
import {IMirrorTokenStorage} from "./interface/IMirrorTokenStorage.sol";

/**
 * @title DistributionStorage
 * @author MirrorXYZ
 */
contract MirrorTokenStorage is IMirrorTokenStorage {
    // ============ Immutable ERC20 Attributes ============

    /// @notice EIP-20 token name for this token
    string public constant override name = "Mirror Governance Token";

    /// @notice EIP-20 token symbol for this token
    string public constant override symbol = "MIRROR";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant override decimals = 18;

    // ============ Mutable ERC20 Attributes ============

    /// @notice Total number of tokens in circulation
    uint256 public override totalSupply;

    /// @notice Official record of token balances for each account
    mapping(address => uint256) public override balanceOf;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) public override allowance;

    // ============ Treasury ============

    address public treasuryConfig;
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

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IGovernable} from "../../../lib/interface/IGovernable.sol";

interface IMirrorTokenStorage {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

