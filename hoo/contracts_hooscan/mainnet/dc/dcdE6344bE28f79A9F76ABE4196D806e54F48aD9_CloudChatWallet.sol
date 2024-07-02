// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * CloudChat Official Wallet Contract
 *
 * Contract Purpose
 *
 * 1. Allocate control of the wallet to multiple individuals and decentralize permissions
 * 2. The wallet funds locked in the contract, everyone can see the contract's * financial status and financial flow
 *
 * Contract Process
 *
 * Financial wallets are only allowed to submit transfer requests
 * Multiple bosses approve the transfer request based on
 * If 2/3 of the bosses agree, the transfer will be executed automatically
 * If 2/3 of the bosses reject, the transfer will be blocked and rejected
 * The transfer address is in the contract and cannot be changed by the bosses
 */
contract CloudChatWallet is Ownable, ReentrancyGuard {
    // deposit order struct
    struct Order {
        // deposit order id
        uint256 id;
        // from address
        address from;
        // deposit token address
        address token;
        // deposit token amount
        uint256 amount;
        // deposit time
        uint256 timestamp;
        // is deposit exist
        bool exist;
    }

    // finance wallet address
    address public financeWallet;
    // hot wallet address
    address public hotWallet;
    // boss address list
    address[] public bosses;
    // boss mapping
    mapping(address => bool) public bossData;
    // order mapping buy order id
    mapping(uint256 => Order) public orders;
    // approve apply mapping by token
    mapping(address => uint256) public approveData;
    // boss approve mapping by token
    mapping(address => address[]) public bossPassedData;
    // boss reject mapping by token
    mapping(address => address[]) public bossRejectedData;

    // all the events
    event setBossEvent(address boss, bool online);
    event setFinanceWalletEvent(address wallet);
    event setHotWalletEvent(address wallet);
    event DepositSuccess(uint256 id, address indexed from, uint256 value);
    event submitTransferApplySuccess(address indexed token, uint256 amount);
    event cancelTransferApplySuccess(address indexed token);
    event ApproveSuccess(
        address indexed token,
        address indexed boss,
        bool isPass
    );
    event TransferSuccess(
        address indexed token,
        address indexed to,
        uint256 value
    );
    event TransferApplyRejected(address indexed token, uint256 value);

    modifier onlyFinance() {
        require(
            financeWallet == _msgSender(),
            "Ownable: caller is not the finance"
        );
        _;
    }

    modifier onlyBoss() {
        require(bossData[_msgSender()], "Ownable: caller is not the boss");
        _;
    }

    /**
     * User deposits into the contract
     * Use the order id in the centralized server for deposits
     */
    function deposit(
        uint256 id,
        address token,
        uint256 amount
    ) external nonReentrant {
        require(!orders[id].exist, "CCError: The order already exists");
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "CCError: transfer failed");
        orders[id] = Order(
            id,
            msg.sender,
            token,
            amount,
            block.timestamp,
            true
        );
        emit DepositSuccess(id, msg.sender, amount);
    }

    /**
     * Set up the boss list
     * Add or remove
     */
    function setBoss(address boss, bool online) external onlyOwner {
        require(boss != address(0), "CCError: boss can not be zero");
        for (uint256 i = 0; i < bosses.length; i++) {
            if (bosses[i] == boss) {
                if (online) return;
                bosses[i] = bosses[bosses.length - 1];
                bosses.pop();
                delete bossData[boss];
                emit setBossEvent(boss, online);
                return;
            }
        }
        if (online) {
            bossData[boss] = true;
            bosses.push(boss);
            emit setBossEvent(boss, online);
        }
    }

    /**
     * Set up a financial wallet
     */
    function setFinanceWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "CCError: wallet can not be zero");
        financeWallet = wallet;
        emit setFinanceWalletEvent(wallet);
    }

    /**
     * Set up a hot wallet
     * The contracted funds will be transferred to this address
     */
    function setHotWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "CCError: wallet can not be zero");
        hotWallet = wallet;
        emit setHotWalletEvent(wallet);
    }

    /**
     * Financial address to submit transfer request
     */
    function submitTransferApply(address token, uint256 amount)
        external
        onlyFinance
    {
        require(
            approveData[token] == 0,
            "CCError: Applications for this token have been submitted"
        );
        require(
            IERC20(token).balanceOf(address(this)) > amount,
            "CCError: Insufficient token balance"
        );
        approveData[token] = amount;
        bossPassedData[token] = new address[](0);
        bossRejectedData[token] = new address[](0);
        emit submitTransferApplySuccess(token, amount);
    }

    /**
     * Reset approve data
     */
    function resetApproveData(address token) private {
        delete approveData[token];
        delete bossPassedData[token];
    }

    /**
     * Financial address cancellation transfer request
     */
    function cancelTransferApply(address token) external onlyFinance {
        require(
            approveData[token] > 0,
            "CCError: There are no cancellable applications at this time"
        );
        resetApproveData(token);
        emit cancelTransferApplySuccess(token);
    }

    /**
     * Check if the current boss has approved or rejected
     */
    function isBossApproved(address token) public view returns (bool) {
        for (uint256 i = 0; i < bossPassedData[token].length; i++) {
            if (bossPassedData[token][i] == msg.sender) {
                return true;
            }
        }
        for (uint256 i = 0; i < bossRejectedData[token].length; i++) {
            if (bossRejectedData[token][i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get the final approval
     * 3 types of results:
     * approved: 1
     * rejected: 2
     * approval in progress: 0
     */
    function getApproveResult(address token) public view returns (uint256) {
        uint256 approvedCount = bossPassedData[token].length;
        uint256 rejectedCount = bossRejectedData[token].length;
        uint256 count = (bosses.length * 2) / 3;
        if (approvedCount >= count) return 1;
        if (rejectedCount >= count) return 2;
        return 0;
    }

    /**
     * The boss performs the operation of approval
     * Pass or reject this apply
     */
    function tranferApprove(address token, bool isPass)
        external
        onlyBoss
        nonReentrant
    {
        require(approveData[token] > 0, "CCError: Approval cannot be made");
        require(
            !isBossApproved(token),
            "CCError: The current boss has already been approved"
        );
        if (isPass) {
            bossPassedData[token].push(msg.sender);
        } else {
            bossRejectedData[token].push(msg.sender);
        }
        emit ApproveSuccess(token, msg.sender, isPass);
        // check and execute the action of approval completion
        uint256 approveResult = getApproveResult(token);
        if (approveResult == 1) {
            uint256 amount = approveData[token];
            bool success = IERC20(token).transfer(hotWallet, amount);
            require(success, "CCError: transfer failed");
            resetApproveData(token);
            emit TransferSuccess(token, hotWallet, amount);
        } else if (approveResult == 2) {
            uint256 amount = approveData[token];
            resetApproveData(token);
            emit TransferApplyRejected(token, amount);
        }
    }
}