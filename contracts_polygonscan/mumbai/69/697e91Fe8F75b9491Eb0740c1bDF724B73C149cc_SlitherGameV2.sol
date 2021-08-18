// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SlitherGameV2 is Ownable, Pausable {
    struct Round {
        mapping(address => uint256) boughtTickets;
        uint256 prizePool;
        bool isPaid;
    }

    struct RewardPayment {
        address player;
        uint256 score;
        uint256 amount;
    }

    string public gameName;
    uint256 public ticketPrice;
    uint256 public currentRound;
    address public token;
    address public vault;
    uint16 public rewardRate;
    mapping(uint256 => Round) private rounds;
    mapping(address => bool) private whitelist;

    event Initialized(
        string gameName,
        uint256 ticketPrice,
        uint256 round,
        address indexed tokenAddress,
        address indexed vaultAddr,
        uint16 rewardRate
    );

    event TicketBought(
        address indexed playerAddress,
        uint256 price,
        uint256 quantity,
        uint256 round
    );

    event RoundEnded(uint256 round, uint256 prizePool);

    event PlayerBeRewarded(
        uint256 round,
        address indexed playerAddress,
        uint256 score,
        uint256 amount
    );

    event RoundPaid(
        uint256 round,
        uint256 rewardAmount
    );

    event TicketPriceChanged(uint256 round, uint256 price);

    constructor(
        uint256 _ticketPrice,
        address _token,
        address _vault,
        uint16 _rewardRate
    ) {
        gameName = "Slither";
        ticketPrice = _ticketPrice;
        currentRound = 1;
        token = _token;
        vault = _vault;
        rewardRate = _rewardRate;

        emit Initialized(
            gameName,
            ticketPrice,
            currentRound,
            token,
            vault,
            rewardRate
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

    function buyTicket(uint256 quantity) external notContract whenNotPaused {
        IBEP20(token).transferFrom(msg.sender, address(this), ticketPrice * quantity);

        rounds[currentRound].boughtTickets[msg.sender] += quantity;
        rounds[currentRound].prizePool += ticketPrice * quantity;

        emit TicketBought(msg.sender, ticketPrice, quantity, currentRound);
    }

    function endRound() external onlyWhitelister returns (uint256) {
        uint256 rewardAmount = rounds[currentRound].prizePool * rewardRate / 10000;
        uint256 serviceAmount = rounds[currentRound].prizePool - rewardAmount;

        if (serviceAmount > 0) {
            IBEP20(token).transfer(vault, serviceAmount);
        }

        emit RoundEnded(
            currentRound,
            rewardAmount
        );

        currentRound++;

        return rewardAmount;
    }

    function getBoughtTickets(uint256 round, address player)
        public
        view
        returns (uint256)
    {
        return rounds[round].boughtTickets[player];
    }

    function getPrizePool(uint256 round)
        public
        view
        returns (uint256)
    {
        return rounds[round].prizePool;
    }

    function _payReward(uint256 round, RewardPayment memory rewardPayment)
        internal
    {
        require(
            rounds[round].boughtTickets[rewardPayment.player] > 0,
            "player is not entered"
        );

        IBEP20(token).transfer(rewardPayment.player, rewardPayment.amount);

        emit PlayerBeRewarded(
            round,
            rewardPayment.player,
            rewardPayment.score,
            rewardPayment.amount
        );
    }

    function payReward(
        uint256 round,
        RewardPayment[] calldata payments
    ) external onlyWhitelister {
        require(round < currentRound, "invalid round");
        require(!rounds[round].isPaid, "this round was paid");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < payments.length; i++) {
            _payReward(round, payments[i]);
            totalAmount += payments[i].amount;
        }

        require(
            totalAmount == rounds[round].prizePool * rewardRate / 10000,
            "total amount is not equal to remaining pool balance"
        );

        rounds[round].isPaid = true;

        emit RoundPaid(round, totalAmount);
    }

    function setTicketPrice(uint256 price) external onlyOwner whenPaused {
        ticketPrice = price;

        emit TicketPriceChanged(currentRound, price);
    }

    function setVault(address user) external onlyOwner whenPaused {
        vault = user;
    }
}