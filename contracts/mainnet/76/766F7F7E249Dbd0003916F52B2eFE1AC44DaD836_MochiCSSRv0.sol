// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IGovernanceOwned.sol";
import "./interfaces/ICSSRAdapter.sol";
import "./interfaces/ICSSRRouter.sol";

///@notice CSSR that mixes rate oracle(keydonix) and centralized(chainlink) / maintained(keep3r) oracle to broaden the oracle usage among small cap tokens
contract MochiCSSRv0 is ICSSRRouter {
    IGovernanceOwned public immutable owned;

    // bluechip will be
    // WETH,
    // WBTC,
    // USDC,
    // DAI
    mapping(address => bool) public blueChip;

    address public defaultPriceSource;
    address public defaultLiquiditySource;

    //to check if adapter is listed
    mapping(address => bool) public adapter;
    mapping(address => address) public priceSource;
    mapping(address => address) public liquiditySource;
    mapping(address => float) public lastPrice;

    ICSSRAdapter public fiatPriceAdapter;

    modifier onlyGov() {
        require(msg.sender == owned.governance(), "!gov");
        _;
    }

    constructor(address _owned) {
        owned = IGovernanceOwned(_owned);
    }

    function setBluechip(address[] calldata _assets) external onlyGov {
        for(uint256 i = 0; i<_assets.length; i++){
            blueChip[_assets[i]] = true;
        }
    }

    function removeBluechip(address[] calldata _assets) external onlyGov {
        for(uint256 i = 0; i<_assets.length; i++){
            blueChip[_assets[i]] = false;
        }
    }

    function listAdapter(address _adapter) external onlyGov {
        adapter[_adapter] = true;
    }

    function delistAdapter(address _adapter) external onlyGov {
        adapter[_adapter] = false;
    }

    function setFiatPriceAdapter(address _adapter) external onlyGov {
        fiatPriceAdapter = ICSSRAdapter(_adapter);
    }

    function setPriceSource(address _adapter, address[] calldata _assets) external onlyGov {
        require(adapter[_adapter], "!listed");
        for(uint256 i = 0; i<_assets.length; i++){
            require(ICSSRAdapter(_adapter).support(_assets[i]), "!supported");
            priceSource[_assets[i]] = _adapter;
        }
    }

    function setLiquiditySource(address _adapter, address[] calldata _assets)
        external
        onlyGov
    {
        require(adapter[_adapter], "!listed");
        for(uint256 i = 0; i<_assets.length; i++){
            require(ICSSRAdapter(_adapter).support(_assets[i]), "!supported");
            liquiditySource[_assets[i]] = _adapter;
        }
    }

    function setDefaultPriceSource(address _adapter) external onlyGov {
        require(adapter[_adapter], "!listed");
        defaultPriceSource = _adapter;
    }

    function setDefaultLiquiditySource(address _adapter) external onlyGov {
        require(adapter[_adapter], "!listed");
        defaultLiquiditySource = _adapter;
    }

    function update(address _asset, bytes memory _data)
        external
        override
        returns (float memory price)
    {
        if (blueChip[_asset]) {
            return fiatPriceAdapter.getPrice(_asset);
        }
        ICSSRAdapter priceAdapter = ICSSRAdapter(priceSource[_asset]);
        if (address(priceAdapter) == address(0)) {
            priceAdapter = ICSSRAdapter(defaultPriceSource);
        }
        price = priceAdapter.update(_asset, _data);
        lastPrice[_asset] = price;
    }

    function getPrice(address _asset)
        external
        view
        override
        returns (float memory)
    {
        if (blueChip[_asset]) {
            return fiatPriceAdapter.getPrice(_asset);
        } else {
            ICSSRAdapter priceAdapter = ICSSRAdapter(priceSource[_asset]);
            if (address(priceAdapter) == address(0)) {
                priceAdapter = ICSSRAdapter(defaultPriceSource);
            }
            return priceAdapter.getPrice(_asset);
        }
    }

    function getLiquidity(address _asset)
        public
        view
        override
        returns (uint256)
    {
        ICSSRAdapter liquidityAdapter = ICSSRAdapter(liquiditySource[_asset]);
        if (address(liquidityAdapter) == address(0)) {
            liquidityAdapter = ICSSRAdapter(defaultLiquiditySource);
        }
        return liquidityAdapter.getLiquidity(_asset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernanceOwned {
    function governance() external view returns (address);
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

