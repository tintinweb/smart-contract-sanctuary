pragma solidity ^0.4.18;


contract DataSourceInterface {

    function isDataSource() public pure returns (bool);

    function getGroupResult(uint matchId) external;
    function getRoundOfSixteenTeams(uint index) external;
    function getRoundOfSixteenResult(uint matchId) external;
    function getQuarterResult(uint matchId) external;
    function getSemiResult(uint matchId) external;
    function getFinalTeams() external;
    function getYellowCards() external;
    function getRedCards() external;

}


/**
* @title DataLayer.
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract DataLayer{

    
    uint256 constant WCCTOKEN_CREATION_LIMIT = 5000000;
    uint256 constant STARTING_PRICE = 45 finney;
    
    /// Epoch times based on when the prices change.
    uint256 constant FIRST_PHASE  = 1527476400;
    uint256 constant SECOND_PHASE = 1528081200;
    uint256 constant THIRD_PHASE  = 1528686000;
    uint256 constant WORLD_CUP_START = 1528945200;

    DataSourceInterface public dataSource;
    address public dataSourceAddress;

    address public adminAddress;
    uint256 public deploymentTime = 0;
    uint256 public gameFinishedTime = 0; //set this to now when oraclize was called.
    uint32 public lastCalculatedToken = 0;
    uint256 public pointsLimit = 0;
    uint32 public lastCheckedToken = 0;
    uint32 public winnerCounter = 0;
    uint32 public lastAssigned = 0;
    uint256 public auxWorstPoints = 500000000;
    uint32 public payoutRange = 0;
    uint32 public lastPrizeGiven = 0;
    uint256 public prizePool = 0;
    uint256 public adminPool = 0;
    uint256 public finalizedTime = 0;

    enum teamState { None, ROS, QUARTERS, SEMIS, FINAL }
    enum pointsValidationState { Unstarted, LimitSet, LimitCalculated, OrderChecked, TopWinnersAssigned, WinnersAssigned, Finished }
    
    /**
    * groups1     scores of the first half of matches (8 bits each)
    * groups2     scores of the second half of matches (8 bits each)
    * brackets    winner&#39;s team ids of each round (5 bits each)
    * timeStamp   creation timestamp
    * extra       number of yellow and red cards (16 bits each)
    */
    struct Token {
        uint192 groups1;
        uint192 groups2;
        uint160 brackets;
        uint64 timeStamp;
        uint32  extra;
    }

    struct GroupResult{
        uint8 teamOneGoals;
        uint8 teamTwoGoals;
    }

    struct BracketPhase{
        uint8[16] roundOfSixteenTeamsIds;
        mapping (uint8 => bool) teamExists;
        mapping (uint8 => teamState) middlePhaseTeamsIds;
        uint8[4] finalsTeamsIds;
    }

    struct Extras {
        uint16 yellowCards;
        uint16 redCards;
    }

    
    // List of all tokens
    Token[] tokens;

    GroupResult[48] groupsResults;
    BracketPhase bracketsResults;
    Extras extraResults;

    // List of all tokens that won 
    uint256[] sortedWinners;

    // List of the worst tokens (they also win)
    uint256[] worstTokens;
    pointsValidationState public pValidationState = pointsValidationState.Unstarted;

    mapping (address => uint256[]) public tokensOfOwnerMap;
    mapping (uint256 => address) public ownerOfTokenMap;
    mapping (uint256 => address) public tokensApprovedMap;
    mapping (uint256 => uint256) public tokenToPayoutMap;
    mapping (uint256 => uint16) public tokenToPointsMap;    


    event LogTokenBuilt(address creatorAddress, uint256 tokenId, Token token);
    event LogDataSourceCallbackList(uint8[] result);
    event LogDataSourceCallbackInt(uint8 result);
    event LogDataSourceCallbackTwoInt(uint8 result, uint8 result2);

}


///Author Dieter Shirley (https://github.com/dete)
contract ERC721 {

    event LogTransfer(address from, address to, uint256 tokenId);
    event LogApproval(address owner, address approved, uint256 tokenId);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);

}












