pragma solidity ^0.4.24;

/**
 *
 *                                ...........       ...........
 *                           .....                              t...
 *                          TT..                                  ..T.
 *                       TUx.                                        .TT
 *                       .XtTT......                          ....TTtXXT
 *                        UT..  ....                                 XU.
 *                        Tt .                                      TUX.
 *                        TXT..                  ..                .UU.
 *                        .UU T.                 ....              TXT
 *                         tX...                   T.. .           UX.
 *                         TXT..      .             ......        .UU
 *                         TUU..     TT.           ..    ..       TXx
 *                         xtUT..     ....uUXUXXUT...    ..       UXT
 *                          Utx .       TXUXXXXXUXU. .....       .UU
 *                          tUt .       XXtTXUUXuUXU      .      TXx
 *                          TXt..       XX .tXT. uXX   ....      UXT
 *                          uUUT .      TX.     .XXX.   ..  . . .XUx
 *                           Utx .T.  . .X...... XUXu      .... .XTx
 *                           uxu ..xT. TXT        XUXt.   . .   TXT.
 *                           Txt . TXXUXT .        UXXXt        tXt.
 *                           uUx  XUXXXUXUXx      XUUUXUXT... . Uxx
 *                            Xt  .XUXUXXXX.  .x.tUXUXXXXT.Tu.  .Tu
 *                            tx.  .XxXXt.  .  x............x. ..TX.
 *                            TT.....  .  .txt x   rm-rf/  .x.. .Tt
 *                            xTT. ... . TUUU..x ...........x.. .Tt
 *                             xT........ .UXTTTT.TTxTTTTTTut...Tx
 *                             ttt..........xTTxTTTuxxuxTTTTTu. Tt
 *                             uUt........  .................. .T
 *                              Xxtt........     ....    . ....Tt
 *                               xxuU... .     .       . . tttUu
 *                                 UTuut                uuuUu..
 *                                   T...................TT..
 *
 *
 *
 * @title CCCosmos SAT
 *  
 * The only official website: https://cccosmos.com
 * 
 *     CCCosmos is a game Dapp that runs on Ethereum. The mode of smart contract makes it run in a decentralized way. 
 * Code logic prevents any others&#39; control and keep the game fun, fair, and feasible. Unlike most DApps that require a browser
 * plug-in, the well-designed CCCosmos can easily help you win great bonuses via any decentralized Ethereum wallet 
 * on your phone.
 *   
 *                                        ///Game Description///
 * # The first-time user can activate his/her Ethereum address by just paying an amount more than 0.01eth.
 * 
 * # The contract will automatically calculate the user&#39;s SAT account according to the price, and may immediately 
 * receive up to seven-fold rewards.
 * 
 * # Holding SAT brings users continuous earnings; if you are the last one to get SAT at the end of the game, you 
 * will win the huge sum in the final pot!
 * 
 * # Final Prize
 * As the game countdown ends, the last SAT buyer will win the Final Pot.
 * 
 * # Early Birds
 * Whenever a player buys SAT, the SAT price goes up; the early birds would get rich earnings.
 * 
 * # Late Surprise
 * SAT buyers will have the chance to win multiplied rewards in betting; later users may win more eths.
 * 
 * # Be Dealers
 * The top three users holding the most SATs are dealers who will continuously receive dealer funds for the day.
 * 
 * # Happy Ending
 * After the game is over, all users will divide up the whole prize pot to win bonuses, and then a new round of 
 * game starts.
 * 
 *                                              ///Rules///
 * 1. The countdown to the end is initially set to be 24 hours. Whenever a user buys a SAT, the remaining time will 
 * be extended by 30 seconds; but the total extension will not exceed 24 hours.
 * 
 * 2. Any amount of eth a user transfers to the contract address, with 0.01 eth deducted for activation fee, can be 
 * used to buy SAT. The remaining sum of SAT can be checked in any Ethereum wallet.
 * 
 * 3. The initial SAT price is 0.000088eth, and the price will increase by 0.000000002eth for every SAT purchased.
 * 
 * 4. All eths the users spent on SAT are put into the prize pot, 50% of which enters the Share Pot, 20% the Final 
 * Pot, 25.5% the Lucky Pot, and the rest 4.5% the Dealer Pot.
 * 
 * 5. When users transfer a certain amount of SAT to the contract address, the corresponding response function 
 * will be triggered and then the transferred SAT will be refunded in full.
 * 
 *    # To get all the eth gains earned at your address by transferring back 0.08 SAT.
 * 
 *    # To make an instant re-investment and buy SAT with all eth gains earned at your address by transferring 
 *      back 0.01 SAT.
 * 
 *    # After the game is over, you can get all the eth gains earned at your address by transferring back any 
 *      amount of SAT.
 * 
 *    # The average withdrawal rate is less than 7.5% and decreases as the total SAT issuance increases. When the 
 *      SAT price reaches 0.1eth, zero-fee is charged!
 * 
 * 6. Users have a 50% chance to get instant rewards in different proportions, maximally seven-fold, after they buy 
 * SAT immediately.! (The maximum amount of the rewards cannot exceed 1/2 of the current lucky pot.)
 * 
 *                             Probability of Winning Rewards
 * 
 *                          Reward ratio           probability
 *                               10%                   30%
 *                               20%                   10%
 *                               50%                   5%
 *                               100%                  3%
 *                               300%                  2%
 *                               700%                  1%
 * 
 * 7. Users can log into cccosmos.com to check the earnings and get other detailed information.
 * 
 * 8. The top three Ethereum addresses with the most SAT purchase for the day will divide up the present Dealer 
 *    Fund!
 * 
 * 9. One month after the game ends, the unclaimed eths will be automatically transferred to the CCCosmos 
 *    Developer Fund for subsequent development and services.
 */

