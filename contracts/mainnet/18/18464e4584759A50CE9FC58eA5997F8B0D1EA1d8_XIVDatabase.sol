// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol"; 
import "./XIVInterface.sol";
contract XIVDatabase is Ownable{
    
    using SafeMath for uint256;
    mapping (address=>uint256) tokensStaked; //amount of XIV staked by user + incentive from betting
    mapping(address=> uint256) actualAmountStakingByUser; // XIV staked by users.
    address[] userStakedAddress; // array of user's address who has staked..
    address[] tempArray;
    // XIVDatabaseLib.BetInfo[] tempBetArray;
    uint256 tokenStakedAmount; // total Amount currently staked by all users.
    uint256 minStakeXIVAmount; // min amount that user can bet on.
    uint256 maxStakeXIVAmount; // max amount that user can bet on.
    uint256 totalTransactions; // sum of all transactions
    uint256 investmentId;
    uint256 slotExecutionId;
    uint256 slotId;
    mapping(address=>bool) isStakeMapping;
    
    mapping(uint256=> XIVDatabaseLib.IncentiveInfo[]) incentiveMapping;
    
    mapping(address=> XIVDatabaseLib.StakingInfo[]) StakingInfoMapping;
    
    uint256 minLPvalue; // min amount of token that user can stake in LP
    mapping(address=>XIVDatabaseLib.LPLockedInfo) lockingPeriodForLPMapping; // time for which staked value is locked 
    
    uint256 betFactorLP; // this is the ratio according to which users can bet considering the amount staked..
    
    address XIVMainContractAddress;
    address XIVBettingFixedContractAddress;
    address XIVBettingFlexibleContractAddress;
    
    address oracleWrapperContractAddress = 0xBc79719636EC60Bc3d98901Af82B278F17a58037; //address of oracle wrapper from where the prices would be fetched
    address XIVTokenContractAddress = 0x44f262622248027f8E2a8Fb1090c4Cf85072392C; //XIV contract address
   
  
    // mapping and arry of the currencies in the flash individuals vaults.
    mapping(address=>XIVDatabaseLib.DefiCoin) flashVaultMapping;
    address[] flashVaultContractAddressArray;
   
   /*
   * fixed individuals starts
   */
    // mapping and arry of the currencies in the fixed individuals vaults.
    mapping(address=>XIVDatabaseLib.DefiCoin) defiCoinsFixedMapping;
    address[] allDefiCoinFixedContractAddressArray;
    // array of daysCount and its % drop and other values for fixed
    XIVDatabaseLib.FixedInfo[] fixedDefiCoinArray;
   
    /*
   * flexible individuals starts
   */
    // mapping and arry of the currencies in the flexible individuals vaults.
    mapping(address=>XIVDatabaseLib.DefiCoin) defiCoinsFlexibleMapping;
    address[] allDefiCoinFlexibleContractAddressArray;
    // flexible individual dropvalue and other values
    XIVDatabaseLib.FlexibleInfo[]  flexibleDefiCoinArray;
    // flexible individual time periods days
    XIVDatabaseLib.TimePeriod[] flexibleDefiCoinTimePeriodArray;
    
    
    /*
   * fixed and flexible adding currency index starts
   */
    // mapping and arry of the currencies for all index vaults.
    mapping(address=>XIVDatabaseLib.IndexCoin)  defiCoinsIndexMapping;
    address[]  allIndexDefiCoinContractAddressArray;
    
    /*
   * flexible index starts
   */
    // flexible index dropvalue and other values
    XIVDatabaseLib.FlexibleInfo[]  flexibleIndexArray;
    // flexible index time periods days
    XIVDatabaseLib.TimePeriod[]  flexibleIndexTimePeriodArray;
    // this include array of imdex on which bet is placed. key will be betId and value will be array of all index...
    mapping(uint256=>XIVDatabaseLib.IndexCoin[]) betIndexForFlexibleArray;  
    // this contains the values on which flexible index bet is placed
    mapping(uint256=>XIVDatabaseLib.BetPriceHistory) betPriceHistoryFlexibleMapping; 
    
    /*
   * fixed index starts
   */
    XIVDatabaseLib.FixedInfo[]  fixedDefiIndexArray;
    // this include array of imdex on which bet is placed. key will be betId and value will be array of all index...
    mapping(uint256=>XIVDatabaseLib.IndexCoin[]) betIndexForFixedArray;  
    // this contains the values on which fixed index bet is placed
    mapping(uint256=>XIVDatabaseLib.BetPriceHistory) betPriceHistoryFixedMapping;
    
    
    uint256  betBaseIndexValue; //10**8 index value 
    uint256  betActualIndexValue; // marketcap value
    
    uint256 betid;
    
    XIVDatabaseLib.BetInfo[]  betArray;
    mapping(uint256=>uint256)  findBetInArrayUsingBetIdMapping; // getting the bet index using betid... Key is betId and value will be index in the betArray...
    mapping(address=> uint256[])  betAddressesArray;
    
    uint256 plentyOneDayPercentage; // percentage in 10**2
    mapping(uint256=>uint256)  plentyThreeDayPercentage; // key is day and value is percentage in 10**2
    mapping(uint256=>uint256)  plentySevenDayPercentage; // key is day and value is percentage in 10**2
    
    uint256[] daysArray;
    
    uint256 rewardGeneratedAmount;
    address[] userAddressUsedForBetting;
    
    mapping(address=>mapping(uint256=>mapping(address=>bool))) existingBetCheckMapping;
    
    event BetDetails(uint256 indexed betId, uint256 indexed status, uint256 indexed betEndTime);
    event LPEvent(uint256 typeOfLP, address indexed userAddress, uint256 amount, uint256 timestamp);
    
    function emitBetDetails(uint256  betId, uint256  status, uint256  betEndTime) external onlyMyContracts{
        emit BetDetails( betId, status, betEndTime);
    }
    function emitLPEvent(uint256 typeOfLP, address userAddress, uint256 amount, uint256 timestamp) external onlyMyContracts{
        emit LPEvent(typeOfLP,  userAddress, amount, timestamp);
    }
    function updateExistingBetCheckMapping(address _userAddress,uint256 _betType, address _BetContractAddress,bool status) external onlyMyContracts{
        existingBetCheckMapping[_userAddress][_betType][_BetContractAddress]=status;
    }
    function getExistingBetCheckMapping(address _userAddress,uint256 _betType, address _BetContractAddress) external view returns(bool){
        return (existingBetCheckMapping[_userAddress][_betType][_BetContractAddress]);
    }
    
     function addFixedDefiCoinArray(uint256 _daysCount,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
         bool isAvailable=false;
         for(uint256 i=0;i<fixedDefiCoinArray.length;i++){
             if(fixedDefiCoinArray[i].daysCount==_daysCount){
                 isAvailable=true;
                 break;
             }
         }
        require(!isAvailable,"Already have this data.");
        XIVDatabaseLib.FixedInfo memory fobject=XIVDatabaseLib.FixedInfo({
            id:fixedDefiCoinArray.length,
            daysCount:_daysCount,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor,
            status:true
        });
        fixedDefiCoinArray.push(fobject);
        addDaysToDayArray(_daysCount);
    }
    function updateFixedDefiCoinArray(uint256 index,uint256 _daysCount,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor, bool _status) public onlyOwner{
        fixedDefiCoinArray[index].daysCount=_daysCount;
        fixedDefiCoinArray[index].upDownPercentage=_upDownPercentage;
        fixedDefiCoinArray[index].riskFactor=_riskFactor;
        fixedDefiCoinArray[index].rewardFactor=_rewardFactor;
        fixedDefiCoinArray[index].status=_status;
        addDaysToDayArray(_daysCount);
    }
    
    function addUpdateForDefiFixedCoin(address _ContractAddress,  string memory _currencySymbol,
                                            uint16 _OracleType, bool _Status, bool isFlashVault) public onlyOwner{
        // add update defi felxible coin
        XIVDatabaseLib.DefiCoin memory dCoin=XIVDatabaseLib.DefiCoin({
            oracleType:_OracleType,
            currencySymbol:_currencySymbol,
            status:_Status
        });
        if(isFlashVault){
            flashVaultMapping[_ContractAddress]=dCoin;
        }else{
            defiCoinsFixedMapping[_ContractAddress]=dCoin;
        }
        // check wheather contract exists in allFlexibleContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,isFlashVault?flashVaultContractAddressArray:allDefiCoinFixedContractAddressArray)){
            (isFlashVault?flashVaultContractAddressArray:allDefiCoinFixedContractAddressArray).push(_ContractAddress);
        }
    }
    
    function getDefiCoinsFixedMapping(address _betContractAddress, bool isFlashVault) external view returns(XIVDatabaseLib.DefiCoin memory){
        return (isFlashVault?flashVaultMapping[_betContractAddress]:defiCoinsFixedMapping[_betContractAddress]);
    }
    function getDefiCoinsFixedContractAddressArray(bool isFlashVault) external view returns(address[] memory){
        return (isFlashVault?flashVaultContractAddressArray:allDefiCoinFixedContractAddressArray);
    }
    
    function addUpdateForDefiCoinFlexible(address _ContractAddress,  string memory _currencySymbol,
                                            uint16 _OracleType, bool _Status) public onlyOwner{
        // add update defi felxible coin
        XIVDatabaseLib.DefiCoin memory dCoin=XIVDatabaseLib.DefiCoin({
            oracleType:_OracleType,
            currencySymbol:_currencySymbol,
            status:_Status
        });
        defiCoinsFlexibleMapping[_ContractAddress]=dCoin;
        // check wheather contract exists in allFlexibleContractAddressArray array
        if(!contractAvailableInArray(_ContractAddress,allDefiCoinFlexibleContractAddressArray)){
            allDefiCoinFlexibleContractAddressArray.push(_ContractAddress);
        }
    }
    
    function getDefiCoinsFlexibleMapping(address _betContractAddress) external view returns(XIVDatabaseLib.DefiCoin memory){
        return (defiCoinsFlexibleMapping[_betContractAddress]);
    }
    function getDefiCoinsFlexibleContractAddressArray() external view returns(address[] memory){
        return allDefiCoinFlexibleContractAddressArray;
    }
    function addflexibleDefiCoinArray(uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        XIVDatabaseLib.FlexibleInfo memory fobject=XIVDatabaseLib.FlexibleInfo({
            id:flexibleDefiCoinArray.length,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor,
            status:true
        });
        flexibleDefiCoinArray.push(fobject);
    }
    function updateflexibleDefiCoinArray(uint256 index,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor, bool _status) public onlyOwner{
        flexibleDefiCoinArray[index].upDownPercentage=_upDownPercentage;
        flexibleDefiCoinArray[index].riskFactor=_riskFactor;
        flexibleDefiCoinArray[index].rewardFactor=_rewardFactor;
        flexibleDefiCoinArray[index].status=_status;
    }
     function addFlexibleDefiCoinTimePeriodArray(uint256 _tdays) public onlyOwner{
         bool isAvailable=false;
         for(uint256 i=0;i<flexibleDefiCoinTimePeriodArray.length;i++){
             if(flexibleDefiCoinTimePeriodArray[i]._days==_tdays){
                 isAvailable=true;
                 break;
             }
         }
        require(!isAvailable,"Already have this data.");
         XIVDatabaseLib.TimePeriod memory tobject= XIVDatabaseLib.TimePeriod({
             _days:_tdays,
             status:true
         });
        flexibleDefiCoinTimePeriodArray.push(tobject);
        addDaysToDayArray(_tdays);
    }
    function updateFlexibleDefiCoinTimePeriodArray(uint256 index, uint256 _tdays, bool _status) public onlyOwner{
        flexibleDefiCoinTimePeriodArray[index]._days=_tdays;
        flexibleDefiCoinTimePeriodArray[index].status=_status;
        addDaysToDayArray(_tdays);
    }
    
    function getFlexibleDefiCoinTimePeriodArray() public view returns(XIVDatabaseLib.TimePeriod[] memory){
        return flexibleDefiCoinTimePeriodArray;
    }
    
     function addUpdateForIndexCoin(XIVDatabaseLib.IndexCoin[] memory tupleCoinArray) public onlyOwner{
        // add update index fixed coin
        tempArray=new address[](0);
        allIndexDefiCoinContractAddressArray=tempArray;
        
        for(uint256 i=0;i<tupleCoinArray.length;i++){
            defiCoinsIndexMapping[tupleCoinArray[i].contractAddress]=tupleCoinArray[i];
            // check wheather contract exists in allFixedContractAddressArray array
            if(!contractAvailableInArray(tupleCoinArray[i].contractAddress,allIndexDefiCoinContractAddressArray)){
                allIndexDefiCoinContractAddressArray.push(tupleCoinArray[i].contractAddress);
            }
        }
    }
    function addflexibleIndexCoinArray(uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
        XIVDatabaseLib.FlexibleInfo memory fobject=XIVDatabaseLib.FlexibleInfo({
            id:flexibleIndexArray.length,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor,
            status:true
        });
        flexibleIndexArray.push(fobject);
    }
    function updateflexibleIndexCoinArray(uint256 index,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor, bool _status) public onlyOwner{
        flexibleIndexArray[index].upDownPercentage=_upDownPercentage;
        flexibleIndexArray[index].riskFactor=_riskFactor;
        flexibleIndexArray[index].rewardFactor=_rewardFactor;
        flexibleIndexArray[index].status=_status;
    }
    
    function addFlexibleIndexTimePeriodArray(uint256 _tdays) public onlyOwner{
         bool isAvailable=false;
         for(uint256 i=0;i<flexibleIndexTimePeriodArray.length;i++){
             if(flexibleIndexTimePeriodArray[i]._days==_tdays){
                 isAvailable=true;
                 break;
             }
         }
        require(!isAvailable,"Already have this data.");
         XIVDatabaseLib.TimePeriod memory tobject= XIVDatabaseLib.TimePeriod({
             _days:_tdays,
             status:true
         });
        flexibleIndexTimePeriodArray.push(tobject);
        addDaysToDayArray(_tdays);
    }
    function updateFlexibleIndexTimePeriodArray(uint256 index, uint256 _tdays, bool _status) public onlyOwner{
        flexibleIndexTimePeriodArray[index]._days=_tdays;
        flexibleIndexTimePeriodArray[index].status=_status;
        addDaysToDayArray(_tdays);
    }
    function getFlexibleIndexTimePeriodArray() public view returns(XIVDatabaseLib.TimePeriod[] memory){
        return flexibleIndexTimePeriodArray;
    }
   function addFixedDefiIndexArray(uint256 _daysCount,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor) public onlyOwner{
         bool isAvailable=false;
         for(uint256 i=0;i<fixedDefiIndexArray.length;i++){
             if(fixedDefiIndexArray[i].daysCount==_daysCount){
                 isAvailable=true;
                 break;
             }
         }
        require(!isAvailable,"Already have this data.");
        XIVDatabaseLib.FixedInfo memory fobject=XIVDatabaseLib.FixedInfo({
            id:fixedDefiIndexArray.length,
            daysCount:_daysCount,
            upDownPercentage:_upDownPercentage,
            riskFactor:_riskFactor,
            rewardFactor:_rewardFactor,
            status:true
        });
        fixedDefiIndexArray.push(fobject);
        addDaysToDayArray(_daysCount);
    }
    function updateFixedDefiIndexArray(uint256 index,uint256 _daysCount,uint16 _upDownPercentage, uint16 _riskFactor, uint16 _rewardFactor, bool _status) public onlyOwner{
        fixedDefiIndexArray[index].daysCount=_daysCount;
        fixedDefiIndexArray[index].upDownPercentage=_upDownPercentage;
        fixedDefiIndexArray[index].riskFactor=_riskFactor;
        fixedDefiIndexArray[index].rewardFactor=_rewardFactor;
        fixedDefiIndexArray[index].status=_status;
        addDaysToDayArray(_daysCount);
    }
    function contractAvailableInArray(address _ContractAddress,address[] memory _contractArray) internal pure returns(bool){
        for(uint256 i=0;i<_contractArray.length;i++){
            if(_ContractAddress==_contractArray[i]){
                return true;
            }
        }
        return false;
    }  
   
    
    function updateMaxStakeXIVAmount(uint256 _maxStakeXIVAmount) external onlyOwner{
        maxStakeXIVAmount=_maxStakeXIVAmount;
    }
    function getMaxStakeXIVAmount() external view returns(uint256){
        return maxStakeXIVAmount;
    }
    function updateMinStakeXIVAmount(uint256 _minStakeXIVAmount) external onlyOwner{
        minStakeXIVAmount=_minStakeXIVAmount;
    }
    function getMinStakeXIVAmount() external view returns(uint256){
        return minStakeXIVAmount;
    }
    function updateMinLPvalue(uint256 _minLPvalue) external onlyOwner{
        minLPvalue=_minLPvalue;
    }
    function getMinLPvalue() external view returns(uint256){
        return minLPvalue;
    }
    function updateBetFactorLP(uint256 _betFactorLP) external onlyOwner{
        betFactorLP=_betFactorLP;
    }
    function getBetFactorLP() external view returns(uint256){
        return betFactorLP;
    }
    
    function updateTotalTransactions(uint256 _totalTransactions) external onlyMyContracts{
        totalTransactions=_totalTransactions;
    }
    function getTotalTransactions() external view returns(uint256){
        return totalTransactions;
    }
    
    function updateXIVMainContractAddress(address _XIVMainContractAddress) external onlyOwner{
        XIVMainContractAddress=_XIVMainContractAddress;
    }
    function updateXIVBettingFixedContractAddress(address _XIVBettingFixedContractAddress) external onlyOwner{
        XIVBettingFixedContractAddress=_XIVBettingFixedContractAddress;
    }
    function updateXIVBettingFlexibleContractAddress(address _XIVBettingFlexibleContractAddress) external onlyOwner{
        XIVBettingFlexibleContractAddress=_XIVBettingFlexibleContractAddress;
    }
    function updateXIVTokenContractAddress(address _XIVTokenContractAddress) external onlyOwner{
        XIVTokenContractAddress=_XIVTokenContractAddress;
    }
    function getXIVTokenContractAddress() external view returns(address){
        return XIVTokenContractAddress;
    }
    function updateBetBaseIndexValue(uint256 _betBaseIndexValue) external onlyMyContracts{
        betBaseIndexValue=_betBaseIndexValue;
    }
    function getBetBaseIndexValue() external view returns(uint256){
        return betBaseIndexValue;
    }
    function updateBetActualIndexValue(uint256 _betActualIndexValue) external onlyMyContracts{
        betActualIndexValue=_betActualIndexValue;
    }
    function getBetActualIndexValue() external view returns(uint256){
        return betActualIndexValue;
    }
    
    // function transferETH(address payable userAddress,uint256 amount) external onlyMyContracts {
    //     require(address(this).balance >= amount,"The Contract does not have enough ethers.");
    //     userAddress.transfer(amount);
    // }
    function transferTokens(address contractAddress,address userAddress,uint256 amount) external onlyMyContracts {
        Token tokenObj=Token(contractAddress);
        require(tokenObj.balanceOf(address(this))>= amount, "Tokens not available");
        tokenObj.transfer(userAddress, amount);
    }
    function transferFromTokens(address contractAddress,address fromAddress, address toAddress,uint256 amount) external onlyMyContracts {
        require(checkTokens(contractAddress,amount,fromAddress));
        Token(contractAddress).transferFrom(fromAddress, toAddress, amount);
    }
    function checkTokens(address contractAddress,uint256 amount, address fromAddress) internal view returns(bool){
         Token tokenObj = Token(contractAddress);
        //check if user has balance
        require(tokenObj.balanceOf(fromAddress) >= amount, "You don't have enough XIV balance");
        //check if user has provided allowance
        require(tokenObj.allowance(fromAddress,address(this)) >= amount, 
        "Please allow smart contract to spend on your behalf");
        return true;
    }
    function getTokensStaked(address userAddress) external view returns(uint256){
        return (tokensStaked[userAddress]);
    }
    function updateTokensStaked(address userAddress, uint256 amount) external onlyMyContracts{
        tokensStaked[userAddress]=amount;
    }
    function getStakingInfoMapping(address userAddress) external view returns(XIVDatabaseLib.StakingInfo[] memory){
        return (StakingInfoMapping[userAddress]);
    }
    function updateStakingInfoMapping(address userAddress, XIVDatabaseLib.StakingInfo memory sInfo) external onlyMyContracts{
        StakingInfoMapping[userAddress].push(sInfo);
    }
    function getActualAmountStakedByUser(address userAddress) external view returns(uint256){
        return (actualAmountStakingByUser[userAddress]);
    } 
    function updateIsStakeMapping(address userAddress,bool isStake) external onlyMyContracts{
        isStakeMapping[userAddress]=(isStake);
    }
    function getIsStakeMapping(address userAddress) external view returns(bool){
        return (isStakeMapping[userAddress]);
    }
    
    function updateIncentiveMapping(uint256 _slotId, XIVDatabaseLib.IncentiveInfo memory iInfo) external onlyMyContracts{
        incentiveMapping[_slotId].push(iInfo);
    }
    function getIncentiveMapping(uint256 _slotId) external view returns(XIVDatabaseLib.IncentiveInfo[] memory){
        return (incentiveMapping[_slotId]);
    }
    
    function updateActualAmountStakedByUser(address userAddress, uint256 amount) external onlyMyContracts{
        actualAmountStakingByUser[userAddress]=amount;
    }
    
    function getLockingPeriodForLPMapping(address userAddress) external view returns(XIVDatabaseLib.LPLockedInfo memory){
        return (lockingPeriodForLPMapping[userAddress]);
    }
    function updateLockingPeriodForLPMapping(address userAddress, uint256 _amountLocked, uint256 _lockedTimeStamp) external onlyMyContracts{
        XIVDatabaseLib.LPLockedInfo memory lpLockedInfo= XIVDatabaseLib.LPLockedInfo({
            lockedTimeStamp:_lockedTimeStamp,
            amountLocked:_amountLocked
        });
        lockingPeriodForLPMapping[userAddress]=lpLockedInfo;
    }
    
    function getTokenStakedAmount() external view returns(uint256){
        return (tokenStakedAmount);
    }
    function updateTokenStakedAmount(uint256 _tokenStakedAmount) external onlyMyContracts{
        tokenStakedAmount=_tokenStakedAmount;
    }
    function getBetId() external view returns(uint256){
        return betid;
    }
    function updateBetId(uint256 _userBetId) external onlyMyContracts{
        betid=_userBetId;
    }
    function getInvestmentId() external view returns(uint256){
        return investmentId;
    }
    function updateInvestmentId(uint256 _investmentId) external onlyMyContracts{
        investmentId=_investmentId;
    }
    function getSlotExecutionId() external view returns(uint256){
        return slotExecutionId;
    }
    function updateSlotExecutionId(uint256 _slotExecutionId) external onlyMyContracts{
        slotExecutionId=_slotExecutionId;
    }
    function getSlotId() external view returns(uint256){
        return slotId;
    }
    function updateSlotId(uint256 _slotId) external onlyMyContracts{
        slotId=_slotId;
    }
    
    function updateBetArray(XIVDatabaseLib.BetInfo memory bObject) external onlyMyContracts{
        betArray.push(bObject);
    }
    function updateBetArrayIndex(XIVDatabaseLib.BetInfo memory bObject, uint256 index) external onlyMyContracts{
        betArray[index]=bObject;
    }
    function getBetArray() external view returns(XIVDatabaseLib.BetInfo[] memory){
        return betArray;
    }
    function getFindBetInArrayUsingBetIdMapping(uint256 _betid) external view returns(uint256){
        return findBetInArrayUsingBetIdMapping[_betid];
    }
    function updateFindBetInArrayUsingBetIdMapping(uint256 _betid, uint256 value) external onlyMyContracts{
        findBetInArrayUsingBetIdMapping[_betid]=value;
    }
    function updateUserStakedAddress(address _address) external onlyMyContracts{
        userStakedAddress.push(_address);
    }
    function getUserStakedAddress() external view returns(address[] memory){
        return userStakedAddress;
    }
    function updateUserStakedAddress(address[] memory _userStakedAddress) external onlyMyContracts{
        userStakedAddress=_userStakedAddress;
    }
    function getFlexibleDefiCoinArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory){
        return flexibleDefiCoinArray;
    }
    
    function getFlexibleIndexArray() external view returns(XIVDatabaseLib.FlexibleInfo[] memory){
        return flexibleIndexArray;
    }
    
    function getFixedDefiCoinArray() external view returns(XIVDatabaseLib.FixedInfo[] memory){
        return fixedDefiCoinArray;
    }
    
    function getFixedDefiIndexArray() external view returns(XIVDatabaseLib.FixedInfo[] memory){
        return fixedDefiIndexArray;
    }
    function getAllIndexContractAddressArray() external view returns(address[] memory){
        return allIndexDefiCoinContractAddressArray;
    }
    function getDefiCoinIndexMapping(address _ContractAddress) external view returns(XIVDatabaseLib.IndexCoin memory){
        return (defiCoinsIndexMapping[_ContractAddress]);
    }
    function updateBetIndexForFixedArray(uint256 _betId, XIVDatabaseLib.IndexCoin memory iCArray) external onlyMyContracts{
        betIndexForFixedArray[_betId].push(iCArray);
    }
    function getBetIndexForFixedArray(uint256 _betId) external view returns(XIVDatabaseLib.IndexCoin[] memory){
        return (betIndexForFixedArray[_betId]);
    }
    function updateBetIndexForFlexibleArray(uint256 _betId, XIVDatabaseLib.IndexCoin memory iCArray) external onlyMyContracts{
        betIndexForFlexibleArray[_betId].push(iCArray);
    }
    function getBetIndexForFlexibleArray(uint256 _betId) external view returns(XIVDatabaseLib.IndexCoin[] memory){
        return (betIndexForFlexibleArray[_betId]);
    }
    function updateBetPriceHistoryFixedMapping(uint256 _betId, XIVDatabaseLib.BetPriceHistory memory bPHObj) external onlyMyContracts{
        betPriceHistoryFixedMapping[_betId]=bPHObj;
    }
    function getBetPriceHistoryFixedMapping(uint256 _betId) external view returns(XIVDatabaseLib.BetPriceHistory memory){
        return (betPriceHistoryFixedMapping[_betId]);
    }
    function updateBetPriceHistoryFlexibleMapping(uint256 _betId, XIVDatabaseLib.BetPriceHistory memory bPHObj) external onlyMyContracts{
        betPriceHistoryFlexibleMapping[_betId]=bPHObj;
    }
    function getBetPriceHistoryFlexibleMapping(uint256 _betId) external view returns(XIVDatabaseLib.BetPriceHistory memory){
        return (betPriceHistoryFlexibleMapping[_betId]);
    }
    function addUpdatePlentyOneDayPercentage(uint256 percentage) public onlyOwner{
        plentyOneDayPercentage=percentage;
    }
    function getPlentyOneDayPercentage() external view returns(uint256){
        return (plentyOneDayPercentage);
    }
    
    function addUpdatePlentyThreeDayPercentage(uint256 _days, uint256 percentage) public onlyOwner{
        plentyThreeDayPercentage[_days]=percentage;
    }
    function getPlentyThreeDayPercentage(uint256 _days) external view returns(uint256){
        return (plentyThreeDayPercentage[_days]);
    }
    
    function addUpdatePlentySevenDayPercentage(uint256 _days, uint256 percentage) public onlyOwner{
        plentySevenDayPercentage[_days]=percentage;
    }
    function getPlentySevenDayPercentage(uint256 _days) external view returns(uint256){
        return (plentySevenDayPercentage[_days]);
    }
    function updateOrcaleAddress(address oracleAddress) external onlyOwner{
        oracleWrapperContractAddress=oracleAddress;
    }
    function getOracleWrapperContractAddress() external view returns(address){
        return oracleWrapperContractAddress;
    }
    function getBetsAccordingToUserAddress(address userAddress) external view returns(uint256[] memory){
        return betAddressesArray[userAddress];
    }
    function getUserBetCount(address userAddress) external view returns(uint256){
        return betAddressesArray[userAddress].length;
    }
    function getUserBetArray(address userAddress, uint256 pageNo, uint256 pageSize) external view returns(XIVDatabaseLib.BetInfo[] memory){
        uint256[] memory betIndexes=betAddressesArray[userAddress];
        if(betIndexes.length>0){
            uint256 startIndex=(((betIndexes.length).sub(pageNo.mul(pageSize))).sub(1));
            uint256 endIndex;
            uint256 pageCount=startIndex.add(1);
            if(pageSize.sub(1)<startIndex){
                endIndex=(startIndex.sub(pageSize.sub(1)));
                pageCount=pageSize;
            }
            XIVDatabaseLib.BetInfo[] memory bArray=new XIVDatabaseLib.BetInfo[](pageCount);
            uint256 value;
            for(uint256 i=endIndex;i<=startIndex;i++){
                bArray[value]=betArray[findBetInArrayUsingBetIdMapping[betIndexes[i]]];
                value++;
            }
            return bArray;
        }
        return new XIVDatabaseLib.BetInfo[](0);
    }
    function updateBetAddressesArray(address userAddress, uint256 _betId) external onlyMyContracts{
        betAddressesArray[userAddress].push(_betId);
    }
    function getRewardGeneratedAmount() external view returns(uint256){
        return rewardGeneratedAmount;
    }
    function updateRewardGeneratedAmount(uint256 _rewardGeneratedAmount) external onlyMyContracts{
        rewardGeneratedAmount=_rewardGeneratedAmount;
    }
    
    function addUserAddressUsedForBetting(address userAddress) external onlyMyContracts{
        userAddressUsedForBetting.push(userAddress);
    }
    function getUserAddressUsedForBetting() external view returns(address[] memory){
        return userAddressUsedForBetting;
    }
    function addDaysToDayArray(uint256 _days) internal{
        bool isAvailable;
        for(uint256 i=0;i<daysArray.length;i++){
            if(daysArray[i]==_days){
                isAvailable=true;
                break;
            }
        }
        if(!isAvailable){
            daysArray.push(_days);
        }
    }
    function isDaysAvailable(uint256 _days) external view returns(bool){
        for(uint256 i=0;i<daysArray.length;i++){
            if(daysArray[i]==_days){
                return true;
            }
        }
        return false;
    }
    function getDaysArray() external view returns(uint256[] memory){
        return daysArray;
    }
    
    
    modifier onlyMyContracts() {
        require(msg.sender == XIVMainContractAddress || msg.sender==XIVBettingFixedContractAddress || msg.sender== XIVBettingFlexibleContractAddress);
        _;
    }
    fallback() external payable {
    }
}