// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BnbSwap is Ownable {
    using SafeMath for uint256;

    address public oneInch = 0x11111112542D85B3EF69AE05771c2dCCff4fAa26;
    mapping(address => uint256) public swapped;

    fallback() external payable {
        uint amount = msg.value;

        require(amount > 0, 'Value must be greater then 0');

        // Calculate fees
        uint fee = amount.mul(50).div(10000);

        // Send value minus fees to 1inch
        (bool success,) = oneInch.call{value : amount.sub(fee)}(msg.data);

        require(success, '1 Inch swap failed');

        swapped[msg.sender] += amount;
    }

    receive() external payable {}

    function claimFees() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakePair.sol";

interface IToken {
    function balanceOf(address _user) external view returns (uint256);
}

interface IFarm {
    function stakedWantTokens(
        uint256 _pid,
        address _user
    ) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (address want);
}

interface IVault {
    function userInfo(
        address _user
    ) external view returns (
        uint256 shares,
        uint256 lastDepositedTime,
        uint256 pacocaAtLastUserAction,
        uint256 lastUserActionTime
    );

    function getPricePerFullShare() external view returns (uint256);
}

contract VotingPower is Ownable {
    using SafeMath for uint256;

    IToken public PACOCA = IToken(0x55671114d774ee99D653D6C12460c780a67f1D18);
    IFarm public PACOCA_FARM = IFarm(0x55410D946DFab292196462ca9BE9f3E4E4F337Dd);
    IVault public PACOCA_VAULT = IVault(0x16205528A8F7510f4421009a7654835b541bb1b9);

    mapping(uint256 => bool) public pacocaPairs;

    event PacocaPairAdded(uint256 _pid);
    event PacocaPairRemoved(uint256 _pid);

    constructor(address _owner) public {
        addPacocaPairPid(2);
        addPacocaPairPid(15);
        addPacocaPairPid(16);
        addPacocaPairPid(21);
        addPacocaPairPid(22);

        transferOwnership(_owner);
    }

    function votingPower(address _user) external view returns (uint256) {
        uint256 tokenBalance = PACOCA.balanceOf(_user);
        uint256 farmBalance = PACOCA_FARM.stakedWantTokens(0, _user);
        uint256 pairBalance = _getPacocaPairBalances(_user);
        uint256 vaultBalance = _getPacocaVaultBalance(_user);

        return tokenBalance.add(farmBalance).add(pairBalance).add(vaultBalance);
    }

    function _getPacocaVaultBalance(address _user) private view returns (uint256){
        uint256 pricePerShare = PACOCA_VAULT.getPricePerFullShare();
        (uint256 shares, , ,) = PACOCA_VAULT.userInfo(_user);

        return shares.mul(pricePerShare).div(1e18);
    }

    function _getPacocaPairBalances(address _user) private view returns (uint256 balance) {
        uint256 length = PACOCA_FARM.poolLength();

        for (uint256 pid = 0; pid < length; ++pid) {
            if (!pacocaPairs[pid]) {
                continue;
            }

            uint256 pairBalance = PACOCA_FARM.stakedWantTokens(pid, _user);

            if (pairBalance > 0) {
                balance = balance.add(
                    _getPacocaPairBalance(PACOCA_FARM.poolInfo(pid), pairBalance)
                );
            }
        }

        return balance;
    }

    function _getPacocaPairBalance(address _pair, uint256 _balance) private view returns (uint256) {
        IPancakePair pair = IPancakePair(_pair);

        bool pacocaToken0 = pair.token0() == address(PACOCA);
        bool pacocaToken1 = pair.token1() == address(PACOCA);

        if (!pacocaToken0 && !pacocaToken1) {
            return 0;
        }

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

        return pacocaToken0
        ? reserve0.mul(_balance).div(pair.totalSupply())
        : reserve1.mul(_balance).div(pair.totalSupply());
    }

    function addPacocaPairPid(uint256 _pid) public onlyOwner {
        pacocaPairs[_pid] = true;

        emit PacocaPairAdded(_pid);
    }

    function removePacocaPairPid(uint256 _pid) public onlyOwner {
        pacocaPairs[_pid] = false;

        emit PacocaPairRemoved(_pid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
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

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IPancakePair.sol";

interface IPancakeFactory {
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function getPair(address, address) external view returns (address);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint8);
}

contract Dashboard {
    using SafeMath for uint;

    struct Balance {
        address token;
        uint balance;
    }

    struct LpInfo {
        address token0;
        address token1;
        uint8 decimals0;
        uint8 decimals1;
        uint reserve0;
        uint reserve1;
        uint totalSupply;
    }

    address immutable internal USD;
    address immutable internal NATIVE_USD_LP;

    constructor(address _usd, address _nativeUsdLp) public {
        USD = _usd;
        NATIVE_USD_LP = _nativeUsdLp;
    }

    function getPriceFromLp(
        address _lpToken,
        address _pricedTokenAddress,
        uint _pricedTokenPrice
    ) internal view returns (
        uint
    ) {
        IPancakePair pair = IPancakePair(_lpToken);

        (uint reserve0, uint reserve1,) = pair.getReserves();

        address token0 = pair.token0();
        address token1 = pair.token1();

        bool token0IsPriced = token0 == _pricedTokenAddress;

        uint8 decimals0 = IERC20(token0).decimals();
        uint8 decimals1 = IERC20(token1).decimals();

        uint reservePriced = token0IsPriced ? reserve0 : reserve1;
        uint reserveUnpriced = token0IsPriced ? reserve1 : reserve0;

        return reservePriced.mul(1e18).div(
            10 ** uint(token0IsPriced ? decimals0 : decimals1)
        ).mul(_pricedTokenPrice).div(
            reserveUnpriced.mul(1e18).div(
                10 ** uint(token0IsPriced ? decimals1 : decimals0)
            )
        );
    }

    function getLpInfo(address _lpToken) public view returns (LpInfo memory) {
        IPancakePair pair = IPancakePair(_lpToken);

        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();

        return LpInfo(
            token0,
            token1,
            IERC20(token0).decimals(),
            IERC20(token1).decimals(),
            reserve0,
            reserve1,
            pair.totalSupply()
        );
    }

    function nativePrice() public view returns (uint) {
        return getPriceFromLp(NATIVE_USD_LP, USD, 1e18);
    }

    function getLpAddresses(
        uint _maxLength,
        address _factory,
        address _connector,
        address[] memory _tokens
    ) external view returns (
        address[] memory tokens
    ) {
        IPancakeFactory factory = IPancakeFactory(_factory);
        address[] memory tempLpTokens = new address[](_maxLength);
        uint resultsLength = 0;

        for (uint tokenIndex = 0; tokenIndex < _tokens.length; ++tokenIndex) {
            address lp = factory.getPair(_tokens[tokenIndex], _connector);

            if (lp != address(0)) {
                tempLpTokens[resultsLength] = lp;
                resultsLength = resultsLength + 1;
            }

            if (resultsLength == _maxLength) {
                return tempLpTokens;
            }
        }

        tokens = new address[](resultsLength);

        for (uint resultsIndex = 0; resultsIndex < resultsLength; ++resultsIndex) {
            tokens[resultsIndex] = tempLpTokens[resultsIndex];
        }

        return tokens;
    }

//    function tokenBalancesOf(
//        address _user,
//        address[] memory _tokens
//    ) external view returns (
//        Balance[] memory balances
//    ) {
//        Balance[] memory tempBalances = new Balance[](_tokens.length);
//        uint resultsLength = 0;
//
//        for (uint tokenIndex = 0; tokenIndex < _tokens.length; ++tokenIndex) {
//            uint balance = IERC20(_tokens[tokenIndex]).balanceOf(_user);
//
//            if (balance > 0) {
//                tempBalances[resultsLength] = Balance(
//                    _tokens[tokenIndex],
//                    balance
//                );
//                resultsLength = resultsLength + 1;
//            }
//        }
//
//        balances = new Balance[](resultsLength);
//
//        for (uint resultsIndex = 0; resultsIndex < resultsLength; ++resultsIndex) {
//            balances[resultsIndex] = tempBalances[resultsIndex];
//        }
//    }
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity ^0.5.16;
pragma solidity 0.6.12;

// XXX: import "./SafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
// XXX: Added SafeERC20 import
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract Timelock {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 6 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    // XXX: Added PACOCA
    IERC20 public PACOCA = IERC20(0x55671114d774ee99D653D6C12460c780a67f1D18);

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public admin_initialized;

    mapping (bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_) public {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
        admin_initialized = false;
    }

    // XXX: function() external payable { }
    receive() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, string(returnData));

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    // XXX: added claimPacoca()
    function claimPacoca() external {
        PACOCA.safeTransfer(admin, PACOCA.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPacocaVault.sol";

contract SweetVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        // How many assets the user has provided.
        uint256 stake;
        // How many staked $PACOCA user had at his last action
        uint256 autoPacocaShares;
        // Pacoca shares not entitled to the user
        uint256 rewardDebt;
        // Timestamp of last user deposit
        uint256 lastDepositedTime;
    }

    // Addresses
    address constant public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 constant public PACOCA = IERC20(0x55671114d774ee99D653D6C12460c780a67f1D18);
    IPacocaVault immutable public AUTO_PACOCA;
    IERC20 immutable public STAKED_TOKEN;

    // Runtime data
    mapping(address => UserInfo) public userInfo; // Info of users
    uint256 public accSharesPerStakedToken; // Accumulated AUTO_PACOCA shares per staked token, times 1e18.

    // Farm info
    IFarm immutable public STAKED_TOKEN_FARM;
    IERC20 immutable public FARM_REWARD_TOKEN;
    uint256 immutable public FARM_PID;
    bool immutable public IS_CAKE_STAKING;
    bool immutable public IS_WAULT;
    bool immutable public IS_BISWAP;

    // Settings
    IPancakeRouter02 immutable public router;
    address[] public pathToPacoca; // Path from staked token to PACOCA
    address[] public pathToWbnb; // Path from staked token to WBNB

    address public treasury;
    address public keeper;
    uint256 public keeperFee = 50; // 0.5%
    uint256 public constant keeperFeeUL = 100; // 1%

    address public platform;
    uint256 public platformFee;
    uint256 public constant platformFeeUL = 500; // 5%

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public buyBackRate;
    uint256 public constant buyBackRateUL = 300; // 5%

    uint256 public earlyWithdrawFee = 100; // 1%
    uint256 public constant earlyWithdrawFeeUL = 300; // 3%
    uint256 public constant withdrawFeePeriod = 3 days;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EarlyWithdraw(address indexed user, uint256 amount, uint256 fee);
    event ClaimRewards(address indexed user, uint256 shares, uint256 amount);

    // Setting updates
    event SetPathToPacoca(address[] oldPath, address[] newPath);
    event SetPathToWbnb(address[] oldPath, address[] newPath);
    event SetBuyBackRate(uint256 oldBuyBackRate, uint256 newBuyBackRate);
    event SetTreasury(address oldTreasury, address newTreasury);
    event SetKeeper(address oldKeeper, address newKeeper);
    event SetKeeperFee(uint256 oldKeeperFee, uint256 newKeeperFee);
    event SetPlatform(address oldPlatform, address newPlatform);
    event SetPlatformFee(uint256 oldPlatformFee, uint256 newPlatformFee);
    event SetEarlyWithdrawFee(uint256 oldEarlyWithdrawFee, uint256 newEarlyWithdrawFee);

    constructor(
        address _autoPacoca,
        address _stakedToken,
        address _stakedTokenFarm,
        address _farmRewardToken,
        uint256 _farmPid,
        bool _isCakeStaking,
        address _router,
        address[] memory _pathToPacoca,
        address[] memory _pathToWbnb,
        address _owner,
        address _treasury,
        address _keeper,
        address _platform,
        uint256 _buyBackRate,
        uint256 _platformFee
    ) public {
        require(
            _pathToPacoca[0] == address(_farmRewardToken) && _pathToPacoca[_pathToPacoca.length - 1] == address(PACOCA),
            "SweetVault: Incorrect path to PACOCA"
        );

        require(
            _pathToWbnb[0] == address(_farmRewardToken) && _pathToWbnb[_pathToWbnb.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        require(_buyBackRate <= buyBackRateUL);
        require(_platformFee <= platformFeeUL);

        AUTO_PACOCA = IPacocaVault(_autoPacoca);
        STAKED_TOKEN = IERC20(_stakedToken);
        STAKED_TOKEN_FARM = IFarm(_stakedTokenFarm);
        FARM_REWARD_TOKEN = IERC20(_farmRewardToken);
        FARM_PID = _farmPid;
        IS_CAKE_STAKING = _isCakeStaking;
        IS_WAULT = _stakedTokenFarm == 0x22fB2663C7ca71Adc2cc99481C77Aaf21E152e2D;
        IS_BISWAP = _stakedTokenFarm == 0xDbc1A13490deeF9c3C12b44FE77b503c1B061739;

        router = IPancakeRouter02(_router);
        pathToPacoca = _pathToPacoca;
        pathToWbnb = _pathToWbnb;

        buyBackRate = _buyBackRate;
        platformFee = _platformFee;

        transferOwnership(_owner);
        treasury = _treasury;
        keeper = _keeper;
        platform = _platform;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(keeper == msg.sender, "SweetVault: caller is not the keeper");
        _;
    }

    // 1. Harvest rewards
    // 2. Collect fees
    // 3. Convert rewards to $PACOCA
    // 4. Stake to pacoca auto-compound vault
    function earn(
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minPacocaOutput
    ) external onlyKeeper {
        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(0);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0, true);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0);
        }

        uint256 rewardTokenBalance = _rewardTokenBalance();

        // Collect platform fees
        if (platformFee > 0) {
            _swap(
                rewardTokenBalance.mul(platformFee).div(10000),
                _minPlatformOutput,
                pathToWbnb,
                platform
            );
        }

        // Collect keeper fees
        if (keeperFee > 0) {
            _swap(
                rewardTokenBalance.mul(keeperFee).div(10000),
                _minKeeperOutput,
                pathToWbnb,
                treasury
            );
        }

        // Collect Burn fees
        if (buyBackRate > 0) {
            _swap(
                rewardTokenBalance.mul(buyBackRate).div(10000),
                _minBurnOutput,
                pathToPacoca,
                BURN_ADDRESS
            );
        }

        // Convert remaining rewards to PACOCA
        _swap(
            _rewardTokenBalance(),
            _minPacocaOutput,
            pathToPacoca,
            address(this)
        );

        uint256 previousShares = totalAutoPacocaShares();
        uint256 pacocaBalance = _pacocaBalance();

        _approveTokenIfNeeded(
            PACOCA,
            pacocaBalance,
            address(AUTO_PACOCA)
        );

        AUTO_PACOCA.deposit(pacocaBalance);

        uint256 currentShares = totalAutoPacocaShares();

        accSharesPerStakedToken = accSharesPerStakedToken.add(
            currentShares.sub(previousShares).mul(1e18).div(totalStake())
        );
    }

    function deposit(uint256 _amount) external virtual nonReentrant {
        require(_amount > 0, "SweetVault: amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        STAKED_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _approveTokenIfNeeded(
            STAKED_TOKEN,
            _amount,
            address(STAKED_TOKEN_FARM)
        );

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.enterStaking(_amount);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount, false);
        } else {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount);
        }

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.add(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external virtual nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "SweetVault: amount must be greater than zero");
        require(user.stake >= _amount, "SweetVault: withdraw amount exceeds balance");

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(_amount);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount, false);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount);
        }

        uint256 currentAmount = _amount;

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(earlyWithdrawFee).div(10000);

            STAKED_TOKEN.safeTransfer(treasury, currentWithdrawFee);

            currentAmount = currentAmount.sub(currentWithdrawFee);

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.sub(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);

        // Withdraw pacoca rewards if user leaves
        if (user.stake == 0 && user.autoPacocaShares > 0) {
            _claimRewards(user.autoPacocaShares, false);
        }

        STAKED_TOKEN.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    function claimRewards(uint256 _shares) external nonReentrant {
        _claimRewards(_shares, true);
    }

    function _claimRewards(uint256 _shares, bool _update) internal {
        UserInfo storage user = userInfo[msg.sender];

        if (_update) {
            user.autoPacocaShares = user.autoPacocaShares.add(
                user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                    user.rewardDebt
                )
            );

            user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        }

        require(user.autoPacocaShares >= _shares, "SweetVault: claim amount exceeds balance");

        user.autoPacocaShares = user.autoPacocaShares.sub(_shares);

        uint256 pacocaBalanceBefore = _pacocaBalance();

        AUTO_PACOCA.withdraw(_shares);

        uint256 withdrawAmount = _pacocaBalance().sub(pacocaBalanceBefore);

        _safePACOCATransfer(msg.sender, withdrawAmount);

        emit ClaimRewards(msg.sender, _shares, withdrawAmount);
    }

    function getExpectedOutputs() external view returns (
        uint256 platformOutput,
        uint256 keeperOutput,
        uint256 burnOutput,
        uint256 pacocaOutput
    ) {
        uint256 wbnbOutput = _getExpectedOutput(pathToWbnb);
        uint256 pacocaOutputWithoutFees = _getExpectedOutput(pathToPacoca);

        platformOutput = wbnbOutput.mul(platformFee).div(10000);
        keeperOutput = wbnbOutput.mul(keeperFee).div(10000);
        burnOutput = pacocaOutputWithoutFees.mul(buyBackRate).div(10000);

        pacocaOutput = pacocaOutputWithoutFees.sub(
            pacocaOutputWithoutFees.mul(platformFee).div(10000).add(
                pacocaOutputWithoutFees.mul(keeperFee).div(10000)
            ).add(
                pacocaOutputWithoutFees.mul(buyBackRate).div(10000)
            )
        );
    }

    function _getExpectedOutput(
        address[] memory _path
    ) internal virtual view returns (uint256) {
        uint256 pending;

        if (IS_WAULT) {
            pending = STAKED_TOKEN_FARM.pendingWex(FARM_PID, address(this));
        } else if (IS_BISWAP) {
            pending = STAKED_TOKEN_FARM.pendingBSW(FARM_PID, address(this));
        } else {
            pending = STAKED_TOKEN_FARM.pendingCake(FARM_PID, address(this));
        }

        uint256 rewards = _rewardTokenBalance().add(pending);

        uint256[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length.sub(1)];
    }

    function balanceOf(
        address _user
    ) external view returns (
        uint256 stake,
        uint256 pacoca,
        uint256 autoPacocaShares
    ) {
        UserInfo memory user = userInfo[_user];

        uint256 pendingShares = user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
            user.rewardDebt
        );

        stake = user.stake;
        autoPacocaShares = user.autoPacocaShares.add(pendingShares);
        pacoca = autoPacocaShares.mul(AUTO_PACOCA.getPricePerFullShare()).div(1e18);
    }

    function _approveTokenIfNeeded(
        IERC20 _token,
        uint256 _amount,
        address _spender
    ) internal {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.safeIncreaseAllowance(_spender, _amount);
        }
    }

    function _rewardTokenBalance() internal view returns (uint256) {
        return FARM_REWARD_TOKEN.balanceOf(address(this));
    }

    function _pacocaBalance() private view returns (uint256) {
        return PACOCA.balanceOf(address(this));
    }

    function totalStake() public view returns (uint256) {
        return STAKED_TOKEN_FARM.userInfo(FARM_PID, address(this));
    }

    function totalAutoPacocaShares() public view returns (uint256) {
        (uint256 shares, , ,) = AUTO_PACOCA.userInfo(address(this));

        return shares;
    }

    // Safe PACOCA transfer function, just in case if rounding error causes pool to not have enough
    function _safePACOCATransfer(address _to, uint256 _amount) private {
        uint256 balance = _pacocaBalance();

        if (_amount > balance) {
            PACOCA.transfer(_to, balance);
        } else {
            PACOCA.transfer(_to, _amount);
        }
    }

    function _swap(
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        address[] memory _path,
        address _to
    ) internal virtual {
        _approveTokenIfNeeded(
            FARM_REWARD_TOKEN,
            _inputAmount,
            address(router)
        );

        router.swapExactTokensForTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );
    }

    function setPathToPacoca(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == address(PACOCA),
            "SweetVault: Incorrect path to PACOCA"
        );

        address[] memory oldPath = pathToPacoca;

        pathToPacoca = _path;

        emit SetPathToPacoca(oldPath, pathToPacoca);
    }

    function setPathToWbnb(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        address[] memory oldPath = pathToWbnb;

        pathToWbnb = _path;

        emit SetPathToWbnb(oldPath, pathToWbnb);
    }

    function setTreasury(address _treasury) external onlyOwner {
        address oldTreasury = treasury;

        treasury = _treasury;

        emit SetTreasury(oldTreasury, treasury);
    }

    function setKeeper(address _keeper) external onlyOwner {
        address oldKeeper = keeper;

        keeper = _keeper;

        emit SetKeeper(oldKeeper, keeper);
    }

    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(_keeperFee <= keeperFeeUL, "SweetVault: Keeper fee too high");

        uint256 oldKeeperFee = keeperFee;

        keeperFee = _keeperFee;

        emit SetKeeperFee(oldKeeperFee, keeperFee);
    }

    function setPlatform(address _platform) external onlyOwner {
        address oldPlatform = platform;

        platform = _platform;

        emit SetPlatform(oldPlatform, platform);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= platformFeeUL, "SweetVault: Platform fee too high");

        uint256 oldPlatformFee = platformFee;

        platformFee = _platformFee;

        emit SetPlatformFee(oldPlatformFee, platformFee);
    }

    function setBuyBackRate(uint256 _buyBackRate) external onlyOwner {
        require(
            _buyBackRate <= buyBackRateUL,
            "SweetVault: Buy back rate too high"
        );

        uint256 oldBuyBackRate = buyBackRate;

        buyBackRate = _buyBackRate;

        emit SetBuyBackRate(oldBuyBackRate, buyBackRate);
    }

    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(
            _earlyWithdrawFee <= earlyWithdrawFeeUL,
            "SweetVault: Early withdraw fee too high"
        );

        uint256 oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFarm {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function pendingBSW(uint256 _pid, address _user) external view returns (uint256);
    function pendingWex(uint256 _pid, address _user) external view returns (uint256);
    function pendingEarnings(uint256 _pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;
    function deposit(uint256 _pid, uint256 _amount, address _referrer) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPacocaVault {
    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function userInfo(address _user) external view returns (
        uint256 shares,
        uint256 lastDepositedTime,
        uint256 pacocaAtLastUserAction,
        uint256 lastUserActionTime
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IFarm.sol";
import "./interfaces/IPancakeRouter01.sol";
import "./interfaces/IPacocaVault.sol";

contract NativeSweetVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        // How many assets the user has provided.
        uint256 stake;
        // How many staked $PACOCA user had at his last action
        uint256 autoPacocaShares;
        // Pacoca shares not entitled to the user
        uint256 rewardDebt;
        // Timestamp of last user deposit
        uint256 lastDepositedTime;
    }

    // Addresses
    address constant public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 constant public PACOCA = IERC20(0x55671114d774ee99D653D6C12460c780a67f1D18);
    IPacocaVault immutable public AUTO_PACOCA;
    IERC20 immutable public STAKED_TOKEN;

    // Runtime data
    mapping(address => UserInfo) public userInfo; // Info of users
    uint256 public accSharesPerStakedToken; // Accumulated AUTO_PACOCA shares per staked token, times 1e18.

    // Farm info
    IFarm immutable public STAKED_TOKEN_FARM;
    IERC20 immutable public FARM_REWARD_TOKEN;
    uint256 immutable public FARM_PID;
    bool immutable public IS_CAKE_STAKING;
    bool immutable public IS_WAULT;
    bool immutable public IS_BISWAP;

    // Settings
    IPancakeRouter01 immutable public router;
    address[] public pathToPacoca; // Path from staked token to PACOCA
    address[] public pathToWbnb; // Path from staked token to WBNB

    address public treasury;
    address public keeper;
    uint256 public keeperFee = 50; // 0.5%
    uint256 public constant keeperFeeUL = 100; // 1%

    address public platform;
    uint256 public platformFee;
    uint256 public constant platformFeeUL = 500; // 5%

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public buyBackRate;
    uint256 public constant buyBackRateUL = 300; // 5%

    uint256 public earlyWithdrawFee = 100; // 1%
    uint256 public constant earlyWithdrawFeeUL = 300; // 3%
    uint256 public constant withdrawFeePeriod = 3 days;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EarlyWithdraw(address indexed user, uint256 amount, uint256 fee);
    event ClaimRewards(address indexed user, uint256 shares, uint256 amount);

    // Setting updates
    event SetPathToPacoca(address[] oldPath, address[] newPath);
    event SetPathToWbnb(address[] oldPath, address[] newPath);
    event SetBuyBackRate(uint256 oldBuyBackRate, uint256 newBuyBackRate);
    event SetTreasury(address oldTreasury, address newTreasury);
    event SetKeeper(address oldKeeper, address newKeeper);
    event SetKeeperFee(uint256 oldKeeperFee, uint256 newKeeperFee);
    event SetPlatform(address oldPlatform, address newPlatform);
    event SetPlatformFee(uint256 oldPlatformFee, uint256 newPlatformFee);
    event SetEarlyWithdrawFee(uint256 oldEarlyWithdrawFee, uint256 newEarlyWithdrawFee);

    constructor(
        address _autoPacoca,
        address _stakedToken,
        address _stakedTokenFarm,
        address _farmRewardToken,
        uint256 _farmPid,
        bool _isCakeStaking,
        address _router,
        address[] memory _pathToPacoca,
        address[] memory _pathToWbnb,
        address _owner,
        address _treasury,
        address _keeper,
        address _platform,
        uint256 _buyBackRate,
        uint256 _platformFee
    ) public {
        require(
            _pathToPacoca[0] == address(_farmRewardToken) && _pathToPacoca[_pathToPacoca.length - 1] == address(PACOCA),
            "SweetVault: Incorrect path to PACOCA"
        );

        require(
            _pathToWbnb[0] == address(_farmRewardToken) && _pathToWbnb[_pathToWbnb.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        require(_buyBackRate <= buyBackRateUL);
        require(_platformFee <= platformFeeUL);

        AUTO_PACOCA = IPacocaVault(_autoPacoca);
        STAKED_TOKEN = IERC20(_stakedToken);
        STAKED_TOKEN_FARM = IFarm(_stakedTokenFarm);
        FARM_REWARD_TOKEN = IERC20(_farmRewardToken);
        FARM_PID = _farmPid;
        IS_CAKE_STAKING = _isCakeStaking;
        IS_WAULT = _stakedTokenFarm == 0x22fB2663C7ca71Adc2cc99481C77Aaf21E152e2D;
        IS_BISWAP = _stakedTokenFarm == 0xDbc1A13490deeF9c3C12b44FE77b503c1B061739;

        router = IPancakeRouter01(_router);
        pathToPacoca = _pathToPacoca;
        pathToWbnb = _pathToWbnb;

        buyBackRate = _buyBackRate;
        platformFee = _platformFee;

        transferOwnership(_owner);
        treasury = _treasury;
        keeper = _keeper;
        platform = _platform;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(keeper == msg.sender, "SweetVault: caller is not the keeper");
        _;
    }

    // 1. Harvest rewards
    // 2. Collect fees
    // 3. Convert rewards to $PACOCA
    // 4. Stake to pacoca auto-compound vault
    function earn(
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minPacocaOutput
    ) external onlyKeeper {
        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(0);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0, true);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0);
        }

        uint256 rewardTokenBalance = _rewardTokenBalance();

        // Collect platform fees
        if (platformFee > 0) {
            _swap(
                rewardTokenBalance.mul(platformFee).div(10000),
                _minPlatformOutput,
                pathToWbnb,
                platform
            );
        }

        // Collect keeper fees
        if (keeperFee > 0) {
            _swap(
                rewardTokenBalance.mul(keeperFee).div(10000),
                _minKeeperOutput,
                pathToWbnb,
                treasury
            );
        }

        // Collect Burn fees
        if (buyBackRate > 0) {
            _swap(
                rewardTokenBalance.mul(buyBackRate).div(10000),
                _minBurnOutput,
                pathToPacoca,
                BURN_ADDRESS
            );
        }

        // Convert remaining rewards to PACOCA
        _swap(
            _rewardTokenBalance(),
            _minPacocaOutput,
            pathToPacoca,
            address(this)
        );

        uint256 previousShares = totalAutoPacocaShares();
        uint256 pacocaBalance = _pacocaBalance();

        _approveTokenIfNeeded(
            PACOCA,
            pacocaBalance,
            address(AUTO_PACOCA)
        );

        AUTO_PACOCA.deposit(pacocaBalance);

        uint256 currentShares = totalAutoPacocaShares();

        accSharesPerStakedToken = accSharesPerStakedToken.add(
            currentShares.sub(previousShares).mul(1e18).div(totalStake())
        );
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "SweetVault: amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        STAKED_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        _approveTokenIfNeeded(
            STAKED_TOKEN,
            _amount,
            address(STAKED_TOKEN_FARM)
        );

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.enterStaking(_amount);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount, false);
        } else {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount);
        }

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.add(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "SweetVault: amount must be greater than zero");
        require(user.stake >= _amount, "SweetVault: withdraw amount exceeds balance");

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(_amount);
        } else if (IS_WAULT) {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount, false);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount);
        }

        uint256 currentAmount = _amount;

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(earlyWithdrawFee).div(10000);

            STAKED_TOKEN.safeTransfer(treasury, currentWithdrawFee);

            currentAmount = currentAmount.sub(currentWithdrawFee);

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.sub(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);

        // Withdraw pacoca rewards if user leaves
        if (user.stake == 0 && user.autoPacocaShares > 0) {
            _claimRewards(user.autoPacocaShares, false);
        }

        STAKED_TOKEN.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    function claimRewards(uint256 _shares) external nonReentrant {
        _claimRewards(_shares, true);
    }

    function _claimRewards(uint256 _shares, bool _update) private {
        UserInfo storage user = userInfo[msg.sender];

        if (_update) {
            user.autoPacocaShares = user.autoPacocaShares.add(
                user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                    user.rewardDebt
                )
            );

            user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        }

        require(user.autoPacocaShares >= _shares, "SweetVault: claim amount exceeds balance");

        user.autoPacocaShares = user.autoPacocaShares.sub(_shares);

        uint256 pacocaBalanceBefore = _pacocaBalance();

        AUTO_PACOCA.withdraw(_shares);

        uint256 withdrawAmount = _pacocaBalance().sub(pacocaBalanceBefore);

        _safePACOCATransfer(msg.sender, withdrawAmount);

        emit ClaimRewards(msg.sender, _shares, withdrawAmount);
    }

    function getExpectedOutputs() external view returns (
        uint256 platformOutput,
        uint256 keeperOutput,
        uint256 burnOutput,
        uint256 pacocaOutput
    ) {
        uint256 wbnbOutput = _getExpectedOutput(pathToWbnb);
        uint256 pacocaOutputWithoutFees = _getExpectedOutput(pathToPacoca);

        platformOutput = wbnbOutput.mul(platformFee).div(10000);
        keeperOutput = wbnbOutput.mul(keeperFee).div(10000);
        burnOutput = pacocaOutputWithoutFees.mul(buyBackRate).div(10000);

        pacocaOutput = pacocaOutputWithoutFees.sub(
            pacocaOutputWithoutFees.mul(platformFee).div(10000).add(
                pacocaOutputWithoutFees.mul(keeperFee).div(10000)
            ).add(
                pacocaOutputWithoutFees.mul(buyBackRate).div(10000)
            )
        );
    }

    function _getExpectedOutput(
        address[] memory _path
    ) private view returns (uint256) {
        uint256 pending;

        if (IS_WAULT) {
            pending = STAKED_TOKEN_FARM.pendingWex(FARM_PID, address(this));
        } else if (IS_BISWAP) {
            pending = STAKED_TOKEN_FARM.pendingBSW(FARM_PID, address(this));
        } else {
            pending = STAKED_TOKEN_FARM.pendingCake(FARM_PID, address(this));
        }

        uint256 rewards = _rewardTokenBalance().add(pending);

        uint256[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length.sub(1)];
    }

    function balanceOf(
        address _user
    ) external view returns (
        uint256 stake,
        uint256 pacoca,
        uint256 autoPacocaShares
    ) {
        UserInfo memory user = userInfo[_user];

        uint256 pendingShares = user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
            user.rewardDebt
        );

        stake = user.stake;
        autoPacocaShares = user.autoPacocaShares.add(pendingShares);
        pacoca = autoPacocaShares.mul(AUTO_PACOCA.getPricePerFullShare()).div(1e18);
    }

    function _approveTokenIfNeeded(
        IERC20 _token,
        uint256 _amount,
        address _spender
    ) private {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.safeIncreaseAllowance(_spender, _amount);
        }
    }

    function _rewardTokenBalance() private view returns (uint256) {
        return FARM_REWARD_TOKEN.balanceOf(address(this));
    }

    function _pacocaBalance() private view returns (uint256) {
        return PACOCA.balanceOf(address(this));
    }

    function totalStake() public view returns (uint256) {
        return STAKED_TOKEN_FARM.userInfo(FARM_PID, address(this));
    }

    function totalAutoPacocaShares() public view returns (uint256) {
        (uint256 shares, , ,) = AUTO_PACOCA.userInfo(address(this));

        return shares;
    }

    // Safe PACOCA transfer function, just in case if rounding error causes pool to not have enough
    function _safePACOCATransfer(address _to, uint256 _amount) private {
        uint256 balance = _pacocaBalance();

        if (_amount > balance) {
            PACOCA.transfer(_to, balance);
        } else {
            PACOCA.transfer(_to, _amount);
        }
    }

    function _swap(
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        address[] memory _path,
        address _to
    ) private {
        _approveTokenIfNeeded(
            FARM_REWARD_TOKEN,
            _inputAmount,
            address(router)
        );

        router.swapExactTokensForTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );
    }

    function setPathToPacoca(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == address(PACOCA),
            "SweetVault: Incorrect path to PACOCA"
        );

        address[] memory oldPath = pathToPacoca;

        pathToPacoca = _path;

        emit SetPathToPacoca(oldPath, pathToPacoca);
    }

    function setPathToWbnb(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == WBNB,
            "SweetVault: Incorrect path to WBNB"
        );

        address[] memory oldPath = pathToWbnb;

        pathToWbnb = _path;

        emit SetPathToWbnb(oldPath, pathToWbnb);
    }

    function setTreasury(address _treasury) external onlyOwner {
        address oldTreasury = treasury;

        treasury = _treasury;

        emit SetTreasury(oldTreasury, treasury);
    }

    function setKeeper(address _keeper) external onlyOwner {
        address oldKeeper = keeper;

        keeper = _keeper;

        emit SetKeeper(oldKeeper, keeper);
    }

    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(_keeperFee <= keeperFeeUL, "SweetVault: Keeper fee too high");

        uint256 oldKeeperFee = keeperFee;

        keeperFee = _keeperFee;

        emit SetKeeperFee(oldKeeperFee, keeperFee);
    }

    function setPlatform(address _platform) external onlyOwner {
        address oldPlatform = platform;

        platform = _platform;

        emit SetPlatform(oldPlatform, platform);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= platformFeeUL, "SweetVault: Platform fee too high");

        uint256 oldPlatformFee = platformFee;

        platformFee = _platformFee;

        emit SetPlatformFee(oldPlatformFee, platformFee);
    }

    function setBuyBackRate(uint256 _buyBackRate) external onlyOwner {
        require(
            _buyBackRate <= buyBackRateUL,
            "SweetVault: Buy back rate too high"
        );

        uint256 oldBuyBackRate = buyBackRate;

        buyBackRate = _buyBackRate;

        emit SetBuyBackRate(oldBuyBackRate, buyBackRate);
    }

    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(
            _earlyWithdrawFee <= earlyWithdrawFeeUL,
            "SweetVault: Early withdraw fee too high"
        );

        uint256 oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IPancakeRouter01.sol";

