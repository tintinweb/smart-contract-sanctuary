pragma solidity ^0.5.0;

import './Initializable.sol';

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuardUpgradeSafe is Initializable {
  // counter to allow mutex lock with only one SSTORE operation
  uint private _guardCounter;

  function __ReentrancyGuardUpgradeSafe__init() internal initializer {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter, 'ReentrancyGuard: reentrant call');
  }

  uint[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(
      _initializing || _isConstructor() || !_initialized,
      'Initializable: contract is already initialized'
    );

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function _isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint cs;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      cs := extcodesize(self)
    }
    return cs == 0;
  }
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import './uniswap/IUniswapV2Router02.sol';
import './SafeToken.sol';
import './Strategy.sol';

contract StrategyWithdrawMinimizeTrading is Ownable, ReentrancyGuard, Strategy {
  using SafeToken for address;
  using SafeMath for uint;

  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  address public wbnb;

  mapping(address => bool) public whitelistedTokens;

  /// @dev Create a new withdraw minimize trading strategy instance.
  /// @param _router The Uniswap router smart contract.
  constructor(IUniswapV2Router02 _router) public {
    factory = IUniswapV2Factory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
  }

  /// @dev Set whitelisted tokens
  /// @param tokens Token list to set whitelist status
  /// @param statuses Status list to set tokens to
  function setWhitelistTokens(address[] calldata tokens, bool[] calldata statuses)
    external
    onlyOwner
  {
    require(tokens.length == statuses.length, 'tokens & statuses length mismatched');
    for (uint idx = 0; idx < tokens.length; idx++) {
      whitelistedTokens[tokens[idx]] = statuses[idx];
    }
  }

  /// @dev Execute worker strategy. Take LP tokens. Return fToken + BNB.
  /// @param user User address to withdraw liquidity.
  /// @param debt Debt amount in WAD of the user.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint debt,
    bytes calldata data
  ) external payable nonReentrant {
    // 1. Find out what farming token we are dealing with.
    (address fToken, uint minFToken) = abi.decode(data, (address, uint));
    require(whitelistedTokens[fToken], 'token not whitelisted');
    IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, wbnb));
    // 2. Remove all liquidity back to BNB and farming tokens.
    lpToken.approve(address(router), uint(-1));
    router.removeLiquidityETH(fToken, lpToken.balanceOf(address(this)), 0, 0, address(this), now);
    // 3. Convert farming tokens to BNB.
    address[] memory path = new address[](2);
    path[0] = fToken;
    path[1] = wbnb;
    fToken.safeApprove(address(router), 0);
    fToken.safeApprove(address(router), uint(-1));
    uint balance = address(this).balance;
    if (debt > balance) {
      // Convert some farming tokens to BNB.
      uint remainingDebt = debt.sub(balance);
      router.swapTokensForExactETH(remainingDebt, fToken.myBalance(), path, address(this), now);
    }
    // 4. Return BNB back to the original caller.
    uint remainingBalance = address(this).balance;
    SafeToken.safeTransferBNB(msg.sender, remainingBalance);
    // 5. Return remaining farming tokens to user.
    uint remainingFToken = fToken.myBalance();
    require(remainingFToken >= minFToken, 'insufficient farming tokens received');
    if (remainingFToken > 0) {
      fToken.safeTransfer(user, remainingFToken);
    }
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  function() external payable {}
}

pragma solidity >=0.5.0;

interface IUniswapV2Router02 {
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
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

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
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
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

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);

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
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
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

pragma solidity 0.5.16;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint);
}

library SafeToken {
  function myBalance(address token) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeApprove');
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransfer');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransferFrom');
  }

  function safeTransferBNB(address to, uint value) internal {
    (bool success, ) = to.call.value(value)(new bytes(0));
    require(success, '!safeTransferBNB');
  }
}

pragma solidity 0.5.16;

interface Strategy {
  /// @dev Execute worker strategy. Take LP tokens + BNB. Return LP tokens + BNB.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The user's total debt, for better decision making context.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint debt,
    bytes calldata data
  ) external payable;
}

pragma solidity 0.5.16;

import './Initializable.sol';

contract Governable is Initializable {
  address public governor; // The current governor.
  address public pendingGovernor; // The address pending to become the governor once accepted.

  modifier onlyGov() {
    require(msg.sender == governor, 'not the governor');
    _;
  }

  /// @dev Initialize the bank smart contract, using msg.sender as the first governor.
  function __Governable__init() internal initializer {
    governor = msg.sender;
    pendingGovernor = address(0);
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param _pendingGovernor The address to become the pending governor.
  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'not the pending governor');
    pendingGovernor = address(0);
    governor = msg.sender;
  }
}

pragma solidity >=0.5.0;

import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

library UniswapV2Library {
  using SafeMath for uint;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    return IUniswapV2Factory(factory).getPair(tokenA, tokenB); // For easy testing
    // (address token0, address token1) = sortTokens(tokenA, tokenB);
    // pair = address(
    //   uint256(
    //     keccak256(
    //       abi.encodePacked(
    //         hex'ff',
    //         factory,
    //         keccak256(abi.encodePacked(token0, token1)),
    //         hex'fc4928e335b531bb85a6d9454f46863f9d6101351e3e8b84620b1806d4a3fcb3' // init code hash
    //       )
    //     )
    //   )
    // );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, ) =
      IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) internal pure returns (uint amountB) {
    require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn.mul(998);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn.mul(amountOut).mul(1000);
    uint denominator = reserveOut.sub(amountOut).mul(998);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint amountIn,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path
  ) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

pragma solidity 0.5.16;
import './IWBNB.sol';

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// pragma solidity ^0.4.18;

