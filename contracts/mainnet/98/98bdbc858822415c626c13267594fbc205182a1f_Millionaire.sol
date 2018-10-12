pragma solidity ^0.4.24;

interface MilAuthInterface {
    function requiredSignatures() external view returns(uint256);
    function requiredDevSignatures() external view returns(uint256);
    function adminCount() external view returns(uint256);
    function devCount() external view returns(uint256);
    function adminName(address _who) external view returns(bytes32);
    function isAdmin(address _who) external view returns(bool);
    function isDev(address _who) external view returns(bool);
    function checkGameRegiester(address _gameAddr) external view returns(bool);
    function checkGameClosed(address _gameAddr) external view returns(bool);
}
interface MillionaireInterface {
    function invest(address _addr, uint256 _affID, uint256 _mfCoin, uint256 _general) external payable;
    function updateGenVaultAndMask(address _addr, uint256 _affID) external payable;
    function clearGenVaultAndMask(address _addr, uint256 _affID, uint256 _eth, uint256 _milFee) external;
    function assign(address _addr) external payable;
    function splitPot() external payable;   
}
interface MilFoldInterface {
    function addPot() external payable;
    function activate() external;    
}

contract Milevents {

    // fired whenever a player registers
    event onNewPlayer
    (
        address indexed playerAddress,
        uint256 playerID,
        uint256 timeStamp
    );

    // fired at end of buy or reload
    event onEndTx
    (
        uint256 rid,                    //current round id
        address indexed buyerAddress,   //buyer address
        uint256 compressData,           //action << 96 | time << 64 | drawCode << 32 | txAction << 8 | roundState
        uint256 eth,                    //buy amount
        uint256 totalPot,               //current total pot
        uint256 tickets,                //buy tickets
        uint256 timeStamp               //buy time
    );

    // fired at end of buy or reload
    event onGameClose
    (
        address indexed gameAddr,       //game address
        uint256 amount,                 //split eth amount
        uint256 timeStamp               //close time
    );

    // fired at time who satisfy the reward condition
    event onReward
    (
        address indexed         rewardAddr,     //reward address
        Mildatasets.RewardType  rewardType,     //rewardType
        uint256 amount                          //reward amount
    );

	// fired whenever theres a withdraw
    event onWithdraw
    (
        address indexed playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );

    event onAffiliatePayout
    (
        address indexed affiliateAddress,
        address indexed buyerAddress,
        uint256 eth,
        uint256 timeStamp
    );

    // fired at every ico
    event onICO
    (
        address indexed buyerAddress,   //user address who buy ico
        uint256 buyAmount,              //buy ico amount
        uint256 buyMf,                  //eth exchange mfcoin amount
        uint256 totalIco,               //now total ico amount
        bool    ended                   //is ico ended
    );

    // fired whenever an player win the playround
    event onPlayerWin(
        address indexed addr,
        uint256 roundID,
        uint256 winAmount,
        uint256 winNums
    );

    event onClaimWinner(
        address indexed addr,
        uint256 winnerNum,
        uint256 totalNum
    );

    event onBuyMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onSellMFCoins(
        address indexed addr,
        uint256 ethAmount,
        uint256 mfAmount,
        uint256 timeStamp
    );

    event onUpdateGenVault(
        address indexed addr,
        uint256 mfAmount,
        uint256 genAmount,
        uint256 ethAmount
    );
}

