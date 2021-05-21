/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/******************************************/
/*       ChainLink starts here            */
/******************************************/

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

/******************************************/
/*       Benchmark starts here            */
/******************************************/

abstract contract Benchmark 

{
    function rebase(uint256 supplyDelta, bool increaseSupply) external virtual returns (uint256);
    
    function transfer(address to, uint256 value) external virtual returns (bool);
    
    function balanceOf(address who) external virtual view returns (uint256);

    function totalSupply() external virtual view returns (uint256);
}

/******************************************/
/*       BenchmarkSync starts here        */
/******************************************/

abstract contract BenchmarkSync 

{
    function syncPools() external virtual;
}

/******************************************/
/*       BenchmarkOracle starts here      */
/******************************************/

contract BenchmarkOracle {

    AggregatorV3Interface internal priceFeed;
    int256 public lastOracleVxx;

    address owner1;
    address owner2;
    address owner3;
    address owner4;
    address owner5;

    address public standard;
    uint256 public standardRewards;
    
    Benchmark public bm;
    BenchmarkSync public sync;

    Transaction public pendingRebasement;
    uint256 internal lastRebasementTime;

    struct Transaction {
        address initiator;
        int256 rebaseOne;
        int256 rebaseTwo;
        bool executed;
    }

    modifier isOwner() 
    {
        require (msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3 || msg.sender == owner4 || msg.sender == owner5);
        _;
    }

    constructor(address _benchmark, address _standard, address _sync)
    {
        /**
        * Network: Ethereum
        * Aggregator: VXX
        * Address: 0xC18F2a0C166A091fcD5E2051EFEFD63c4f4A27E9
        */
        priceFeed = AggregatorV3Interface(0xC18F2a0C166A091fcD5E2051EFEFD63c4f4A27E9);
        lastOracleVxx = getOracleVxx();

        owner1 = 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec;
        owner2 = 0xdBd39C1b439ba2588Dab47eED41b8456486F4Ba5;
        owner3 = 0x90d33D152A422D63e0Dd1c107b7eD3943C06ABA8;
        owner4 = 0xE12E421D5C4b4D8193bf269BF94DC8dA28798BA9;
        owner5 = 0xD4B33C108659A274D8C35b60e6BfCb179a2a6D4C;
        standard = _standard;
        bm = Benchmark(_benchmark);
        sync = BenchmarkSync(_sync);

        
        pendingRebasement.executed = true;
    }

    /**
     * Returns the latest price
     */
    function getOracleVxx() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * Returns absolute value.
     */
    function abs(int x) private pure returns (int) {
    return x >= 0 ? x : -x;
    }
    
    /**
     * @dev Initiates a rebasement proposal that has to be confirmed by another owner of the contract to be executed. Can't be called while another proposal is pending.
     * @param _rebaseOne Divergence from the target price.
     * @param _rebaseTwo VXX difference.
     */
    function initiateRebasement(int256 _rebaseOne, int256 _rebaseTwo) public isOwner
    {
        require (pendingRebasement.executed == true, "Pending rebasement.");
        require (lastRebasementTime < (block.timestamp - 54000), "Rebasement has already occured within the past 15 hours.");

        Transaction storage txn = pendingRebasement; 
        txn.initiator = msg.sender;
        txn.rebaseOne = _rebaseOne;
        txn.rebaseTwo = _rebaseTwo;
        txn.executed = false;
    }

    /**
     * @dev Confirms and executes a pending rebasement proposal. Prohibits further proposals for 15 hours. Distribute Standard rewards and sync liquidity pools.
     * @param _overrule True if Chainlink Oracle should be ignored.
     * @param _currentVxx Manually provide current VXX value if Chainlink Oracle is ignored.
     */
    function confirmRebasement(bool _overrule, int256 _currentVxx) public isOwner
    {
        require (pendingRebasement.initiator != msg.sender, "Initiator can't confirm rebasement.");
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        int256 oracleRebaseTwo;

        if (_overrule == false) {
            oracleRebaseTwo = ((getOracleVxx() - lastOracleVxx) * 1e10) / lastOracleVxx;   
            oracleRebaseTwo = oracleRebaseTwo < 0 ? int(0) : oracleRebaseTwo;
            require (oracleRebaseTwo == pendingRebasement.rebaseTwo, "VXX rebases don't match!");
            lastOracleVxx = getOracleVxx();
        } else {
            oracleRebaseTwo = pendingRebasement.rebaseTwo;
            require(_currentVxx != 0, "Current VXX not provided.");
            lastOracleVxx = _currentVxx;
        }  

        pendingRebasement.executed = true;
        lastRebasementTime = block.timestamp;
        
        int256 rebasePercentage = pendingRebasement.rebaseOne + oracleRebaseTwo;
        bool increaseSupply = rebasePercentage >= 0 ? true : false;
        uint256 absolutePercentage = uint256(abs(rebasePercentage));
        uint256 supplyDelta = bm.totalSupply() * absolutePercentage / 1e10;

        bm.rebase(supplyDelta, increaseSupply);
        bm.transfer(standard, standardRewards);

        sync.syncPools();
    }

    /**
     * @dev View Supply delta and sign for rebasement verification.
     * @param _overrule True if Chainlink Oracle should be ignored.
     */
    function verifyRebasement(bool _overrule) public view returns (uint256, bool)
    {
        int256 oracleRebaseTwo;

        if (_overrule == false) {
            oracleRebaseTwo = ((getOracleVxx() - lastOracleVxx) * 1e10) / lastOracleVxx;   
            oracleRebaseTwo = oracleRebaseTwo < 0 ? int(0) : oracleRebaseTwo;
            require (oracleRebaseTwo == pendingRebasement.rebaseTwo, "VXX rebases don't match!");
        } else {
            oracleRebaseTwo = pendingRebasement.rebaseTwo;
        }  
        
        int256 rebasePercentage = pendingRebasement.rebaseOne + oracleRebaseTwo;
        bool increaseSupply = rebasePercentage >= 0 ? true : false;
        uint256 absolutePercentage = uint256(abs(rebasePercentage));
        uint256 supplyDelta = bm.totalSupply() * absolutePercentage / 1e10;

        return(supplyDelta, increaseSupply);
    }

    /**
     * @dev Denies a pending rebasement proposal and allows the creation of a new proposal.
     */
    function denyRebasement() public isOwner
    {
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        
        pendingRebasement.executed = true;
    }

    /**
     * @dev Change Standard staking rewards. 
     * @param _standardRewards New amount.
     */
    function setStandardRewards(uint256 _standardRewards) public isOwner {
        standardRewards = _standardRewards;
    }

    /**
     * @dev Remove all MARK deposited on this contract. 
     */
    function withdrawMark() public {
        require (msg.sender == 0x2c155e07a1Ee62f229c9968B7A903dC69436e3Ec || msg.sender == 0xdBd39C1b439ba2588Dab47eED41b8456486F4Ba5, "Only Masterchief can withdraw.");
        bm.transfer(msg.sender, bm.balanceOf(address(this)));
    }

    /**
     * @dev Change the contract for pool synchronization. 
     */
    function setSyncContract(address _sync) public isOwner {
        sync = BenchmarkSync(_sync);
    }
}