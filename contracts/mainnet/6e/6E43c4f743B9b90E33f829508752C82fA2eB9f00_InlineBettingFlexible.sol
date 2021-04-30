// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./InlineInterface.sol";

contract InlineBettingFlexible is Ownable{
    
    using SafeMath for uint256;
    address public databaseContractAddress=0x790E5E60a5B751A30d9210a2B9CE01De17D039A8;
    uint256 secondsInADay=24 hours;
    
    InlineDatabaseLib.IndexCoin[] tempObjectArray;
    
    function betFlexible(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex, uint256 _days) external{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible 4-> flash fixed 5-> flash flexible
        require(typeOfBet==1 || typeOfBet==3  || typeOfBet==5, "Invalid bet Type");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(!dContract.getExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress),"you can't place bet using these values.");
        require(dContract.isDaysAvailable(_days),"Day does not exists.");
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        require((dContract.getBetFactorLP()).mul(dContract.getTokenStakedAmount())>=
                        ((tokenObj.balanceOf(databaseContractAddress)).sub(dContract.getTokenStakedAmount())).add(amountOfXIV),
                        "Staking Vaults Have EXCEEDED CAPACITY. Please Check Back in 24hrs?");
       
        require(amountOfXIV>=dContract.getMinStakeXIVAmount() && amountOfXIV<=dContract.getMaxStakeXIVAmount(),"Please enter amount in the specified range");
       
        if(typeOfBet==1 || typeOfBet==5){
            //defi flexible
            require((typeOfBet==1?dContract.getDefiCoinsFlexibleMapping(_betContractAddress):
                                    dContract.getDefiCoinsFixedMapping(_betContractAddress,true)).status,"The currency is currently disabled.");
            require(isFlexibleDaysAvailable(_days,false),"Day does not exists.");
            require(checkTimeForBet(_days),"Staking time closed for the selected day");
            require(dContract.getFlexibleDefiCoinArray().length>betSlabeIndex,"Day does not exists.");
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
            InlineDatabaseLib.BetInfo memory binfo=InlineDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:_betContractAddress,
                betType:typeOfBet,
                currentPrice:uint256(oWObject.getPrice((typeOfBet==1?dContract.getDefiCoinsFlexibleMapping(_betContractAddress):
                                    dContract.getDefiCoinsFixedMapping(_betContractAddress,true)).currencySymbol, (typeOfBet==1?dContract.getDefiCoinsFlexibleMapping(_betContractAddress):
                                    dContract.getDefiCoinsFixedMapping(_betContractAddress,true)).oracleType)),
                betTimePeriod:_days.mul(1 days),
                checkpointPercent:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFlexibleDefiCoinArray()[betSlabeIndex].riskFactor,
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
            uint256 betEndTime=((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay)).add(binfo.betTimePeriod).sub(1));
            dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        }else if(typeOfBet==3){
            //index flexible
            require(isFlexibleDaysAvailable(_days, true),"Day does not exists.");
            require(checkTimeForBet(_days),"Staking time closed for the selected day");
            require(dContract.getFlexibleIndexArray().length>betSlabeIndex,"Day does not exists.");
            InlineDatabaseLib.BetInfo memory binfo=InlineDatabaseLib.BetInfo({
                id:dContract.getBetId(),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:address(0),
                betType:typeOfBet,
                currentPrice:uint256(calculateIndexValueForFlexibleInternal(dContract.getBetId())),
                betTimePeriod:_days.mul(1 days),
                checkpointPercent:dContract.getFlexibleIndexArray()[betSlabeIndex].upDownPercentage,
                rewardFactor:dContract.getFlexibleIndexArray()[betSlabeIndex].rewardFactor,
                riskFactor:dContract.getFlexibleIndexArray()[betSlabeIndex].riskFactor,
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
            uint256 betEndTime=((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay)).add(binfo.betTimePeriod).sub(1));
            dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        }
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfXIV);
        dContract.updateTotalTransactions(dContract.getTotalTransactions().add(amountOfXIV));
        dContract.updateExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress,true);
    }
    function checkTimeForBet(uint256 _days) internal view returns(bool){
        uint256 currentTime=block.timestamp;
        uint256 utcMidNight=((block.timestamp.div(secondsInADay)).mul(secondsInADay));
        if(_days==1){
            if(((utcMidNight).add(2 hours))>currentTime){
                return true;
            }else{
                return false;
            }
        }else if(_days==3){
            if(((utcMidNight).add(12 hours))>currentTime){
                return true;
            }else{
                return false;
            }
        }
        return true;
    }
    function isFlexibleDaysAvailable(uint256 _days, bool isIndex) internal view returns(bool){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        if(isIndex){
            for(uint256 i=0;i<dContract.getFlexibleIndexTimePeriodArray().length;i++){
                if(dContract.getFlexibleIndexTimePeriodArray()[i]._days==_days && dContract.getFlexibleIndexTimePeriodArray()[i].status==true){
                    return true;
                }
            }
        }else{
            for(uint256 i=0;i<dContract.getFlexibleDefiCoinTimePeriodArray().length;i++){
                if(dContract.getFlexibleDefiCoinTimePeriodArray()[i]._days==_days && dContract.getFlexibleDefiCoinTimePeriodArray()[i].status==true){
                    return true;
                }
            }
        }
        return false;
    }
   function calculateIndexValueForBetActual() external view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        return totalMarketcap;
    }
    function calculateIndexValueForBetBase() external view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
         if(dContract.getBetBaseIndexValue()==0){
            return (10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValue()){
                return (dContract.getBetBaseIndexValue().add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValue()))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue())));
            }else if(totalMarketcap<dContract.getBetActualIndexValue()){
                return (dContract.getBetBaseIndexValue().sub((
                                                     (dContract.getBetActualIndexValue().sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue())));
            }
        }
        return (10**11);
    }
    
    function calculateIndexValueForFlexibleInternal(uint256 _betId) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
                dContract.updateBetIndexForFlexibleArray(_betId,iCObj);
            }
        }
        InlineDatabaseLib.BetPriceHistory memory bPHObj=InlineDatabaseLib.BetPriceHistory({
            baseIndexValue:dContract.getBetBaseIndexValue()==0?10**11:dContract.getBetBaseIndexValue(),
            actualIndexValue:totalMarketcap
        });
        dContract.updateBetPriceHistoryFlexibleMapping(_betId,bPHObj);
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
    
    function claimBet(uint256 userBetId) external{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 index=dContract.getFindBetInArrayUsingBetIdMapping(userBetId);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        require((bObject.status==0) 
                || (bObject.status==1)
                || (bObject.status==2),"bet is closed.");
        if(bObject.status==0){
           if(block.timestamp.sub(bObject.timestamp) > 6 days){
                plentyFinal(index,7);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 5 days){
                plentyFinal(index,6);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 4 days){
                plentyFinal(index,5);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 3 days){
                plentyFinal(index,4);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 2 days){
                plentyFinal(index,3);
                return;
            }else if(block.timestamp.sub(bObject.timestamp) > 1 days){
                plentyFinal(index,2);
                return;
            }else{
                plentyFinal(index,1);
                return;
            }
        }else{
            claimBetFinal(index);
        }
    }
    
    function claimBetFinal(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        require(bObject.userAddress==msg.sender,"Authentication failure");
        require(bObject.amount!=0,"Your bet amount is 0");
        dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,(bObject.amount)); 
        bObject.amount=0; // return 3 times
        dContract.updateBetArrayIndex(bObject,index);
    }
    function plentyFinal(uint256 index, uint256 _days) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        uint256 plentyPercentage;
        if(bObject.betTimePeriod==1 days){
            plentyPercentage=dContract.getPlentyOneDayPercentage();
        }else if(bObject.betTimePeriod==3 days){
            plentyPercentage=dContract.getPlentyThreeDayPercentage(_days);
        }else if(bObject.betTimePeriod==7 days){
            plentyPercentage=dContract.getPlentySevenDayPercentage(_days);
        }
        if(plentyPercentage!=0){
            uint256 plentyAmount=((plentyPercentage.mul(bObject.amount)).div(10**4));
            uint256 userAmount=(bObject.amount).sub(plentyAmount);
            if(userAmount!=0){
                dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,userAmount); 
            }
            bObject.status=3;
            bObject.amount=0;
            
            InlineDatabaseLib.IncentiveInfo memory iInfo= InlineDatabaseLib.IncentiveInfo({
                tillInvestmentId:dContract.getInvestmentId().sub(1),
                incentiveAmount:plentyAmount,
                totalAmountStakedAtIncentiveTime:dContract.getTokenStakedAmount()
            }); 
            dContract.updateIncentiveMapping(dContract.getSlotId(),iInfo);
            dContract.updateSlotId(dContract.getSlotId().add(1));
            dContract.updateBetArrayIndex(bObject,index);
            dContract.updateExistingBetCheckMapping(bObject.userAddress,bObject.betType,bObject.contractAddress,false);
        }
    }
    
    function marketCapValue(InlineDatabaseLib.IndexCoin memory iCObj,Token tObj) internal view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
         if((keccak256(abi.encodePacked(iCObj.currencySymbol))) == (keccak256(abi.encodePacked("ETH"))) || (keccak256(abi.encodePacked(iCObj.currencySymbol))) == (keccak256(abi.encodePacked("BTC")))){
            return ((((oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                        /* .mul(iCObj.contributionPercentage)*/)
                                        .div(10**2)));
        }else{
            return (((tObj.totalSupply().mul(oWObject.getPrice(iCObj.currencySymbol,iCObj.oracleType))
                                /*.mul(iCObj.contributionPercentage)*/)
                                .div((10**tObj.decimals()).mul(10**2))));
        }
    }
    function getPieChartValue() external view returns(InlineDatabaseLib.IndexCoin[] memory){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        InlineDatabaseLib.IndexCoin[] memory tempIndexArray=new InlineDatabaseLib.IndexCoin[](dContract.getAllIndexContractAddressArray().length);
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray().length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray()[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getDefiCoinIndexMapping(dContract.getAllIndexContractAddressArray()[i]);
            if(iCObj.status){
                iCObj.contributionPercentage=(marketCapValue(iCObj,tObj).mul(10**4))/totalMarketcap;
                tempIndexArray[i]=iCObj;
            }
        }
        return tempIndexArray;
    }
    
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}