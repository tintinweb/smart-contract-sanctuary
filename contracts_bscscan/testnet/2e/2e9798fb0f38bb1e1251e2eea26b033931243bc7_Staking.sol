// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;

import {Ownable} from "./Ownable.sol";
import {SafeERC20} from './SafeERC20.sol';
import {IERC20} from './IERC20.sol';
import {ReentrancyGuard} from './ReentrancyGuard.sol';
import {EnumerableSet} from './EnumerableSet.sol';


library Errors {
    string public constant ZERO_ADDRESS = 'ZERO_ADDRESS';
    string public constant LOCK_END_BEFORE_START = 'LOCK_END_BEFORE_START';
    string public constant DEPOSIT_BEFORE_START = 'DEPOSIT_BEFORE_START';
    string public constant DEPOSIT_AFTER_END = 'DEPOSIT_AFTER_END';
    string public constant WITHDRAW_BEFORE_END = 'WITHDRAW_BEFORE_END';
    string public constant NOT_STAKING_TOKEN = 'NOT_STAKING_TOKEN';
    string public constant INSUFFICIENT_USER_DEPOSIT = 'INSUFFICIENT_USER_DEPOSIT';
    string public constant ZERO_AMOUNT = 'ZERO_AMOUNT';
    string public constant IN_EMERGENCY = 'IN_EMERGENCY';
    string public constant DISABLED = 'DISABLED';
}

