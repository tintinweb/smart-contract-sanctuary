// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPharoCover {
    function payoutActivePoliciesForCurrentPharo() external;
    function mintObelisk(address treasury, bytes memory data) external;
}

interface ITokenPriceFeed {
    function latestRoundData() external 
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function requestValue() external;
}


contract ShibPayoutKeeper is KeeperCompatibleInterface {
    address public constant treasury = 0x3f15B8c6F9939879Cb030D6dd935348E57109637;

    IPharoCover private _pharoCoverInterface;
    ITokenPriceFeed private _tokenPriceFeed;

    mapping(uint256 => uint256) public answers;

    constructor(address pharoCoverAddress, address priceFeedAddress) public {
        _pharoCoverInterface = IPharoCover(pharoCoverAddress);
        _tokenPriceFeed = ITokenPriceFeed(priceFeedAddress);
    }

    function checkUpkeep
    (
        bytes calldata checkData
    ) 
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // get the latest round data
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) 
                = _tokenPriceFeed.latestRoundData();

        (uint256 percentage) = abi.decode(performData, (uint256));
        
        answers[uint256(roundId)] = uint256(answer);
        uint256(answer);
        uint256 prevPrice = answers[roundId] - 1;
        // 15% swing in 15 minutes will trigger a payout on all policies 
        // covering this event.
        uint256 lowLimit = prevPrice - (prevPrice * percentage) / 1000;
        // check if we need to perform upkeep
        if(uint256(answer) < lowLimit) {
            upkeepNeeded = true;
        }
        
        if(upkeepNeeded) { 
            // set up the performData to send to performUpkeep
            performData = abi.encodePacked(uint256(answer), uint256(roundId), updatedAt, percentage);

            return (upkeepNeeded, performData);
        }
        
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint256 price, uint256 roundId, uint256 updatedAt, uint256 percentage) = abi.decode(performData, (uint256, uint256, uint256, uint256));

        _pharoCoverInterface.payoutActivePoliciesForCurrentPharo();
        // Mint the Obelisk Core NFT ~ metadata can be updated later also
        _pharoCoverInterface.mintObelisk(treasury, performData);
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