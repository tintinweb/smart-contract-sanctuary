// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { IERC20WithCheckpointing } from "./aragonone/IERC20WithCheckpointing.sol";
import { Checkpointing } from "./aragonone/Checkpointing.sol";
import { CheckpointingHelpers } from "./aragonone/CheckpointingHelpers.sol";
import { ERC20ViewOnly } from "../utils/ERC20ViewOnly.sol";
import { Decimal } from "../utils/Decimal.sol";
import { DecimalERC20 } from "../utils/DecimalERC20.sol";
import { BlockContext } from "../utils/BlockContext.sol";
import { PerpFiOwnableUpgrade } from "../utils/PerpFiOwnableUpgrade.sol";
import { AddressArray } from "../utils/AddressArray.sol";
import { IStakeModule } from "../interface/IStakeModule.sol";

contract StakedPerpToken is IERC20WithCheckpointing, ERC20ViewOnly, DecimalERC20, PerpFiOwnableUpgrade, BlockContext {
    using Checkpointing for Checkpointing.History;
    using CheckpointingHelpers for uint256;
    using SafeMath for uint256;
    using AddressArray for address[];

    uint256 public constant TOKEN_AMOUNT_LIMIT = 20;

    //
    // EVENTS
    //
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event Withdrawn(address staker, uint256 amount);
    event StakeModuleAdded(address stakedModule);
    event StakeModuleRemoved(address stakedModule);

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // ERC20 variables
    string public name;
    string public symbol;
    uint8 public decimals;
    // ERC20 variables

    // Checkpointing total supply of the deposited token
    Checkpointing.History internal totalSupplyHistory;

    // Checkpointing balances of the deposited token by staker
    mapping(address => Checkpointing.History) internal balancesHistory;

    // staker => the time staker can withdraw PERP
    mapping(address => uint256) public stakerCooldown;

    // staker => PERP staker can withdraw
    mapping(address => Decimal.decimal) public stakerWithdrawPendingBalance;

    address[] public stakeModules;
    IERC20 public perpToken;
    uint256 public cooldownPeriod;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    function initialize(IERC20 _perpToken, uint256 _cooldownPeriod) external initializer {
        require(address(_perpToken) != address(0), "Invalid input.");
        __Ownable_init();
        name = "Staked Perpetual";
        symbol = "sPERP";
        decimals = 18;
        perpToken = _perpToken;
        cooldownPeriod = _cooldownPeriod;
    }

    function stake(Decimal.decimal calldata _amount) external {
        requireNonZeroAmount(_amount);
        requireStakeModuleExisted();
        address msgSender = _msgSender();

        // copy calldata amount to memory
        Decimal.decimal memory amount = _amount;

        // stake after unstake is allowed, and the states mutated by unstake() will being undo
        if (stakerWithdrawPendingBalance[msgSender].toUint() != 0) {
            amount = amount.addD(stakerWithdrawPendingBalance[msgSender]);
            delete stakerWithdrawPendingBalance[msgSender];
            delete stakerCooldown[msgSender];
        }

        // if staking after unstaking, the amount to be transferred does not need to be updated
        _transferFrom(perpToken, msgSender, address(this), _amount);
        _mint(msgSender, amount);

        // Have to update balance first
        for (uint256 i; i < stakeModules.length; i++) {
            IStakeModule(stakeModules[i]).notifyStakeChanged(msgSender);
        }

        emit Staked(msgSender, amount.toUint());
    }

    // this function mutates stakerWithdrawPendingBalance, stakerCooldown, addTotalSupplyCheckPoint,
    // addPersonalBalanceCheckPoint, burn
    function unstake() external {
        address msgSender = _msgSender();
        requireStakeModuleExisted();
        require(stakerWithdrawPendingBalance[msgSender].toUint() == 0, "Need to withdraw first");

        Decimal.decimal memory balance = Decimal.decimal(balancesHistory[msgSender].latestValue());
        requireNonZeroAmount(balance);

        _burn(msgSender, balance);

        stakerCooldown[msgSender] = _blockTimestamp().add(cooldownPeriod);
        stakerWithdrawPendingBalance[msgSender] = balance;

        // Have to update balance first
        for (uint256 i; i < stakeModules.length; i++) {
            IStakeModule(stakeModules[i]).notifyStakeChanged(msgSender);
        }

        emit Unstaked(msgSender, balance.toUint());
    }

    function withdraw() external {
        address msgSender = _msgSender();
        Decimal.decimal memory balance = stakerWithdrawPendingBalance[msgSender];
        requireNonZeroAmount(balance);
        // there won't be a case that cooldown == 0 && balance == 0
        require(_blockTimestamp() >= stakerCooldown[msgSender], "Still in cooldown");

        delete stakerWithdrawPendingBalance[msgSender];
        delete stakerCooldown[msgSender];
        _transfer(perpToken, msgSender, balance);

        emit Withdrawn(msgSender, balance.toUint());
    }

    function addStakeModule(IStakeModule _stakeModule) external onlyOwner {
        require(stakeModules.length < TOKEN_AMOUNT_LIMIT, "exceed stakeModule amount limit");
        require(stakeModules.add(address(_stakeModule)), "invalid input");

        emit StakeModuleAdded(address(_stakeModule));
    }

    function removeStakeModule(IStakeModule _stakeModule) external onlyOwner {
        address removedAddr = stakeModules.remove(address(_stakeModule));
        require(removedAddr != address(0), "stakeModule does not exist");
        require(removedAddr == address(_stakeModule), "remove wrong stakeModule");

        emit StakeModuleRemoved(address(_stakeModule));
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner {
        require(_cooldownPeriod != 0, "invalid input");
        cooldownPeriod = _cooldownPeriod;
    }

    //
    // VIEW FUNCTIONS
    //

    //
    // override: ERC20
    //
    function balanceOf(address _owner) public view override returns (uint256) {
        return _balanceOfAt(_owner, _blockNumber()).toUint();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupplyAt(_blockNumber()).toUint();
    }

    //
    // override: IERC20WithCheckpointing
    //
    function balanceOfAt(address _owner, uint256 __blockNumber) external view override returns (uint256) {
        return _balanceOfAt(_owner, __blockNumber).toUint();
    }

    function totalSupplyAt(uint256 __blockNumber) external view override returns (uint256) {
        return _totalSupplyAt(__blockNumber).toUint();
    }

    //
    // EXTERNAL FUNCTIONS
    //
    function getStakeModuleLength() external view returns (uint256) {
        return stakeModules.length;
    }

    //
    // INTERNAL FUNCTIONS
    //
    function isStakeModuleExisted(IStakeModule _stakeModule) public view returns (bool) {
        return stakeModules.isExisted(address(_stakeModule));
    }

    function _mint(address account, Decimal.decimal memory amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        Decimal.decimal memory balance = Decimal.decimal(balanceOf(account));
        Decimal.decimal memory newBalance = balance.addD(amount);
        Decimal.decimal memory currentTotalSupply = Decimal.decimal(totalSupply());
        Decimal.decimal memory newTotalSupply = currentTotalSupply.addD(amount);

        uint256 blockNumber = _blockNumber();
        addPersonalBalanceCheckPoint(account, blockNumber, newBalance);
        addTotalSupplyCheckPoint(blockNumber, newTotalSupply);

        emit Transfer(address(0), account, amount.toUint());
    }

    function _burn(address account, Decimal.decimal memory amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        Decimal.decimal memory balance = Decimal.decimal(balanceOf(account));
        Decimal.decimal memory newBalance = balance.subD(amount);
        Decimal.decimal memory currentTotalSupply = Decimal.decimal(totalSupply());
        Decimal.decimal memory newTotalSupply = currentTotalSupply.subD(amount);

        uint256 blockNumber = _blockNumber();
        addPersonalBalanceCheckPoint(account, blockNumber, newBalance);
        addTotalSupplyCheckPoint(blockNumber, newTotalSupply);

        emit Transfer(account, address(0), amount.toUint());
    }

    function addTotalSupplyCheckPoint(uint256 __blockNumber, Decimal.decimal memory _amount) internal {
        totalSupplyHistory.addCheckpoint(__blockNumber.toUint64Time(), _amount.toUint().toUint192Value());
    }

    function addPersonalBalanceCheckPoint(
        address _staker,
        uint256 __blockNumber,
        Decimal.decimal memory _amount
    ) internal {
        balancesHistory[_staker].addCheckpoint(__blockNumber.toUint64Time(), _amount.toUint().toUint192Value());
    }

    function _balanceOfAt(address _owner, uint256 __blockNumber) internal view returns (Decimal.decimal memory) {
        return Decimal.decimal(balancesHistory[_owner].getValueAt(__blockNumber.toUint64Time()));
    }

    function _totalSupplyAt(uint256 __blockNumber) internal view returns (Decimal.decimal memory) {
        return Decimal.decimal(totalSupplyHistory.getValueAt(__blockNumber.toUint64Time()));
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireNonZeroAmount(Decimal.decimal memory _amount) private pure {
        require(_amount.toUint() > 0, "Amount is 0");
    }

    function requireStakeModuleExisted() internal view {
        require(stakeModules.length > 0, "no stakeModule");
    }
}

// source: https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/interfaces/IERC20WithCheckpointing.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.6.9;

interface IERC20WithCheckpointing {
    function balanceOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);

    function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
}

// source: https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/Checkpointing.sol

/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.6.9;

/**
 * @title Checkpointing
 * @notice Checkpointing library for keeping track of historical values based on an arbitrary time
 *         unit (e.g. seconds or block numbers).
 * @dev Inspired by:
 *   - MiniMe token (https://github.com/aragon/minime/blob/master/contracts/MiniMeToken.sol)
 *   - Staking (https://github.com/aragon/staking/blob/master/contracts/Checkpointing.sol)
 */
library Checkpointing {
    string private constant ERROR_PAST_CHECKPOINT = "CHECKPOINT_PAST_CHECKPOINT";

    struct Checkpoint {
        uint64 time;
        uint192 value;
    }

    struct History {
        Checkpoint[] history;
    }

    function addCheckpoint(
        History storage _self,
        uint64 _time,
        uint192 _value
    ) internal {
        uint256 length = _self.history.length;
        if (length == 0) {
            _self.history.push(Checkpoint(_time, _value));
        } else {
            Checkpoint storage currentCheckpoint = _self.history[length - 1];
            uint256 currentCheckpointTime = uint256(currentCheckpoint.time);

            if (_time > currentCheckpointTime) {
                _self.history.push(Checkpoint(_time, _value));
            } else if (_time == currentCheckpointTime) {
                currentCheckpoint.value = _value;
            } else {
                // ensure list ordering
                revert(ERROR_PAST_CHECKPOINT);
            }
        }
    }

    function getValueAt(History storage _self, uint64 _time) internal view returns (uint256) {
        return _getValueAt(_self, _time);
    }

    function lastUpdated(History storage _self) internal view returns (uint256) {
        uint256 length = _self.history.length;
        if (length > 0) {
            return uint256(_self.history[length - 1].time);
        }

        return 0;
    }

    function latestValue(History storage _self) internal view returns (uint256) {
        uint256 length = _self.history.length;
        if (length > 0) {
            return uint256(_self.history[length - 1].value);
        }

        return 0;
    }

    function _getValueAt(History storage _self, uint64 _time) private view returns (uint256) {
        uint256 length = _self.history.length;

        // Short circuit if there's no checkpoints yet
        // Note that this also lets us avoid using SafeMath later on, as we've established that
        // there must be at least one checkpoint
        if (length == 0) {
            return 0;
        }

        // Check last checkpoint
        uint256 lastIndex = length - 1;
        Checkpoint storage lastCheckpoint = _self.history[lastIndex];
        if (_time >= lastCheckpoint.time) {
            return uint256(lastCheckpoint.value);
        }

        // Check first checkpoint (if not already checked with the above check on last)
        if (length == 1 || _time < _self.history[0].time) {
            return 0;
        }

        // Do binary search
        // As we've already checked both ends, we don't need to check the last checkpoint again
        uint256 low = 0;
        uint256 high = lastIndex - 1;

        while (high > low) {
            uint256 mid = (high + low + 1) / 2; // average, ceil round
            Checkpoint storage checkpoint = _self.history[mid];
            uint64 midTime = checkpoint.time;

            if (_time > midTime) {
                low = mid;
            } else if (_time < midTime) {
                // Note that we don't need SafeMath here because mid must always be greater than 0
                // from the while condition
                high = mid - 1;
            } else {
                // _time == midTime
                return uint256(checkpoint.value);
            }
        }

        return uint256(_self.history[low].value);
    }
}

// source: https://github.com/aragonone/voting-connectors/blob/master/shared/contract-utils/contracts/CheckpointingHelpers.sol

pragma solidity 0.6.9;

library CheckpointingHelpers {
    uint256 private constant MAX_UINT64 = uint64(-1);
    uint256 private constant MAX_UINT192 = uint192(-1);

    string private constant ERROR_UINT64_TOO_BIG = "UINT64_NUMBER_TOO_BIG";
    string private constant ERROR_UINT192_TOO_BIG = "UINT192_NUMBER_TOO_BIG";

    function toUint64Time(uint256 _a) internal pure returns (uint64) {
        require(_a <= MAX_UINT64, ERROR_UINT64_TOO_BIG);
        return uint64(_a);
    }

    function toUint192Value(uint256 _a) internal pure returns (uint192) {
        require(_a <= MAX_UINT192, ERROR_UINT192_TOO_BIG);
        return uint192(_a);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20ViewOnly is IERC20 {
    function transfer(address, uint256) public virtual override returns (bool) {
        revert("transfer() is not supported");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override returns (bool) {
        revert("transferFrom() is not supported");
    }

    function approve(address, uint256) public virtual override returns (bool) {
        revert("approve() is not supported");
    }

    function allowance(address, address) public view virtual override returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;
    using SafeMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal(x.d.mul(DecimalMath.unit(18)) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.add(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.sub(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.mul(y);
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.div(y);
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
/// @author Alberto Cuesta Cañada
library DecimalMath {
    using SafeMath for uint256;

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.add(y);
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.sub(y);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(y).div(unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return x.mul(unit(decimals)).div(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { Decimal } from "./Decimal.sol";

abstract contract DecimalERC20 {
    using SafeMath for uint256;
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private decimalMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // INTERNAL functions
    //

    // CAUTION: do not input _from == _to s.t. this function will always fail
    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, roundedDownValue));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: transfer failed");
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, roundedDownValue));

        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: transferFrom failed");
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        // to be compatible with some erc20 tokens like USDT
        __approve(_token, _spender, Decimal.zero());
        __approve(_token, _spender, _value);
    }

    //
    // VIEW
    //
    function _allowance(
        IERC20 _token,
        address _owner,
        address _spender
    ) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.allowance(_owner, _spender));
    }

    function _balanceOf(IERC20 _token, address _owner) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.balanceOf(_owner));
    }

    function _totalSupply(IERC20 _token) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.totalSupply());
    }

    function _toDecimal(IERC20 _token, uint256 _number) internal view returns (Decimal.decimal memory) {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return Decimal.decimal(_number.div(10**(tokenDecimals.sub(18))));
        }

        return Decimal.decimal(_number.mul(10**(uint256(18).sub(tokenDecimals))));
    }

    function _toUint(IERC20 _token, Decimal.decimal memory _decimal) internal view returns (uint256) {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return _decimal.toUint().mul(10**(tokenDecimals.sub(18)));
        }
        return _decimal.toUint().div(10**(uint256(18).sub(tokenDecimals)));
    }

    function _getTokenDecimals(address _token) internal view returns (uint256) {
        uint256 tokenDecimals = decimalMap[_token];
        if (tokenDecimals == 0) {
            (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSignature("decimals()"));
            require(success && data.length != 0, "DecimalERC20: get decimals failed");
            tokenDecimals = abi.decode(data, (uint256));
        }
        return tokenDecimals;
    }

    //
    // PRIVATE
    //
    function _updateDecimal(address _token) private {
        uint256 tokenDecimals = _getTokenDecimals(_token);
        if (decimalMap[_token] != tokenDecimals) {
            decimalMap[_token] = tokenDecimals;
        }
    }

    function __approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) private {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) =
            address(_token).call(abi.encodeWithSelector(_token.approve.selector, _spender, _toUint(_token, _value)));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "DecimalERC20: approve failed");
    }

    // To prevent from deflationary token, check receiver's balance is as expectation.
    function _validateBalance(
        IERC20 _token,
        address _to,
        uint256 _roundedDownValue,
        Decimal.decimal memory _balanceBefore
    ) private view {
        require(
            _balanceOf(_token, _to).cmp(_balanceBefore.addD(_toDecimal(_token, _roundedDownValue))) == 0,
            "DecimalERC20: balance inconsistent"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

import { ContextUpgradeSafe } from "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

// copy from openzeppelin Ownable, only modify how the owner transfer
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
contract PerpFiOwnableUpgrade is ContextUpgradeSafe {
    address private _owner;
    address private _candidate;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function candidate() public view returns (address) {
        return _candidate;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "PerpFiOwnableUpgrade: caller is not the owner");
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
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "PerpFiOwnableUpgrade: zero address");
        require(newOwner != _owner, "PerpFiOwnableUpgrade: same as original");
        require(newOwner != _candidate, "PerpFiOwnableUpgrade: same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "PerpFiOwnableUpgrade: candidate is zero address");
        require(_candidate == _msgSender(), "PerpFiOwnableUpgrade: not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

library AddressArray {
    function add(address[] storage addrArray, address addr) internal returns (bool) {
        if (addr == address(0) || isExisted(addrArray, addr)) {
            return false;
        }
        addrArray.push(addr);
        return true;
    }

    function remove(address[] storage addrArray, address addr) internal returns (address) {
        if (addr == address(0)) {
            return address(0);
        }

        uint256 lengthOfArray = addrArray.length;
        for (uint256 i; i < lengthOfArray; i++) {
            if (addr == addrArray[i]) {
                if (i != lengthOfArray - 1) {
                    addrArray[i] = addrArray[lengthOfArray - 1];
                }
                addrArray.pop();
                return addr;
            }
        }
        return address(0);
    }

    function isExisted(address[] memory addrArray, address addr) internal pure returns (bool) {
        for (uint256 i; i < addrArray.length; i++) {
            if (addr == addrArray[i]) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;

interface IStakeModule {
    function notifyStakeChanged(address staker) external;
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
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
  }
}