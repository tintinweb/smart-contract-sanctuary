// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IOwnableEvents} from "../../lib/Ownable.sol";
import {IPausableEvents} from "../../lib/Pausable.sol";
import {ITreasuryConfig} from "../../interface/ITreasuryConfig.sol";
import {ITributaryRegistry} from "../../interface/ITributaryRegistry.sol";
import {IMirrorTreasury} from "../../interface/IMirrorTreasury.sol";
import {MirrorDutchAuctionProxy} from "./MirrorDutchAuctionProxy.sol";
import {IMirrorDutchAuctionLogic} from "./interface/IMirrorDutchAuctionLogic.sol";

interface IMirrorDutchAuctionFactory {
    /// @notice Emitted when a proxy is deployed
    event MirrorDutchAuctionProxyDeployed(
        address proxy,
        address operator,
        address logic,
        bytes initializationData
    );

    function deploy(
        address operator,
        address tributary,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig
    ) external returns (address proxy);
}

/**
 * @title MirrorDutchAuctionFactory
 * @author MirrorXYZ
 * This contract implements a factory to deploy a simple Dutch Auction
 * proxies with a price reduction mechanism at fixed intervals.
 */
contract MirrorDutchAuctionFactory is
    IMirrorDutchAuctionFactory,
    IOwnableEvents,
    IPausableEvents
{
    /// @notice The contract that holds the Dutch Auction logic
    address public logic;

    /// @notice The contract that holds the treasury configuration
    address public treasuryConfig;

    /// @notice Address that holds the tributary registry for Mirror treasury
    address public tributaryRegistry;

    constructor(
        address logic_,
        address treasuryConfig_,
        address tributaryRegistry_
    ) {
        logic = logic_;
        treasuryConfig = treasuryConfig_;
        tributaryRegistry = tributaryRegistry_;
    }

    function deploy(
        address operator,
        address tributary,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig
    ) external override returns (address proxy) {
        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorDutchAuctionLogic.initialize.selector,
            operator,
            treasuryConfig,
            auctionConfig
        );

        proxy = address(
            new MirrorDutchAuctionProxy{
                salt: keccak256(
                    abi.encode(
                        operator,
                        auctionConfig.recipient,
                        auctionConfig.nft
                    )
                )
            }(logic, initializationData)
        );

        emit MirrorDutchAuctionProxyDeployed(
            proxy,
            operator,
            logic,
            initializationData
        );

        ITributaryRegistry(tributaryRegistry).registerTributary(
            proxy,
            tributary
        );
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IPausableEvents {
    /// @notice Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @notice Emitted when the pause is lifted by `account`.
    event Unpaused(address account);
}

interface IPausable {
    function paused() external returns (bool);
}

contract Pausable is IPausable, IPausableEvents {
    bool public override paused;

    // Modifiers

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /// @notice Initializes the contract in unpaused state.
    constructor(bool paused_) {
        paused = paused_;
    }

    // ============ Internal Functions ============

    function _pause() internal whenNotPaused {
        paused = true;

        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        paused = false;

        emit Unpaused(msg.sender);
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

interface IMirrorTreasury {
    function transferFunds(address payable to, uint256 value) external;

    function transferERC20(
        address token,
        address to,
        uint256 value
    ) external;

    function contributeWithTributary(address tributary) external payable;

    function contribute(uint256 amount) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorDutchAuctionProxy
 * @author MirrorXYZ
 */
contract MirrorDutchAuctionProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Stores implementation logic.
     * @param implementation - the implementation holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address implementation, bytes memory initializationData) {
        // Delegatecall into the relayer, supplying initialization calldata.
        (bool ok, ) = implementation.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    /**
     * @notice When any function is called on this contract, we delegate to
     * the logic contract stored in the implementation storage slot.
     */
    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorDutchAuctionLogic {
    /// @notice Emitted when the auction starts
    event AuctionStarted(uint256 blockNumber);

    /// @notice Emitted when a withdrawal takes place.
    event Withdrawal(address recipient, uint256 amount, uint256 fee);

    /// @notice Emitted when a bid takes place.
    event Bid(address recipient, uint256 price, uint256 tokenId);

    struct AuctionConfig {
        uint256[] prices;
        uint256 interval;
        uint256 startTokenId;
        uint256 endTokenId;
        address recipient;
        address nft;
        address nftOwner;
    }

    /// @notice Get a list of prices
    function prices(uint256 index) external returns (uint256);

    /// @notice Get the time interval in blocks
    function interval() external returns (uint256);

    /// @notice Get the current tokenId
    function tokenId() external returns (uint256);

    /// @notice Get the last tokenId
    function endTokenId() external returns (uint256);

    /// @notice Get total time elapsed since auction started
    function globalTimeElapsed() external returns (uint256);

    /// @notice Get the recipient of the funds for withdrawals
    function recipient() external returns (address);

    /// @notice Get whether an account has purchased
    function purchased(address account) external returns (bool);

    /// @notice Get the block at which auction started
    function auctionStartBlock() external returns (uint256);

    /// @notice Get the block at which auction was paused, only set if auction has started
    function pauseBlock() external returns (uint256);

    /// @notice Get the block at which auction was unpaused
    function unpauseBlock() external returns (uint256);

    /// @notice Get the contract that holds the NFTs
    function nft() external returns (address);

    /// @notice Set the owner of the nfts transfered
    function nftOwner() external returns (address);

    /// @notice Get the ending price
    function endingPrice() external returns (uint256);

    /// @notice Change the withdrawal recipient
    function changeRecipient(address newRecipient) external;

    /// @notice Get the contract that holds the treasury configuration
    function getAllPrices() external returns (uint256[] memory);

    /**
     * @dev This contract is used as the logic for proxies. Hence we include
     * the ability to call "initialize" when deploying a proxy to set initial
     * variables without having to define them and implement in the proxy's
     * constructor. This function reverts if called after deployment.
     */
    function initialize(
        address owner_,
        address treasuryConfig_,
        IMirrorDutchAuctionLogic.AuctionConfig memory auctionConfig_
    ) external;

    /// @notice Pause auction
    function pause() external;

    /// @notice Unpause auction
    function unpause() external;

    /// @notice Withdraw all funds and destroy contract
    function cancel() external;

    /// @notice Current price. Zero if auction has not started.
    function price() external view returns (uint256);

    /// @notice Current time elapsed.
    function time() external view returns (uint256);

    /**
     * @notice Bid for an NFT. If the price is met transfer NFT to sender.
     * If price drops before the transaction mines, refund value.
     */
    function bid() external payable;

    /// @notice Withdraw all funds, and pay fee
    function withdraw() external;
}