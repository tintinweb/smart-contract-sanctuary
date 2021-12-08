// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20Permit.sol";


contract ERC20Wrapper is ERC20Permit {

    event Wrapped(address indexed from, address indexed to, uint256 underlying, uint256 wrapper);
    event Unwrapped(address indexed from, address indexed to, uint256 wrapper, uint256 underlying);

    IERC20 public immutable underlying;     // IERC20 being wrapped in this contract
    uint256 public cache;                   // Amount of underlying wrapped in this contract

    constructor(IERC20 underlying_, string memory name, string memory symbol, uint8 decimals) ERC20Permit(name, symbol, decimals) {
        underlying = underlying_;
    }

    /// @dev Take underlying from the caller and mint wrapper tokens in exchange.
    /// Any amount of unaccounted underlying in this contract will also be used.
    function wrap(address to, uint256 underlyingIn)
        external
        returns (uint256 wrapperOut)
    {
        uint256 underlyingHere = underlying.balanceOf(address(this)) - cache;
        uint256 underlyingUsed = underlyingIn + underlyingHere;
        wrapperOut = _wrapMath(underlyingUsed);

        _mint(to, wrapperOut);
        cache += underlyingUsed;

        require(underlyingIn == 0 || underlying.transferFrom(msg.sender, address(this), underlyingIn), "Transfer fail");
        
        emit Wrapped(msg.sender, to, underlyingUsed, wrapperOut);
    }

    /// @dev Burn wrapper token from the caller and send underlying tokens in exchange.
    /// Any amount of unaccounted wrapper in this contract will also be used.
    function unwrap(address to, uint256 wrapperIn)
        external
        returns (uint256 underlyingOut)
    {
        uint256 wrapperHere = _balanceOf[address(this)];
        uint256 wrapperUsed = wrapperIn + wrapperHere;
        underlyingOut = _unwrapMath(wrapperUsed);

        if (wrapperIn > 0) _burn(msg.sender, wrapperIn);  // Approval not necessary
        if (wrapperHere > 0) _burn(address(this), wrapperHere);
        cache -= underlyingOut;

        require(underlying.transfer(to, underlyingOut), "Transfer fail");
        
        emit Unwrapped(msg.sender, to, wrapperUsed, underlyingOut);
    }

    /// @dev Formula to convert from underlying to wrapper amounts. Feel free to override with your own.
    function _wrapMath(uint256 underlyingAmount) internal virtual returns (uint256 wrapperAmount) {
        wrapperAmount = underlyingAmount;
    }

    /// @dev Formula to convert from wrapper to underlying amounts. Feel free to override with your own.
    function _unwrapMath(uint256 wrapperAmount) internal virtual returns (uint256 underlyingAmount) {
        underlyingAmount = wrapperAmount;
    }
}