interface IWBNB {
    function withdraw(uint) external;
}

contract Pool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when mining ends. Never ends if set to zero
    uint256 public bonusEndBlock;

    // The block number when mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // Tokens earned per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public immutable PRECISION_FACTOR;

    // The reward token
    IERC20 public immutable rewardToken;

    // The staked token
    IERC20 public immutable stakedToken;

    // WBNB address
    IWBNB public immutable WBNB;
    bool public immutable IS_BNB_REWARDS;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event EmergencyRewardWithdraw(uint256 amount);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardTokenDecimals: reward token decimals
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _admin: admin address with ownership
     */
    constructor(
        address _wbnb,
        address _stakedToken,
        address _rewardToken,
        uint256 _rewardTokenDecimals,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        address _admin
    ) public {
        require(_stakedToken != _rewardToken, "Staked and reward token must be different");

        WBNB = IWBNB(_wbnb);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        require(_rewardTokenDecimals < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10 ** (uint256(30).sub(_rewardTokenDecimals)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        IS_BNB_REWARDS = _rewardToken == _wbnb;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    receive() external payable {
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                if (IS_BNB_REWARDS) {
                    WBNB.withdraw(pending);
                    msg.sender.transfer(pending);
                } else {
                    rewardToken.safeTransfer(address(msg.sender), pending);
                }
            }
        }

        if (_amount > 0) {
            uint256 initialBalance = stakedToken.balanceOf(address(this));
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);

            uint256 receivedAmount = stakedToken.balanceOf(address(this)).sub(initialBalance);
            user.amount = user.amount.add(receivedAmount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    function compound(
        address _router,
        address[] calldata _path,
        uint256 _minOutput
    ) external nonReentrant {
        require(
            _path[0] == address(rewardToken) && _path[_path.length - 1] == address(stakedToken),
            "compound: Invalid path"
        );

        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount == 0) {
            return;
        }

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        uint256 initialBalance = stakedToken.balanceOf(address(this));

        rewardToken.safeIncreaseAllowance(_router, pending);

        IPancakeRouter01(_router).swapExactTokensForTokens(
            pending,
            _minOutput,
            _path,
            address(this),
            block.timestamp
        );

        uint256 amount = stakedToken.balanceOf(address(this)).sub(initialBalance);

        user.amount = user.amount.add(amount);
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Compound(msg.sender, amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakedToken.safeTransfer(address(msg.sender), _amount);
        }

        if (pending > 0) {
            if (IS_BNB_REWARDS) {
                WBNB.withdraw(pending);
                msg.sender.transfer(pending);
            } else {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;

        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);

        emit EmergencyRewardWithdraw(_amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(bonusEndBlock == 0 || block.number < startBlock, "Pool has started");

        _updatePool();

        rewardPerBlock = _rewardPerBlock;

        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));

            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock);

        accTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    ) internal view returns (uint256) {
        if (_to <= bonusEndBlock || bonusEndBlock == 0) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IPancakeswapFarm.sol";
import "./interfaces/IPancakeRouter02.sol";

interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

abstract contract StratX2 is Ownable, ReentrancyGuard, Pausable {
    // Maximises yields in pancakeswap

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isCAKEStaking; // only for staking CAKE using pancakeswap's native CAKE staking contract.
    bool public isSameAssetDeposit;
    bool public isAutoComp; // this vault is purely for staking. eg. WBNB-AUTO staking vault.

    address public farmContractAddress; // address of farm, eg, PCS, Thugs etc.
    uint256 public pid; // pid of pool in farmContractAddress
    address public wantAddress;
    address public token0Address;
    address public token1Address;
    address public earnedAddress;
    address public uniRouterAddress; // uniswap, pancakeswap etc

    address public wbnbAddress;
    address public autoFarmAddress;
    address public AUTOAddress;
    address public govAddress; // timelock contract
    bool public onlyGov = false;

    uint256 public lastEarnBlock = 0;
    uint256 public wantLockedTotal = 0;
    uint256 public sharesTotal = 0;

    uint256 public controllerFee = 0; // 70;
    uint256 public constant controllerFeeMax = 10000; // 100 = 1%
    uint256 public constant controllerFeeUL = 300;

    uint256 public buyBackRate = 0; // 250;
    uint256 public constant buyBackRateMax = 10000; // 100 = 1%
    uint256 public constant buyBackRateUL = 800;
    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;
    address public rewardsAddress;

    uint256 public entranceFeeFactor = 9990; // < 0.1% entrance fee - goes to pool + prevents front-running
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public withdrawFeeFactor = 10000; // 0.1% withdraw fee - goes to pool
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public slippageFactor = 950; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 995;

    address[] public earnedToAUTOPath;
    address[] public earnedToToken0Path;
    address[] public earnedToToken1Path;
    address[] public token0ToEarnedPath;
    address[] public token1ToEarnedPath;

    event SetSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _slippageFactor
    );

    event SetGov(address _govAddress);
    event SetOnlyGov(bool _onlyGov);
    event SetUniRouterAddress(address _uniRouterAddress);
    event SetRewardsAddress(address _rewardsAddress);

    modifier onlyAllowGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }

    // Receives new deposits from user
    function deposit(
        address _userAddress,
        uint256 _wantAmt
    ) external virtual onlyOwner nonReentrant whenNotPaused returns (uint256) {
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        uint256 sharesAdded = _wantAmt;
        if (wantLockedTotal > 0 && sharesTotal > 0) {
            sharesAdded = _wantAmt
            .mul(sharesTotal)
            .mul(entranceFeeFactor)
            .div(wantLockedTotal)
            .div(entranceFeeFactorMax);
        }
        sharesTotal = sharesTotal.add(sharesAdded);

        if (isAutoComp) {
            _farm();
        } else {
            wantLockedTotal = wantLockedTotal.add(_wantAmt);
        }

        return sharesAdded;
    }

    function farm() external virtual nonReentrant {
        _farm();
    }

    function _farm() internal virtual {
        require(isAutoComp, "!isAutoComp");
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).enterStaking(wantAmt); // Just for CAKE staking, we dont use deposit()
        } else {
            IPancakeswapFarm(farmContractAddress).deposit(pid, wantAmt);
        }
    }

    function _unfarm(uint256 _wantAmt) internal virtual {
        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).leaveStaking(_wantAmt); // Just for CAKE staking, we dont use withdraw()
        } else {
            IPancakeswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
        }
    }

    function withdraw(
        address _userAddress,
        uint256 _wantAmt
    ) external virtual onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "_wantAmt <= 0");

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }
        sharesTotal = sharesTotal.sub(sharesRemoved);

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(
                withdrawFeeFactorMax
            );
        }

        if (isAutoComp) {
            _unfarm(_wantAmt);
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20(wantAddress).safeTransfer(autoFarmAddress, _wantAmt);

        return sharesRemoved;
    }

    // 1. Harvest farm tokens
    // 2. Converts farm tokens into want tokens
    // 3. Deposits want tokens

    function earn() external virtual nonReentrant whenNotPaused {
        require(isAutoComp, "!isAutoComp");

        if (onlyGov) {
            require(msg.sender == govAddress, "!gov");
        }

        // Harvest farm tokens
        _unfarm(0);

        if (earnedAddress == wbnbAddress) {
            _wrapBNB();
        }

        // Converts farm tokens into want tokens
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));

        earnedAmt = distributeFees(earnedAmt);
        earnedAmt = buyBack(earnedAmt);

        if (isCAKEStaking || isSameAssetDeposit) {
            lastEarnBlock = block.number;
            _farm();
            return;
        }

        IERC20(earnedAddress).safeApprove(uniRouterAddress, 0);
        IERC20(earnedAddress).safeIncreaseAllowance(
            uniRouterAddress,
            earnedAmt
        );

        if (earnedAddress != token0Address) {
            // Swap half earned to token0
            _safeSwap(
                uniRouterAddress,
                earnedAmt.div(2),
                slippageFactor,
                earnedToToken0Path,
                address(this),
                block.timestamp.add(600)
            );
        }

        if (earnedAddress != token1Address) {
            // Swap half earned to token1
            _safeSwap(
                uniRouterAddress,
                earnedAmt.div(2),
                slippageFactor,
                earnedToToken1Path,
                address(this),
                block.timestamp.add(600)
            );
        }

        // Get want tokens, ie. add liquidity
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token0Amt > 0 && token1Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );
            IPancakeRouter02(uniRouterAddress).addLiquidity(
                token0Address,
                token1Address,
                token0Amt,
                token1Amt,
                0,
                0,
                address(this),
                block.timestamp.add(600)
            );
        }

        lastEarnBlock = block.number;

        _farm();
    }

    function buyBack(uint256 _earnedAmt) internal virtual returns (uint256) {
        if (buyBackRate == 0) {
            return _earnedAmt;
        }

        uint256 buyBackAmt = _earnedAmt.mul(buyBackRate).div(buyBackRateMax);

        if (earnedAddress == AUTOAddress) {
            IERC20(earnedAddress).safeTransfer(buyBackAddress, buyBackAmt);
        } else {
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                buyBackAmt
            );

            _safeSwap(
                uniRouterAddress,
                buyBackAmt,
                slippageFactor,
                earnedToAUTOPath,
                buyBackAddress,
                block.timestamp.add(600)
            );
        }

        return _earnedAmt.sub(buyBackAmt);
    }

    function distributeFees(uint256 _earnedAmt) internal virtual returns (uint256) {
        if (_earnedAmt > 0 && controllerFee > 0) {
            uint256 fee = _earnedAmt.mul(controllerFee).div(controllerFeeMax);
            IERC20(earnedAddress).safeTransfer(rewardsAddress, fee);
            _earnedAmt = _earnedAmt.sub(fee);
        }

        return _earnedAmt;
    }

    function convertDustToEarned() external virtual whenNotPaused {
        require(isAutoComp, "!isAutoComp");
        require(!isCAKEStaking, "isCAKEStaking");

        // Converts dust tokens into earned tokens, which will be reinvested on the next earn().

        // Converts token0 dust (if any) to earned tokens
        uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
        if (token0Address != earnedAddress && token0Amt > 0) {
            IERC20(token0Address).safeIncreaseAllowance(
                uniRouterAddress,
                token0Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                uniRouterAddress,
                token0Amt,
                slippageFactor,
                token0ToEarnedPath,
                address(this),
                block.timestamp.add(600)
            );
        }

        // Converts token1 dust (if any) to earned tokens
        uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
        if (token1Address != earnedAddress && token1Amt > 0) {
            IERC20(token1Address).safeIncreaseAllowance(
                uniRouterAddress,
                token1Amt
            );

            // Swap all dust tokens to earned tokens
            _safeSwap(
                uniRouterAddress,
                token1Amt,
                slippageFactor,
                token1ToEarnedPath,
                address(this),
                block.timestamp.add(600)
            );
        }
    }

    function pause() external virtual onlyAllowGov {
        _pause();
    }

    function unpause() external virtual onlyAllowGov {
        _unpause();
    }

    function setSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _slippageFactor
    ) external virtual onlyAllowGov {
        require(
            _entranceFeeFactor >= entranceFeeFactorLL,
            "_entranceFeeFactor too low"
        );
        require(
            _entranceFeeFactor <= entranceFeeFactorMax,
            "_entranceFeeFactor too high"
        );
        entranceFeeFactor = _entranceFeeFactor;

        require(
            _withdrawFeeFactor >= withdrawFeeFactorLL,
            "_withdrawFeeFactor too low"
        );
        require(
            _withdrawFeeFactor <= withdrawFeeFactorMax,
            "_withdrawFeeFactor too high"
        );
        withdrawFeeFactor = _withdrawFeeFactor;

        require(_controllerFee <= controllerFeeUL, "_controllerFee too high");
        controllerFee = _controllerFee;

        require(_buyBackRate <= buyBackRateUL, "_buyBackRate too high");
        buyBackRate = _buyBackRate;

        require(
            _slippageFactor <= slippageFactorUL,
            "_slippageFactor too high"
        );
        slippageFactor = _slippageFactor;

        emit SetSettings(
            _entranceFeeFactor,
            _withdrawFeeFactor,
            _controllerFee,
            _buyBackRate,
            _slippageFactor
        );
    }

    function setGov(address _govAddress) external virtual onlyAllowGov {
        govAddress = _govAddress;
        emit SetGov(_govAddress);
    }

    function setOnlyGov(bool _onlyGov) external virtual onlyAllowGov {
        onlyGov = _onlyGov;
        emit SetOnlyGov(_onlyGov);
    }

    function setUniRouterAddress(
        address _uniRouterAddress
    ) external virtual onlyAllowGov {
        uniRouterAddress = _uniRouterAddress;
        emit SetUniRouterAddress(_uniRouterAddress);
    }

    function setRewardsAddress(
        address _rewardsAddress
    ) external virtual onlyAllowGov {
        rewardsAddress = _rewardsAddress;
        emit SetRewardsAddress(_rewardsAddress);
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external virtual onlyAllowGov {
        require(_token != earnedAddress, "!safe");
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _wrapBNB() internal virtual {
        // BNB -> WBNB
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            IWBNB(wbnbAddress).deposit{value: bnbBal}(); // BNB -> WBNB
        }
    }

    function wrapBNB() external virtual onlyAllowGov {
        _wrapBNB();
    }

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual {
        uint256[] memory amounts =
        IPancakeRouter02(_uniRouterAddress).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length.sub(1)];

        IPancakeRouter02(_uniRouterAddress)
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            amountOut.mul(_slippageFactor).div(1000),
            _path,
            _to,
            _deadline
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function pendingBSW(uint256 _pid, address _user) external view returns (uint256);
    function pendingWex(uint256 _pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

contract StratX2_CAFE is StratX2 {
    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool _isCAKEStaking,
        bool _isSameAssetDeposit,
        bool _isAutoComp,
        address[] memory _earnedToAUTOPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        autoFarmAddress = _addresses[2];
        AUTOAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5];
        token1Address = _addresses[6];
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _isCAKEStaking;
        isSameAssetDeposit = _isSameAssetDeposit;
        isAutoComp = _isAutoComp;

        uniRouterAddress = _addresses[9];
        earnedToAUTOPath = _earnedToAUTOPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        entranceFeeFactor = _entranceFeeFactor;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(autoFarmAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeRouter02.sol";

contract Broom is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public constant PACOCA = 0x55671114d774ee99D653D6C12460c780a67f1D18;
    address public constant buyBackAddress = 0x000000000000000000000000000000000000dEaD;

    uint public buyBackRate = 300; // Initial fee 3%;
    uint public constant buyBackRateMax = 10000; // 100 = 1%
    uint public constant buyBackRateUL = 1000; // Fee upper limit 10%

    event SetBuyBackRate(uint _buyBackRate);

    constructor (address _owner) public {
        transferOwnership(_owner);
    }

    function sweep(
        address _router,
        address _connector,
        address[] calldata _tokens,
        uint[] calldata _amounts,
        uint[] calldata _amountsOutMin
    ) external {
        for (uint index = 0; index < _tokens.length; ++index) {
            _approveTokenIfNeeded(_tokens[index], _router);

            IERC20(_tokens[index]).safeTransferFrom(msg.sender, address(this), _amounts[index]);

            _swap(
                _router,
                _connector,
                _tokens[index],
                IERC20(_tokens[index]).balanceOf(address(this)),
                _amountsOutMin[index]
            );
        }

        uint balance = IERC20(PACOCA).balanceOf(address(this));
        uint buyBackAmount = balance.mul(buyBackRate).div(buyBackRateMax);

        _safePACOCATransfer(buyBackAddress, buyBackAmount);
        _safePACOCATransfer(msg.sender, balance.sub(buyBackAmount));
    }

    function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, uint(- 1));
        }
    }

    function _swap(
        address _router,
        address _connector,
        address _fromToken,
        uint _amount,
        uint _amountOutMin
    ) private {
        if (_fromToken == PACOCA) {
            return;
        }

        address[] memory path;

        if (_fromToken == _connector) {
            path = new address[](2);

            path[0] = _fromToken;
            path[1] = PACOCA;
        } else {
            path = new address[](3);

            path[0] = _fromToken;
            path[1] = _connector;
            path[2] = PACOCA;
        }

        IPancakeRouter02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount, // input amount
            _amountOutMin, // min output amount
            path, // path
            address(this), // to
            block.timestamp // deadline
        );
    }

    function setBuyBackRate(uint _buyBackRate) external onlyOwner {
        require(_buyBackRate <= buyBackRateUL, "_buyBackRate too high");
        buyBackRate = _buyBackRate;

        emit SetBuyBackRate(_buyBackRate);
    }

    // Safe PACOCA transfer function, just in case if rounding error causes pool to not have enough
    function _safePACOCATransfer(address _to, uint256 _amount) private {
        uint256 balance = IERC20(PACOCA).balanceOf(address(this));

        if (_amount > balance) {
            IERC20(PACOCA).transfer(_to, balance);
        } else {
            IERC20(PACOCA).transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

interface IBnbSwap {
    function swapped(address) external returns (uint256);
}

interface IPacocaNFTs {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

interface IPacoca {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PacocaAirdrop is ERC1155Receiver, Ownable {
    using SafeMath for uint256;

    event NewSwap(address user, uint256 amount);

    struct UserInfo {
        uint256 swapped;
        uint256 debt;
        bool migrated;
        mapping(uint256 => bool) claims;
    }

    struct NftInfo {
        bool claimable;
        uint256 value;
    }

    // ---------- CONTRACTS ----------

    address public oneInch;
    IBnbSwap public bnbSwap;
    IPacocaNFTs public pacocaNFTs;
    IPacoca public pacoca;

    // ---------- DATA ----------

    mapping(address => UserInfo) public users;
    mapping(uint256 => NftInfo) public nfts;
    bool public tokenClaimEnabled = false;
    bool public migrationEnabled = true;

    constructor(address _oneInch, address _bnbSwap, address _pacocaNFTs, address _pacoca) public {
        oneInch = _oneInch;
        bnbSwap = IBnbSwap(_bnbSwap);
        pacocaNFTs = IPacocaNFTs(_pacocaNFTs);
        pacoca = IPacoca(_pacoca);
    }

    // ---------- EXECUTE SWAPS ----------

    fallback() external payable {
        uint amount = msg.value;

        require(amount > 0, 'Value must be greater then 0');

        // Calculate fees
        uint fee = amount.mul(50).div(10000);

        // Send value minus fees to 1inch
        (bool success,) = oneInch.call{value : amount.sub(fee)}(msg.data);

        require(success, '1 Inch swap failed');

        _swap(msg.sender, amount);
    }

    function migrate(address _user) public {
        require(migrationEnabled, 'Migration has ended');
        require(!users[_user].migrated, 'User already migrated');

        users[_user].migrated = true;

        _swap(_user, bnbSwap.swapped(_user));
    }

    function _swap(address _user, uint256 amount) private {
        UserInfo storage user = users[msg.sender];

        user.swapped = user.swapped.add(amount);

        emit NewSwap(_user, amount);
    }

    // ---------- CLAIM REWARDS ----------

    function claimNFT(uint256 id) public {
        UserInfo storage user = users[msg.sender];
        uint256 balance = user.swapped.sub(user.debt);

        require(nfts[id].claimable, 'This NFT is not claimable yet');
        require(!user.claims[id], 'NFT already claimed');

        if (id == 0) {
            require(balance >= 20 ether, 'Not enough BNB swapped');

            user.debt = user.debt.add(20 ether);
        }
        else if (id == 1) {
            require(balance >= 10 ether, 'Not enough BNB swapped');

            user.debt = user.debt.add(10 ether);
        }
        else if (id == 2) {
            require(balance > 0, 'Not enough BNB swapped');

            user.debt = user.debt.add(5 ether);
        }

        user.claims[id] = true;
        pacocaNFTs.safeTransferFrom(address(this), msg.sender, id, 1, '');
    }

    function claimPacoca(uint nftId) public {
        require(tokenClaimEnabled, 'Tokens not yet claimable');

        pacocaNFTs.burn(msg.sender, nftId, 1);
        pacoca.transferFrom(address(this), msg.sender, nfts[nftId].value);
    }

    // ---------- ADMIN ----------

    function setNftInfo(uint id, bool claimable, uint256 value) public onlyOwner {
        NftInfo storage nft = nfts[id];

        nft.claimable = claimable;
        nft.value = value;
    }

    function setTokenClaimStatus(bool status) public onlyOwner {
        tokenClaimEnabled = status;
    }

    function setMigrationStatus(bool status) public onlyOwner {
        migrationEnabled = status;
    }

    function claimFees() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // ---------- RECEIVE PAYMENTS ----------

    receive() external payable {}

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";

contract PacocaCollectibles is ERC1155("https://api.pacoca.io/nfts/"), ERC1155Burnable, Ownable {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function getCollectibleURI(uint256 id) external view returns (string memory) {
        if (bytes(this.uri(id)).length == 0) {
            return "";
        }
        else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(this.uri(id), uint2str(id), ".json"));
        }
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint j = _i;
        uint len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bStr = new bytes(len);
        uint k = len;

        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }

        return string(bStr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract PACOCAToken is ERC20 {
    function mint(address _to, uint256 _amount) public virtual;
}

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // Transfer want tokens pacocaFarm -> strategy
    function deposit(
        address _userAddress,
        uint256 _wantAmt
    ) external returns (uint256);

    // Transfer want tokens strategy -> pacocaFarm
    function withdraw(
        address _userAddress,
        uint256 _wantAmt
    ) external returns (uint256);

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

contract PacocaFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.

        // We do some fancy math here. Basically, any point in time, the amount of PACOCA
        // entitled to a user but is pending to be distributed is:
        //
        //   amount = user.shares / sharesTotal * wantLockedTotal
        //   pending reward = (amount * pool.accPACOCAPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws want tokens to a pool. Here's what happens:
        //   1. The pool's `accPACOCAPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 want; // Address of the want token.
        uint256 allocPoint; // How many allocation points assigned to this pool. PACOCA to distribute per block.
        uint256 lastRewardBlock; // Last block number that PACOCA distribution occurs.
        uint256 accPACOCAPerShare; // Accumulated PACOCA per share, times 1e12. See below.
        address strat; // Strategy address that will PACOCA compound want tokens
    }

    address public immutable PACOCA;

    address constant public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 constant public ownerPACOCAReward = 200; // 15% Dev + 5% MKT

    uint256 public maxSupply = 100000000e18;
    uint256 public PACOCAPerBlock = 2e18; // PACOCA tokens created per block
    uint256 public immutable startBlock; // https://bscscan.com/block/countdown/7862758

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(IERC20 => bool) public availableAssets; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetAllocPoint(uint256 indexed _pid, uint256 _oldAllocPoint, uint256 _allocPoint);
    event SetMaxSupply(uint256 oldSupply, uint256 newSupply);
    event SetPacocaPerBlock(uint256 oldPacocaPerBlock, uint256 pacocaPerBlock);

    constructor(address _pacoca, uint256 _startBlock) public {
        PACOCA = _pacoca;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (IERC20(PACOCA).totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending PACOCA on frontend.
    function pendingPACOCA(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPACOCAPerShare = pool.accPACOCAPerShare;
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (block.number > pool.lastRewardBlock && sharesTotal != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 PACOCAReward = multiplier.mul(PACOCAPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            accPACOCAPerShare = accPACOCAPerShare.add(
                PACOCAReward.mul(1e12).div(sharesTotal)
            );
        }
        return user.shares.mul(accPACOCAPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see staked Want tokens on frontend.
    function stakedWantTokens(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        uint256 wantLockedTotal = IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        if (sharesTotal == 0) {
            return 0;
        }
        return user.shares.mul(wantLockedTotal).div(sharesTotal);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 sharesTotal = IStrategy(pool.strat).sharesTotal();
        if (sharesTotal == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 PACOCAReward = multiplier.mul(PACOCAPerBlock).mul(pool.allocPoint).div(
            totalAllocPoint
        );

        PACOCAToken(PACOCA).mint(
            owner(),
            PACOCAReward.mul(ownerPACOCAReward).div(1000)
        );
        PACOCAToken(PACOCA).mint(address(this), PACOCAReward);

        pool.accPACOCAPerShare = pool.accPACOCAPerShare.add(
            PACOCAReward.mul(1e12).div(sharesTotal)
        );
        pool.lastRewardBlock = block.number;
    }

    // Want tokens moved from user -> PACOCAFarm (PACOCA allocation) -> Strat (compounding)
    function deposit(uint256 _pid, uint256 _wantAmt) external nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.shares > 0) {
            uint256 pending = user.shares.mul(pool.accPACOCAPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safePACOCATransfer(msg.sender, pending);
            }
        }
        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            pool.want.safeIncreaseAllowance(pool.strat, _wantAmt);
            uint256 sharesAdded = IStrategy(poolInfo[_pid].strat).deposit(msg.sender, _wantAmt);
            user.shares = user.shares.add(sharesAdded);
        }
        user.rewardDebt = user.shares.mul(pool.accPACOCAPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _wantAmt) public nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal = IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();

        require(user.shares > 0, "user.shares is 0");
        require(sharesTotal > 0, "sharesTotal is 0");

        // Withdraw pending PACOCA
        uint256 pending = user.shares.mul(pool.accPACOCAPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safePACOCATransfer(msg.sender, pending);
        }

        // Withdraw want tokens
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);
        if (_wantAmt > amount) {
            _wantAmt = amount;
        }
        if (_wantAmt > 0) {
            uint256 sharesRemoved = IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, _wantAmt);

            if (sharesRemoved > user.shares) {
                user.shares = 0;
            } else {
                user.shares = user.shares.sub(sharesRemoved);
            }

            uint256 wantBal = IERC20(pool.want).balanceOf(address(this));
            if (wantBal < _wantAmt) {
                _wantAmt = wantBal;
            }
            pool.want.safeTransfer(address(msg.sender), _wantAmt);
        }
        user.rewardDebt = user.shares.mul(pool.accPACOCAPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }

    function withdrawAll(uint256 _pid) external nonReentrant {
        withdraw(_pid, uint256(-1));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantLockedTotal =
        IStrategy(poolInfo[_pid].strat).wantLockedTotal();
        uint256 sharesTotal = IStrategy(poolInfo[_pid].strat).sharesTotal();
        uint256 amount = user.shares.mul(wantLockedTotal).div(sharesTotal);

        IStrategy(poolInfo[_pid].strat).withdraw(msg.sender, amount);

        pool.want.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
        user.shares = 0;
        user.rewardDebt = 0;
    }

    // Safe PACOCA transfer function, just in case if rounding error causes pool to not have enough
    function safePACOCATransfer(address _to, uint256 _PACOCAAmt) internal {
        uint256 PACOCABal = IERC20(PACOCA).balanceOf(address(this));
        bool transferSuccess = false;

        if (_PACOCAAmt > PACOCABal) {
            transferSuccess = IERC20(PACOCA).transfer(_to, PACOCABal);
        } else {
            transferSuccess = IERC20(PACOCA).transfer(_to, _PACOCAAmt);
        }

        require(transferSuccess, "safePACOCATransfer: transfer failed");
    }

    /*
        ------------------------------------
                Governance functions
        ------------------------------------
    */

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. (Only if want tokens are stored here.)
    function addPool(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    ) external onlyOwner {
        require(!availableAssets[_want], "Can't add another pool of same asset");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
        want: _want,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accPACOCAPerShare: 0,
        strat: _strat
        })
        );
        availableAssets[_want] = true;
    }

    // Update the given pool's PACOCA allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 oldAllocPoint = poolInfo[_pid].allocPoint;

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );

        poolInfo[_pid].allocPoint = _allocPoint;

        emit SetAllocPoint(_pid, oldAllocPoint, _allocPoint);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        uint256 oldMaxSupply = maxSupply;

        maxSupply = _maxSupply;

        emit SetMaxSupply(oldMaxSupply, maxSupply);
    }

    function setPacocaPerBlock(uint256 _PACOCAPerBlock) public onlyOwner {
        uint256 oldPacocaPerBlock = PACOCAPerBlock;

        PACOCAPerBlock = _PACOCAPerBlock;

        emit SetPacocaPerBlock(oldPacocaPerBlock, PACOCAPerBlock);
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external onlyOwner {
        require(_token != PACOCA, "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TokenTimelock {
    uint public constant duration = 40 days;
    uint public immutable end;
    address payable public immutable owner;

    constructor(address payable _owner) public {
        end = block.timestamp + duration;
        owner = _owner;
    }

    function deposit(address token, uint amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    receive() external payable {}

    function withdraw(address token, uint amount) external {
        require(msg.sender == owner, 'only owner');
        require(block.timestamp >= end, 'too early');

        if (token == address(0)) {
            owner.transfer(amount);
        } else {
            IERC20(token).transfer(owner, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pacoca is ERC20("Pacoca", "PACOCA"), Ownable {
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./helpers/Governable.sol";

// Pacoca single token farm strategy
contract StratPacoca is Ownable, ReentrancyGuard, Pausable, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable wantAddress;
    address public immutable pacocaFarmAddress;

    // Total want tokens managed by strategy
    uint256 public wantLockedTotal = 0;

    // Sum of all shares of users to wantLockedTotal
    uint256 public sharesTotal = 0;

    uint256 public entranceFeeFactor = 10000; // No deposit fees
    uint256 public constant entranceFeeFactorMax = 10000;
    uint256 public constant entranceFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    uint256 public withdrawFeeFactor = 10000; // No withdraw fees
    uint256 public constant withdrawFeeFactorMax = 10000;
    uint256 public constant withdrawFeeFactorLL = 9950; // 0.5% is the max entrance fee settable. LL = lowerlimit

    event SetSettings(uint256 _entranceFeeFactor, uint256 _withdrawFeeFactor);

    constructor (address _pacoca, address _pacocaFarmAddress, address _govAddress) public {
        wantAddress = _pacoca;
        pacocaFarmAddress = _pacocaFarmAddress;
        govAddress = _govAddress;

        transferOwnership(_pacocaFarmAddress);
    }

    // This contract doesn't auto-compound
    // earn() function is here to follow the Strategy interface
    function earn() external {}

    // Transfer want tokens pacocaFarm -> strategy
    function deposit(
        address _userAddress,
        uint256 _wantAmt
    ) external virtual onlyOwner nonReentrant whenNotPaused returns (uint256) {
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );

        uint256 sharesAdded = _wantAmt;

        if (wantLockedTotal > 0 && sharesTotal > 0) {
            sharesAdded = _wantAmt
            .mul(sharesTotal)
            .mul(entranceFeeFactor)
            .div(wantLockedTotal)
            .div(entranceFeeFactorMax);
        }

        sharesTotal = sharesTotal.add(sharesAdded);

        wantLockedTotal = wantLockedTotal.add(_wantAmt);

        return sharesAdded;
    }

    // Transfer want tokens strategy -> pacocaFarm
    function withdraw(
        address _userAddress,
        uint256 _wantAmt
    ) external virtual onlyOwner nonReentrant returns (uint256) {
        require(_wantAmt > 0, "_wantAmt <= 0");

        uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);

        if (sharesRemoved > sharesTotal) {
            sharesRemoved = sharesTotal;
        }

        sharesTotal = sharesTotal.sub(sharesRemoved);

        if (withdrawFeeFactor < withdrawFeeFactorMax) {
            _wantAmt = _wantAmt.mul(withdrawFeeFactor).div(
                withdrawFeeFactorMax
            );
        }

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));

        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        if (wantLockedTotal < _wantAmt) {
            _wantAmt = wantLockedTotal;
        }

        wantLockedTotal = wantLockedTotal.sub(_wantAmt);

        IERC20(wantAddress).safeTransfer(pacocaFarmAddress, _wantAmt);

        return sharesRemoved;
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external virtual onlyAllowGov {
        require(_token != wantAddress, "!safe");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function setSettings(
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor
    ) external virtual onlyAllowGov {
        require(
            _entranceFeeFactor >= entranceFeeFactorLL,
            "_entranceFeeFactor too low"
        );
        require(
            _entranceFeeFactor <= entranceFeeFactorMax,
            "_entranceFeeFactor too high"
        );
        entranceFeeFactor = _entranceFeeFactor;

        require(
            _withdrawFeeFactor >= withdrawFeeFactorLL,
            "_withdrawFeeFactor too low"
        );
        require(
            _withdrawFeeFactor <= withdrawFeeFactorMax,
            "_withdrawFeeFactor too high"
        );
        withdrawFeeFactor = _withdrawFeeFactor;

        emit SetSettings(_entranceFeeFactor, _withdrawFeeFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract Governable {
    address public govAddress;

    event SetGov(address _govAddress);

    modifier onlyAllowGov() {
        require(msg.sender == govAddress, "!gov");
        _;
    }

    function setGov(address _govAddress) public virtual onlyAllowGov {
        govAddress = _govAddress;
        emit SetGov(_govAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StratX2.sol";

interface IBakeryswapFarm {
    function deposit(address _pair, uint256 _amount) external;

    function withdraw(address _pair, uint256 _amount) external;
}

contract StratX2_BAKE is StratX2 {
    constructor(
        address[] memory _addresses,
        uint256 _pid,
        bool _isCAKEStaking,
        bool _isSameAssetDeposit,
        bool _isAutoComp,
        address[] memory _earnedToAUTOPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        uint256 _controllerFee,
        uint256 _buyBackRate,
        uint256 _entranceFeeFactor,
        uint256 _withdrawFeeFactor
    ) public {
        wbnbAddress = _addresses[0];
        govAddress = _addresses[1];
        autoFarmAddress = _addresses[2];
        AUTOAddress = _addresses[3];

        wantAddress = _addresses[4];
        token0Address = _addresses[5];
        token1Address = _addresses[6];
        earnedAddress = _addresses[7];

        farmContractAddress = _addresses[8];
        pid = _pid;
        isCAKEStaking = _isCAKEStaking;
        isSameAssetDeposit = _isSameAssetDeposit;
        isAutoComp = _isAutoComp;

        uniRouterAddress = _addresses[9];
        earnedToAUTOPath = _earnedToAUTOPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;

        controllerFee = _controllerFee;
        rewardsAddress = _addresses[10];
        buyBackRate = _buyBackRate;
        entranceFeeFactor = _entranceFeeFactor;
        withdrawFeeFactor = _withdrawFeeFactor;

        transferOwnership(autoFarmAddress);
    }

    function _farm() internal override {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        wantLockedTotal = wantLockedTotal.add(wantAmt);
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);

        IBakeryswapFarm(farmContractAddress).deposit(wantAddress, wantAmt);
    }

    function _unfarm(uint256 _wantAmt) internal override {
        IBakeryswapFarm(farmContractAddress).withdraw(wantAddress, _wantAmt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IPacocaFarm.sol";

contract PacocaVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
        uint256 pacocaAtLastUserAction; // keeps track of pacoca deposited at the last user action
        uint256 lastUserActionTime; // keeps track of the last user action time
    }

    IERC20 public immutable token; // Pacoca token
    IPacocaFarm public immutable masterchef;

    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    uint256 public lastHarvestedTime;
    address public treasury;

    uint256 public withdrawFee;
    uint256 public withdrawFeePeriod = 72 hours; // 3 days
    uint256 public constant MAX_WITHDRAW_FEE = 200; // 2%

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender);
    event SetTreasury(address treasury);
    event SetWithdrawFee(uint256 withdrawFee);

    /**
     * @notice Constructor
     * @param _token: Pacoca token contract
     * @param _masterchef: MasterChef contract
     * @param _owner: address of the owner
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _token,
        IPacocaFarm _masterchef,
        address _owner,
        address _treasury,
        uint256 _withdrawFee
    ) public {
        token = _token;
        masterchef = _masterchef;
        treasury = _treasury;
        withdrawFee = _withdrawFee;

        transferOwnership(_owner);
    }

    /**
     * @notice Deposits funds into the Pacoca Vault
     * @param _amount: number of tokens to deposit (in PACOCA)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "PacocaVault: Nothing to deposit");

        uint256 pool = underlyingTokenBalance();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;
        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }
        UserInfo storage user = userInfo[msg.sender];

        user.shares = user.shares.add(currentShares);
        user.lastDepositedTime = block.timestamp;

        totalShares = totalShares.add(currentShares);

        user.pacocaAtLastUserAction = user.shares.mul(underlyingTokenBalance()).div(totalShares);
        user.lastUserActionTime = block.timestamp;

        _earn();

        emit Deposit(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Reinvests PACOCA tokens into MasterChef
     */
    function harvest() external {
        masterchef.withdraw(0, 0);

        _earn();

        emit Harvest(msg.sender);
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "PacocaVault: Cannot be zero address");

        treasury = _treasury;

        emit SetTreasury(treasury);
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(
            _withdrawFee <= MAX_WITHDRAW_FEE,
            "PacocaVault: withdrawFee cannot be more than MAX_WITHDRAW_FEE"
        );

        withdrawFee = _withdrawFee;

        emit SetWithdrawFee(withdrawFee);
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending Pacoca rewards
     */
    function calculateTotalPendingPacocaRewards() external view returns (uint256) {
        uint256 amount = masterchef.pendingPACOCA(0, address(this));
        amount = amount.add(available());

        return amount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : underlyingTokenBalance().mul(1e18).div(totalShares);
    }

    /**
     * @notice Withdraws from funds from the Pacoca Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(
            _shares > 0,
            "PacocaVault: Nothing to withdraw"
        );
        require(
            _shares <= user.shares,
            "PacocaVault: Withdraw amount exceeds balance"
        );

        uint256 currentAmount = (underlyingTokenBalance().mul(_shares)).div(totalShares);
        user.shares = user.shares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            masterchef.withdraw(0, balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }

        if (
            withdrawFee > 0 &&
            block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)
        ) {
            uint256 currentWithdrawFee = currentAmount.mul(withdrawFee).div(10000);
            token.safeTransfer(treasury, currentWithdrawFee);
            currentAmount = currentAmount.sub(currentWithdrawFee);
        }

        if (user.shares > 0) {
            user.pacocaAtLastUserAction = user.shares.mul(underlyingTokenBalance()).div(totalShares);
        } else {
            user.pacocaAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function underlyingTokenBalance() public view returns (uint256) {
        (uint256 amount,) = masterchef.userInfo(0, address(this));

        return token.balanceOf(address(this)).add(amount);
    }

    /**
     * @notice Deposits tokens into MasterChef to earn staking rewards
     */
    function _earn() internal {
        uint256 balance = available();

        if (balance > 0) {
            if (token.allowance(address(this), address(masterchef)) < balance) {
                token.safeApprove(address(masterchef), uint(- 1));
            }

            masterchef.deposit(0, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IPacocaFarm {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256 shares, uint256 rewardDebt);

    function pendingPACOCA(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IPacocaFarm.sol";

contract AutoPacoca is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable token; // Pacoca token

    IPacocaFarm public immutable masterchef;

    mapping(address => uint256) public sharesOf;

    uint256 public totalShares;

    event Deposit(address indexed sender, uint256 amount, uint256 shares);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);
    event Harvest(address indexed sender);

    /**
     * @notice Constructor
     * @param _token: Pacoca token contract
     * @param _masterchef: MasterChef contract
     * @param _owner: address of the owner
     */
    constructor(
        IERC20 _token,
        IPacocaFarm _masterchef,
        address _owner
    ) public {
        token = _token;
        masterchef = _masterchef;

        transferOwnership(_owner);
    }

    /**
     * @notice Reinvests PACOCA tokens into MasterChef
     */
    function harvest() external {
        masterchef.withdraw(0, 0);

        _earn();

        emit Harvest(msg.sender);
    }

    /**
     * @notice Deposits funds into the Pacoca Vault
     * @param _amount: number of tokens to deposit (in PACOCA)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Nothing to deposit");

        uint256 pool = underlyingTokenBalance();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 currentShares = 0;

        if (totalShares != 0) {
            currentShares = (_amount.mul(totalShares)).div(pool);
        } else {
            currentShares = _amount;
        }

        sharesOf[msg.sender] = sharesOf[msg.sender].add(currentShares);

        totalShares = totalShares.add(currentShares);

        _earn();

        emit Deposit(msg.sender, _amount, currentShares);
    }

    /**
     * @notice Withdraws from funds from the Pacoca Vault
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public nonReentrant {
        uint256 userShares = sharesOf[msg.sender];

        require(_shares > 0, "AutoPacoca: Nothing to withdraw");
        require(_shares <= userShares, "AutoPacoca: Withdraw amount exceeds balance");

        uint256 currentAmount = (underlyingTokenBalance().mul(_shares)).div(totalShares);
        sharesOf[msg.sender] = userShares.sub(_shares);
        totalShares = totalShares.sub(_shares);

        uint256 bal = available();
        if (bal < currentAmount) {
            uint256 balWithdraw = currentAmount.sub(bal);
            masterchef.withdraw(0, balWithdraw);
            uint256 balAfter = available();
            uint256 diff = balAfter.sub(bal);
            if (diff < balWithdraw) {
                currentAmount = bal.add(diff);
            }
        }

        token.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount, _shares);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external {
        withdraw(sharesOf[msg.sender]);
    }

    /**
     * @notice Calculates the total pending rewards that can be restaked
     * @return Returns total pending Pacoca rewards
     */
    function calculateTotalPendingPacocaRewards() external view returns (uint256) {
        uint256 amount = masterchef.pendingPACOCA(0, address(this));
        amount = amount.add(available());

        return amount;
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() public view returns (uint256) {
        return totalShares == 0 ? 1e18 : underlyingTokenBalance().mul(1e18).div(totalShares);
    }

    /**
     * @notice Custom logic for how much the vault allows to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in MasterChef
     */
    function underlyingTokenBalance() public view returns (uint256) {
        (uint256 amount,) = masterchef.userInfo(0, address(this));

        return token.balanceOf(address(this)).add(amount);
    }

    /**
     * @notice Deposits tokens into MasterChef to earn staking rewards
     */
    function _earn() internal {
        uint256 balance = available();

        if (balance > 0) {
            if (token.allowance(address(this), address(masterchef)) < balance) {
                token.safeApprove(address(masterchef), uint(- 1));
            }

            masterchef.deposit(0, balance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./BnbStorage.sol";

contract BnbVault is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct UserInfo {
        // How many assets the user has provided.
        uint stake;
        // Bnb not entitled to the user
        uint rewardDebt;
        // Timestamp of last user deposit
        uint lastDepositedTime;
    }

    IERC20 public immutable PACOCA;
    IERC20 public immutable WBNB;
    BnbStorage public immutable BNB_STORAGE;
    address public treasury;

    mapping(address => UserInfo) public userInfo; // Info of users
    uint public accBnbPerStakedToken; // Accumulated BNB per staked token, times 1e18.

    uint public earlyWithdrawFee = 100; // 1%
    uint public constant earlyWithdrawFeeUL = 300; // 3%
    uint public constant withdrawFeePeriod = 3 days;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event EarlyWithdraw(address indexed user, uint amount, uint fee);
    event Collected(uint amount, uint timestamp);

    event SetTreasury(address oldTreasury, address newTreasury);
    event SetEarlyWithdrawFee(uint oldEarlyWithdrawFee, uint newEarlyWithdrawFee);

    constructor (address _pacoca, address _wbnb, address _bnbStorage, address _treasury) public {
        PACOCA = IERC20(_pacoca);
        WBNB = IERC20(_wbnb);
        BNB_STORAGE = BnbStorage(_bnbStorage);
        treasury = _treasury;
    }

    function deposit(uint _amount) external nonReentrant {
        _collect();

        UserInfo storage user = userInfo[msg.sender];

        // Claim pending rewards
        if (user.stake > 0) {
            uint pending = user.stake.mul(accBnbPerStakedToken).div(1e18).sub(
                user.rewardDebt
            );

            if (pending > 0) {
                WBNB.safeTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            PACOCA.safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );

            user.stake = user.stake.add(_amount);
            user.lastDepositedTime = block.timestamp;
        }

        user.rewardDebt = user.stake.mul(accBnbPerStakedToken).div(1e18);

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint _amount) public nonReentrant {
        _collect();

        UserInfo storage user = userInfo[msg.sender];

        require(user.stake > 0, "BnbVault::withdraw: User has no stake");

        // Claim pending rewards
        uint pending = user.stake.mul(accBnbPerStakedToken).div(1e18).sub(
            user.rewardDebt
        );

        if (pending > 0) {
            WBNB.safeTransfer(msg.sender, pending);
        }

        // Withdraw staked tokens
        uint amount = _amount > user.stake ? user.stake : _amount;

        if (amount > 0) {
            user.stake = user.stake.sub(amount);

            if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
                uint currentWithdrawFee = amount.mul(earlyWithdrawFee).div(10000);

                PACOCA.safeTransfer(treasury, currentWithdrawFee);

                amount = amount.sub(currentWithdrawFee);

                emit EarlyWithdraw(msg.sender, amount, currentWithdrawFee);
            }

            PACOCA.safeTransfer(msg.sender, amount);
        }

        user.rewardDebt = user.stake.mul(accBnbPerStakedToken).div(1e18);

        emit Withdraw(msg.sender, amount);
    }

    function pendingRewards(address _user) external view returns (uint) {
        UserInfo storage user = userInfo[_user];

        uint pending = BNB_STORAGE.balance().mul(user.stake).div(pacocaBalance());

        return user.stake.mul(accBnbPerStakedToken).div(1e18).sub(
            user.rewardDebt
        ).add(pending);
    }

    function _collect() private {
        if (BNB_STORAGE.balance() == 0) {
            return;
        }

        uint initialBalance = bnbBalance();

        BNB_STORAGE.collect();

        uint amountCollected = bnbBalance().sub(initialBalance);

        accBnbPerStakedToken = accBnbPerStakedToken.add(
            amountCollected.mul(1e18).div(pacocaBalance())
        );

        emit Collected(amountCollected, block.timestamp);
    }

    function bnbBalance() public view returns (uint) {
        return WBNB.balanceOf(address(this));
    }

    function pacocaBalance() public view returns (uint) {
        return PACOCA.balanceOf(address(this));
    }

    function setTreasury(address _treasury) external onlyOwner {
        address oldTreasury = treasury;

        treasury = _treasury;

        emit SetTreasury(oldTreasury, treasury);
    }

    function setEarlyWithdrawFee(uint _earlyWithdrawFee) external onlyOwner {
        require(
            _earlyWithdrawFee <= earlyWithdrawFeeUL,
            "BnbVault::setEarlyWithdrawFee: Early withdraw fee too high"
        );

        uint oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BnbStorage {
    using SafeERC20 for IERC20;

    IERC20 public immutable WBNB;
    address public immutable VAULT;

    constructor (address _wbnb, address _vault) public {
        WBNB = IERC20(_wbnb);
        VAULT = _vault;
    }

    function collect() external {
        require(
            msg.sender == VAULT,
            "BnbStorage::collect: Only bnb vault is allowed to claim"
        );

        WBNB.safeTransfer(VAULT, balance());
    }

    function balance() public view returns (uint) {
        return WBNB.balanceOf(address(this));
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SweetVault.sol";

contract SweetVault_Honey is SweetVault {
    constructor(
        address _autoPacoca,
        address _stakedToken,
        address _stakedTokenFarm,
        address _farmRewardToken,
        uint256 _farmPid,
        bool _isCakeStaking,
        address _router,
        address[] memory _pathToPacoca,
        address[] memory _pathToWbnb,
        address _owner,
        address _treasury,
        address _keeper,
        address _platform,
        uint256 _buyBackRate,
        uint256 _platformFee
    ) SweetVault(
        _autoPacoca,
        _stakedToken,
        _stakedTokenFarm,
        _farmRewardToken,
        _farmPid,
        _isCakeStaking,
        _router,
        _pathToPacoca,
        _pathToWbnb,
        _owner,
        _treasury,
        _keeper,
        _platform,
        _buyBackRate,
        _platformFee
    ) public {}

    function deposit(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "SweetVault: amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        uint256 initialBalance = _stakedTokenBalance();
        uint256 initialStake = totalStake();

        STAKED_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        uint256 amountReceived = _stakedTokenBalance().sub(initialBalance);

        _approveTokenIfNeeded(
            STAKED_TOKEN,
            amountReceived,
            address(STAKED_TOKEN_FARM)
        );

        STAKED_TOKEN_FARM.deposit(FARM_PID, amountReceived, treasury);

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.add(totalStake().sub(initialStake));
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "SweetVault: amount must be greater than zero");
        require(user.stake >= _amount, "SweetVault: withdraw amount exceeds balance");

        uint256 initialBalance = _stakedTokenBalance();

        STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount);

        uint256 currentAmount = _stakedTokenBalance().sub(initialBalance);

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(earlyWithdrawFee).div(10000);

            STAKED_TOKEN.safeTransfer(treasury, currentWithdrawFee);

            currentAmount = currentAmount.sub(currentWithdrawFee);

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        user.autoPacocaShares = user.autoPacocaShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.sub(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);

        // Withdraw pacoca rewards if user leaves
        if (user.stake == 0 && user.autoPacocaShares > 0) {
            _claimRewards(user.autoPacocaShares, false);
        }

        STAKED_TOKEN.safeTransfer(msg.sender, currentAmount);

        emit Withdraw(msg.sender, currentAmount);
    }

    function _getExpectedOutput(
        address[] memory _path
    ) internal view override returns (uint256) {
        uint256 pending = STAKED_TOKEN_FARM.pendingEarnings(FARM_PID, address(this));

        uint256 rewards = _rewardTokenBalance().add(pending);

        uint256[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length.sub(1)];
    }

    function _stakedTokenBalance() private view returns (uint256) {
        return STAKED_TOKEN.balanceOf(address(this));
    }

    function _swap(
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        address[] memory _path,
        address _to
    ) internal override {
        _approveTokenIfNeeded(
            FARM_REWARD_TOKEN,
            _inputAmount,
            address(router)
        );

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface ILegacyVault {
    function earn() external;
}

interface ISweetVault {
    function earn(uint, uint, uint, uint) external;

    function getExpectedOutputs() external view returns (uint, uint, uint, uint);

    function totalStake() external view returns (uint);
}
//
//interface KeeperCompatibleInterface {
//    function checkUpkeep(
//        bytes calldata checkData
//    ) external view returns (
//        bool upkeepNeeded,
//        bytes memory performData
//    );
//
//    function performUpkeep(
//        bytes calldata performData
//    ) external;
//}

//contract SweetKeeper is Ownable, KeeperCompatibleInterface {
contract SweetKeeper is Ownable {
    using SafeMath for uint;

    struct VaultInfo {
        uint lastCompound;
        bool enabled;
    }

    struct CompoundInfo {
        address[] legacyVaults;
        address[] sweetVaults;
        uint[] minPlatformOutputs;
        uint[] minKeeperOutputs;
        uint[] minBurnOutputs;
        uint[] minPacocaOutputs;
    }

    address[] public legacyVaults;
    address[] public sweetVaults;

    mapping(address => VaultInfo) public vaultInfos;

    address public keeper;
    address public moderator;

    uint public maxDelay = 1 days;
    uint public minKeeperFee = 5500000000000000;
    uint public slippageFactor = 9600; // 4%
    uint16 public maxVaults = 4;

    constructor(
        address _keeper,
        address _moderator,
        address _owner
    ) public {
        keeper = _keeper;
        moderator = _moderator;

        transferOwnership(_owner);
    }
//
//    modifier onlyKeeper() {
//        require(msg.sender == keeper, "SweetKeeper::onlyKeeper: Not keeper");
//        _;
//    }
//
//    modifier onlyModerator() {
//        require(msg.sender == moderator, "SweetKeeper::onlyModerator: Not moderator");
//        _;
//    }
//
//    function checkUpkeep(
//        bytes calldata
//    ) external override view returns (
//        bool upkeepNeeded,
//        bytes memory performData
//    ) {
//        CompoundInfo memory tempCompoundInfo = CompoundInfo(
//            new address[](legacyVaults.length),
//            new address[](sweetVaults.length),
//            new uint[](sweetVaults.length),
//            new uint[](sweetVaults.length),
//            new uint[](sweetVaults.length),
//            new uint[](sweetVaults.length)
//        );
//
//        uint16 legacyVaultsLength = 0;
//        uint16 sweetVaultsLength = 0;
//
//        for (uint16 index = 0; index < sweetVaults.length; ++index) {
//            if (maxVaults == sweetVaultsLength) {
//                continue;
//            }
//
//            address vault = sweetVaults[index];
//            VaultInfo memory vaultInfo = vaultInfos[vault];
//
//            if (!vaultInfo.enabled || ISweetVault(vault).totalStake() == 0) {
//                continue;
//            }
//
//            (uint platformOutput, uint keeperOutput, uint burnOutput, uint pacocaOutput) = _getExpectedOutputs(vault);
//
//            if (
//                block.timestamp >= vaultInfo.lastCompound + maxDelay
//                || keeperOutput >= minKeeperFee
//            ) {
//                tempCompoundInfo.sweetVaults[sweetVaultsLength] = vault;
//
//                tempCompoundInfo.minPlatformOutputs[sweetVaultsLength] = platformOutput.mul(slippageFactor).div(10000);
//                tempCompoundInfo.minKeeperOutputs[sweetVaultsLength] = keeperOutput.mul(slippageFactor).div(10000);
//                tempCompoundInfo.minBurnOutputs[sweetVaultsLength] = burnOutput.mul(slippageFactor).div(10000);
//                tempCompoundInfo.minPacocaOutputs[sweetVaultsLength] = pacocaOutput.mul(slippageFactor).div(10000);
//
//                sweetVaultsLength = sweetVaultsLength + 1;
//            }
//        }
//
//        for (uint16 index = 0; index < legacyVaults.length; ++index) {
//            if (maxVaults == (sweetVaultsLength + legacyVaultsLength)) {
//                continue;
//            }
//
//            address vault = legacyVaults[index];
//            VaultInfo memory vaultInfo = vaultInfos[vault];
//
//            if (!vaultInfo.enabled) {
//                continue;
//            }
//
//            if (block.timestamp >= vaultInfo.lastCompound + maxDelay) {
//                tempCompoundInfo.legacyVaults[legacyVaultsLength] = vault;
//
//                legacyVaultsLength = legacyVaultsLength + 1;
//            }
//        }
//
//        if (legacyVaultsLength > 0 || sweetVaultsLength > 0) {
//            CompoundInfo memory compoundInfo = CompoundInfo(
//                new address[](legacyVaultsLength),
//                new address[](sweetVaultsLength),
//                new uint[](sweetVaultsLength),
//                new uint[](sweetVaultsLength),
//                new uint[](sweetVaultsLength),
//                new uint[](sweetVaultsLength)
//            );
//
//            for (uint16 index = 0; index < legacyVaultsLength; ++index) {
//                compoundInfo.legacyVaults[index] = tempCompoundInfo.legacyVaults[index];
//            }
//
//            for (uint16 index = 0; index < sweetVaultsLength; ++index) {
//                compoundInfo.sweetVaults[index] = tempCompoundInfo.sweetVaults[index];
//                compoundInfo.minPlatformOutputs[index] = tempCompoundInfo.minPlatformOutputs[index];
//                compoundInfo.minKeeperOutputs[index] = tempCompoundInfo.minKeeperOutputs[index];
//                compoundInfo.minBurnOutputs[index] = tempCompoundInfo.minBurnOutputs[index];
//                compoundInfo.minPacocaOutputs[index] = tempCompoundInfo.minPacocaOutputs[index];
//            }
//
//            return (true, abi.encode(
//                compoundInfo.legacyVaults,
//                compoundInfo.sweetVaults,
//                compoundInfo.minPlatformOutputs,
//                compoundInfo.minKeeperOutputs,
//                compoundInfo.minBurnOutputs,
//                compoundInfo.minPacocaOutputs
//            ));
//        }
//
//        return (false, "");
//    }
//
//    function performUpkeep(
//        bytes calldata performData
//    ) external override onlyKeeper {
//        (
//        address[] memory _legacyVaults,
//        address[] memory _sweetVaults,
//        uint[] memory _minPlatformOutputs,
//        uint[] memory _minKeeperOutputs,
//        uint[] memory _minBurnOutputs,
//        uint[] memory _minPacocaOutputs
//        ) = abi.decode(
//            performData,
//            (address[], address[], uint[], uint[], uint[], uint[])
//        );
//
//        _earn(
//            _legacyVaults,
//            _sweetVaults,
//            _minPlatformOutputs,
//            _minKeeperOutputs,
//            _minBurnOutputs,
//            _minPacocaOutputs
//        );
//    }
//
//    function _earn(
//        address[] memory _legacyVaults,
//        address[] memory _sweetVaults,
//        uint[] memory _minPlatformOutputs,
//        uint[] memory _minKeeperOutputs,
//        uint[] memory _minBurnOutputs,
//        uint[] memory _minPacocaOutputs
//    ) private {
//        uint legacyLength = _legacyVaults.length;
//
//        for (uint index = 0; index < legacyLength; ++index) {
//            address vault = _legacyVaults[index];
//
//            ILegacyVault(vault).earn();
//
//            vaultInfos[vault].lastCompound = block.timestamp;
//        }
//
//        uint sweetLength = _sweetVaults.length;
//
//        for (uint index = 0; index < sweetLength; ++index) {
//            address vault = _sweetVaults[index];
//
//            ISweetVault(vault).earn(
//                _minPlatformOutputs[index],
//                _minKeeperOutputs[index],
//                _minBurnOutputs[index],
//                _minPacocaOutputs[index]
//            );
//
//            vaultInfos[vault].lastCompound = block.timestamp;
//        }
//    }
//
//    function _getExpectedOutputs(
//        address _vault
//    ) private view returns (
//        uint, uint, uint, uint
//    ) {
//        try ISweetVault(_vault).getExpectedOutputs() returns (
//            uint platformOutput,
//            uint keeperOutput,
//            uint burnOutput,
//            uint pacocaOutput
//        ) {
//            return (platformOutput, keeperOutput, burnOutput, pacocaOutput);
//        }
//        catch (bytes memory) {
//        }
//
//        return (0, 0, 0, 0);
//    }
//
//    function legacyVaultsLength() external view returns (uint) {
//        return legacyVaults.length;
//    }
//
//    function sweetVaultsLength() external view returns (uint) {
//        return sweetVaults.length;
//    }
//
//    function addVault(address _vault, bool _legacy) public onlyModerator {
//        require(
//            vaultInfos[_vault].lastCompound == 0,
//            "SweetKeeper::addVault: Vault already exists"
//        );
//
//        vaultInfos[_vault] = VaultInfo(
//            block.timestamp - 6 hours,
//            true
//        );
//
//        if (_legacy) {
//            legacyVaults.push(_vault);
//        }
//        else {
//            sweetVaults.push(_vault);
//        }
//    }
//
//    function enableVault(address _vault) external onlyModerator {
//        vaultInfos[_vault].enabled = true;
//    }
//
//    function disableVault(address _vault) external onlyModerator {
//        vaultInfos[_vault].enabled = false;
//    }
//
//    function setKeeper(address _keeper) public onlyOwner {
//        keeper = _keeper;
//    }
//
//    function setModerator(address _moderator) public onlyOwner {
//        moderator = _moderator;
//    }
//
//    function setMaxDelay(uint _maxDelay) public onlyOwner {
//        maxDelay = _maxDelay;
//    }
//
//    function setMinKeeperFee(uint _minKeeperFee) public onlyOwner {
//        minKeeperFee = _minKeeperFee;
//    }
//
//    function setSlippageFactor(uint _slippageFactor) public onlyOwner {
//        slippageFactor = _slippageFactor;
//    }
//
//    function setMaxVaults(uint16 _maxVaults) public onlyOwner {
//        maxVaults = _maxVaults;
//    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenIndexer is Ownable {
    address[] public tokens;

    function addTokens(address[] calldata _tokens) external {
        for (uint index = 0; index < _tokens.length; ++index) {
            tokens.push(_tokens[index]);
        }
    }
}

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    function earn() external;
}

interface ISweetVault {
    function earn(uint256, uint256, uint256, uint256) external;
}

contract Earn is Ownable {

    constructor(address _owner) public {
        transferOwnership(_owner);
    }

    function earn(
        address[] calldata _legacyVaults,
        address[] calldata _sweetVaults,
        uint256[] calldata _minPlatformOutputs,
        uint256[] calldata _minKeeperOutputs,
        uint256[] calldata _minBurnOutputs,
        uint256[] calldata _minPacocaOutputs
    ) public onlyOwner {
        uint256 legacyLength = _legacyVaults.length;

        for (uint256 index = 0; index < legacyLength; ++index) {
            IVault(_legacyVaults[index]).earn();
        }

        uint256 sweetLength = _sweetVaults.length;

        for (uint256 index = 0; index < sweetLength; ++index) {
            ISweetVault(_sweetVaults[index]).earn(
                _minPlatformOutputs[index],
                _minKeeperOutputs[index],
                _minBurnOutputs[index],
                _minPacocaOutputs[index]
            );
        }
    }

}