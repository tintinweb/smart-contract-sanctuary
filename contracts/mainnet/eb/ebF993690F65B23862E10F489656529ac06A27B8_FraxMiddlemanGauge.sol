// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== FraxMiddlemanGauge ========================
// ====================================================================
// Looks at the gauge controller contract and pushes out FXS rewards once
// a week to the gauges (farms).
// This contract is what gets added to the gauge as a 'slice'

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IFraxGaugeFXSRewardsDistributor.sol";
import "./IERC20EthManager.sol";
import "./IRootChainManager.sol";
import "./IWormhole.sol";
import './TransferHelper.sol';
import "./Owned.sol";
import "./ReentrancyGuard.sol";

contract FraxMiddlemanGauge is Owned, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    // Instances and addresses
    address public reward_token_address = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0; // FXS
    address public rewards_distributor_address;

    // Informational
    string public name;

    // Admin addresses
    address public timelock_address;

    // Gauge-related
    address public bridge_address;
    uint256 public bridge_type;
    address public destination_address_override;
    string public non_evm_destination_address;

    // Tracking
    uint32 public fake_nonce;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner || msg.sender == timelock_address, "Not owner or timelock");
        _;
    }

    modifier onlyRewardsDistributor() {
        require(msg.sender == rewards_distributor_address, "Not rewards distributor");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _timelock_address,
        address _rewards_distributor_address,
        address _bridge_address,
        uint256 _bridge_type,
        address _destination_address_override,
        string memory _non_evm_destination_address,
        string memory _name
    ) Owned(_owner) {
        timelock_address = _timelock_address;

        rewards_distributor_address = _rewards_distributor_address;

        bridge_address = _bridge_address;
        bridge_type = _bridge_type;
        destination_address_override = _destination_address_override;
        non_evm_destination_address = _non_evm_destination_address;

        name = _name;

        fake_nonce = 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Callable only by the rewards distributor
    function pullAndBridge(uint256 reward_amount) external onlyRewardsDistributor nonReentrant {
        require(bridge_address != address(0), "Invalid bridge address");

        // Pull in the rewards from the rewards distributor
        TransferHelper.safeTransferFrom(reward_token_address, rewards_distributor_address, address(this), reward_amount);

        address address_to_send_to = address(this);
        if (destination_address_override != address(0)) address_to_send_to = destination_address_override;

        if (bridge_type == 0) {
            // Avalanche [AB]
            TransferHelper.safeTransfer(reward_token_address, address_to_send_to, reward_amount);
        }
        else if (bridge_type == 1) {
            // BSC
            TransferHelper.safeTransfer(reward_token_address, address_to_send_to, reward_amount);
        }
        else if (bridge_type == 2) {
            // Fantom [Multichain / Anyswap]
            // Bridge is 0xC564EE9f21Ed8A2d8E7e76c085740d5e4c5FaFbE
            TransferHelper.safeTransfer(reward_token_address, address_to_send_to, reward_amount);
        }
        else if (bridge_type == 3) {
            // Polygon
            // Bridge is 0xA0c68C638235ee32657e8f720a23ceC1bFc77C77
            // Interesting info https://blog.cryption.network/cryption-network-launches-cross-chain-staking-6cf000c25477

            // Approve
            IRootChainManager rootChainMgr = IRootChainManager(bridge_address);
            bytes32 tokenType = rootChainMgr.tokenToType(reward_token_address);
            address predicate = rootChainMgr.typeToPredicate(tokenType);
            ERC20(reward_token_address).approve(predicate, reward_amount);
            
            // DepositFor
            bytes memory depositData = abi.encode(reward_amount);
            rootChainMgr.depositFor(address_to_send_to, reward_token_address, depositData);
        }
        else if (bridge_type == 4) {
            // Solana
            // Wormhole Bridge is 0xf92cD566Ea4864356C5491c177A430C222d7e678

            revert("Not supported yet");

            // // Approve
            // ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // // lockAssets
            // require(non_evm_destination_address != 0, "Invalid destination");
            // // non_evm_destination_address = base58 -> hex
            // // https://www.appdevtools.com/base58-encoder-decoder
            // IWormhole(bridge_address).lockAssets(
            //     reward_token_address,
            //     reward_amount,
            //     non_evm_destination_address,
            //     1,
            //     fake_nonce,
            //     false
            // );
        }
        else if (bridge_type == 5) {
            // Harmony
            // Bridge is at 0x2dccdb493827e15a5dc8f8b72147e6c4a5620857

            // Approve
            ERC20(reward_token_address).approve(bridge_address, reward_amount);

            // lockToken
            IERC20EthManager(bridge_address).lockToken(reward_token_address, reward_amount, address_to_send_to);
        }

        fake_nonce += 1;
    }

    /* ========== RESTRICTED FUNCTIONS - Owner or timelock only ========== */
    
    // Added to support recovering LP Rewards and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function setTimelock(address _new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = _new_timelock;
    }

    function setBridgeInfo(address _bridge_address, uint256 _bridge_type, address _destination_address_override, string memory _non_evm_destination_address) external onlyByOwnerOrGovernance {
        _bridge_address = bridge_address;
        
        // 0: Avalanche
        // 1: BSC
        // 2: Fantom
        // 3: Polygon
        // 4: Solana
        // 5: Harmony
        bridge_type = _bridge_type;

        // Overridden cross-chain destination address
        destination_address_override = _destination_address_override;

        // Set bytes32 / non-EVM address on the other chain, if applicable
        non_evm_destination_address = _non_evm_destination_address;
        
        emit BridgeInfoChanged(_bridge_address, _bridge_type, _destination_address_override, _non_evm_destination_address);
    }

    function setRewardsDistributor(address _rewards_distributor_address) external onlyByOwnerOrGovernance {
        rewards_distributor_address = _rewards_distributor_address;
    }

    /* ========== EVENTS ========== */

    event RecoveredERC20(address token, uint256 amount);
    event BridgeInfoChanged(address bridge_address, uint256 bridge_type, address destination_address_override, string non_evm_destination_address);
}