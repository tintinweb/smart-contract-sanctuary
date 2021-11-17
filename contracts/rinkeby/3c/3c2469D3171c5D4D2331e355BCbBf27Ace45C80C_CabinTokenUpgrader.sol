// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {IERC20} from "../../external/interface/IERC20.sol";

/**
 * @title CabinTokenUpgrader
 * @author MirrorXYZ
 * @notice This contract allows swapping a legacy ERC20 token for an upgraded one.
 */
contract CabinTokenUpgrader {
    // ============ Immutable Storage ============

    address public immutable legacyAddress;
    address public immutable targetAddress;

    // ============ Mutable Storage ============

    uint256 public totalMigrated;

    // ============ Events ============

    event Upgraded(address owner, uint256 amount);

    // ============ Constructor ============

    constructor(address legacyAddress_, address targetAddress_) {
        legacyAddress = legacyAddress_;
        targetAddress = targetAddress_;
    }

    // ============ Public Functions ============

    // Burns the legacy token, and distributes the new one.
    function upgrade(address upgrader, uint256 amount) public {
        // Burn the legacy token, for the given amount.
        IERC20(legacyAddress).transferFrom(upgrader, address(this), amount);
        IERC20(targetAddress).transfer(upgrader, amount);
        // Keep track of the amount that has been migrated.
        totalMigrated += amount;
        // Emit an event broadcasting that a holder has upgraded.
        emit Upgraded(upgrader, amount);
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