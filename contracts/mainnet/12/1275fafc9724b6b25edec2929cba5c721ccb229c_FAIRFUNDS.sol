pragma solidity ^0.4.24;

/**
*
*  https://fundingsecured.me/fair/
*
*
*  ________ ________  ___  ________
* |\  _____\\   __  \|\  \|\   __  \
* \ \  \__/\ \  \|\  \ \  \ \  \|\  \
*  \ \   __\\ \   __  \ \  \ \   _  _\
*   \ \  \_| \ \  \ \  \ \  \ \  \\  \|
*    \ \__\   \ \__\ \__\ \__\ \__\\ _\
*     \|__|    \|__|\|__|\|__|\|__|\|__|
*  ________ ___  ___  ________   ________  ________
* |\  _____\\  \|\  \|\   ___  \|\   ___ \|\   ____\
* \ \  \__/\ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \___|_
*  \ \   __\\ \  \\\  \ \  \\ \  \ \  \ \\ \ \_____  \
*   \ \  \_| \ \  \\\  \ \  \\ \  \ \  \_\\ \|____|\  \
*    \ \__\   \ \_______\ \__\\ \__\ \_______\____\_\  \
*     \|__|    \|_______|\|__| \|__|\|_______|\_________\
*                                            \|_________|
*
*  https://fundingsecured.me/fair/
*
*
* Warning:
*
* FAIR FUNDS is a game system built on FUNDING SECURED, using infinite loops of token redistribution through open source smart contract codes and pre-defined rules.
* This system is for internal use only and all could be lost by sending anything to this contract address.
* No one can change anything once the contract has been deployed.
* Built in Antiwhale for initial stages for a fairer system.
*
* Official Website: https://fundingsecured.me/
* Official Exchange: https://fundingsecured.me/exchange
* Official Discord: https://discordapp.com/invite/3FrBqBa
* Official Twitter: https://twitter.com/FundingSecured_
* Official Telegram: https://t.me/fundingsecured
 *
**/


