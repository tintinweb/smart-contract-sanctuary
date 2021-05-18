/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;

contract RouterManager {
    address public admin;
    address private _route;
    event NewRoute(address oldAddr, address newAddr, uint timestamp);
    
    constructor() public {
        admin = msg.sender;
    }
    
    function getRoute() external view returns (address) {
        return _route;
    }
    
    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }
    
     function decodeMessage(bytes memory message, bytes memory signature) internal pure returns (address, address) {
        address signer = source(message, signature);

        (string memory kind, address value) = abi.decode(message, (string, address));
        require(keccak256(abi.encodePacked(kind)) == keccak256(abi.encodePacked("route")), "Kind of data must be 'route'");
        return (signer, value);
    }
    
    function setRoute(bytes calldata message, bytes calldata signature) external {
         (address signer, address value) = decodeMessage(message, signature);
         require(signer == admin, "only admin allowed set router");
         emit NewRoute(_route, value, block.timestamp);
         _route = value;
    }
}