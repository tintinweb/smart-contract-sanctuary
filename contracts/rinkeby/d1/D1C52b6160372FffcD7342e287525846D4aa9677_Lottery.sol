// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./PancakeInterface.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract Lottery is Ownable {
  address[] public players; // All the players will be saved in this array.
  uint256 public entryFee; // This is the amount of wei as entry fee to be a player. 
  IERC20 public immutable token = IERC20(0x94Bdcdf666B82e2359c1809849512dE3cCD819E5); // ADACash token instance.
  uint256 public lotteryFundCollected = 0; // amount of funds collected in each lottery will saved here till before it ends.
  IERC20 public immutable cardano = IERC20(0x94Bdcdf666B82e2359c1809849512dE3cCD819E5); // Cardano token instance to collect rewards and withdraw them.

  uint8 public winnerPercent = 80; // 80 % of tokens will go to the winner's wallet.
  uint8 public contractPercent = 15; // 15 % of tokens will stay in the contract.
  uint8 public burnPercent = 5; // 5% of tokens will go to the dead address.
  uint256 public timeInterval = 7*24*60*60; // Time interval for a lottery currently 7 days.
  uint256 public lastLotteryStartingTime = block.timestamp; // This is last lottery starting time.
  bool public paused = false; // owner can pause the lottery So, any one can't participate if the lottery is paused.

  IPancakeRouter02 public immutable pancakeV2Router = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // pancake router instance.

  constructor (uint256 _entryFee) {
    entryFee = _entryFee; // Assigning the entry fee.
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state; // can pause and unpause the lottery.
  }

  function changeTimeInterval(uint8 _days, uint256 _seconds) public onlyOwner {
    timeInterval = _days*(24*60*60) + _seconds; // can change the time interval with number of days and additional seconds.
  }

  // change the _winnerPercent, _contractPercent, _burnPercent.
  //  Sum of all three percentages must be equal to 100.
  function changeRewardPercent(uint8 _winnerPercent, uint8 _contractPercent, uint8 _burnPercent) public onlyOwner {
    require(_winnerPercent + _contractPercent + _burnPercent == uint8(100), "Sum should be 100 of total reward percent"); 
    winnerPercent = _winnerPercent;
    contractPercent = _contractPercent;
    burnPercent = _burnPercent;
  }

  // Private function to swap bnb for tokens.
  function swap_bnb_for_tokens(uint256 _amount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = pancakeV2Router.WETH();
      path[1] = address(token);

      // make the swap
      pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
          0, // accept any amount of ETH
          path,
          address(this),
          block.timestamp
      );
  }

  // function for a player to take part in a lottery by paying bnb.
  // It will swap the bnb's to ADACash tokens from pancake swap.
  // Reward will be 80% of total deposit will go to the winner's wallet.
  // 15 % will be stay in the contract and 5% of tokens will burn.

  function enter() public payable {
    require(msg.value >= entryFee);
    require(!paused, "Lottery: paused");
    players.push(msg.sender);
    uint256 initialBalance = token.balanceOf(address(this));
    swap_bnb_for_tokens(msg.value);
    // added balance will be the amount of tokens player add.
    lotteryFundCollected += token.balanceOf(address(this)) - initialBalance;
  }

  // private function to pick a random number.
  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  }

  // can be call by the owner after the lottery time ends. 
  // it will select a random player and make it winner.
  // it will reinitialize the lottery after transfering the rewards.

  function pickWinner() public onlyOwner {
    require(lastLotteryStartingTime + timeInterval >= block.timestamp, "Lottery not finished.");
    uint index = random() % players.length;
    token.transfer(players[index], (lotteryFundCollected*winnerPercent)/100);
    token.transfer(0x000000000000000000000000000000000000dEaD, (lotteryFundCollected*burnPercent)/100);
    players = new address[](0);
    lotteryFundCollected = 0;
    lastLotteryStartingTime = block.timestamp;
  }

  // This is to get player array in single call.
  function getPlayers() public view returns (address[] memory) {
    return players;
  }

  // owner can withdraw 15% rewarded tokens which is saved in the contract it self.
  // need to put address as an argument where he want to send those tokens.

  function withdrawRewardedTokens(address _address) public onlyOwner {
    uint256 extraTokens = token.balanceOf(address(this)) - lotteryFundCollected;
    token.transfer(_address, extraTokens);
  }

  // owner can withdraw the cardano by calling this function.
  // need to put address as an argument where he want to send those tokens.

  function withdrawCardano(address _address) public onlyOwner {
    cardano.transfer(_address, cardano.balanceOf(address(this)));
  }

  // owner can change the entry fee for the lottery.
  // Please make sure that the lottery is ends and restarted again before calling this function.
  // owner can also pause the lottery while calling this function to prevent players to enter the lottery.
  function changeEntryFee(uint256 _entryFee) public onlyOwner {
    entryFee = _entryFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}