// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./token/BambooToken.sol";

//
// Bamboo Burn Yearly Party is a contract that encourages people to burn BAMBOO.
// Every year, a percentage of BAMBOOVAULT will be used as jackpot.
// The random approach used here is based on third-party trust to the Bamboo team to set a random seed at the start
// of the contract, that will not be revealed or used to gain an advantage.
//

contract BBYP is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The BAMBOO TOKEN, currency used to buy tickets and give the prize
    BambooToken public bamboo;

    // The timestamp of the next lottery draw.
    uint256 public purchaseLimit;

    // The price of a ticket entry.
    uint256 public price;

    // List of participants for current raindrop.
    address[] private participants;

    // Current prize pool amount.
    uint256 public prizePool;

    // Tracking of number of tickets
    struct UserInfo{
        uint256 validLimit;         // Timestamp until these tickets are valid
        uint256 tickets;            // Number of tickets bought by the user
    }

    // Tracking of amount of tickets per user.
    mapping(address => UserInfo) private ticketHolders;

    // Tracking of seeds so they cannot be repeated.
    mapping(uint256 => bool) private previousSeeds;

    // Last winner address
    address public lastWinner;

    // The seed for the random number, set at the beginning of the lottery.
    bytes32 sealedSeed;

    // Contract is only active when the seed has been set.
    bool public isActive;


    // Variables used for randomness.
    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = uint256(~0xff);
    uint256 private _targetBlock;
    bool public commited;

    event TicketsPurchased(address indexed user, uint256 ntickets);
    event NewLottery(uint256 purchaseLimit);
    event TicketPriceSet(uint256 price);
    event Winner(address indexed winner);
    event AddedToPool(uint256 amount);
    event Commit(uint256 targetBlock);


    constructor(BambooToken _bamboo) {
        bamboo = _bamboo;
        isActive = false;
    }

    // Purchase tickets for the lottery by burning them. The bamboo should be approved beforehand.
    // If user wants to know how many tickets he has, he can opt to register them for a bit of extra gas.
    function buyTickets(uint _ntickets, bool _register) public {
        require(msg.sender != owner(), "buyTickets: owner cannot participate");
        require(isActive, "buyTickets: lottery has not started yet");
        require(block.timestamp<=purchaseLimit, "buyTickets: period of buying tickets ended");
        require(_ntickets >0, "buyTickets: invalid number of tickets!");
        uint256 balance = bamboo.balanceOf(msg.sender);
        require(balance >=price.mul(_ntickets), "buyTickets: not enough bamboo!");
        uint256 cost = price.mul(_ntickets);
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), cost);
        // Contract burns the bamboo.
        bamboo.burn(cost);
        for(uint i=0; i<_ntickets; i++)
        {
            participants.push(msg.sender);
            // Shuffle participant into list
            if(participants.length > 1){
                uint256 randomN = uint256(blockhash(block.number)).mod(participants.length);
                participants[participants.length-1] = participants[randomN];
                participants[randomN] = msg.sender;
            }
        }
        if(_register){
            registerTicket(msg.sender, _ntickets);
        }
        emit TicketsPurchased(msg.sender, _ntickets);
    }

    // Register ticket of current lottery
    function registerTicket(address _addr, uint _ntickets) internal {
        UserInfo storage user = ticketHolders[_addr];
        if(user.validLimit != purchaseLimit) {
            user.validLimit = purchaseLimit;
            user.tickets = _ntickets;
        }
        else{
            user.tickets +=_ntickets;
        }
    }

    // Stop the ticket sell and saves the future block where the winner will be drawn
    function commit() public {
        require(isActive, "drawWinner: lottery has not started yet");
        require(block.timestamp>purchaseLimit , "drawWinner: period of buying tickets still up!");
        require(!commited, "drawWinner: this raindrop has already been commited");
        // If there are not enough participants, restart the lottery.
        if(participants.length < 1){
            purchaseLimit = block.timestamp.add(365 days);
            emit NewLottery(purchaseLimit);
        }
        else{
            _targetBlock = block.number + 1;
            commited = true;
            emit Commit(_targetBlock);
        }
    }

    // Stop the ticket sell and saves the future block where the winner will be drawn
    function revealWinner(bytes32 _seed) public onlyOwner {
        require(_targetBlock < block.number , "revealWinner: wait for a block to pass");
        require(commited, "revealWinner: this raindrop has not been commited yet");
        require(keccak256(abi.encode(msg.sender, _seed)) == sealedSeed, "revealWinner: the seed does not match the sealed seed");
        uint256 randomN = uint256(keccak256(abi.encode(_seed, blockhash(_targetBlock))));
        // For a detailed explanation of this step, check Raindrop smart contract.
        if (randomN == 0) {
            _targetBlock = (block.number & maskFirst248Bits) + (_targetBlock & maskLast8Bits);
            if (_targetBlock >= block.number) _targetBlock -= 256;
            randomN = uint256(keccak256(abi.encode(_seed, blockhash(_targetBlock))));
        }
        randomN = uint256(keccak256(abi.encode(randomN, _targetBlock)));
        address winner = participants[randomN % participants.length];

        // Declare the winner and reset the lottery!
        IERC20(bamboo).safeTransfer(winner, prizePool);
        lastWinner = winner;
        emit Winner(winner);
        // Reset variables for next lottery. Deleting variables returns a bit of gas.
        delete(participants);
        delete(commited);
        delete(_targetBlock);
        delete(isActive);
        delete(prizePool);
        // Burn any residual bamboo.
        uint256 contractBalance = bamboo.balanceOf(address(this));
        if (contractBalance > 0) {
            bamboo.burn(contractBalance);
        }
    }

    // A simple function that returns the number of tickets registered from a user.
    function getTickets(address _user) external view returns (uint256) {
        if(ticketHolders[_user].validLimit == purchaseLimit){
            return ticketHolders[_user].tickets;
        }
        else{
            return 0;
        }
    }

    // Allows a BBYP yearly cycle. Owner should send a hashed seed, that will be used to generate the winner next year.
    function beginLottery(bytes32 _sealedSeed) external onlyOwner{
        uint256 keySeed = uint256(_sealedSeed);
        require(!isActive, "beginLottery: lottery already started");
        require(!previousSeeds[keySeed], "beginLottery: already used seed");
        require(price > 0, "beginLottery: please set ticket price first");
        sealedSeed = _sealedSeed;
        isActive = true;
        // Allow a year to buy tickets.
        purchaseLimit = block.timestamp.add(365 days);
        previousSeeds[keySeed] = true;
        emit NewLottery(purchaseLimit);
    }

    // Sets the ticket price.
    function setTicketPrice(uint256 _amount) external onlyOwner{
        require(_amount > 0, "setTicketPrice: invalid amount");
        require(!isActive, "setTicketPrice: lottery already started");
        price = _amount;
        emit TicketPriceSet(price);
    }

    // Deposits bamboo to the prize pool. This will come from the BAMBOOVAULT wallet. Accepts external non-refundable contributions.
    function addToPool(uint256 _amount) external {
        require(isActive, "addToPool: lottery has not started yet");
        require(!commited, "addToPool: this lottery has been closed");
        require(block.timestamp<=purchaseLimit, "addToPool: cannot add to pool after tickets are closed");
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), _amount);
        prizePool = prizePool.add(_amount);
        emit AddedToPool(_amount);
    }
}