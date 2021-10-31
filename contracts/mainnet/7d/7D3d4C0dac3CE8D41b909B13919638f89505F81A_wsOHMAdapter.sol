// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ICSSRAdapter.sol";
import "../interfaces/ICSSRRouter.sol";
import "../interfaces/wsOHM/IWSOHM.sol";

contract wsOHMAdapter is ICSSRAdapter {
    ICSSRRouter public immutable cssrRouter;
    address public immutable ohm;
    IWSOHM public immutable wsOHM;

    constructor(address _cssr, address _ohm, address _wsOHM) {
        cssrRouter = ICSSRRouter(_cssr);
        ohm = _ohm;
        wsOHM = IWSOHM(_wsOHM);
    }

    function update(address _asset, bytes calldata _data)
        external
        override
        returns (float memory)
    {
        return getPrice(_asset);
    }
    
    function support(address _asset) external view override returns (bool) {
        return _asset == address(wsOHM);
    }

    function getPrice(address _asset) public view override returns(float memory) {
        require(_asset == address(wsOHM), "!support");
        float memory ohmPrice = cssrRouter.getPrice(ohm);
        return float({
            numerator: wsOHM.wOHMTosOHM(ohmPrice.numerator),
            denominator: ohmPrice.denominator
        });
    }

    function getLiquidity(address _asset)
        external
        view
        override
        returns (uint256)
    {
        revert("chainlink adapter does not support liquidity");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface ICSSRAdapter {
    function update(address _asset, bytes memory _data)
        external
        returns (float memory price);

    function support(address _asset) external view returns (bool);

    function getPrice(address _asset)
        external
        view
        returns (float memory price);

    function getLiquidity(address _asset)
        external
        view
        returns (uint256 _liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface ICSSRRouter {
    function update(address _asset, bytes memory _data)
        external
        returns (float memory);

    function getPrice(address _asset) external view returns (float memory);

    function getLiquidity(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWSOHM {
    function wOHMTosOHM(uint256 wohm) external view returns(uint256);
    function sOHMTowOHM(uint256 wsohm) external view returns(uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

struct float {
    uint256 numerator;
    uint256 denominator;
}

library Float {
    function multiply(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.numerator / f.denominator;
    }

    function inverse(float memory f) internal pure returns(float memory) {
        require(f.numerator != 0 && f.denominator != 0, "div 0");
        return float({
            numerator: f.denominator,
            denominator: f.numerator
        });
    }

    function divide(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.denominator / f.numerator;
    }

    function add(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator + a.denominator*b.numerator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }
    
    function sub(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator - b.numerator*a.denominator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function mul(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator * b.numerator,
            denominator : a.denominator * b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function gt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator > a.denominator * b.numerator;
    }

    function lt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator < a.denominator * b.numerator;
    }

    function gte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator >= a.denominator * b.numerator;
    }

    function lte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator <= a.denominator * b.numerator;
    }

    function equals(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator == b.numerator * a.denominator;
    }
}