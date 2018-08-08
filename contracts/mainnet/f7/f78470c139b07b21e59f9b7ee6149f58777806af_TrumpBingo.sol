pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract TrumpBingo {

    /* GLOBAL CONSTANTS */
    uint256 private minBid = 0.01 ether;
    uint256 private feePercent = 5;  // only charged from profits
    uint256 private jackpotPercent = 10;  // only charged from profits
    uint256 private startingCoownerPrice = 10 ether;

    /* ADMIN AREA */

    bool public paused;

    address public ceoAddress;
    address public feeAddress;
    address public feedAddress;

    modifier notPaused() {
        require(!paused);
        _;
    }

    modifier onlyFeed() {
        require(msg.sender == feedAddress);
        _;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setFeedAddress(address _newFeed) public onlyCEO {
        feedAddress = _newFeed;
    }

    function setFeeAddress(address _newFee) public onlyCEO {
        feeAddress = _newFee;
    }

    function pauseContract() public onlyCEO {
        paused = true;
    }

    function unpauseContract() public onlyCEO {
        paused = false;
    }

    /* PROFITS */

    mapping (address => uint256) private profits;

    function getProfits(address who) public view returns (uint256) {
        return profits[who];
    }

    function withdraw(address who) public {
        require(profits[who] > 0);
        uint256 amount = profits[who];
        profits[who] = 0;
        who.transfer(amount);
    }

    /* COOWNER MANAGEMENT */

    address public feeCoownerAddress;
    uint256 public coownerPrice;

    function becomeCoowner() public payable {
        if (msg.value < coownerPrice) {
            revert();
        }

        uint256 ourFee = coownerPrice / 10;
        uint256 profit = coownerPrice - ourFee;
        profits[feeCoownerAddress] += profit;
        profits[feeAddress] += ourFee;
        profits[msg.sender] += msg.value - coownerPrice;
        coownerPrice = coownerPrice * 3 / 2;
        feeCoownerAddress = msg.sender;
    }


    /* WORD MANAGEMENT */

    struct Word {
        string word;
        bool disabled;
    }


    event WordSetChanged();

    Word[] private words;
    mapping (string => uint256) private idByWord;

    function getWordCount() public view returns (uint) {
        return words.length;
     }

    function getWord(uint index) public view returns (string word,
                                                      bool disabled) {
        require(index < words.length);
        return (words[index].word, words[index].disabled);
    }

    function getWordIndex(string word) public view returns (uint) {
        return idByWord[word];
     }


    function addWord(string word) public onlyCEO {
        uint index = idByWord[word];
        require(index == 0);
        index = words.push(Word({word: word, disabled: false})) - 1;
        idByWord[word] = index;
        bids.length = words.length;
        WordSetChanged();
    }

    function delWord(string word) public onlyCEO {
        uint index = idByWord[word];
        require(index > 0);
        require(bids[index].bestBidder == address(0));
        idByWord[word] = 0;
        words[index].disabled = true;
        WordSetChanged();
    }

    /* WINNERS MANAGEMENT */
    uint public prevTweetTime;
    uint256 public prevRoundTweetId;
    struct WinnerInfo {
        address who;
        uint256 howMuch;
        uint256 wordId;
    }

    WinnerInfo[] private prevRoundWinners;
    uint private prevRoundWinnerCount;

    function getPrevRoundWinnerCount() public view returns (uint256 winnerCount)  {
        winnerCount = prevRoundWinnerCount;
    }

    function getPrevRoundWinner(uint i) public view returns (address who, uint256 howMuch, uint256 wordId) {
        who = prevRoundWinners[i].who;
        howMuch = prevRoundWinners[i].howMuch;
        wordId = prevRoundWinners[i].wordId;
    }

    function addWinner(address who, uint howMuch, uint wordId) private {
        ++prevRoundWinnerCount;
        if (prevRoundWinners.length < prevRoundWinnerCount) {
            prevRoundWinners.length = prevRoundWinnerCount;
        }
        prevRoundWinners[prevRoundWinnerCount - 1].who = who;
        prevRoundWinners[prevRoundWinnerCount - 1].howMuch = howMuch;
        prevRoundWinners[prevRoundWinnerCount - 1].wordId = wordId;
    }

    /* BIDS MANAGEMENT */
    struct Bid {
        uint256 cumValue;
        uint256 validRoundNo;
    }

    struct WordBids {
        mapping (address => Bid) totalBids;
        address bestBidder;
    }

    uint256 private curRound;
    WordBids[] private bids;

    uint256 private totalBank;
    uint256 private totalJackpot;

    function getJackpot() public view returns (uint256) {
        return totalJackpot;
    }

    function getBank() public view returns (uint256) {
        return totalBank;
    }

    function getBestBidder(uint256 wordIndex) public view returns (address, uint256) {
        return (bids[wordIndex].bestBidder, bids[wordIndex].totalBids[bids[wordIndex].bestBidder].cumValue);
    }

    function getBestBid(uint256 wordIndex) public view returns (uint256) {
        return bids[wordIndex].totalBids[bids[wordIndex].bestBidder].cumValue;
    }

    function getMinAllowedBid(uint256 wordIndex) public view returns (uint256) {
        return getBestBid(wordIndex) + minBid;
    }

    function getTotalBid(address who, uint256 wordIndex) public view returns (uint256) {
        if (bids[wordIndex].totalBids[who].validRoundNo != curRound) {
            return 0;
        }
        return bids[wordIndex].totalBids[who].cumValue;
    }

    function startNewRound() private {
        totalBank = 0;
        ++curRound;
        for (uint i = 0; i < bids.length; ++i) {
            bids[i].bestBidder = 0;
        }
    }

    event BestBidUpdate();

    function addBid(address who, uint wordIndex, uint256 value) private {
        if (bids[wordIndex].totalBids[who].validRoundNo != curRound) {
            bids[wordIndex].totalBids[who].cumValue = 0;
            bids[wordIndex].totalBids[who].validRoundNo = curRound;
        }

        uint256 newBid = value + bids[wordIndex].totalBids[who].cumValue;
        uint256 minAllowedBid = getMinAllowedBid(wordIndex);
        if (minAllowedBid > newBid) {
            revert();
        }

        bids[wordIndex].totalBids[who].cumValue = newBid;
        bids[wordIndex].bestBidder = who;
        totalBank += value;
        BestBidUpdate();
    }

    function calcPayouts(bool[] hasWon) private {
        uint256 totalWon;
        uint i;
        for (i = 0; i < words.length; ++i) {
            if (hasWon[i]) {
                totalWon += getBestBid(i);
            }
        }

        if (totalWon == 0) {
            totalJackpot += totalBank;
            return;
        }
        uint256 bank = totalJackpot / 2;
        totalJackpot -= bank;
        bank += totalBank;

        // charge only loosers
        uint256 fee = uint256(SafeMath.div(SafeMath.mul(bank - totalWon, feePercent), 100));
        bank -= fee;
        profits[feeAddress] += fee / 2;
        fee -= fee / 2;
        profits[feeCoownerAddress] += fee;

        uint256 jackpotFill = uint256(SafeMath.div(SafeMath.mul(bank - totalWon, jackpotPercent), 100));
        bank -= jackpotFill;
        totalJackpot += jackpotFill;

        for (i = 0; i < words.length; ++i) {
            if (hasWon[i] && bids[i].bestBidder != address(0)) {
                uint256 payout = uint256(SafeMath.div(SafeMath.mul(bank, getBestBid(i)), totalWon));
                profits[bids[i].bestBidder] += payout;
                addWinner(bids[i].bestBidder, payout, i);
            }
        }
    }

    function getPotentialProfit(address who, string word) public view returns
        (uint256 minNeededBid,
         uint256 expectedProfit) {

        uint index = idByWord[word];
        require(index > 0);

        uint currentBid = getTotalBid(who, index);
        address bestBidder;
        (bestBidder,) = getBestBidder(index);
        if (bestBidder != who) {
            minNeededBid = getMinAllowedBid(index) - currentBid;
        }

        uint256 bank = totalJackpot / 2;
        bank += totalBank;

        uint256 fee = uint256(SafeMath.div(SafeMath.mul(bank - currentBid, feePercent), 100));
        bank -= fee;

        uint256 jackpotFill = uint256(SafeMath.div(SafeMath.mul(bank - currentBid, jackpotPercent), 100));
        bank -= jackpotFill;

        expectedProfit = bank;
    }

    function bid(string word) public payable notPaused {
        uint index = idByWord[word];
        require(index > 0);
        addBid(msg.sender, index, msg.value);
    }

    /* FEED TRUMP TWEET */

    function hasSubstring(string haystack, string needle) private pure returns (bool) {
        uint needleSize = bytes(needle).length;
        bytes32 hash = keccak256(needle);
        for(uint i = 0; i < bytes(haystack).length - needleSize; i++) {
            bytes32 testHash;
            assembly {
                testHash := sha3(add(add(haystack, i), 32), needleSize)
            }
            if (hash == testHash)
                return true;
        }
        return false;
    }

    event RoundFinished();
    event NoBids();
    event NoBingoWords();

    function feedTweet(uint tweetTime, uint256 tweetId, string tweet) public onlyFeed notPaused {
        prevTweetTime = tweetTime;
        if (totalBank == 0) {
            NoBids();
            return;
        }

        bool[] memory hasWon = new bool[](words.length);
        bool anyWordPresent = false;
        for (uint i = 0; i < words.length; ++i) {
            hasWon[i] = (!words[i].disabled) && hasSubstring(tweet, words[i].word);
            if (hasWon[i]) {
                anyWordPresent = true;
            }
        }

        if (!anyWordPresent) {
            NoBingoWords();
            return;
        }

        prevRoundTweetId = tweetId;
        prevRoundWinnerCount = 0;
        calcPayouts(hasWon);
        RoundFinished();
        startNewRound();
    }

    /* CONSTRUCTOR */

    function TrumpBingo() public {
        ceoAddress = msg.sender;
        feeAddress = msg.sender;
        feedAddress = msg.sender;
        feeCoownerAddress = msg.sender;
        coownerPrice = startingCoownerPrice;

        paused = false;
        words.push(Word({word: "", disabled: true})); // fake &#39;0&#39; word
        startNewRound();
    }


}