contract WBNB is IWBNB {
  string public name = 'Wrapped BNB';
  string public symbol = 'WBNB';
  uint8 public decimals = 18;

  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);
  event Deposit(address indexed dst, uint wad);
  event Withdrawal(address indexed src, uint wad);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  function() external payable {
    deposit();
  }

  function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint wad) public {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    msg.sender.transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }

  function totalSupply() public view returns (uint) {
    return address(this).balance;
  }

  function approve(address guy, uint wad) public returns (bool) {
    allowance[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

  function transfer(address dst, uint wad) public returns (bool) {
    return transferFrom(msg.sender, dst, wad);
  }

  function transferFrom(
    address src,
    address dst,
    uint wad
  ) public returns (bool) {
    require(balanceOf[src] >= wad);

    if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
      require(allowance[src][msg.sender] >= wad);
      allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    emit Transfer(src, dst, wad);

    return true;
  }
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

pragma solidity >=0.5.0;

interface IWBNB {
  function deposit() external payable;

  function transfer(address to, uint value) external returns (bool);

  function withdraw(uint) external;
}

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import './GoblinConfig.sol';
import './PriceOracle.sol';
import './SafeToken.sol';

interface IPancakeswapGoblin {
  function lpToken() external view returns (IUniswapV2Pair);
}

contract PancakeswapGoblinConfig is Ownable, GoblinConfig {
  using SafeToken for address;
  using SafeMath for uint;

  struct Config {
    bool acceptDebt;
    uint64 workFactor;
    uint64 killFactor;
    uint64 maxPriceDiff;
  }

  PriceOracle public oracle;
  mapping(address => Config) public goblins;

  constructor(PriceOracle _oracle) public {
    oracle = _oracle;
  }

  /// @dev Set oracle address. Must be called by owner.
  function setOracle(PriceOracle _oracle) external onlyOwner {
    oracle = _oracle;
  }

  /// @dev Set goblin configurations. Must be called by owner.
  function setConfigs(address[] calldata addrs, Config[] calldata configs) external onlyOwner {
    uint len = addrs.length;
    require(configs.length == len, 'bad len');
    for (uint idx = 0; idx < len; idx++) {
      goblins[addrs[idx]] = Config({
        acceptDebt: configs[idx].acceptDebt,
        workFactor: configs[idx].workFactor,
        killFactor: configs[idx].killFactor,
        maxPriceDiff: configs[idx].maxPriceDiff
      });
    }
  }

  /// @dev Return whether the given goblin is stable, presumably not under manipulation.
  function isStable(address goblin) public view returns (bool) {
    IUniswapV2Pair lp = IPancakeswapGoblin(goblin).lpToken();
    address token0 = lp.token0();
    address token1 = lp.token1();
    // 1. Check that reserves and balances are consistent (within 1%)
    (uint r0, uint r1, ) = lp.getReserves();
    uint t0bal = token0.balanceOf(address(lp));
    uint t1bal = token1.balanceOf(address(lp));
    require(t0bal.mul(100) <= r0.mul(101), 'bad t0 balance');
    require(t1bal.mul(100) <= r1.mul(101), 'bad t1 balance');
    // 2. Check that price is in the acceptable range
    (uint price, uint lastUpdate) = oracle.getPrice(token0, token1);
    require(lastUpdate >= now - 7 days, 'price too stale');
    uint lpPrice = r1.mul(1e18).div(r0);
    uint maxPriceDiff = goblins[goblin].maxPriceDiff;
    require(lpPrice <= price.mul(maxPriceDiff).div(10000), 'price too high');
    require(lpPrice >= price.mul(10000).div(maxPriceDiff), 'price too low');
    // 3. Done
    return true;
  }

  /// @dev Return whether the given goblin accepts more debt.
  function acceptDebt(address goblin) external view returns (bool) {
    require(isStable(goblin), '!stable');
    return goblins[goblin].acceptDebt;
  }

  /// @dev Return the work factor for the goblin + BNB debt, using 1e4 as denom.
  function workFactor(
    address goblin,
    uint /* debt */
  ) external view returns (uint) {
    require(isStable(goblin), '!stable');
    return uint(goblins[goblin].workFactor);
  }

  /// @dev Return the kill factor for the goblin + BNB debt, using 1e4 as denom.
  function killFactor(
    address goblin,
    uint /* debt */
  ) external view returns (uint) {
    require(isStable(goblin), '!stable');
    return uint(goblins[goblin].killFactor);
  }
}

pragma solidity 0.5.16;

interface GoblinConfig {
  /// @dev Return whether the given goblin accepts more debt.
  function acceptDebt(address goblin) external view returns (bool);

  /// @dev Return the work factor for the goblin + BNB debt, using 1e4 as denom.
  function workFactor(address goblin, uint debt) external view returns (uint);

  /// @dev Return the kill factor for the goblin + BNB debt, using 1e4 as denom.
  function killFactor(address goblin, uint debt) external view returns (uint);
}

pragma solidity 0.5.16;

interface PriceOracle {
  /// @dev Return the wad price of token0/token1, multiplied by 1e18
  /// NOTE: (if you have 1 token0 how much you can sell it for token1)
  function getPrice(address token0, address token1)
    external
    view
    returns (uint price, uint lastUpdate);
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import './uniswap/IUniswapV2Router02.sol';
import './SafeToken.sol';
import './Strategy.sol';

contract StrategyLiquidate is Ownable, ReentrancyGuard, Strategy {
  using SafeToken for address;

  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  address public wbnb;

  mapping(address => bool) public whitelistedTokens;

  /// @dev Create a new liquidate strategy instance.
  /// @param _router The Uniswap router smart contract.
  constructor(IUniswapV2Router02 _router) public {
    factory = IUniswapV2Factory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
  }

  /// @dev Set whitelisted tokens
  /// @param tokens Token list to set whitelist status
  /// @param statuses Status list to set tokens to
  function setWhitelistTokens(address[] calldata tokens, bool[] calldata statuses)
    external
    onlyOwner
  {
    require(tokens.length == statuses.length, 'tokens & statuses length mismatched');
    for (uint idx = 0; idx < tokens.length; idx++) {
      whitelistedTokens[tokens[idx]] = statuses[idx];
    }
  }

  /// @dev Execute worker strategy. Take LP tokens. Return BNB.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address, /* user */
    uint, /* debt */
    bytes calldata data
  ) external payable nonReentrant {
    // 1. Find out what farming token we are dealing with.
    (address fToken, uint minBNB) = abi.decode(data, (address, uint));
    require(whitelistedTokens[fToken], 'token not whitelisted');
    IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, wbnb));
    // 2. Remove all liquidity back to BNB and farming tokens.
    lpToken.approve(address(router), uint(-1));
    router.removeLiquidityETH(fToken, lpToken.balanceOf(address(this)), 0, 0, address(this), now);
    // 3. Convert farming tokens to BNB.
    address[] memory path = new address[](2);
    path[0] = fToken;
    path[1] = wbnb;
    fToken.safeApprove(address(router), 0);
    fToken.safeApprove(address(router), uint(-1));
    router.swapExactTokensForETH(fToken.myBalance(), 0, path, address(this), now);
    // 4. Return all BNB back to the original caller.
    uint balance = address(this).balance;
    require(balance >= minBNB, 'insufficient BNB received');
    SafeToken.safeTransferBNB(msg.sender, balance);
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  function() external payable {}
}

pragma solidity 0.5.16;

interface BankConfig {
  /// @dev Return minimum BNB debt size per position.
  function minDebtSize() external view returns (uint);

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint);

  /// @dev Return the bps rate for reserve pool.
  function getReservePoolBps() external view returns (uint);

  /// @dev Return the bps rate for Avada Kill caster.
  function getKillBps() external view returns (uint);

  /// @dev Return whether the given address is a goblin.
  function isGoblin(address goblin) external view returns (bool);

  /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
  function acceptDebt(address goblin) external view returns (bool);

  /// @dev Return the work factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function workFactor(address goblin, uint debt) external view returns (uint);

  /// @dev Return the kill factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function killFactor(address goblin, uint debt) external view returns (uint);
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import './PriceOracle.sol';

contract SimplePriceOracle is Ownable, PriceOracle {
  event PriceUpdate(address indexed token0, address indexed token1, uint price);

  struct PriceData {
    uint192 price;
    uint64 lastUpdate;
  }

  /// @notice Public price data mapping storage.
  mapping(address => mapping(address => PriceData)) public store;

  /// @dev Set the prices of the token token pairs. Must be called by the owner.
  function setPrices(
    address[] calldata token0s,
    address[] calldata token1s,
    uint[] calldata prices
  ) external onlyOwner {
    uint len = token0s.length;
    require(token1s.length == len, 'bad token1s length');
    require(prices.length == len, 'bad prices length');
    for (uint idx = 0; idx < len; idx++) {
      address token0 = token0s[idx];
      address token1 = token1s[idx];
      uint price = prices[idx];
      store[token0][token1] = PriceData({price: uint192(price), lastUpdate: uint64(now)});
      emit PriceUpdate(token0, token1, price);
    }
  }

  /// @dev Return the wad price of token0/token1, multiplied by 1e18
  /// NOTE: (if you have 1 token0 how much you can sell it for token1)
  function getPrice(address token0, address token1)
    external
    view
    returns (uint price, uint lastUpdate)
  {
    PriceData memory data = store[token0][token1];
    price = uint(data.price);
    lastUpdate = uint(data.lastUpdate);
    require(price != 0 && lastUpdate != 0, 'bad price data');
    return (price, lastUpdate);
  }
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/IUniswapV2Router02.sol';
import './Strategy.sol';
import './SafeToken.sol';
import './Goblin.sol';
import './interfaces/IMasterChef.sol';

contract PancakeswapGoblin is Ownable, ReentrancyGuard, Goblin {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;

  /// @notice Events
  event Reinvest(address indexed caller, uint reward, uint bounty);
  event AddShare(uint indexed id, uint share);
  event RemoveShare(uint indexed id, uint share);
  event Liquidate(uint indexed id, uint wad);

  /// @notice Immutable variables
  IMasterChef public masterChef;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  IUniswapV2Pair public lpToken;
  address public wbnb;
  address public fToken;
  address public cake;
  address public operator;
  uint public pid;

  /// @notice Mutable state variables
  mapping(uint => uint) public shares;
  mapping(address => bool) public okStrats;
  uint public totalShare;
  Strategy public addStrat; // use StrategyAllBNBOnly strat (for reinvesting)
  Strategy public liqStrat;
  uint public reinvestBountyBps;

  constructor(
    address _operator,
    IMasterChef _masterChef,
    IUniswapV2Router02 _router,
    uint _pid,
    Strategy _addStrat,
    Strategy _liqStrat,
    uint _reinvestBountyBps
  ) public {
    operator = _operator;
    wbnb = _router.WETH();
    masterChef = _masterChef;
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    // Get lpToken and fToken from MasterChef pool
    pid = _pid;
    (IERC20 _lpToken, , , ) = masterChef.poolInfo(_pid);
    lpToken = IUniswapV2Pair(address(_lpToken));
    address token0 = lpToken.token0();
    address token1 = lpToken.token1();
    fToken = token0 == wbnb ? token1 : token0;
    cake = address(masterChef.cake());
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    lpToken.approve(address(_masterChef), uint(-1)); // 100% trust in the staking pool
    lpToken.approve(address(router), uint(-1)); // 100% trust in the router
    fToken.safeApprove(address(router), uint(-1)); // 100% trust in the router
    cake.safeApprove(address(router), uint(-1)); // 100% trust in the router
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Require that the caller must be the operator (the bank).
  modifier onlyOperator() {
    require(msg.sender == operator, 'not operator');
    _;
  }

  /// @dev Return the entitied LP token balance for the given shares.
  /// @param share The number of shares to be converted to LP balance.
  function shareToBalance(uint share) public view returns (uint) {
    if (totalShare == 0) return share; // When there's no share, 1 share = 1 balance.
    (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
    return share.mul(totalBalance).div(totalShare);
  }

  /// @dev Return the number of shares to receive if staking the given LP tokens.
  /// @param balance the number of LP tokens to be converted to shares.
  function balanceToShare(uint balance) public view returns (uint) {
    if (totalShare == 0) return balance; // When there's no share, 1 share = 1 balance.
    (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
    return balance.mul(totalShare).div(totalBalance);
  }

  /// @dev Re-invest whatever this worker has earned back to staked LP tokens.
  function reinvest() public onlyEOA nonReentrant {
    // 1. Withdraw all the rewards.
    masterChef.withdraw(pid, 0);
    uint reward = cake.balanceOf(address(this));
    if (reward == 0) return;
    // 2. Send the reward bounty to the caller.
    uint bounty = reward.mul(reinvestBountyBps) / 10000;
    cake.safeTransfer(msg.sender, bounty);
    // 3. Convert all the remaining rewards to BNB.
    address[] memory path = new address[](2);
    path[0] = address(cake);
    path[1] = address(wbnb);
    router.swapExactTokensForETH(reward.sub(bounty), 0, path, address(this), now);
    // 4. Use add BNB strategy to convert all BNB to LP tokens.
    addStrat.execute.value(address(this).balance)(address(0), 0, abi.encode(fToken, 0));
    // 5. Mint more LP tokens and stake them for more rewards.
    masterChef.deposit(pid, lpToken.balanceOf(address(this)));
    emit Reinvest(msg.sender, reward, bounty);
  }

  /// @dev Work on the given position. Must be called by the operator.
  /// @param id The position ID to work on.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The amount of user debt to help the strategy make decisions.
  /// @param data The encoded data, consisting of strategy address and calldata.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external payable onlyOperator nonReentrant {
    // 1. Convert this position back to LP tokens.
    _removeShare(id);
    // 2. Perform the worker strategy; sending LP tokens + BNB; expecting LP tokens + BNB.
    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], 'unapproved work strategy');
    lpToken.transfer(strat, lpToken.balanceOf(address(this)));
    Strategy(strat).execute.value(msg.value)(user, debt, ext);
    // 3. Add LP tokens back to the farming pool.
    _addShare(id);
    // 4. Return any remaining BNB back to the operator.
    SafeToken.safeTransferBNB(msg.sender, address(this).balance);
  }

  /// @dev Return maximum output given the input amount and the status of Uniswap reserves.
  /// @param aIn The amount of asset to market sell.
  /// @param rIn the amount of asset in reserve for input.
  /// @param rOut The amount of asset in reserve for output.
  function getMktSellAmount(
    uint aIn,
    uint rIn,
    uint rOut
  ) public pure returns (uint) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, 'bad reserve values');
    uint aInWithFee = aIn.mul(998);
    uint numerator = aInWithFee.mul(rOut);
    uint denominator = rIn.mul(1000).add(aInWithFee);
    return numerator / denominator;
  }

  /// @dev Return the amount of BNB to receive if we are to liquidate the given position.
  /// @param id The position ID to perform health check.
  function health(uint id) external view returns (uint) {
    // 1. Get the position's LP balance and LP total supply.
    uint lpBalance = shareToBalance(shares[id]);
    uint lpSupply = lpToken.totalSupply(); // Ignore pending mintFee as it is insignificant
    // 2. Get the pool's total supply of WBNB and farming token.
    (uint r0, uint r1, ) = lpToken.getReserves();
    (uint totalWBNB, uint totalfToken) = lpToken.token0() == wbnb ? (r0, r1) : (r1, r0);
    // 3. Convert the position's LP tokens to the underlying assets.
    uint userWBNB = lpBalance.mul(totalWBNB).div(lpSupply);
    uint userfToken = lpBalance.mul(totalfToken).div(lpSupply);
    // 4. Convert all farming tokens to BNB and return total BNB.
    return
      getMktSellAmount(userfToken, totalfToken.sub(userfToken), totalWBNB.sub(userWBNB)).add(
        userWBNB
      );
  }

  /// @dev Liquidate the given position by converting it to BNB and return back to caller.
  /// @param id The position ID to perform liquidation
  function liquidate(uint id) external onlyOperator nonReentrant {
    // 1. Convert the position back to LP tokens and use liquidate strategy.
    _removeShare(id);
    lpToken.transfer(address(liqStrat), lpToken.balanceOf(address(this)));
    liqStrat.execute(address(0), 0, abi.encode(fToken, 0));
    // 2. Return all available BNB back to the operator.
    uint wad = address(this).balance;
    SafeToken.safeTransferBNB(msg.sender, wad);
    emit Liquidate(id, wad);
  }

  /// @dev Internal function to stake all outstanding LP tokens to the given position ID.
  function _addShare(uint id) internal {
    uint balance = lpToken.balanceOf(address(this));
    if (balance > 0) {
      uint share = balanceToShare(balance);
      masterChef.deposit(pid, balance);
      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);
      emit AddShare(id, share);
    }
  }

  /// @dev Internal function to remove shares of the ID and convert to outstanding LP tokens.
  function _removeShare(uint id) internal {
    uint share = shares[id];
    if (share > 0) {
      uint balance = shareToBalance(share);
      masterChef.withdraw(pid, balance);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      emit RemoveShare(id, share);
    }
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  /// @dev Set the reward bounty for calling reinvest operations.
  /// @param _reinvestBountyBps The bounty value to update.
  function setReinvestBountyBps(uint _reinvestBountyBps) external onlyOwner {
    reinvestBountyBps = _reinvestBountyBps;
  }

  /// @dev Set the given strategies' approval status.
  /// @param strats The strategy addresses.
  /// @param isOk Whether to approve or unapprove the given strategies.
  function setStrategyOk(address[] calldata strats, bool isOk) external onlyOwner {
    uint len = strats.length;
    for (uint idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
    }
  }

  /// @dev Update critical strategy smart contracts. EMERGENCY ONLY. Bad strategies can steal funds.
  /// @param _addStrat The new add strategy contract.
  /// @param _liqStrat The new liquidate strategy contract.
  function setCriticalStrategies(Strategy _addStrat, Strategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;
  }

  function() external payable {}
}

