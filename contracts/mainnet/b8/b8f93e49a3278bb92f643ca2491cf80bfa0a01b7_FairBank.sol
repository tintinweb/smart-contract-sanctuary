pragma solidity ^0.4.25;

/**
 *
 *  https://fairdapp.com/bank/  https://fairdapp.com/bank/   https://fairdapp.com/bank/
 *   
 *       _______     _       ______  _______ ______ ______  
 *      (_______)   (_)     (______)(_______|_____ (_____ \ 
 *       _____ _____ _  ____ _     _ _______ _____) )____) )
 *      |  ___|____ | |/ ___) |   | |  ___  |  ____/  ____/ 
 *      | |   / ___ | | |   | |__/ /| |   | | |    | |      
 *      |_|   \_____|_|_|   |_____/ |_|   |_|_|    |_|      
 *                                                     
 *               ______              _                              
 *              (____  \            | |                             
 *               ____)  )_____ ____ | |  _                          
 *              |  __  ((____ |  _ \| |_/ )                         
 *              | |__)  ) ___ | | | |  _ (                          
 *              |______/\_____|_| |_|_| \_)                         
 *                                                    
 *         ______ _             _                            
 *        / _____|_)           | |         _                 
 *       ( (____  _ ____  _   _| | _____ _| |_ ___   ____    
 *        \____ \| |    \| | | | |(____ (_   _) _ \ / ___)   
 *        _____) ) | | | | |_| | |/ ___ | | || |_| | |       
 *       (______/|_|_|_|_|____/ \_)_____|  \__)___/|_|       
 *                                                   
 *   
 *  Warning:
 *     
 *  FairDAPP – Bank Simulator (actually this probably has more resemblance 
 *  of a government bond simulator but Bank is a more catchy name)
 *  is a system designed to explore how a real world financial bank would
 *  operate during a financial collapse without quantitative easing and bail outs.
 *  This system is simulated through open source smart contract codes and pre-defined rules.
 *  This contract may only be used internally for study purposes and all could be 
 *  lost by sending anything to this contract address. 
 *  All users are prohibited to interact with this contract if this 
 *  contract is in conflict with user’s local regulations or laws.
 * 
 *  -Original Contract built by the FairDAPP Community
 *  -Code Audited by 8Bit & Etherguy (formula calculations are excluded from the audit)
 *  
 *  -The contract has an activation switch to activate the system.
 *  -The resetTime and reduceTime functions have an on and off switch which the developer owner can control.
 *  -No one can change anything else once the contract has been deployed.
 *  
 *  -No anti-whales and almost no restrictions on what a user can do!
 *  -There is no need to FOMO, early players have no significant advantage over later players.
 *      -Scaling is slow, the system is designed for players to stake many stages. 
 *  -The contract is fully solvent in any event (assuming there are no bugs).
 *      -ie. The contract will always payout what it owes. 
 *
**/


