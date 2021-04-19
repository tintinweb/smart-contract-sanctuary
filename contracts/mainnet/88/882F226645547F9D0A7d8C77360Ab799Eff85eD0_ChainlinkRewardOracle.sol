/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

// File: @chainlink\contracts\src\v0.7\interfaces\AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// File: contracts\ChainlinkRewardOracle.sol



pragma solidity ^0.7.1;


contract ChainlinkRewardOracle {

  mapping(uint16 => uint256[]) public base_SFI_rewards;
  mapping(uint16 => uint256[]) public bonus_SFI_rewards;

  mapping(uint256 => AggregatorV3Interface) public pool_feed;
  mapping(uint256 => uint256) public base_asset_price_begin;
  mapping(uint256 => uint256) public base_asset_price_end;
  mapping(uint256 => uint256) public limit; // If end price is less than X percent of `begin` use maximum reward; 1e18 scale

  mapping(uint16 => uint16[]) public tracked_pools;

  enum states {UNSET, REWARD_SET, STARTED, ENDED}
  mapping(uint16 => states) public epoch_state;

  address public governance;
  address public _new_governance;
  address public strategy;

  constructor(address strategyAddr) {
    governance = msg.sender;
    strategy = strategyAddr;
  }

  function set_feed(uint16 epoch, uint16 pool, address feedAddr, uint256 maxPct, uint256 alt_reward) public {
    require(msg.sender == strategy || msg.sender == governance, "must be strategy or gov");
    require(epoch_state[epoch] == states.REWARD_SET, "rewards must be set and not started");
    require(pool < base_SFI_rewards[epoch].length, "cannot feed pool with undefined reward");
    require(maxPct < 1 ether, "can't award on no change"); // Prevent divide by zero
    uint256 index = pack(epoch, pool);
    pool_feed[index] = AggregatorV3Interface(feedAddr);
    tracked_pools[epoch].push(pool);
    limit[index] = maxPct;
    bonus_SFI_rewards[epoch][pool] = alt_reward;
  }

  function set_base_reward(uint16 epoch, uint256[] calldata SFI_rewards) public {
    require(msg.sender == strategy || msg.sender == governance, "must be strategy or gov");
    require(epoch_state[epoch] == states.UNSET || epoch_state[epoch] == states.REWARD_SET, "must not be started");
    epoch_state[epoch] = states.REWARD_SET;
    base_SFI_rewards[epoch] = SFI_rewards;
    bonus_SFI_rewards[epoch] = SFI_rewards;
  }

  event BeginEpoch(uint16 epoch);

  function begin_epoch(uint16 epoch) public {
    require(msg.sender == strategy || msg.sender == governance, "must be strategy or gov");
    require(epoch_state[epoch] == states.REWARD_SET, "must set rewards first");
    epoch_state[epoch] = states.STARTED;
    emit BeginEpoch(epoch);
    for (uint256 i = 0; i < tracked_pools[epoch].length; i++) {
      uint256 index = pack(epoch, tracked_pools[epoch][i]);
      base_asset_price_begin[index] = get_latest_price(index);
    }
  }

  event EndEpoch(uint16 epoch);

  function end_epoch(uint16 epoch) public {
    require(msg.sender == strategy || msg.sender == governance, "must be strategy or gov");
    require(epoch_state[epoch] == states.STARTED, "must be started");
    epoch_state[epoch] = states.ENDED;
    emit EndEpoch(epoch);
    for (uint256 i = 0; i < tracked_pools[epoch].length; i++) {
      uint256 index = pack(epoch, tracked_pools[epoch][i]);
      base_asset_price_end[index] = get_latest_price(index);
    }
  }

  event OracleGetReward(uint256 index, uint256 begin, uint256 end, uint256 reward);

  function get_reward(uint16 epoch, uint16 pool) public view returns (uint256 index, uint256 begin, uint256 end, uint256 reward) {
    require(epoch_state[epoch] == states.ENDED, "must be ended");
    if (pool > base_SFI_rewards[epoch].length) {
      return (index, begin, end, reward);
    }

    index = pack(epoch, pool);

    if (pool_feed[index] == AggregatorV3Interface(0x0)) {
      reward = base_SFI_rewards[epoch][pool];
      return (index, begin, end, reward);
    }

    begin = base_asset_price_begin[index];
    end = base_asset_price_end[index];

    if (end >= begin) {
      reward = base_SFI_rewards[epoch][pool];
      return (index, begin, end, reward);
    }

    uint256 pct = limit[index];
    uint256 max_price_move = begin * pct / 1e18;

    reward = base_SFI_rewards[epoch][pool] + calc_reward_bonus(begin, end, pct, max_price_move, bonus_SFI_rewards[epoch][pool]);

    return (index, begin, end, reward);
  }

  function calc_reward_bonus(uint256 begin, uint256 end, uint256 pct, uint256 max_price_move, uint256 bonus_SFI_reward) internal pure returns (uint256) {
    if (end <= max_price_move) return bonus_SFI_reward;
    uint256 delta = (begin - end);
    uint256 delta_pct = (delta * 1 ether) / begin;
    uint256 reward_multiplier = delta_pct * 1 ether / (1 ether - pct);
    return bonus_SFI_reward * reward_multiplier / 1 ether;
  }

  function get_latest_price(uint256 index) internal view returns (uint256) {
    AggregatorV3Interface priceFeed = pool_feed[index];
    require(priceFeed != AggregatorV3Interface(0x0), "no feed found");
    // uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound
    (,int price,,,) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function pack(uint16 epoch, uint16 pool) internal pure returns (uint256) {
    return uint256(epoch) | uint256(pool) << 16;
  }

  //  function unpack(uint256 value) public pure returns (uint16, uint16) {
  //    return (uint16(value), uint16(value >> 16));
  //  }

  event SetGovernance(address prev, address next);
  event AcceptGovernance(address who);

  function set_governance(address to) external {
    require(msg.sender == governance, "must be governance");
    _new_governance = to;
    emit SetGovernance(msg.sender, to);
  }

  function accept_governance() external {
    require(msg.sender == _new_governance, "must be new governance");
    governance = msg.sender;
    emit AcceptGovernance(msg.sender);
  }

  function set_strategy(address to) external {
    require(msg.sender == governance, "must be governance");
    strategy = to;
  }
}