pragma solidity 0.5.16;

interface Goblin {
  /// @dev Work on a (potentially new) position. Optionally send BNB back to Bank.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external payable;

  /// @dev Re-invest whatever the goblin is working on.
  function reinvest() external;

  /// @dev Return the amount of BNB wei to get back if we are to liquidate the position.
  function health(uint id) external view returns (uint);

  /// @dev Liquidate the given position to BNB. Send all BNB back to Bank.
  function liquidate(uint id) external;
}

pragma solidity 0.5.16;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';

// Making the original MasterChef as an interface leads to compilation fail.
// Use Contract instead of Interface here
contract IMasterChef {
  // Info of each user.
  struct UserInfo {
    uint amount; // How many LP tokens the user has provided.
    uint rewardDebt; // Reward debt. See explanation below.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint allocPoint; // How many allocation points assigned to this pool. CAKEs to distribute per block.
    uint lastRewardBlock; // Last block number that CAKEs distribution occurs.
    uint accCakePerShare; // Accumulated CAKEs per share, times 1e12. See below.
  }

  address public cake;

  // Info of each user that stakes LP tokens.
  mapping(uint => PoolInfo) public poolInfo;
  mapping(uint => mapping(address => UserInfo)) public userInfo;

  // Deposit LP tokens to MasterChef for CAKE allocation.
  function deposit(uint _pid, uint _amount) external {}

  // Withdraw LP tokens from MasterChef.
  function withdraw(uint _pid, uint _amount) external {}
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import './BankConfig.sol';
import './GoblinConfig.sol';

interface InterestModel {
  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint);
}

contract TripleSlopeModel {
  using SafeMath for uint;

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external pure returns (uint) {
    uint total = debt.add(floating);
    uint utilization = total == 0 ? 0 : debt.mul(100e18).div(total);
    if (utilization < 80e18) {
      // Less than 80% utilization - 0%-20% APY
      return utilization.mul(20e16).div(80e18) / 365 days;
    } else if (utilization < 90e18) {
      // Between 80% and 90% - 20% APY
      return uint(20e16) / 365 days;
    } else if (utilization < 100e18) {
      // Between 90% and 100% - 20%-200% APY
      return (20e16 + utilization.sub(90e18).mul(180e16).div(10e18)) / 365 days;
    } else {
      // Not possible, but just in case - 200% APY
      return uint(200e16) / 365 days;
    }
  }
}

contract ConfigurableInterestBankConfig is BankConfig, Ownable {
  /// The minimum BNB debt size per position.
  uint public minDebtSize;
  /// The portion of interests allocated to the reserve pool.
  uint public getReservePoolBps;
  /// The reward for successfully killing a position.
  uint public getKillBps;
  /// Mapping for goblin address to its configuration.
  mapping(address => GoblinConfig) public goblins;
  /// Interest rate model
  InterestModel public interestModel;

  constructor(
    uint _minDebtSize,
    uint _reservePoolBps,
    uint _killBps,
    InterestModel _interestModel
  ) public {
    setParams(_minDebtSize, _reservePoolBps, _killBps, _interestModel);
  }

  /// @dev Set all the basic parameters. Must only be called by the owner.
  /// @param _minDebtSize The new minimum debt size value.
  /// @param _reservePoolBps The new interests allocated to the reserve pool value.
  /// @param _killBps The new reward for killing a position value.
  /// @param _interestModel The new interest rate model contract.
  function setParams(
    uint _minDebtSize,
    uint _reservePoolBps,
    uint _killBps,
    InterestModel _interestModel
  ) public onlyOwner {
    minDebtSize = _minDebtSize;
    getReservePoolBps = _reservePoolBps;
    getKillBps = _killBps;
    interestModel = _interestModel;
  }

  /// @dev Set the configuration for the given goblins. Must only be called by the owner.
  function setGoblins(address[] calldata addrs, GoblinConfig[] calldata configs)
    external
    onlyOwner
  {
    require(addrs.length == configs.length, 'bad length');
    for (uint idx = 0; idx < addrs.length; idx++) {
      goblins[addrs[idx]] = configs[idx];
    }
  }

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(uint debt, uint floating) external view returns (uint) {
    return interestModel.getInterestRate(debt, floating);
  }

  /// @dev Return whether the given address is a goblin.
  function isGoblin(address goblin) external view returns (bool) {
    return address(goblins[goblin]) != address(0);
  }

  /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
  function acceptDebt(address goblin) external view returns (bool) {
    return goblins[goblin].acceptDebt(goblin);
  }

  /// @dev Return the work factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function workFactor(address goblin, uint debt) external view returns (uint) {
    return goblins[goblin].workFactor(goblin, debt);
  }

  /// @dev Return the kill factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function killFactor(address goblin, uint debt) external view returns (uint) {
    return goblins[goblin].killFactor(goblin, debt);
  }
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/IUniswapV2Router02.sol';
import './SafeToken.sol';
import './Strategy.sol';

contract StrategyAllBNBOnly is Ownable, ReentrancyGuard, Strategy {
  using SafeToken for address;
  using SafeMath for uint;

  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  address public wbnb;

  mapping(address => bool) public whitelistedTokens;

  /// @dev Create a new add BNB only strategy instance.
  /// @param _router The Uniswap router smart contract.
  constructor(IUniswapV2Router02 _router) public {
    factory = IUniswapV2Factory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
  }

  /// @dev Set whitelist tokens
  /// @param tokens Token list to set statuses
  /// @param statuses Status list to set tokens to
  function setWhitelistTokens(address[] calldata tokens, bool[] calldata statuses)
    external
    onlyOwner
  {
    require(tokens.length == statuses.length, 'tokens & statuses length mismatched');
    for (uint idx = 0; idx < tokens.length; idx++) {
      whitelistedTokens[tokens[idx]] = statuses[idx];
    }
  }

  /// @dev Execute worker strategy. Take BNB. Return LP tokens.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address, /* user */
    uint, /* debt */
    bytes calldata data
  ) external payable nonReentrant {
    // 1. Find out what farming token we are dealing with and min additional LP tokens.
    (address fToken, uint minLPAmount) = abi.decode(data, (address, uint));
    require(whitelistedTokens[fToken], 'token not whitelisted');
    IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, wbnb));
    // 2. Compute the optimal amount of BNB to be converted to farming tokens.
    uint balance = address(this).balance;
    (uint r0, uint r1, ) = lpToken.getReserves();
    uint rIn = lpToken.token0() == wbnb ? r0 : r1;
    uint aIn =
      Math.sqrt(rIn.mul(balance.mul(3992000).add(rIn.mul(3992004)))).sub(rIn.mul(1998)) / 1996;
    // 3. Convert that portion of BNB to farming tokens.
    address[] memory path = new address[](2);
    path[0] = wbnb;
    path[1] = fToken;
    router.swapExactETHForTokens.value(aIn)(0, path, address(this), now);
    // 4. Mint more LP tokens and return all LP tokens to the sender.
    fToken.safeApprove(address(router), 0);
    fToken.safeApprove(address(router), uint(-1));
    (, , uint moreLPAmount) =
      router.addLiquidityETH.value(address(this).balance)(
        fToken,
        fToken.myBalance(),
        0,
        0,
        address(this),
        now
      );
    require(moreLPAmount >= minLPAmount, 'insufficient LP tokens received');
    lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  function() external payable {}
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'Synthetixio/[email protected]/contracts/interfaces/IStakingRewards.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/IUniswapV2Router02.sol';
import './Strategy.sol';
import './SafeToken.sol';
import './Goblin.sol';