contract FAIRFUNDS {
    using SafeMath for uint256;

    /*------------------------------
                CONFIGURABLES
     ------------------------------*/
    string public name = "FAIRFUNDS";    // Contract name
    string public symbol = "FAIRFUNDS";

    uint256 public initAmount;          // Initial stage target
    uint256 public amountProportion;    // Stage target growth rate %
    uint256 public dividend;            // Input to Dividend %
    uint256 public jackpot;             // Input to Jackpot %
    uint256 public jackpotProportion;   // Jackpot payout %
    uint256 public fundsTokenDividend;  // Dividend fee % to FUNDS token holders
    uint256 public promotionRatio;      // Promotion %
    uint256 public duration;            // Duration per stage
    bool public activated = false;

    address public developerAddr;
    address public fundsDividendAddr;

    /*------------------------------
                DATASETS
     ------------------------------*/
    uint256 public rId;   // Current round id number
    uint256 public sId;   // Current stage id number

    mapping (uint256 => Indatasets.Round) public round; // (rId => data) round data by round id
    mapping (uint256 => mapping (uint256 => Indatasets.Stage)) public stage;    // (rId => sId => data) stage data by round id & stage id
    mapping (address => Indatasets.Player) public player;   // (address => data) player data
    mapping (uint256 => mapping (address => uint256)) public playerRoundAmount; // (rId => address => playerRoundAmount) round data by round id
    mapping (uint256 => mapping (address => uint256)) public playerRoundSid;
    mapping (uint256 => mapping (address => uint256)) public playerRoundwithdrawAmountFlag;
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerStageAmount;    // (rId => sId => address => playerStageAmount) round data by round id & stage id
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public playerStageAccAmount;

    //Antiwhale setting, max 5% of stage target for the first 10 stages per address
    uint256[] amountLimit = [0, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250];

    /*------------------------------
                PUBLIC FUNCTIONS
    ------------------------------*/

    constructor()
        public
    {
        developerAddr = msg.sender;
        fundsDividendAddr = 0xd529ADaE263048f495A05B858c8E7C077F047813;
    }

    /*------------------------------
                MODIFIERS
     ------------------------------*/

    modifier isActivated() {
        require(activated == true, "its not ready yet.  check ?eta in discord");
        _;
    }

    modifier senderVerify() {
        require (msg.sender == tx.origin);
        _;
    }

    modifier stageVerify(uint256 _rId, uint256 _sId, uint256 _amount) {
        require(stage[_rId][_sId].amount.add(_amount) <= stage[_rId][_sId].targetAmount);
        _;
    }

    /**
     * Don&#39;t toy or spam the contract.
     */
    modifier amountVerify() {
        require(msg.value >= 100000000000000);
        _;
    }

    modifier playerVerify() {
        require(player[msg.sender].active == true);
        _;
    }

    /**
     * Activation of contract with settings
     */
    function activate()
        public
    {
        require(msg.sender == developerAddr);
        require(activated == false, "FUNDS already activated");

        activated = true;
        initAmount = 10000000000000000000;
        amountProportion = 10;
        dividend = 70;
        jackpot = 20;
        jackpotProportion = 70;
        fundsTokenDividend = 10;
        promotionRatio = 10;
        duration = 15600;
        rId = 1;
        sId = 1;

        round[rId].start = now;
        initStage(rId, sId);

    }

    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        isActivated()
        senderVerify()
        amountVerify()
        payable
        public
    {
        buyAnalysis(0x0);
    }

    /**
     * Standard buy function.
     */
    function buy(address _recommendAddr)
        isActivated()
        senderVerify()
        amountVerify()
        public
        payable
        returns(uint256)
    {
        buyAnalysis(_recommendAddr);
    }

    /**
     * Withdraw function.
     * Withdraw 50 stages at once on current settings.
     * May require to request withdraw more than once to withdraw everything.
     */
    function withdraw()
        isActivated()
        senderVerify()
        playerVerify()
        public
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount;
        uint256 _playerWithdrawAmountFlag;

        (_amount, player[msg.sender].withdrawRid, player[msg.sender].withdrawSid, _playerWithdrawAmountFlag) = getPlayerDividendByStage(_rId, _sId, msg.sender);

        if(_playerWithdrawAmountFlag > 0)
            playerRoundwithdrawAmountFlag[player[msg.sender].withdrawRid][msg.sender] = _playerWithdrawAmountFlag;

        if(player[msg.sender].promotionAmount > 0 ){
            _amount = _amount.add(player[msg.sender].promotionAmount);
            player[msg.sender].promotionAmount = 0;
        }
        msg.sender.transfer(_amount);
    }


    /**
     * Core logic to analyse buy behaviour.
     */
    function buyAnalysis(address _recommendAddr)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _promotionRatio = promotionRatio;

        if(now > stage[_rId][_sId].end && stage[_rId][_sId].targetAmount > stage[_rId][_sId].amount){

            endRound(_rId, _sId);

            _rId = rId;
            _sId = sId;
            round[_rId].start = now;
            initStage(_rId, _sId);

            _amount = limitAmount(_rId, _sId);
            buyRoundDataRecord(_rId, _amount);
            _promotionRatio = promotionDataRecord(_recommendAddr, _amount);
            buyStageDataRecord(_rId, _sId, _promotionRatio, _amount);
            buyPlayerDataRecord(_rId, _sId, _amount);

        }else if(now <= stage[_rId][_sId].end){

            _amount = limitAmount(_rId, _sId);
            buyRoundDataRecord(_rId, _amount);
            _promotionRatio = promotionDataRecord(_recommendAddr, _amount);

            if(stage[_rId][_sId].amount.add(_amount) >= stage[_rId][_sId].targetAmount){

                uint256 differenceAmount = (stage[_rId][_sId].targetAmount).sub(stage[_rId][_sId].amount);
                buyStageDataRecord(_rId, _sId, _promotionRatio, differenceAmount);
                buyPlayerDataRecord(_rId, _sId, differenceAmount);

                endStage(_rId, _sId);

                _sId = sId;
                initStage(_rId, _sId);
                round[_rId].endSid = _sId;
                buyStageDataRecord(_rId, _sId, _promotionRatio, _amount.sub(differenceAmount));
                buyPlayerDataRecord(_rId, _sId, _amount.sub(differenceAmount));

            }else{
                buyStageDataRecord(_rId, _sId, _promotionRatio, _amount);
                buyPlayerDataRecord(_rId, _sId, _amount);

            }
        }
    }


    /**
     * Sets the initial stage parameter.
     */
    function initStage(uint256 _rId, uint256 _sId)
        private
    {
        uint256 _targetAmount;
        stage[_rId][_sId].start = now;
        stage[_rId][_sId].end = now.add(duration);
        if(_sId > 1){
            stage[_rId][_sId - 1].end = now;
            stage[_rId][_sId - 1].ended = true;
            _targetAmount = (stage[_rId][_sId - 1].targetAmount.mul(amountProportion + 100)) / 100;
        }else
            _targetAmount = initAmount;

        stage[_rId][_sId].targetAmount = _targetAmount;

    }

    /**
     * Execution of antiwhale.
     */
    function limitAmount(uint256 _rId, uint256 _sId)
        private
        returns(uint256)
    {
        uint256 _amount = msg.value;

        if(amountLimit.length > _sId)
            _amount = ((stage[_rId][_sId].targetAmount.mul(amountLimit[_sId])) / 1000).sub(playerStageAmount[_rId][_sId][msg.sender]);
        else
            _amount = ((stage[_rId][_sId].targetAmount.mul(500)) / 1000).sub(playerStageAmount[_rId][_sId][msg.sender]);

        if(_amount >= msg.value)
            return msg.value;
        else
            msg.sender.transfer(msg.value.sub(_amount));

        return _amount;
    }

    /**
     * Record the addresses eligible for promotion links.
     */
    function promotionDataRecord(address _recommendAddr, uint256 _amount)
        private
        returns(uint256)
    {
        uint256 _promotionRatio = promotionRatio;

        if(_recommendAddr != 0x0000000000000000000000000000000000000000
            && _recommendAddr != msg.sender
            && player[_recommendAddr].active == true
        )
            player[_recommendAddr].promotionAmount = player[_recommendAddr].promotionAmount.add((_amount.mul(_promotionRatio)) / 100);
        else
            _promotionRatio = 0;

        return _promotionRatio;
    }


    /**
     * Records the round data.
     */
    function buyRoundDataRecord(uint256 _rId, uint256 _amount)
        private
    {

        round[_rId].amount = round[_rId].amount.add(_amount);
        fundsDividendAddr.transfer(_amount.mul(fundsTokenDividend) / 100);
    }

    /**
     * Records the stage data.
     */
    function buyStageDataRecord(uint256 _rId, uint256 _sId, uint256 _promotionRatio, uint256 _amount)
        stageVerify(_rId, _sId, _amount)
        private
    {
        if(_amount <= 0)
            return;
        stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_sId].dividendAmount = stage[_rId][_sId].dividendAmount.add((_amount.mul(dividend.sub(_promotionRatio))) / 100);
    }

    /**
     * Records the player data.
     */
    function buyPlayerDataRecord(uint256 _rId, uint256 _sId, uint256 _amount)
        private
    {
        if(_amount <= 0)
            return;

        if(player[msg.sender].active == false){
            player[msg.sender].active = true;
            player[msg.sender].withdrawRid = _rId;
            player[msg.sender].withdrawSid = _sId;
        }

        if(playerRoundAmount[_rId][msg.sender] == 0){
            round[_rId].players++;
            playerRoundSid[_rId][msg.sender] = _sId;
        }

        if(playerStageAmount[_rId][_sId][msg.sender] == 0)
            stage[_rId][_sId].players++;

        playerRoundAmount[_rId][msg.sender] = playerRoundAmount[_rId][msg.sender].add(_amount);
        playerStageAmount[_rId][_sId][msg.sender] = playerStageAmount[_rId][_sId][msg.sender].add(_amount);

        player[msg.sender].amount = player[msg.sender].amount.add(_amount);

        if(playerRoundSid[_rId][msg.sender] > 0){

            if(playerStageAccAmount[_rId][_sId][msg.sender] == 0){

                for(uint256 i = playerRoundSid[_rId][msg.sender]; i < _sId; i++){

                    if(playerStageAmount[_rId][i][msg.sender] > 0)
                        playerStageAccAmount[_rId][_sId][msg.sender] = playerStageAccAmount[_rId][_sId][msg.sender].add(playerStageAmount[_rId][i][msg.sender]);

                }
            }

            playerStageAccAmount[_rId][_sId][msg.sender] = playerStageAccAmount[_rId][_sId][msg.sender].add(_amount);
        }
    }

    /**
     * Execute end of round events.
     */
    function endRound(uint256 _rId, uint256 _sId)
        private
    {
        round[_rId].end = now;
        round[_rId].ended = true;
        round[_rId].endSid = _sId;
        stage[_rId][_sId].end = now;
        stage[_rId][_sId].ended = true;

        if(stage[_rId][_sId].players == 0)
            round[_rId + 1].jackpotAmount = round[_rId + 1].jackpotAmount.add(round[_rId].jackpotAmount);
        else
            round[_rId + 1].jackpotAmount = round[_rId + 1].jackpotAmount.add(round[_rId].jackpotAmount.mul(100 - jackpotProportion) / 100);

        rId++;
        sId = 1;

    }

    /**
     * Execute end of stage events.
     */
    function endStage(uint256 _rId, uint256 _sId)
        private
    {
        uint256 _jackpotAmount = stage[_rId][_sId].amount.mul(jackpot) / 100;
        round[_rId].endSid = _sId;
        round[_rId].jackpotAmount = round[_rId].jackpotAmount.add(_jackpotAmount);
        stage[_rId][_sId].end = now;
        stage[_rId][_sId].ended = true;
        if(_sId > 1)
            stage[_rId][_sId].accAmount = stage[_rId][_sId].targetAmount.add(stage[_rId][_sId - 1].accAmount);
        else
            stage[_rId][_sId].accAmount = stage[_rId][_sId].targetAmount;

        sId++;
    }

    /**
     * Precalculations for withdraws to conserve gas.
     */
    function getPlayerDividendByStage(uint256 _rId, uint256 _sId, address _playerAddr)
        private
        view
        returns(uint256, uint256, uint256, uint256)
    {

        uint256 _dividend;
        uint256 _stageNumber;
        uint256 _startSid;
        uint256 _playerAmount;

        for(uint256 i = player[_playerAddr].withdrawRid; i <= _rId; i++){

            if(playerRoundAmount[i][_playerAddr] == 0)
                continue;

            _playerAmount = 0;
            _startSid = i == player[_playerAddr].withdrawRid ? player[_playerAddr].withdrawSid : 1;
            for(uint256 j = _startSid; j < round[i].endSid; j++){

                if(playerStageAccAmount[i][j][_playerAddr] > 0)
                    _playerAmount = playerStageAccAmount[i][j][_playerAddr];

                if(_playerAmount == 0)
                    _playerAmount = playerRoundwithdrawAmountFlag[i][_playerAddr];

                if(_playerAmount == 0)
                    continue;
                _dividend = _dividend.add(
                    (
                        _playerAmount.mul(stage[i][j].dividendAmount)
                    ).div(stage[i][j].accAmount)
                );

                _stageNumber++;
                if(_stageNumber >= 50)
                    return (_dividend, i, j + 1, _playerAmount);
            }

            if(round[i].ended == true
                && stage[i][round[i].endSid].amount > 0
                && playerStageAmount[i][round[i].endSid][_playerAddr] > 0
            ){
                _dividend = _dividend.add(getPlayerJackpot(_playerAddr, i));
                _stageNumber++;
                if(_stageNumber >= 50)
                    return (_dividend, i + 1, 1, 0);
            }
        }
        return (_dividend, _rId, _sId, _playerAmount);
    }

    /**
     * Get player current withdrawable dividend.
     */
    function getPlayerDividend(address _playerAddr)
        public
        view
        returns(uint256)
    {
        uint256 _endRid = rId;
        uint256 _startRid = player[_playerAddr].withdrawRid;
        uint256 _startSid;
        uint256 _dividend;

        for(uint256 i = _startRid; i <= _endRid; i++){

            if(i == _startRid)
                _startSid = player[_playerAddr].withdrawSid;
            else
                _startSid = 1;
            _dividend = _dividend.add(getPlayerDividendByRound(_playerAddr, i, _startSid));
        }

        return _dividend;
    }

    /**
     * Get player data for rounds and stages.
     */
    function getPlayerDividendByRound(address _playerAddr, uint256 _rId, uint256 _sId)
        public
        view
        returns(uint256)
    {
        uint256 _dividend;
        uint256 _startSid = _sId;
        uint256 _endSid = round[_rId].endSid;

        uint256 _playerAmount;
        uint256 _totalAmount;
        for(uint256 i = _startSid; i < _endSid; i++){

            if(stage[_rId][i].ended == false)
                continue;

            _playerAmount = 0;
            _totalAmount = 0;
            for(uint256 j = 1; j <= i; j++){

                if(playerStageAmount[_rId][j][_playerAddr] > 0)
                    _playerAmount = _playerAmount.add(playerStageAmount[_rId][j][_playerAddr]);

                _totalAmount = _totalAmount.add(stage[_rId][j].amount);
            }

            if(_playerAmount == 0 || stage[_rId][i].dividendAmount == 0)
                continue;
            _dividend = _dividend.add((_playerAmount.mul(stage[_rId][i].dividendAmount)).div(_totalAmount));
        }

        if(round[_rId].ended == true)
            _dividend = _dividend.add(getPlayerJackpot(_playerAddr, _rId));

        return _dividend;
    }


    /**
     * Get player data for jackpot winnings.
     */
    function getPlayerJackpot(address _playerAddr, uint256 _rId)
        public
        view
        returns(uint256)
    {
        uint256 _dividend;

        if(round[_rId].ended == false)
            return _dividend;

        uint256 _endSid = round[_rId].endSid;
        uint256 _playerStageAmount = playerStageAmount[_rId][_endSid][_playerAddr];
        uint256 _stageAmount = stage[_rId][_endSid].amount;
        if(_stageAmount <= 0)
            return _dividend;

        uint256 _jackpotAmount = round[_rId].jackpotAmount.mul(jackpotProportion) / 100;
        uint256 _stageDividendAmount = stage[_rId][_endSid].dividendAmount;
        uint256 _stageJackpotAmount = (_stageAmount.mul(jackpot) / 100).add(_stageDividendAmount);

        _dividend = _dividend.add(((_playerStageAmount.mul(_jackpotAmount)).div(_stageAmount)));
        _dividend = _dividend.add(((_playerStageAmount.mul(_stageJackpotAmount)).div(_stageAmount)));

        return _dividend;
    }

    /**
     * For frontend.
     */
    function getHeadInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, bool)
    {
        return
            (
                rId,
                sId,
                round[rId].jackpotAmount,
                stage[rId][sId].targetAmount,
                stage[rId][sId].amount,
                stage[rId][sId].end,
                stage[rId][sId].ended
            );
    }

    /**
     * For frontend.
     */
    function getPersonalStatus(address _playerAddr)
        public
        view
        returns(uint256, uint256, uint256)
    {
        if (player[_playerAddr].active == true){
            return
            (
                round[rId].jackpotAmount,
                playerRoundAmount[rId][_playerAddr],
                getPlayerDividendByRound(_playerAddr, rId, 1)
            );
        }else{
            return
            (
                round[rId].jackpotAmount,
                0,
                0
            );
        }
    }

    /**
     * For frontend.
     */
    function getValueInfo(address _playerAddr)
        public
        view
        returns(uint256, uint256)
    {
        if (player[_playerAddr].active == true){
            return
            (
                getPlayerDividend(_playerAddr),
                player[_playerAddr].promotionAmount
            );
        }else{
            return
            (
                0,
                0
            );
        }
    }

}

library Indatasets {

    struct Round {
        uint256 start;          // time round started
        uint256 end;            // time round ends/ended
        bool ended;             // has round end function been ran
        uint256 endSid;         // last stage for current round
        uint256 amount;         // Eth recieved for current round
        uint256 jackpotAmount;  // total jackpot for current round
        uint256 players;        // total players for current round
    }

    struct Stage {
        uint256 start;          // time stage started
        uint256 end;            // time strage ends/ended
        bool ended;             // has stage end function been ran
        uint256 targetAmount;   // amount needed for current stage
        uint256 amount;         // Eth received for current stage
        uint256 dividendAmount; // total dividend for current stage
        uint256 accAmount;      // total accumulative amount for current stage
        uint256 players;        // total players for current stage
    }

    struct Player {
        bool active;                // Activation status of player, if false player has not been activated.
        uint256 amount;             // Total player input.
        uint256 promotionAmount;    // Total promotion amount of the player.
        uint256 withdrawRid;        // Last withdraw round of the player.
        uint256 withdrawSid;        // Last withdraw stage of the player.
    }
}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
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
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
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
    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}