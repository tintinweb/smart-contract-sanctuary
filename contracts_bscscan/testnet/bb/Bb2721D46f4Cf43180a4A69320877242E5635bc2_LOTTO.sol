pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

contract LOTTO {
    using SafeMath for uint256;

    address payable public owner;
    address payable public BuyBackandBurn;
    address payable public marketWallet;

    address[] public users;
    address[] public winners;

    uint256 public amountRaised;
    uint256 public totalusers;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public startIndex;
    uint256 public ticketFee = 0.001 ether;
    uint256 public timePeriod = 7 days;
    uint256 public rewardPercent = 50;
    uint256 public buybackPercent = 30;
    uint256 public marketPercent = 20;
    uint256 public percentDivider = 100;

    struct User {
        uint256 winCount;
        uint256 lastWinAt;
    }

    mapping(address => User) public userData;
    mapping(address => uint256) public userContribution;

    modifier onlyOwner() {
        require(msg.sender == owner, "BEP20: Not an owner");
        _;
    }

    event TicketBought(address _user, uint256 _amount);
    event LotteryWinner(address _user, uint256 _amount);
    event burning(address _user, uint256 _amount);
    event market(address _user, uint256 _amount);

    constructor(address payable _owner) {
        BuyBackandBurn = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        marketWallet = payable(0x3411CA4c8B564F05102C3367840e599e8ed4096D);
        owner = _owner;
        startTime = block.timestamp;
        ticketFee = 0.001 ether;
        timePeriod = 7 days;
        rewardPercent = 50;
        buybackPercent = 30;
        marketPercent = 20;
        percentDivider = 100;

        endTime = startTime.add(timePeriod);
    }

    receive() external payable {}

    //   => for web3 use
    function BuyTicket() public payable {
        require(block.timestamp >= startTime, "wait to start");
        require(block.timestamp <= endTime, "ended");
        require(msg.value == ticketFee, "amount should be equal to 0.01 bnb");
        users.push(msg.sender);
        userContribution[msg.sender] = userContribution[msg.sender].add(
            msg.value
        );
        amountRaised = amountRaised.add(msg.value);
        totalusers++;
        emit TicketBought(msg.sender, msg.value);
    }

    function Lottery() public onlyOwner {
        uint256 winnerIndex = luckyDraw(startIndex, users.length);
        address winner = users[winnerIndex];
        uint256 contractBalance = address(this).balance;
        uint256 winningAmount = contractBalance.mul(rewardPercent).div(
            percentDivider
        );
        uint256 buyBackAmount = contractBalance.mul(buybackPercent).div(
            percentDivider
        );
        uint256 marketAmount = contractBalance.mul(marketPercent).div(
            percentDivider
        );
        winners.push(winner);

        User memory user = userData[winner];
        user.winCount++;
        user.lastWinAt = block.timestamp;
        payable(winner).transfer(winningAmount);
        BuyBackandBurn.transfer(buyBackAmount);
        marketWallet.transfer(marketAmount);
        startTime = block.timestamp;
        endTime = startTime.add(timePeriod);
        startIndex = users.length;

        emit LotteryWinner(winner, winningAmount);
        emit burning(BuyBackandBurn, buyBackAmount);
        emit market(marketWallet, marketAmount);
    }

    function luckyDraw(uint256 from, uint256 to)
        private
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number // +
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changTime(uint256 _duration) public onlyOwner {
        timePeriod = _duration;
    }

    function migrateFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    function changeLotteryData(
        uint256 _ticketFee,
        uint256 _timePeriod,
        uint256 _rewardPercent,
        uint256 _buybackPercent,
        uint256 _marketPercent,
        uint256 _percentDivider
    ) external onlyOwner {
        ticketFee = _ticketFee;
        timePeriod = _timePeriod;
        rewardPercent = _rewardPercent;
        buybackPercent = _buybackPercent;
        marketPercent = _marketPercent;
        percentDivider = _percentDivider;
    }

    function updateWallets(address payable _buyBack, address payable _market)
        external
        onlyOwner
    {
        BuyBackandBurn = _buyBack;
        marketWallet = _market;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}