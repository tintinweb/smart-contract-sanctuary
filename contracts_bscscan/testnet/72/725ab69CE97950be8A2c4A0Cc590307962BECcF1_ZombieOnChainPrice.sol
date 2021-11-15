pragma solidity >=0.7.0 <0.9.0;
import "./libraries/Percentages.sol";

// SPDX-License-Identifier: MIT
/**
 * @title ZombieOnChainPrice
 * Gets ZombieToken on chain zmbe price. This price can be manipulated and cannot be used for critical contracts.
 */

interface ApeswapPair {
    function getReserves() external view returns (uint112, uint112, uint32);
    function token1() external view returns(address);
}


interface IERC20 {
    function decimals() external view returns (uint);
}

interface BnbPriceConsumer {
    function getLatestPrice() external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

contract ZombieOnChainPrice {
    using Percentages for uint256;
    ApeswapPair public zmbeBnbPair;
    BnbPriceConsumer public bnbPriceConsumer;
    constructor(ApeswapPair _zmbeBnbPair, BnbPriceConsumer _bnbPriceConsumer) {
        zmbeBnbPair = _zmbeBnbPair;
        bnbPriceConsumer = _bnbPriceConsumer;
    }

    function usdToZmbe(uint amount) public view returns(uint) {
//        uint oneBnb = 10 ** 18;
//        uint oneBnbInZmbe = getBnbInZmbe(1);
//        uint basisPoints = oneBnb.calcBasisPoints(bnbPriceConsumer.usdToBnb(amount));
        return 100**18; // oneBnbInZmbe.calcPortionFromBasisPoints(basisPoints);
    }

//    function getBnbInZmbe(uint amount) private view returns(uint) {
//        IERC20 token1 = IERC20(zmbeBnbPair.token1());
//        (uint Res0, uint Res1,) = zmbeBnbPair.getReserves();
//
//        // decimals
//        uint res0 = Res0*(10**token1.decimals());
//        return((amount*res0)/Res1);
//    }
}

pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

