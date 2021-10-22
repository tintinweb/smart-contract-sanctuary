/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

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
/*       Sprotocol starts here            */
/******************************************/

abstract contract Sprotocol

{
    function rebase(uint256 supplyDelta, bool increaseSupply) external virtual returns (uint256);
    
    function transfer(address to, uint256 value) external virtual returns (bool);
    
    function balanceOf(address who) external virtual view returns (uint256);

    function totalSupply() external virtual view returns (uint256);
}

/******************************************/
/*       SprotocolSync starts here        */
/******************************************/

abstract contract SprotocolSync 

{
    function syncPools() external virtual;
}

/******************************************/
/*       SprotocolOracle starts here      */
/******************************************/

contract SprotocolOracle {

    AggregatorV3Interface internal priceFeed;
    int256 public lastOracleWti;

    address owner1;
    address owner2;

    address public standard;
    uint256 public standardRewards;
    
    Sprotocol public bm;
    SprotocolSync public sync;

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
        require (msg.sender == owner1 || msg.sender == owner2);
        _;
    }

    constructor(address _sprotocol, address _standard, address _sync)
    {
        /**
        * Network: Binance Smart Chain
        * Aggregator: WTI - https://market.link/feeds/3bc2cf75-9ffb-4d4e-b0be-374ebe528404
        * Address: 0xb1BED6C1fC1adE2A975F54F24851c7F410e27718
        */
        priceFeed = AggregatorV3Interface(0xb1BED6C1fC1adE2A975F54F24851c7F410e27718);
        lastOracleWti = getOracleWti();

        owner1 = 0x6b80FD0457273494007813d1Dca3Fa4aB11F272e;
        owner2 = 0x7600277697748a01446B4888b65B337b7a855E6d;
        standard = _standard;
        bm = Sprotocol(_sprotocol);
        sync = SprotocolSync(_sync);

        
        pendingRebasement.executed = true;
    }

    /**
     * Returns the latest price
     */
    function getOracleWti() public view returns (int) {
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
     * @param _rebaseTwo WTI difference.
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
     * @param _currentWti Manually provide current WTI value if Chainlink Oracle is ignored.
     */
    function confirmRebasement(bool _overrule, int256 _currentWti) public isOwner
    {
        require (pendingRebasement.initiator != msg.sender, "Initiator can't confirm rebasement.");
        require (pendingRebasement.executed == false, "Rebasement already executed.");
        int256 oracleRebaseTwo;

        if (_overrule == false) {
            oracleRebaseTwo = ((getOracleWti() - lastOracleWti) * 1e10) / lastOracleWti;   
            oracleRebaseTwo = oracleRebaseTwo < 0 ? int(0) : oracleRebaseTwo;
            require (oracleRebaseTwo == pendingRebasement.rebaseTwo, "WTI rebases don't match!");
            lastOracleWti = getOracleWti();
        } else {
            oracleRebaseTwo = pendingRebasement.rebaseTwo;
            require(_currentWti != 0, "Current WTI not provided.");
            lastOracleWti = _currentWti;
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
            oracleRebaseTwo = ((getOracleWti() - lastOracleWti) * 1e10) / lastOracleWti;   
            oracleRebaseTwo = oracleRebaseTwo < 0 ? int(0) : oracleRebaseTwo;
            require (oracleRebaseTwo == pendingRebasement.rebaseTwo, "WTI rebases don't match!");
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
     * @dev Remove all WTISDR deposited on this contract. 
     */
    function withdrawWtisdr() public {
        require (msg.sender == 0x6b80FD0457273494007813d1Dca3Fa4aB11F272e || msg.sender == 0x7600277697748a01446B4888b65B337b7a855E6d, "Only Masterchief can withdraw.");
        bm.transfer(msg.sender, bm.balanceOf(address(this)));
    }

    /**
     * @dev Change the contract for pool synchronization. 
     */
    function setSyncContract(address _sync) public isOwner {
        sync = SprotocolSync(_sync);
    }
}