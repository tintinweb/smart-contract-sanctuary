/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

interface AggregatorV3Interface {
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

contract CalculationsSynth is Manageable {
    
    mapping (address => bool) public eurSynths;
    mapping (address => bool) public gbpSynths;
    mapping (address => bool) public chfSynths;
    mapping (address => bool) public audSynths;
    mapping (address => bool) public jpySynths;
    mapping (address => bool) public krwSynths;
    
    AggregatorV3Interface public eurChainlinkFeed;
    AggregatorV3Interface public gbpChainlinkFeed;
    AggregatorV3Interface public chfChainlinkFeed;
    AggregatorV3Interface public audChainlinkFeed;
    AggregatorV3Interface public jpyChainlinkFeed;
    AggregatorV3Interface public krwChainlinkFeed;
    
    constructor(
        address _managementListAddress,
        address _eurChainlinkFeed,
        address _gbpChainlinkFeed,
        address _chfChainlinkFeed,
        address _audChainlinkFeed,
        address _jpyChainlinkFeed,
        address _krwChainlinkFeed
    ) Manageable(_managementListAddress) {
        eurChainlinkFeed = AggregatorV3Interface(_eurChainlinkFeed);
        gbpChainlinkFeed = AggregatorV3Interface(_gbpChainlinkFeed);
        chfChainlinkFeed = AggregatorV3Interface(_chfChainlinkFeed);
        audChainlinkFeed = AggregatorV3Interface(_audChainlinkFeed);
        jpyChainlinkFeed = AggregatorV3Interface(_jpyChainlinkFeed);
        krwChainlinkFeed = AggregatorV3Interface(_krwChainlinkFeed);
    }

    function setEurFeed(address _eurChainlinkFeed) public onlyManagers {
        eurChainlinkFeed = AggregatorV3Interface(_eurChainlinkFeed);
    }

    function setGbpFeed(address _gbpChainlinkFeed) public onlyManagers {
        gbpChainlinkFeed = AggregatorV3Interface(_gbpChainlinkFeed);
    }

    function setChfFeed(address _chfChainlinkFeed) public onlyManagers {
        chfChainlinkFeed = AggregatorV3Interface(_chfChainlinkFeed);
    }

    function setAudFeed(address _audChainlinkFeed) public onlyManagers {
        audChainlinkFeed = AggregatorV3Interface(_audChainlinkFeed);
    }

    function setJpyFeed(address _jpyChainlinkFeed) public onlyManagers {
        jpyChainlinkFeed = AggregatorV3Interface(_jpyChainlinkFeed);
    }

    function setKrwFeed(address _krwChainlinkFeed) public onlyManagers {
        krwChainlinkFeed = AggregatorV3Interface(_krwChainlinkFeed);
    }
    
    function setSynths(
        address[] memory _eurSynths,
        address[] memory _gbpSynths,
        address[] memory _chfSynths,
        address[] memory _audSynths,
        address[] memory _jpySynths,
        address[] memory _krwSynths
    ) public onlyManagers {
        for (uint i = 0; i < _eurSynths.length; i++) {
            eurSynths[_eurSynths[i]] = true;
        }
        for (uint i = 0; i < _gbpSynths.length; i++) {
            gbpSynths[_gbpSynths[i]] = true;
        }
        for (uint i = 0; i < _chfSynths.length; i++) {
            chfSynths[_chfSynths[i]] = true;
        }
        for (uint i = 0; i < _audSynths.length; i++) {
            audSynths[_audSynths[i]] = true;
        }
        for (uint i = 0; i < _jpySynths.length; i++) {
            jpySynths[_jpySynths[i]] = true;
        }
        for (uint i = 0; i < _krwSynths.length; i++) {
            krwSynths[_krwSynths[i]] = true;
        }
    }
    
    function setEurSynth(address synthAddress, bool isSynth) public onlyManagers {
        eurSynths[synthAddress] = isSynth;
    }
    
    function setGbpSynth(address synthAddress, bool isSynth) public onlyManagers {
        gbpSynths[synthAddress] = isSynth;
    }
    
    function setChfSynth(address synthAddress, bool isSynth) public onlyManagers {
        chfSynths[synthAddress] = isSynth;
    }
    
    function setAudSynth(address synthAddress, bool isSynth) public onlyManagers {
        audSynths[synthAddress] = isSynth;
    }
    
    function setJpySynth(address synthAddress, bool isSynth) public onlyManagers {
        jpySynths[synthAddress] = isSynth;
    }
    
    function setKrwSynth(address synthAddress, bool isSynth) public onlyManagers {
        krwSynths[synthAddress] = isSynth;
    }
    
    function getEurPrice() public view returns (int256) {
        (,int price,,,) = eurChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getGbpPrice() public view returns (int256) {
        (,int price,,,) = gbpChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getChfPrice() public view returns (int256) {
        (,int price,,,) = chfChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getAudPrice() public view returns (int256) {
        (,int price,,,) = audChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getJpyPrice() public view returns (int256) {
        (,int price,,,) = jpyChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getKrwPrice() public view returns (int256) {
        (,int price,,,) = krwChainlinkFeed.latestRoundData();
        return price;
    }
    
    function getPriceUsdc(address tokenAddress) public view returns (int256) {
        int256 price;
        
        if (eurSynths[tokenAddress]) {
            price = getEurPrice();
        } else if (gbpSynths[tokenAddress]) {
            price = getGbpPrice();
        } else if (chfSynths[tokenAddress]) {
            price = getChfPrice();
        } else if (audSynths[tokenAddress]) {
            price = getAudPrice();
        } else if (jpySynths[tokenAddress]) {
            price = getJpyPrice();
        } else if (krwSynths[tokenAddress]) {
            price = getKrwPrice();
        } else {
            revert("token not a synth");
        }
        
        return price / 10 ** 2;
    }
}