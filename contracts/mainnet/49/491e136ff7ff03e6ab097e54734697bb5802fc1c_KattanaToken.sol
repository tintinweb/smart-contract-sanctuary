// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import './Math.sol';
import './SafeERC20.sol';
import './LiquidityTrap.sol';
import './LiquidityActivityTrap.sol';
import './ExtraMath.sol';

contract KattanaToken is LiquidityTrap, LiquidityActivityTrap {
    using ExtraMath for *;
    using SafeMath for *;
    using SafeERC20 for IERC20;

    uint private constant MONTH = 30 days;
    uint private constant YEAR = 365 days;

    enum LockType {
        Empty,
        Seed,
        Private,
        Strategic,
        Liquidity,
        Foundation,
        Team,
        Reserve,
        Advisors
    }

    struct LockConfig {
        uint32 releaseStart;
        uint32 vesting;
    }

    struct Lock {
        uint128 balance; // Total locked.
        uint128 released; // Released so far.
    }

    mapping(LockType => LockConfig) public lockConfigs;
    mapping(LockType => mapping(address => Lock)) public locks;

    // Friday, April 9, 2021 12:00:00 PM
    uint public constant DAY_ONE = 1617969600;

    uint private constant KTN = 10**18;

    bool public protected = true;

    event Note(address sender, bytes data);
    event LockTransfer(LockType lock, address from, address to, uint amount);

    modifier note() {
        emit Note(_msgSender(), msg.data);
        _;
    }

    constructor(address _distributor, uint128 _trapAmount, address _uniswapV2Factory, address _pairToken)
        ERC20('Kattana', 'KTN')
        LiquidityProtectedBase(_uniswapV2Factory, _pairToken)
        LiquidityTrap(_trapAmount)
    {
        lockConfigs[LockType.Seed] = LockConfig(
            (DAY_ONE + MONTH).toUInt32(),
            (9 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Seed)), 900_000 * KTN);
        locks[LockType.Seed][_distributor].balance = (900_000 * KTN).toUInt128();

        lockConfigs[LockType.Private] = LockConfig(
            (DAY_ONE + MONTH).toUInt32(),
            (8 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Private)), 1_147_500 * KTN);
        locks[LockType.Private][_distributor].balance = (1_147_500 * KTN).toUInt128();

        lockConfigs[LockType.Strategic] = LockConfig(
            (DAY_ONE).toUInt32(),
            (4 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Strategic)), 240_000 * KTN);
        locks[LockType.Strategic][_distributor].balance = (240_000 * KTN).toUInt128();

        lockConfigs[LockType.Liquidity] = LockConfig(
            (DAY_ONE).toUInt32(),
            (8 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Liquidity)), 1_720_000 * KTN);
        locks[LockType.Liquidity][_distributor].balance = (1_720_000 * KTN).toUInt128();

        lockConfigs[LockType.Foundation] = LockConfig(
            (DAY_ONE).toUInt32(),
            (10 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Foundation)), 2_000_000 * KTN);
        locks[LockType.Foundation][_distributor].balance = (2_000_000 * KTN).toUInt128();

        lockConfigs[LockType.Team] = LockConfig(
            (DAY_ONE + YEAR).toUInt32(),
            (10 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Team)), 1_500_000 * KTN);
        locks[LockType.Team][_distributor].balance = (1_500_000 * KTN).toUInt128();

        lockConfigs[LockType.Reserve] = LockConfig(
            (DAY_ONE + YEAR).toUInt32(),
            (10 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Reserve)), 1_000_000 * KTN);
        locks[LockType.Reserve][_distributor].balance = (1_000_000 * KTN).toUInt128();

        lockConfigs[LockType.Advisors] = LockConfig(
            (DAY_ONE + 6 * MONTH).toUInt32(),
            (10 * MONTH).toUInt32()
        );
        _mint(address(uint(LockType.Advisors)), 450_000 * KTN);
        locks[LockType.Advisors][_distributor].balance = (450_000 * KTN).toUInt128();

        // Public sale + day one unlock.
        _mint(_distributor, 1_042_500 * KTN);

        require(totalSupply() == 10_000_000 * KTN, 'Invalid total supply');
    }

    // In case someone will send other token here.
    function withdrawLocked(IERC20 _token, address _receiver, uint _amount) external onlyOwner() note() {
        _token.safeTransfer(_receiver, _amount);
    }

    function _passed(uint _time) private view returns(bool) {
        return block.timestamp > _time;
    }

    function _notPassed(uint _time) private view returns(bool) {
        return _not(_passed(_time));
    }

    function _since(uint _timestamp) private view returns(uint) {
        if (_notPassed(_timestamp)) {
            return 0;
        }
        return block.timestamp.sub(_timestamp);
    }

    function _not(bool _condition) private pure returns(bool) {
        return !_condition;
    }

    function batchTransfer(address[] memory _to, uint[] memory _amount) public {
        require(_to.length == _amount.length, 'Invalid input');
        for (uint _i = 0; _i < _to.length; _i++) {
            transfer(_to[_i], _amount[_i]);
        }
    }

    function batchTransferLock(LockType _lockType, address[] memory _to, uint[] memory _amount) public {
        require(_to.length == _amount.length, 'Invalid input');
        for (uint _i = 0; _i < _to.length; _i++) {
            transferLock(_lockType, _to[_i], _amount[_i]);
        }
    }

    // Assign locked tokens to another holder.
    function transferLock(LockType _lockType, address _to, uint _amount) public {
        require(_amount > 0, 'Invalid amount');
        Lock memory _lock = locks[_lockType][_msgSender()];
        require(_lock.released == 0, 'Cannot transfer after release');
        require(_lock.balance >= _amount, 'Insuffisient locked funds');

        locks[_lockType][_msgSender()].balance = _lock.balance.sub(_amount).toUInt128();
        locks[_lockType][_to].balance = locks[_lockType][_to].balance.add(_amount).toUInt128();
        emit LockTransfer(_lockType, _msgSender(), _to, _amount);
    }

    // Get released tokens to the main balance.
    function releaseLock(LockType _lock) external note() {
        _release(_lock, _msgSender());
    }

    function _release(LockType _lockType, address _holder) private {
        LockConfig memory _lockConfig = lockConfigs[_lockType];

        Lock memory _lock = locks[_lockType][_holder];
        uint _balance = _lock.balance;
        uint _released = _lock.released;

        uint _vestedBalance = _balance.mul(_since(_lockConfig.releaseStart)) / _lockConfig.vesting;
        uint _balanceToRelease = Math.min(_vestedBalance, _balance);

        require(_balanceToRelease > _released, 'Insufficient unlocked');

        // Underflow cannot happen here, SafeMath usage left for code style.
        uint _amount = _balanceToRelease.sub(_released);

        locks[_lockType][_holder].released = _balanceToRelease.toUInt128();
        _transfer(address(uint(_lockType)), _holder, _amount);
    }

    // UI function.
    function releasable(LockType _lockType, address _holder) public view returns(uint) {
        LockConfig memory _lockConfig = lockConfigs[_lockType];

        Lock memory _lock = locks[_lockType][_holder];
        uint _balance = _lock.balance;
        uint _released = _lock.released;

        uint _vestedBalance = _balance.mul(_since(_lockConfig.releaseStart)) / _lockConfig.vesting;
        uint _balanceToRelease = Math.min(_vestedBalance, _balance);

        if (_balanceToRelease <= _released) {
            return 0;
        }

        // Underflow cannot happen here, SafeMath usage left for code style.
        return _balanceToRelease.sub(_released);
    }

    // UI function.
    function releasableTotal(address _holder) public view returns(uint[9] memory _result) {
        _result[1] = releasable(LockType.Seed, _holder);
        _result[2] = releasable(LockType.Private, _holder);
        _result[3] = releasable(LockType.Strategic, _holder);
        _result[4] = releasable(LockType.Liquidity, _holder);
        _result[5] = releasable(LockType.Foundation, _holder);
        _result[6] = releasable(LockType.Team, _holder);
        _result[7] = releasable(LockType.Reserve, _holder);
        _result[8] = releasable(LockType.Advisors, _holder);
    }

    function disableProtection() external onlyOwner() {
        protected = false;
    }

    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        if (protected) {
            LiquidityActivityTrap_validateTransfer(_from, _to, _amount);
            LiquidityTrap_validateTransfer(_from, _to, _amount);
        }
    }
}