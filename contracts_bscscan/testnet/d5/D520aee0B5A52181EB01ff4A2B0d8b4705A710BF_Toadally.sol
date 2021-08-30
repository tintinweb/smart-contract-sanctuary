//                              .-----.
//                             /7  .  (
//                            /   .-.  \
//                           /   /   \  \
//                          / `  )   (   )
//                         / `   )   ).  \
//                       .'  _.   \_/  . |
//      .--.           .' _.' )`.        |
//     (    `---...._.'   `---.'_)    ..  \
//      \            `----....___    `. \  |
//       `.           _ ----- _   `._  )/  |
//         `.       /"  \   /"  \`.  `._   |
//           `.    ((O)` ) ((O)` ) `.   `._\
//             `-- '`---'   `---' )  `.    `-.
//                /                  ` \      `-.
//              .'                      `.       `.
//             /                     `  ` `.       `-.
//      .--.   \ ===._____.======. `    `   `. .___.--`     .''''.
//     ' .` `-. `.                )`. `   ` ` \          .' . '  8)
//    (8  .  ` `-.`.               ( .  ` `  .`\      .'  '    ' /
//     \  `. `    `-.               ) ` .   ` ` \  .'   ' .  '  /
//      \ ` `.  ` . \`.    .--.     |  ` ) `   .``/   '  // .  /
//       `.  ``. .   \ \   .-- `.  (  ` /_   ` . / ' .  '/   .'
//         `. ` \  `  \ \  '-.   `-'  .'  `-.  `   .  .'/  .'
//           \ `.`.  ` \ \    ) /`._.`       `.  ` .  .'  /
//            |  `.`. . \ \  (.'               `.   .'  .'
//         __/  .. \ \ ` ) \                     \.' .. \__
//  .-._.-'     '"  ) .-'   `.                   (  '"     `-._.--.
// (_________.-====' / .' /\_)`--..__________..-- `====-. _________)
//
//     ______     __  _            __     ______                __
//    / ____/  __/ /_(_)___  _____/ /_   /_  __/___  ____ _____/ /____
//   / __/ | |/_/ __/ / __ \/ ___/ __/    / / / __ \/ __ `/ __  / ___/
//  / /____>  </ /_/ / / / / /__/ /_     / / / /_/ / /_/ / /_/ (__  )
// /_____/_/|_|\__/_/_/ /_/\___/\__/    /_/  \____/\__,_/\__,_/____/
//
// extincttoads.com
// t.me/extincttoads
// extincttoads
//
// Hearthstone on the blockchain

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './Context.sol';
import './Ownable.sol';
import './SafeMath.sol';

import './IERC20.sol';
import './ERC20.sol';

import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';

contract Toadally is ERC20, Ownable {
  using SafeMath for uint256;

  string private _name;
  string private _symbol;

  uint256 private _liquidityFee = 2; // Self explanatory
  uint256 private _molassesFund = 4; // Marketing fund
  uint256 private _lillyPadFund = 4; // Play 2 Earn Buyback
  uint256 private _fTotal = _liquidityFee + _molassesFund + _lillyPadFund; // Total fees
  
  uint256 private constant _tTotal = 1e12 * 10**18;
  uint8 private constant _decimals = 18;

  IUniswapV2Router02 public uniswapV2Router; // What our tx's will be routed through (Uniswap / Pancake / Quick)
  address public immutable uniswapV2Pair;

  bool public enabledSwap = false; // This is for enabling trading

  uint256 public maxBuyPercent = 10; // The percentage users will be able to buy
  uint256 private maxBuyAmount = (_tTotal / 100) * maxBuyPercent;

  uint256 public maxSellPercent = 100; // The percentage users will be able to swap (or sell)
  uint256 private maxSellAmount = (_tTotal / 100) * maxSellPercent;

  uint256 public maxWalletAmount = _tTotal;

  mapping(address => bool) private _isExcluded; // Match excluded addresses

  event blacklistUpdated(address indexed user, bool value);
  event swapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event swapETHForTokens(uint256 amountIn, address[] path);

  constructor(
    string memory name,
    string memory symbol,
    address router
  ) ERC20(name, symbol) {
    _name = name;
    _symbol = symbol;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = _uniswapV2Pair;

    _mint(msg.sender, _tTotal); // _mint is an internal function, and as such cannot be called outside of this construction (safu)
    emit Transfer(address(0), msg.sender, _tTotal);
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public pure override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public pure override returns (uint256) {
    return _tTotal;
  }

  function totalFees() public view returns (uint256) {
    return _fTotal;
  }
}