/**
* @title AccessControlLayer
* @author CryptoCup Team (https://cryptocup.io/about)
* @dev Containes basic admin modifiers to restrict access to some functions. Allows
* for pauseing, and setting emergency stops.
*/
contract AccessControlLayer is DataLayer{

    bool public paused = false;
    bool public finalized = false;
    bool public saleOpen = true;

   /**
   * @dev Main modifier to limit access to delicate functions.
   */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    /**
    * @dev Modifier that checks that the contract is not paused
    */
    modifier isNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier that checks that the contract is paused
    */
    modifier isPaused() {
        require(paused);
        _;
    }

    /**
    * @dev Modifier that checks that the contract has finished successfully
    */
    modifier hasFinished() {
        require((gameFinishedTime != 0) && now >= (gameFinishedTime + (15 days)));
        _;
    }

    /**
    * @dev Modifier that checks that the contract has finalized
    */
    modifier hasFinalized() {
        require(finalized);
        _;
    }

    /**
    * @dev Checks if pValidationState is in the provided stats
    * @param state State required to run
    */
    modifier checkState(pointsValidationState state){
        require(pValidationState == state);
        _;
    }

    /**
    * @dev Transfer contract&#39;s ownership
    * @param _newAdmin Address to be set
    */
    function setAdmin(address _newAdmin) external onlyAdmin {

        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    /**
    * @dev Sets the contract pause state
    * @param state True to pause
    */
    function setPauseState(bool state) external onlyAdmin {
        paused = state;
    }

    /**
    * @dev Sets the contract to finalized
    * @param state True to finalize
    */
    function setFinalized(bool state) external onlyAdmin {
        paused = state;
        finalized = state;
        if(finalized == true)
            finalizedTime = now;
    }
}

/**
* @title CryptoCupToken, main implemantations of the ERC721 standard
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract CryptocupToken is AccessControlLayer, ERC721 {

    //FUNCTIONALTIY
    /**
    * @notice checks if a user owns a token
    * @param userAddress - The address to check.
    * @param tokenId - ID of the token that needs to be verified.
    * @return true if the userAddress provided owns the token.
    */
    function _userOwnsToken(address userAddress, uint256 tokenId) internal view returns (bool){

         return ownerOfTokenMap[tokenId] == userAddress;

    }

    /**
    * @notice checks if the address provided is approved for a given token 
    * @param userAddress 
    * @param tokenId 
    * @return true if it is aproved
    */
    function _tokenIsApproved(address userAddress, uint256 tokenId) internal view returns (bool) {

        return tokensApprovedMap[tokenId] == userAddress;
    }

    /**
    * @notice transfers the token specified from sneder address to receiver address.
    * @param fromAddress the sender address that initially holds the token.
    * @param toAddress the receipient of the token.
    * @param tokenId ID of the token that will be sent.
    */
    function _transfer(address fromAddress, address toAddress, uint256 tokenId) internal {

      require(tokensOfOwnerMap[toAddress].length < 100);
      require(pValidationState == pointsValidationState.Unstarted);
      
      tokensOfOwnerMap[toAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = toAddress;

      uint256[] storage tokenArray = tokensOfOwnerMap[fromAddress];
      for (uint256 i = 0; i < tokenArray.length; i++){
        if(tokenArray[i] == tokenId){
          tokenArray[i] = tokenArray[tokenArray.length-1];
        }
      }
      delete tokenArray[tokenArray.length-1];
      tokenArray.length--;

      delete tokensApprovedMap[tokenId];

    }

    /**
    * @notice Approve the address for a given token
    * @param tokenId - ID of token to be approved
    * @param userAddress - Address that will be approved
    */
    function _approve(uint256 tokenId, address userAddress) internal {
        tokensApprovedMap[tokenId] = userAddress;
    }

    /**
    * @notice set token owner to an address
    * @dev sets token owner on the contract data structures
    * @param ownerAddress address to be set
    * @param tokenId Id of token to be used
    */
    function _setTokenOwner(address ownerAddress, uint256 tokenId) internal{

    	tokensOfOwnerMap[ownerAddress].push(tokenId);
      ownerOfTokenMap[tokenId] = ownerAddress;
    
    }

    //ERC721 INTERFACE
    function name() public view returns (string){
      return "Cryptocup";
    }

    function symbol() public view returns (string){
      return "CC";
    }

    
    function balanceOf(address userAddress) public view returns (uint256 count) {
      return tokensOfOwnerMap[userAddress].length;

    }

    function transfer(address toAddress,uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_userOwnsToken(msg.sender, tokenId));

      _transfer(msg.sender, toAddress, tokenId);
      LogTransfer(msg.sender, toAddress, tokenId);

    }


    function transferFrom(address fromAddress, address toAddress, uint256 tokenId) external isNotPaused {

      require(toAddress != address(0));
      require(toAddress != address(this));
      require(_tokenIsApproved(msg.sender, tokenId));
      require(_userOwnsToken(fromAddress, tokenId));

      _transfer(fromAddress, toAddress, tokenId);
      LogTransfer(fromAddress, toAddress, tokenId);

    }

    function approve( address toAddress, uint256 tokenId) external isNotPaused {

        require(toAddress != address(0));
        require(_userOwnsToken(msg.sender, tokenId));

        _approve(tokenId, toAddress);
        LogApproval(msg.sender, toAddress, tokenId);

    }

    function totalSupply() public view returns (uint) {

        return tokens.length;

    }

    function ownerOf(uint256 tokenId) external view returns (address ownerAddress) {

        ownerAddress = ownerOfTokenMap[tokenId];
        require(ownerAddress != address(0));

    }

    function tokensOfOwner(address ownerAddress) external view returns(uint256[] tokenIds) {

        tokenIds = tokensOfOwnerMap[ownerAddress];

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
}


/**
* @title GameLogicLayer, contract in charge of everything related to calculating points, asigning
* winners, and distributing prizes.
* @author CryptoCup Team (https://cryptocup.io/about)
*/
contract GameLogicLayer is CryptocupToken{

    using SafeMath for *;

    uint8 TEAM_RESULT_MASK_GROUPS = 15;
    uint160 RESULT_MASK_BRACKETS = 31;
    uint16 EXTRA_MASK_BRACKETS = 65535;

    uint16 private lastPosition;
    uint16 private superiorQuota;
    
    uint16[] private payDistributionAmount = [1,1,1,1,1,1,1,1,1,1,5,5,10,20,50,100,100,200,500,1500,2500];
    uint32[] private payoutDistribution;

	event LogGroupDataArrived(uint matchId, uint8 result, uint8 result2);
    event LogRoundOfSixteenArrived(uint id, uint8 result);
    event LogMiddlePhaseArrived(uint matchId, uint8 result);
    event LogFinalsArrived(uint id, uint8[4] result);
    event LogExtrasArrived(uint id, uint16 result);
    
    //ORACLIZE
    function dataSourceGetGroupResult(uint matchId) external onlyAdmin{
        dataSource.getGroupResult(matchId);
    }

    function dataSourceGetRoundOfSixteen(uint index) external onlyAdmin{
        dataSource.getRoundOfSixteenTeams(index);
    }

    function dataSourceGetRoundOfSixteenResult(uint matchId) external onlyAdmin{
        dataSource.getRoundOfSixteenResult(matchId);
    }

    function dataSourceGetQuarterResult(uint matchId) external onlyAdmin{
        dataSource.getQuarterResult(matchId);
    }
    
    function dataSourceGetSemiResult(uint matchId) external onlyAdmin{
        dataSource.getSemiResult(matchId);
    }

    function dataSourceGetFinals() external onlyAdmin{
        dataSource.getFinalTeams();
    }

    function dataSourceGetYellowCards() external onlyAdmin{
        dataSource.getYellowCards();
    }

    function dataSourceGetRedCards() external onlyAdmin{
        dataSource.getRedCards();
    }

    /**
    * @notice sets a match result to the contract storage
    * @param matchId id of match to check
    * @param result number of goals the first team scored
    * @param result2 number of goals the second team scored
    */
    
    function dataSourceCallbackGroup(uint matchId, uint8 result, uint8 result2) public {

        require (msg.sender == dataSourceAddress);
        require (matchId >= 0 && matchId <= 47);

        groupsResults[matchId].teamOneGoals = result;
        groupsResults[matchId].teamTwoGoals = result2;

        LogGroupDataArrived(matchId, result, result2);

    }

    /**
    * @notice sets the sixteen teams that made it through groups to the contract storage
    * @param id index of sixteen teams
    * @param result results to be set
    */

    function dataSourceCallbackRoundOfSixteen(uint id, uint8 result) public {

        require (msg.sender == dataSourceAddress);

        bracketsResults.roundOfSixteenTeamsIds[id] = result;
        bracketsResults.teamExists[result] = true;
        
        LogRoundOfSixteenArrived(id, result);

    }

    function dataSourceCallbackTeamId(uint matchId, uint8 result) public {
        require (msg.sender == dataSourceAddress);

        teamState state = bracketsResults.middlePhaseTeamsIds[result];

        if (matchId >= 48 && matchId <= 55){
            if (state < teamState.ROS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.ROS;
        } else if (matchId >= 56 && matchId <= 59){
            if (state < teamState.QUARTERS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.QUARTERS;
        } else if (matchId == 60 || matchId == 61){
            if (state < teamState.SEMIS)
                bracketsResults.middlePhaseTeamsIds[result] = teamState.SEMIS;
        }

        LogMiddlePhaseArrived(matchId, result);
    }

    /**
    * @notice sets the champion, second, third and fourth teams to the contract storage
    * @param id 
    * @param result ids of the four teams
    */
    function dataSourceCallbackFinals(uint id, uint8[4] result) public {

        require (msg.sender == dataSourceAddress);

        uint256 i;

        for(i = 0; i < 4; i++){
            bracketsResults.finalsTeamsIds[i] = result[i];
        }

        LogFinalsArrived(id, result);

    }

    /**
    * @notice sets the number of cards to the contract storage
    * @param id 101 for yellow cards, 102 for red cards
    * @param result amount of cards
    */
    function dataSourceCallbackExtras(uint id, uint16 result) public {

        require (msg.sender == dataSourceAddress);

        if (id == 101){
            extraResults.yellowCards = result;
        } else if (id == 102){
            extraResults.redCards = result;
        }

        LogExtrasArrived(id, result);

    }

    /**
    * @notice check if prediction for a match winner is correct
    * @param realResultOne amount of goals team one scored
    * @param realResultTwo amount of goals team two scored
    * @param tokenResultOne amount of goals team one was predicted to score
    * @param tokenResultTwo amount of goals team two was predicted to score
    * @return 
    */
    function matchWinnerOk(uint8 realResultOne, uint8 realResultTwo, uint8 tokenResultOne, uint8 tokenResultTwo) internal pure returns(bool){

        int8 realR = int8(realResultOne - realResultTwo);
        int8 tokenR = int8(tokenResultOne - tokenResultTwo);

        return (realR > 0 && tokenR > 0) || (realR < 0 && tokenR < 0) || (realR == 0 && tokenR == 0);

    }

    /**
    * @notice get points from a single match 
    * @param matchIndex 
    * @param groupsPhase token predictions
    * @return 10 if predicted score correctly, 3 if predicted only who would win
    * and 0 if otherwise
    */
    function getMatchPointsGroups (uint256 matchIndex, uint192 groupsPhase) internal view returns(uint16 matchPoints) {

        uint8 tokenResultOne = uint8(groupsPhase & TEAM_RESULT_MASK_GROUPS);
        uint8 tokenResultTwo = uint8((groupsPhase >> 4) & TEAM_RESULT_MASK_GROUPS);

        uint8 teamOneGoals = groupsResults[matchIndex].teamOneGoals;
        uint8 teamTwoGoals = groupsResults[matchIndex].teamTwoGoals;

        if (teamOneGoals == tokenResultOne && teamTwoGoals == tokenResultTwo){
            matchPoints += 10;
        } else {
            if (matchWinnerOk(teamOneGoals, teamTwoGoals, tokenResultOne, tokenResultTwo)){
                matchPoints += 3;
            }
        }

    }

    /**
    * @notice calculates points from the last two matches
    * @param brackets token predictions
    * @return amount of points gained from the last two matches
    */
    function getFinalRoundPoints (uint160 brackets) internal view returns(uint16 finalRoundPoints) {

        uint8[3] memory teamsIds;

        for (uint i = 0; i <= 2; i++){
            brackets = brackets >> 5; //discard 4th place
            teamsIds[2-i] = uint8(brackets & RESULT_MASK_BRACKETS);
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[0]){
            finalRoundPoints += 100;
        }

        if (teamsIds[2] == bracketsResults.finalsTeamsIds[2]){
            finalRoundPoints += 25;
        }

        if (teamsIds[0] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

        if (teamsIds[1] == bracketsResults.finalsTeamsIds[0] || teamsIds[1] == bracketsResults.finalsTeamsIds[1]){
            finalRoundPoints += 50;
        }

    }

    /**
    * @notice calculates points for round of sixteen, quarter-finals and semifinals
    * @param size amount of matches in round
    * @param round ros, qf, sf or f
    * @param brackets predictions
    * @return amount of points
    */
    function getMiddleRoundPoints(uint8 size, teamState round, uint160 brackets) internal view returns(uint16 middleRoundResults){

        uint8 teamId;

        for (uint i = 0; i < size; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (uint(bracketsResults.middlePhaseTeamsIds[teamId]) >= uint(round) ) {
                middleRoundResults+=60;
            }

            brackets = brackets >> 5;
        }

    }

    /**
    * @notice calculates points for correct predictions of group winners
    * @param brackets token predictions
    * @return amount of points
    */
    function getQualifiersPoints(uint160 brackets) internal view returns(uint16 qualifiersPoints){

        uint8 teamId;

        for (uint256 i = 0; i <= 15; i++){
            teamId = uint8(brackets & RESULT_MASK_BRACKETS);

            if (teamId == bracketsResults.roundOfSixteenTeamsIds[15-i]){
                qualifiersPoints+=30;
            } else if (bracketsResults.teamExists[teamId]){
                qualifiersPoints+=25;
            }
            
            brackets = brackets >> 5;
        }

    }

    /**
    * @notice calculates points won by yellow and red cards predictions
    * @param extras token predictions
    * @return amount of points
    */
    function getExtraPoints(uint32 extras) internal view returns(uint16 extraPoints){

        uint16 redCards = uint16(extras & EXTRA_MASK_BRACKETS);
        extras = extras >> 16;
        uint16 yellowCards = uint16(extras);

        if (redCards == extraResults.redCards){
            extraPoints+=20;
        }

        if (yellowCards == extraResults.yellowCards){
            extraPoints+=20;
        }

    }

    /**
    * @notice calculates total amount of points for a token
    * @param t token to calculate points for
    * @return total amount of points
    */
    function calculateTokenPoints (Token memory t) internal view returns(uint16 points){
        
        //Groups phase 1
        uint192 g1 = t.groups1;
        for (uint256 i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(23-i, g1);
            g1 = g1 >> 8;
        }

        //Groups phase 2
        uint192 g2 = t.groups2;
        for (i = 0; i <= 23; i++){
            points+=getMatchPointsGroups(47-i, g2);
            g2 = g2 >> 8;
        }
        
        uint160 bracketsLocal = t.brackets;

        //Brackets phase 1
        points+=getFinalRoundPoints(bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

        //Brackets phase 2 
        points+=getMiddleRoundPoints(4, teamState.QUARTERS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 20;

        //Brackets phase 3 
        points+=getMiddleRoundPoints(8, teamState.ROS, bracketsLocal);
        bracketsLocal = bracketsLocal >> 40;

        //Brackets phase 4
        points+=getQualifiersPoints(bracketsLocal);

        //Extras
        points+=getExtraPoints(t.extra);

    }

    /**
    * @notice Sets the points of all the tokens between the last chunk set and the amount given.
    * @dev This function uses all the data collected earlier by oraclize to calculate points.
    * @param amount The amount of tokens that should be analyzed.
    */
	function calculatePointsBlock(uint32 amount) external{

        require (gameFinishedTime == 0);
        require(amount + lastCheckedToken <= tokens.length);


        for (uint256 i = lastCalculatedToken; i < (lastCalculatedToken + amount); i++) {
            uint16 points = calculateTokenPoints(tokens[i]);
            tokenToPointsMap[i] = points;
            if(worstTokens.length == 0 || points <= auxWorstPoints){
                if(worstTokens.length != 0 && points < auxWorstPoints){
                  worstTokens.length = 0;
                }
                if(worstTokens.length < 100){
                    auxWorstPoints = points;
                    worstTokens.push(i);
                }
            }
        }

        lastCalculatedToken += amount;
  	}

    /**
    * @notice Sets the structures for payout distribution, last position and superior quota. Payout distribution is the
    * percentage of the pot each position gets, last position is the percentage of the pot the last position gets,
    * and superior quota is the total amount OF winners that are given a prize.
    * @dev Each of this structures is dynamic and is assigned depending on the total amount of tokens in the game  
    */
    function setPayoutDistributionId () internal {
        if(tokens.length < 101){
            payoutDistribution = [289700, 189700, 120000, 92500, 75000, 62500, 52500, 42500, 40000, 35600, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 10;
        }else if(tokens.length < 201){
            payoutDistribution = [265500, 165500, 105500, 75500, 63000, 48000, 35500, 20500, 20000, 19500, 18500, 17800, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 20;
        }else if(tokens.length < 301){
            payoutDistribution = [260700, 155700, 100700, 70900, 60700, 45700, 35500, 20500, 17900, 12500, 11500, 11000, 10670, 0, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 30;
        }else if(tokens.length < 501){
            payoutDistribution = [238600, 138600, 88800, 63800, 53800, 43800, 33800, 18800, 17500, 12500, 9500, 7500, 7100, 6700, 0, 0, 0, 0, 0, 0, 0];
            lastPosition = 0;
            superiorQuota = 50;
        }else if(tokens.length < 1001){
            payoutDistribution = [218300, 122300, 72300, 52400, 43900, 33900, 23900, 16000, 13000, 10000, 9000, 7000, 5000, 4000, 3600, 0, 0, 0, 0, 0, 0];
            lastPosition = 4000;
            superiorQuota = 100;
        }else if(tokens.length < 2001){
            payoutDistribution = [204500, 114000, 64000, 44100, 35700, 26700, 22000, 15000, 11000, 9500, 8500, 6500, 4600, 2500, 2000, 1800, 0, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 200;
        }else if(tokens.length < 3001){
            payoutDistribution = [189200, 104800, 53900, 34900, 29300, 19300, 15300, 14000, 10500, 8300, 8000, 6000, 3800, 2500, 2000, 1500, 1100, 0, 0, 0, 0];
            lastPosition = 2500;
            superiorQuota = 300;
        }else if(tokens.length < 5001){
            payoutDistribution = [178000, 100500, 47400, 30400, 24700, 15500, 15000, 12000, 10200, 7800, 7400, 5500, 3300, 2000, 1500, 1200, 900, 670, 0, 0, 0];
            lastPosition = 2000;
            superiorQuota = 500;
        }else if(tokens.length < 10001){
            payoutDistribution = [157600, 86500, 39000, 23100, 18900, 15000, 14000, 11000, 9300, 6100, 6000, 5000, 3800, 1500, 1100, 900, 700, 500, 360, 0, 0];
            lastPosition = 1500;
            superiorQuota = 1000;
        }else if(tokens.length < 25001){
            payoutDistribution = [132500, 70200, 31300, 18500, 17500, 14000, 13500, 10500, 7500, 5500, 5000, 4000, 3000, 1000, 900, 700, 600, 400, 200, 152, 0];
            lastPosition = 1000;
            superiorQuota = 2500;
        } else {
            payoutDistribution = [120000, 63000,  27000, 18800, 17300, 13700, 13000, 10000, 6300, 5000, 4500, 3900, 2500, 900, 800, 600, 500, 350, 150, 100, 70];
            lastPosition = 900;
            superiorQuota = 5000;
        }

    }

    /**
    * @notice Sets the id of the last token that will be given a prize.
    * @dev This is done to offload some of the calculations needed for sorting, and to cap the number of sorts
    * needed to just the winners and not the whole array of tokens.
    * @param tokenId last token id
    */
    function setLimit(uint256 tokenId) external onlyAdmin{
        require(tokenId < tokens.length);
        require(pValidationState == pointsValidationState.Unstarted || pValidationState == pointsValidationState.LimitSet);
        pointsLimit = tokenId;
        pValidationState = pointsValidationState.LimitSet;
        lastCheckedToken = 0;
        lastCalculatedToken = 0;
        winnerCounter = 0;
        
        setPayoutDistributionId();
    }

    /**
    * @notice Sets the 10th percentile of the sorted array of points
    * @param amount tokens in a chunk
    */
    function calculateWinners(uint32 amount) external onlyAdmin checkState(pointsValidationState.LimitSet){
        require(amount + lastCheckedToken <= tokens.length);
        uint256 points = tokenToPointsMap[pointsLimit];

        for(uint256 i = lastCheckedToken; i < lastCheckedToken + amount; i++){
            if(tokenToPointsMap[i] > points ||
                (tokenToPointsMap[i] == points && i <= pointsLimit)){
                winnerCounter++;
            }
        }
        lastCheckedToken += amount;

        if(lastCheckedToken == tokens.length){
            require(superiorQuota == winnerCounter);
            pValidationState = pointsValidationState.LimitCalculated;
        }
    }

    /**
    * @notice Checks if the order given offchain coincides with the order of the actual previously calculated points
    * in the smart contract.
    * @dev the token sorting is done offchain so as to save on the huge amount of gas and complications that 
    * could occur from doing all the sorting onchain.
    * @param sortedChunk chunk sorted by points
    */
    function checkOrder(uint32[] sortedChunk) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        require(sortedChunk.length + sortedWinners.length <= winnerCounter);

        for(uint256 i=0;i < sortedChunk.length-1;i++){
            uint256 id = sortedChunk[i];
            uint256 sigId = sortedChunk[i+1];
            require(tokenToPointsMap[id] > tokenToPointsMap[sigId] ||
                (tokenToPointsMap[id] == tokenToPointsMap[sigId] &&  id < sigId));
        }

        if(sortedWinners.length != 0){
            uint256 id2 = sortedWinners[sortedWinners.length-1];
            uint256 sigId2 = sortedChunk[0];
            require(tokenToPointsMap[id2] > tokenToPointsMap[sigId2] ||
                (tokenToPointsMap[id2] == tokenToPointsMap[sigId2] && id2 < sigId2));
        }

        for(uint256 j=0;j < sortedChunk.length;j++){
            sortedWinners.push(sortedChunk[j]);
        }

        if(sortedWinners.length == winnerCounter){
            require(sortedWinners[sortedWinners.length-1] == pointsLimit);
            pValidationState = pointsValidationState.OrderChecked;
        }

    }

    /**
    * @notice If anything during the point calculation and sorting part should fail, this function can reset 
    * data structures to their initial position, so as to  
    */
    function resetWinners(uint256 newLength) external onlyAdmin checkState(pointsValidationState.LimitCalculated){
        
        sortedWinners.length = newLength;
    
    }

    /**
    * @notice Assigns prize percentage for the lucky top 30 winners. Each token will be assigned a uint256 inside
    * tokenToPayoutMap structure that represents the size of the pot that belongs to that token. If any tokens
    * tie inside of the first 30 tokens, the prize will be summed and divided equally. 
    */
    function setTopWinnerPrizes() external onlyAdmin checkState(pointsValidationState.OrderChecked){

        uint256 percent = 0;
        uint[] memory tokensEquals = new uint[](30);
        uint16 tokenEqualsCounter = 0;
        uint256 currentTokenId;
        uint256 currentTokenPoints;
        uint256 lastTokenPoints;
        uint32 counter = 0;
        uint256 maxRange = 13;
        if(tokens.length < 201){
          maxRange = 10;
        }
        

        while(payoutRange < maxRange){
          uint256 inRangecounter = payDistributionAmount[payoutRange];
          while(inRangecounter > 0){
            currentTokenId = sortedWinners[counter];
            currentTokenPoints = tokenToPointsMap[currentTokenId];

            inRangecounter--;

            //Special case for the last one
            if(inRangecounter == 0 && payoutRange == maxRange - 1){
                if(currentTokenPoints == lastTokenPoints){
                  percent += payoutDistribution[payoutRange];
                  tokensEquals[tokenEqualsCounter] = currentTokenId;
                  tokenEqualsCounter++;
                }else{
                  tokenToPayoutMap[currentTokenId] = payoutDistribution[payoutRange];
                }
            }

            if(counter != 0 && (currentTokenPoints != lastTokenPoints || (inRangecounter == 0 && payoutRange == maxRange - 1))){ //Fix second condition
                    for(uint256 i=0;i < tokenEqualsCounter;i++){
                        tokenToPayoutMap[tokensEquals[i]] = percent.div(tokenEqualsCounter);
                    }
                    percent = 0;
                    tokensEquals = new uint[](30);
                    tokenEqualsCounter = 0;
            }

            percent += payoutDistribution[payoutRange];
            tokensEquals[tokenEqualsCounter] = currentTokenId;
            
            tokenEqualsCounter++;
            counter++;

            lastTokenPoints = currentTokenPoints;
           }
           payoutRange++;
        }

        pValidationState = pointsValidationState.TopWinnersAssigned;
        lastPrizeGiven = counter;
    }

    /**
    * @notice Sets prize percentage to every address that wins from the position 30th onwards
    * @dev If there are less than 300 tokens playing, then this function will set nothing.
    * @param amount tokens in a chunk
    */
    function setWinnerPrizes(uint32 amount) external onlyAdmin checkState(pointsValidationState.TopWinnersAssigned){
        require(lastPrizeGiven + amount <= winnerCounter);
        
        uint16 inRangeCounter = payDistributionAmount[payoutRange];
        for(uint256 i = 0; i < amount; i++){
          if (inRangeCounter == 0){
            payoutRange++;
            inRangeCounter = payDistributionAmount[payoutRange];
          }

          uint256 tokenId = sortedWinners[i + lastPrizeGiven];

          tokenToPayoutMap[tokenId] = payoutDistribution[payoutRange];

          inRangeCounter--;
        }
        //i + amount prize was not given yet, so amount -1
        lastPrizeGiven += amount;
        payDistributionAmount[payoutRange] = inRangeCounter;

        if(lastPrizeGiven == winnerCounter){
            pValidationState = pointsValidationState.WinnersAssigned;
            return;
        }
    }

    /**
    * @notice Sets prizes for last tokens and sets prize pool amount
    */
    function setLastPositions() external onlyAdmin checkState(pointsValidationState.WinnersAssigned){
        
            
        for(uint256 j = 0;j < worstTokens.length;j++){
            uint256 tokenId = worstTokens[j];
            tokenToPayoutMap[tokenId] += lastPosition.div(worstTokens.length);
        }

        uint256 balance = address(this).balance;
        adminPool = balance.mul(25).div(100);
        prizePool = balance.mul(75).div(100);

        pValidationState = pointsValidationState.Finished;
        gameFinishedTime = now;
    }

}


/**
* @title CoreLayer
* @author CryptoCup Team (https://cryptocup.io/about)
* @notice Main contract
*/
contract CoreLayer is GameLogicLayer {
    
    function CoreLayer() public {
        adminAddress = msg.sender;
        deploymentTime = now;
    }

    /** 
    * @dev Only accept eth from the admin
    */
    function() external payable {
        require(msg.sender == adminAddress);

    }

    function isDataSourceCallback() public pure returns (bool){
        return true;
    }   

    /** 
    * @notice Builds ERC721 token with the predictions provided by the user.
    * @param groups1  - First half of the group matches scores encoded in a uint192.
    * @param groups2 -  Second half of the groups matches scores encoded in a uint192.
    * @param brackets - Bracket information encoded in a uint160.
    * @param extra -    Extra information (number of red cards and yellow cards) encoded in a uint32.
    * @dev An automatic timestamp is added for internal use.
    */
    function buildToken(uint192 groups1, uint192 groups2, uint160 brackets, uint32 extra) external payable isNotPaused {

        Token memory token = Token({
            groups1: groups1,
            groups2: groups2,
            brackets: brackets,
            timeStamp: uint64(now),
            extra: extra
        });

        require(msg.value >= _getTokenPrice());
        require(msg.sender != address(0));
        require(tokens.length < WCCTOKEN_CREATION_LIMIT);
        require(tokensOfOwnerMap[msg.sender].length < 100);
        require(now < WORLD_CUP_START); //World cup Start

        uint256 tokenId = tokens.push(token) - 1;
        require(tokenId == uint256(uint32(tokenId)));

        _setTokenOwner(msg.sender, tokenId);
        LogTokenBuilt(msg.sender, tokenId, token);

    }

    /** 
    * @param tokenId - ID of token to get.
    * @return Returns all the valuable information about a specific token.
    */
    function getToken(uint256 tokenId) external view returns (uint192 groups1, uint192 groups2, uint160 brackets, uint64 timeStamp, uint32 extra) {

        Token storage token = tokens[tokenId];

        groups1 = token.groups1;
        groups2 = token.groups2;
        brackets = token.brackets;
        timeStamp = token.timeStamp;
        extra = token.extra;

    }

    /**
    * @notice Called by the development team once the World Cup has ended (adminPool is set) 
    * @dev Allows dev team to retrieve adminPool
    */
    function adminWithdrawBalance() external onlyAdmin {

        adminAddress.transfer(adminPool);
        adminPool = 0;

    }

    /**
    * @notice Allows any user to retrieve their asigned prize. This would be the sum of the price of all the tokens
    * owned by the caller of this function.
    * @dev If the caller has no prize, the function will revert costing no gas to the caller.
    */
    function withdrawPrize() external checkState(pointsValidationState.Finished){
        uint256 prize = 0;
        uint256[] memory tokenList = tokensOfOwnerMap[msg.sender];
        
        for(uint256 i = 0;i < tokenList.length; i++){
            prize += tokenToPayoutMap[tokenList[i]];
            tokenToPayoutMap[tokenList[i]] = 0;
        }
        
        require(prize > 0);
        msg.sender.transfer((prizePool.mul(prize)).div(1000000));
      
    }

    
    /**
    * @notice Gets current token price 
    */
    function _getTokenPrice() internal view returns(uint256 tokenPrice){

        if ( now >= THIRD_PHASE){
            tokenPrice = (150 finney);
        } else if (now >= SECOND_PHASE) {
            tokenPrice = (110 finney);
        } else if (now >= FIRST_PHASE) {
            tokenPrice = (75 finney);
        } else {
            tokenPrice = STARTING_PRICE;
        }

        require(tokenPrice >= STARTING_PRICE && tokenPrice <= (200 finney));

    }

    /**
    * @dev Sets the data source contract address 
    * @param _address Address to be set
    */
    function setDataSourceAddress(address _address) external onlyAdmin {
        
        DataSourceInterface c = DataSourceInterface(_address);

        require(c.isDataSource());

        dataSource = c;
        dataSourceAddress = _address;
    }

    /**
    * @notice Testing function to corroborate group data from oraclize call
    * @param x Id of the match to get
    * @return uint8 Team 1 goals
    * @return uint8 Team 2 goals
    */
    function getGroupData(uint x) external view returns(uint8 a, uint8 b){
        a = groupsResults[x].teamOneGoals;
        b = groupsResults[x].teamTwoGoals;  
    }

    /**
    * @notice Testing function to corroborate round of sixteen data from oraclize call
    * @return An array with the ids of the round of sixteen teams
    */
    function getBracketData() external view returns(uint8[16] a){
        a = bracketsResults.roundOfSixteenTeamsIds;
    }

    /**
    * @notice Testing function to corroborate brackets data from oraclize call
    * @param x Team id
    * @return The place the team reached
    */
    function getBracketDataMiddleTeamIds(uint8 x) external view returns(teamState a){
        a = bracketsResults.middlePhaseTeamsIds[x];
    }

    /**
    * @notice Testing function to corroborate finals data from oraclize call
    * @return the 4 (four) final teams ids
    */
    function getBracketDataFinals() external view returns(uint8[4] a){
        a = bracketsResults.finalsTeamsIds;
    }

    /**
    * @notice Testing function to corroborate extra data from oraclize call
    * @return amount of yellow and red cards
    */
    function getExtrasData() external view returns(uint16 a, uint16 b){
        a = extraResults.yellowCards;
        b = extraResults.redCards;  
    }

    //EMERGENCY CALLS
    //If something goes wrong or fails, these functions will allow retribution for token holders 

    /**
    * @notice if there is an unresolvable problem, users can call to this function to get a refund.
    */
    function emergencyWithdraw() external hasFinalized{

        uint256 balance = STARTING_PRICE * tokensOfOwnerMap[msg.sender].length;

        delete tokensOfOwnerMap[msg.sender];
        msg.sender.transfer(balance);

    }

     /**
    * @notice Let the admin cash-out the entire contract balance 10 days after game has finished.
    */
    function finishedGameWithdraw() external onlyAdmin hasFinished{

        uint256 balance = address(this).balance;
        adminAddress.transfer(balance);

    }
    
    /**
    * @notice Let the admin cash-out the entire contract balance 10 days after game has finished.
    */
    function emergencyWithdrawAdmin() external hasFinalized onlyAdmin{

        require(finalizedTime != 0 &&  now >= finalizedTime + 10 days );
        msg.sender.transfer(address(this).balance);

    }
}