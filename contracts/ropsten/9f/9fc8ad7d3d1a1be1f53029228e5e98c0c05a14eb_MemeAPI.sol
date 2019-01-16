pragma solidity ^0.5.1;


contract MemeAPI {
    
    modifier roundIsOver() {
        bool roundOver = roundOver();
        require(roundOver);
        _;
    }
    
    mapping(uint256 => uint256) internal roundWinnings;
    mapping(uint256 => uint256) internal winners;
    mapping(uint256 => mapping(uint256 => uint256)) internal roundBalances;
    mapping(address => mapping(uint256 => uint256)) internal firstBalances;
    mapping(address => mapping(uint256 => uint256)) internal secondBalances;
    
    mapping(address => mapping(uint256 => uint256)) internal userPayouts;
    mapping(address => uint256) internal lastUserRound;
    
    uint256 public roundNumber = 0;
    uint256 public roundEndTime = 0;
    uint256 constant internal roundLength = 3 minutes;
    
    constructor()
        public
    {
        startNextRound();
    }
    
    function startNextRound()
        internal
    {
        roundNumber = roundNumber + 1;
        roundEndTime = now + roundLength;
    }
    
    function firstBuyPrice() 
        public 
        view 
        returns (uint256)  
    {
        return 800000000000000000;
    }
    
    function firstSellPrice() 
        public 
        view 
        returns (uint256)  
    {
        return 1200000000000000000;
    }
    
    function secondBuyPrice() 
        public 
        view 
        returns (uint256)  
    {
        return 800000000000000000;
    }
    
    function secondSellPrice() 
        public 
        view 
        returns (uint256)  
    {
        return 1200000000000000000;
    }
    
    function firstBalance(address user) 
        public 
        view 
        returns (uint256)  
    {
        return firstBalances[user][roundNumber];
    }
    
    function secondBalance(address user) 
        public 
        view 
        returns (uint256)  
    {
        return secondBalances[user][roundNumber];
    }
    
    function roundTotalWinnings(address user) 
        public 
        view 
        returns (uint256)  
    {
        return roundWinnings[roundNumber];
    }
    
    function roundTimeRemaining() 
        public 
        view 
        returns (uint256)  
    {
        if (roundOver()) {
            return 0;
        } else {
            return roundEndTime - now;
        }
    }
    
    
    function roundTotalWinnings()
        public
        view 
        returns (uint256)
    {
        return roundWinnings[roundNumber];
    }
    
    function roundOver() 
        public 
        view 
        returns (bool)  
    {
        return now >= roundEndTime;
    }
    
    function endRound() 
        public 
        roundIsOver
    {
        uint256 firstBalanceTotal = roundBalances[roundNumber][0];
        uint256 secondBalanceTotal = roundBalances[roundNumber][1];
        
        if (firstBalanceTotal > secondBalanceTotal) {
            winners[roundNumber] = 0;
        } if (firstBalanceTotal > secondBalanceTotal) {
            winners[roundNumber] = 1;
        } else {
            winners[roundNumber] = 1;
        }
        
        startNextRound();
    }
    
    function buyFirst()
        public
        payable
    {
        uint256 etherIn = msg.value;
        address user = msg.sender;
        
        uint256 tokens = etherIn * firstBuyPrice();
        firstBalances[user][roundNumber] += tokens;
        
        roundBalances[roundNumber][0] += tokens;
        roundWinnings[roundNumber] += etherIn;
        
        lastUserRound[user] = roundNumber;
    }
    
    function buySecond()
        public
        payable
    {
        uint256 etherIn = msg.value;
        address user = msg.sender;
        
        uint256 tokens = etherIn * firstBuyPrice();
        secondBalances[user][roundNumber] += tokens;
        
        roundBalances[roundNumber][0] += tokens;
        roundWinnings[roundNumber] += etherIn;
        
        lastUserRound[user] = roundNumber;
    }
    
    function sellFirst(uint256 amount)
        public
        payable
    {
        address user = msg.sender;
        
        require(amount >= firstBalances[user][roundNumber]);
        
        firstBalances[user][roundNumber] -= amount;
        roundWinnings[roundNumber] -= amount / firstSellPrice();
    }
    
    function sellSecond(uint256 amount)
        public
        payable
    {
        address user = msg.sender;
        
        require(amount >= secondBalances[user][roundNumber]);
        
        secondBalances[user][roundNumber] -= amount;
        
        uint256 etherOwed = amount / secondSellPrice();
        roundWinnings[roundNumber] -= etherOwed;
        
        userPayouts[user][roundNumber] += etherOwed;
    }
    
    function payouts(address user) 
        public 
        view 
        returns (uint256)
    {
        uint256 lastRound = lastUserRound[user];
        uint256 winner = winners[lastRound];
        uint256 userTokenBalance = 0;
        if (winner == 0) {
            userTokenBalance = firstBalances[user][lastRound];
        } else {
            userTokenBalance = secondBalances[user][lastRound];
        }
        
        uint256 share = userTokenBalance / roundBalances[lastRound][winner];
        
        uint256 payoutsDue = share * roundWinnings[lastRound];
        
        return payoutsDue;
    }
    
    function payday()
        public
    {
        address payable user = msg.sender;
        uint256 paymentDue = payouts(user);
        
        uint256 lastRound = lastUserRound[user];
        uint256 winner = winners[lastRound];
        
        if (winner == 0) {
            firstBalances[user][lastRound] = 0;
        } else {
            secondBalances[user][lastRound] = 0;
        }
        
        if (paymentDue > 0) {
            user.transfer(paymentDue);
        }
    }
}