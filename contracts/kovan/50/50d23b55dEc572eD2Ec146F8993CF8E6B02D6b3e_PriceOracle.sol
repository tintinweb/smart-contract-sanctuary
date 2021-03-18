/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// File: contracts/PriceOracle.sol

pragma solidity ^0.6.12;

contract PriceOracle {
    address constant ADMIN = address(0x4403b4F1921E041adEd1eBeD2495546eeD32eDA9);
    address oracle = address(0xbBdE93962Ca9fe39537eeA7380550ca6845F8db7);
    
    bool public constant isPriceOracle = true;

    function setOracle(address _oracle) external {
        require(msg.sender == ADMIN, "not-admin");
        
        oracle = _oracle;
    }

    function getUnderlyingPrice(address rToken) virtual external view returns (uint) {
        return PriceOracle(oracle).getUnderlyingPrice(rToken);
    }
}