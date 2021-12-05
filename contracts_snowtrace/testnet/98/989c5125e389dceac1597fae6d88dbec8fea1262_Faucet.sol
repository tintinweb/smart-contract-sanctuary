/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**************************************

    :: Interface BenQi Asset ::

**************************************/

interface IAsset {
    
    function decimals() external view returns (uint256);
    function allocateTo(address, uint256) external;

}

/**************************************

    :: Contract BenQi Faucet ::

 **************************************/

contract Faucet {

    // constants
    address constant internal USDC = 0x45ea5d57BA80B5e3b0Ed502e9a08d568c96278F9;
    address constant internal WETH = 0x4f5003fd2234Df46FB2eE1531C89b8bdcc372255;
    address constant internal WBTC = 0x385104afA0BfdAc5A2BcE2E3fae97e96D1CB9160;
    address constant internal LINK = 0x8913a950A5fBF2832B88B9F1e4D0EeBd5281Ac10;

    // BenQi markets
    mapping (string => address) public markets;

    // events
    event Used(address market, address sender, uint256 amount);

    // errors
    error InvalidMarket(string market);

    /**************************************
    
        Constructor

     **************************************/

    constructor() {

        // init markets
        markets["USDC"] = USDC;
        markets["WETH"] = WETH;
        markets["WBTC"] = WBTC;
        markets["LINK"] = LINK;

    }

    /**************************************
    
        Use faucet

     **************************************/

    function use(
        string memory _market,
        uint256 _amount
    ) external {

        // retrieve market address from name
        address market_ = markets[_market];

        if (market_ == address(0x0)) {

            // revert for unsupported market
            revert InvalidMarket(_market);

        }

        // get decimals
        uint256 decimals_ = IAsset(market_).decimals();

        // mint
        IAsset(market_).allocateTo(msg.sender, _amount * (10 ** decimals_));

        // event
        emit Used(market_, address(msg.sender), _amount);

    }

}