contract UniswapGoblin is Ownable, ReentrancyGuard, Goblin {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;

  /// @notice Events
  event Reinvest(address indexed caller, uint reward, uint bounty);
  event AddShare(uint indexed id, uint share);
  event RemoveShare(uint indexed id, uint share);
  event Liquidate(uint indexed id, uint wad);

  /// @notice Immutable variables
  IStakingRewards public staking;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  IUniswapV2Pair public lpToken;
  address public wbnb;
  address public fToken;
  address public uni;
  address public operator;

  /// @notice Mutable state variables
  mapping(uint => uint) public shares;
  mapping(address => bool) public okStrats;
  uint public totalShare;
  Strategy public addStrat; // use StrategyAllBNBOnly strat (for reinvesting)
  Strategy public liqStrat;
  uint public reinvestBountyBps;

  constructor(
    address _operator,
    IStakingRewards _staking,
    IUniswapV2Router02 _router,
    address _fToken,
    address _uni,
    Strategy _addStrat,
    Strategy _liqStrat,
    uint _reinvestBountyBps
  ) public {
    operator = _operator;
    wbnb = _router.WETH();
    staking = _staking;
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    lpToken = IUniswapV2Pair(factory.getPair(wbnb, _fToken));
    fToken = _fToken;
    uni = _uni;
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    lpToken.approve(address(_staking), uint(-1)); // 100% trust in the staking pool
    lpToken.approve(address(router), uint(-1)); // 100% trust in the router
    _fToken.safeApprove(address(router), uint(-1)); // 100% trust in the router
    _uni.safeApprove(address(router), uint(-1)); // 100% trust in the router
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Require that the caller must be the operator (the bank).
  modifier onlyOperator() {
    require(msg.sender == operator, 'not operator');
    _;
  }

  /// @dev Return the entitied LP token balance for the given shares.
  /// @param share The number of shares to be converted to LP balance.
  function shareToBalance(uint share) public view returns (uint) {
    if (totalShare == 0) return share; // When there's no share, 1 share = 1 balance.
    uint totalBalance = staking.balanceOf(address(this));
    return share.mul(totalBalance).div(totalShare);
  }

  /// @dev Return the number of shares to receive if staking the given LP tokens.
  /// @param balance the number of LP tokens to be converted to shares.
  function balanceToShare(uint balance) public view returns (uint) {
    if (totalShare == 0) return balance; // When there's no share, 1 share = 1 balance.
    uint totalBalance = staking.balanceOf(address(this));
    return balance.mul(totalShare).div(totalBalance);
  }

  /// @dev Re-invest whatever this worker has earned back to staked LP tokens.
  function reinvest() public onlyEOA nonReentrant {
    // 1. Withdraw all the rewards.
    staking.getReward();
    uint reward = uni.myBalance();
    if (reward == 0) return;
    // 2. Send the reward bounty to the caller.
    uint bounty = reward.mul(reinvestBountyBps) / 10000;
    uni.safeTransfer(msg.sender, bounty);
    // 3. Convert all the remaining rewards to BNB.
    address[] memory path = new address[](2);
    path[0] = address(uni);
    path[1] = address(wbnb);
    router.swapExactTokensForETH(reward.sub(bounty), 0, path, address(this), now);
    // 4. Use add BNB strategy to convert all BNB to LP tokens.
    addStrat.execute.value(address(this).balance)(address(0), 0, abi.encode(fToken, 0));
    // 5. Mint more LP tokens and stake them for more rewards.
    staking.stake(lpToken.balanceOf(address(this)));
    emit Reinvest(msg.sender, reward, bounty);
  }

  /// @dev Work on the given position. Must be called by the operator.
  /// @param id The position ID to work on.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The amount of user debt to help the strategy make decisions.
  /// @param data The encoded data, consisting of strategy address and calldata.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external payable onlyOperator nonReentrant {
    // 1. Convert this position back to LP tokens.
    _removeShare(id);
    // 2. Perform the worker strategy; sending LP tokens + BNB; expecting LP tokens + BNB.
    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], 'unapproved work strategy');
    lpToken.transfer(strat, lpToken.balanceOf(address(this)));
    Strategy(strat).execute.value(msg.value)(user, debt, ext);
    // 3. Add LP tokens back to the farming pool.
    _addShare(id);
    // 4. Return any remaining BNB back to the operator.
    SafeToken.safeTransferBNB(msg.sender, address(this).balance);
  }

  /// @dev Return maximum output given the input amount and the status of Uniswap reserves.
  /// @param aIn The amount of asset to market sell.
  /// @param rIn the amount of asset in reserve for input.
  /// @param rOut The amount of asset in reserve for output.
  function getMktSellAmount(
    uint aIn,
    uint rIn,
    uint rOut
  ) public pure returns (uint) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, 'bad reserve values');
    uint aInWithFee = aIn.mul(998);
    uint numerator = aInWithFee.mul(rOut);
    uint denominator = rIn.mul(1000).add(aInWithFee);
    return numerator / denominator;
  }

  /// @dev Return the amount of BNB to receive if we are to liquidate the given position.
  /// @param id The position ID to perform health check.
  function health(uint id) external view returns (uint) {
    // 1. Get the position's LP balance and LP total supply.
    uint lpBalance = shareToBalance(shares[id]);
    uint lpSupply = lpToken.totalSupply(); // Ignore pending mintFee as it is insignificant
    // 2. Get the pool's total supply of WBNB and farming token.
    (uint r0, uint r1, ) = lpToken.getReserves();
    (uint totalWBNB, uint totalfToken) = lpToken.token0() == wbnb ? (r0, r1) : (r1, r0);
    // 3. Convert the position's LP tokens to the underlying assets.
    uint userWBNB = lpBalance.mul(totalWBNB).div(lpSupply);
    uint userfToken = lpBalance.mul(totalfToken).div(lpSupply);
    // 4. Convert all farming tokens to BNB and return total BNB.
    return
      getMktSellAmount(userfToken, totalfToken.sub(userfToken), totalWBNB.sub(userWBNB)).add(
        userWBNB
      );
  }

  /// @dev Liquidate the given position by converting it to BNB and return back to caller.
  /// @param id The position ID to perform liquidation
  function liquidate(uint id) external onlyOperator nonReentrant {
    // 1. Convert the position back to LP tokens and use liquidate strategy.
    _removeShare(id);
    lpToken.transfer(address(liqStrat), lpToken.balanceOf(address(this)));
    liqStrat.execute(address(0), 0, abi.encode(fToken, 0));
    // 2. Return all available BNB back to the operator.
    uint wad = address(this).balance;
    SafeToken.safeTransferBNB(msg.sender, wad);
    emit Liquidate(id, wad);
  }

  /// @dev Internal function to stake all outstanding LP tokens to the given position ID.
  function _addShare(uint id) internal {
    uint balance = lpToken.balanceOf(address(this));
    if (balance > 0) {
      uint share = balanceToShare(balance);
      staking.stake(balance);
      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);
      emit AddShare(id, share);
    }
  }

  /// @dev Internal function to remove shares of the ID and convert to outstanding LP tokens.
  function _removeShare(uint id) internal {
    uint share = shares[id];
    if (share > 0) {
      uint balance = shareToBalance(share);
      staking.withdraw(balance);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      emit RemoveShare(id, share);
    }
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  /// @dev Set the reward bounty for calling reinvest operations.
  /// @param _reinvestBountyBps The bounty value to update.
  function setReinvestBountyBps(uint _reinvestBountyBps) external onlyOwner {
    reinvestBountyBps = _reinvestBountyBps;
  }

  /// @dev Set the given strategies' approval status.
  /// @param strats The strategy addresses.
  /// @param isOk Whether to approve or unapprove the given strategies.
  function setStrategyOk(address[] calldata strats, bool isOk) external onlyOwner {
    uint len = strats.length;
    for (uint idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
    }
  }

  /// @dev Update critical strategy smart contracts. EMERGENCY ONLY. Bad strategies can steal funds.
  /// @param _addStrat The new add strategy contract.
  /// @param _liqStrat The new liquidate strategy contract.
  function setCriticalStrategies(Strategy _addStrat, Strategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;
  }

  function() external payable {}
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/IUniswapV2Router02.sol';
import './SafeToken.sol';
import './Strategy.sol';

contract StrategyAddTwoSidesOptimal is Ownable, ReentrancyGuard, Strategy {
  using SafeToken for address;
  using SafeMath for uint;

  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  address public wbnb;
  address public goblin;
  address public fToken_;

  /// @dev Create a new add two-side optimal strategy instance.
  /// @param _router The Uniswap router smart contract.
  constructor(
    IUniswapV2Router02 _router,
    address _goblin,
    address _fToken
  ) public {
    factory = IUniswapV2Factory(_router.factory());
    router = _router;
    wbnb = _router.WETH();
    goblin = _goblin;
    fToken_ = _fToken;
  }

  /// @dev Throws if called by any account other than the goblin.
  modifier onlyGoblin() {
    require(isGoblin(), 'caller is not the goblin');
    _;
  }

  /// @dev Returns true if the caller is the current goblin.
  function isGoblin() public view returns (bool) {
    return msg.sender == goblin;
  }

  /// @dev Compute optimal deposit amount
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amonut of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  /// @dev Compute optimal deposit amount helper
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amonut of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');

    uint a = 998;
    uint b = uint(1998).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);

    uint d = a.mul(c).mul(4);
    uint e = Math.sqrt(b.mul(b).add(d));

    uint numerator = e.sub(b);
    uint denominator = a.mul(2);

    return numerator.div(denominator);
  }

  /// @dev Execute worker strategy. Take fToken + BNB. Return LP tokens.
  /// @param user User address
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address user,
    uint,
    /* debt */
    bytes calldata data
  ) external payable onlyGoblin nonReentrant {
    // 1. Find out what farming token we are dealing with.
    (address fToken, uint fAmount, uint minLPAmount) = abi.decode(data, (address, uint, uint));
    require(fToken == fToken_, 'token mismatched');
    IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, wbnb));
    // 2. Compute the optimal amount of BNB and fToken to be converted.
    if (fAmount > 0) {
      fToken.safeTransferFrom(user, address(this), fAmount);
    }
    uint ethBalance = address(this).balance;
    uint swapAmt;
    bool isReversed;
    {
      (uint r0, uint r1, ) = lpToken.getReserves();
      (uint ethReserve, uint fReserve) = lpToken.token0() == wbnb ? (r0, r1) : (r1, r0);
      (swapAmt, isReversed) = optimalDeposit(ethBalance, fToken.myBalance(), ethReserve, fReserve);
    }
    // 3. Convert between BNB and farming tokens
    fToken.safeApprove(address(router), 0);
    fToken.safeApprove(address(router), uint(-1));
    address[] memory path = new address[](2);
    (path[0], path[1]) = isReversed ? (fToken, wbnb) : (wbnb, fToken);
    if (isReversed) {
      router.swapExactTokensForETH(swapAmt, 0, path, address(this), now); // farming tokens to BNB
    } else {
      router.swapExactETHForTokens.value(swapAmt)(0, path, address(this), now); // BNB to farming tokens
    }
    // 4. Mint more LP tokens and return all LP tokens to the sender.
    (, , uint moreLPAmount) =
      router.addLiquidityETH.value(address(this).balance)(
        fToken,
        fToken.myBalance(),
        0,
        0,
        address(this),
        now
      );
    require(moreLPAmount >= minLPAmount, 'insufficient LP tokens received');
    lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  function() external payable {}
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/math/Math.sol';
import './ReentrancyGuardUpgradeSafe.sol';
import './Initializable.sol';
import './Governable.sol';
import './BankConfig.sol';
import './Goblin.sol';
import './SafeToken.sol';

