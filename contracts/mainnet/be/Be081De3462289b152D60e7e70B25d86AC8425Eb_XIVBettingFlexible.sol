// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./XIVInterface.sol";

contract XIVBettingFlexible is Ownable,ReentrancyGuard{
    
    using SafeMath for uint256;
    address public databaseContractAddress=0x09eD6f016178cF5Aed0bda43A7131B775042a3c6;
    uint256 constant secondsInADay=24 hours;
    
    function betFlexible(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex, uint256 _days) external nonReentrant{
         /* 0-> defi fixed, 1-> defi flexible, 2-> defi index fixed, 3-> defi index flexible, 
        * 4-> chain coin fixed, 5-> chain coin flexible, 6-> chain index fixed, 7-> chain index flexible
        * 8-> NFT fixed, 9-> NFT flexible, 10-> NFT index fixed, 11-> NFT index flexible
        */
        require(typeOfBet==1 || typeOfBet==3  || typeOfBet==5 || typeOfBet==7 || typeOfBet==9  || typeOfBet==11, "Invalid bet Type");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(!dContract.getExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress),"you can't place bet using these values.");
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        require((dContract.getBetFactorLP()).mul(dContract.getTokenStakedAmount())>=
                        ((tokenObj.balanceOf(databaseContractAddress)).sub(dContract.getTokenStakedAmount())).add(amountOfXIV),
                        "Staking Vaults Have EXCEEDED CAPACITY. Please Check Back in 24hrs?");
       
        require(amountOfXIV>=dContract.getMinStakeXIVAmount() && amountOfXIV<=dContract.getMaxStakeXIVAmount(),"Please enter amount in the specified range");
       
        require(checkTimeForBet(_days),"Staking time closed for the selected day");
        uint256 _currentPrice;
        XIVDatabaseLib.FlexibleInfo memory flexInfo;
        uint256 _coinType;
        if(typeOfBet==1 || typeOfBet==3){
            _coinType=1;
        }else if(typeOfBet==5 || typeOfBet==7){
            _coinType=2;
        }else if(typeOfBet==9 || typeOfBet==11){
            _coinType=3;
        }
        if(typeOfBet==1 || typeOfBet==5 || typeOfBet==9){
            //defi flexible
            require(dContract.getFlexibleMapping(_betContractAddress,_coinType).status,"The currency is currently disabled.");
            require(dContract.getFlexibleDefiCoinArray().length>betSlabeIndex,"Day does not exists.");
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
            _currentPrice=uint256(oWObject.getPrice(dContract.getFlexibleMapping(_betContractAddress,_coinType).currencySymbol, dContract.getFlexibleMapping(_betContractAddress,_coinType).oracleType));
            flexInfo=dContract.getFlexibleDefiCoinArray()[betSlabeIndex];
        }else{
            //index flexible
            require(dContract.getFlexibleIndexArray().length>betSlabeIndex,"Day does not exists.");
            _currentPrice=uint256(calculateIndexValueForFlexibleInternal(dContract.getBetId(),_coinType));
            flexInfo=dContract.getFlexibleIndexArray()[betSlabeIndex];
        }
        XIVDatabaseLib.BetInfo memory binfo=XIVDatabaseLib.BetInfo({
            id:uint128(dContract.getBetId()),
            principalAmount:amountOfXIV,
            amount:amountOfXIV,
            userAddress:msg.sender,
            contractAddress:typeOfBet==3?address(0):_betContractAddress,
            betType:typeOfBet,
            currentPrice:_currentPrice,
            betTimePeriod:_days.mul(1 days),
            checkpointPercent:flexInfo.upDownPercentage,
            rewardFactor:flexInfo.rewardFactor,
            riskFactor:flexInfo.riskFactor,
            timestamp:block.timestamp,
            coinType:_coinType,
            status:0
        });
        
        saveBetInfo(binfo);
    }
    function saveBetInfo(XIVDatabaseLib.BetInfo memory binfo) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        dContract.updateBetArray(binfo);
        dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
        if(dContract.getBetsAccordingToUserAddress(binfo.userAddress).length==0){
            dContract.addUserAddressUsedForBetting(binfo.userAddress);
        }
        dContract.updateBetAddressesArray(binfo.userAddress,dContract.getBetId());
        dContract.updateBetId(dContract.getBetId().add(1));
        uint256 betEndTime=(((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay))).add(secondsInADay.div(2)).add(binfo.betTimePeriod).sub(1));
        dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),binfo.userAddress,databaseContractAddress,binfo.amount);
        dContract.updateTotalTransactions(dContract.getTotalTransactions().add(binfo.amount));
        dContract.updateExistingBetCheckMapping(binfo.userAddress,binfo.betType,binfo.contractAddress,true);
    }
    function checkTimeForBet(uint256 _days) internal view returns(bool){
        uint256 currentTime=block.timestamp;
        uint256 utcNoon=((currentTime.div(secondsInADay)).mul(secondsInADay)).add(secondsInADay.div(2));
        if(_days==1){
            if(((utcNoon).add(4 hours))>currentTime && utcNoon<currentTime){
                return true;
            }else{
                return false;
            }
        }else if(_days==3){
            if(((utcNoon).add(12 hours))>currentTime && utcNoon<currentTime){
                return true;
            }else{
                return false;
            }
        }
        return true;
    }
    
   function calculateIndexValueForBetActual(uint256 coinType) public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray(coinType).length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray(coinType)[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getAllIndexContractAddressArray(coinType)[i],coinType);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        return totalMarketcap;
    }
    function calculateIndexValueForBetBase(uint256 coinType) external view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap=calculateIndexValueForBetActual(coinType);
         if(dContract.getBetBaseIndexValue(coinType)==0){
            return (10**11);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValue(coinType)){
                return (dContract.getBetBaseIndexValue(coinType).add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValue(coinType)))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue(coinType))));
            }else if(totalMarketcap<dContract.getBetActualIndexValue(coinType)){
                return (dContract.getBetBaseIndexValue(coinType).sub((
                                                     (dContract.getBetActualIndexValue(coinType).sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue(coinType))));
            }
        }
        return (10**11);
    }
    
    function calculateIndexValueForFlexibleInternal(uint256 _betId,uint256 coinType) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray(coinType).length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray(coinType)[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getAllIndexContractAddressArray(coinType)[i],coinType);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
                dContract.updateBetIndexArray(_betId,iCObj);
            }
        }
        XIVDatabaseLib.BetPriceHistory memory bPHObj=XIVDatabaseLib.BetPriceHistory({
            baseIndexValue:uint128(dContract.getBetBaseIndexValue(coinType)==0?10**11:dContract.getBetBaseIndexValue(coinType)),
            actualIndexValue:uint128(totalMarketcap)
        });
        dContract.updateBetPriceHistoryMapping(_betId,bPHObj);
        if(dContract.getBetBaseIndexValue(coinType)==0){
            dContract.updateBetBaseIndexValue(10**11,coinType);
        }else{
            if(totalMarketcap>dContract.getBetActualIndexValue(coinType)){
                dContract.updateBetBaseIndexValue(dContract.getBetBaseIndexValue(coinType).add((
                                                     (totalMarketcap.sub(dContract.getBetActualIndexValue(coinType)))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue(coinType))),coinType);
            }else if(totalMarketcap<dContract.getBetActualIndexValue(coinType)){
                dContract.updateBetBaseIndexValue(dContract.getBetBaseIndexValue(coinType).sub((
                                                     (dContract.getBetActualIndexValue(coinType).sub(totalMarketcap))
                                                     .mul(100*10**8)).div(dContract.getBetActualIndexValue(coinType))),coinType);
            }
        }
        dContract.updateBetActualIndexValue(totalMarketcap,coinType);
        return totalMarketcap;
    }
    
    function claimBet(uint256 userBetId) external nonReentrant{
        // 0-> defi Fixed, 1->defi flexible, 2-> index Fixed and 3-> index flexible
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 index=dContract.getFindBetInArrayUsingBetIdMapping(userBetId);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
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
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        require(bObject.userAddress==msg.sender,"Authentication failure");
        require(bObject.amount!=0,"Your bet amount is 0");
        dContract.transferTokens(dContract.getXIVTokenContractAddress(),msg.sender,(bObject.amount)); 
        bObject.amount=0; // return 3 times
        dContract.updateBetArrayIndex(bObject,index);
    }
    function plentyFinal(uint256 index, uint256 _days) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        XIVDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
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
            if(plentyAmount!=0){
                dContract.transferTokens(dContract.getXIVTokenContractAddress(),dContract.getAdminAddress(),plentyAmount); 
            }
            bObject.status=3;
            bObject.amount=0;
            dContract.updateBetArrayIndex(bObject,index);
            dContract.updateExistingBetCheckMapping(bObject.userAddress,bObject.betType,bObject.contractAddress,false);
        }
    }
    
    function marketCapValue(XIVDatabaseLib.IndexCoin memory iCObj,Token tObj) internal view returns(uint256){
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
    function getPieChartValue(uint256 coinType) external view returns(XIVDatabaseLib.IndexCoin[] memory){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        XIVDatabaseLib.IndexCoin[] memory tempIndexArray=new XIVDatabaseLib.IndexCoin[](dContract.getAllIndexContractAddressArray(coinType).length);
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray(coinType).length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray(coinType)[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getAllIndexContractAddressArray(coinType)[i],coinType);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray(coinType).length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray(coinType)[i]);
            XIVDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getAllIndexContractAddressArray(coinType)[i],coinType);
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