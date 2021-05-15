// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./InlineInterface.sol";

contract InlineBettingFixed is Ownable{
    
     using SafeMath for uint256;
    uint256 constant secondsInADay=24 hours;
    
    uint256 stakeOffset;
    bool isValued=false;
    address public databaseContractAddress=0x4C82649c190Ad1D8b98dcbE17f1826d2F3855862;
    
    
     function betFixed(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex) external{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible 4-> flash fixed 5-> flash flexible
        require(typeOfBet==0 || typeOfBet==2 || typeOfBet==4,"Invalid bet Type");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(!dContract.getExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress),"you can't place bet using these values.");
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        require((dContract.getBetFactorLP()).mul(dContract.getTokenStakedAmount())>=
                        ((tokenObj.balanceOf(databaseContractAddress)).sub(dContract.getTokenStakedAmount())).add(amountOfXIV),
                        "Staking Vaults Have EXCEEDED CAPACITY. Please Check Back in 24hrs?");
        require(amountOfXIV>=dContract.getMinStakeXIVAmount() && amountOfXIV<=dContract.getMaxStakeXIVAmount(),"Please enter amount in the specified range");
                   
        if(typeOfBet==0 || typeOfBet==4){
            bool isFlashVault=(typeOfBet==4?true:false);
            require(dContract.isDaysAvailable(dContract.getFixedDefiCoinArray()[betSlabeIndex].daysCount),"Day does not exists.");
            require(dContract.getFixedDefiCoinArray().length>betSlabeIndex,"Day does not exists.");
            require(checkTimeForBet(dContract.getFixedDefiCoinArray()[betSlabeIndex].daysCount),"Staking time closed for the selected day");
            require(dContract.getDefiCoinsFixedMapping(_betContractAddress,isFlashVault).status,"The currency is currently disabled.");
           
            // defi fixed
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
            InlineDatabaseLib.BetInfo memory binfo=InlineDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:_betContractAddress,
                betType:typeOfBet,
                currentPrice:uint256(oWObject.getPrice(dContract.getDefiCoinsFixedMapping(_betContractAddress,isFlashVault).currencySymbol, dContract.getDefiCoinsFixedMapping(_betContractAddress,isFlashVault).oracleType)),
                betTimePeriod:(dContract.getFixedDefiCoinArray()[betSlabeIndex].daysCount).mul(1 days),
                checkpointPercent:dContract.getFixedDefiCoinArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFixedDefiCoinArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFixedDefiCoinArray()[betSlabeIndex].riskFactor,
                timestamp:block.timestamp,
                adminCommissionFee:0,
                status:0
            });
            dContract.updateBetArray(binfo);
            dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
            if(dContract.getBetsAccordingToUserAddress(msg.sender).length==0){
                dContract.addUserAddressUsedForBetting(msg.sender);
            }
            dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
            dContract.updateBetId(dContract.getBetId().add(1));
            uint256 betEndTime=((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay)).add(secondsInADay.div(2)).add(binfo.betTimePeriod).sub(1));
            dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        }else if(typeOfBet==2){
            //index Fixed 
            require(dContract.isDaysAvailable(dContract.getFixedDefiIndexArray()[betSlabeIndex].daysCount),"Day does not exists.");
            require(dContract.getFixedDefiIndexArray().length>betSlabeIndex,"Day does not exists.");
            require(checkTimeForBet(dContract.getFixedDefiIndexArray()[betSlabeIndex].daysCount),"Staking time closed for the selected day");
            
             InlineDatabaseLib.BetInfo memory binfo=InlineDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:address(0),
                betType:typeOfBet,
                currentPrice:uint256(calculateIndexValueForFixedInternal(dContract.getBetId())),
                betTimePeriod:(dContract.getFixedDefiIndexArray()[betSlabeIndex].daysCount).mul(1 days),
                checkpointPercent:dContract.getFixedDefiIndexArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFixedDefiIndexArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFixedDefiIndexArray()[betSlabeIndex].riskFactor,
                timestamp:block.timestamp,
                adminCommissionFee:0,
                status:0
            });
            dContract.updateBetArray(binfo);
            dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
            if(dContract.getBetsAccordingToUserAddress(msg.sender).length==0){
                dContract.addUserAddressUsedForBetting(msg.sender);
            }
            dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
            dContract.updateBetId(dContract.getBetId().add(1));
            uint256 betEndTime=((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay)).add(secondsInADay.div(2)).add(binfo.betTimePeriod).sub(1));
            dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        }
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfXIV);
        dContract.updateTotalTransactions(dContract.getTotalTransactions().add(amountOfXIV));
        dContract.updateExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress,true);
    }
    function checkTimeForBet(uint256 _days) public view returns(bool){
        uint256 currentTime=block.timestamp;
        uint256 utcNoon=((block.timestamp.div(secondsInADay)).mul(secondsInADay)).add(secondsInADay.div(2));
        if(_days==1){
            if(((utcNoon).add(4 hours))>currentTime && utcNoon<currentTime){
                return true;
            }else{
                return false;
            }
        }else if(_days==3){
            if(((utcNoon).add(12 hours))>currentTime  && utcNoon<currentTime){
                return true;
            }else{
                return false;
            }
        }
        return true;
    }
    
    function calculateIndexValueForFixedInternal(uint256 _betId) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
                dContract.updateBetIndexForFixedArray(_betId,iCObj);
            }
        }
        InlineDatabaseLib.BetPriceHistory memory bPHObj=InlineDatabaseLib.BetPriceHistory({
            baseIndexValue:dContract.getBetBaseIndexValue()==0?10**11:dContract.getBetBaseIndexValue(),
            actualIndexValue:totalMarketcap
        });
        dContract.updateBetPriceHistoryFixedMapping(_betId,bPHObj);
        if(dContract.getBetBaseIndexValue()==0){
            dContract.updateBetBaseIndexValue(10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValue()){
                dContract.updateBetBaseIndexValue(dContract.getBetBaseIndexValue().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValue()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue())));
            }else if(totalMarketcap<dContract.getBetActualIndexValue()){
                dContract.updateBetBaseIndexValue(dContract.getBetBaseIndexValue().sub((
                                                     (dContract.getBetActualIndexValue().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue())));
            }
        }
        dContract.updateBetActualIndexValue(totalMarketcap);
        return totalMarketcap;
    }
    function updateStatus(uint256[] memory offerIds/**uint256 pageNo, uint256 pageSize**/) external {
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
        if(!isValued){
            stakeOffset=stakeOffset.add(dContract.getTokenStakedAmount());
            isValued=true;
        }
           for(uint256 i=0;i<offerIds.length;i++){ 
            InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[offerIds[i]];
            if(bObject.status==0){
                uint256 sevenDaysTime=((((bObject.timestamp).div(secondsInADay)).mul(secondsInADay)).add(bObject.betTimePeriod).sub(1));
                if(block.timestamp>=sevenDaysTime){
                     if(bObject.betType==0 || bObject.betType==1 || bObject.betType==4 || bObject.betType==5){
                        // defi fixed
                        string memory tempSymbol;
                        uint256 tempOracle;
                        if(bObject.betType==0 || bObject.betType==4 || bObject.betType==5){
                            bool isFlashVault=((bObject.betType==4 || bObject.betType==5)?true:false);
                            tempSymbol=dContract.getDefiCoinsFixedMapping(bObject.contractAddress,isFlashVault).currencySymbol;
                            tempOracle=dContract.getDefiCoinsFixedMapping(bObject.contractAddress,isFlashVault).oracleType;
                        }else if(bObject.betType==1){
                            tempSymbol=dContract.getDefiCoinsFlexibleMapping(bObject.contractAddress).currencySymbol;
                            tempOracle=dContract.getDefiCoinsFlexibleMapping(bObject.contractAddress).oracleType;
                        }
                        uint256 currentprice=uint256(oWObject.getPrice(tempSymbol, tempOracle));
                       
                        if(currentprice>bObject.currentPrice){
                            uint16 percentageValue=uint16(((currentprice.sub(bObject.currentPrice).mul(10**4))
                                                    .div(currentprice)));
                            if(percentageValue>=bObject.checkpointPercent){
                                updateXIVForStakers(offerIds[i], true);
                            }else{
                                updateXIVForStakers(offerIds[i], false);
                            }
                        }else{
                            updateXIVForStakers(offerIds[i], false);
                        }
                    }else if(bObject.betType==2){
                        //index Fixed 
                       updateXIVForStakersIndexFixed(offerIds[i]);
                        
                    }else if(bObject.betType==3){
                        //index flexible
                       updateXIVForStakersIndexFlexible(offerIds[i]);
                    }
                }
            }
        }
    }
    function getUserStakedAddressCount() public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        return dContract.getUserStakedAddress().length;
    }
    function incentiveStakers(uint256 pageNo, uint256 pageSize) external{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 pageStart=pageNo.mul(pageSize);
        uint256 pageSizeValue=(pageSize.mul(pageNo.add(1)));
        if(getUserStakedAddressCount()<pageSizeValue){
            pageSizeValue=getUserStakedAddressCount();
        }
        for(uint256 i=pageStart;i<pageSizeValue;i++){
            address userAddress=dContract.getUserStakedAddress()[i];
            uint256 updatedAmount;
            if(stakeOffset>0){
                updatedAmount=(((dContract.getTokensStaked(userAddress).mul(10**4).mul(stakeOffset))
                                    .div(dContract.getTokenStakedAmount().mul(10**4))));
            }else{
                updatedAmount=dContract.getTokensStaked(userAddress);
            }
            
            dContract.updateTokensStaked(userAddress,updatedAmount);
        }
        if(getUserStakedAddressCount()<pageSizeValue || getUserStakedAddressCount()==pageSizeValue){
            if(stakeOffset>0){
                dContract.updateTokenStakedAmount(stakeOffset);
            }else{
                dContract.updateTokenStakedAmount(dContract.getTokenStakedAmount());
            }
            stakeOffset=0;
            isValued=false;
        }
    }
   
     function updateXIVForStakers(uint256 index, bool isWon) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(isWon){
            bObject.status=1;
            uint256 rewardAmount=(uint256(bObject.rewardFactor).mul(bObject.amount)).div(10**4);
            dContract.updateRewardGeneratedAmount(dContract.getRewardGeneratedAmount().add(rewardAmount));
            stakeOffset=stakeOffset.sub(rewardAmount);
            bObject.amount=bObject.amount.add(rewardAmount);
            dContract.updateBetArrayIndex(bObject,index);
        }else{
            bObject.status=2;
            uint256 riskAmount=(uint256(bObject.riskFactor).mul(bObject.amount)).div(10**4);
            stakeOffset=stakeOffset.add(riskAmount);
            bObject.amount=bObject.amount.sub(riskAmount);
            dContract.updateBetArrayIndex(bObject,index);
        }
        dContract.updateExistingBetCheckMapping(bObject.userAddress,bObject.betType,bObject.contractAddress,false);
    }
    
    function getCalculateIndexValueForFixed(uint256 index) public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        for(uint256 i=0;i<dContract.getBetIndexForFixedArray(bObject.id).length;i++){
            Token tObj=Token(dContract.getBetIndexForFixedArray(bObject.id)[i].contractAddress);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getBetIndexForFixedArray(bObject.id)[i].contractAddress);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        return totalMarketcap;
    }
     function updateXIVForStakersIndexFixed(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap=getCalculateIndexValueForFixed(index);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(dContract.getBetPriceHistoryFixedMapping(bObject.id).actualIndexValue<totalMarketcap){
             uint16 percentageValue=uint16(((totalMarketcap.sub(dContract.getBetPriceHistoryFixedMapping(bObject.id).actualIndexValue)
                                                .mul(10**4)).div(totalMarketcap)));
            if(percentageValue>=bObject.checkpointPercent){
                updateXIVForStakers(index, true);
            }else{
                updateXIVForStakers(index, false);
            }
        }else{
            updateXIVForStakers(index, false);
        }
    }
    function getCalculateIndexValueForFlexible(uint256 index) public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        for(uint256 i=0;i<dContract.getBetIndexForFlexibleArray(bObject.id).length;i++){
            Token tObj=Token(dContract.getBetIndexForFlexibleArray(bObject.id)[i].contractAddress);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getBetIndexForFlexibleArray(bObject.id)[i].contractAddress);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        return totalMarketcap;
    }
    function marketCapValue(InlineDatabaseLib.IndexCoin memory iCObj,Token tObj) internal view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
         if((keccak256(abi.encodePacked(iCObj.currencySymbol))) == (keccak256(abi.encodePacked("ETH"))) || (keccak256(abi.encodePacked(iCObj.currencySymbol))) == (keccak256(abi.encodePacked("BTC")))){
            return ((((oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                    /*    .mul(iCObj.contributionPercentage)*/)
                                        .div(10**2)));
        }else{
            return (((tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                /*.mul(iCObj.contributionPercentage)*/)
                                .div((10**tObj.decimals()).mul(10**2))));
        }
    }
    function updateXIVForStakersIndexFlexible(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap=getCalculateIndexValueForFlexible(index);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(dContract.getBetPriceHistoryFlexibleMapping(bObject.id).actualIndexValue<totalMarketcap){
             uint16 percentageValue=uint16(((totalMarketcap.sub(dContract.getBetPriceHistoryFlexibleMapping(bObject.id).actualIndexValue)
                                                     .mul(10**4)).div(totalMarketcap)));
            if(percentageValue>=bObject.checkpointPercent){
                updateXIVForStakers(index, true);
            }else{
                updateXIVForStakers(index, false);
            }
        }else{
            updateXIVForStakers(index, false);
        }
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}