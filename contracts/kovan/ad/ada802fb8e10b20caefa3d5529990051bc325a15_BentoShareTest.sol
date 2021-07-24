/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

/// @notice Interface for ERC-20 token interactions with {permit} extensions
interface IERC20 { 
    /// @dev ERC-20:
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    /// @dev EIP-2612:
    function permit(
        address owner, 
        address spender, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;
    /// @dev DAI-like {permit}:
    function permitAllowed(
        address owner,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @notice Minimal interface for BentoBox token vault (V1) interactions
interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function registerProtocol() external;
}

contract BentoShareTest is IFlashBorrower {
    IERC20 public testToken;
    IBentoBoxV1 constant bento = IBentoBoxV1(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // BENTO vault contract
    
    constructor(IERC20 _testToken) {
        bento.registerProtocol(); // register this contract with BENTO
        _testToken.approve(address(bento), type(uint256).max);
        testToken = _testToken;
    }

    function depositToBento(uint256 amount) external {
        bento.deposit(testToken, address(this), address(this), amount, 0);
    }
    
    function withdrawFromBento(uint256 amount) external {
        bento.withdraw(testToken, address(this), msg.sender, 0, amount);
    }
    
    function onFlashLoan(
        address sender, // account that activates flash loan from BENTO
        IERC20, // default to flash borrow xSUSHI
        uint256 amount, // xSUSHI amount flash borrowed
        uint256 fee, // BENTO flash loan fee
        bytes calldata // default to not use data in flash loan
    ) external override {
        /// @dev The following functions pay back xSUSHI to BENTO with fee and send any winnings to `sender`.
        uint256 payback = amount + fee; // calculate `payback` to BENTO as borrowed xSUSHI `amount` + `fee`
        testToken.transfer(msg.sender, payback); // send `payback` to BENTO
        testToken.transfer(sender, testToken.balanceOf(address(this)) - payback); // skim remainder xSUSHI winnings to `sender`
    }
}