contract ERC721{
    
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

contract FairBank is ERC721{
    using SafeMath for uint256;
    using NameFilter for string;
    address public developerAddr;

    string public name = "FairDAPP - Bank Simulator";
    string public symbol = "FBank";
    
    uint256 public stageDuration;
    uint256 public standardProtectRatio;
    bool public activated = false;
    bool public modifyCountdown = false;
    
    uint256 public rId;
    uint256 public sId;
    
    mapping (uint256 => FBankdatasets.Round) public round;
    mapping (uint256 => mapping (uint256 => FBankdatasets.Stage)) public stage;
    
    mapping (address => bytes32) public register;
    mapping (bytes32 => address) public playerName;
    
    mapping (address => uint256[]) public playerGoodsList;
    mapping (address => uint256[]) public playerWithdrawList;
    
    /**
     * Anti clone protection.
     * Do not clone this contract without permission even if you manage to break the conceal. 
     * The concealed code contains core calculations necessary for this contract to function, read line 1058. 
     * This contract can be licensed for a fee, contact us instead of cloning!
     */ 
    FairBankCompute constant private bankCompute = FairBankCompute(0x26DA117A72DBcB686c2FCF88c4BFC6110cAe0464);
    
    FBankdatasets.Goods[] public goodsList;
    
    FBankdatasets.Card[6] public cardList;
    mapping (uint256 => address) public cardIndexToApproved;
    
    modifier registerVerify() {
        require(msg.value == 10000000000000000, "registration fee is 0.01 ether, please set the exact amount");
        _;
    }
    
    modifier isActivated() {
        require(activated == true, "FairBank its not ready yet.  check ?eta in discord"); 
        _;
    }
    
    modifier isDeveloperAddr() {
        require(msg.sender == developerAddr, "Permission denied");
        _;
    }
    
    modifier modifyCountdownVerify() {
        require(modifyCountdown == true, "this feature is not turned on or has been turned off"); 
        _;
    }
     
    modifier senderVerify() {
        require (msg.sender == tx.origin, "sender does not meet the rules");
        _;
    }
    
    /**
     * Don&#39;t toy or spam the contract, it may raise the gas cost for everyone else.
     * The scientists will take anything below 0.001 ETH sent to the contract.
     * Thank you for your donation.
     */
    modifier amountVerify() {
        if(msg.value < 1000000000000000){
            developerAddr.send(msg.value);
        }else{
            require(msg.value >= 1000000000000000, "minimum amount is 0.001 ether");
            _;
        }
    }
    
    modifier playerVerify() {
        require(playerGoodsList[msg.sender].length > 0, "user has not purchased the product or has completed the withdrawal");
        _;
    }
    
    modifier stepSizeVerify(uint256 _stepSize) {
        require(_stepSize <= 1000000, "step size must not exceed 1000000");
        _;
    }
    
    constructor()
        public
    {
        developerAddr = msg.sender;
        
        stageDuration = 64800;
        standardProtectRatio = 57;
        uint256 i;
        while(i < cardList.length){
            cardList[i].playerAddress = developerAddr;
            cardList[i].amount = 5000000000000000000; 
            i++;
        }
    }
    
    function registered(string _playerName)
        senderVerify()
        registerVerify()
        payable
        public
    {
        bytes32 _name = _playerName.nameFilter();
        require(_name != bytes32(0), "name cannot be empty");
        require(playerName[_name] == address(0), "this name has already been registered");
        require(register[msg.sender] == bytes32(0), "please do not repeat registration");
        
        playerName[_name] = msg.sender;
        register[msg.sender] = _name;
        developerAddr.send(msg.value);
    }
    
    /**
     * Activation of contract with settings
     */
    function activate()
        senderVerify()
        isDeveloperAddr()
        public
    {
        require(activated == false, "FairBank already activated");
        
        activated = true;
        rId = 1;
        sId = 1;
        round[rId].start = now;
        stage[rId][sId].start = now;
    }
    
    function openModifyCountdown()
        senderVerify()
        isDeveloperAddr()
        public
    {
        require(modifyCountdown == false, "Time service is already open");
        
        modifyCountdown = true;
        
    }
    
    function closeModifyCountdown()
        senderVerify()
        isDeveloperAddr()
        public
    {
        require(modifyCountdown == true, "Time service is already open");
        
        modifyCountdown = false;
        
    }
    
    function purchaseCard(uint256 _cId)
        isActivated()
        senderVerify()
        payable
        public
    {
        
        address _player = msg.sender;
        uint256 _amount = msg.value;
        uint256 _purchasePrice = cardList[_cId].amount.mul(110) / 100;
        
        require(
            cardList[_cId].playerAddress != address(0) 
            && cardList[_cId].playerAddress != _player 
            && _amount >= _purchasePrice, 
            "Failed purchase"
        );
        
        if(cardIndexToApproved[_cId] != address(0)){
            cardIndexToApproved[_cId].send(
                cardList[_cId].amount.mul(105) / 100
                );
            delete cardIndexToApproved[_cId];
        }else
            cardList[_cId].playerAddress.send(
                cardList[_cId].amount.mul(105) / 100
                );
                
        developerAddr.send(cardList[_cId].amount.mul(5) / 100);
        if(_amount > _purchasePrice)
            _player.send(_amount.sub(_purchasePrice));
            
        cardList[_cId].amount = _purchasePrice;
        cardList[_cId].playerAddress = _player;
        
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
        buyAnalysis(100, standardProtectRatio, address(0));
    }

    function buy(uint256 _stepSize, uint256 _protectRatio, address _recommendAddr)
        isActivated()
        senderVerify()
        amountVerify()
        stepSizeVerify(_stepSize)
        public
        payable
    {
        buyAnalysis(
            _stepSize <= 0 ? 100 : _stepSize, 
            _protectRatio <= 100 ? _protectRatio : standardProtectRatio, 
            _recommendAddr
            );
    }
    
    function buyXname(uint256 _stepSize, uint256 _protectRatio, string _recommendName)
        isActivated()
        senderVerify()
        amountVerify()
        stepSizeVerify(_stepSize)
        public
        payable
    {
        buyAnalysis(
            _stepSize <= 0 ? 100 : _stepSize, 
            _protectRatio <= 100 ? _protectRatio : standardProtectRatio, 
            playerName[_recommendName.nameFilter()]
            );
    }
    
    /**
     * Standard withdraw function.
     */
    function withdraw()
        isActivated()
        senderVerify()
        playerVerify()
        public
    {
        
        address _player = msg.sender;
        uint256[] memory _playerGoodsList = playerGoodsList[_player];
        uint256 length = _playerGoodsList.length;
        uint256 _totalAmount;
        uint256 _amount;
        uint256 _withdrawSid;
        uint256 _reachAmount;
        bool _finish;
        uint256 i;
        
        delete playerGoodsList[_player];
        while(i < length){
            
            (_amount, _withdrawSid, _reachAmount, _finish) = getEarningsAmountByGoodsIndex(_playerGoodsList[i]);
            
            if(_finish == true){
                playerWithdrawList[_player].push(_playerGoodsList[i]);
            }else{
                goodsList[_playerGoodsList[i]].withdrawSid = _withdrawSid;
                goodsList[_playerGoodsList[i]].reachAmount = _reachAmount;
                playerGoodsList[_player].push(_playerGoodsList[i]);
            }
            
            _totalAmount = _totalAmount.add(_amount);
            i++;
        }
        _player.transfer(_totalAmount);
    }
     
     /**
     * Backup withdraw function in case gas is too high to use standard withdraw.
     */
    function withdrawByGid(uint256 _gId)
        isActivated()
        senderVerify()
        playerVerify()
        public
    {
        address _player = msg.sender;
        uint256 _amount;
        uint256 _withdrawSid;
        uint256 _reachAmount;
        bool _finish;
        
        (_amount, _withdrawSid, _reachAmount, _finish) = getEarningsAmountByGoodsIndex(_gId);
            
        if(_finish == true){
            
            for(uint256 i = 0; i < playerGoodsList[_player].length; i++){
                if(playerGoodsList[_player][i] == _gId)
                    break;
            }
            require(i < playerGoodsList[_player].length, "gid is wrong");
            
            playerWithdrawList[_player].push(_gId);
            playerGoodsList[_player][i] = playerGoodsList[_player][playerGoodsList[_player].length - 1];
            playerGoodsList[_player].length--;
        }else{
            goodsList[_gId].withdrawSid = _withdrawSid;
            goodsList[_gId].reachAmount = _reachAmount;
        }
        
        _player.transfer(_amount);
    }
    
    function resetTime()
        modifyCountdownVerify()
        senderVerify()
        public
        payable
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _costAmount = _targetAmount.mul(20) / 100;
        
        if(_costAmount > 3 ether)
            _costAmount = 3 ether;
        require(_amount >= _costAmount, "Not enough price");
        
        stage[_rId][_sId].start = now;
        
        cardList[5].playerAddress.send(_costAmount / 2);
        developerAddr.send(_costAmount / 2);
        
        if(_amount > _costAmount)
            msg.sender.send(_amount.sub(_costAmount));
        
    }
    
    function reduceTime()
        modifyCountdownVerify()
        senderVerify()
        public
        payable
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _amount = msg.value;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ?
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _costAmount = _targetAmount.mul(30) / 100;
        
        if(_costAmount > 3 ether)
            _costAmount = 3 ether;
        require(_amount >= _costAmount, "Not enough price");
        
        stage[_rId][_sId].start = now - stageDuration + 1800;
        
        cardList[5].playerAddress.send(_costAmount / 2);
        developerAddr.send(_costAmount / 2);
        
        if(_amount > _costAmount)
            msg.sender.send(_amount.sub(_costAmount));
        
    }
    
    /**
     * Core logic to analyse buy behaviour. 
     */
    function buyAnalysis(uint256 _stepSize, uint256 _protectRatio, address _recommendAddr)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _targetExpectedAmount = getStageTargetAmount(_sId);
        uint256 _targetAmount = 
            stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
            _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
        uint256 _stageTargetBalance = 
            stage[_rId][_sId].amount > 0 ? 
            _targetAmount.sub(stage[_rId][_sId].amount) : _targetAmount;
        
        if(now > stage[_rId][_sId].start.add(stageDuration) 
            && _targetAmount > stage[_rId][_sId].amount
        ){
            
            endRound(_rId, _sId);
            
            _rId = rId;
            _sId = sId;
            stage[_rId][_sId].start = now;
            
            _targetExpectedAmount = getStageTargetAmount(_sId);
            _targetAmount = 
                stage[_rId][_sId].dividendAmount <= _targetExpectedAmount ? 
                _targetExpectedAmount : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
            _stageTargetBalance = 
                stage[_rId][_sId].amount > 0 ? 
                _targetAmount.sub(stage[_rId][_sId].amount) : _targetAmount;
        }
        if(_stageTargetBalance > msg.value)
            buyDataRecord(
                _rId, 
                _sId, 
                _targetAmount, 
                msg.value, 
                _stepSize, 
                _protectRatio
                );
        else
            multiStake(
                msg.value, 
                _stepSize, 
                _protectRatio, 
                _targetAmount, 
                _stageTargetBalance
                );
        /* This is a backstop check to ensure that the contract will always be solvent.
        It would reject any stakes with a protection ratio that the contract may not be able to repay.
        This backstop should never be needed under current settings. */
        require(
            (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ) > 0, "data error"
        );    
        bankerFeeDataRecord(_recommendAddr, msg.value, _protectRatio);    
    }
    
    function multiStake(uint256 _amount, uint256 _stepSize, uint256 _protectRatio, uint256 _targetAmount, uint256 _stageTargetBalance)
        private
    {
        uint256 _rId = rId;
        uint256 _sId = sId;
        uint256 _crossStageNum = 1;
        uint256 _protectTotalAmount;
        uint256 _dividendTotalAmount;
            
        while(true){

            if(_crossStageNum == 1){
                playerDataRecord(
                    _rId, 
                    _sId, 
                    _amount, 
                    _stageTargetBalance, 
                    _stepSize, 
                    _protectRatio, 
                    _crossStageNum
                    );
                round[_rId].amount = round[_rId].amount.add(_amount);
                round[_rId].protectAmount = round[_rId].protectAmount.add(
                    _amount.mul(_protectRatio.mul(88)) / 10000);    
            }
                
            buyStageDataRecord(
                _rId, 
                _sId, 
                _targetAmount, 
                _stageTargetBalance, 
                _sId.
                add(_stepSize), 
                _protectRatio
                );
            _dividendTotalAmount = _dividendTotalAmount.add(stage[_rId][_sId].dividendAmount);
            _protectTotalAmount = _protectTotalAmount.add(stage[_rId][_sId].protectAmount);
            
            _sId++;
            _amount = _amount.sub(_stageTargetBalance);
            _targetAmount = 
                stage[_rId][_sId].dividendAmount <= getStageTargetAmount(_sId) ? 
                getStageTargetAmount(_sId) : stage[_rId][_sId].dividendAmount;
            _targetAmount = _targetAmount.mul(100) / 88;
            _stageTargetBalance = _targetAmount;
            _crossStageNum++;
            if(_stageTargetBalance >= _amount){
                buyStageDataRecord(
                    _rId, 
                    _sId, 
                    _targetAmount, 
                    _amount, 
                    _sId.add(_stepSize), 
                    _protectRatio
                    );
                playerDataRecord(
                    _rId, 
                    _sId, 
                    0, 
                    _amount, 
                    _stepSize, 
                    _protectRatio, 
                    _crossStageNum
                    );
                    
                if(_targetAmount == _amount)
                    _sId++;
                    
                stage[_rId][_sId].start = now;
                sId = _sId;
                
                round[_rId].protectAmount = round[_rId].protectAmount.sub(_protectTotalAmount);
                round[_rId].dividendAmount = round[_rId].dividendAmount.add(_dividendTotalAmount);
                break;
            }
        }
    }
    
    /**
     * Records all data.
     */
    function buyDataRecord(uint256 _rId, uint256 _sId, uint256 _targetAmount, uint256 _amount, uint256 _stepSize, uint256 _protectRatio)
        private
    {
        uint256 _expectEndSid = _sId.add(_stepSize);
        uint256 _protectAmount = _amount.mul(_protectRatio.mul(88)) / 10000;
        
        round[_rId].amount = round[_rId].amount.add(_amount);
        round[_rId].protectAmount = round[_rId].protectAmount.add(_protectAmount);
        
        stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_expectEndSid].protectAmount = stage[_rId][_expectEndSid].protectAmount.add(_protectAmount);
        stage[_rId][_expectEndSid].dividendAmount = 
            stage[_rId][_expectEndSid].dividendAmount.add(
                computeEarningsAmount(_sId, 
                _amount, 
                _targetAmount, 
                _expectEndSid, 
                100 - _protectRatio
                )
                );
                
        FBankdatasets.Goods memory _goods;
        _goods.rId = _rId;
        _goods.startSid = _sId;
        _goods.amount = _amount;
        _goods.endSid = _expectEndSid;
        _goods.protectRatio = _protectRatio;
        playerGoodsList[msg.sender].push(goodsList.push(_goods) - 1);
    }
    
    /**
     * Records the stage data.
     */
    function buyStageDataRecord(uint256 _rId, uint256 _sId, uint256 _targetAmount, uint256 _amount, uint256 _expectEndSid, uint256 _protectRatio)
        private
    {
        uint256 _protectAmount = _amount.mul(_protectRatio.mul(88)) / 10000;
        
        if(_targetAmount != _amount)
            stage[_rId][_sId].amount = stage[_rId][_sId].amount.add(_amount);
        stage[_rId][_expectEndSid].protectAmount = stage[_rId][_expectEndSid].protectAmount.add(_protectAmount);
        stage[_rId][_expectEndSid].dividendAmount = 
            stage[_rId][_expectEndSid].dividendAmount.add(
                computeEarningsAmount(
                    _sId, 
                    _amount, 
                    _targetAmount, 
                    _expectEndSid, 
                    100 - _protectRatio
                    )
                );
    }
    
    /**
     * Records the player data.
     */
    function playerDataRecord(uint256 _rId, uint256 _sId, uint256 _totalAmount, uint256 _stageBuyAmount, uint256 _stepSize, uint256 _protectRatio, uint256 _crossStageNum)
        private
    {    
        if(_crossStageNum <= 1){
            FBankdatasets.Goods memory _goods;
            _goods.rId = _rId;
            _goods.startSid = _sId;
            _goods.amount = _totalAmount;
            _goods.stepSize = _stepSize;
            _goods.protectRatio = _protectRatio;
            if(_crossStageNum == 1)
                _goods.startAmount = _stageBuyAmount;
            playerGoodsList[msg.sender].push(goodsList.push(_goods) - 1);
        }
        else{
            uint256 _goodsIndex = goodsList.length - 1;
            goodsList[_goodsIndex].endAmount = _stageBuyAmount;
            goodsList[_goodsIndex].endSid = _sId;
        }
        
    }
    
    function bankerFeeDataRecord(address _recommendAddr, uint256 _amount, uint256 _protectRatio)
        private
    {
        uint256 _jackpotProportion = 80;
        if(_recommendAddr != address(0) 
            && _recommendAddr != msg.sender 
            && (register[_recommendAddr] != bytes32(0))
        ){
            _recommendAddr.send(_amount / 50);
            msg.sender.send(_amount / 100);
        }
        else
            _jackpotProportion = 110;
            
        round[rId].jackpotAmount = round[rId].jackpotAmount.add(_amount.mul(_jackpotProportion).div(1000));

        uint256 _cardAmount = _amount / 200;
        if(_protectRatio == 0)
            cardList[0].playerAddress.send(_cardAmount);
        else if(_protectRatio > 0 && _protectRatio < 57)
            cardList[1].playerAddress.send(_cardAmount);   
        else if(_protectRatio == 57)
            cardList[2].playerAddress.send(_cardAmount);   
        else if(_protectRatio > 57 && _protectRatio < 100)
            cardList[3].playerAddress.send(_cardAmount);   
        else if(_protectRatio == 100)
            cardList[4].playerAddress.send(_cardAmount);   
        
        developerAddr.send(_amount / 200);
    }
    
    function endRound(uint256 _rId, uint256 _sId)
        private
    {
        round[_rId].end = now;
        round[_rId].ended = true;
        round[_rId].endSid = _sId;
        
        if(stage[_rId][_sId].amount > 0)
            round[_rId + 1].jackpotAmount = (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ).mul(20).div(100);
        else
            round[_rId + 1].jackpotAmount = (
                round[_rId].jackpotAmount.add(round[_rId].amount.mul(88) / 100)
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            );
        
        round[_rId + 1].start = now;
        rId++;
        sId = 1;
    }
    
    function getStageTargetAmount(uint256 _sId)
        public
        view
        returns(uint256)
    {
        return bankCompute.getStageTargetAmount(_sId);
    }
    
    function computeEarningsAmount(uint256 _sId, uint256 _amount, uint256 _currentTargetAmount, uint256 _expectEndSid, uint256 _ratio)
        public
        view
        returns(uint256)
    {
        return bankCompute.computeEarningsAmount(_sId, _amount, _currentTargetAmount, _expectEndSid, _ratio);
    }
    
    function getEarningsAmountByGoodsIndex(uint256 _goodsIndex)
        public
        view
        returns(uint256, uint256, uint256, bool)
    {
        FBankdatasets.Goods memory _goods = goodsList[_goodsIndex];
        uint256 _sId = sId;
        uint256 _amount;
        uint256 _targetExpectedAmount;
        uint256 _targetAmount;
        if(_goods.stepSize == 0){
            if(round[_goods.rId].ended == true){
                if(round[_goods.rId].endSid > _goods.endSid){
                    _targetExpectedAmount = getStageTargetAmount(_goods.startSid);
                    _targetAmount = 
                        stage[_goods.rId][_goods.startSid].dividendAmount <= _targetExpectedAmount ? 
                        _targetExpectedAmount : stage[_goods.rId][_goods.startSid].dividendAmount;
                    _targetAmount = _targetAmount.mul(100) / 88;
                    _amount = computeEarningsAmount(
                        _goods.startSid, 
                        _goods.amount, 
                        _targetAmount, 
                        _goods.endSid, 
                        100 - _goods.protectRatio
                        );
                    
                }else
                    _amount = _goods.amount.mul(_goods.protectRatio.mul(88)) / 10000;
                    
                if(round[_goods.rId].endSid == _goods.startSid)
                    _amount = _amount.add(
                        _goods.amount.mul(
                            getRoundJackpot(_goods.rId)
                            ).div(stage[_goods.rId][_goods.startSid].amount)
                            );
                
                return (_amount, 0, 0, true);
            }else{
                if(_sId > _goods.endSid){
                    _targetExpectedAmount = getStageTargetAmount(_goods.startSid);
                    _targetAmount = 
                        stage[_goods.rId][_goods.startSid].dividendAmount <= _targetExpectedAmount ?
                        _targetExpectedAmount : stage[_goods.rId][_goods.startSid].dividendAmount;
                    _targetAmount = _targetAmount.mul(100) / 88;
                    _amount = computeEarningsAmount(
                        _goods.startSid, 
                        _goods.amount, 
                        _targetAmount, 
                        _goods.endSid, 
                        100 - _goods.protectRatio
                        );
                }else
                    return (0, 0, 0, false);
            }
            return (_amount, 0, 0, true);
            
        }else{
            
            uint256 _startSid = _goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid;
            uint256 _ratio = 100 - _goods.protectRatio;
            uint256 _reachAmount = _goods.reachAmount;
            if(round[_goods.rId].ended == true){
                
                while(true){
                    
                    if(_startSid - (_goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid) > 100){
                        return (_amount, _startSid, _reachAmount, false);
                    }
                    
                    if(round[_goods.rId].endSid > _startSid.add(_goods.stepSize)){
                        _targetExpectedAmount = getStageTargetAmount(_startSid);
                        _targetAmount = 
                            stage[_goods.rId][_startSid].dividendAmount <= _targetExpectedAmount ? 
                            _targetExpectedAmount : stage[_goods.rId][_startSid].dividendAmount;
                        _targetAmount = _targetAmount.mul(100) / 88;
                        if(_startSid == _goods.endSid){
                            _amount = _amount.add(
                                computeEarningsAmount(
                                    _startSid, 
                                    _goods.endAmount, 
                                    _targetAmount, 
                                    _startSid.add(_goods.stepSize), 
                                    _ratio
                                    )
                                );
                            return (_amount, _goods.endSid, 0, true);
                        }
                        _amount = _amount.add(
                            computeEarningsAmount(
                                _startSid, 
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount, 
                                _targetAmount, 
                                _startSid.add(_goods.stepSize), 
                                _ratio
                                )
                            );
                        _reachAmount = 
                            _reachAmount.add(
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount
                            );
                    }else{
                        
                        _amount = _amount.add(
                            (_goods.amount.sub(_reachAmount))
                            .mul(_goods.protectRatio.mul(88)) / 10000
                            );
                        
                        if(round[_goods.rId].endSid == _goods.endSid)
                            _amount = _amount.add(
                                _goods.endAmount.mul(getRoundJackpot(_goods.rId))
                                .div(stage[_goods.rId][_goods.endSid].amount)
                                );
                        
                        return (_amount, _goods.endSid, 0, true);
                    }
                    
                    _startSid++;
                }
                
            }else{
                while(true){
                    
                    if(_startSid - (_goods.withdrawSid == 0 ? _goods.startSid : _goods.withdrawSid) > 100){
                        return (_amount, _startSid, _reachAmount, false);
                    }
                    
                    if(_sId > _startSid.add(_goods.stepSize)){
                        _targetExpectedAmount = getStageTargetAmount(_startSid);
                        _targetAmount = 
                            stage[_goods.rId][_startSid].dividendAmount <= _targetExpectedAmount ? 
                            _targetExpectedAmount : stage[_goods.rId][_startSid].dividendAmount;
                        _targetAmount = _targetAmount.mul(100) / 88;
                        if(_startSid == _goods.endSid){
                            _amount = _amount.add(
                                computeEarningsAmount(
                                    _startSid, 
                                    _goods.endAmount, 
                                    _targetAmount, 
                                    _startSid.add(_goods.stepSize), 
                                    _ratio
                                    )
                                );
                            return (_amount, _goods.endSid, 0, true);
                        }
                        _amount = _amount.add(
                            computeEarningsAmount(
                                _startSid, 
                                _startSid == _goods.startSid ? _goods.startAmount : _targetAmount, 
                                _targetAmount, 
                                _startSid.add(_goods.stepSize), 
                                _ratio
                                )
                            );
                        _reachAmount = 
                            _reachAmount.add(
                                _startSid == _goods.startSid ? 
                                _goods.startAmount : _targetAmount
                            );
                    }else    
                        return (_amount, _startSid, _reachAmount, false);
                    
                    _startSid++;
                }
            }
        }
    }
    
    function getRoundJackpot(uint256 _rId)
        public
        view
        returns(uint256)
    {
        return (
            (
                round[_rId].jackpotAmount
                .add(round[_rId].amount.mul(88) / 100))
                .sub(round[_rId].protectAmount)
                .sub(round[_rId].dividendAmount)
            ).mul(80).div(100);
    }
    
    function getHeadInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 _targetExpectedAmount = getStageTargetAmount(sId);
        
        return
            (
                rId,
                sId,
                stage[rId][sId].start.add(stageDuration),
                stage[rId][sId].amount,
                (
                    stage[rId][sId].dividendAmount <= _targetExpectedAmount ? 
                    _targetExpectedAmount : stage[rId][sId].dividendAmount
                ).mul(100) / 88,
                round[rId].jackpotAmount.add(round[rId].amount.mul(88) / 100)
                .sub(round[rId].protectAmount)
                .sub(round[rId].dividendAmount)
            );
    }
    
    function getPlayerGoodList(address _player)
        public
        view
        returns(uint256[])
    {
        return playerGoodsList[_player];
    }

    function totalSupply() 
        public 
        view 
        returns (uint256 total)
    {
        return cardList.length;
    }
    
    function balanceOf(address _owner) 
        public 
        view 
        returns (uint256 balance)
    {
        uint256 _length = cardList.length;
        uint256 _count;
        for(uint256 i = 0; i < _length; i++){
            if(cardList[i].playerAddress == _owner)
                _count++;
        }
        
        return _count;
    }
    
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        returns (address owner)
    {
        require(cardList.length > _tokenId, "tokenId error");
        owner = cardList[_tokenId].playerAddress;
        require(owner != address(0), "No owner");
    }
    
    function approve(address _to, uint256 _tokenId)
        senderVerify()
        public
    {
        require (register[_to] != bytes32(0), "Not a registered user");
        require (msg.sender == cardList[_tokenId].playerAddress, "The card does not belong to you");
        require (cardList.length > _tokenId, "tokenId error");
        require (cardIndexToApproved[_tokenId] == address(0), "Approved");
        
        cardIndexToApproved[_tokenId] = _to;
        
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId)
        senderVerify()
        public
    {
        address _newOwner = msg.sender;
        address _oldOwner = cardList[_tokenId].playerAddress;
        
        require(_newOwner != address(0), "Address error");
        require(_newOwner == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _newOwner;
        delete cardIndexToApproved[_tokenId];
        
        emit Transfer(_oldOwner, _newOwner, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) 
        senderVerify()
        public
    {
        require (msg.sender == cardList[_tokenId].playerAddress, "The card does not belong to you");
        require(_to != address(0), "Address error");
        require(_to == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _to;
        
        if(cardIndexToApproved[_tokenId] != address(0))
            delete cardIndexToApproved[_tokenId];
        
        emit Transfer(msg.sender, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId)
        senderVerify()
        public
    {
        require (_from == cardList[_tokenId].playerAddress, "Owner error");
        require(_to != address(0), "Address error");
        require(_to == cardIndexToApproved[_tokenId], "Without permission");
        
        cardList[_tokenId].playerAddress = _to;
        delete cardIndexToApproved[_tokenId];
        
        emit Transfer(_from, _to, _tokenId);
    }
    
}

library FBankdatasets {
    
    struct Round {
        uint256 start;
        uint256 end;
        bool ended;
        uint256 endSid;
        uint256 amount;
        uint256 protectAmount;
        uint256 dividendAmount;
        uint256 jackpotAmount;
    }
    
    struct Stage {
        uint256 start;
        uint256 amount;
        uint256 protectAmount;
        uint256 dividendAmount;
    }
    
    struct Goods {
        uint256 rId;
        uint256 startSid;
        uint256 endSid;
        uint256 withdrawSid;
        uint256 amount;
        uint256 startAmount;
        uint256 endAmount;
        uint256 reachAmount;
        uint256 stepSize;
        uint256 protectRatio;
    }
    
    struct Card {
        address playerAddress;
        uint256 amount;
    }
}

/**
 * Anti clone protection.
 * Do not clone this contract without permission even if you manage to break the conceal. 
 * The concealed code contains core calculations necessary for this contract to function. 
 * This contract can be licensed for a fee, contact us instead of cloning!
 */ 
interface FairBankCompute {
    function getStageTargetAmount(uint256 _sId) external view returns(uint256);
    function computeEarningsAmount(uint256 _sId, uint256 _amount, uint256 _currentTargetAmount, uint256 _expectEndSid, uint256 _ratio) external view returns(uint256);
}

library NameFilter {
    
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 3, "string must be between 4 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        for (uint256 i = 0; i < _length; i++)
        {
            require
            (
                // OR uppercase A-Z
                (_temp[i] > 0x40 && _temp[i] < 0x5b) ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                "string contains invalid characters"
            );
        }
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
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