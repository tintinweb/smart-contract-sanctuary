pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RockPaperScissors {

  struct Player {
    address payable playerAddress;
    RPS move;
    uint256 betAmount;
  }

  IERC20 private _token;
  bool public isBet = false;
  Player public player;

  enum RPS { NONE, ROCK, PAPER, SCISSORS }

  event PlacedBet(address indexed player, uint256 amount);
  event PlayerMoved(address indexed player, uint8 move);
  event RewardPlayer(address indexed winner);

  constructor(address tokenAddress) {
     isBet = false;
    _token = IERC20(tokenAddress);
  }

  function bet(uint256 _amount) public {
    require(_amount > 0, "RockPaperScissors: amount is 0");

    if(!isBet) {
      player.playerAddress = payable(msg.sender);
      player.betAmount = _amount;
      emit PlacedBet(player.playerAddress, player.betAmount);
    } 
    _token.transferFrom(msg.sender, address(this), _amount);
    isBet = true;
  }

  function moveRPS(uint8 move) public {
    require(player.betAmount != 0, "RockPaperScissors: player no bet");    
    
    if(msg.sender == player.playerAddress) {      
      player.move = RPS(move);
      emit PlayerMoved(player.playerAddress, uint8(player.move));
      judgeWinner();
    }      
  }

  function generateRandomNum(string memory _str) private view returns (uint) {
    uint rand = uint(keccak256(abi.encodePacked(_str)));
    return (rand % 3) + 1;
  }

  function judgeWinner() private {
    address winner = address(0);
    uint8 pcMove = uint8(generateRandomNum("test"));

    if ((player.move == RPS.ROCK && RPS(pcMove) == RPS.SCISSORS) || (player.move == RPS.PAPER && RPS(pcMove) == RPS.ROCK) || (player.move == RPS.SCISSORS && RPS(pcMove) == RPS.PAPER)) {
      winner = player.playerAddress;
    } else if ((RPS(pcMove) == RPS.ROCK && player.move == RPS.SCISSORS) || (RPS(pcMove) == RPS.PAPER && player.move == RPS.ROCK) || (RPS(pcMove) == RPS.SCISSORS && player.move == RPS.PAPER)) {
      winner = address(this);
    }

    if (winner == player.playerAddress) {
      _token.transfer(winner, player.betAmount * 2);
    } 
    
    emit RewardPlayer(winner);
  }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}