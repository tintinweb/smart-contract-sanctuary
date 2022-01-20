// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./AggregatorV3Interface.sol";
import "./IERC20.sol";
import "./KeeperCompatible.sol";

contract GameV1 is KeeperCompatible {
    //Owner Address
    address public owner;
    IERC20 ierc20;
    AggregatorV3Interface internal priceFeed;
    //Structure for Player Bets Details
    struct predictDetails {
        string currency;
        bool insured;
        uint256 stackAmount;
        bool upOrDown;
        uint256 duration;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        int256 currentCurrencyPrice;
        int256 endingCurrencyPrice;
        string playerStatus;
    }

    // Counter Every Time Predictor Enter
    mapping(address => uint256) private playerIDCounter;
    mapping(address => mapping(uint256 => predictDetails)) public prediction;
    //Structure for Player Bets ID
    struct BetReferenceID {
        address currentPlayer;
        uint256 ID;
    }
    //Bet Arrays Active & Ended Both 
    BetReferenceID[] public activeBetRefrences;
    BetReferenceID[] public endedBetRefrences;

    // Mapping of  Winners List and Balance
    mapping(address => uint256) public playerStackBalance;
    mapping(address => uint256) public playerBalance;

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
    // keepers Variable
    uint private immutable interval;
    uint private lastimeInvokeCall;

    constructor() {
        //Setting Owner Address
        owner = msg.sender;
        //Setting Rewards Initial Value
        insuredReward = 10;
        noninsuredReward = 80;
        // Setting Stake Reward & Duration
        stackDuration = 7 days;
        stackRewardPer = 25;

        // Keepers Variables
        interval = 60;
        lastimeInvokeCall = block.timestamp;

    }

    // Set Token Address For Game Contract in Order To Use IERC20
    function SetTokenAddress(address _tokenAddress) public onlyOwner {
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
        require(msg.sender == owner,"Only Owner");
    }

    // Game Method Predict Player Can Predict 
    function predict(string memory _currency,bool isInsured,uint256 _stackAmount,bool _upOrDown,uint _duration) public zeroAddress returns (bool) {
        priceFeed = setCurrency(_currency);
        int256 price = getLatestPrice();
        playerIDCounter[msg.sender] = playerIDCounter[msg.sender] + 1;
        uint startTime = block.timestamp;
        uint endTime = block.timestamp+_duration*60; 
        prediction[msg.sender][playerIDCounter[msg.sender]] = predictDetails(
            _currency,
            isInsured,
            _stackAmount,
            _upOrDown,
            _duration,
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
                 // Logic To Remove Bets 
                activeBetRefrences[i] = activeBetRefrences[activeBetRefrences.length-1];
                activeBetRefrences.pop();
            
            }else{
                i++;
            }
        }
        // Bets Will Remove Between 23:50 to 23:59
        uint start = ((block.timestamp/86400)*86400) + 23 * 3600 + 55 * 60; // 23:55 Time Stamp of Current Date in UTC
        uint end =  ((block.timestamp/86400)*86400) + 23 * 3600 + 58 * 60; // 23:59  Time Stamp  of Current Date in UTC

        if(block.timestamp >= start && block.timestamp <= end){
        delete endedBetRefrences;
        }

        if(endedStackReference.length >=1000){
            delete endedStackReference;
        }
        
    }

    function setReward(uint256 _insured, uint256 _notinsured) public zeroAddress onlyOwner{
        insuredReward = _insured;
        noninsuredReward = _notinsured;
    }
    function setStackingDetails(
        uint256 _stackRewardPercentage,
        uint256 _stackDuration
    ) public  zeroAddress onlyOwner returns (bool) {
        stackDuration = _stackDuration * 86400;
        stackRewardPer = _stackRewardPercentage;
        return true;
    }

    // Set Currency Mainnet AggregatorV3Interface Address 
    function setCurrency(string memory _currency)
        private
        pure
        returns (AggregatorV3Interface)
    {
        if (keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("BTC"))) {
            return AggregatorV3Interface(0xc907E116054Ad103354f2D350FD2514433D57F6f);
        } else if (keccak256(abi.encodePacked(_currency)) ==keccak256(abi.encodePacked("ETH"))){
            return AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        } else if (keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("DAI"))) {
            return AggregatorV3Interface(0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D);
        } else if (keccak256(abi.encodePacked(_currency)) ==keccak256(abi.encodePacked("MATIC"))) {
            return AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        }
        return AggregatorV3Interface(address(0));
    }
    function getLatestPrice() private view returns (int256) {
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
    
    function claimStackTokens() public zeroAddress {
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
                activeStackReference[i] = activeStackReference[activeStackReference.length-1];
                activeStackReference.pop();
                
            }else{
                i++;
            }
        }

        if(totalBalanceToTransfer == 0){
            revert("Your Stake Time is Not Expired");
        }
        if (ierc20.balanceOf(address(this)) < totalBalanceToTransfer){
            //Throw Error Insufficient Balance 
            revert ("Insufficient Balance");
        }
        if (totalBalanceToTransfer > 0) {
            ierc20.transfer(msg.sender, totalBalanceToTransfer); // Transfering Total Stake Amount to Current Caller
            playerStackBalance[msg.sender] = playerStackBalance[msg.sender] - totalBalanceToTransfer; // Active Stake - Expired Bets
        }

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

    //Clean Up Methods For Ended Bet Reference & Ended Stake Reference
    function cleanEndedBetReference(uint _index)public onlyOwner{
        while(_index!=0){
        endedBetRefrences.pop();
        _index--;
        }
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