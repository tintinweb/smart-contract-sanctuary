/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//
// Fauceth
// Interface: Swapship.org
// Virtual Stable Denomination Coin: Mint Contract V1 "Ether"
// May 2021
//

// //////////////////////////////////////////////////////////////////////////////// //
//                                                                                  //
//                               ////   //////   /////                              //
//                              //        //     //                                 //
//                              //        //     /////                              //
//                                                                                  //
//                              Never break the chain.                              //
//                                  http://RTC.wtf                                  //
//                                                                                  //
// //////////////////////////////////////////////////////////////////////////////// //

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity ^0.6.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

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

// SPDX-License-Identifier: MIT
// File: contracts/VSDC.sol

pragma solidity ^0.6.0;

interface VSDC {
    function mint(address guy, uint wad) external returns (bool);
    function burn(address guy, uint wad) external returns (bool);
}

// File: contracts/Fauceth.sol
contract Fauceth {
    AggregatorV3Interface internal ethPriceFeed;
    VSDC public stablecoin;

    struct FaucetInfo {
      uint depo;
      uint debt;
    }

    address public vsdc = 0x9E4CBFf3565aED44F84A74D9df6393a279B2e4fe;
    mapping (address => FaucetInfo) public faucets;

    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    constructor() public {
        stablecoin = VSDC(vsdc);

        /*
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         *
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
         ethPriceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    function receive() public payable {
        deposit();
    }

    function fallback() public payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0);

        uint wad = msg.value;
        uint prx = getEthPrice();
        uint val = wad * prx / 1e18;

        faucets[msg.sender].depo += wad;
        faucets[msg.sender].debt += val;

        stablecoin.mint(msg.sender, val);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(faucets[msg.sender].depo >= wad);

        uint prx = getEthPrice();
        uint val = wad * prx / 1e18;

        faucets[msg.sender].depo -= wad;
        faucets[msg.sender].debt += val;
        msg.sender.transfer(wad);

        emit Withdrawal(msg.sender, wad);
    }

    function getEthPrice() public view returns (uint) {
        uint price = 0;
        
        (
            uint80 roundID, 
            int ticker,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethPriceFeed.latestRoundData();

        if(ticker < 0) {
            price = uint(-ticker);
        }
        else {
            price = uint(ticker);
        }
        
        return (price * 1e10);
    }
}