pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DiceGame {

    using SafeMath for *;

    modifier onlyOwner {
        require(owner == msg.sender, "only owner");
        _;
    }

    modifier onlyBanker {
        if(banker[msg.sender] == false) revert();
        _;
    }

    uint constant BET_EXPIRATION_BLOCKS = 250;
    uint constant public maxNumber = 96;
    uint constant public minNumber = 2;
    uint public maxProfit = 4 ether;
    uint public maxPendingPayouts; //total unpaid
    uint public minBet = 0.01 ether;
    uint public pID = 160000;


    struct Bet {

        uint amount;
        uint40 placeBlockNumber;
        uint8 roll;
        bool lessThan;
        address player;
    }

    address public signer = 0x62fF37a452F8fc3A471a59127430C1bCFAeaf313;
    address public owner;

    mapping(bytes32 => Bet) public bets;
    mapping(address => uint) playerPendingWithdrawals;
    mapping(address => uint) playerIdxAddr;
    mapping(uint => address) playerAddrIdx;
    mapping(address => bool) banker;

    event LogBet(bytes32 indexed BetID, address indexed PlayerAddress, uint BetValue, uint PlayerNumber, bool LessThan, uint256 Timestamp);
    event LogResult(bytes32 indexed BetID, address indexed PlayerAddress, uint PlayerNumber, bool LessThan, uint DiceResult, uint BetValue, uint Value, int Status, uint256 Timestamp);
    event LogRefund(bytes32 indexed BetID, address indexed PlayerAddress, uint indexed RefundValue);
    event LogHouseWithdraw(uint indexed amount);
    event BlockHashVerifyFailed(bytes32 commit);

    constructor() payable public {
        owner = msg.sender;
        playerIdxAddr[msg.sender] = pID;
        playerAddrIdx[pID] = msg.sender;

    }


    function setSecretSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMinBet(uint _minBet) public onlyOwner {
        minBet = _minBet;
    }

    function addBankerAddress(address bankerAddress) public onlyOwner {
        banker[bankerAddress] = true;
    }

    function setInvite(address inviteAddress, uint inviteID, uint profit) public onlyOwner {
        playerIdxAddr[inviteAddress] = inviteID;
        playerAddrIdx[inviteID] = inviteAddress;
        playerPendingWithdrawals[inviteAddress] = profit;
    }

    function batchSetInvite(address[] inviteAddress, uint[] inviteID, uint[] profit) public onlyOwner {
        uint length = inviteAddress.length;
        for(uint i = 0;i< length; i++) {
            setInvite(inviteAddress[i], inviteID[i], profit[i]);
        }

    }


    function getPlayerAddr(uint _pid) public view returns (address) {
        return playerAddrIdx[_pid];
    }

    function createInviteID(address _addr) public returns (bool) {
        if (playerIdxAddr[_addr] == 0) {
            pID++;
            playerIdxAddr[_addr] = pID;
            playerAddrIdx[pID] = _addr;
            return true;
        }
        return false;
    }

    function getPlayerId(address _addr) public view returns (uint){
        return playerIdxAddr[_addr];
    }

    function setMaxProfit(uint _maxProfit) public onlyOwner {
        maxProfit = _maxProfit;
    }


    function() public payable {

    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function placeBet(uint8 roll, bool lessThan, uint affID, uint lastBlock, bytes32 commit, uint8 v, bytes32 r, bytes32 s) public payable {
        uint amount = msg.value;
        require(amount >= minBet, "Amount is less than minimum bet size");
        require(roll >= minNumber && roll <= maxNumber, "Place number should be with rang.");
        require(block.number < lastBlock, "Commit has expired.");

        bytes32 signatureHash = keccak256(abi.encodePacked(lastBlock, commit));
        require(signer == ecrecover(signatureHash, v, r, s), "ECDSA signature is not valid.");

        Bet storage bet = bets[commit];
        require(bet.player == address(0x0));


        uint possibleWinAmount = getDiceWinAmount(amount, roll, lessThan);

        require(possibleWinAmount <=  amount + maxProfit, "maxProfit limit violation.");

        maxPendingPayouts = maxPendingPayouts.add(possibleWinAmount);

        require(maxPendingPayouts  <=   address(this).balance, "insufficient contract balance for payout.");


        bet.amount = amount;
        bet.placeBlockNumber = uint40(block.number);
        bet.roll = uint8(roll);
        bet.lessThan = lessThan;
        bet.player = msg.sender;

        emit LogBet(commit, msg.sender, amount, bet.roll, bet.lessThan, now);

        if (affID > 150000 && affID <= pID) {
            address affAddress = playerAddrIdx[affID];
            if(affAddress != address(0x0)) {
                playerPendingWithdrawals[affAddress] = playerPendingWithdrawals[affAddress].add(amount.div(100));
            }
        }


    }


    function getDiceWinAmount(uint amount, uint roll, bool lessThan) private pure returns (uint) {

        uint rollNumber = lessThan ? roll : 101 - roll;

        return amount * 98 / rollNumber;
    }

    /**
        refund user bet amount
    */
    function refundBet(bytes32 commit) external {

        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        address player = bet.player;

        require(amount != 0);
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

        bet.amount = 0;
        uint winAmount = getDiceWinAmount(amount, bet.roll, bet.lessThan);
        maxPendingPayouts = maxPendingPayouts.sub(winAmount);

        safeSendFunds(player, amount);

    }

    function settleUncle(bytes32 reveal,bytes32 uncleHash) onlyBanker external {
        bytes32 commit = keccak256(abi.encodePacked(reveal));

        Bet storage bet = bets[commit];

        settle(bet, reveal, uncleHash);
    }

    function settleBet(bytes32 reveal,bytes32 blockHash) external {


        bytes32 commit = keccak256(abi.encodePacked(reveal));

        Bet storage bet = bets[commit];

        uint placeBlockNumber = bet.placeBlockNumber;

        require(block.number > placeBlockNumber);
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS);


        if(blockhash(placeBlockNumber) != blockHash) { //the place bet in uncle block
            emit BlockHashVerifyFailed(commit);
            return;
        }

        settle(bet, reveal, blockHash);

    }

    function settle(Bet storage bet,bytes32 reveal,bytes32 blockHash) private {

        uint amount = bet.amount;
        uint8 roll = bet.roll;
        bool lessThan = bet.lessThan;
        address player = bet.player;

        require(amount != 0);


        bet.amount = 0;

        bytes32 seed = keccak256(abi.encodePacked(reveal, blockHash));

        uint dice = uint(seed) % 100 + 1;

        uint diceWinAmount = getDiceWinAmount(amount, roll, lessThan);


        maxPendingPayouts = maxPendingPayouts.sub(diceWinAmount);

        uint diceWin = 0;

        if ((lessThan && dice <= roll) || (!lessThan && dice >= roll)){ //win
            diceWin = diceWinAmount;
            safeSendFunds(player, diceWin);
        }

        bytes32 commit = keccak256(abi.encodePacked(reveal));

        emit LogResult(commit, player, roll,lessThan,  dice, amount, diceWin, diceWin == 0 ? 1 : 2, now);
    }

    function safeSendFunds(address beneficiary, uint amount) private {
        if (!beneficiary.send(amount)) {
            playerPendingWithdrawals[beneficiary] = playerPendingWithdrawals[beneficiary].add(amount);

        }
    }


    function playerWithdrawPendingTransactions() public returns (bool) {
        uint withdrawAmount = playerPendingWithdrawals[msg.sender];
        require(withdrawAmount > 0);
        playerPendingWithdrawals[msg.sender] = 0;
        if (msg.sender.call.value(withdrawAmount)()) {
            return true;
        } else {
            playerPendingWithdrawals[msg.sender] = withdrawAmount;
            return false;
        }
    }

    function pendingWithdrawalsBalance() public view returns (uint) {
        return playerPendingWithdrawals[msg.sender];
    }

    function inviteProfit(address _player) public view returns (uint) {
        return playerPendingWithdrawals[_player];
    }


    function houseWithdraw(uint amount) public onlyOwner {

        if (!owner.send(amount)) revert();

        emit LogHouseWithdraw(amount);
    }

    function ownerkill() public onlyOwner {
        selfdestruct(owner);
    }



}