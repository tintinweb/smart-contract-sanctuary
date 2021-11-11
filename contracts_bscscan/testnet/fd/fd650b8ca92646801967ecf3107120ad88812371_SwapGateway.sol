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

    bool _isReleaseAll;
    uint256 _lockedBalances;
    uint128 public rate;
    uint64 constant _bnbModulus = 10**18;
    uint32 constant _tokenModulus = 10**8;
    uint32 constant _secondsInDay = 5;
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
    event ChangeReleasePeriod(
        bool isReleaseAll,
        uint32 keepPeriod,
        uint32 releasePeriod,
        uint16 releaseNowPermille,
        uint16 releasePerMille,
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
        bool isReleaseAll,
        uint128 _rate,
        uint32 keepPeriod,
        uint32 releasePeriod,
        uint16 releaseNowPermille,
        uint16 releasePerMille
    ) {
        _tokenContract = IBEP20(token);
        _isReleaseAll = isReleaseAll;
        rate = _rate;
        _keepPeriod = keepPeriod * _secondsInDay;
        _releasePeriod = releasePeriod * _secondsInDay;
        _releaseNowPermille = releaseNowPermille;
        _releasePerMille = releasePerMille;
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
            _tokenContract.balanceOf(address(this)) >= _lockedBalances + amount,
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

        _releaseNow(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + _keepPeriod;
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
        if (_isReleaseAll) {
            user2NextReleaseAmount[user] = user2LockedBalances[user];
        }

        require(user2NextReleaseAmount[user] > 0, "Released all");

        _releaseNow(user);

        // Set next release date
        user2NextReleaseDate[user] = block.timestamp + _releasePeriod;
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
            _tokenContract.balanceOf(address(this)) >= _lockedBalances + amount,
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
    function changeRate(uint128 _rate) external onlyOwner {
        emit ChangeRate(rate, _rate, block.timestamp);
        rate = _rate;
    }

    /**
     * Change release period
     * @dev Allow owner change release period
     */
    function changeReleasePeriod(
        bool isReleaseAll,
        uint32 keepPeriod,
        uint32 releasePeriod,
        uint16 releaseNowPermille,
        uint16 releasePerMille
    ) external onlyOwner {
        _isReleaseAll = isReleaseAll;
        _keepPeriod = keepPeriod * _secondsInDay;
        _releasePeriod = releasePeriod * _secondsInDay;
        _releaseNowPermille = releaseNowPermille;
        _releasePerMille = releasePerMille;
        emit ChangeReleasePeriod(
            _isReleaseAll,
            _keepPeriod,
            _releasePeriod,
            _releaseNowPermille,
            _releasePerMille,
            block.timestamp
        );
    }
}