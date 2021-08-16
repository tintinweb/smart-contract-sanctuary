// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract TokenplayGame is Ownable, Pausable {
    struct Round {
        mapping(address => uint256) boughtTickets;
        uint256 bnbPrizePool;
        uint256 topPrizePool;
        bool isPaid;
    }

    struct RewardPayment {
        address player;
        uint256 amount;
    }

    string public gameName;
    uint256 public ticketPriceInBNB;
    uint256 public ticketPriceInTOP;
    uint256 public currentRound;
    address public token;
    address public vault;
    mapping(uint256 => Round) private rounds;
    mapping(address => bool) private whitelist;

    event Initialized(
        string gameName,
        uint256 ticketPriceInBNB,
        uint256 ticketPriceInTOP,
        uint256 round,
        address indexed tokenAddr,
        address indexed vaultAddr
    );

    event TicketBoughtUsingBNB(
        address indexed playerAddr,
        uint256 ticketPrice,
        uint256 round
    );

    event TicketBoughtUsingTOP(
        address indexed playerAddr,
        uint256 ticketPrice,
        uint256 round
    );

    event RoundEnded(uint256 round, uint256 bnbPrizePool, uint256 topPrizePool);

    event PlayerBeRewardedInBNB(
        uint256 round,
        address indexed playerAddr,
        uint256 rewardAmount
    );

    event PlayerBeRewardedInTOP(
        uint256 round,
        address indexed playerAddr,
        uint256 rewardAmount
    );

    event RoundPaid(
        uint256 round,
        uint256 bnbRewardAmount,
        uint256 topRewardAmount
    );

    event TicketPriceInBNBChanged(uint256 round, uint256 ticketPrice);
    event TicketPriceInTOPChanged(uint256 round, uint256 ticketPrice);

    constructor(
        string memory _gameName,
        uint256 _ticketPriceInBNB,
        uint256 _ticketPriceInTOP,
        address _token,
        address _vault
    ) {
        gameName = _gameName;
        ticketPriceInBNB = _ticketPriceInBNB;
        ticketPriceInTOP = _ticketPriceInTOP;
        currentRound = 1;
        token = _token;
        vault = _vault;

        emit Initialized(
            gameName,
            ticketPriceInBNB,
            ticketPriceInTOP,
            currentRound,
            token,
            vault
        );
    }

    modifier onlyWhitelist() {
        require(
            whitelist[msg.sender] == true,
            "Ownable: caller is not in the whitelist"
        );
        _;
    }

    function addWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function buyTicketUsingBNB() external payable whenNotPaused {
        require(msg.value == ticketPriceInBNB, "purchase amount is not enough");

        rounds[currentRound].boughtTickets[msg.sender] += 1;
        rounds[currentRound].bnbPrizePool += ticketPriceInBNB;

        emit TicketBoughtUsingBNB(msg.sender, ticketPriceInBNB, currentRound);
    }

    function buyTicketUsingTOP() external whenNotPaused {
        IBEP20(token).transferFrom(msg.sender, address(this), ticketPriceInTOP);

        rounds[currentRound].boughtTickets[msg.sender] += 1;
        rounds[currentRound].topPrizePool += ticketPriceInTOP;

        emit TicketBoughtUsingTOP(msg.sender, ticketPriceInTOP, currentRound);
    }

    function endRound() external onlyWhitelist returns (uint256, uint256) {
        uint256 halfBNBPool = rounds[currentRound].bnbPrizePool / 2;
        uint256 halfTOPPool = rounds[currentRound].topPrizePool / 2;

        if (halfBNBPool > 0) {
            payable(vault).transfer(halfBNBPool);
        }

        if (halfTOPPool > 0) {
            IBEP20(token).transfer(vault, halfTOPPool);
        }

        emit RoundEnded(
            currentRound,
            rounds[currentRound].bnbPrizePool,
            rounds[currentRound].topPrizePool
        );

        currentRound++;

        return (halfBNBPool, halfTOPPool);
    }

    function getBoughtTickets(uint256 round, address user)
        public
        view
        returns (uint256)
    {
        return rounds[round].boughtTickets[user];
    }

    function getPrizePool(uint256 round)
        public
        view
        returns (uint256, uint256)
    {
        return (rounds[round].bnbPrizePool, rounds[round].topPrizePool);
    }

    function _payBNBReward(uint256 round, RewardPayment memory rewardPayment)
        internal
    {
        require(
            rounds[round].boughtTickets[rewardPayment.player] > 0,
            "player is not entered"
        );

        payable(rewardPayment.player).transfer(rewardPayment.amount);

        emit PlayerBeRewardedInBNB(
            round,
            rewardPayment.player,
            rewardPayment.amount
        );
    }

    function _payTOPReward(uint256 round, RewardPayment memory rewardPayment)
        internal
    {
        require(
            rounds[round].boughtTickets[rewardPayment.player] > 0,
            "player is not entered"
        );

        IBEP20(token).transfer(rewardPayment.player, rewardPayment.amount);

        emit PlayerBeRewardedInTOP(
            round,
            rewardPayment.player,
            rewardPayment.amount
        );
    }

    function payRewards(
        uint256 round,
        RewardPayment[] calldata bnbPayments,
        RewardPayment[] calldata topPayments
    ) external onlyWhitelist {
        require(round < currentRound, "invalid round");
        require(!rounds[round].isPaid, "this round was paid");

        uint256 totalBNBAmount = 0;
        uint256 totalTOPAmount = 0;

        for (uint256 i = 0; i < bnbPayments.length; i++) {
            _payBNBReward(round, bnbPayments[i]);
            totalBNBAmount += bnbPayments[i].amount;
        }

        for (uint256 i = 0; i < topPayments.length; i++) {
            _payTOPReward(round, topPayments[i]);
            totalTOPAmount += topPayments[i].amount;
        }

        require(
            totalBNBAmount == rounds[round].bnbPrizePool / 2,
            "total BNB amount is not equal to remaining pool balance"
        );

        require(
            totalTOPAmount == rounds[round].topPrizePool / 2,
            "total TOP amount is not equal to remaining pool balance"
        );

        rounds[round].isPaid = true;

        emit RoundPaid(round, totalBNBAmount, totalTOPAmount);
    }

    function setTicketPriceInBNB(uint256 price) external onlyOwner whenPaused {
        ticketPriceInBNB = price;

        emit TicketPriceInBNBChanged(currentRound, ticketPriceInBNB);
    }

    function setTicketPriceInTOP(uint256 price) external onlyOwner whenPaused {
        ticketPriceInTOP = price;

        emit TicketPriceInTOPChanged(currentRound, ticketPriceInTOP);
    }

    function setVault(address user) external onlyOwner whenPaused {
        vault = user;
    }
}