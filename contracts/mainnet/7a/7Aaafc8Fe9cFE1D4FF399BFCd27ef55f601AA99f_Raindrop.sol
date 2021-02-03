// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./token/BambooToken.sol";


//
//
// Raindrop is the contract in charge of the lottery system.
// Every 10 days the contract will choose a winner.
// Randomness used here is based on future block hash, requiring two calls to determine the winner. (Commit + Draw).
// We are aware of the security vulnerabilities for this PRNG approach, still is for now the choice for finding the winner, because it is easier for end users.
// The PRNG method here is based on the Breeding Contract from the CriptoKitties DAPP.
//  Which was written by Axiom Zen, Dieter Shirley <[email protected]> (https://github.com/dete), Fabiano P. Soriani <[email protected]> (https://github.com/flockonus), Jordan Schalm

contract Raindrop is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info used in case of an emergency refund.
    struct UserInfo{
        uint256 validLimit;         // Timestamp until these tickets are valid
        uint256 tickets;            // Number of tickets bought by the user
        uint256 amountSpent;        // Amount spent on tickets
    }

    // Simple flag to check if contract has been started.
    // Owner could stop the contract if there are security issues. In that case all participants will be refunded.
    bool public isCloudy;

    // The address that will receive a percentage of the lottery.
    address public feeTo;

    // The BAMBOO TOKEN, currency used to buy tickets and give the  price.
    BambooToken public bamboo;

    // The timestamp of the next lottery draw.
    uint256 public nextRain;

    // The price of a ticket entry.
    uint256 public price;

    // Number of winners (and minimum participants).
    uint public constant nwinners = 9;

    // The winners of the last lottery.
    address[] private lastWinners;

    // List of participants for current raindrop.
    address[] private participants;
    // Tracking of amount of tickets per user. Needed in case of an emergency refund.
    mapping(address => UserInfo) private ticketHolders;

    // Current prize pool amount.
    uint256 public prizePool;

    // Variables used for randomness.
    uint256 internal constant maskLast8Bits = uint256(0xff);
    uint256 internal constant maskFirst248Bits = uint256(~0xff);
    uint256 private _targetBlock;
    bool public commited;
    bool public refundPeriod;

    event TicketsPurchased(address indexed user, uint256 ntickets);
    event NewRain(uint256 nextRain);
    event TicketPriceSet(uint256 price);
    event Commit(uint256 targetBlock);

    constructor(BambooToken _bamboo) {
        bamboo = _bamboo;
        isCloudy = false;
        refundPeriod = false;
    }

    // Purchase tickets for the lottery. The bamboo should be approved beforehand.
    function buyTickets(uint _ntickets) public {
        require(msg.sender != owner(), "buyTickets: owner cannot participate");
        require(isCloudy, "buyTickets: lottery has not started yet");
        require(block.timestamp<=nextRain, "buyTickets: period of buying tickets ended");
        require(_ntickets >0, "buyTickets: invalid number of tickets!");
        uint256 balance = bamboo.balanceOf(msg.sender);
        require(balance >=price.mul(_ntickets), "buyTickets: not enough bamboo!");

        uint256 cost = price.mul(_ntickets);
        IERC20(bamboo).safeTransferFrom(address(msg.sender), address(this), cost);
        prizePool = prizePool.add(cost);
        registerTicket(msg.sender, _ntickets);
        for(uint i=0; i<_ntickets; i++)
        {
            participants.push(msg.sender);
        }
        emit TicketsPurchased(msg.sender, _ntickets);
    }

    // Register ticket of current lottery in case of a refund.
    function registerTicket(address _addr, uint _ntickets) internal {
        UserInfo storage user = ticketHolders[_addr];
        if(user.validLimit != nextRain) {
            user.validLimit = nextRain;
            user.tickets = _ntickets;
        }
        else{
            user.tickets += _ntickets;
        }
        user.amountSpent += price.mul(_ntickets);
    }

    // Stop the ticket sell and prepare the variables.
    function commit() public {
        require(isCloudy, "commit: lottery has not started yet");
        require(block.timestamp>nextRain , "commit: period of buying tickets still up!");
        require(!commited, "commit: this raindrop has already been commited");
        // If there are not enough participants, add 1 week.
        if(participants.length < nwinners){
            nextRain = block.timestamp.add(7 days);
            emit NewRain(nextRain);
            updateTickets();
        }
        else{
            _targetBlock = block.number + 1;
            commited = true;
            emit Commit(_targetBlock);
        }
    }
    // Choose the winner. This call could be expensive, so the Bamboo team will be calling it every endRain day.
    function drawWinners() public {
        require(isCloudy, "drawWinners: lottery has not started yet");
        require(block.timestamp>nextRain , "drawWinners: period of buying tickets still up!");
        require(commited, "drawWinners: this raindrop has not been commited yet");
        // We will use the blockhash of the next n blocks to choose the n winners.
        require(block.number > _targetBlock + nwinners, "drawWinners: please wait for some more blocks to pass");
        uint256 prize = prizePool.div(10);
        uint256[] memory randomNums = new uint256[](nwinners);

        for(uint i=0; i<nwinners; ++i) {
            uint256 targetBlock = _targetBlock + i;
            // Try to grab the hash of the "target block". This should be available the vast
            // majority of the time (it will only fail if no-one calls drawWinner() within 256
            // blocks of the target block, which is about 40 minutes.
            uint256 randomN = uint256(blockhash(targetBlock));
            if (randomN == 0) {
                // We don't want to completely bail if the target block is no-longer available,
                // nor do we want to just use the current block's hash (since it could allow a
                // caller to game the random result). Compute the most recent block that has the
                // the same value modulo 256 as the target block. The hash for this block will
                // still be available, and – while it can still change as time passes – it will
                // only change every 40 minutes. Again, someone is very likely to jump in with
                // the giveBirth() call before it can cycle too many times.
                _targetBlock = (block.number & maskFirst248Bits) + (targetBlock & maskLast8Bits);

                // The computation above could result in a block LARGER than the current block,
                // if so, subtract 256.
                if (_targetBlock >= block.number) _targetBlock = _targetBlock.sub(256);
                targetBlock = _targetBlock + i;
                randomN = uint256(blockhash(targetBlock));

            }
            randomN = uint256(keccak256(abi.encode(randomN, targetBlock)));
            randomNums[i] = randomN;

        }

        // Reset variables for next lottery. Deleting variables returns a bit of gas.
        delete(prizePool);
        delete(commited);
        delete(_targetBlock);
        // Select winners.
        delete(lastWinners);
        for (uint i=0; i<nwinners; i++) {
            uint256 rindex = randomNums[i].mod(participants.length);
            lastWinners.push(participants[rindex]);
            // Remove that ticket from contention.
            participants[rindex] = participants[participants.length -1];
            participants.pop();
        }
        delete(participants);

        // Declare the winners and reset the lottery!
        for(uint i=0; i<nwinners; i++){
            IERC20(bamboo).safeTransfer(lastWinners[i], prize);
        }
        IERC20(bamboo).safeTransfer(feeTo, prize);
        nextRain = block.timestamp.add(10 days);
        emit NewRain(nextRain);
    }

    // Get the winners of the last lottery.
    function getLastWinners() public view returns(address[] memory) {
        return lastWinners;
    }

    // Stops the contract and allows users to call for refunds
    function emergencyStop() public onlyOwner {
        delete(isCloudy);
        delete(commited);
        delete(_targetBlock);
        delete(nextRain);
        delete(prizePool);
        delete(participants);
        refundPeriod = true;
    }

    // In emergencies, allows users to refund tickets.
    function refund() public {
        require(refundPeriod, 'refund: can only refund on emergency stop');
        UserInfo storage user = ticketHolders[msg.sender];
        require(user.amountSpent > 0, 'refund: nothing to refund');
        uint256 amount = user.amountSpent;
        IERC20(bamboo).safeTransfer(msg.sender, amount);
        delete(ticketHolders[msg.sender]);
    }

    // This function is called when there is less than minimum participants. No require needed
    function updateTickets() internal {
        address last;
        for(uint i=0; i<participants.length; i++) {
            address current = participants[i];
            if (current != last){
                ticketHolders[current].validLimit = nextRain;
            }
            last = current;
        }
    }

    // A simple function that returns the number of tickets from a user.
    function getTickets(address _user) external view returns (uint256) {
        if(ticketHolders[_user].validLimit == nextRain){
            return ticketHolders[_user].tickets;
        }
        else{
            return 0;
        }
    }

    // Allows the owner to start the contract. After this call, the contract doesn't need the owner anymore to work.
    function startRain() public onlyOwner {
        require(!isCloudy, "startRain: contract already started");
        require(price>0, "startRain: please set ticket price first");
        nextRain = block.timestamp.add(10 days);
        isCloudy = true;
        refundPeriod = false;
        emit NewRain(nextRain);
    }

    // Sets the address that will receive the commission from the lottery.
    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    // Sets the ticket price.
    function setTicketPrice(uint256 _amount) external onlyOwner {
        require(_amount > 0, "setTicketPrice: invalid amount");
        require(!isCloudy, "setTicketPrice: raindrop already started");
        price = _amount;
        emit TicketPriceSet(price);
    }

}