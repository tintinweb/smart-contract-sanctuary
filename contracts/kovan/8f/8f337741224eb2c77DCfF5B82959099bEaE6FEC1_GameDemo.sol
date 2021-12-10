// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameDemo {

  // Nonce should be private, it is used to help generate randomness based on past behaviour
  uint256 private nonce;
  uint256[] private nonceIncrements = [31054527504, 22181805360, 17252515280, 14115694320, 11944049040, 9704539845, 9133684560, 8172244080, 6750984240, 5354228880];

  // Keep track of total Eth balance of house, as well as liquidity shares
  uint256 public totalBalance; // tracks money in contract
  uint256 public totalLiquidity; // tracks total liquidity deposited. Only at start, money units = liquidity units
  mapping (address => uint256) public liquidity; // liquidity by address

  // House edge is houseEdgeNumerator/houseEdgeDenominator,
  // e.g. 5/100 is 5% advantage, so house stake is 95% of player stake
  uint256 public houseEdgeNumerator;
  uint256 public houseEdgeDenominator;

  // Aggregate statistics
  uint256 public totalPlays;
  uint256 public totalStakePlayer;
  uint256 public totalStakeHouse;
  uint256 public totalValueReturned;

  // Statistics from last game
  uint256 public lastNumber;
  uint256 public lastThreshold;
  uint256 public lastLimit;
  uint256 public lastStakePlayer;
  uint256 public lastStakeHouse;
  uint256 public lastValueReturned;

  constructor() {
    // In this setup, 3/100 = 3% house edge, so house returns around $97 on every $100 played
    houseEdgeNumerator = 3;
    houseEdgeDenominator = 100;
    incrementNonce(1);
  }

  function liquidityValue(address addr) public view returns (uint256) {
    if (totalLiquidity == 0) {
      return 0;
    }
    return liquidity[addr] * totalBalance / totalLiquidity;
  }

  function incrementNonce(uint256 index) private {
    nonce += nonceIncrements[index % nonceIncrements.length];
  }

  function deposit() public payable returns (uint256) {
    incrementNonce(2);
    uint256 ethDeposit = msg.value;
    require(ethDeposit > 0, "$ETH to deposit must be greater than zero");
    uint256 liqDeposit = totalBalance == 0 ? ethDeposit : (ethDeposit * totalLiquidity) / totalBalance;
    // After initial deposit, should not let totalBalance go back to zero unless liquidity also goes back to zero
    // (L'Hôpital's rule applied to formula for liqDeposit)
    // This is ensured by not allowing more than ~10% of house money to be staked on any individual game (*)
    totalBalance += ethDeposit;
    totalLiquidity += liqDeposit;
    liquidity[msg.sender] += liqDeposit;
    return liqDeposit;
  }

  function withdraw(uint256 liqWithdraw) public returns (uint256) {
    incrementNonce(3);
    require(0 < liqWithdraw, "Liquidity amount to withdraw must be greater than zero");
    require(liqWithdraw <= liquidity[msg.sender], "User has insufficient liquidity");
    uint256 ethWithdraw = (liqWithdraw * totalBalance) / totalLiquidity;
    totalBalance -= ethWithdraw;
    totalLiquidity -= liqWithdraw;
    liquidity[msg.sender] -= liqWithdraw;
    (bool sent, ) = msg.sender.call{value: ethWithdraw}("");
    require(sent, "Failed to withdraw user's $ETH");
    return ethWithdraw;
  }

  function withdrawAll() public returns (uint256) {
    incrementNonce(4);
    return withdraw(liquidity[msg.sender]);
  }

  // More reliable alternative would be using Chainlink VRF
  function getRandom(uint256 threshold, uint256 limit) public returns (uint256) {
    incrementNonce(5);
    uint256 bh = uint(blockhash(block.number - 1));
    uint256 bt = block.timestamp;
    uint256 res = 1 + uint(keccak256(abi.encodePacked(bh, bt, nonce)));
    lastNumber = 1 + (res % limit); // between 1 and limit
    lastThreshold = threshold;
    lastLimit = limit;
    return lastNumber;
  }

  function playGameCoinFlip1In2() public payable {
    incrementNonce(6);
    playGameGeneral(2, 2);
  }

  function playGameDiceRoll1In6() public payable {
    incrementNonce(7);
    playGameGeneral(6, 6);
  }

  // Game is to generate a random number in range 1..limit
  // Player wins if number is in range threshold..limit
  // House wins if number is in range 1..(threshold-1)
  function playGameGeneral(uint256 threshold, uint256 limit) public payable {
    incrementNonce(8);
    totalPlays += 1;
    lastValueReturned = 0;
    require(0 < totalBalance, "Liquidity must be deposited before play can commence");
    require(0 < threshold, "Threshold must be greater than 0");
    require(threshold <= limit, "Threshold cannot be greater than limit");
    lastStakePlayer = msg.value;
    totalStakePlayer += lastStakePlayer;
    totalBalance += lastStakePlayer; // payable function, so player has already deposited
    require(0 < lastStakePlayer, "Put some money in, you cheapskate!");
    uint256 widthPlayerWin = limit - (threshold - 1);
    uint256 widthHouseWin = limit - widthPlayerWin;
    lastStakeHouse = (lastStakePlayer * (houseEdgeDenominator - houseEdgeNumerator) * widthHouseWin) / (houseEdgeDenominator * widthPlayerWin);
    totalStakeHouse += lastStakeHouse;
    require(lastStakeHouse * 10 <= totalBalance, "House stake exceeds 10% - please try again with lower stake"); // (*)
    uint256 randomInteger = getRandom(threshold, limit);
    if (threshold <= randomInteger) {
      // Player wins! :D
      incrementNonce(9);
      lastValueReturned = lastStakePlayer + lastStakeHouse;
      totalBalance -= lastValueReturned;
      totalValueReturned += lastValueReturned;
      (bool sent, ) = msg.sender.call{value: lastValueReturned}("");
      require(sent, "Failed to send user $ETH winnings");
    } else {
      // Player loses :(
      incrementNonce(10);
    }
  }  
}