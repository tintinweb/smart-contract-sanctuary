// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Pixel Map Wrapper Proxy
 */
contract Proxy {

    address public constant PIXELMAP = 0x44C8E0e13c590513Bdb2EaA81ffA5274cFD78042;
    address public constant WRAPPER = 0x3d4577A86e19e71b82391Bc6Ca0A25E30adF0234;
    
    function delegateCallWrap(uint _location) external payable {
        
        (bool setSuccess,) = PIXELMAP.delegatecall(
            abi.encodeWithSignature("setTile(uint, string, string, uint)", _location, 'x', 'x', msg.value * 10^18)
        );
        assert(setSuccess);
        
        (bool wrapSuccess,) = WRAPPER.delegatecall(abi.encodeWithSignature("wrap(uint)", _location));
        assert(wrapSuccess);
    }
}

