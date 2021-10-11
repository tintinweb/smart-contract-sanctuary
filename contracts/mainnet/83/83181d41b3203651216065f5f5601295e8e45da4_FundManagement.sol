// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * Contract to allow Tracer DAO to delegate funds to managers to spend as they see fit. 
 * Managers can request to withdraw funds assigned to them. The DAO may take back the funds at any time.
 */
contract FundManagement is Ownable {
    using SafeERC20 for IERC20;

    struct Fund {
        uint256 totalAmount; // Total amount of tokens assigned to the manager
        address asset;
        uint256 requestedWithdrawTime; // Timestamp which the manager may withdraw the pendingWithdrawAmount
        uint256 pendingWithdrawAmount; // Total amount of tokens the manager is pending to withdraw
    }

    /* ========== STATE VARIABLES ========== */

    uint256 public requestWindow = 2 days; // default period needed to wait after requesting that one can withdraw funds
    mapping(address => mapping(uint256 => Fund)) public funds; // user -> fundId -> fund
    mapping(address => uint256) public numberOfFunds; // user -> number of funds owned
    mapping(address => uint256) public locked; // asset -> amount locked up

    constructor() {}

    /* ========== VIEWS ========== */

    /**
     * @notice Checks a users fund if they passed the withdraw window and amount they're able to claim.
     */
    function checkClaimableAmount(address account, uint256 fundNumber) external view returns (bool claimable, uint256 amount) {
        Fund memory fund = funds[account][fundNumber];
        return (block.timestamp >= fund.requestedWithdrawTime, fund.pendingWithdrawAmount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice User requests funds that are allocated to them. After the request window if no clawback, they may claim those requested funds.
     * Note: If this function is called while there is already a pending request, it will add to the pending withdrawable amount and reset the request window.
     */
    function requestFunds(uint256 fundNumber, uint256 amount) external {
        require(
            fundNumber < numberOfFunds[msg.sender],
            "Fund number does not exist"
        );
        Fund storage fund = funds[msg.sender][fundNumber];
        uint256 totalWithdrawableAmount = fund.pendingWithdrawAmount + amount;
        require(
            totalWithdrawableAmount <= fund.totalAmount, 
            "Amount > total allocated funds"
        );
        
        fund.requestedWithdrawTime = block.timestamp + requestWindow;
        fund.pendingWithdrawAmount = totalWithdrawableAmount;

        emit RequestFunds(msg.sender, fundNumber, amount);
    }

    /**
     * @notice User claims the funds they requested. Only claimable after request window has passed with no clawbacks.
     */
    function claim(uint256 fundNumber) external {
        require(
            fundNumber < numberOfFunds[msg.sender],
            "Fund number does not exist"
        );
        Fund storage fund = funds[msg.sender][fundNumber];
        uint256 pendingAmount = fund.pendingWithdrawAmount;

        require(
            pendingAmount > 0,
            "No withdrawable funds"
        );
        require(
            pendingAmount <= fund.totalAmount, 
            "Amount > total allocated funds"
        );
        require(
            block.timestamp >= fund.requestedWithdrawTime,
            "Not withdrawable yet"
        );

        locked[fund.asset] = locked[fund.asset] - pendingAmount;
        fund.totalAmount = fund.totalAmount - pendingAmount;
        fund.pendingWithdrawAmount = 0;

        IERC20(fund.asset).safeTransfer(msg.sender, pendingAmount);

        emit Claim(msg.sender, fundNumber, pendingAmount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Owner of the contract may create a fund for a user/fundmanager. The fund will allow the user/fundmanager to request funds and claim it after the request window.
     */
    function createFund(address account, uint256 amount, address asset) external onlyOwner returns (uint256 fundNumber) {
        require(
            account != address(0) && asset != address(0),
            "Account or asset cannot be null"
        );
        require(
            amount > 0,
            "Invalid amount"
        );
        uint256 currentLocked = locked[asset];
        require(
            IERC20(asset).balanceOf(address(this)) >= currentLocked + amount,
            "Not enough tokens"
        );

        fundNumber = numberOfFunds[account];
        funds[account][fundNumber] = Fund(
            {
                totalAmount: amount,
                asset: asset,
                requestedWithdrawTime: 0,
                pendingWithdrawAmount: 0
            }
        );

        numberOfFunds[account] = fundNumber + 1;
        locked[asset] = currentLocked + amount;

        emit CreateFund(account, fundNumber, asset, amount);
    }

    /**
     * @notice Stops a fund from being claimed by deallocating their amount to 0. Those deallocated funds are unlocked for the owner to withdraw or reallocate.
     */
    function clawbackFunds(address account, uint256 fundNumber) external onlyOwner {
        require(
            account != address(0),
            "Account cannot be null"
        );
        require(
            fundNumber < numberOfFunds[account],
            "Fund number does not exist"
        );
        Fund storage fund = funds[account][fundNumber];

        locked[fund.asset] = locked[fund.asset] - fund.totalAmount;
        fund.totalAmount = 0;
        fund.pendingWithdrawAmount = 0;

        emit Clawback(account, fundNumber);
    }

    /**
     * @notice Add more tokens to a fund.
     */
    function addToFund(address account, uint256 amount, uint256 fundNumber) external onlyOwner {
        require(
            account != address(0),
            "Account cannot be null"
        );
        require(
            fundNumber < numberOfFunds[account],
            "Fund number does not exist"
        );
        Fund storage fund = funds[account][fundNumber];

        uint256 currentLocked = locked[fund.asset];
        require(
            IERC20(fund.asset).balanceOf(address(this)) - currentLocked >= amount,
            "Not enough unlocked tokens"
        );

        fund.totalAmount = fund.totalAmount + amount;
        locked[fund.asset] = currentLocked + amount;

        emit AddToFund(account, fundNumber, amount);
    }

    /**
     * @notice Withdraws an asset only if it's unlocked/deallocated. If you want to withdraw locked/allocated assets, clawback it first.
     */
    function withdrawUnlockedAssets(uint256 amount, address asset) external onlyOwner {
        IERC20 token = IERC20(asset);
        require(
            token.balanceOf(address(this)) - locked[asset] >= amount,
            "Not enough unlocked tokens"
        );
        token.safeTransfer(owner(), amount);
    }

    /**
     * @notice Change the duration of time a fund manager needs to wait to withdraw funds they request.
     * @param duration of time in seconds.
     */
    function setRequestWindow(uint256 duration) external onlyOwner {
        requestWindow = duration;
        emit ChangeRequestWindow(duration);
    }

    /* ========== EVENTS ========== */

    event AddToFund(address indexed account, uint256 fundNumber, uint256 amount);
    event ChangeRequestWindow(uint256 duration);
    event Claim(address indexed to, uint256 fundNumber, uint256 amount);
    event Clawback(address indexed account, uint256 fundNumber);
    event CreateFund(address indexed manager, uint256 fundNumber, address indexed asset, uint256 amount);
    event RequestFunds(address indexed to, uint256 fundNumber, uint256 amount);
}