contract Bank is Initializable, ERC20, ReentrancyGuardUpgradeSafe, Governable {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;

  /// @notice Events
  event AddDebt(uint indexed id, uint debtShare);
  event RemoveDebt(uint indexed id, uint debtShare);
  event Work(uint indexed id, uint loan);
  event Kill(uint indexed id, address indexed killer, uint prize, uint left);

  string public name;
  string public symbol;
  uint8 public decimals;

  struct Position {
    address goblin;
    address owner;
    uint debtShare;
  }

  BankConfig public config;
  mapping(uint => Position) public positions;
  uint public nextPositionID;

  uint public glbDebtShare;
  uint public glbDebtVal;
  uint public lastAccrueTime;
  uint public reservePool;

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Add more debt to the global debt pool.
  modifier accrue(uint msgValue) {
    if (now > lastAccrueTime) {
      uint interest = pendingInterest(msgValue);
      uint toReserve = interest.mul(config.getReservePoolBps()).div(10000);
      reservePool = reservePool.add(toReserve);
      glbDebtVal = glbDebtVal.add(interest);
      lastAccrueTime = now;
    }
    _;
  }

  function initialize(BankConfig _config) external initializer {
    __Governable__init();
    __ReentrancyGuardUpgradeSafe__init();
    config = _config;
    lastAccrueTime = now;
    nextPositionID = 1;
    name = 'Interest Bearing BNB';
    symbol = 'ibBNB';
    decimals = 18;
  }

  /// @dev Return the pending interest that will be accrued in the next call.
  /// @param msgValue Balance value to subtract off address(this).balance when called from payable functions.
  function pendingInterest(uint msgValue) public view returns (uint) {
    if (now > lastAccrueTime) {
      uint timePast = now.sub(lastAccrueTime);
      uint balance = address(this).balance.sub(msgValue);
      uint ratePerSec = config.getInterestRate(glbDebtVal, balance);
      return ratePerSec.mul(glbDebtVal).mul(timePast).div(1e18);
    } else {
      return 0;
    }
  }

  /// @dev Return the BNB debt value given the debt share. Be careful of unaccrued interests.
  /// @param debtShare The debt share to be converted.
  function debtShareToVal(uint debtShare) public view returns (uint) {
    if (glbDebtShare == 0) return debtShare; // When there's no share, 1 share = 1 val.
    return debtShare.mul(glbDebtVal).div(glbDebtShare);
  }

  /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
  /// @param debtVal The debt value to be converted.
  function debtValToShare(uint debtVal) public view returns (uint) {
    if (glbDebtShare == 0) return debtVal; // When there's no share, 1 share = 1 val.
    return debtVal.mul(glbDebtShare).div(glbDebtVal).add(1);
  }

  /// @dev Return BNB value and debt of the given position. Be careful of unaccrued interests.
  /// @param id The position ID to query.
  function positionInfo(uint id) public view returns (uint, uint) {
    Position storage pos = positions[id];
    return (Goblin(pos.goblin).health(id), debtShareToVal(pos.debtShare));
  }

  /// @dev Return the total BNB entitled to the token holders. Be careful of unaccrued interests.
  function totalBNB() public view returns (uint) {
    return address(this).balance.add(glbDebtVal).sub(reservePool);
  }

  /// @dev Add more BNB to the bank. Hope to get some good returns.
  function deposit() external payable accrue(msg.value) nonReentrant {
    uint total = totalBNB().sub(msg.value);
    uint share = total == 0 ? msg.value : msg.value.mul(totalSupply()).div(total);
    _mint(msg.sender, share);
    require(totalSupply() >= 1e17, 'deposit: total supply too low');
  }

  /// @dev Withdraw BNB from the bank by burning the share tokens.
  function withdraw(uint share) external accrue(0) nonReentrant {
    uint amount = share.mul(totalBNB()).div(totalSupply());
    _burn(msg.sender, share);
    SafeToken.safeTransferBNB(msg.sender, amount);
    uint supply = totalSupply();
    require(supply == 0 || supply >= 1e17, 'withdraw: total supply too low');
  }

  /// @dev Create a new farming position to unlock your yield farming potential.
  /// @param id The ID of the position to unlock the earning. Use ZERO for new position.
  /// @param goblin The address of the authorized goblin to work for this position.
  /// @param loan The amount of BNB to borrow from the pool.
  /// @param maxReturn The max amount of BNB to return to the pool.
  /// @param data The calldata to pass along to the goblin for more working context.
  function work(
    uint id,
    address goblin,
    uint loan,
    uint maxReturn,
    bytes calldata data
  ) external payable onlyEOA accrue(msg.value) nonReentrant {
    // 1. Sanity check the input position, or add a new position of ID is 0.
    if (id == 0) {
      id = nextPositionID++;
      positions[id].goblin = goblin;
      positions[id].owner = msg.sender;
    } else {
      require(id < nextPositionID, 'bad position id');
      require(positions[id].goblin == goblin, 'bad position goblin');
      require(positions[id].owner == msg.sender, 'not position owner');
    }
    emit Work(id, loan);
    // 2. Make sure the goblin can accept more debt and remove the existing debt.
    require(config.isGoblin(goblin), 'not a goblin');
    require(loan == 0 || config.acceptDebt(goblin), 'goblin not accept more debt');
    uint debt = _removeDebt(id).add(loan);
    // 3. Perform the actual work, using a new scope to avoid stack-too-deep errors.
    uint back;
    {
      uint sendBNB = msg.value.add(loan);
      require(sendBNB <= address(this).balance, 'insufficient BNB in the bank');
      uint beforeBNB = address(this).balance.sub(sendBNB);
      Goblin(goblin).work.value(sendBNB)(id, msg.sender, debt, data);
      back = address(this).balance.sub(beforeBNB);
    }
    // 4. Check and update position debt.
    uint lessDebt = Math.min(debt, Math.min(back, maxReturn));
    debt = debt.sub(lessDebt);
    if (debt > 0) {
      require(debt >= config.minDebtSize(), 'too small debt size');
      uint health = Goblin(goblin).health(id);
      uint workFactor = config.workFactor(goblin, debt);
      require(health.mul(workFactor) >= debt.mul(10000), 'bad work factor');
      _addDebt(id, debt);
    }
    // 5. Return excess BNB back.
    if (back > lessDebt) SafeToken.safeTransferBNB(msg.sender, back - lessDebt);

    // 6. Check total debt share/value not too small
    require(glbDebtShare >= 1e12, 'remaining global debt share too small');
    require(glbDebtVal >= 1e12, 'remaining global debt value too small');
  }

  /// @dev Kill the given to the position. Liquidate it immediately if killFactor condition is met.
  /// @param id The position ID to be killed.
  function kill(uint id) external onlyEOA accrue(0) nonReentrant {
    // 1. Verify that the position is eligible for liquidation.
    Position storage pos = positions[id];
    require(pos.debtShare > 0, 'no debt');
    uint debt = _removeDebt(id);
    uint health = Goblin(pos.goblin).health(id);
    uint killFactor = config.killFactor(pos.goblin, debt);
    require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");
    // 2. Perform liquidation and compute the amount of BNB received.
    uint beforeBNB = address(this).balance;
    Goblin(pos.goblin).liquidate(id);
    uint back = address(this).balance.sub(beforeBNB);
    uint prize = back.mul(config.getKillBps()).div(10000);
    uint rest = back.sub(prize);
    // 3. Clear position debt and return funds to liquidator and position owner.
    if (prize > 0) SafeToken.safeTransferBNB(msg.sender, prize);
    uint left = rest > debt ? rest - debt : 0;
    if (left > 0) SafeToken.safeTransferBNB(pos.owner, left);
    emit Kill(id, msg.sender, prize, left);
  }

  /// @dev Internal function to add the given debt value to the given position.
  function _addDebt(uint id, uint debtVal) internal {
    Position storage pos = positions[id];
    uint debtShare = debtValToShare(debtVal);
    pos.debtShare = pos.debtShare.add(debtShare);
    glbDebtShare = glbDebtShare.add(debtShare);
    glbDebtVal = glbDebtVal.add(debtVal);
    emit AddDebt(id, debtShare);
  }

  /// @dev Internal function to clear the debt of the given position. Return the debt value.
  function _removeDebt(uint id) internal returns (uint) {
    Position storage pos = positions[id];
    uint debtShare = pos.debtShare;
    if (debtShare > 0) {
      uint debtVal = debtShareToVal(debtShare);
      pos.debtShare = 0;
      glbDebtShare = glbDebtShare.sub(debtShare);
      glbDebtVal = glbDebtVal.sub(debtVal);
      emit RemoveDebt(id, debtShare);
      return debtVal;
    } else {
      return 0;
    }
  }

  /// @dev Update bank configuration to a new address. Must only be called by owner.
  /// @param _config The new configurator address.
  function updateConfig(BankConfig _config) external onlyGov {
    config = _config;
  }

  /// @dev Withdraw BNB reserve for underwater positions to the given address.
  /// @param to The address to transfer BNB to.
  /// @param value The number of BNB tokens to withdraw. Must not exceed `reservePool`.
  function withdrawReserve(address to, uint value) external onlyGov nonReentrant {
    reservePool = reservePool.sub(value);
    SafeToken.safeTransferBNB(to, value);
  }

  /// @dev Reduce BNB reserve, effectively giving them to the depositors.
  /// @param value The number of BNB reserve to reduce.
  function reduceReserve(uint value) external onlyGov {
    reservePool = reservePool.sub(value);
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyGov nonReentrant {
    token.safeTransfer(to, value);
  }

  /// @dev Fallback function to accept BNB. Goblins will send BNB back the pool.
  function() external payable {}
}

pragma solidity 0.5.16;

interface IBank {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through `transferFrom`. This is
   * zero by default.
   *
   * This value changes when `approve` or `transferFrom` are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * > Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an `Approval` event.
   */
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /// @dev Return the total BNB entitled to the token holders. Be careful of unaccrued interests.
  function totalBNB() external view returns (uint);

  /// @dev Add more BNB to the bank. Hope to get some good returns.
  function deposit() external payable;

  /// @dev Withdraw BNB from the bank by burning the share tokens.
  function withdraw(uint share) external;
}

pragma solidity =0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/UniswapV2Library.sol';
import './uniswap/IUniswapV2Router02.sol';
import './interfaces/IBank.sol';

// helper methods for interacting with ERC20 tokens and sending BNB that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: APPROVE_FAILED'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: TRANSFER_FAILED'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper: TRANSFER_FROM_FAILED'
    );
  }

  function safeTransferBNB(address to, uint value) internal {
    (bool success, ) = to.call.value(value)(new bytes(0));
    require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
  }
}

