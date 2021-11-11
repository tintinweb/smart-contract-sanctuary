// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IBEP20.sol";
import "./Math.sol";

/**
 * Swap Gateway
 * @dev Allow anyone swap bnb to specified token
 * @author Brian Dhang
 */
contract SwapGateway is Pausable, Ownable {
    using Math for uint256;

    IBEP20 immutable _tokenContract;

    bool public isReleaseAll;
    uint256 public rate;
    uint256 public lockedBalances;
    uint256 public keepPeriod;
    uint256 public releasePeriod;
    uint256 public releaseNowPermille;
    uint256 public releasePerMille;
    uint256 constant _bnbModulus = 10**18;
    uint256 constant _tokenModulus = 10**8;
    uint256 constant _secondsInDay = 86400;

    mapping(address => string) public user2Kyc;
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
    event ChangeRate(uint256 from, uint256 to, uint256 timestamp);
    event ChangeReleasePeriod(
        bool isReleaseAll,
        uint256 keepPeriod,
        uint256 releasePeriod,
        uint256 releaseNowPermille,
        uint256 releasePerMille,
        uint256 timestamp
    );
    event Transfer(
        address from,
        address to,
        uint256 bnbValue,
        uint256 timestamp
    );

    /**
     * Constructor
     * @dev Set token address, swap rate and release period
     */
    constructor(
        address token,
        uint256 _rate,
        bool is_release_all,
        uint256 keep_period,
        uint256 release_period,
        uint256 release_now_per_mille,
        uint256 release_per_mille
    ) {
        _tokenContract = IBEP20(token);
        rate = _rate;
        isReleaseAll = is_release_all;
        keepPeriod = keep_period * _secondsInDay;
        releasePeriod = release_period * _secondsInDay;
        releaseNowPermille = release_now_per_mille;
        releasePerMille = release_per_mille;
    }

    /**
     * Swap
     * @dev Allow anyone swrap bnb to token
     */
    function swap(string memory kyc) external payable whenNotPaused {
        address user = msg.sender;
        uint256 bnbValue = msg.value;
        uint256 amount = ((bnbValue * rate) / _bnbModulus) * _tokenModulus;

        require(bnbValue >= 0.01 ether, "Too small bnb");
        require(
            _tokenContract.balanceOf(address(this)) >= lockedBalances + amount,
            "Token sold out"
        );

        // Lock token for contract
        lockedBalances += amount;

        // Lock token for user
        user2Kyc[user] = kyc;
        user2Balances[user] += amount;
        user2LockedBalances[user] += amount;
        emit Swap(user, bnbValue, amount, block.timestamp, kyc);

        // Release some token to user now
        if (isReleaseAll) {
            user2NextReleaseAmount[user] = amount;
        } else {
            user2NextReleaseAmount[user] = (amount * releaseNowPermille) / 1000;
        }

        _releaseNow(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + keepPeriod;
    }

    /**
     * Pause
     * @dev Allow owner pause swap function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * Unpause
     * @dev Allow owner unpause swap function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Release
     * @dev Allow anyone check and release token for specified user
     */
    function release(address user) external {
        require(block.timestamp >= user2NextReleaseDate[user], "Too early");
        if (isReleaseAll) {
            user2NextReleaseAmount[user] = user2LockedBalances[user];
        }

        require(user2NextReleaseAmount[user] > 0, "Released all");

        _releaseNow(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + releasePeriod;
    }

    /**
     * Release now
     * @dev Send token to user
     */
    function _releaseNow(address user) private {
        uint256 amount = user2NextReleaseAmount[user];
        _tokenContract.transfer(user, amount);
        emit Release(user, amount, block.timestamp, user2Kyc[user]);

        // Calculate locked token for contract and for user
        lockedBalances -= amount;
        user2LockedBalances[user] -= amount;

        // Set next release amount
        user2NextReleaseAmount[user] = Math.min(
            (user2Balances[user] * releasePerMille) / 1000,
            user2LockedBalances[user]
        );
    }

    /**
     * Deposit token
     * @dev Allow owner deposit token
     */
    function depositToken(uint256 amount) external onlyOwner {
        _tokenContract.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    /**
     * Withdraw token
     * @dev Allow owner withdraw free token
     */
    function withdrawToken(uint256 amount) external onlyOwner {
        require(
            _tokenContract.balanceOf(address(this)) >= lockedBalances + amount,
            "Token locked"
        );
        _tokenContract.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * Withdraw bnb
     * @dev Allow owner transfer bnb to wallet
     */
    function withdrawBnb(uint256 bnbValue) external onlyOwner {
        payable(msg.sender).transfer(bnbValue);
        emit Transfer(address(this), msg.sender, bnbValue, block.timestamp);
    }

    /**
     * Change rate
     * @dev Allow owner change swap rate
     */
    function changeRate(uint256 _rate) external onlyOwner {
        emit ChangeRate(rate, _rate, block.timestamp);
        rate = _rate;
    }

    /**
     * Change release period
     * @dev Allow owner change release period
     */
    function changeReleasePeriod(
        bool is_release_all,
        uint256 keep_period,
        uint256 release_period,
        uint256 release_now_per_mille,
        uint256 release_per_mille
    ) external onlyOwner {
        isReleaseAll = is_release_all;
        keepPeriod = keep_period * _secondsInDay;
        releasePeriod = release_period * _secondsInDay;
        releaseNowPermille = release_now_per_mille;
        releasePerMille = release_per_mille;
        emit ChangeReleasePeriod(
            isReleaseAll,
            keepPeriod,
            releasePeriod,
            releaseNowPermille,
            releasePerMille,
            block.timestamp
        );
    }
}