contract Millionaire is MillionaireInterface,Milevents {
    using SafeMath for *;
    using MFCoinsCalc for uint256;

//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    string  constant private    name_ = "Millionaire Official";
    uint256 constant private    icoRndMax_ = 2 weeks;        // ico max period
    uint256 private             icoEndtime_;                    // ico end time
    uint256 private             icoAmount_;                     // ico eth amount;
    uint256 private             sequence_;                      // affiliate id sequence
    bool    private             activated_;                     // mark contract is activated;
    bool    private             icoEnd_;                        // is ico ended;

    MilFoldInterface     public          milFold_;                       // milFold contract
    MilAuthInterface constant private milAuth_ = MilAuthInterface(0xf856f6a413f7756FfaF423aa2101b37E2B3aFFD9);

    uint256     public          globalMask_;                    // use to calc player gen
    uint256     public          mfCoinPool_;                    // MFCoin Pool
    uint256     public          totalSupply_;                   // MFCoin current supply

    address constant private fundAddr_ = 0xB0c7Dc00E8A74c9dEc8688EFb98CcB2e24584E3B; // foundation address
    uint256 constant private REGISTER_FEE = 0.01 ether;         // register affiliate fees
    uint256 constant private MAX_ICO_AMOUNT = 3000 ether;       // max tickets you can buy one time

    mapping(address => uint256) private balance_;               // player coin balance
    mapping(uint256 => address) private plyrAddr_;             // (id => address) returns player id by address
    mapping(address => Mildatasets.Player) private plyr_;      // (addr => data) player data

//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
//==============================================================================
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "its not ready start");
        _;
    }

    /**
     * @dev prevents contracts from interacting with Millionare
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 0.1 ether, "must > 0.1 ether");
        _;
    }

    /**
     * @dev check sender must be devs
     */
    modifier onlyDevs()
    {
        require(milAuth_.isDev(msg.sender) == true, "msg sender is not a dev");
        _;
    }

    /**
     * @dev default buy set to ico
     */
    function()
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        icoCore(msg.value);
    }

    /**
     * @dev buy MFCoin use eth in ico phase
     */
    function buyICO()
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        icoCore(msg.value);
    }

    function icoCore(uint256 _eth) private {
        if (icoEnd_) {
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
        } else {
            if (block.timestamp > icoEndtime_ || icoAmount_ >= MAX_ICO_AMOUNT) {
                plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
                icoEnd_ = true;

                milFold_.activate();
                emit onICO(msg.sender, 0, 0, MAX_ICO_AMOUNT, icoEnd_);
            } else {
                uint256 ethAmount = _eth;
                if (ethAmount + icoAmount_ > MAX_ICO_AMOUNT) {
                    ethAmount = MAX_ICO_AMOUNT.sub(icoAmount_);
                    plyr_[msg.sender].eth = _eth.sub(ethAmount);
                }
                icoAmount_ = icoAmount_.add(ethAmount);

                uint256 converts = ethAmount.mul(65)/100;
                uint256 pot = ethAmount.sub(converts);

                //65% of your eth use to convert MFCoin
                uint256 buytMf = buyMFCoins(msg.sender, converts);

                //35% of your eth use to pot
                milFold_.addPot.value(pot)();

                if (icoAmount_ >= MAX_ICO_AMOUNT) {
                    icoEnd_ = true;

                    milFold_.activate();
                }
                emit onICO(msg.sender, ethAmount, buytMf, icoAmount_, icoEnd_);
            }
        }
    }

    /**
     * @dev withdraw all you earnings to your address
     */
    function withdraw()
        public
        isActivated()
        isHuman()
    {
        updateGenVault(msg.sender);
        if (plyr_[msg.sender].eth > 0) {
            uint256 amount = plyr_[msg.sender].eth;
            plyr_[msg.sender].eth = 0;
            msg.sender.transfer(amount);
            emit onWithdraw(
                msg.sender,
                amount,
                block.timestamp
            );
        }
    }

    /**
     * @dev register as a affiliate
     */
    function registerAff()
        public
        isHuman()
        payable
    {
        require (msg.value >= REGISTER_FEE, "register affiliate fees must >= 0.01 ether");
        require (plyr_[msg.sender].playerID == 0, "you already register!");
        plyrAddr_[++sequence_] = msg.sender;
        plyr_[msg.sender].playerID = sequence_;
        fundAddr_.transfer(msg.value);
        emit onNewPlayer(msg.sender,sequence_, block.timestamp);
    }

    function setMilFold(address _milFoldAddr)
        public
        onlyDevs
    {
        require(address(milFold_) == 0, "milFold has been set");
        require(_milFoldAddr != 0, "milFold is invalid");

        milFold_ = MilFoldInterface(_milFoldAddr);
    }

    function activate()
        public
        onlyDevs
    {
        require(address(milFold_) != 0, "milFold has not been set");
        require(activated_ == false, "ICO already activated");

        // activate the ico
        activated_ = true;
        icoEndtime_ = block.timestamp + icoRndMax_;
    }

    /**
     * @dev external contracts interact with Millionare via investing MF Coin
     * @param _addr player&#39;s address
     * @param _affID affiliate ID
     * @param _mfCoin eth amount to buy MF Coin
     * @param _general eth amount assign to general
     */
    function invest(address _addr, uint256 _affID, uint256 _mfCoin, uint256 _general)
        external
        isActivated()
        payable
    {
        require(milAuth_.checkGameRegiester(msg.sender), "game no register");
        require(_mfCoin.add(_general) <= msg.value, "account is insufficient");

        if (msg.value > 0) {
            uint256 tmpAffID = 0;
            if (_affID == 0 || plyrAddr_[_affID] == _addr) {
                tmpAffID = plyr_[_addr].laff;
            } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
                plyr_[_addr].laff = _affID;
                tmpAffID = _affID;
            }
            
            // if affiliate not exist, assign affiliate to general, i.e. set affiliate to zero
            uint256 _affiliate = msg.value.sub(_mfCoin).sub(_general);
            if (tmpAffID > 0 && _affiliate > 0) {
                address affAddr = plyrAddr_[tmpAffID];
                plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(_affiliate);
                plyr_[affAddr].eth = plyr_[affAddr].eth.add(_affiliate);
                emit onAffiliatePayout(affAddr, _addr, _affiliate, block.timestamp);
            }

            if (totalSupply_ > 0) {
                uint256 delta = _general.mul(1 ether).div(totalSupply_);
                globalMask_ = globalMask_.add(delta);
            } else {
                //if nobody hold MFCoin,so nobody get general,it will give foundation
                fundAddr_.transfer(_general);
            }

            updateGenVault(_addr);
            
            buyMFCoins(_addr, _mfCoin);

            emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
        }
    }

    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarnings(address _addr)
        private
        view
        returns(uint256)
    {
        uint256 diffMask = globalMask_.sub(plyr_[_addr].mask);
        if (diffMask > 0) {
            return diffMask.mul(balance_[_addr]).div(1 ether);
        }
    }

    /**
     * @dev updates masks for round and player when keys are bought
     */
    function updateGenVaultAndMask(address _addr, uint256 _affID)
        external
        payable
    {
        require(msg.sender == address(milFold_), "no authrity");

        if (msg.value > 0) {
            /**
             * 50/80 use to convert MFCoin
             * 10/80 use to affiliate
             * 20/80 use to general
             */
            uint256 converts = msg.value.mul(50).div(80);

            uint256 tmpAffID = 0;
            if (_affID == 0 || plyrAddr_[_affID] == _addr) {
                tmpAffID = plyr_[_addr].laff;
            } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
                plyr_[_addr].laff = _affID;
                tmpAffID = _affID;
            }
            uint256 affAmount = 0;
            if (tmpAffID > 0) {
                affAmount = msg.value.mul(10).div(80);
                address affAddr = plyrAddr_[tmpAffID];
                plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(affAmount);
                plyr_[affAddr].eth = plyr_[affAddr].eth.add(affAmount);
                emit onAffiliatePayout(affAddr, _addr, affAmount, block.timestamp);
            }
            if (totalSupply_ > 0) {
                uint256 delta = msg.value.sub(converts).sub(affAmount).mul(1 ether).div(totalSupply_);
                globalMask_ = globalMask_.add(delta);
            } else {
                //if nobody hold MFCoin,so nobody get general,it will give foundation
                fundAddr_.transfer(msg.value.sub(converts).sub(affAmount));
            }
            
            updateGenVault(_addr);
            
            buyMFCoins(_addr, converts);

            emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
        }
    }

    /**
     * @dev game contract has been paid 20% amount for Millionaire and paid back now
     */
    function clearGenVaultAndMask(address _addr, uint256 _affID, uint256 _eth, uint256 _milFee)
        external
    {
        require(msg.sender == address(milFold_), "no authrity");

        //check player eth balance is enough pay for
        uint256 _earnings = calcUnMaskedEarnings(_addr);
        require(plyr_[_addr].eth.add(_earnings) >= _eth, "eth balance not enough");
        
        /**
         * 50/80 use to convert MFCoin
         * 10/80 use to affiliate
         * 20/80 use to general
         */
        uint256 converts = _milFee.mul(50).div(80);
        
        uint256 tmpAffID = 0;
        if (_affID == 0 || plyrAddr_[_affID] == _addr) {
            tmpAffID = plyr_[_addr].laff;
        } else if (plyr_[_addr].laff == 0 && plyrAddr_[_affID] != address(0)) {
            plyr_[_addr].laff = _affID;
            tmpAffID = _affID;
        }
        
        uint256 affAmount = 0;
        if (tmpAffID > 0) {
            affAmount = _milFee.mul(10).div(80);
            address affAddr = plyrAddr_[tmpAffID];
            plyr_[affAddr].affTotal = plyr_[affAddr].affTotal.add(affAmount);
            plyr_[affAddr].eth = plyr_[affAddr].eth.add(affAmount);

            emit onAffiliatePayout(affAddr, _addr, affAmount, block.timestamp);
        }
        if (totalSupply_ > 0) {
            uint256 delta = _milFee.sub(converts).sub(affAmount).mul(1 ether).div(totalSupply_);
            globalMask_ = globalMask_.add(delta);
        } else {
            //if nobody hold MFCoin,so nobody get general,it will give foundation
            fundAddr_.transfer(_milFee.sub(converts).sub(affAmount));
        }

        updateGenVault(_addr);
        
        buyMFCoins(_addr,converts);

        plyr_[_addr].eth = plyr_[_addr].eth.sub(_eth);
        milFold_.addPot.value(_eth.sub(_milFee))();

        emit onUpdateGenVault(_addr, balance_[_addr], plyr_[_addr].genTotal, plyr_[_addr].eth);
    }


    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(address _addr) private
    {
        uint256 _earnings = calcUnMaskedEarnings(_addr);
        if (_earnings > 0) {
            plyr_[_addr].mask = globalMask_;
            plyr_[_addr].genTotal = plyr_[_addr].genTotal.add(_earnings);
            plyr_[_addr].eth = plyr_[_addr].eth.add(_earnings);
        } else if (globalMask_ > plyr_[_addr].mask) {
            plyr_[_addr].mask = globalMask_;
        }
        
    }
    
    /**
     * @dev convert eth to coin
     * @param _addr user address
     * @return return back coins
     */
    function buyMFCoins(address _addr, uint256 _eth) private returns(uint256) {
        uint256 _coins = calcCoinsReceived(_eth);
        mfCoinPool_ = mfCoinPool_.add(_eth);
        totalSupply_ = totalSupply_.add(_coins);
        balance_[_addr] = balance_[_addr].add(_coins);

        emit onBuyMFCoins(_addr, _eth, _coins, now);
        return _coins;
    }

    /**
     * @dev sell coin to eth
     * @param _coins sell coins
     * @return return back eth
     */
    function sellMFCoins(uint256 _coins) public {
        require(icoEnd_, "ico phase not end");
        require(balance_[msg.sender] >= _coins, "coins amount is out of range");

        updateGenVault(msg.sender);
        
        uint256 _eth = totalSupply_.ethRec(_coins);
        mfCoinPool_ = mfCoinPool_.sub(_eth);
        totalSupply_ = totalSupply_.sub(_coins);
        balance_[msg.sender] = balance_[msg.sender].sub(_coins);

        if (milAuth_.checkGameClosed(address(milFold_))) {
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(_eth);
        } else {
            /**
             * 10/100 transfer to pot
             * 90/100 transfer to owner
             */
            uint256 earnAmount = _eth.mul(90).div(100);
            plyr_[msg.sender].eth = plyr_[msg.sender].eth.add(earnAmount);
    
            milFold_.addPot.value(_eth.sub(earnAmount))();
        }
        
        emit onSellMFCoins(msg.sender, earnAmount, _coins, now);
    }

    /**
     * @dev anyone winner of milfold will call this function
     * @param _addr winner address
     */
    function assign(address _addr)
        external
        payable
    {
        require(msg.sender == address(milFold_), "no authrity");

        plyr_[_addr].eth = plyr_[_addr].eth.add(msg.value);
    }

    /**
     * @dev If unfortunate the game has problem or has no winner at long time, we&#39;ll end the game and divide the pot equally among all MF users
     */
    function splitPot()
        external
        payable
    {
        require(milAuth_.checkGameClosed(msg.sender), "game has not been closed");
        
        uint256 delta = msg.value.mul(1 ether).div(totalSupply_);
        globalMask_ = globalMask_.add(delta);
        emit onGameClose(msg.sender, msg.value, now);
    }

    /**
     * @dev returns ico info
     * @return ico end time
     * @return already ico summary
     * @return ico phase is end
     */
    function getIcoInfo()
        public
        view
        returns(uint256, uint256, bool) {
        return (icoAmount_, icoEndtime_, icoEnd_);
    }

    /**
     * @dev returns player info based on address
     * @param _addr address of the player you want to lookup
     * @return player ID
     * @return player eth balance
     * @return player MFCoin
     * @return general vault
     * @return affiliate vault
     */
    function getPlayerAccount(address _addr)
        public
        isActivated()
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        uint256 genAmount = calcUnMaskedEarnings(_addr);
        return (
            plyr_[_addr].playerID,
            plyr_[_addr].eth.add(genAmount),
            balance_[_addr],
            plyr_[_addr].genTotal.add(genAmount),
            plyr_[_addr].affTotal
        );
    }

    /**
     * @dev give _eth can convert how much MFCoin
     * @param _eth eth i will give
     * @return MFCoin will return back
     */
    function calcCoinsReceived(uint256 _eth)
        public
        view
        returns(uint256)
    {
        return mfCoinPool_.keysRec(_eth);
    }

    /**
     * @dev returns current eth price for X coins.
     * @param _coins number of coins desired (in 18 decimal format)
     * @return amount of eth needed to send
     */
    function calcEthReceived(uint256 _coins)
        public
        view
        returns(uint256)
    {
        if (totalSupply_ < _coins) {
            return 0;
        }
        return totalSupply_.ethRec(_coins);
    }

    function getMFBalance(address _addr)
        public
        view
        returns(uint256) {
        return balance_[_addr];
    }

}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library Mildatasets {

    // between `DRAWN&#39; and `ASSIGNED&#39;, someone need to claim winners.
    enum RoundState {
        UNKNOWN,        // aim to differ from normal states
        STARTED,        // start current round
        STOPPED,        // stop current round
        DRAWN,          // draw code
        ASSIGNED        // assign to foundation, winners, and migrate the rest to the next round
    }

    // MilFold Transaction Action.
    enum TxAction {
        UNKNOWN,        // default
        BUY,            // buy or reload tickets and so on 
        DRAW,           // draw code of game 
        ASSIGN,         // assign to winners
        ENDROUND        // end game and start new round
    }

    // RewardType
    enum RewardType {
        UNKNOWN,        // default
        DRAW,           // draw code
        ASSIGN,         // assign winner
        END,            // end game
        CLIAM           // winner cliam
    }

    struct Player {
        uint256 playerID;       // Player id(use to affiliate other player)
        uint256 eth;            // player eth balance
        uint256 mask;           // player mask
        uint256 genTotal;       // general total vault
        uint256 affTotal;       // affiliate total vault
        uint256 laff;           // last affiliate id used
    }

    struct Round {
        uint256                         roundDeadline;      // deadline to end round
        uint256                         claimDeadline;      // deadline to claim winners
        uint256                         pot;                // pot
        uint256                         blockNumber;        // draw block number(last one)
        RoundState                      state;              // round state
        uint256                         drawCode;           // draw code
        uint256                         totalNum;           // total number
        mapping (address => uint256)    winnerNum;          // winners&#39; number
        address[]                       winners;            // winners
    }

}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
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
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

    /**
     * @dev x to the power of y
     */
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}

//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================
library MFCoinsCalc {
    using SafeMath for *;
    /**
     * @dev calculates number of keys received given X eth
     * @param _curEth current amount of eth in contract
     * @param _newEth eth being spent
     * @return amount of ticket purchased
     */
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }

    /**
     * @dev calculates amount of eth received if you sold X keys
     * @param _curKeys current amount of keys that exist
     * @param _sellKeys amount of keys you wish to sell
     * @return amount of eth received
     */
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /**
     * @dev calculates how many keys would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _eth)
        internal
        pure
        returns(uint256)
    {
        return (((((_eth).mul(1000000000000000000).mul(2000000000000000000000000000)).add(39999800000250000000000000000000000000000000000000000000000000000)).sqrt()).sub(199999500000000000000000000000000)) / (1000000000);
    }

    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys "in contract"
     * @return eth that would exists
     */
    function eth(uint256 _keys)
        internal
        pure
        returns(uint256)
    {
        return ((500000000).mul(_keys.sq()).add(((399999000000000).mul(_keys.mul(1000000000000000000))) / (2) )) / ((1000000000000000000).sq());
    }
}