contract IbBNBRouter is Ownable {
  using SafeMath for uint;

  address public router;
  address public ibBNB;
  address public alpha;
  address public lpToken;

  constructor(
    address _router,
    address _ibBNB,
    address _alpha
  ) public {
    router = _router;
    ibBNB = _ibBNB;
    alpha = _alpha;
    address factory = IUniswapV2Router02(router).factory();
    lpToken = UniswapV2Library.pairFor(factory, ibBNB, alpha);
    IUniswapV2Pair(lpToken).approve(router, uint(-1)); // 100% trust in the router
    IBank(ibBNB).approve(router, uint(-1)); // 100% trust in the router
    IERC20(alpha).approve(router, uint(-1)); // 100% trust in the router
  }

  function() external payable {
    assert(msg.sender == ibBNB); // only accept BNB via fallback from the Bank contract
  }

  // **** BNB-ibBNB FUNCTIONS ****
  // Get number of ibBNB needed to withdraw to get exact amountBNB from the Bank
  function ibBNBForExactBNB(uint amountBNB) public view returns (uint) {
    uint totalBNB = IBank(ibBNB).totalBNB();
    return
      totalBNB == 0
        ? amountBNB
        : amountBNB.mul(IBank(ibBNB).totalSupply()).add(totalBNB).sub(1).div(totalBNB);
  }

  // Add BNB and Alpha from ibBNB-Alpha Pool.
  // 1. Receive BNB and Alpha from caller.
  // 2. Wrap BNB to ibBNB.
  // 3. Provide liquidity to the pool.
  function addLiquidityBNB(
    uint amountAlphaDesired,
    uint amountAlphaMin,
    uint amountBNBMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountAlpha,
      uint amountBNB,
      uint liquidity
    )
  {
    TransferHelper.safeTransferFrom(alpha, msg.sender, address(this), amountAlphaDesired);
    IBank(ibBNB).deposit.value(msg.value)();
    uint amountIbBNBDesired = IBank(ibBNB).balanceOf(address(this));
    uint amountIbBNB;
    (amountAlpha, amountIbBNB, liquidity) = IUniswapV2Router02(router).addLiquidity(
      alpha,
      ibBNB,
      amountAlphaDesired,
      amountIbBNBDesired,
      amountAlphaMin,
      0,
      to,
      deadline
    );
    if (amountAlphaDesired > amountAlpha) {
      TransferHelper.safeTransfer(alpha, msg.sender, amountAlphaDesired.sub(amountAlpha));
    }
    IBank(ibBNB).withdraw(amountIbBNBDesired.sub(amountIbBNB));
    amountBNB = msg.value.sub(address(this).balance);
    if (amountBNB > 0) {
      TransferHelper.safeTransferBNB(msg.sender, address(this).balance);
    }
    require(amountBNB >= amountBNBMin, 'IbBNBRouter: require more BNB than amountBNBmin');
  }

  /// @dev Compute optimal deposit amount
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  /// (forked from ./StrategyAddTwoSidesOptimal.sol)
  function optimalDeposit(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint swapAmt, bool isReversed) {
    if (amtA.mul(resB) >= amtB.mul(resA)) {
      swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
      isReversed = false;
    } else {
      swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
      isReversed = true;
    }
  }

  /// @dev Compute optimal deposit amount helper
  /// @param amtA amount of token A desired to deposit
  /// @param amtB amount of token B desired to deposit
  /// @param resA amount of token A in reserve
  /// @param resB amount of token B in reserve
  /// (forked from ./StrategyAddTwoSidesOptimal.sol)
  function _optimalDepositA(
    uint amtA,
    uint amtB,
    uint resA,
    uint resB
  ) internal pure returns (uint) {
    require(amtA.mul(resB) >= amtB.mul(resA), 'Reversed');

    uint a = 998;
    uint b = uint(1998).mul(resA);
    uint _c = (amtA.mul(resB)).sub(amtB.mul(resA));
    uint c = _c.mul(1000).div(amtB.add(resB)).mul(resA);

    uint d = a.mul(c).mul(4);
    uint e = Math.sqrt(b.mul(b).add(d));

    uint numerator = e.sub(b);
    uint denominator = a.mul(2);

    return numerator.div(denominator);
  }

  // Add ibBNB and Alpha to ibBNB-Alpha Pool.
  // All ibBNB and Alpha supplied are optimally swap and add too ibBNB-Alpha Pool.
  function addLiquidityTwoSidesOptimal(
    uint amountIbBNBDesired,
    uint amountAlphaDesired,
    uint amountLPMin,
    address to,
    uint deadline
  ) external returns (uint liquidity) {
    if (amountIbBNBDesired > 0) {
      TransferHelper.safeTransferFrom(ibBNB, msg.sender, address(this), amountIbBNBDesired);
    }
    if (amountAlphaDesired > 0) {
      TransferHelper.safeTransferFrom(alpha, msg.sender, address(this), amountAlphaDesired);
    }
    uint swapAmt;
    bool isReversed;
    {
      (uint r0, uint r1, ) = IUniswapV2Pair(lpToken).getReserves();
      (uint ibBNBReserve, uint alphaReserve) =
        IUniswapV2Pair(lpToken).token0() == ibBNB ? (r0, r1) : (r1, r0);
      (swapAmt, isReversed) = optimalDeposit(
        amountIbBNBDesired,
        amountAlphaDesired,
        ibBNBReserve,
        alphaReserve
      );
    }
    address[] memory path = new address[](2);
    (path[0], path[1]) = isReversed ? (alpha, ibBNB) : (ibBNB, alpha);
    IUniswapV2Router02(router).swapExactTokensForTokens(swapAmt, 0, path, address(this), now);
    (, , liquidity) = IUniswapV2Router02(router).addLiquidity(
      alpha,
      ibBNB,
      IERC20(alpha).balanceOf(address(this)),
      IBank(ibBNB).balanceOf(address(this)),
      0,
      0,
      to,
      deadline
    );
    uint dustAlpha = IERC20(alpha).balanceOf(address(this));
    uint dustIbBNB = IBank(ibBNB).balanceOf(address(this));
    if (dustAlpha > 0) {
      TransferHelper.safeTransfer(alpha, msg.sender, dustAlpha);
    }
    if (dustIbBNB > 0) {
      TransferHelper.safeTransfer(ibBNB, msg.sender, dustIbBNB);
    }
    require(liquidity >= amountLPMin, 'IbBNBRouter: receive less lpToken than amountLPMin');
  }

  // Add BNB and Alpha to ibBNB-Alpha Pool.
  // All BNB and Alpha supplied are optimally swap and add too ibBNB-Alpha Pool.
  function addLiquidityTwoSidesOptimalBNB(
    uint amountAlphaDesired,
    uint amountLPMin,
    address to,
    uint deadline
  ) external payable returns (uint liquidity) {
    if (amountAlphaDesired > 0) {
      TransferHelper.safeTransferFrom(alpha, msg.sender, address(this), amountAlphaDesired);
    }
    IBank(ibBNB).deposit.value(msg.value)();
    uint amountIbBNBDesired = IBank(ibBNB).balanceOf(address(this));
    uint swapAmt;
    bool isReversed;
    {
      (uint r0, uint r1, ) = IUniswapV2Pair(lpToken).getReserves();
      (uint ibBNBReserve, uint alphaReserve) =
        IUniswapV2Pair(lpToken).token0() == ibBNB ? (r0, r1) : (r1, r0);
      (swapAmt, isReversed) = optimalDeposit(
        amountIbBNBDesired,
        amountAlphaDesired,
        ibBNBReserve,
        alphaReserve
      );
    }
    address[] memory path = new address[](2);
    (path[0], path[1]) = isReversed ? (alpha, ibBNB) : (ibBNB, alpha);
    IUniswapV2Router02(router).swapExactTokensForTokens(swapAmt, 0, path, address(this), now);
    (, , liquidity) = IUniswapV2Router02(router).addLiquidity(
      alpha,
      ibBNB,
      IERC20(alpha).balanceOf(address(this)),
      IBank(ibBNB).balanceOf(address(this)),
      0,
      0,
      to,
      deadline
    );
    uint dustAlpha = IERC20(alpha).balanceOf(address(this));
    uint dustIbBNB = IBank(ibBNB).balanceOf(address(this));
    if (dustAlpha > 0) {
      TransferHelper.safeTransfer(alpha, msg.sender, dustAlpha);
    }
    if (dustIbBNB > 0) {
      TransferHelper.safeTransfer(ibBNB, msg.sender, dustIbBNB);
    }
    require(liquidity >= amountLPMin, 'IbBNBRouter: receive less lpToken than amountLPMin');
  }

  // Remove BNB and Alpha from ibBNB-Alpha Pool.
  // 1. Remove ibBNB and Alpha from the pool.
  // 2. Unwrap ibBNB to BNB.
  // 3. Return BNB and Alpha to caller.
  function removeLiquidityBNB(
    uint liquidity,
    uint amountAlphaMin,
    uint amountBNBMin,
    address to,
    uint deadline
  ) public returns (uint amountAlpha, uint amountBNB) {
    TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), liquidity);
    uint amountIbBNB;
    (amountAlpha, amountIbBNB) = IUniswapV2Router02(router).removeLiquidity(
      alpha,
      ibBNB,
      liquidity,
      amountAlphaMin,
      0,
      address(this),
      deadline
    );
    TransferHelper.safeTransfer(alpha, to, amountAlpha);
    IBank(ibBNB).withdraw(amountIbBNB);
    amountBNB = address(this).balance;
    if (amountBNB > 0) {
      TransferHelper.safeTransferBNB(to, address(this).balance);
    }
    require(amountBNB >= amountBNBMin, 'IbBNBRouter: receive less BNB than amountBNBmin');
  }

  // Remove liquidity from ibBNB-Alpha Pool and convert all ibBNB to Alpha
  // 1. Remove ibBNB and Alpha from the pool.
  // 2. Swap ibBNB for Alpha.
  // 3. Return Alpha to caller.
  function removeLiquidityAllAlpha(
    uint liquidity,
    uint amountAlphaMin,
    address to,
    uint deadline
  ) public returns (uint amountAlpha) {
    TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), liquidity);
    (uint removeAmountAlpha, uint removeAmountIbBNB) =
      IUniswapV2Router02(router).removeLiquidity(
        alpha,
        ibBNB,
        liquidity,
        0,
        0,
        address(this),
        deadline
      );
    address[] memory path = new address[](2);
    path[0] = ibBNB;
    path[1] = alpha;
    uint[] memory amounts =
      IUniswapV2Router02(router).swapExactTokensForTokens(removeAmountIbBNB, 0, path, to, deadline);
    TransferHelper.safeTransfer(alpha, to, removeAmountAlpha);
    amountAlpha = removeAmountAlpha.add(amounts[1]);
    require(amountAlpha >= amountAlphaMin, 'IbBNBRouter: receive less Alpha than amountAlphaMin');
  }

  // Swap exact amount of BNB for Token
  // 1. Receive BNB from caller
  // 2. Wrap BNB to ibBNB.
  // 3. Swap ibBNB for Token
  function swapExactBNBForAlpha(
    uint amountAlphaOutMin,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts) {
    IBank(ibBNB).deposit.value(msg.value)();
    address[] memory path = new address[](2);
    path[0] = ibBNB;
    path[1] = alpha;
    uint[] memory swapAmounts =
      IUniswapV2Router02(router).swapExactTokensForTokens(
        IBank(ibBNB).balanceOf(address(this)),
        amountAlphaOutMin,
        path,
        to,
        deadline
      );
    amounts = new uint[](2);
    amounts[0] = msg.value;
    amounts[1] = swapAmounts[1];
  }

  // Swap Token for exact amount of BNB
  // 1. Receive Token from caller
  // 2. Swap Token for ibBNB.
  // 3. Unwrap ibBNB to BNB.
  function swapAlphaForExactBNB(
    uint amountBNBOut,
    uint amountAlphaInMax,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts) {
    TransferHelper.safeTransferFrom(alpha, msg.sender, address(this), amountAlphaInMax);
    address[] memory path = new address[](2);
    path[0] = alpha;
    path[1] = ibBNB;
    IBank(ibBNB).withdraw(0);
    uint[] memory swapAmounts =
      IUniswapV2Router02(router).swapTokensForExactTokens(
        ibBNBForExactBNB(amountBNBOut),
        amountAlphaInMax,
        path,
        address(this),
        deadline
      );
    IBank(ibBNB).withdraw(swapAmounts[1]);
    amounts = new uint[](2);
    amounts[0] = swapAmounts[0];
    amounts[1] = address(this).balance;
    TransferHelper.safeTransferBNB(to, address(this).balance);
    if (amountAlphaInMax > amounts[0]) {
      TransferHelper.safeTransfer(alpha, msg.sender, amountAlphaInMax.sub(amounts[0]));
    }
  }

  // Swap exact amount of Token for BNB
  // 1. Receive Token from caller
  // 2. Swap Token for ibBNB.
  // 3. Unwrap ibBNB to BNB.
  function swapExactAlphaForBNB(
    uint amountAlphaIn,
    uint amountBNBOutMin,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts) {
    TransferHelper.safeTransferFrom(alpha, msg.sender, address(this), amountAlphaIn);
    address[] memory path = new address[](2);
    path[0] = alpha;
    path[1] = ibBNB;
    uint[] memory swapAmounts =
      IUniswapV2Router02(router).swapExactTokensForTokens(
        amountAlphaIn,
        0,
        path,
        address(this),
        deadline
      );
    IBank(ibBNB).withdraw(swapAmounts[1]);
    amounts = new uint[](2);
    amounts[0] = swapAmounts[0];
    amounts[1] = address(this).balance;
    TransferHelper.safeTransferBNB(to, amounts[1]);
    require(amounts[1] >= amountBNBOutMin, 'IbBNBRouter: receive less BNB than amountBNBmin');
  }

  // Swap BNB for exact amount of Token
  // 1. Receive BNB from caller
  // 2. Wrap BNB to ibBNB.
  // 3. Swap ibBNB for Token
  function swapBNBForExactAlpha(
    uint amountAlphaOut,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts) {
    IBank(ibBNB).deposit.value(msg.value)();
    uint amountIbBNBInMax = IBank(ibBNB).balanceOf(address(this));
    address[] memory path = new address[](2);
    path[0] = ibBNB;
    path[1] = alpha;
    uint[] memory swapAmounts =
      IUniswapV2Router02(router).swapTokensForExactTokens(
        amountAlphaOut,
        amountIbBNBInMax,
        path,
        to,
        deadline
      );
    amounts = new uint[](2);
    amounts[0] = msg.value;
    amounts[1] = swapAmounts[1];
    // Transfer left over BNB back
    if (amountIbBNBInMax > swapAmounts[0]) {
      IBank(ibBNB).withdraw(amountIbBNBInMax.sub(swapAmounts[0]));
      amounts[0] = msg.value.sub(address(this).balance);
      TransferHelper.safeTransferBNB(msg.sender, address(this).balance);
    }
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner {
    TransferHelper.safeTransfer(token, to, value);
  }

  /// @dev Recover BNB that were accidentally sent to this smart contract.
  /// @param to The address to send the BNB to.
  /// @param value The number of BNB to transfer to `to`.
  function recoverBNB(address to, uint value) external onlyOwner {
    TransferHelper.safeTransferBNB(to, value);
  }
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Factory.sol';
import 'Uniswap/[email protected]/contracts/interfaces/IUniswapV2Pair.sol';
import 'Uniswap/[email protected]/contracts/libraries/Math.sol';
import './uniswap/IUniswapV2Router02.sol';
import './Strategy.sol';
import './SafeToken.sol';
import './Goblin.sol';
import './interfaces/IMasterChef.sol';

// PancakeswapPool1Goblin is specific for CAKE-BNB pool in Pancakeswap.
// In this case, fToken = CAKE and pid = 1.
contract PancakeswapPool1Goblin is Ownable, ReentrancyGuard, Goblin {
  /// @notice Libraries
  using SafeToken for address;
  using SafeMath for uint;

  /// @notice Events
  event Reinvest(address indexed caller, uint reward, uint bounty);
  event AddShare(uint indexed id, uint share);
  event RemoveShare(uint indexed id, uint share);
  event Liquidate(uint indexed id, uint wad);

  /// @notice Immutable variables
  IMasterChef public masterChef;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  IUniswapV2Pair public lpToken;
  address public wbnb;
  address public cake;
  address public operator;
  uint public constant pid = 1;

  /// @notice Mutable state variables
  mapping(uint => uint) public shares;
  mapping(address => bool) public okStrats;
  uint public totalShare;
  Strategy public addStrat; // use StrategyTwoSidesOptimal strat (for reinvesting)
  Strategy public liqStrat;
  uint public reinvestBountyBps;

  constructor(
    address _operator,
    IMasterChef _masterChef,
    IUniswapV2Router02 _router,
    Strategy _addStrat,
    Strategy _liqStrat,
    uint _reinvestBountyBps
  ) public {
    operator = _operator;
    wbnb = _router.WETH();
    masterChef = _masterChef;
    router = _router;
    factory = IUniswapV2Factory(_router.factory());
    (IERC20 _lpToken, , , ) = masterChef.poolInfo(pid);
    lpToken = IUniswapV2Pair(address(_lpToken));
    cake = address(masterChef.cake());
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    lpToken.approve(address(_masterChef), uint(-1)); // 100% trust in the staking pool
    lpToken.approve(address(router), uint(-1)); // 100% trust in the router
    cake.safeApprove(address(router), uint(-1)); // 100% trust in the router
  }

  /// @dev Require that the caller must be an EOA account to avoid flash loans.
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'not eoa');
    _;
  }

  /// @dev Require that the caller must be the operator (the bank).
  modifier onlyOperator() {
    require(msg.sender == operator, 'not operator');
    _;
  }

  /// @dev Return the entitied LP token balance for the given shares.
  /// @param share The number of shares to be converted to LP balance.
  function shareToBalance(uint share) public view returns (uint) {
    if (totalShare == 0) return share; // When there's no share, 1 share = 1 balance.
    (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
    return share.mul(totalBalance).div(totalShare);
  }

  /// @dev Return the number of shares to receive if staking the given LP tokens.
  /// @param balance the number of LP tokens to be converted to shares.
  function balanceToShare(uint balance) public view returns (uint) {
    if (totalShare == 0) return balance; // When there's no share, 1 share = 1 balance.
    (uint totalBalance, ) = masterChef.userInfo(pid, address(this));
    return balance.mul(totalShare).div(totalBalance);
  }

  /// @dev Re-invest whatever this worker has earned back to staked LP tokens.
  function reinvest() public onlyEOA nonReentrant {
    // 1. Withdraw all the rewards.
    masterChef.withdraw(pid, 0);
    uint reward = cake.balanceOf(address(this));
    if (reward == 0) return;
    // 2. Send the reward bounty to the caller.
    uint bounty = reward.mul(reinvestBountyBps) / 10000;
    cake.safeTransfer(msg.sender, bounty);
    // 3. Use add Two-side optimal strategy to convert cake to BNB and add
    // liquidity to get LP tokens.
    cake.safeTransfer(address(addStrat), reward.sub(bounty));
    addStrat.execute(address(this), 0, abi.encode(cake, 0, 0));
    // 4. Mint more LP tokens and stake them for more rewards.
    masterChef.deposit(pid, lpToken.balanceOf(address(this)));
    emit Reinvest(msg.sender, reward, bounty);
  }

  /// @dev Work on the given position. Must be called by the operator.
  /// @param id The position ID to work on.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The amount of user debt to help the strategy make decisions.
  /// @param data The encoded data, consisting of strategy address and calldata.
  function work(
    uint id,
    address user,
    uint debt,
    bytes calldata data
  ) external payable onlyOperator nonReentrant {
    // 1. Convert this position back to LP tokens.
    _removeShare(id);
    // 2. Perform the worker strategy; sending LP tokens + BNB; expecting LP tokens + BNB.
    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], 'unapproved work strategy');
    lpToken.transfer(strat, lpToken.balanceOf(address(this)));
    Strategy(strat).execute.value(msg.value)(user, debt, ext);
    // 3. Add LP tokens back to the farming pool.
    _addShare(id);
    // 4. Return any remaining BNB back to the operator.
    SafeToken.safeTransferBNB(msg.sender, address(this).balance);
  }

  /// @dev Return maximum output given the input amount and the status of Uniswap reserves.
  /// @param aIn The amount of asset to market sell.
  /// @param rIn the amount of asset in reserve for input.
  /// @param rOut The amount of asset in reserve for output.
  function getMktSellAmount(
    uint aIn,
    uint rIn,
    uint rOut
  ) public pure returns (uint) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, 'bad reserve values');
    uint aInWithFee = aIn.mul(998);
    uint numerator = aInWithFee.mul(rOut);
    uint denominator = rIn.mul(1000).add(aInWithFee);
    return numerator / denominator;
  }

  /// @dev Return the amount of BNB to receive if we are to liquidate the given position.
  /// @param id The position ID to perform health check.
  function health(uint id) external view returns (uint) {
    // 1. Get the position's LP balance and LP total supply.
    uint lpBalance = shareToBalance(shares[id]);
    uint lpSupply = lpToken.totalSupply(); // Ignore pending mintFee as it is insignificant
    // 2. Get the pool's total supply of WBNB and farming token.
    (uint r0, uint r1, ) = lpToken.getReserves();
    (uint totalWBNB, uint totalPancake) = lpToken.token0() == wbnb ? (r0, r1) : (r1, r0);
    // 3. Convert the position's LP tokens to the underlying assets.
    uint userWBNB = lpBalance.mul(totalWBNB).div(lpSupply);
    uint userPancake = lpBalance.mul(totalPancake).div(lpSupply);
    // 4. Convert all farming tokens to BNB and return total BNB.
    return
      getMktSellAmount(userPancake, totalPancake.sub(userPancake), totalWBNB.sub(userWBNB)).add(
        userWBNB
      );
  }

  /// @dev Liquidate the given position by converting it to BNB and return back to caller.
  /// @param id The position ID to perform liquidation
  function liquidate(uint id) external onlyOperator nonReentrant {
    // 1. Convert the position back to LP tokens and use liquidate strategy.
    _removeShare(id);
    lpToken.transfer(address(liqStrat), lpToken.balanceOf(address(this)));
    liqStrat.execute(address(0), 0, abi.encode(cake, 0));
    // 2. Return all available BNB back to the operator.
    uint wad = address(this).balance;
    SafeToken.safeTransferBNB(msg.sender, wad);
    emit Liquidate(id, wad);
  }

  /// @dev Internal function to stake all outstanding LP tokens to the given position ID.
  function _addShare(uint id) internal {
    uint balance = lpToken.balanceOf(address(this));

    if (balance > 0) {
      uint share = balanceToShare(balance);
      masterChef.deposit(pid, balance);
      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);
      emit AddShare(id, share);
    }
  }

  /// @dev Internal function to remove shares of the ID and convert to outstanding LP tokens.
  function _removeShare(uint id) internal {
    uint share = shares[id];
    if (share > 0) {
      uint balance = shareToBalance(share);
      masterChef.withdraw(pid, balance);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      emit RemoveShare(id, share);
    }
  }

  /// @dev Recover ERC20 tokens that were accidentally sent to this smart contract.
  /// @param token The token contract. Can be anything. This contract should not hold ERC20 tokens.
  /// @param to The address to send the tokens to.
  /// @param value The number of tokens to transfer to `to`.
  function recover(
    address token,
    address to,
    uint value
  ) external onlyOwner nonReentrant {
    token.safeTransfer(to, value);
  }

  /// @dev Set the reward bounty for calling reinvest operations.
  /// @param _reinvestBountyBps The bounty value to update.
  function setReinvestBountyBps(uint _reinvestBountyBps) external onlyOwner {
    reinvestBountyBps = _reinvestBountyBps;
  }

  /// @dev Set the given strategies' approval status.
  /// @param strats The strategy addresses.
  /// @param isOk Whether to approve or unapprove the given strategies.
  function setStrategyOk(address[] calldata strats, bool isOk) external onlyOwner {
    uint len = strats.length;
    for (uint idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
    }
  }

  /// @dev Update critical strategy smart contracts. EMERGENCY ONLY. Bad strategies can steal funds.
  /// @param _addStrat The new add strategy contract.
  /// @param _liqStrat The new liquidate strategy contract.
  function setCriticalStrategies(Strategy _addStrat, Strategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;
  }

  function() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(msg.sender == owner, "This function is restricted to the contract's owner");
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

