/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//
// VSDC Swapship Fauceth
// Interface: Swapship.org
// Virtual Stable Denomination Coin: Swap Contract V1 "Ether"
// July 2021
//

// //////////////////////////////////////////////////////////////////////////////// //
//                                                                                  //
//                               ////   //////   /////                              //
//                              //        //     //                                 //
//                              //        //     /////                              //
//                                                                                  //
//                              Never break the chain.                              //
//                                   www.RTC.wtf                                    //
//                                                                                  //
// //////////////////////////////////////////////////////////////////////////////// //

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function devsdcription() external view returns (string memory);
    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/VSDC.sol

pragma solidity ^0.8.0;

interface VSDC {
    function balanceOf(address usr) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function mint(address usr, uint wad) external returns (bool);
    function burnFrom(address src, uint wad) external returns (bool);
}

// Copyright (C) 2021 RTC/Veronika
// SPDX-License-Identifier: No License
// File: contracts/Fauceth.sol

pragma solidity ^0.8.0;

contract Fauceth {
    AggregatorV3Interface internal ethpf;
    VSDC public vsdc;

    uint public pb  = 1e18;           // Price Feed Base
    uint public frb = 1000;          // Fee Rate Base
    uint public fr  = frb - 997;     // Fee Rate 0.3%

    address payable public _chest    = payable(0xF55d7A2F553Be0bEAEDcE903103a2a13e9b5508C);
    address public _vsdc             = 0x88D59Ba796fDf639dEd3b5E720988D59fDb71Eb8; // 0x7311cd50667Eff17f4E97DffBe9683aeC47e4890;

    mapping (address => uint) public blocks;

    constructor() {
        vsdc = VSDC(_vsdc);

        /*
         * Network: Rinkeby
         * Aggregator: ETH/USD
         * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
         *
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
         ethpf = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    receive() external payable {
        mint();
    }

    fallback() external payable {
        mint();
    }

    function mint() public payable {
        require(blocks[msg.sender] < (block.number + 1), "mint: Block alredy used. Try next block.");
        require(msg.value > 0, "mint: Amount must be greater than zero. Increase amount.");

        uint prx = getPrice();
        require(prx > 0, "mint: Price feed cannot be zero. Try again.");

        uint wad = msg.value;
        uint fee = wad * fr / frb;
        uint val = (wad - fee) * prx / pb;

        (bool success, bytes memory data) = _chest.call{value: fee}("");
        require(success, "mint: Fee transfer failed. Try again.");

        vsdc.mint(msg.sender, val);
        blocks[msg.sender] = block.number;
    }

    function burn(uint val) public {
        require(blocks[msg.sender] < (block.number + 1), "burn: Block alredy used. Try next block.");
        require(val > 0, "burn: Amount must be greater than zero. Increase amount.");

        uint prx = getPrice();
        require(prx > 0, "burn: Price feed cannot be zero. Try again.");

        uint wad = val * pb / prx;
        uint fee = wad * fr / frb;
             wad = wad - fee;

        (bool success_fee, bytes memory data_fee) = _chest.call{value: fee}("");
        require(success_fee, "burn: Fee transfer failed. Try again.");

        address payable _to = payable(msg.sender);
        (bool success, bytes memory data) = _to.call{value: wad}("");
        require(success, "burn: Eth transfer failed. Try again.");

        vsdc.burnFrom(msg.sender, val);
        blocks[msg.sender] = block.number;
    }

    function getPrice() public view returns (uint) {
        uint price = 0;
        
        (
            uint80 roundID, 
            int ticker,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethpf.latestRoundData();

        if(ticker < 0) {
            price = uint(-ticker);
        }
        else {
            price = uint(ticker);
        }
        
        return (price * 1e10);
    }
}