pragma solidity ^0.5.1;


contract MemeAPI {
    
    event onTokenMint(
        address indexed userAddress,
        uint256 index,
        uint256 incomingEthereum,
        uint256 tokensMinted
    );

    event onTokenBurn(
        address indexed userAddress,
        uint256 index,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    modifier roundIsOver() {
        bool roundOver = roundOver();
        require(roundOver);
        _;
    }
    
    modifier roundOngoing() {
        bool roundOver = roundOver();
        require(!roundOver);
        _;
    }
    
    modifier onlyAdmin() {
        address user = msg.sender;
        require(administrators[user]);
        _;
    }
    
    uint256 constant internal roundLength = 3 minutes;
    uint256 constant internal tokenPriceInitial = 0.000001 ether;
    uint256 constant internal tokenPriceIncremental = 0.0000001 ether;
    uint256 constant internal magnitude = 2**64;
    
    mapping(address => bool) internal administrators;
    
    mapping(uint256 => Round) internal rounds;
    mapping(address => UserBalance) internal playerBalances;

    uint256 public roundNumber = 0;
    uint256 public roundEndTime = 0;
    
    uint256 internal maxIndex = 1;
    
    struct UserBalance {
        // round -> index == balance
        mapping(uint256 => mapping(uint256 => uint256)) balances;
        uint256 lastRound;
    }
    
    struct Round {
        uint256 winnings;
        mapping(uint256 => uint256) balancesByIndex;
        uint256 winner;
    }
    
    constructor()
        public
    {
        administrators[msg.sender] = true;
        
        startNextRound();
    }
    
    function getGameFee(uint256 etherPayed) 
        internal
        pure
        returns(uint256)
    {
        return SafeMath.div(etherPayed, 100);
    }
    
    function setMaxIndex(uint256 newMaxIndex)
        onlyAdmin
        public
    {
        require(newMaxIndex > 0);
        
        maxIndex = maxIndex;
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
        return buyPriceAtIndex(0);
    }
    
    function firstSellPrice() 
        public 
        view 
        returns (uint256)  
    {
        return sellPriceAtIndex(0);
    }
    
    function secondBuyPrice() 
        public 
        view 
        returns (uint256)  
    {
        return buyPriceAtIndex(0);
    }
    
    function secondSellPrice() 
        public 
        view 
        returns (uint256)  
    {
        return sellPriceAtIndex(1);
    }
    
    function buyPriceAtIndex(uint256 index)
        public
        view
        returns(uint256)
    {
        uint256 supply = supplyAtIndex(index);
        
        if (supply == 0) {
            return tokenPriceInitial + tokenPriceIncremental;
        } else {
            uint256 etherAmount = ethereumToTokens(1e18, supply);
            uint256 tax = getGameFee(etherAmount);
            uint256 taxedEthereum = SafeMath.add(etherAmount, tax);
            return taxedEthereum;
        }
    }

    function sellPriceAtIndex(uint256 index)
        public
        view
        returns(uint256)
    {
        uint256 supply = supplyAtIndex(index);
        
        if (supply == 0) {
            return tokenPriceInitial - tokenPriceIncremental;
        } else {
            uint256 etherAmount = tokensToEthereum(1e18, supply);
            uint256 tax = getGameFee(etherAmount);
            uint256 taxedEthereum = SafeMath.sub(etherAmount, tax);
            return taxedEthereum;
        }
    }
    
    function tokensToEthereum(uint256 tokens, uint256 supply)
        internal
        pure
        returns(uint256)
    {
        uint256 tokensPadded = (tokens + 1e18);
        uint256 etherReceived =
        (
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial
                            + 
                            (tokenPriceIncremental * ((supply + 1e18) / 1e18))
                        ) - tokenPriceIncremental
                    ) * (tokensPadded - 1e18)
                ),
                (tokenPriceIncremental * ((tokensPadded**2 - tokensPadded) / 1e18)) / 2
            )
            / 1e18
        );
        
        return etherReceived;
    }
    
    function firstBalance(address user) 
        public 
        view 
        returns (uint256)  
    {
        return balancesByIndex(0, user);
    }
    
    function secondBalance(address user) 
        public 
        view 
        returns (uint256)  
    {
        return balancesByIndex(1, user);
    }
    
    function balancesByIndex(uint256 index, address user) 
        public 
        view 
        returns (uint256)  
    {
        return playerBalances[user].balances[roundNumber][index];
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
        return rounds[roundNumber].winnings;
    }
    
    function roundOver() 
        public 
        view 
        returns (bool)  
    {
        return now >= roundEndTime;
    }
    
    function endRound() 
        roundIsOver
        public 
    {
        uint256 firstBalanceTotal = rounds[roundNumber].balancesByIndex[0];
        uint256 secondBalanceTotal = rounds[roundNumber].balancesByIndex[1];
        
        if (firstBalanceTotal == secondBalanceTotal) {
            roundEndTime = now + roundLength;
        } else {
            if (firstBalanceTotal > secondBalanceTotal) {
                rounds[roundNumber].winner = 0;
            } else {
                rounds[roundNumber].winner = 1;
            }
            
            startNextRound();
        }
    }
    
    function buyFirst()
        roundOngoing
        public
        payable
    {
        buyAtIndex(0);
    }
    
    function buyAtIndex(uint256 index)
        roundOngoing
        public
        payable
    {
        require(index <= maxIndex && index >= 0);
        
        address user = msg.sender;
        
        // if this is the first play this round, 
        // check if user is owed any money from previous rounds
        if (playerBalances[user].lastRound != roundNumber) {
            payday();
        }
        
        uint256 etherIn = msg.value;
        uint256 supply = supplyAtIndex(index);
        
        uint256 tax = getGameFee(etherIn);
        uint256 taxedEthereum = SafeMath.sub(etherIn, tax);
        uint256 tokens = ethereumToTokens(taxedEthereum, supply);

        require(tokens > 0 && (SafeMath.add(tokens, supply) > supply));

        // increase supply
        if (supply > 0) {
            rounds[roundNumber].balancesByIndex[index] = SafeMath.add(rounds[roundNumber].balancesByIndex[index], tokens);
        } else {
            rounds[roundNumber].balancesByIndex[index] = tokens;
        }
        
        // increase winnings
        uint256 winnings = rounds[roundNumber].winnings;
        if (winnings > 0) {
            rounds[roundNumber].winnings = SafeMath.add(rounds[roundNumber].winnings, taxedEthereum);
        } else {
            rounds[roundNumber].winnings = taxedEthereum;
        }

        // update user balance
        uint256 userBalance = playerBalances[user].balances[roundNumber][index];
        if (userBalance > 0) {
            playerBalances[user].balances[roundNumber][index] = SafeMath.add(userBalance, tokens);
        } else {
            playerBalances[user].balances[roundNumber][index] = tokens;
        }
        
        playerBalances[user].lastRound = roundNumber;
        
        emit onTokenMint(user, index, etherIn, tokens);
    }
    
    function supplyAtIndex(uint256 index) 
        internal
        view
        returns (uint256)
    {
        return rounds[roundNumber].balancesByIndex[index];
    }
    
    function ethereumToTokens(uint256 etherPayed, uint256 supply)
        internal
        pure
        returns(uint256)
    {
        uint256 tokenPriceInitialPadded = tokenPriceInitial * 1e18;
        uint256 tokensReceived = 
         (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            (tokenPriceInitialPadded**2)
                            +
                            (2 * (tokenPriceIncremental * 1e18)*(etherPayed * 1e18))
                            +
                            (((tokenPriceIncremental)**2) * (supply**2))
                            +
                            (2 * (tokenPriceIncremental) * tokenPriceInitialPadded * supply)
                        )
                    ), tokenPriceInitialPadded
                )
            ) / (tokenPriceIncremental)
        ) - (supply)
        ;
  
        return tokensReceived;
    }
    
    function sqrt(uint x)
        internal
        pure
        returns (uint y)
    {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function buySecond()
        roundOngoing
        public
        payable
    {
         buyAtIndex(1);
    }
    
    function sellAtIndex(uint256 index, uint256 amount)
        roundOngoing
        public
        payable
    {
        require(index <= maxIndex && index >= 0);
        
        address payable user = msg.sender;
        
        require(amount <= playerBalances[user].balances[roundNumber][index]);
        
        uint256 supply = supplyAtIndex(index);
        
        uint256 etherAmount = tokensToEthereum(amount, supply);
        uint256 tax = getGameFee(etherAmount);
        uint256 taxedEthereum = SafeMath.sub(etherAmount, tax);
        
        // burn the sold tokens
        rounds[roundNumber].balancesByIndex[index] = SafeMath.sub(supply, amount);
        
        // subtract from jackpot
        rounds[roundNumber].winnings = SafeMath.sub(rounds[roundNumber].winnings, taxedEthereum);
        
        // update user balances
        playerBalances[user].balances[roundNumber][index] = SafeMath.sub(playerBalances[user].balances[roundNumber][index], amount);

        if (taxedEthereum > 0) {
            user.transfer(taxedEthereum);
        }
        
        emit onTokenBurn(user, index, amount, taxedEthereum);
    }
    
    function sellFirst(uint256 amount)
        roundOngoing
        public
        payable
    {
        sellAtIndex(0, amount);
    }
    
    function sellSecond(uint256 amount)
        roundOngoing
        public
        payable
    {
        sellAtIndex(1, amount);
    }
    
    function payouts(address user) 
        public 
        view 
        returns (uint256)
    {
        uint256 lastRound = playerBalances[user].lastRound;
        if (lastRound != roundNumber) {
            uint256 winner = rounds[lastRound].winner;
            uint256 userTokenBalance = playerBalances[user].balances[lastRound][winner];
            uint256 winnerTotalSupply = rounds[lastRound].balancesByIndex[winner];
            uint256 winnings = rounds[lastRound].winnings;
            
            if (winnings > 0) {
                uint256 share = SafeMath.div(userTokenBalance, winnerTotalSupply);
                uint256 payoutsDue = SafeMath.mul(share, winnings);
    
                return payoutsDue;
            }
        }
        
        return 0;
    }
    
    function payday()
        public
    {
        address payable user = msg.sender;
        uint256 paymentDue = payouts(user);
        
        uint256 lastRound = playerBalances[user].lastRound;
        uint256 winner = rounds[lastRound].winner;
        playerBalances[user].balances[lastRound][winner] = 0;
        
        if (paymentDue > 0) {
            user.transfer(paymentDue);
        }
    }

    function getCurrentRoundInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            roundNumber,               // 0
            roundTimeRemaining(),      // 1
            roundTotalWinnings(),      // 2
            buyPriceAtIndex(0),        // 3
            sellPriceAtIndex(0),       // 4
            supplyAtIndex(0),          // 5
            buyPriceAtIndex(1),        // 6
            sellPriceAtIndex(1),       // 7
            supplyAtIndex(1)           // 8
        );
    }
    
    function getPlayerInfo(address user)
        public
        view
        returns (uint256, uint256, uint256)
    {
        return (
            balancesByIndex(0, user),        // 0
            balancesByIndex(1, user),        // 1
            payouts(user)                    // 2
        );
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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