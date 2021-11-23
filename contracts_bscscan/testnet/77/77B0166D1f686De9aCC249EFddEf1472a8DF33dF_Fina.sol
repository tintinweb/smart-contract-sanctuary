/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

abstract contract Proxy {
    function _delegate(address impl) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function implementation() internal view virtual returns (address);

    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(implementation());
    }

    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }

    function _beforeFallback() internal virtual {}
}

interface FinaMarket {
    function cardsQuota(uint) external view returns (uint);
}
interface FinaCard {
    function cardInfoes(uint) external view returns (uint256, uint256, uint256, string memory, uint256,uint256, string memory);
}

contract Fina is Proxy {
    address internal _impl;
    uint internal _require_rarity;

    //    FinaMarket constant _mar = FinaMarket(0x3F50dA5128D712b7C5c7B329a03901bcCA3dDAaE);
    //    FinaCard constant _card = FinaCard(0xa318d9a2D6900A652FD0C9fea8c57a29b2a63709);
    FinaMarket constant _mar = FinaMarket(0x291869b19A96173B481B1880eb43A7e72BF10c74);
    FinaCard constant _card = FinaCard(0x7B80bE85AAD8C3600FAE9f0495EE59901E73EE28);

    function _randModulus(uint mod) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                msg.sender)
            )) % mod;
        return rand;
    }

    function setImplementation(address _addr) external {
        _impl = _addr;
    }

    function set_require_rarity(uint _rarity) external {
        _require_rarity = _rarity;
    }

    function implementation() internal override view returns (address) {
        return _impl;
    }

    function _fallback() internal override {
        _delegate(implementation());
//        uint _mod = 0;
//
//        for (uint i = 0;i < 28;i ++) {
//            if (_mar.cardsQuota(i + 1)> 0) {
//                _mod ++;
//            }
//        }
//        uint _r = _randModulus(_mod);
//        (,, uint _rarity,,,,) = _card.cardInfoes(_r + 1);
//        if (_rarity == _require_rarity) {
//            _beforeFallback();
//            _delegate(implementation());
//        }
    }
}