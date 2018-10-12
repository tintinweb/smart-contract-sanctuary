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

contract MilFold is MilFoldInterface,Milevents {
    using SafeMath for *;

//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    uint256     constant private    rndMax_ = 90000;                                        // max length a round timer can be
    uint256     constant private    claimMax_ = 43200;                                      // max limitation period to claim winned
    address     constant private    fundAddr_ = 0xB0c7Dc00E8A74c9dEc8688EFb98CcB2e24584E3B; // foundation address
    uint256     constant private    MIN_ETH_BUYIN = 0.002 ether;                            // min buy amount
    uint256     constant private    COMMON_REWARD_AMOUNT = 0.01 ether;                      // reward who end round or draw the game
    uint256     constant private    CLAIM_WINNER_REWARD_AMOUNT = 1 ether;                   // reward who claim an winner
    uint256     constant private    MAX_WIN_AMOUNT = 5000 ether;                            // max win amount every round;

    uint256     private             rID_;                                                   // current round;
    uint256     private             lID_;                                                   // last round;
    uint256     private             lBlockNumber_;                                          // last round end block number;
    bool        private             activated_;                                             // mark contract is activated;
    
    MillionaireInterface constant private millionaire_ = MillionaireInterface(0x98BDbc858822415C626c13267594fbC205182A1F);
    MilAuthInterface constant private milAuth_ = MilAuthInterface(0xf856f6a413f7756FfaF423aa2101b37E2B3aFFD9);

    mapping (address => uint256) private playerTickets_;                                    // (addr => tickets) returns player tickets
    mapping (uint256 => Mildatasets.Round) private round_;                                  // (rID => data) returns round data
    mapping (uint256 => mapping(address => uint256[])) private playerTicketNumbers_;        // (rID => address => data) returns round data
    mapping (address => uint256) private playerWinTotal_;                                   // (addr => eth) returns total winning eth

//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
//==============================================================================
    /**
     * @dev used to make sure no one can interact with contract until it has
     * been activated.
     */
    modifier isActivated() {
        require(activated_ == true, "it&#39;s not ready yet");
        _;
    }

    /**
     * @dev prevents contracts from interacting with milfold,except constructor
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
        require(_eth >= MIN_ETH_BUYIN, "can&#39;t be less anymore");
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
     * @dev used to make sure the paid is sufficient to buy tickets.
     * @param _eth the eth you want pay for
     * @param _num the numbers you want to buy
     */
    modifier inSufficient(uint256 _eth, uint256[] _num) {
        uint256 totalTickets = _num.length;
        require(_eth >= totalTickets.mul(500)/1 ether, "insufficient to buy the very tickets");
        _;
    }

    /**
     * @dev used to make sure the paid is sufficient to buy tickets.
     * @param _eth the eth you want pay for
     * @param _startNums the start numbers you want to buy
     * @param _endNums the end numbers you want to to buy
     */
    modifier inSufficient2(uint256 _eth, uint256[] _startNums, uint256[] _endNums) {
        uint256 totalTickets = calcSectionTickets(_startNums, _endNums);
        require(_eth >= totalTickets.mul(500)/1 ether, "insufficient to buy the very tickets");
        _;
    }

    /**
     * @dev deposit to contract
     */
    function() public isActivated() payable {
        addPot();
    }

    /**
     * @dev buy tickets with pay eth
     * @param _affID the id of the player who gets the affiliate fee
     */
    function buyTickets(uint256 _affID)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev direct buy nums with pay eth in express way
     * @param _affID the id of the player who gets the affiliate fee
     * @param _nums which nums you buy, less than 10
     */
    function expressBuyNums(uint256 _affID, uint256[] _nums)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        inSufficient(msg.value, _nums)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);
        convertCore(msg.sender, _nums.length, TicketCompressor.encode(_nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev direct buy section nums with pay eth in express way
     * @param _affID the id of the player who gets the affiliate fee
     * @param _startNums  section nums,start
     * @param _endNums section nums,end
     */
    function expressBuyNumSec(uint256 _affID, uint256[] _startNums, uint256[] _endNums)
        public
        isActivated()
        isHuman()
        isWithinLimits(msg.value)
        inSufficient2(msg.value, _startNums, _endNums)
        payable
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        buyCore(msg.sender, _affID, msg.value);
        convertCore(
            msg.sender,
            calcSectionTickets(_startNums, _endNums),
            TicketCompressor.encode(_startNums, _endNums)
        );

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            msg.value,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev buy tickets with use your vaults
     * @param _affID the id of the player who gets the affiliate fee
     * @param _eth the vaults you want pay for
     */
    function reloadTickets(uint256 _affID, uint256 _eth)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev direct buy nums with use your vaults in express way
     * @param _affID the id of the player who gets the affiliate fee
     * @param _eth the vaults you want pay for
     * @param _nums which nums you buy, no more than 10
     */
    function expressReloadNums(uint256 _affID, uint256 _eth, uint256[] _nums)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        inSufficient(_eth, _nums)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);
        convertCore(msg.sender, _nums.length, TicketCompressor.encode(_nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev direct buy section nums with use your vaults in express way
     * @param _affID the id of the player who gets the affiliate fee
     * @param _eth the vaults you want pay for
     * @param _startNums  section nums, start
     * @param _endNums section nums, end
     */
    function expressReloadNumSec(uint256 _affID, uint256 _eth, uint256[] _startNums, uint256[] _endNums)
        public
        isActivated()
        isHuman()
        isWithinLimits(_eth)
        inSufficient2(_eth, _startNums, _endNums)
    {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        reloadCore(msg.sender, _affID, _eth);
        convertCore(msg.sender, calcSectionTickets(_startNums, _endNums), TicketCompressor.encode(_startNums, _endNums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            _eth,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev convert to nums with you consume tickets
     * @param nums which nums you buy, no more than 10
     */
    function convertNums(uint256[] nums) public {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        convertCore(msg.sender, nums.length, TicketCompressor.encode(nums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            0,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    /**
     * @dev convert to section nums with you consume tickets
     * @param startNums  section nums, start
     * @param endNums section nums, end
     */
    function convertNumSec(uint256[] startNums, uint256[] endNums) public {
        uint256 compressData = checkRoundAndDraw(msg.sender);
        convertCore(msg.sender, calcSectionTickets(startNums, endNums), TicketCompressor.encode(startNums, endNums));

        emit onEndTx(
            rID_,
            msg.sender,
            compressData,
            0,
            round_[rID_].pot,
            playerTickets_[msg.sender],
            block.timestamp
        );
    }

    function buyCore(address _addr, uint256 _affID, uint256 _eth)
        private
    {
        /**
         * 2% transfer to foundation
         * 18% transfer to pot
         * 80% transfer to millionaire, 50% use to convert MFCoin and 30% use to genAndAff
         */
        // 1 ticket = 0.002 eth, i.e., tickets = eth * 500
        playerTickets_[_addr] = playerTickets_[_addr].add(_eth.mul(500)/1 ether);

        // transfer 2% to foundation
        uint256 foundFee = _eth.div(50);
        fundAddr_.transfer(foundFee);

        // transfer 80%(50% use to convert MFCoin and 30% use to genAndAff) amount to millionaire
        uint256 milFee = _eth.mul(80).div(100);

        millionaire_.updateGenVaultAndMask.value(milFee)(_addr, _affID);

        round_[rID_].pot = round_[rID_].pot.add(_eth.sub(milFee).sub(foundFee));
    }

    function reloadCore(address _addr, uint256 _affID, uint256 _eth)
        private
    {
        /**
         * 2% transfer to foundation
         * 18% transfer to pot
         * 80% transfer to millionaire, 50% use to convert MFCoin and 30% use to genAndAff
         */
        // transfer 80%(50% use to convert MFCoin and 30% use to genAndAff) amount to millionaire
        uint256 milFee = _eth.mul(80).div(100);
        
        millionaire_.clearGenVaultAndMask(_addr, _affID, _eth, milFee);

        // 1 ticket = 0.002 eth, i.e., tickets = eth * 500
        playerTickets_[_addr] = playerTickets_[_addr].add(_eth.mul(500)/1 ether);

        // transfer 2% to foundation
        uint256 foundFee = _eth.div(50);
        fundAddr_.transfer(foundFee);
        
        //game pot will add in default function
        //round_[rID_].pot = round_[rID_].pot.add(_eth.sub(milFee).sub(foundFee));
    }

    function convertCore(address _addr, uint256 length, uint256 compressNumber)
        private
    {
        playerTickets_[_addr] = playerTickets_[_addr].sub(length);
        uint256[] storage plyTicNums = playerTicketNumbers_[rID_][_addr];
        plyTicNums.push(compressNumber);
    }

    // in order to draw the MilFold, we have to do all as following
    // 1. end current round
    // 2. calculate the draw-code
    // 3. claim winned
    // 4. assign to foundation, winners, and migrate the rest to the next round

    function checkRoundAndDraw(address _addr)
        private
        returns(uint256)
    {
        if (lID_ > 0
            && round_[lID_].state == Mildatasets.RoundState.STOPPED
            && (block.number.sub(lBlockNumber_) >= 7)) {
            // calculate the draw-code
            round_[lID_].drawCode = calcDrawCode();
            round_[lID_].claimDeadline = now + claimMax_;
            round_[lID_].state = Mildatasets.RoundState.DRAWN;
            round_[lID_].blockNumber = block.number;
            
            round_[rID_].roundDeadline = now + rndMax_;
            
            if (round_[rID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[rID_].pot.sub(COMMON_REWARD_AMOUNT);
                //reward who Draw Code 0.01 ether
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.DRAW, COMMON_REWARD_AMOUNT);
            }
            return lID_ << 96 | round_[lID_].claimDeadline << 64 | round_[lID_].drawCode << 32 | uint256(Mildatasets.TxAction.DRAW) << 8 | uint256(Mildatasets.RoundState.DRAWN);
        } else if (lID_ > 0
            && round_[lID_].state == Mildatasets.RoundState.DRAWN
            && now > round_[lID_].claimDeadline) {
            // assign to foundation, winners, and migrate the rest to the next round
            if (round_[lID_].totalNum > 0) {
                assignCore();
            }
            round_[lID_].state = Mildatasets.RoundState.ASSIGNED;
            
            if (round_[rID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[rID_].pot.sub(COMMON_REWARD_AMOUNT);
                //reward who Draw Code 0.01 ether
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.ASSIGN, COMMON_REWARD_AMOUNT);
            }
            return lID_ << 96 | uint256(Mildatasets.TxAction.ASSIGN) << 8 | uint256(Mildatasets.RoundState.ASSIGNED);
        } else if ((rID_ == 1 || round_[lID_].state == Mildatasets.RoundState.ASSIGNED)
            && now >= round_[rID_].roundDeadline) {
            // end current round
            lID_ = rID_;
            lBlockNumber_ = block.number;
            round_[lID_].state = Mildatasets.RoundState.STOPPED;

            rID_ = rID_ + 1;

            // migrate last round pot to this round util last round draw
            round_[rID_].state = Mildatasets.RoundState.STARTED;
            if (round_[lID_].pot > COMMON_REWARD_AMOUNT) {
                round_[rID_].pot = round_[lID_].pot.sub(COMMON_REWARD_AMOUNT);
                
                //reward who end round 0.01 ether
                _addr.transfer(COMMON_REWARD_AMOUNT);
                
                emit onReward(_addr, Mildatasets.RewardType.END, COMMON_REWARD_AMOUNT);
            } else {
                round_[rID_].pot = round_[lID_].pot;
            }
            

            return rID_ << 96 | uint256(Mildatasets.TxAction.ENDROUND) << 8 | uint256(Mildatasets.RoundState.STARTED);
        } 
        return rID_ << 96 | uint256(Mildatasets.TxAction.BUY) << 8 | uint256(round_[rID_].state);
    }

    /**
     * @dev claim the winner identified by the given player&#39;s address
     * @param _addr player&#39;s address
     */
    function claimWinner(address _addr)
        public
        isActivated()
        isHuman()
    {
        require(lID_ > 0 && round_[lID_].state == Mildatasets.RoundState.DRAWN && now <= round_[lID_].claimDeadline, "it&#39;s not time for claiming");
        require(round_[lID_].winnerNum[_addr] == 0, "the winner have been claimed already");

        uint winNum = 0;
        uint256[] storage ptns = playerTicketNumbers_[lID_][_addr];
        for (uint256 j = 0; j < ptns.length; j ++) {
            (uint256 tType, uint256 tLength, uint256[] memory playCvtNums) = TicketCompressor.decode(ptns[j]);
            for (uint256 k = 0; k < tLength; k ++) {
                if ((tType == 1 && playCvtNums[k] == round_[lID_].drawCode) ||
                    (tType == 2 && round_[lID_].drawCode >= playCvtNums[2 * k] && round_[lID_].drawCode <= playCvtNums[2 * k + 1])) {
                    winNum++;
                }
            }
        }
        
        if (winNum > 0) {
            if (round_[lID_].winnerNum[_addr] == 0) {
                round_[lID_].winners.push(_addr);
            }
            round_[lID_].totalNum = round_[lID_].totalNum.add(winNum);
            round_[lID_].winnerNum[_addr] = winNum;
            
            uint256 rewardAmount = CLAIM_WINNER_REWARD_AMOUNT.min(round_[lID_].pot.div(200)); //reward who claim winner ,min 1 ether,no more than 1% reward
            
            round_[rID_].pot = round_[rID_].pot.sub(rewardAmount);
            // reward who claim an winner
            msg.sender.transfer(rewardAmount);
            emit onReward(msg.sender, Mildatasets.RewardType.CLIAM, COMMON_REWARD_AMOUNT);
            
            emit onClaimWinner(
                _addr,
                winNum,
                round_[lID_].totalNum
            );
        }
    }

    function assignCore() private {
        /**
         * 2% transfer to foundation
         * 48% transfer to next round
         * 50% all winner share 50% pot on condition singal share no more than MAX_WIN_AMOUNT
         */
        uint256 lPot = round_[lID_].pot;
        uint256 totalWinNum = round_[lID_].totalNum;
        uint256 winShareAmount = (MAX_WIN_AMOUNT.mul(totalWinNum)).min(lPot.div(2));
        uint256 foundFee = lPot.div(50);

        fundAddr_.transfer(foundFee);

        uint256 avgShare = winShareAmount / totalWinNum;
        for (uint256 idx = 0; idx < round_[lID_].winners.length; idx ++) {
            address addr = round_[lID_].winners[idx];
            uint256 num = round_[lID_].winnerNum[round_[lID_].winners[idx]];
            uint256 amount = round_[lID_].winnerNum[round_[lID_].winners[idx]].mul(avgShare);

            millionaire_.assign.value(amount)(addr);
            playerWinTotal_[addr] = playerWinTotal_[addr].add(amount);

            emit onPlayerWin(addr, lID_, amount, num);
        }

        round_[rID_].pot = round_[rID_].pot.sub(winShareAmount).sub(foundFee);
    }

    function calcSectionTickets(uint256[] startNums, uint256[] endNums)
        private
        pure
        returns(uint256)
    {
        require(startNums.length == endNums.length, "tickets length invalid");
        uint256 totalTickets = 0;
        uint256 tickets = 0;
        for (uint256 i = 0; i < startNums.length; i ++) {
            tickets = endNums[i].sub(startNums[i]).add(1);
            totalTickets = totalTickets.add(tickets);
        }
        return totalTickets;
    }

    function calcDrawCode() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(

            ((uint256(keccak256(abi.encodePacked(blockhash(block.number))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 1))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 2))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 3))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 4))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 5))))) / (block.timestamp)).add
            ((uint256(keccak256(abi.encodePacked(blockhash(block.number - 6))))) / (block.timestamp))

        ))) % 10000000;

    }

    function activate() public {
        // only millionaire can activate
        require(msg.sender == address(millionaire_), "only contract millionaire can activate");

        // can only be ran once
        require(activated_ == false, "MilFold already activated");

        // activate the contract
        activated_ = true;

        // lets start first round
        rID_ = 1;
        round_[1].roundDeadline = now + rndMax_;
        round_[1].state = Mildatasets.RoundState.STARTED;
        // round_[0].pot refers to initial pot from ico phase
        round_[1].pot = round_[0].pot;
    }

    function addPot()
        public
        payable {
        require(milAuth_.checkGameClosed(address(this)) == false, "game already closed");
        require(msg.value > 0, "add pot failed");
        round_[rID_].pot = round_[rID_].pot.add(msg.value);
    }

    function close()
        public
        isActivated
        onlyDevs {
        require(milAuth_.checkGameClosed(address(this)), "game no closed");
        activated_ = false;
        millionaire_.splitPot.value(address(this).balance)();
    }

    /**
     * @dev return players&#39;s total winning eth
     * @param _addr player&#39;s address
     * @return player&#39;s total tickets
     * @return player&#39;s total winning eth
     */
    function getPlayerAccount(address _addr)
        public
        view
        returns(uint256, uint256)
    {
        return (playerTickets_[_addr], playerWinTotal_[_addr]);
    }

    /**
     * @dev return numbers in the round
     * @param _rid round id
     * @param _addr player&#39;s address
     * @return player&#39;s numbers
     */
    function getPlayerRoundNums(uint256 _rid, address _addr)
        public
        view
        returns(uint256[])
    {
        return playerTicketNumbers_[_rid][_addr];
    }

    /**
     * @dev return player&#39;s winning information in the round
     * @return winning numbers
     * @param _rid round id
     * @param _addr player&#39;s address
     */
    function getPlayerRoundWinningInfo(uint256 _rid, address _addr)
        public
        view
        returns(uint256)
    {
        Mildatasets.RoundState state = round_[_rid].state;
        if (state >= Mildatasets.RoundState.UNKNOWN && state < Mildatasets.RoundState.DRAWN) {
            return 0;
        } else if (state == Mildatasets.RoundState.ASSIGNED) {
            return round_[_rid].winnerNum[_addr];
        } else {
            // only drawn but not assigned, we need to query the player&#39;s winning numbers
            uint256[] storage ptns = playerTicketNumbers_[_rid][_addr];
            uint256 nums = 0;
            for (uint256 j = 0; j < ptns.length; j ++) {
                (uint256 tType, uint256 tLength, uint256[] memory playCvtNums) = TicketCompressor.decode(ptns[j]);
                for (uint256 k = 0; k < tLength; k ++) {
                    if ((tType == 1 && playCvtNums[k] == round_[_rid].drawCode) ||
                        (tType == 2 && round_[_rid].drawCode >= playCvtNums[2 * k] && round_[lID_].drawCode <= playCvtNums[2 * k + 1])) {
                        nums ++;
                    }
                }
            }

            return nums;
        }
    }

    /**
     * @dev check player is claim in round
     * @param _rid round id
     * @param _addr player address
     * @return true is claimed else false
     */
    function checkPlayerClaimed(uint256 _rid, address _addr)
        public
        view
        returns(bool) {
        return round_[_rid].winnerNum[_addr] > 0;
    }

    /**
     * @dev return current round information
     * @return round id
     * @return last round state
     *      1. current round started
     *      2. current round stopped(wait for drawing code)
     *      3. drawn code(wait for claiming winners)
     *      4. assigned to foundation, winners, and migrate the rest to the next round)
     * @return round end time
     * @return last round claiming time
     * @return round pot
     */
    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        return (
            rID_,
            uint256(round_[lID_].state),
            round_[rID_].roundDeadline,
            round_[lID_].claimDeadline,
            round_[rID_].pot
        );
    }

    /**
     * @dev return history round information
     * @param _rid round id
     * @return items include as following
     *  round state
     *      1. current round started
     *      2. current round stopped(wait for drawing code)
     *      3. drawn code(wait for claiming winners)
     *      4. assigned to foundation, winners, and migrate the rest to the next round)
     *  round end time
     *  winner claim end time
     *  draw code
     *  round pot
     *  draw block number(last one)
     * @return winners&#39; address
     * @return winning number
     */
    function getHistoryRoundInfo(uint256 _rid)
        public
        view
        returns(uint256[], address[], uint256[])
    {
        uint256 length = round_[_rid].winners.length;
        uint256[] memory numbers = new uint256[](length);
        if (round_[_rid].winners.length > 0) {
            for (uint256 idx = 0; idx < length; idx ++) {
                numbers[idx] = round_[_rid].winnerNum[round_[_rid].winners[idx]];
            }
        }

        uint256[] memory items = new uint256[](6);
        items[0] = uint256(round_[_rid].state);
        items[1] = round_[_rid].roundDeadline;
        items[2] = round_[_rid].claimDeadline;
        items[3] = round_[_rid].drawCode;
        items[4] = round_[_rid].pot;
        items[5] = round_[_rid].blockNumber;

        return (items, round_[_rid].winners, numbers);
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

library TicketCompressor {

    uint256 constant private mask = 16777215; //2 ** 24 - 1

    function encode(uint256[] tickets)
        internal
        pure
        returns(uint256)
    {
        require((tickets.length > 0) && (tickets.length <= 10), "tickets must > 0 and <= 10");

        uint256 value = tickets[0];
        for (uint256 i = 1 ; i < tickets.length ; i++) {
            require(tickets[i] < 10000000, "ticket number must < 10000000");
            value = value << 24 | tickets[i];
        }
        return 1 << 248 | tickets.length << 240 | value;
    }

    function encode(uint256[] startTickets, uint256[] endTickets)
        internal
        pure
        returns(uint256)
    {
        require(startTickets.length > 0 && startTickets.length == endTickets.length && startTickets.length <= 5, "section tickets must > 0 and <= 5");

        uint256 value = startTickets[0] << 24 | endTickets[0];
        for (uint256 i = 1 ; i < startTickets.length ; i++) {
            require(startTickets[i] <= endTickets[i] && endTickets[i] < 10000000, "tickets number invalid");
            value = value << 48 | startTickets[i] << 24 | endTickets[i];
        }
        return 2 << 248 | startTickets.length << 240 | value;
    }

    function decode(uint256 _input)
	    internal
	    pure
	    returns(uint256,uint256,uint256[])
    {
        uint256 _type = _input >> 248;
        uint256 _length = _input >> 240 & 127;
        require(_type == 1 || _type == 2, "decode type is incorrect!");


        if (_type == 1) {
            uint256[] memory results = new uint256[](_length);
            uint256 tempVal = _input;
            for (uint256 i=0 ; i < _length ; i++) {
                results[i] = tempVal & mask;
                tempVal = tempVal >> 24;
            }
            return (_type,_length,results);
        } else {
            uint256[] memory result2 = new uint256[](_length * 2);
            uint256 tempVal2 = _input;
            for (uint256 j=0 ; j < _length ; j++) {
                result2[2 * j + 1] = tempVal2 & mask;
                tempVal2 = tempVal2 >> 24;
                result2[2 * j] = tempVal2 & mask;
                tempVal2 = tempVal2 >> 24;
            }
            return (_type,_length,result2);
        }
    }

}