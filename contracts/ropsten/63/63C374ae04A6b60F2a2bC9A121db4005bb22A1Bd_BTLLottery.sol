/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approveForICO(address spender, uint256 tokens)
        external
        returns (bool success);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);
}

contract BTLLottery {
    address payable public manager;
    ERC20Interface token;
    enum LotteryState {
        Open,
        Closed,
        Finished
    }
    enum LotteryTicketState {
        Pending,
        Success,
        Rejected
    }
    mapping(string => LotteryInstance) public lotteries;
    mapping(string => LotteryTicket) public lotteryTickets;
    mapping(string => mapping(uint256 => address)) winners;
    
    struct LotteryTicket {
        string numbers;
        string paymentHash;
        address buyer;
        string lottery;
        LotteryTicketState state;
    }

    struct LotteryInstance {
        string winningNumbers;
        address payable admin;
        uint256 entryFee;
        LotteryState state;
    }

    constructor(address contractAddr) {
        manager = payable(msg.sender);
        token = ERC20Interface(contractAddr);
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can have access.");
        _;
    }

    event PurchaseLottery(address buyer, string txId);
    
    function changeFounder(address payable _manager) public onlyManager {
        manager = _manager;
    }

    function closeLottery(string memory id) public {
        require(lotteries[id].admin == msg.sender, "400_OAA"); // only admin access
        lotteries[id].state = LotteryState.Closed;
    }

    function finishLotteryState(string memory id) public {
        require(lotteries[id].admin == msg.sender, "400_OAA"); // only admin access
        lotteries[id].state = LotteryState.Finished;
    }

    function createLotteryInstance(string memory id, uint256 entryFee, address payable admin) public onlyManager {
        lotteries[id] = LotteryInstance("", admin, entryFee, LotteryState.Open);
    }

    /**
     * This is the actual transfer of coins from buyer to admin wallet, once its been success.
     * Single transaction can be for multiple tickets
     * Lottery ticket of buyer will be activated from admin.
     */
    // function purchaseLotteryTicketPayment(string memory lotteryId, string memory txId) public payable {
    //     require(
    //         lotteries[lotteryId].admin == address(0),
    //         "400_INL"
    //     ); // Invalid lottery
    //     require(
    //         lotteries[lotteryId].entryFee <= token.balanceOf(msg.sender),
    //         "400_NEB"
    //     ); // not enough BTLs in buyer account
    //     require(
    //         lotteries[lotteryId].entryFee <= token.balanceOf(msg.sender),
    //         "400_NEB"
    //     ); // not enough BTLs in buyer account
        
    //     // transfer BTL from buyer to admin
    //     // have to call approve function of BTL token before this.
    //     token.transferFrom(msg.sender, lotteries[lotteryId].admin, lotteries[lotteryId].entryFee);
    //     emit PurchaseLottery(msg.sender, txId);
    // }
    
    /**
     * This function will be called from admin to add ticket entry for buyer
     * once transaction has been success.
     */
    function buyLotteryTicket(
        string memory id,
        string memory paymentHash,
        string memory numbers,
        string memory lotteryId,
        address payable buyer
    ) public onlyManager {
        lotteryTickets[id] = LotteryTicket(numbers, paymentHash, buyer, lotteryId, LotteryTicketState.Success);
    }

    /**
    * Will be called from manager after BTL transaction done from buyer to manager
    */
    function afterLotteryEntryFeeDone(
        address payable buyer,
        string memory ticketId
    ) public payable onlyManager {
        require(lotteryTickets[ticketId].buyer != address(0), "404_TNE"); // ticket not exist
        require(lotteryTickets[ticketId].buyer == buyer, "400_IBA"); // invalid buyer address

        // 1 BTL for as reward.
        if (token.balanceOf(manager) > 1 * 10**(8)) {
            // call approve function of BTL Contract before this.
            token.transferFrom(manager, buyer, 1);
        }
        lotteryTickets[ticketId].state = LotteryTicketState.Success;
    }

    /**
    * Will be called from manager account to set winner
    */
    function setWinner(
        address payable winner,
        string memory lotteryId,
        string memory winningNumbers,
        uint256 winnerNo
    ) public onlyManager {
        require(lotteries[lotteryId].admin != address(0), "404_TNE"); // lottery not exist
        winners[lotteryId][winnerNo] = winner;
        lotteries[lotteryId].winningNumbers = winningNumbers;
        lotteries[lotteryId].state = LotteryState.Finished;
    }
}