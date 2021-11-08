// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IBEP20.sol";

/**
 * Swap Gateway
 * Allow anyone swap BNB to get token
 */
contract SwapGateway is Pausable, Ownable {
    address immutable _token;
    uint256 lockedBalances;
    uint64 _rate;
    uint64 constant bnb_modulus = 10**18;
    uint32 constant token_modulus = 10**8;

    mapping(address => uint256) user2Balances;
    mapping(address => uint256) user2DepositDate;
    mapping(address => uint256) user2ReleaseAmount;
    mapping(address => uint256) user2LastReleaseDate;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);
    event Swap(address indexed user, string userId, uint256 amount);
    event Release(address indexed user, uint256 amount);

    /**
     * Constructor
     * @dev Set wallet address
     */
    constructor(address token, uint64 rate) {
        _token = token;
        _rate = rate;
    }

    /**
     * Swap
     * @dev Allow anyone wrap BNB to get token
     */
    function swap(string memory userId, uint256 amount)
        external
        payable
        whenNotPaused
    {
        require(amount >= 0.01 ether);
        require(msg.value == amount);

        uint256 tokenAmount = ((amount * _rate) / bnb_modulus) * token_modulus;
        require(
            IBEP20(_token).balanceOf(address(this)) >=
                lockedBalances + tokenAmount
        );
        emit Swap(msg.sender, userId, amount);

        // Reset lock status when user deposit more
        lockedBalances += tokenAmount;
        user2Balances[msg.sender] += tokenAmount;
        user2DepositDate[msg.sender] = block.timestamp;
        user2LastReleaseDate[msg.sender] = block.timestamp + 60 days;

        // Release 10% token to user now
        user2ReleaseAmount[msg.sender] = tokenAmount / 10;
        _release();
    }

    /**
     * Release
     * @dev Allow user check status to release
     * @dev Condition 1: Wait 90 days from deposit day
     * @dev Condition 2: Each month can release 7.5%
     */
    function release() external {
        require(
            block.timestamp > (user2DepositDate[msg.sender] + 90 days) &&
                block.timestamp > (user2LastReleaseDate[msg.sender] + 30 days)
        );
        user2ReleaseAmount[msg.sender] =
            (user2Balances[msg.sender] * 75) /
            1000;
        _release();
    }

    /**
     * Release internal
     * @dev Send token to user
     */
    function _release() internal {
        uint256 amount = user2ReleaseAmount[msg.sender];
        IBEP20(_token).transferFrom(owner(), msg.sender, amount);
        emit Release(msg.sender, amount);

        user2ReleaseAmount[msg.sender] = 0;
        user2LastReleaseDate[msg.sender] = block.timestamp;
        lockedBalances -= amount;
    }

    /**
     * Deposit
     * @dev Allow owner deposit token
     * Can only be called by the current owner.
     */
    function deposit(address token, uint256 amount) external onlyOwner {
        IBEP20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    /**
     * Withdraw
     * @dev Allow owner withdraw BNB
     * Can only be called by the current owner.
     */
    function withdraw(uint256 amount) external payable onlyOwner {
        payable(owner()).transfer(amount);

        emit Withdraw(msg.sender, amount);
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
     * @dev Change BNB to token rate
     * Can only be called by the current owner.
     */
    function setRate(uint64 rate) external onlyOwner {
        _rate = rate;
    }
}