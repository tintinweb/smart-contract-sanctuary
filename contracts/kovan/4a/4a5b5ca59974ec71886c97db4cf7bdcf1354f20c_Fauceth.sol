/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

//
// Fauceth
// Interface: Swapship.org Payship.org VSDC.info
// Virtual Stable Digital Coin: Minting Contract V1 "Ether"
// May 2021
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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

interface VSDC {
    function totalSupply() external view returns (uint);
    function approve(address usr, uint wad) external returns (bool);
    function balanceOf(address usr) external view returns (uint);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function mint(address usr, uint wad) external returns (bool);
    function burn(uint wad) external returns (bool);

    event Approval(address indexed src, address indexed usr, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

// SPDX-License-Identifier: MIT
// File: contracts/Fauceth.sol
contract Fauceth {
    AggregatorV3Interface internal ethpf;
    VSDC public vsdc;

    struct FaucetInfo {
      uint depo;
      uint debt;
    }

    uint public ctv = 80;
    uint public fee = 997;
    uint public base = 1e20;

    address public _chest = 0xeaA5A8e2946a586A06A8B16Be2E87d78F556d835;
    address public _vsdc = 0xa95d48B67EA8abd3F7BCA832913f8c547d8629B5;
    mapping (address => FaucetInfo) public faucets;

    event  Deposit(address indexed dst, uint wad);
    event  Borrow(address indexed dst, uint val);
    event  Repay(address indexed dst, uint val);
    event  Withdrawal(address indexed src, uint wad);
    event  Liquidation(address indexed src, address indexed dst, uint wad);

    constructor() public {
        vsdc = VSDC(_vsdc);

        /*
         * Network: Kovan
         * Aggregator: ETH/USD
         * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
         *
         * Network: Mainnet
         * Aggregator: ETH/USD
         * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
         */
         ethpf = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
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
        uint prx = getPrice();

        require(prx > 0);
        uint val = wad * prx * ctv / base;

        vsdc.mint(msg.sender, val);
        faucets[msg.sender].depo += wad;
        faucets[msg.sender].debt += val;

        emit Deposit(msg.sender, msg.value);
    }

    function borrow() public {
        uint depo = faucets[msg.sender].depo;
        uint debt = faucets[msg.sender].debt;
        uint prx = getPrice();

        require(prx > 0);
        uint val = depo * prx * ctv / base;
        
        require(val > 0 && val > debt);
        uint ext = val - debt;

        vsdc.mint(msg.sender, ext);
        faucets[msg.sender].debt += ext;

        emit Borrow(msg.sender, ext);
    }

    function repay(uint val) public {
        require(val > 0 && val <= faucets[msg.sender].debt);
        uint fee = val * 997 / 1000;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender));
        if (fee > 0) {
            vsdc.transferFrom(msg.sender,_chest,fee);
        }

        //vsdc.burn(val);
        faucets[msg.sender].debt -= val;

        emit Repay(msg.sender, val);
    }

    function withdraw(uint wad) public payable {
        uint depo = faucets[msg.sender].depo;
        uint debt = faucets[msg.sender].debt;
        address payable _to = payable(msg.sender);

        require(wad > 0 && depo >= wad);
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx * ctv / base;

        require(depoval >= debt);
        uint val = debt * wad / depo;
        uint fee = val * 997 / 1000;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender));
        if (fee > 0) {
            vsdc.transfer(_chest,fee);
        }

        vsdc.burn(val);
        (bool sent, bytes memory data) = _to.call{value: wad}("");

        require(sent);
        faucets[msg.sender].depo -= wad;
        faucets[msg.sender].debt -= val;

        emit Withdrawal(msg.sender, wad);
    }

    function liquidate(address usr) public {
        require(faucets[usr].depo > 0 && faucets[usr].debt > 0);
        uint depo = faucets[usr].depo;
        uint debt = faucets[usr].debt;

        address payable _to = payable(msg.sender);
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx / 1e18;

        require(depoval < debt);
        uint val = debt + (debt - depoval);
        uint fee = val * 997 / 1000;
        uint tot = val + fee;

        require(tot <= vsdc.balanceOf(msg.sender));
        if (fee > 0) {
            vsdc.transfer(_chest,fee);
        }

        vsdc.burn(val);
        (bool sent, bytes memory data) = _to.call{value: depo}("");

        require(sent);
        faucets[usr].depo = 0;
        faucets[usr].debt = 0;

        emit Liquidation(usr, msg.sender, depo);
    }

    function sink(address usr) public {
        require(faucets[usr].depo > 0 && faucets[usr].debt > 0);
        uint depo = faucets[usr].depo;
        uint debt = faucets[usr].debt;

        address payable _to = payable(_chest);
        uint prx = getPrice();

        require(prx > 0);
        uint depoval = depo * prx / 1e18;

        require(depoval < debt);
        (bool sent, bytes memory data) = _to.call{value: depo}("");

        require(sent);
        faucets[usr].depo = 0;
        faucets[usr].debt = 0;

        emit Liquidation(usr, _chest, depo);
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