pragma solidity 0.5.16;
import 'OpenZeppelin/[email protected]/contracts/ownership/Ownable.sol';
import './BankConfig.sol';

contract SimpleBankConfig is BankConfig, Ownable {
  /// @notice Configuration for each goblin.
  struct GoblinConfig {
    bool isGoblin;
    bool acceptDebt;
    uint workFactor;
    uint killFactor;
  }

  /// The minimum BNB debt size per position.
  uint public minDebtSize;
  /// The interest rate per second, multiplied by 1e18.
  uint public interestRate;
  /// The portion of interests allocated to the reserve pool.
  uint public getReservePoolBps;
  /// The reward for successfully killing a position.
  uint public getKillBps;
  /// Mapping for goblin address to its configuration.
  mapping(address => GoblinConfig) public goblins;

  constructor(
    uint _minDebtSize,
    uint _interestRate,
    uint _reservePoolBps,
    uint _killBps
  ) public {
    setParams(_minDebtSize, _interestRate, _reservePoolBps, _killBps);
  }

  /// @dev Set all the basic parameters. Must only be called by the owner.
  /// @param _minDebtSize The new minimum debt size value.
  /// @param _interestRate The new interest rate per second value.
  /// @param _reservePoolBps The new interests allocated to the reserve pool value.
  /// @param _killBps The new reward for killing a position value.
  function setParams(
    uint _minDebtSize,
    uint _interestRate,
    uint _reservePoolBps,
    uint _killBps
  ) public onlyOwner {
    minDebtSize = _minDebtSize;
    interestRate = _interestRate;
    getReservePoolBps = _reservePoolBps;
    getKillBps = _killBps;
  }

  /// @dev Set the configuration for the given goblin. Must only be called by the owner.
  /// @param goblin The goblin address to set configuration.
  /// @param _isGoblin Whether the given address is a valid goblin.
  /// @param _acceptDebt Whether the goblin is accepting new debts.
  /// @param _workFactor The work factor value for this goblin.
  /// @param _killFactor The kill factor value for this goblin.
  function setGoblin(
    address goblin,
    bool _isGoblin,
    bool _acceptDebt,
    uint _workFactor,
    uint _killFactor
  ) public onlyOwner {
    goblins[goblin] = GoblinConfig({
      isGoblin: _isGoblin,
      acceptDebt: _acceptDebt,
      workFactor: _workFactor,
      killFactor: _killFactor
    });
  }

  /// @dev Return the interest rate per second, using 1e18 as denom.
  function getInterestRate(
    uint, /* debt */
    uint /* floating */
  ) external view returns (uint) {
    return interestRate;
  }

  /// @dev Return whether the given address is a goblin.
  function isGoblin(address goblin) external view returns (bool) {
    return goblins[goblin].isGoblin;
  }

  /// @dev Return whether the given goblin accepts more debt. Revert on non-goblin.
  function acceptDebt(address goblin) external view returns (bool) {
    require(goblins[goblin].isGoblin, '!goblin');
    return goblins[goblin].acceptDebt;
  }

  /// @dev Return the work factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function workFactor(
    address goblin,
    uint /* debt */
  ) external view returns (uint) {
    require(goblins[goblin].isGoblin, '!goblin');
    return goblins[goblin].workFactor;
  }

  /// @dev Return the kill factor for the goblin + BNB debt, using 1e4 as denom. Revert on non-goblin.
  function killFactor(
    address goblin,
    uint /* debt */
  ) external view returns (uint) {
    require(goblins[goblin].isGoblin, '!goblin');
    return goblins[goblin].killFactor;
  }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.4.24;


interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}