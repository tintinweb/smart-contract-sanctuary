pragma solidity ^0.5.1;


contract Faceoff {
    
    modifier onlyTokenHolders() {
        address userAddress = msg.sender; 
        require(firstBalances[userAddress] + secondBalances[userAddress] > 0);
        _; 
    }
    
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
    
    string public name = "Head2Head";
    string public symbol = "H2H";
    uint8 constant public decimals = 18;
    
    uint256 constant internal tokenPriceInitial = 0.0001 ether;
    uint256 constant internal tokenPriceIncremental = 0.00001 ether;
    
    uint256 constant internal magnitude = 2**64;
    
    uint8 constant internal gameFee = 1;
    
    mapping(address => bool) internal administrators;
    
    mapping(address => uint256) internal firstBalances;
    mapping(address => uint256) internal secondBalances;
    
    mapping(address => int256) internal firstPayouts;
    mapping(address => int256) internal secondPayouts;
    
    uint256 public firstTokenSupply = 0;
    uint256 public secondTokenSupply = 0;
    
    uint256 public firstProfitPerShare = 0;
    uint256 public secondProfitPerShare = 0;
    
    constructor() 
        public 
    {
        administrators[0xF416D2D8F2739Ca7CF6d05e2b4aD509FAfc42f78] = true;
    }
    
    function()
        payable
        external
    {
        
    }
    
    function buyFirst()
        payable
        public
    {
        purchaseFirstTokens(msg.value);
    }
    
    function purchaseFirstTokens(uint256 etherPayed)
        internal
        returns(uint256)
    {
        address userAddress = msg.sender;
        uint256 tax = SafeMath.div(etherPayed, gameFee);
        uint256 taxedEthereum = SafeMath.sub(etherPayed, tax);
        uint256 tokens = ethereumToTokens(taxedEthereum, firstTokenSupply);

        require(tokens > 0 && (SafeMath.add(tokens, firstTokenSupply) > firstTokenSupply));
        
        // increase supply
        if (firstTokenSupply > 0) {
            firstTokenSupply = SafeMath.add(firstTokenSupply, tokens);
        } else {
            firstTokenSupply = tokens;
        }
        
        // update user balance
        firstBalances[userAddress] = SafeMath.add(firstBalances[userAddress], tokens);
        
        // fire event
        emit onTokenMint(userAddress, 0, etherPayed, tokens);
        
        return tokens;
    }
    
    function ethereumToTokens(uint256 etherPayed, uint256 supply)
        internal
        view
        returns(uint256)
    {
        // wei used to prevent underflow
        uint256 tokenPriceInitialWei = tokenPriceInitial * 1e18;
        uint256 tokenPriceIncrementalWei = tokenPriceIncremental * 1e18;
        uint256 etherPayedWei = etherPayed * 1e18;
        
        uint256 tokens = 
         (
            (
                SafeMath.sub(
                    (sqrt
                        (
                            (supply**2) * tokenPriceIncremental
                            +
                            (2*(etherPayedWei)*(tokenPriceIncrementalWei))
                            +
                            (2*(supply)*(tokenPriceIncrementalWei))*(tokenPriceInitialWei)
                            +
                            (tokenPriceInitialWei**2)
                        )
                    ), tokenPriceInitialWei
                )
            )/(tokenPriceIncremental)
        )-(supply);
  
        return tokens;
    }
    
    function tokensToEthereum(uint256 tokens, uint256 supply)
        internal
        view
        returns(uint256)
    {
        // prevent underflow
        uint256 tokensWei = (tokens + 1e18);
        uint256 supplyWei = (supply + 1e18);
        uint256 etherReceived =
            SafeMath.sub(
                SafeMath.add(
                    tokensWei*tokenPriceInitial, 
                    tokensWei*tokenPriceInitial*supply/1e18
                ),
                ((tokensWei**2)*tokenPriceInitial)/2
            )/1e18;
        return etherReceived;
    }
    
    function firstTotalSupply()
        public
        view
        returns(uint256)
    {
        return firstTokenSupply;
    }
    
    function firstBuyPrice() 
        public 
        view 
        returns(uint256)
    {
        if (firstTokenSupply == 0) {
            return tokenPriceInitial + tokenPriceIncremental;
        } else {
            uint256 etherAmount = tokensToEthereum(1e18, firstTokenSupply);
            uint256 tax = SafeMath.div(etherAmount, gameFee);
            uint256 taxedEthereum = SafeMath.add(etherAmount, tax);
            return taxedEthereum;
        }
    }
    
    function firstSellPrice() 
        public 
        view 
        returns(uint256)
    {
        if (firstTokenSupply == 0) {
            return tokenPriceInitial - tokenPriceIncremental;
        } else {
            uint256 etherAmount = tokensToEthereum(1e18, firstTokenSupply);
            uint256 tax = SafeMath.div(etherAmount, gameFee);
            uint256 taxedEthereum = SafeMath.sub(etherAmount, tax);
            return taxedEthereum;
        }
    }
    
    function secondTotalSupply()
        public
        view
        returns(uint256)
    {
        return secondTokenSupply;
    }
    
    function firstBalanceOf(address userAddress)
        view
        public
        returns(uint256)
    {
        return firstBalances[userAddress];
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