pragma solidity ^0.4.25;

contract HexBoard3 {

  // To ease iteration
  uint8 constant public minTileId= 1;
  uint8 constant public maxTileId = 19;
  uint8 constant public numTiles = 19;

  // Any 0s in the neighbor array represent non-neighbors. There might be a better way to do this, but w/e
  mapping(uint8 => uint8[6]) public tileToNeighbors;
  uint8 constant public nullNeighborValue = 0;

  // TODO: Add neighbor calculation in if we want to use neighbors in jackpot calculation
  constructor() public {
  }
}

contract JackpotRules {
  using SafeMath for uint256;

  constructor() public {}

  // NOTE: The next methods *must* add up to 100%

  // 50%
  function _winnerJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(2);
  }

  // 40%
  function _landholderJackpot(uint256 jackpot) public pure returns (uint256) {
    return (jackpot.mul(2)).div(5);
  }

  // 5%
  function _nextPotJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(20);
  }

  // 5%
  function _teamJackpot(uint256 jackpot) public pure returns (uint256) {
    return jackpot.div(20);
  }
}

library Math {
  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
  * @dev Calculates the average of two numbers. Since these are integers,
  * averages of an even and odd number cannot be represented, and will be
  * rounded down.
  */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PullPayment {
    using SafeMath for uint256;

    mapping(address => uint256) public payments;
    uint256 public totalPayments;

    /**
     * @dev Withdraw accumulated balance, called by payee.
     */
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(address(this).balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        payee.transfer(payment);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function asyncSend(address dest, uint256 amount) internal {
        payments[dest] = payments[dest].add(amount);
        totalPayments = totalPayments.add(amount);
    }
}

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract TaxRules {
    using SafeMath for uint256;

    constructor() public {}

    // 10%
    function _priceToTax(uint256 price) public pure returns (uint256) {
        return price.div(10);
    }

    // NOTE: The next methods *must* add up to 100%

    // 40%
    function _jackpotTax(uint256 tax) public pure returns (uint256) {
        return (tax.mul(2)).div(5);
    }

    // 38%
    function _totalLandholderTax(uint256 tax) public pure returns (uint256) {
        return (tax.mul(19)).div(50);
    }

    // 17%/12%
    function _teamTax(uint256 tax, bool hasReferrer) public pure returns (uint256) {
        if (hasReferrer) {
            return (tax.mul(3)).div(25);
        } else {
            return (tax.mul(17)).div(100);
        }
    }
    
    // sell 25% of tokens
    function _p3dSellPercentage(uint256 tokens) public pure returns (uint256) {
        return tokens.div(4);
    }

    // 5% although only invoked if _teamTax is lower value
    function _referrerTax(uint256 tax, bool hasReferrer)  public pure returns (uint256) {
        if (hasReferrer) {
            return tax.div(20);
        } else {
            return 0;
        }
    }

    // 5%
    function _nextPotTax(uint256 tax) public pure returns (uint256) {
        return tax.div(20);
    }
}

contract Microverse is
    HexBoard3,
    PullPayment,
    Ownable,
    TaxRules,
    JackpotRules {
    using SafeMath for uint256;
    using Math for uint256;

    // states this contract progresses through
    enum Stage {
        DutchAuction,
        GameRounds
    }
    Stage public stage = Stage.DutchAuction;

    modifier atStage(Stage _stage) {
        require(
            stage == _stage,
            "Function cannot be called at this time."
        );
        _;
    }

    // NOTE: stage arg for debugging purposes only! Should just be set to 0 by default
    constructor(uint startingStage) public {
        if (startingStage == uint(Stage.GameRounds)) {
            stage = Stage.GameRounds;
            _startGameRound();
        } else {
            _startAuction();
        }
    }

    mapping(uint8 => address) public tileToOwner;
    mapping(uint8 => uint256) public tileToPrice;
    uint256 public totalTileValue;

    function _changeTilePrice(uint8 tileId, uint256 newPrice) private {
        uint256 oldPrice = tileToPrice[tileId];
        tileToPrice[tileId] = newPrice;
        totalTileValue = (totalTileValue.sub(oldPrice)).add(newPrice);
    }

    event TileOwnerChanged(
        uint8 indexed tileId,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 oldPrice,
        uint256 newPrice
    );

    /////////////
    // P3D stuff
    // RENT SEEKERS BTFO
    /////////////

    // the muscle behind growth
    HourglassInterface constant P3DContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    
    function _buyP3D(uint256 amount) private {
        P3DContract.buy.value(amount)(0x765a944008f08e8366c4ac4c88db63961f65be79);
    }
    
    function _sendP3D(address to, uint256 amount) private {
        P3DContract.transfer(to, amount);
    }
    
    function getP3DBalance() view public returns(uint256) {
        return (P3DContract.balanceOf(address(this)));
    }
    
    function getDivsBalance() view public returns(uint256) {
        return (P3DContract.dividendsOf(address(this)));
    }
    
    function withdrawContractBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableBalance = contractBalance.sub(totalPayments);

        // No withdrawal necessary if <= 0 balance
        require(withdrawableBalance > 0);

        asyncSend(msg.sender, withdrawableBalance);
    }

    //////////
    // Auction
    //////////

    event AuctionStarted(
        uint256 startingAuctionPrice,
        uint256 endingAuctionPrice,
        uint256 auctionDuration,
        uint256 startTime
    );

    event AuctionEnded(
        uint256 endTime
    );

    uint256 constant public startingAuctionPrice = 1 ether;
    uint256 constant public endingAuctionPrice = 0.05 ether;
    uint256 constant public auctionDuration = 5 days; // period over which land price decreases linearly

    uint256 public numBoughtTiles;
    uint256 public auctionStartTime;

    function buyTileAuction(uint8 tileId, uint256 newPrice, address referrer) public payable atStage(Stage.DutchAuction) {
        require(
            tileToOwner[tileId] == address(0) && tileToPrice[tileId] == 0,
            "Can&#39;t buy a tile that&#39;s already been auctioned off"
        );

        uint256 tax = _priceToTax(newPrice);
        uint256 price = getTilePriceAuction();

        require(
            msg.value >= tax.add(price),
            "Must pay the full price and tax for a tile on auction"
        );

        // NOTE: *entire* payment distributed as Game taxes
        _distributeAuctionTax(msg.value, referrer);

        tileToOwner[tileId] = msg.sender;
        _changeTilePrice(tileId, newPrice);

        numBoughtTiles = numBoughtTiles.add(1);

        emit TileOwnerChanged(tileId, address(0), msg.sender, price, newPrice);

        if (numBoughtTiles >= numTiles) {
            endAuction();
        }
    }

    // NOTE: Some common logic with _distributeTax
    function _distributeAuctionTax(uint256 tax, address referrer) private {
        _distributeLandholderTax(_totalLandholderTax(tax));

        // NOTE: Because no notion of &#39;current jackpot&#39;, everything added to next pot
        uint256 totalJackpotTax = _jackpotTax(tax).add(_nextPotTax(tax));
        nextJackpot = nextJackpot.add(totalJackpotTax);

        // NOTE: referrer tax comes out of p3d tax
        bool hasReferrer = referrer != address(0);
        _buyP3D(_teamTax(tax, hasReferrer));
        asyncSend(referrer, _referrerTax(tax, hasReferrer));
    }

    function getTilePriceAuction() public view atStage(Stage.DutchAuction) returns (uint256) {
        uint256 secondsPassed = 0;

        // This should always be the case...
        if (now > auctionStartTime) {
            secondsPassed = now.sub(auctionStartTime);
        }

        if (secondsPassed >= auctionDuration) {
            return endingAuctionPrice;
        } else {
            uint256 maxPriceDelta = startingAuctionPrice.sub(endingAuctionPrice);
            uint256 actualPriceDelta = (maxPriceDelta.mul(secondsPassed)).div(auctionDuration);

            return startingAuctionPrice.sub(actualPriceDelta);
        }
    }

    function endAuction() private {
        require(
            numBoughtTiles >= numTiles,
            "Can&#39;t end auction if are unbought tiles"
        );

        stage = Stage.GameRounds;
        _startGameRound();

        emit AuctionEnded(now);
    }

    function _startAuction() private {
        auctionStartTime = now;
        numBoughtTiles = 0;

        emit AuctionStarted(startingAuctionPrice,
                            endingAuctionPrice,
                            auctionDuration,
                            auctionStartTime);
    }

    ///////
    // Game
    ///////

    uint256 constant public startingRoundExtension = 12 hours;
    uint256 constant public halvingVolume = 10 ether; // tx volume before next duration halving
    uint256 constant public minRoundExtension = 10 seconds; // could set to 1 second

    uint256 public roundNumber = 0;

    uint256 public curExtensionVolume;
    uint256 public curRoundExtension;

    uint256 public roundEndTime;

    uint256 public jackpot;
    uint256 public nextJackpot;

    // Only emitted if owner doesn&#39;t *also* change
    event TilePriceChanged(
        uint8 indexed tileId,
        address indexed owner,
        uint256 oldPrice,
        uint256 newPrice
    );

    event GameRoundStarted(
        uint256 initJackpot,
        uint256 endTime,
        uint256 roundNumber
    );

    event GameRoundExtended(
        uint256 endTime
    );

    event GameRoundEnded(
        uint256 jackpot
    );

    ////////////////////////////////////
    // [Game] Round extension management
    ////////////////////////////////////

    function roundTimeRemaining() public view atStage(Stage.GameRounds) returns (uint256)  {
        if (_roundOver()) {
            return 0;
        } else {
            return roundEndTime.sub(now);
        }
    }

    function _extendRound() private {
        roundEndTime = roundEndTime.max(now.add(curRoundExtension));

        emit GameRoundExtended(roundEndTime);
    }

    function _startGameRound() private {
        curExtensionVolume = 0 ether;
        curRoundExtension = startingRoundExtension;

        jackpot = nextJackpot;
        nextJackpot = 0;

        roundNumber = roundNumber.add(1);

        _extendRound();

        emit GameRoundStarted(jackpot, roundEndTime, roundNumber);
    }

    function _roundOver() private view returns (bool) {
        return now >= roundEndTime;
    }

    modifier duringRound() {
        require(
            !_roundOver(),
            "Round can&#39;t be over!"
        );
        _;
    }

    // NOTE: Must be called for all volume we want to count towards round extension halving
    function _logRoundExtensionVolume(uint256 amount) private {
        curExtensionVolume = curExtensionVolume.add(amount);

        if (curExtensionVolume >= halvingVolume) {
            curRoundExtension = curRoundExtension.div(2).max(minRoundExtension);
            curExtensionVolume = 0 ether;
        }
    }

    ////////////////////////
    // [Game] Player actions
    ////////////////////////

    function endGameRound() public atStage(Stage.GameRounds) {
        require(
            _roundOver(),
            "Round must be over!"
        );

        _distributeJackpot();

        emit GameRoundEnded(jackpot);

        _startGameRound();
    }

    function setTilePrice(uint8 tileId, uint256 newPrice, address referrer)
        public
        payable
        atStage(Stage.GameRounds)
        duringRound {
        require(
            tileToOwner[tileId] == msg.sender,
            "Can&#39;t set tile price for a tile you don&#39;t own!"
        );

        uint256 tax = _priceToTax(newPrice);

        require(
            msg.value >= tax,
            "Must pay tax on new tile price!"
        );

        uint256 oldPrice = tileToPrice[tileId];
        _distributeTax(msg.value, referrer);
        _changeTilePrice(tileId, newPrice);

        // NOTE: Currently we extend round for &#39;every&#39; tile price change. Alternatively could do only on
        // increases or decreases or changes exceeding some magnitude
        _extendRound();
        _logRoundExtensionVolume(msg.value);

        emit TilePriceChanged(tileId, tileToOwner[tileId], oldPrice, newPrice);
    }

    function buyTile(uint8 tileId, uint256 newPrice, address referrer)
        public
        payable
        atStage(Stage.GameRounds)
        duringRound {
        address oldOwner = tileToOwner[tileId];
        require(
            oldOwner != msg.sender,
            "Can&#39;t buy a tile you already own"
        );

        uint256 tax = _priceToTax(newPrice);

        uint256 oldPrice = tileToPrice[tileId];
        require(
            msg.value >= tax.add(oldPrice),
            "Must pay full price and tax for tile"
        );

        // pay seller
        asyncSend(oldOwner, tileToPrice[tileId]);
        tileToOwner[tileId] = msg.sender;

        uint256 actualTax = msg.value.sub(oldPrice);
        _distributeTax(actualTax, referrer);

        _changeTilePrice(tileId, newPrice);
        _extendRound();
        _logRoundExtensionVolume(msg.value);

        emit TileOwnerChanged(tileId, oldOwner, msg.sender, oldPrice, newPrice);
    }

    ///////////////////////////////////////
    // [Game] Dividend/jackpot distribution
    ///////////////////////////////////////

    function _distributeJackpot() private {
        uint256 winnerJackpot = _winnerJackpot(jackpot);
        uint256 landholderJackpot = _landholderJackpot(jackpot);
        
        // get divs
        uint256 divs = getDivsBalance();
        if (divs > 0) {
            P3DContract.withdraw();
        }
        
        // add divs to landholderJackpot
        landholderJackpot = landholderJackpot + divs;
        
        _distributeWinnerAndLandholderJackpot(winnerJackpot, landholderJackpot);

        _buyP3D(_teamJackpot(jackpot));
        
        nextJackpot = nextJackpot.add(_nextPotJackpot(jackpot));
    }

    function _calculatePriceComplement(uint8 tileId) private view returns (uint256) {
        return totalTileValue.sub(tileToPrice[tileId]);
    }

    // NOTE: These are bundled together so that we only have to compute complements once
    function _distributeWinnerAndLandholderJackpot(uint256 winnerJackpot, uint256 landholderJackpot) private {
        uint256[] memory complements = new uint256[](numTiles + 1); // inc necessary b/c tiles are 1-indexed
        uint256 totalPriceComplement = 0;

        uint256 bestComplement = 0;
        uint8 lastWinningTileId = 0;
        for (uint8 i = minTileId; i <= maxTileId; i++) {
            uint256 priceComplement = _calculatePriceComplement(i);

            // update winner
            if (bestComplement == 0 || priceComplement > bestComplement) {
                bestComplement = priceComplement;
                lastWinningTileId = i;
            }

            complements[i] = priceComplement;
            totalPriceComplement = totalPriceComplement.add(priceComplement);
        }
        uint256 numWinners = 0;
        for (i = minTileId; i <= maxTileId; i++) {
            if (_calculatePriceComplement(i) == bestComplement) {
                numWinners++;
            }
        }
        
        // transfer some % P3D tokens to (why? see )
        uint256 p3dTokens = getP3DBalance();
    
        // distribute jackpot among all winners. save time on the majority (1-winner) case
        if (numWinners == 1) {
            asyncSend(tileToOwner[lastWinningTileId], winnerJackpot);
            
            if (p3dTokens > 0) {
                _sendP3D(tileToOwner[lastWinningTileId], _p3dSellPercentage(p3dTokens));
            }
        } else {
            for (i = minTileId; i <= maxTileId; i++) {
                if (_calculatePriceComplement(i) == bestComplement) {
                    asyncSend(tileToOwner[i], winnerJackpot.div(numWinners));
                    
                    if (p3dTokens > 0) {
                        _sendP3D(tileToOwner[i], _p3dSellPercentage(p3dTokens));
                    }
                }
            }
        }

        // distribute landholder things
        for (i = minTileId; i <= maxTileId; i++) {
            // NOTE: We don&#39;t exclude the jackpot winner(s) here, so the winner(s) is paid &#39;twice&#39;
            uint256 landholderAllocation = complements[i].mul(landholderJackpot).div(totalPriceComplement);

            asyncSend(tileToOwner[i], landholderAllocation);
        }
    }

    function _distributeTax(uint256 tax, address referrer) private {
        jackpot = jackpot.add(_jackpotTax(tax));

        _distributeLandholderTax(_totalLandholderTax(tax));
        nextJackpot = nextJackpot.add(_nextPotTax(tax));

        // NOTE: referrer tax comes out of p3d tax
        bool hasReferrer = referrer != address(0);
        _buyP3D(_teamTax(tax, hasReferrer));
        asyncSend(referrer, _referrerTax(tax, hasReferrer));
    }

    function _distributeLandholderTax(uint256 tax) private {
        for (uint8 tile = minTileId; tile <= maxTileId; tile++) {
            if (tileToOwner[tile] != address(0) && tileToPrice[tile] != 0) {
                uint256 tilePrice = tileToPrice[tile];
                uint256 allocation = tax.mul(tilePrice).div(totalTileValue);

                asyncSend(tileToOwner[tile], allocation);
            }
        }
    }
}

interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}