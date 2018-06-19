pragma solidity ^0.4.18;

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
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

contract TheWhaleWins {
    using SafeMath for uint256;

    address contractOwner;
    uint tokenStartPrice = 1 ether;
    uint tokenStartPrice2 = 1.483239697419133 ether;
    uint tokenPrice;
    uint tokenPrice2;
    address tokenOwner;
    address tokenOwner2;
    uint lastBuyBlock;
    uint newRoundDelay = 2500;

    address public richestPlayer;
    uint public highestPrice;

    uint public round;
    uint public flips;
    uint payoutRound;
    uint public richestRoundId;

    event Transfer(address indexed from, address indexed to, uint256 price);
    event NewRound(uint paidPrice, uint win, address winner);
    event RichestBonus(uint win, address richestPlayer);


    function TheWhaleWins() public {
        contractOwner = msg.sender;
        tokenOwner = address(0);
        lastBuyBlock = block.number; 
        tokenPrice = tokenStartPrice;
        tokenPrice2 = tokenStartPrice2;
    }

    function getRoundId() public view returns(uint) {
        return round*1000000+flips;
    }

    function startPrice(uint price) public {
      require(contractOwner == msg.sender);
      tokenStartPrice = price;
      tokenStartPrice2 = price * 1483239697419133 / 1000000000000000;
    }

    function changeNewRoundDelay(uint delay) public {
        require(contractOwner == msg.sender);
        newRoundDelay = delay;
    }
    function changeContractOwner(address newOwner) public {
        require(contractOwner == msg.sender);
        contractOwner = newOwner;
    }
    

    function buyToken() public payable {
        address currentOwner;
        uint256 currentPrice;
        uint256 paidTooMuch;
        uint256 payment;

        if (tokenPrice < tokenPrice2) {
            currentOwner = tokenOwner;
            currentPrice = tokenPrice;
            require(tokenOwner2 != msg.sender);
        } else {
            currentOwner = tokenOwner2;
            currentPrice = tokenPrice2;
            require(tokenOwner != msg.sender);
        }
        require(msg.value >= currentPrice);

        paidTooMuch = msg.value.sub(currentPrice);
        payment = currentPrice.div(2);

        if (tokenPrice < tokenPrice2) {
            tokenPrice = currentPrice.mul(110).div(50);
            tokenOwner = msg.sender;
        } else {
            tokenPrice2 = currentPrice.mul(110).div(50);
            tokenOwner2 = msg.sender;
        }
        lastBuyBlock = block.number;
        flips++;

        Transfer(currentOwner, msg.sender, currentPrice);

        if (currentOwner != address(0)) {
            payoutRound = getRoundId()-3;
            currentOwner.call.value(payment).gas(24000)();
        }
        if (paidTooMuch > 0)
            msg.sender.transfer(paidTooMuch);
    }

    function getBlocksToNextRound() public view returns(uint) {
        if (lastBuyBlock + newRoundDelay < block.number) {
            return 0;
        }
        return lastBuyBlock + newRoundDelay + 1 - block.number;
    }

    function getPool() public view returns(uint balance) {
        balance = this.balance;
    }

    function finishRound() public {
        require(tokenPrice > tokenStartPrice);
        require(lastBuyBlock + newRoundDelay < block.number);

        lastBuyBlock = block.number;
        address owner = tokenOwner;
        uint price = tokenPrice;
        if (tokenPrice2>tokenPrice) {
            owner = tokenOwner2;
            price = tokenPrice2;
        }
        uint lastPaidPrice = price.mul(50).div(110);
        uint win = this.balance - lastPaidPrice;

        if (highestPrice < lastPaidPrice) {
            richestPlayer = owner;
            highestPrice = lastPaidPrice;
            richestRoundId = getRoundId()-1;
        }

        tokenPrice = tokenStartPrice;
        tokenPrice2 = tokenStartPrice2;
        tokenOwner = address(0);
        tokenOwner2 = address(0);

        payoutRound = getRoundId()-1;
        flips = 0;
        round++;
        NewRound(lastPaidPrice, win / 2, owner);

        contractOwner.transfer((this.balance - (lastPaidPrice + win / 2) - win / 10) * 19 / 20);
        owner.call.value(lastPaidPrice + win / 2).gas(24000)();
        if (richestPlayer!=address(0)) {
            payoutRound = richestRoundId;
            RichestBonus(win / 10, richestPlayer);
            richestPlayer.call.value(win / 10).gas(24000)();
        }
    }

    function getPayoutRoundId() public view returns(uint) {
        return payoutRound;
    }
    function getPrice() public view returns(uint) {
        if (tokenPrice2<tokenPrice)
            return tokenPrice2;
        return tokenPrice;
    }

    function getCurrentData() public view returns (uint price, uint nextPrice, uint pool, address winner, address looser, bool canFinish, uint nextPool, uint win, uint nextWin) {
        winner = tokenOwner;
        looser = tokenOwner2;
        price = tokenPrice2;
        nextPrice = tokenPrice;
        if (tokenPrice2>tokenPrice) {
            winner = tokenOwner2;
            looser = tokenOwner;
            price = tokenPrice;
            nextPrice = tokenPrice2;
        }
        canFinish = (tokenPrice > tokenStartPrice) && (lastBuyBlock + newRoundDelay < block.number);
        pool = getPool();
        if (price == tokenStartPrice) {
            nextPool = pool + price;
            win = 0;
        } else if (price == tokenStartPrice2) {
            nextPool = pool + price;
            win = (pool-nextPrice.mul(50).div(110))/2;
        } else {
            nextPool = pool + price / 2;
            win = (pool-nextPrice.mul(50).div(110))/2;
        }
        nextWin = (nextPool-price)/2;
    }
}