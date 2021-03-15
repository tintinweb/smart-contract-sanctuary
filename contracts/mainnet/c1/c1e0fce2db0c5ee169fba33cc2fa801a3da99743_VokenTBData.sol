// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibSafeMath.sol";
import "LibIUSDPrice.sol";


/**
 * @title Interface of VokenTB.
 */
interface IVokenTB {
    function cap() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function burningPermilleBorder() external view returns (uint16 min, uint16 max);
    function vokenCounter() external view returns (uint256);
}



/**
 * @dev VokenTB Data
 */
contract VokenTBData {
    using SafeMath for uint256;

    IVokenTB private immutable VOKEN_TB = IVokenTB(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);
    IUSDPrice private immutable USDPrice = IUSDPrice(0x0D116c07ED875E21864548dA8930163C4739FA90);

    function data()
        public
        view
        returns (
            uint256 cap,
            uint256 totalSupply,
            uint16 burningPermilleMin,
            uint16 burningPermilleMax,
            
            uint256 etherPrice,
            uint256 vokenPrice,
            uint256 vokenCounter
        )
    {
        cap = VOKEN_TB.cap();
        totalSupply = VOKEN_TB.totalSupply();
        
        (burningPermilleMin, burningPermilleMax) = VOKEN_TB.burningPermilleBorder();
        
        etherPrice = USDPrice.etherPrice();
        vokenPrice = USDPrice.vokenPrice();

        vokenCounter = VOKEN_TB.vokenCounter();
    }
}