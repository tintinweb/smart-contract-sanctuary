// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {CrowdfundWithEditionsStorage} from "./CrowdfundWithEditionsStorage.sol";
import {ERC20Storage} from "../../../external/ERC20Storage.sol";
import {IERC20Events} from "../../../external/interface/IERC20.sol";

interface ICrowdfundWithEditionsFactory {
    function mediaAddress() external returns (address);

    function logic() external returns (address);

    function editions() external returns (address);

    // ERC20 data.
    function parameters()
        external
        returns (
            address payable fundingRecipient,
            uint256 fundingCap,
            uint256 operatorPercent,
            uint256 feePercentage
        );
}

/**
 * @title CrowdfundWithEditionsProxy
 * @author MirrorXYZ
 */
contract CrowdfundWithEditionsProxy is
    CrowdfundWithEditionsStorage,
    ERC20Storage,
    IERC20Events
{
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address treasuryConfig_,
        address payable operator_,
        string memory name_,
        string memory symbol_
    ) ERC20Storage(name_, symbol_) {
        address logic = ICrowdfundWithEditionsFactory(msg.sender).logic();

        assembly {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }

        emit Upgraded(logic);

        editions = ICrowdfundWithEditionsFactory(msg.sender).editions();
        // Crowdfund-specific data.
        (
            fundingRecipient,
            fundingCap,
            operatorPercent,
            feePercentage
        ) = ICrowdfundWithEditionsFactory(msg.sender).parameters();

        operator = operator_;
        treasuryConfig = treasuryConfig_;
        // Initialize mutable storage.
        status = Status.FUNDING;
    }

    /// @notice Get current logic
    function logic() external view returns (address logic_) {
        assembly {
            logic_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

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

/**
 * @title CrowdfundWithEditionsStorage
 * @author MirrorXYZ
 */
contract CrowdfundWithEditionsStorage {
    /**
     * @notice The two states that this contract can exist in.
     * "FUNDING" allows contributors to add funds.
     */
    enum Status {
        FUNDING,
        TRADING
    }

    // ============ Constants ============

    /// @notice The factor by which ETH contributions will multiply into crowdfund tokens.
    uint16 internal constant TOKEN_SCALE = 1000;

    // ============ Reentrancy ============

    /// @notice Reentrancy constants.
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    /// @notice Current reentrancy status -- used by the modifier.
    uint256 internal reentrancy_status;

    /// @notice The operator has a special role to change contract status.
    address payable public operator;

    /// @notice Receives the funds when calling withdraw. Operator can configure.
    address payable public fundingRecipient;

    /// @notice Treasury configuration.
    address public treasuryConfig;

    /// @notice We add a hard cap to prevent raising more funds than deemed reasonable.
    uint256 public fundingCap;

    /// @notice Fee percentage that the crowdfund pays to the treasury.
    uint256 public feePercentage;

    /// @notice The operator takes some equity in the tokens, represented by this percent.
    uint256 public operatorPercent;

    // ============ Mutable Storage ============

    /// @notice Represents the current state of the campaign.
    Status public status;

    // ============ Tiered Campaigns ============

    /// @notice Address of the editions contract to purchase from.
    address public editions;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title ERC20Storage
 * @author MirrorXYZ
 */
contract ERC20Storage {
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 total number of tokens in circulation
    uint256 public totalSupply;

    /// @notice Initialize total supply to zero.
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        totalSupply = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IERC20 {
    /// @notice EIP-20 token name for this token
    function name() external returns (string calldata);

    /// @notice EIP-20 token symbol for this token
    function symbol() external returns (string calldata);

    /// @notice EIP-20 token decimals for this token
    function decimals() external returns (uint8);

    /// @notice EIP-20 total number of tokens in circulation
    function totalSupply() external returns (uint256);

    /// @notice EIP-20 official record of token balances for each account
    function balanceOf(address account) external returns (uint256);

    /// @notice EIP-20 allowance amounts on behalf of others
    function allowance(address owner, address spender)
        external
        returns (uint256);

    /// @notice EIP-20 approves _spender_ to transfer up to _value_ multiple times
    function approve(address spender, uint256 value) external returns (bool);

    /// @notice EIP-20 transfer _value_ to _to_ from _msg.sender_
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice EIP-20 transfer _value_ to _to_ from _from_
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Events {
    /// @notice EIP-20 Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
}

