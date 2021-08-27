// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract TokenplayGameV2 is Ownable, Pausable {
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
    uint16 public rewardRate;
    mapping(uint256 => Round) private rounds;
    mapping(address => bool) private whitelist;

    event Initialized(
        string gameName,
        uint256 ticketPriceInBNB,
        uint256 ticketPriceInTOP,
        uint256 startRound,
        uint16 rewardRate,
        address indexed tokenAddress,
        address indexed vaultAddress
    );

    event TicketBoughtUsingBNB(
        address indexed playerAddress,
        uint256 price,
        uint256 quantity,
        uint256 round
    );

    event TicketBoughtUsingTOP(
        address indexed playerAddress,
        uint256 price,
        uint256 quantity,
        uint256 round
    );

    event RoundEnded(uint256 round, uint256 bnbPrizePool, uint256 topPrizePool);

    event PlayerBeRewardedInBNB(
        uint256 round,
        address indexed playerAddress,
        uint256 amount
    );

    event PlayerBeRewardedInTOP(
        uint256 round,
        address indexed playerAddress,
        uint256 amount
    );

    event RoundPaid(
        uint256 round,
        uint256 bnbRewardAmount,
        uint256 topRewardAmount
    );

    event TicketPriceInBNBChanged(uint256 round, uint256 ticketPrice);
    event TicketPriceInTOPChanged(uint256 round, uint256 ticketPrice);
    event RewardRateChanged(uint256 round, uint256 rewardRate);

    constructor(
        string memory _gameName,
        uint256 _ticketPriceInBNB,
        uint256 _ticketPriceInTOP,
        uint16 _rewardRate,
        address _token,
        address _vault
    ) {
        gameName = _gameName;
        ticketPriceInBNB = _ticketPriceInBNB;
        ticketPriceInTOP = _ticketPriceInTOP;
        currentRound = 1;
        rewardRate = _rewardRate;
        token = _token;
        vault = _vault;

        emit Initialized(
            gameName,
            ticketPriceInBNB,
            ticketPriceInTOP,
            currentRound,
            rewardRate,
            token,
            vault
        );
    }

    modifier onlyWhitelister() {
        require(
            whitelist[msg.sender] == true,
            "Ownable: caller is not in the whitelist"
        );
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function addWhitelister(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeWhitelister(address user) external onlyOwner {
        whitelist[user] = false;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function buyTicketUsingBNB(uint256 quantity) external payable notContract whenNotPaused {
        uint256 totalAmount = ticketPriceInBNB * quantity;

        require(msg.value == totalAmount, "purchase amount is not enough");

        rounds[currentRound].boughtTickets[msg.sender] += quantity;
        rounds[currentRound].bnbPrizePool += totalAmount;

        emit TicketBoughtUsingBNB(msg.sender, ticketPriceInBNB, quantity,currentRound);
    }

    function buyTicketUsingTOP(uint256 quantity) external notContract whenNotPaused {
        uint256 totalAmount = ticketPriceInTOP * quantity;

        IBEP20(token).transferFrom(msg.sender, address(this), totalAmount);

        rounds[currentRound].boughtTickets[msg.sender] += quantity;
        rounds[currentRound].topPrizePool += totalAmount;

        emit TicketBoughtUsingTOP(msg.sender, ticketPriceInTOP, quantity, currentRound);
    }

    function endRound() external onlyWhitelister returns (uint256, uint256) {
        uint256 rewardAmountInBNB = rounds[currentRound].bnbPrizePool * rewardRate / 10000;
        uint256 serviceAmountInBNB = rounds[currentRound].bnbPrizePool - rewardAmountInBNB;
        uint256 rewardAmountInTOP = rounds[currentRound].topPrizePool * rewardRate / 10000;
        uint256 serviceAmountInTOP = rounds[currentRound].topPrizePool - rewardAmountInTOP;

        if (serviceAmountInBNB > 0) {
            payable(vault).transfer(serviceAmountInBNB);
        }

        if (serviceAmountInTOP > 0) {
            IBEP20(token).transfer(vault, serviceAmountInTOP);
        }

        emit RoundEnded(
            currentRound,
            rounds[currentRound].bnbPrizePool,
            rounds[currentRound].topPrizePool
        );

        currentRound++;

        return (rewardAmountInBNB, rewardAmountInTOP);
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
    ) external onlyWhitelister {
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

    function setRewardRate(uint16 rate) external onlyOwner whenPaused {
        rewardRate = rate;

        emit RewardRateChanged(currentRound, rewardRate);
    }

    function setVault(address user) external onlyOwner whenPaused {
        vault = user;
    }
}