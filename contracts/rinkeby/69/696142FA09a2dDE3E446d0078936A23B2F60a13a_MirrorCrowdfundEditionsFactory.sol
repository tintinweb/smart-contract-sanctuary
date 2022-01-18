// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {Clones} from "../../lib/Clones.sol";
import {IMirrorCrowdfundEditionsFactory, IMirrorCrowdfundEditionsFactoryEvents} from "./interface/IMirrorCrowdfundEditionsFactory.sol";
import {IMirrorCrowdfundEditions} from "./interface/IMirrorCrowdfundEditions.sol";

/**
 * @title MirrorCrowdfundEditionsFactory
 * @author MirrorXYZ
 * The MirrorCrowdfundEditionsFactory contract is used to deploy edition proxies.
 */
contract MirrorCrowdfundEditionsFactory is
    IMirrorCrowdfundEditionsFactoryEvents,
    IMirrorCrowdfundEditionsFactory
{
    /// @notice Address that holds the logic logic for Crowdfunds
    address public logic;

    constructor(address logic_) {
        logic = logic_;
    }

    // ======== Deploy function =========

    /**
     * @notice Deploys a crowdfund proxy, creates a crowdfund, and
     * registers the new proxies tributary. Emits a MirrorProxyDeployed
     * event with the crowdfund-logic address.
     */
    function deployAndCreateEditions(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IMirrorCrowdfundEditions.EditionTier[] memory tiers
    ) external override returns (address proxy) {
        proxy = Clones.cloneDeterministic(
            logic,
            keccak256(abi.encode(owner, name_, symbol_, baseURI_))
        );

        IMirrorCrowdfundEditions(proxy).initialize(
            owner,
            msg.sender, // operator is the crowdfund contract.
            name_,
            symbol_,
            baseURI_,
            tiers
        );

        emit EditionsProxyDeployed(proxy, msg.sender, owner, logic);
    }

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(logic_, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev Copy of OpenZeppelin's Clones contract
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditions} from "./IMirrorCrowdfundEditions.sol";

interface IMirrorCrowdfundEditionsFactoryEvents {
    event EditionsProxyDeployed(
        address indexed proxy,
        address indexed operator,
        address indexed owner,
        address logic
    );
}

interface IMirrorCrowdfundEditionsFactory {
    function deployAndCreateEditions(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        IMirrorCrowdfundEditions.EditionTier[] memory tiers
    ) external returns (address proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IMirrorCrowdfundEditionStructs} from "./IMirrorCrowdfundEditionStructs.sol";

interface IMirrorCrowdfundEditionsEvents {
    /// @notice Create edition
    event EditionCreated(
        uint256 purchasableAmount,
        uint256 price,
        uint256 editionId
    );

    event OperatorChanged(
        address indexed proxy,
        address oldOperator,
        address newOperator
    );

    event EditionLimitSet(uint256 indexed editionId, uint256 limit);
}

interface IMirrorCrowdfundEditions is IMirrorCrowdfundEditionStructs {
    function initialize(
        address owner_,
        address operator_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        EditionTier[] memory tiers
    ) external;

    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    /// @notice Create edition
    function createEditions(EditionTier[] memory tiers) external;

    function mint(uint256 editionId, address to)
        external
        returns (uint256 tokenId);

    function unpause(uint256 editionId) external;

    function pause(uint256 editionId) external;

    function purchase(uint256 editionId, address recipient)
        external
        returns (uint256 tokenId);

    function editionPrice(uint256 editionId) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface IMirrorCrowdfundEditionStructs {
    /// @notice Statuses for funding and redeeming.
    enum FundingStatus {
        CONTRIBUTE,
        CONTRIBUTE_WITH_PROOF,
        PAUSED,
        CLOSED,
        REFUND,
        REDEEM_WITH_PROOF
    }

    struct Edition {
        // How many tokens are available to purchase in a campaign?
        uint256 purchasableAmount;
        // What is the price per token in the campaign?
        uint256 price;
        // What is the content hash of the token's content?
        bytes32 contentHash;
        // How many have currently been minted in total?
        uint256 numMinted;
        // How many have been purchased?
        uint256 numPurchased;
        // Is this edition paused?
        bool paused;
        // Optionally limit the number of tokens that can be minted.
        uint256 limit;
    }

    struct EditionTier {
        // When setting up an EditionTier, specify the supply limit.
        uint256 quantity;
        uint256 price;
        bytes32 contentHash;
    }

    // ERC20 Attributes.
    struct ERC20Attributes {
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        uint256 nonce;
    }

    // Initialization configuration.
    struct CrowdfundInitConfig {
        address owner;
        uint256 exchangeRate;
        address fundingRecipient;
        FundingStatus fundingStatus;
    }

    struct CampaignConfig {
        string name;
        string symbol;
        uint256 fundingCap;
    }

    struct Campaign {
        address editionsProxy;
        uint256 fundingCap;
        uint256 amountRaised;
    }
}