/**
 * @title SafeMath
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
}

/**
 * @title Ownable
 * @dev https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

/**
 * @title Saturn
 * @dev The Saturn token.
 */
contract Saturn is Ownable {
    using SafeMath for uint256;

    struct Player {
        uint256 pid; // player ID, start with 1
        uint256 ethTotal; // total buy amount in ETH
        uint256 ethBalance; // the ETH balance which can be withdraw
        uint256 ethWithdraw; // total eth which has already been withdrawn by player
        uint256 ethShareWithdraw; // total shared pot which has already been withdrawn by player
        uint256 tokenBalance; // token balance
        uint256 tokenDay; // the day which player last buy
        uint256 tokenDayBalance; // the token balance for last day
    }

    struct LuckyRecord {
        address player; // player address
        uint256 amount; // lucky reward amount
        uint64 txId; // tx ID
        uint64 time; // lucky reward time
        // lucky reward level.
        // reward amount: 1: 700%, 2: 300%, 3: 100%, 4: 50%, 5: 20%, 6: 10%
        // reward chance: 1: 1%, 2: 2%, 3: 3%, 4: 5%, 5: 10%, 6: 30%
        uint64 level;
    }

    // Keep lucky player which is pending for reward after next block
    struct LuckyPending {
        address player; // player address
        uint256 amount; // player total eth for this tx
        uint64 txId; // tx id
        uint64 block; // current block number
        uint64 level; // lucky level
    }

    struct InternalBuyEvent {
        // flag1
        // 0 - new player (bool)
        // 1-20 - tx ID
        // 21-31 - finish time
        // 32-46 - dealer1 ID
        // 47-61 - dealer2 ID
        // 62-76 - dealer3 ID
        uint256 flag1;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Buy(
        address indexed _token, address indexed _player, uint256 _amount, uint256 _total,
        uint256 _totalSupply, uint256 _totalPot, uint256 _sharePot, uint256 _finalPot, uint256 _luckyPot,
        uint256 _price, uint256 _flag1
    );
    event Withdraw(address indexed _token, address indexed _player, uint256 _amount);
    event Win(address indexed _token, address indexed _winner, uint256 _winAmount);

    string constant public name = "Saturn";
    string constant public symbol = "SAT";
    uint8 constant public decimals = 18;

    uint256 constant private FEE_REGISTER_ACCOUNT = 10 finney; // register fee per player
    uint256 constant private BUY_AMOUNT_MIN = 1000000000; // buy token minimal ETH
    uint256 constant private BUY_AMOUNT_MAX = 100000000000000000000000; // buy token maximal ETH
    uint256 constant private TIME_DURATION_INCREASE = 30 seconds; // time increased by each token
    uint256 constant private TIME_DURATION_MAX = 24 hours; // max duration for game
    uint256 constant private ONE_TOKEN = 1000000000000000000; // one token which is 10^18

    mapping(address => Player) public playerOf; // player address => player info
    mapping(uint256 => address) public playerIdOf; // player id => player address
    uint256 public playerCount; // total player

    uint256 public totalSupply; // token total supply

    uint256 public totalPot; // total eth which players bought
    uint256 public sharePot; // shared pot for all players
    uint256 public finalPot; // final win pot for winner (last player)
    uint256 public luckyPot; // lucky pot based on random number.

    uint64 public txCount; // total transaction
    uint256 public finishTime; // game finish time. It will be set startTime+24 hours when activate the contract.
    uint256 public startTime; // the game is activated when now>=startTime.

    address public lastPlayer; // last player which by at least one key.
    address public winner; // winner for final pot.
    uint256 public winAmount; // win amount for winner, which will be final pot.

    uint256 public price; // token price

    address[3] public dealers; // top 3 token owners for daily. Dealers will be reset every midnight (00:00) UTC&#177;00:00
    uint256 public dealerDay; // The midnight time in UTC&#177;00:00 which last player bought the token (without hour, minute, second)

    LuckyPending[] public luckyPendings;
    uint256 public luckyPendingIndex;
    LuckyRecord[] public luckyRecords; // The lucky player history.

    address public feeOwner; // fee owner. all fee will be send to this address.
    uint256 public feeAmount; // current fee amount. new fee will be added to it.

    // withdraw fee price levels.
    uint64[16] public feePrices = [uint64(88000000000000),140664279921934,224845905067685,359406674201608,574496375292119,918308169866219,1467876789325690,2346338995279770,3750523695724810,5995053579423660,9582839714125510,15317764181758900,24484798507285300,39137915352965200,62560303190573500,99999999999999100];
    // withdraw fee percent. if feePrices[i]<=current price<feePrices[i + 1], then the withdraw fee will be (feePercents[i]/1000)*withdrawAmount
    uint8[16] public feePercents = [uint8(150),140,130,120,110,100,90,80,70,60,50,40,30,20,10,0];
    // current withdraw fee index. it will be updated when player buy token
    uint256 public feeIndex;

    /**
    * @dev Init the contract with fee owner. the game is not ready before activate function is called.
    * Token total supply will be 0.
    */
    constructor(uint256 _startTime, address _feeOwner) public {
        require(_startTime >= now && _feeOwner != address(0));
        startTime = _startTime;
        finishTime = _startTime + TIME_DURATION_MAX;
        totalSupply = 0;
        price = 88000000000000;
        feeOwner = _feeOwner;
        owner = msg.sender;
    }

    /**
     * @dev Throws if game is not ready
     */
    modifier isActivated() {
        require(now >= startTime);
        _;
    }

    /**
     * @dev Throws if sender is not account (contract etc.).
     * This is not 100% guarantee that the caller is account (ie after account abstraction is implemented), but it is good enough.
     */
    modifier isAccount() {
        address _address = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_address)}
        require(_codeLength == 0 && tx.origin == msg.sender);
        _;
    }

    /**
     * @dev Token balance for player
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return playerOf[_owner].tokenBalance;
    }

    /**
     * @dev Get lucky pending size
     */
    function getLuckyPendingSize() public view returns (uint256) {
        return luckyPendings.length;
    }
    /**
     * @dev Get lucky record size
     */
    function getLuckyRecordSize() public view returns (uint256) {
        return luckyRecords.length;
    }

    /**
     * @dev Get the game info
     */
    function getGameInfo() public view returns (
        uint256 _balance, uint256 _totalPot, uint256 _sharePot, uint256 _finalPot, uint256 _luckyPot, uint256 _rewardPot, uint256 _price,
        uint256 _totalSupply, uint256 _now, uint256 _timeLeft, address _winner, uint256 _winAmount, uint8 _feePercent
    ) {
        _balance = address(this).balance;
        _totalPot = totalPot;
        _sharePot = sharePot;
        _finalPot = finalPot;
        _luckyPot = luckyPot;
        _rewardPot = _sharePot;
        uint256 _withdraw = _sharePot.add(_finalPot).add(_luckyPot);
        if (_totalPot > _withdraw) {
            _rewardPot = _rewardPot.add(_totalPot.sub(_withdraw));
        }
        _price = price;
        _totalSupply = totalSupply;
        _now = now;
        _feePercent = feeIndex >= feePercents.length ? 0 : feePercents[feeIndex];
        if (now < finishTime) {
            _timeLeft = finishTime - now;
        } else {
            _timeLeft = 0;
            _winner = winner != address(0) ? winner : lastPlayer;
            _winAmount = winner != address(0) ? winAmount : finalPot;
        }
    }

    /**
     * @dev Get the player info by address
     */
    function getPlayerInfo(address _playerAddress) public view returns (
        uint256 _pid, uint256 _ethTotal, uint256 _ethBalance, uint256 _ethWithdraw,
        uint256 _tokenBalance, uint256 _tokenDayBalance
    ) {
        Player storage _player = playerOf[_playerAddress];
        if (_player.pid > 0) {
            _pid = _player.pid;
            _ethTotal = _player.ethTotal;
            uint256 _sharePot = _player.tokenBalance.mul(sharePot).div(totalSupply); // all share pot the player will get.
            _ethBalance = _player.ethBalance;
            if (_sharePot > _player.ethShareWithdraw) {
                _ethBalance = _ethBalance.add(_sharePot.sub(_player.ethShareWithdraw));
            }
            _ethWithdraw = _player.ethWithdraw;
            _tokenBalance = _player.tokenBalance;
            uint256 _day = (now / 86400) * 86400;
            if (_player.tokenDay == _day) {
                _tokenDayBalance = _player.tokenDayBalance;
            }
        }
    }

    /**
     * @dev Get dealer and lucky records
     */
    function getDealerAndLuckyInfo(uint256 _luckyOffset) public view returns (
        address[3] _dealerPlayers, uint256[3] _dealerDayTokens, uint256[3] _dealerTotalTokens,
        address[5] _luckyPlayers, uint256[5] _luckyAmounts, uint256[5] _luckyLevels, uint256[5] _luckyTimes
    ) {
        uint256 _day = (now / 86400) * 86400;
        if (dealerDay == _day) {
            for (uint256 _i = 0; _i < 3; ++_i) {
                if (dealers[_i] != address(0)) {
                    Player storage _player = playerOf[dealers[_i]];
                    _dealerPlayers[_i] = dealers[_i];
                    _dealerDayTokens[_i] = _player.tokenDayBalance;
                    _dealerTotalTokens[_i] = _player.tokenBalance;
                }
            }
        }
        uint256 _size = _luckyOffset >= luckyRecords.length ? 0 : luckyRecords.length - _luckyOffset;
        if (_luckyPlayers.length < _size) {
            _size = _luckyPlayers.length;
        }
        for (_i = 0; _i < _size; ++_i) {
            LuckyRecord memory _record = luckyRecords[luckyRecords.length - _luckyOffset - 1 - _i];
            _luckyPlayers[_i] = _record.player;
            _luckyAmounts[_i] = _record.amount;
            _luckyLevels[_i] = _record.level;
            _luckyTimes[_i] = _record.time;
        }
    }

    /**
    * @dev Withdraw the balance and share pot.
    *
    * Override ERC20 transfer token function. This token is not allowed to transfer between players.
    * So the _to address must be the contract address.
    * 1. When game already finished: Player can send any amount of token to contract, and the contract will send the eth balance and share pot to player.
    * 2. When game is not finished yet:
    *    A. Withdraw. Player send 0.08 Token to contract, and the contract will send the eth balance and share pot to player.
    *    B. ReBuy. Player send 0.01 Token to contract, then player&#39;s eth balance and share pot will be used to buy token.
    *    C. Invalid. Other value is invalid.
    * @param _to address The address which you want to transfer/sell to. MUST be contract address.
    * @param _value uint256 the amount of tokens to be transferred/sold.
    */
    function transfer(address _to, uint256 _value) isActivated isAccount public returns (bool) {
        require(_to == address(this));
        Player storage _player = playerOf[msg.sender];
        require(_player.pid > 0);
        if (now >= finishTime) {
            if (winner == address(0)) {
                // If the endGame is not called, then call it.
                endGame();
            }
            // Player want to withdraw.
            _value = 80000000000000000;
        } else {
            // Only withdraw or rebuy allowed.
            require(_value == 80000000000000000 || _value == 10000000000000000);
        }
        uint256 _sharePot = _player.tokenBalance.mul(sharePot).div(totalSupply); // all share pot the player will get.
        uint256 _eth = 0;
        // the total share pot need to sub amount which already be withdrawn by player.
        if (_sharePot > _player.ethShareWithdraw) {
            _eth = _sharePot.sub(_player.ethShareWithdraw);
            _player.ethShareWithdraw = _sharePot;
        }
        // add the player&#39;s eth balance
        _eth = _eth.add(_player.ethBalance);
        _player.ethBalance = 0;
        _player.ethWithdraw = _player.ethWithdraw.add(_eth);
        if (_value == 80000000000000000) {
            // Player want to withdraw
            // Calculate fee based on price level.
            uint256 _fee = _eth.mul(feeIndex >= feePercents.length ? 0 : feePercents[feeIndex]).div(1000);
            if (_fee > 0) {
                feeAmount = feeAmount.add(_fee);
                _eth = _eth.sub(_fee);
            }
            sendFeeIfAvailable();
            msg.sender.transfer(_eth);
            emit Withdraw(_to, msg.sender, _eth);
            emit Transfer(msg.sender, _to, 0);
        } else {
            // Player want to rebuy token
            InternalBuyEvent memory _buyEvent = InternalBuyEvent({
                flag1: 0
                });
            buy(_player, _buyEvent, _eth);
        }
        return true;
    }

    /**
    * @dev Buy token using ETH
    * Player sends ETH to this contract, then his token balance will be increased based on price.
    * The total supply will also be increased.
    * Player need 0.01 ETH register fee to register this address (first time buy).
    * The buy amount need between 0.000000001ETH and 100000ETH
    */
    function() isActivated isAccount payable public {
        uint256 _eth = msg.value;
        require(now < finishTime);
        InternalBuyEvent memory _buyEvent = InternalBuyEvent({
            flag1: 0
            });
        Player storage _player = playerOf[msg.sender];
        if (_player.pid == 0) {
            // Register the player, make sure the eth is enough.
            require(_eth >= FEE_REGISTER_ACCOUNT);
            // Reward player BUY_AMOUNT_MIN for register. So the final register fee will be FEE_REGISTER_ACCOUNT-BUY_AMOUNT_MIN
            uint256 _fee = FEE_REGISTER_ACCOUNT.sub(BUY_AMOUNT_MIN);
            _eth = _eth.sub(_fee);
            // The register fee will go to fee owner
            feeAmount = feeAmount.add(_fee);
            playerCount = playerCount.add(1);
            Player memory _p = Player({
                pid: playerCount,
                ethTotal: 0,
                ethBalance: 0,
                ethWithdraw: 0,
                ethShareWithdraw: 0,
                tokenBalance: 0,
                tokenDay: 0,
                tokenDayBalance: 0
                });
            playerOf[msg.sender] = _p;
            playerIdOf[_p.pid] = msg.sender;
            _player = playerOf[msg.sender];
            // The player is newly register first time.
            _buyEvent.flag1 += 1;
        }
        buy(_player, _buyEvent, _eth);
    }

    /**
     * @dev Buy the token
     */
    function buy(Player storage _player, InternalBuyEvent memory _buyEvent, uint256 _amount) private {
        require(now < finishTime && _amount >= BUY_AMOUNT_MIN && _amount <= BUY_AMOUNT_MAX);
        // Calculate the midnight
        uint256 _day = (now / 86400) * 86400;
        uint256 _backEth = 0;
        uint256 _eth = _amount;
        if (totalPot < 200000000000000000000) {
            // If the totalPot<200ETH, we are allow to buy 5ETH each time.
            if (_eth >= 5000000000000000000) {
                // the other eth will add to player&#39;s ethBalance
                _backEth = _eth.sub(5000000000000000000);
                _eth = 5000000000000000000;
            }
        }
        txCount = txCount + 1; // do not need use safe math
        _buyEvent.flag1 += txCount * 10; // do not need use safe math
        _player.ethTotal = _player.ethTotal.add(_eth);
        totalPot = totalPot.add(_eth);
        // Calculate the new total supply based on totalPot
        uint256 _newTotalSupply = calculateTotalSupply(totalPot);
        // The player will get the token with totalSupply delta
        uint256 _tokenAmount = _newTotalSupply.sub(totalSupply);
        _player.tokenBalance = _player.tokenBalance.add(_tokenAmount);
        // If the player buy token before today, then add the tokenDayBalance.
        // otherwise reset tokenDayBalance
        if (_player.tokenDay == _day) {
            _player.tokenDayBalance = _player.tokenDayBalance.add(_tokenAmount);
        } else {
            _player.tokenDay = _day;
            _player.tokenDayBalance = _tokenAmount;
        }
        // Update the token price by new total supply
        updatePrice(_newTotalSupply);
        handlePot(_day, _eth, _newTotalSupply, _tokenAmount, _player, _buyEvent);
        if (_backEth > 0) {
            _player.ethBalance = _player.ethBalance.add(_backEth);
        }
        sendFeeIfAvailable();
        emitEndTxEvents(_eth, _tokenAmount, _buyEvent);
    }

    /**
     * @dev Handle the pot (share, final, lucky and dealer)
     */
    function handlePot(uint256 _day, uint256 _eth, uint256 _newTotalSupply, uint256 _tokenAmount, Player storage _player, InternalBuyEvent memory _buyEvent) private {
        uint256 _sharePotDelta = _eth.div(2); // share pot: 50%
        uint256 _finalPotDelta = _eth.div(5); // final pot: 20%;
        uint256 _luckyPotDelta = _eth.mul(255).div(1000); // lucky pot: 25.5%;
        uint256 _dealerPotDelta = _eth.sub(_sharePotDelta).sub(_finalPotDelta).sub(_luckyPotDelta); // dealer pot: 4.5%
        sharePot = sharePot.add(_sharePotDelta);
        finalPot = finalPot.add(_finalPotDelta);
        luckyPot = luckyPot.add(_luckyPotDelta);
        totalSupply = _newTotalSupply;
        handleDealerPot(_day, _dealerPotDelta, _player, _buyEvent);
        handleLuckyPot(_eth, _player);
        // The player need to buy at least one token to change the finish time and last player.
        if (_tokenAmount >= ONE_TOKEN) {
            updateFinishTime(_tokenAmount);
            lastPlayer = msg.sender;
        }
        _buyEvent.flag1 += finishTime * 1000000000000000000000; // do not need use safe math
    }

    /**
     * @dev Handle lucky pot. The player can lucky pot by random number. The maximum amount will be half of total lucky pot
     * The lucky reward will be added to player&#39;s eth balance
     */
    function handleLuckyPot(uint256 _eth, Player storage _player) private {
        uint256 _seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
                (block.number)
            )));
        _seed = _seed - ((_seed / 1000) * 1000);
        uint64 _level = 0;
        if (_seed < 227) { // 22.7%
            _level = 1;
        } else if (_seed < 422) { // 19.5%
            _level = 2;
        } else if (_seed < 519) { // 9.7%
            _level = 3;
        } else if (_seed < 600) { // 8.1%
            _level = 4;
        } else if (_seed < 700) { // 10%
            _level = 5;
        } else {  // 30%
            _level = 6;
        }
        if (_level >= 5) {
            // if level is 5 and 6, we will reward immediately
            handleLuckyReward(txCount, _level, _eth, _player);
        } else {
            // otherwise we will save it for next block to check if it is reward or not
            LuckyPending memory _pending = LuckyPending({
                player: msg.sender,
                amount: _eth,
                txId: txCount,
                block: uint64(block.number + 1),
                level: _level
                });
            luckyPendings.push(_pending);
        }
        // handle the pending lucky reward
        handleLuckyPending(_level >= 5 ? 0 : 1);
    }

    function handleLuckyPending(uint256 _pendingSkipSize) private {
        if (luckyPendingIndex < luckyPendings.length - _pendingSkipSize) {
            LuckyPending storage _pending = luckyPendings[luckyPendingIndex];
            if (_pending.block <= block.number) {
                uint256 _seed = uint256(keccak256(abi.encodePacked(
                        (block.timestamp).add
                        (block.difficulty).add
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
                        (block.gaslimit).add
                        (block.number)
                    )));
                _seed = _seed - ((_seed / 1000) * 1000);
                handleLucyPendingForOne(_pending, _seed);
                if (luckyPendingIndex < luckyPendings.length - _pendingSkipSize) {
                    _pending = luckyPendings[luckyPendingIndex];
                    if (_pending.block <= block.number) {
                        handleLucyPendingForOne(_pending, _seed);
                    }
                }
            }
        }
    }

    function handleLucyPendingForOne(LuckyPending storage _pending, uint256 _seed) private {
        luckyPendingIndex = luckyPendingIndex.add(1);
        bool _reward = false;
        if (_pending.level == 4) {
            _reward = _seed < 617;
        } else if (_pending.level == 3) {
            _reward = _seed < 309;
        } else if (_pending.level == 2) {
            _reward = _seed < 102;
        } else if (_pending.level == 1) {
            _reward = _seed < 44;
        }
        if (_reward) {
            handleLuckyReward(_pending.txId, _pending.level, _pending.amount, playerOf[_pending.player]);
        }
    }

    function handleLuckyReward(uint64 _txId, uint64 _level, uint256 _eth, Player storage _player) private {
        uint256 _amount;
        if (_level == 1) {
            _amount = _eth.mul(7); // 700%
        } else if (_level == 2) {
            _amount = _eth.mul(3); // 300%
        } else if (_level == 3) {
            _amount = _eth;        // 100%
        } else if (_level == 4) {
            _amount = _eth.div(2); // 50%
        } else if (_level == 5) {
            _amount = _eth.div(5); // 20%
        } else if (_level == 6) {
            _amount = _eth.div(10); // 10%
        }
        uint256 _maxPot = luckyPot.div(2);
        if (_amount > _maxPot) {
            _amount = _maxPot;
        }
        luckyPot = luckyPot.sub(_amount);
        _player.ethBalance = _player.ethBalance.add(_amount);
        LuckyRecord memory _record = LuckyRecord({
            player: msg.sender,
            amount: _amount,
            txId: _txId,
            level: _level,
            time: uint64(now)
            });
        luckyRecords.push(_record);
    }

    /**
     * @dev Handle dealer pot. The top 3 of total day token (daily) will get dealer reward.
     * The dealer reward will be added to player&#39;s eth balance
     */
    function handleDealerPot(uint256 _day, uint256 _dealerPotDelta, Player storage _player, InternalBuyEvent memory _buyEvent) private {
        uint256 _potUnit = _dealerPotDelta.div(dealers.length);
        // If this is the first buy in today, then reset the dealers info.
        if (dealerDay != _day || dealers[0] == address(0)) {
            dealerDay = _day;
            dealers[0] = msg.sender;
            dealers[1] = address(0);
            dealers[2] = address(0);
            _player.ethBalance = _player.ethBalance.add(_potUnit);
            feeAmount = feeAmount.add(_dealerPotDelta.sub(_potUnit));
            _buyEvent.flag1 += _player.pid * 100000000000000000000000000000000; // do not need safe math
            return;
        }
        // Sort the dealers info by daily token balance.
        for (uint256 _i = 0; _i < dealers.length; ++_i) {
            if (dealers[_i] == address(0)) {
                dealers[_i] = msg.sender;
                break;
            }
            if (dealers[_i] == msg.sender) {
                break;
            }
            Player storage _dealer = playerOf[dealers[_i]];
            if (_dealer.tokenDayBalance < _player.tokenDayBalance) {
                for (uint256 _j = dealers.length - 1; _j > _i; --_j) {
                    if (dealers[_j - 1] != msg.sender) {
                        dealers[_j] = dealers[_j - 1];
                    }
                }
                dealers[_i] = msg.sender;
                break;
            }
        }
        // the all dealers share the dealer reward.
        uint256 _fee = _dealerPotDelta;
        for (_i = 0; _i < dealers.length; ++_i) {
            if (dealers[_i] == address(0)) {
                break;
            }
            _dealer = playerOf[dealers[_i]];
            _dealer.ethBalance = _dealer.ethBalance.add(_potUnit);
            _fee = _fee.sub(_potUnit);
            _buyEvent.flag1 += _dealer.pid *
            (_i == 0 ? 100000000000000000000000000000000 :
            (_i == 1 ? 100000000000000000000000000000000000000000000000 :
            (_i == 2 ? 100000000000000000000000000000000000000000000000000000000000000 : 0))); // do not need safe math, only keep top 3 dealers ID
        }
        if (_fee > 0) {
            feeAmount = feeAmount.add(_fee);
        }
    }

    function emitEndTxEvents(uint256 _eth, uint256 _tokenAmount, InternalBuyEvent memory _buyEvent) private {
        emit Transfer(address(this), msg.sender, _tokenAmount);
        emit Buy(
            address(this), msg.sender, _eth, _tokenAmount,
            totalSupply, totalPot, sharePot, finalPot, luckyPot,
            price, _buyEvent.flag1
        );
    }

    /**
     * @dev End the game.
     */
    function endGame() private {
        // The fee owner will get the lucky pot, because no player will allow to buy the token.
        if (luckyPot > 0) {
            feeAmount = feeAmount.add(luckyPot);
            luckyPot = 0;
        }
        // Set the winner information if it is not set.
        // The winner reward will go to winner eth balance.
        if (winner == address(0) && lastPlayer != address(0)) {
            winner = lastPlayer;
            lastPlayer = address(0);
            winAmount = finalPot;
            finalPot = 0;
            Player storage _player = playerOf[winner];
            _player.ethBalance = _player.ethBalance.add(winAmount);
            emit Win(address(this), winner, winAmount);
        }
    }

    /**
     * @dev Update the finish time. each token will increase 30 seconds, up to 24 hours
     */
    function updateFinishTime(uint256 _tokenAmount) private {
        uint256 _timeDelta = _tokenAmount.div(ONE_TOKEN).mul(TIME_DURATION_INCREASE);
        uint256 _finishTime = finishTime.add(_timeDelta);
        uint256 _maxTime = now.add(TIME_DURATION_MAX);
        finishTime = _finishTime <= _maxTime ? _finishTime : _maxTime;
    }

    function updatePrice(uint256 _newTotalSupply) private {
        price = _newTotalSupply.mul(2).div(10000000000).add(88000000000000);
        uint256 _idx = feeIndex + 1;
        while (_idx < feePrices.length && price >= feePrices[_idx]) {
            feeIndex = _idx;
            ++_idx;
        }
    }

    function calculateTotalSupply(uint256 _newTotalPot) private pure returns(uint256) {
        return _newTotalPot.mul(10000000000000000000000000000)
        .add(193600000000000000000000000000000000000000000000)
        .sqrt()
        .sub(440000000000000000000000);
    }

    function sendFeeIfAvailable() private {
        if (feeAmount > 1000000000000000000) {
            feeOwner.transfer(feeAmount);
            feeAmount = 0;
        }
    }

    /**
    * @dev Change the fee owner.
    *
    * @param _feeOwner The new fee owner.
    */
    function changeFeeOwner(address _feeOwner) onlyOwner public {
        require(_feeOwner != feeOwner && _feeOwner != address(0));
        feeOwner = _feeOwner;
    }

    /**
    * @dev Withdraw the fee. The owner can withdraw the money after 30 days of game finish.
    * This prevents the money is not locked in this contract.
    * Player can contact the contract owner to get back money if the money is withdrawn.
    * @param _amount The amount which will be withdrawn.
    */
    function withdrawFee(uint256 _amount) onlyOwner public {
        require(now >= finishTime.add(30 days));
        if (winner == address(0)) {
            endGame();
        }
        feeAmount = feeAmount > _amount ? feeAmount.sub(_amount) : 0;
        feeOwner.transfer(_amount);
    }

}