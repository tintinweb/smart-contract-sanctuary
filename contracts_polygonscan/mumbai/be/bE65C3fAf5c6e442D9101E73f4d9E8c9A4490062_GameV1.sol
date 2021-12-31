// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./AggregatorV3Interface.sol";
import "./IERC20.sol";
import "./KeeperCompatible.sol";

contract GameV1 is KeeperCompatible {
    address public owner;
    IERC20 ierc20;
    AggregatorV3Interface internal priceFeed;
    struct predictDetails {
        string currency;
        bool insured;
        uint256 stackAmount;
        bool upOrDown;
        uint256 slot;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        int256 currentCurrencyPrice;
        int256 endingCurrencyPrice;
        string playerStatus;
    }

    // Counter Every Time Predictor Enter
    mapping(address => uint256) private playerIDCounter;
    mapping(address => mapping(uint256 => predictDetails)) public prediction;
    struct BetReferenceID {
        address currentPlayer;
        uint256 ID;
    }
    // active players array which contain [address][ID] create
    BetReferenceID[] public activeBetRefrences;
    BetReferenceID[] public endedBetRefrences;

    // mapping to track winners list and balance
    mapping(address => uint256) public playerStackBalance;
    mapping(address => uint256) public playerBalance;

    // mapping to track stack list and balance

    //Variables to Set ResetReward in percentage
    uint256 private insuredReward;
    uint256 private noninsuredReward;

    // Struct for Player Stack Details
    struct LockStakingDetails {
        uint256 startStackTime;
        uint256 endedStackTime;
        uint256 stackAmount;
        uint256 rewardPercentage;
        uint256 totalRewardAmount;
    }

    struct CustomTime {
        uint256 hh;
        uint256 mm;
        uint256 ss;
    }
    // Struct For Stack Reference ID
    struct StackReferenceID {
        address stackPlayerAddress;
        uint256 ID;
    }
    // Mapping For Each Player Stack Counter
    mapping(address => uint256) private stackCounter;
    // mapping for lockStacking
    mapping(address => mapping(uint256 => LockStakingDetails)) public lockStaking;
    // Active & Ended Stack Player Array
    StackReferenceID[] public activeStackReference;
    StackReferenceID[] public endedStackReference;

    // Lockstacking Duration & Reward Percentage
    uint256 private stackDuration;
    uint256 private stackRewardPer;

    // Time Slot
    CustomTime [] public validSlots; 
    
    uint private immutable interval;
    uint private lastimeInvokeCall;

    constructor() {
        // Game
        owner = msg.sender;
        insuredReward = 10;
        noninsuredReward = 80;
        stackDuration = 5 minutes;
        stackRewardPer = 25;

        // Keepers Variables
        interval = 300;
        lastimeInvokeCall = block.timestamp;

        // Pushing Slot into Arrays
        validSlots.push(CustomTime(12,15,0));
        validSlots.push(CustomTime(12,25,0));
        validSlots.push(CustomTime(12,35,0));
        validSlots.push(CustomTime(12,45,0));
    }

    // Token Methods
    function SetTokenAddress(address _tokenAddress) public onlyOwner {
        //require(owner == msg.sender, "Only Owner Can Set Token");
        ierc20 = IERC20(_tokenAddress);
    }
    // Modifers alternative for Require Statement 
    modifier zeroAddress{
        _zeroAddress();
        _;
    }
    modifier onlyOwner{
        _onlyOwner();
        _;
    }
    // Private Function For Modifers
    function _zeroAddress() private view{
        require(msg.sender != address(0));
    }
    function _onlyOwner() private view{
        require(msg.sender == owner);
    }

    // Game Methods
    function predict(string memory _currency,bool isInsured,uint256 _stackAmount,bool _upOrDown,uint _slot) public zeroAddress returns (bool) {

        require(checkSlot(_slot),"Invalid Slot");
        priceFeed = setCurrency(_currency);
        int256 price = getLatestPrice(); // 1 ToDo: pass priceFeed as an argument
        // require(msg.sender != address(0), "Zero Address Detected");
        playerIDCounter[msg.sender] = playerIDCounter[msg.sender] + 1;
        uint startTime = block.timestamp;
        uint endTime = _slot; // Function That Give End Time According The Slot For He/She Predicting GMT
        require(endTime > startTime,"Slot Expired");
        prediction[msg.sender][playerIDCounter[msg.sender]] = predictDetails(
            _currency,
            isInsured,
            _stackAmount,
            _upOrDown,
            _slot,
            startTime,
            endTime,
            price,
            0,
            "predict"
        );
        ierc20.transferFrom(msg.sender, address(this), _stackAmount);
        activeBetRefrences.push(
            BetReferenceID((msg.sender), playerIDCounter[msg.sender])
        );
        
        return true;
    }

    function invokePrediction() public {
        //Here we will check which all bets are ended we will remove them from activeBetRefrences and push them to endedBetRefrences
        int256 currentPrice;
        // Declared Once Early Declared Inside Loop
        address PlayerAddress;
        uint256 PlayerId;
        uint i = 0;
        
        //loop activeBetRefrences
        while (i<activeBetRefrences.length) {
             PlayerAddress = activeBetRefrences[i].currentPlayer;
             PlayerId = activeBetRefrences[i].ID;
            if (block.timestamp >=prediction[PlayerAddress][PlayerId].endTimeStamp){
                // Set Currency & Get The Price
                    priceFeed = setCurrency(prediction[PlayerAddress][PlayerId].currency);
                    currentPrice = getLatestPrice(); //Pass 2 paramas one for price feed and another for roundid/timestamp/bid endtime
                    if (prediction[PlayerAddress][PlayerId].insured == true && prediction[PlayerAddress][PlayerId].upOrDown == true) {
                        //Player Insured Call Up
                            if (currentPrice >prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Won");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else if (currentPrice ==prediction[PlayerAddress][PlayerId].currentCurrencyPrice){
                                // if Price same no win no lose player can claim token
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Tie");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else {
                                //Lost the prediction but insured, so goes to stacking  
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Stack");
                                updateBalance(PlayerAddress,PlayerId);
                                activeStackReference.push(StackReferenceID((PlayerAddress),stackCounter[PlayerAddress]));
                            }
                        } else if (prediction[PlayerAddress][PlayerId].insured == true && prediction[PlayerAddress][PlayerId].upOrDown == false) {
                            //Player Insured Call Down
                            if (currentPrice < prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Won");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else if (currentPrice == prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                // if Price same no win no lose player can claim token
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Tie");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else {
                                setPredictDetails(PlayerAddress, PlayerId,currentPrice,"Stack");
                                updateBalance(PlayerAddress,PlayerId);
                                activeStackReference.push(StackReferenceID((PlayerAddress),stackCounter[PlayerAddress]));
                            }
                        }else if (prediction[PlayerAddress][PlayerId].insured == false && prediction[PlayerAddress][PlayerId].upOrDown == true) {
                        //Player Not Insured Call Up 
                            if (currentPrice >prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Won");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                                
                            } else if (currentPrice == prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                setPredictDetails(PlayerAddress, PlayerId, currentPrice, "Tie");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else {
                                setPredictDetails(PlayerAddress, PlayerId,currentPrice, "Lose");
                                endedBetRefrences.push(activeBetRefrences[i]);
                            }
                        } else if ( prediction[PlayerAddress][PlayerId].insured == false && prediction[PlayerAddress][PlayerId].upOrDown == false) {
                            // Player Not Insured Call Down
                            if (currentPrice < prediction[PlayerAddress][PlayerId].currentCurrencyPrice) {
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Won");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                            } else if (currentPrice == prediction[PlayerAddress][PlayerId].currentCurrencyPrice){
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Tie");
                                updateBalance(PlayerAddress,PlayerId);
                                endedBetRefrences.push(activeBetRefrences[i]);
                                
                            } else {
                                setPredictDetails(PlayerAddress,PlayerId,currentPrice,"Lose");
                                endedBetRefrences.push(activeBetRefrences[i]);
                            }
                        }
                 //delete activeBetRefrences[i];
                //removeNoOrder(i);
                activeBetRefrences[i] = activeBetRefrences[activeBetRefrences.length-1];
                activeBetRefrences.pop();
            
            }else{
                i++;
            }
        }
    }
    // Function to Remove Element from arrays
    // function removeNoOrder(uint256 _index) private {
    //     for (uint256 i = _index; i < activeBetRefrences.length - 1; i++) {
    //         activeBetRefrences[i] = activeBetRefrences[i + 1];
    //     }
    //     activeBetRefrences.pop();
    // }
    // function removeNoOrderStack(uint256 _index) private {
    //     for (uint256 j = _index; j < activeStackReference.length - 1; j++) {
    //         activeStackReference[j] = activeStackReference[j + 1];
    //     }
    //     activeStackReference.pop();
    // }
    function setReward(uint256 _insured, uint256 _notinsured) public zeroAddress onlyOwner{
        // require(msg.sender == owner, "Only Owner Can Set");
        // require(msg.sender != address(0), "Zero Address Detected");
        insuredReward = _insured;
        noninsuredReward = _notinsured;
    }
    function setStackingDetails(
        uint256 _stackRewardPercentage,
        uint256 _stackDuration
    ) public  zeroAddress onlyOwner returns (bool) {
        // require(msg.sender == owner, "Only Owner Can Set");
        // require(msg.sender != address(0), "Zero Address Detected");
        stackDuration = _stackDuration * 86400;
        stackRewardPer = _stackRewardPercentage;
        return true;
    }
    function setCurrency(string memory _currency)
        private
        pure
        returns (AggregatorV3Interface)
    {
        if (keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("BTC"))) {
            return AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);
        } else if (keccak256(abi.encodePacked(_currency)) ==keccak256(abi.encodePacked("ETH"))){
            return AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
        } else if (keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("DAI"))) {
            return AggregatorV3Interface(0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046);
        } else if (keccak256(abi.encodePacked(_currency)) ==keccak256(abi.encodePacked("MATIC"))) {
            return AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
        }
        return AggregatorV3Interface(address(0));
    }
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    // Claim Methods
    function claimTokenWinner() public zeroAddress returns (bool) {
        require(playerBalance[msg.sender] != 0,"Balance Zero");
        // require(msg.sender != address(0), "Zero Address Detected");
        ierc20.transferFrom(address(this),msg.sender,playerBalance[msg.sender]);
        playerBalance[msg.sender] = 0;
        return true;
    }
    
    function claimStackTokens() public zeroAddress returns (bool) {
        // require(msg.sender != address(0), "Zero Address Detected");
        require(playerStackBalance[msg.sender]!=0,"Balance Zero");
        uint256 totalBalanceToTransfer = 0;
        uint i =0;
        while (i < activeStackReference.length) {
            address playerAddress = activeStackReference[i].stackPlayerAddress;
            uint256 playerID = activeStackReference[i].ID;
            if (msg.sender == playerAddress && block.timestamp >= lockStaking[playerAddress][playerID].endedStackTime) // Current Caller Player address is in Stack Array
            {
                totalBalanceToTransfer += lockStaking[playerAddress][playerID].totalRewardAmount;
                endedStackReference.push(StackReferenceID((playerAddress),stackCounter[playerAddress]));
                //delete activeStackReference[i];
                //removeNoOrderStack(i);
                activeStackReference[i] = activeStackReference[activeStackReference.length-1];
                activeStackReference.pop();
                
            }else{
                i++;
            }
        }

        if (ierc20.balanceOf(address(this)) < totalBalanceToTransfer){
            //Throw error insufficient balance for stacking/game contract
            revert ("Insufficient Balance");
        } else if (totalBalanceToTransfer > 0) {
            ierc20.transfer(msg.sender, totalBalanceToTransfer);
            playerStackBalance[msg.sender] = 0;
        }

        return false;
    }
    // Function to Reduce Invoke Size
    function setPredictDetails(address _PlayerAddress,uint _PlayerId,int _currentPrice,string memory _status)private{
        prediction[_PlayerAddress][_PlayerId].endingCurrencyPrice = _currentPrice;
        prediction[_PlayerAddress][_PlayerId].playerStatus = _status;

    }
    // Function to Make Entry in Balances Mapping 
    function updateBalance(address _currentPlayer,uint _playerId) private{
        string memory _status = prediction[_currentPlayer][_playerId].playerStatus;
        bool isInsured = prediction[_currentPlayer][_playerId].insured;
        uint stakeBalance = prediction[_currentPlayer][_playerId].stackAmount;
        if(keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("Won"))){
            if(isInsured){
            playerBalance[_currentPlayer] = playerBalance[_currentPlayer] + ((prediction[_currentPlayer][_playerId].stackAmount * insuredReward) / 100)+ 
            (prediction[_currentPlayer][_playerId].stackAmount);
            ierc20.approve(_currentPlayer,playerBalance[_currentPlayer]);
            }else if(!isInsured){
               playerBalance[_currentPlayer] = playerBalance[_currentPlayer] + ((prediction[_currentPlayer][_playerId].stackAmount * noninsuredReward) / 100)+ 
            (prediction[_currentPlayer][_playerId].stackAmount);
            ierc20.approve(_currentPlayer,playerBalance[_currentPlayer]); 
            }
        }else if(keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("Stack"))){
        // Update The Stack Counter
             stackCounter[_currentPlayer] = stackCounter[_currentPlayer] +1;
        // Entries in LockStakingDetails
        lockStaking[_currentPlayer][stackCounter[_currentPlayer]] = LockStakingDetails(block.timestamp, block.timestamp + (stackDuration),
        stakeBalance,stackRewardPer,(stakeBalance * stackRewardPer) / 100);
        // Updating Stacking Balance Mapping
        playerStackBalance[_currentPlayer] =playerStackBalance[_currentPlayer] +((stakeBalance * stackRewardPer) / 100);
        } else if(keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("Tie"))){
            playerBalance[_currentPlayer] = playerBalance[_currentPlayer] + (prediction[_currentPlayer][_playerId].stackAmount);
            ierc20.approve(_currentPlayer,playerBalance[_currentPlayer]); 
        }

    }

    // Game Getters Functions
    function returnActiveBetReference() public view returns (BetReferenceID[] memory){
        return activeBetRefrences;
    }
    function returnEndedBetReference() public view returns (BetReferenceID[] memory){
        return endedBetRefrences;
    }
    function returnActiveStackBetreference() public view returns (StackReferenceID[] memory){
        return activeStackReference;
    }
    function returnEndedStackBetreference() public view returns (StackReferenceID[] memory){
        return endedStackReference;
    }
    function getInsuredReward() public view returns (uint256) {
        return insuredReward;
    }
    function getNonInsuredReward() public view returns (uint256) {
        return noninsuredReward;
    }
    function getStackDuration() public view returns (uint256) {
        return stackDuration;
    }
    function getStackRewardPer() public view returns (uint256) {
        return stackRewardPer;
    }
    
    // Slots Functions
    function checkSlot(uint _slot) private view returns(bool){
        for(uint i=0;i<validSlots.length;i++){
            uint slottimeStamp =((block.timestamp/86400)*86400 ) + (validSlots[i].hh * 3600) + (validSlots[i].mm *60) + validSlots[i].ss;
            if(slottimeStamp ==_slot){
                return true;
            }
        }
        return false;
    }

    function getSlot() public view returns(CustomTime [] memory){
        return validSlots;
    }
    function updateSlots(uint _HOUR,uint _MIN,uint _SEC,uint _index) public  onlyOwner returns(bool){
        validSlots[_index] = (CustomTime(_HOUR,_MIN,_SEC));
        return true;
    }

    function addSlot(uint _HOUR , uint _MIN, uint _SEC)public onlyOwner{
        validSlots.push(CustomTime(_HOUR,_MIN,_SEC));
    }

    function removeSlot(uint _SlotNo)public onlyOwner{
        delete validSlots[_SlotNo];
        for(uint i = _SlotNo; i < validSlots.length -1;i++){
            validSlots[i] = validSlots[i+1];
        }
        validSlots.pop();
    }

    // Keepers Methods
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastimeInvokeCall) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        lastimeInvokeCall = block.timestamp;
        invokePrediction();
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }

}