/**
 *Submitted for verification at Etherscan.io on 2021-12-09
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
    function mint(address usr, uint wad) external;
    function burnFrom(address src, uint wad) external;
    function balanceOf(address usr) external returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// Copyright (C) 2021 RTC/Veronika
// SPDX-License-Identifier: No License
// File: contracts/Fauceth.sol

pragma solidity ^0.8.0;

contract Fauceth {
    uint8   public constant fr   = 3;         // Fee Rate 0.3%
    uint32  public constant frb  = 1000;      // Fee Rate Base

    address public constant _owner            = 0xf4D73A15d2377B274b567D24a040167c2530C546;
    address public constant _vsdc             = 0x949a31f0F48c803f300504E27c96f64455F53d57;
    address payable public constant _chest    = payable(0xF55d7A2F553Be0bEAEDcE903103a2a13e9b5508C);

    mapping (address => uint) public blocks;
    mapping (address => bool) public contractors;

    AggregatorV3Interface internal pf;
    VSDC public vsdc;

    constructor() {
        vsdc = VSDC(_vsdc);

        /*
         * Network: Rinkeby
         * Aggregator: ETH/USD
         * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
         *
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         *
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
         pf = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    receive() external payable {
        mint();
    }

    fallback() external payable {
        mint();
    }

    function mint() public payable {
        uint wad = msg.value;
        require(control());
        require(wad > 0, "No value");

        uint prx = getPrice();
        require(prx > 0, "No price");

        uint fee = wad * fr / frb; wad -= fee;
        uint val = wad * prx / 1e18;

        require(_chest.send(fee));
        vsdc.mint(msg.sender, val);
        blocks[msg.sender] = block.number;

        delete wad;
        delete prx;
        delete fee;
        delete val;
    }

    function burn(uint val) public {
        require(control());
        require(val > 0 && vsdc.balanceOf(msg.sender) >= val, "No balance");

        uint prx = getPrice();
        require(prx > 0, "No price");

        uint wad = val * 1e18 / prx;
        uint fee = wad * fr / frb; wad -= fee;
        address payable _to = payable(msg.sender);

        vsdc.burnFrom(msg.sender, val);
        _chest.transfer(fee);
        _to.transfer(wad);
        blocks[msg.sender] = block.number;

        delete wad;
        delete prx;
        delete fee;
    }

    function getPrice() public view returns (uint) {
        uint prx = 0;
        
        (
            uint80 roundID, 
            int ticker,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = pf.latestRoundData();

        if(ticker < 0) {
            prx = uint(-ticker) * 1e10;
        }
        else {
            prx = uint(ticker) * 1e10;
        }

        delete roundID;
        delete ticker;
        delete startedAt;
        delete timeStamp;
        delete answeredInRound;
        
        return prx;
    }

    function controlContractors(address _contractor, bool _access) public {
        require(control());
        require(msg.sender == _owner);

        contractors[_contractor] = _access;
    }

    function control() internal view returns (bool) {
        require((msg.sender == tx.origin) || contractors[msg.sender] == true, "Access denied");
        require((blocks[msg.sender] < block.number) || contractors[msg.sender] == true, "Block used");
        return true;
    }
}