// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IBEP20.sol";
import "./Math.sol";

/**
 * Swap Gateway
 * @dev Allow anyone swap bnb to get token
 * @author Brian Dhang
 */
contract SwapGateway is Pausable, Ownable {
    using Math for uint256;

    address immutable _token;
    bool _isReleaseAll;
    uint256 _lockedBalances;
    uint128 _rate;
    uint64 constant _bnbModulus = 10**18;
    uint32 constant _tokenModulus = 10**8;
    uint32 constant _secondsInDay = 86400;
    uint32 _keepPeriod;
    uint32 _releasePeriod;
    uint16 _releaseNowPermille;
    uint16 _releasePerMille;

    mapping(address => string) user2Kyc;
    mapping(address => uint256) public user2Balances;
    mapping(address => uint256) public user2LockedBalances;
    mapping(address => uint256) public user2NextReleaseDate;
    mapping(address => uint256) public user2NextReleaseAmount;

    event Swap(
        address indexed user,
        uint256 bnbValue,
        uint256 amount,
        uint256 timestamp,
        string kyc
    );
    event Release(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        string kyc
    );
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 amount, uint256 timestamp);
    event ChangeRate(uint128 from, uint128 to, uint256 timestamp);
    event ReleaseAll(bool isReleaseAll, uint256 timestamp);
    event Transfer(
        address from,
        address to,
        uint256 bnbValue,
        uint256 timestamp
    );

    /**
     * Constructor
     * @dev Set token address, swap rate and release all status
     */
    constructor(
        address token,
        bool isReleaseAll,
        uint128 newRate,
        uint32 keepPeriod,
        uint32 releasePeriod,
        uint16 releaseNowPermille,
        uint16 releasePerMille
    ) {
        _token = token;
        _isReleaseAll = isReleaseAll;
        _rate = newRate;
        _keepPeriod = keepPeriod * _secondsInDay;
        _releasePeriod = releasePeriod * _secondsInDay;
        _releaseNowPermille = releaseNowPermille;
        _releasePerMille = releasePerMille;
    }

    /**
     * Swap
     * @dev Allow anyone wrap bnb to get token
     */
    function swap(string memory kyc) external payable whenNotPaused {
        address user = msg.sender;
        uint256 bnbValue = msg.value;
        uint256 amount = ((bnbValue * _rate) / _bnbModulus) * _tokenModulus;

        require(bnbValue >= 0.01 ether, "Too small bnb");
        require(
            IBEP20(_token).balanceOf(address(this)) >= _lockedBalances + amount,
            "Token sold out"
        );

        // Lock token for contract
        _lockedBalances += amount;

        // Lock token for user
        user2Kyc[user] = kyc;
        user2Balances[user] += amount;
        user2LockedBalances[user] += amount;
        emit Swap(user, bnbValue, amount, block.timestamp, kyc);

        // Release some token to user now
        if (_isReleaseAll) {
            user2NextReleaseAmount[user] = amount;
        } else {
            user2NextReleaseAmount[user] =
                (amount * _releaseNowPermille) /
                1000;
        }
        _release(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + _keepPeriod;
    }

    /**
     * Release
     * @dev Allow user check status to release
     * @dev Condition 1: Wait "_keepPeriod" minutes from deposit time
     * @dev Condition 2: Each "_releasePeriod" minutes can release "_releasePerMille" / 1000
     */
    function release(address user) external {
        require(block.timestamp >= user2NextReleaseDate[user], "Too early");
        if (_isReleaseAll) {
            user2NextReleaseAmount[user] = user2LockedBalances[user];
        }

        require(user2NextReleaseAmount[user] > 0, "Released all");

        _release(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + _releasePeriod;
    }

    /**
     * Release internal
     * @dev Send token to user
     */
    function _release(address user) internal {
        uint256 amount = user2NextReleaseAmount[user];
        IBEP20(_token).transfer(user, amount);
        emit Release(user, amount, block.timestamp, user2Kyc[user]);

        // Calculate locked token for contract and for user
        _lockedBalances -= amount;
        user2LockedBalances[user] -= amount;

        // Set next release amount
        user2NextReleaseAmount[user] = Math.min(
            (user2Balances[user] * _releasePerMille) / 1000,
            user2LockedBalances[user]
        );
    }

    /**
     * Deposit token
     * @dev Allow owner deposit token
     * Can only be called by the current owner.
     */
    function depositToken(uint256 amount) external onlyOwner {
        IBEP20(_token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    /**
     * Withdraw token
     * @dev Allow owner withdraw free token
     * Can only be called by the current owner.
     */
    function withdrawToken(uint256 amount) external onlyOwner {
        require(
            IBEP20(_token).balanceOf(address(this)) >= _lockedBalances + amount,
            "Token locked"
        );
        IBEP20(_token).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * Withdraw bnb
     * @dev Allow owner transfer bnb to wallet
     * Can only be called by the current owner.
     */
    function withdrawBnb(uint256 bnbValue) external onlyOwner {
        payable(msg.sender).transfer(bnbValue);

        emit Transfer(address(this), msg.sender, bnbValue, block.timestamp);
    }

    /** Pause
     * @dev Pause deposit
     * Can only be called by the current owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /** Unpause
     * @dev Unpause deposit
     * Can only be called by the current owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /** Set Rate
     * @dev Change bnb to token rate
     * Can only be called by the current owner.
     */
    function setRate(uint128 newRate) external onlyOwner {
        emit ChangeRate(_rate, newRate, block.timestamp);
        _rate = newRate;
    }

    /** Release all
     * @dev Change release all status
     * Can only be called by the current owner.
     */
    function setReleaseAll(bool isReleaseAll) external onlyOwner {
        _isReleaseAll = isReleaseAll;
        emit ReleaseAll(isReleaseAll, block.timestamp);
    }

    /**
     * Rate
     * @dev Returns rate.
     */
    function rate() public view returns (uint128) {
        return _rate;
    }
}