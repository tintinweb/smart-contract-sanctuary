// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPharoCover {
    function payoutActivePoliciesForCurrentPharo() external;
    function mintObelisk(address treasury) external;
}

interface ITokenPriceFeed {
    function latestRoundData() external 
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function requestValue() external;
}

/// @title Pay Master Contract
/// @author jaxcoder
/// @notice Handles automated payouts based on event status
/// @dev testing with counter... adding some other stuff for later use
contract TokenMonitor is KeeperCompatibleInterface {
    // Interface
    IPharoCover private _pharoCoverInterface;
    ITokenPriceFeed private _tokenPriceFeed;

    address public constant treasury = 0x3f15B8c6F9939879Cb030D6dd935348E57109637;

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;
    uint256 public shibPrice = 0;

    mapping(uint256 => uint256) public answers;

    constructor(uint updateInterval, address pharoCoverAddress, address priceFeedAddress) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;

      _pharoCoverInterface = IPharoCover(pharoCoverAddress);
      _tokenPriceFeed = ITokenPriceFeed(priceFeedAddress);
    }

    /// @dev returns whether or not to call the payout function
    ///      with some data in performData for the payouts and 
    ///      minting of the Obelisk.
    function checkUpkeep
    (
        bytes calldata checkData
    ) 
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // check the interval to see if we need to check the price
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // _tokenPriceFeed.requestValue(); // todo: how to delay after this is called??
        // (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) 
        //     = _tokenPriceFeed.latestRoundData();

        // answers[uint256(roundId)] = uint256(answer);
        
        // set up the performData to send to performUpkeep
        //performData = abi.encodePacked(uint256(answer), uint256(roundId), updatedAt);
        //return (true, performData);
    }

    /// @dev this will do the actual upkeep and call the payout function
    /// @notice this will check for a % price fluctuation over a 15 minute interval.
    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        // _tokenPriceFeed.requestValue();
        // (uint256 price, uint256 roundId, uint256 updatedAt) 
        //     = abi.decode(performData, (uint256, uint256, uint256));

        // (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) 
        //      = _tokenPriceFeed.latestRoundData();
        
        shibPrice = 50;//uint256(answer);
        // uint256 prevPrice = answers[roundId] - 1;
        // 15% swing in 15 minutes will trigger a payout on all policies 
        // covering this event.
        // uint256 lowLimit = prevPrice - (prevPrice * 1500) / 1000;
        // uint256 highLimit = prevPrice + (prevPrice * 1500) / 1000;

        // if(shibPrice > highLimit || shibPrice < lowLimit) {
        //     _pharoCoverInterface.payoutActivePoliciesForCurrentPharo();
        // }
        
        // Mint the Obelisk Core NFT ~ metadata can be updated later also
        //_pharoCoverInterface.mintObelisk(treasury);
    }   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}