/// @title Implements "guarantee pool" and "lottery pool"
/// @author Vladimir Smelov <[email protected]>
/// @notice Does not support deflationary tokens!
contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool internal _emergency;
    address internal _stakingToken;
    address internal _stakingSyntheticToken;
    uint256 internal _lockStartTimestamp;
    uint256 internal _lockEndTimestamp;

    EnumerableSet.AddressSet internal _stakers;
    mapping(address => mapping(address => uint256)) internal _userTokenStakedAmount;
    mapping(address => mapping(address => uint256)) internal _userTokenWithdrawnAmount;

    /// @notice this only increasing on new stake and does not change on withdrawal
    mapping(address => uint256) internal _tokenTotalStakedAmount;
    mapping(address => uint256) internal _tokenTotalWithdrawnAmount;

    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event EmergencySet(
        address indexed user
    );

    function getEmergency() view external returns(bool) {
        return _emergency;
    }

    function getNumberOfStakers() view external returns(uint256) {
        return _stakers.length();
    }

    function getStakerByIndex(uint256 index) view external returns(address) {
        return _stakers.at(index);
    }

    function getStakingToken() view external returns(address) {
        return _stakingToken;
    }

    function getStakingSyntheticToken() view external returns(address) {
        return _stakingSyntheticToken;
    }

    function getLockStartTimestamp() view external returns(uint256) {
        return _lockStartTimestamp;
    }

    function getLockEndTimestamp() view external returns(uint256) {
        return _lockEndTimestamp;
    }

    /*
    @notice Total staked tokens from all users
    */
    function getTotalTokenStakedAmount(address token) external view onlyStakingToken(token) returns(uint256) {
        return _tokenTotalStakedAmount[token];
    }

    /*
    @notice Total balance tokens from all users minus withdrawals
    */
    function getTotalTokenBalanceAmount(address token) external view onlyStakingToken(token) returns(uint256) {
        unchecked {
            return _tokenTotalStakedAmount[token] - _tokenTotalWithdrawnAmount[token];
        }
    }

    /*
    @notice Total staked tokens from some user
    */
    function getUserTokenStakedAmount(address user, address token) external view onlyStakingToken(token) returns(uint256) {
        return _userTokenStakedAmount[user][token];
    }

    /*
    @notice Total balance tokens from some user minus withdrawals
    */
    function getUserTokenBalanceAmount(address user, address token) external view onlyStakingToken(token) returns(uint256) {
        unchecked {
            return _userTokenStakedAmount[user][token] - _userTokenWithdrawnAmount[user][token];
        }
    }


    /*
    @param stakingToken Address of the Lunch X token contract
    @param stakingSyntheticToken Address of the Lunch X power token contract
    @param lockStartTimestamp Start time of the lock
    @param lockEndTimestamp End of the lock period
    */
    constructor (address stakingToken, address stakingSyntheticToken, uint256 lockStartTimestamp, uint256 lockEndTimestamp) {
        require(stakingToken != address(0), Errors.ZERO_ADDRESS);
        require(stakingSyntheticToken != address(0), Errors.ZERO_ADDRESS);
        require(lockStartTimestamp < lockEndTimestamp, Errors.LOCK_END_BEFORE_START);
        _stakingToken = stakingToken;
        _stakingSyntheticToken = stakingSyntheticToken;
        _lockStartTimestamp = lockStartTimestamp;
        _lockEndTimestamp = lockEndTimestamp;
    }

    modifier onlyNotEmergency() {
        require(!_emergency, Errors.IN_EMERGENCY);
        _;
    }

    modifier onlyStakingToken(address token) {
        require(token == _stakingToken || token == _stakingSyntheticToken, Errors.NOT_STAKING_TOKEN);
        _;
    }

    /*
    Transfers tokens on behalf of msg.sender to this contract,

    if the transfer occurs within the specified period (lock_start, lock_end),
    and the transferred tokens are either launcx or laynchx power - then the transfer ends with success,
    if not, an error is issued corresponding to the problem.

    If the transfer is successful,
    it adds to the counter of transferred tokens with this address the amount of transferred tokens (report from zero)
    */
    function depositToken(address token, uint256 amount) external onlyStakingToken(token) nonReentrant onlyNotEmergency {
        require(block.timestamp >= _lockStartTimestamp, Errors.DEPOSIT_BEFORE_START);
        require(block.timestamp < _lockEndTimestamp, Errors.DEPOSIT_AFTER_END);
        require(amount > 0, Errors.ZERO_AMOUNT);
        if ((_userTokenStakedAmount[msg.sender][_stakingToken] == _userTokenWithdrawnAmount[msg.sender][_stakingToken]) &&
            (_userTokenStakedAmount[msg.sender][_stakingSyntheticToken] == _userTokenWithdrawnAmount[msg.sender][_stakingSyntheticToken])){
            // deposit from zero
            _stakers.add(msg.sender);
        }
        _userTokenStakedAmount[msg.sender][token] += amount;
        _tokenTotalStakedAmount[token] += amount;
        emit Deposit(msg.sender, token, amount);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);  // todo deflationary token
    }

    // If there is a problem with the contract, it should be possible for all users to take tokens back.
    function setEmergency() external onlyOwner nonReentrant onlyNotEmergency {
        _emergency = true;
        emit EmergencySet(msg.sender);
    }

    /*
    When a function is called, all tokens of the specified type previously translated by the called address
    are transferred back to the calling address.
    If the transfer is initiated between lock_start and lock_end, - an error
    If tokens have already been transferred in whole or in part - also an error.
    */
    function withdrawToken(address token, uint256 amount) external onlyStakingToken(token) nonReentrant {
        if (!_emergency) {
            require(block.timestamp > _lockEndTimestamp, Errors.WITHDRAW_BEFORE_END);  // note: > not >= for safety
        }
        require(amount > 0, Errors.ZERO_AMOUNT);
        uint256 newWithdrawnAmount = _userTokenWithdrawnAmount[msg.sender][token] + amount;
        require(newWithdrawnAmount <= _userTokenStakedAmount[msg.sender][token], Errors.INSUFFICIENT_USER_DEPOSIT);
        _userTokenWithdrawnAmount[msg.sender][token] = newWithdrawnAmount;
        _tokenTotalWithdrawnAmount[token] += amount;
        emit Withdraw(msg.sender, token, amount);
        IERC20(token).safeTransfer(msg.sender, amount);  // todo deflationary token
    }

    fallback() external payable {
        revert(Errors.DISABLED);
    }
}