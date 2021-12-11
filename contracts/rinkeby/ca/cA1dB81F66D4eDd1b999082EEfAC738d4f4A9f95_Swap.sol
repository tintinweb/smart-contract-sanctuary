// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Swap {
    address public dataFeedAddress;

    uint256 tokoFees;
    uint256 fee;
    uint256 factor = 1 ether;

    uint256 public totalLiquidtyProvided;
    uint256 public totalLiquidity;
    uint256 public publicFees;
    uint256 public rewardRate;
    uint256 public chainId;

    mapping (address =>mapping (uint256=>uint256)) offChainBalances;
    mapping (address =>mapping (uint256=>uint256)) withdrawals;

    mapping(address => bool) admin;
    mapping(address => uint256) public providedLiquidity;
    mapping(uint256 => address) public assets;
    mapping (uint256=>bool) public chainAvailable;

    // events
    event fundWithdraw( address indexed by, uint256 amount, uint256 chain);
    event swaped(address indexed by, uint256 amount, uint256 fromChain, uint256 toChain);
    event liquidWithdraw( address indexed by, uint256 amount, uint256 profit, uint256 chain);
    event liquidityProvided( address indexed by, uint256 amount, uint256 chain);

    // modifier
    modifier isAdmin(){
        require(admin[msg.sender]);
        _;
    }

    constructor(uint256 chainID, address feedAD) {
        admin[msg.sender] = true;
        chainId = chainID;
        dataFeedAddress = feedAD;
    }

    function swap(uint256 chain) external payable {
        require(chainAvailable[chain]);

        uint256 swapFee = msg.value * fee / 100;
        uint256 swapValue = msg.value - swapFee;
        
        uint256 recievingAmount = getRecieveAmount(chain, swapValue);

        totalLiquidity += swapValue;
        offChainBalances[msg.sender][chain] += recievingAmount;

        distributeFees(swapFee);
        rewardCal();

        emit swaped(msg.sender, swapValue, chainId, chain);
    }

    function release(uint256 chain, uint256 value_) external {
        require((value_ - withdrawals[msg.sender][chain]) > 0);
        require(totalLiquidtyProvided > (value_ - withdrawals[msg.sender][chain]));

        uint256 amount = value_ - withdrawals[msg.sender][chain];
        withdrawals[msg.sender][chain] = value_;
        totalLiquidity -= amount;
        totalLiquidtyProvided -= amount;

        (bool os, ) = payable(msg.sender).call{value: amount}("");
        require(os);

        emit liquidityProvided(msg.sender, amount, chainId);
    }

    function provide() external payable {
        totalLiquidtyProvided += msg.value;
        totalLiquidity += msg.value;
        providedLiquidity[msg.sender] += msg.value;

        rewardCal();
        
        emit liquidityProvided(msg.sender, msg.value, chainId);
    }

    function withdrawLP(uint256 amount) external {
        require(providedLiquidity[msg.sender] > 0);
        require(totalLiquidtyProvided > providedLiquidity[msg.sender]);

        uint256 profit = amount * rewardRate / factor;
        uint256 totalAmount = amount + profit;

        totalLiquidtyProvided -= amount;
        totalLiquidity -= amount;
        publicFees -= profit;
        providedLiquidity[msg.sender] -= amount;
        rewardCal();

        (bool os, ) = payable(msg.sender).call{value: totalAmount}("");
        require(os);

        emit liquidWithdraw(msg.sender, amount, profit, chainId);
    }

    // for data

    function getRecieveAmount(uint256 chain, uint amountInWei) public view returns(uint){
        int256 nativeAsset = getLatestPrice(dataFeedAddress);
        int256 convertionAsset = getLatestPrice(assets[chain]);
        uint256 recievingAmount = uint(nativeAsset) * amountInWei / uint(convertionAsset);

        return recievingAmount;
    }

    function getOffchainBalance(uint chain, address owner) external view returns(uint){
        return offChainBalances[owner][chain];
    }

    function getWithdrawnBalance(uint chain, address owner) external view returns(uint){
        return withdrawals[owner][chain];
    }


    // restricted

    function withdraw() isAdmin external {
        require(admin[msg.sender]);

        uint256 amount = tokoFees;
        tokoFees = 0;

        (bool os, ) = payable(msg.sender).call{value: amount}("");
        require(os);
    }

    function changeFee(uint256 amount) isAdmin external {
        require(admin[msg.sender]);

        fee = amount;
    }

    function addNetwork(uint chain, address asset) isAdmin external{
        assets[chain] = asset;
        chainAvailable[chain] = true;
    }

    function removeNetwork(uint chain) isAdmin external{
        chainAvailable[chain] = true;
    }

    // internal
    function distributeFees(uint256 fee_) internal {
        publicFees += (fee_ * 90) / 100;
        tokoFees += fee_ / 10;
    }

    function rewardCal() internal {
        uint256 reward = publicFees * factor / totalLiquidtyProvided;
        rewardRate = reward;
    }

    function getLatestPrice(address assetAddress) internal view returns (int) {
        AggregatorV3Interface  priceFeed = AggregatorV3Interface(assetAddress);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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