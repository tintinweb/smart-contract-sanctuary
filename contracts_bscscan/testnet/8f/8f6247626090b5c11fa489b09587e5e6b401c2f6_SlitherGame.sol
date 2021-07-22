// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

import "./IBEP20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SlitherGame is Ownable, Pausable {
    string public gameName;
    uint256 public ticketPrice;
    address public token;
    mapping(address => uint256) private boughtTickets;
    mapping(address => bool) private whitelist;

    event Initialized(
        uint256 ticketPrice,
        address indexed tokenAddress
    );

    event TicketBought(
        address indexed playerAddress,
        uint256 price,
        uint256 quantity
    );

    event PlayerBeRewarded(
        address indexed playerAddress,
        uint256 score,
        uint256 amount
    );

    event TicketPriceChanged(uint256 price);

    constructor(
        uint256 _ticketPrice,
        address _token
    ) {
        gameName = "Slither";
        ticketPrice = _ticketPrice;
        token = _token;

        emit Initialized(
            ticketPrice,
            token
        );
    }

    modifier onlyWhitelist() {
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

    function buyTicket(uint256 quantity) external notContract whenNotPaused {
        IBEP20(token).transferFrom(msg.sender, address(this), ticketPrice * quantity);

        boughtTickets[msg.sender] += quantity;

        emit TicketBought(msg.sender, ticketPrice, quantity);
    }

    function getBoughtTickets(address player)
        public
        view
        returns (uint256)
    {
        return boughtTickets[player];
    }

    function getPrizePool()
        public
        view
        returns (uint256)
    {
        return IBEP20(token).balanceOf(address(this));
    }

    function payReward(address player, uint256 score, uint256 amount) external onlyWhitelist {
        require(
            boughtTickets[player] > 0,
            "player hasn't bought any tickets yet"
        );

        require(
            IBEP20(token).balanceOf(address(this)) >= amount,
            "reward amount is higher than pool balance"
        );

        IBEP20(token).transfer(player, amount);

        emit PlayerBeRewarded(
            player,
            score,
            amount
        );
    }

    function setTicketPrice(uint256 price) external onlyOwner whenPaused {
        ticketPrice = price;

        emit TicketPriceChanged(price);
    }
}