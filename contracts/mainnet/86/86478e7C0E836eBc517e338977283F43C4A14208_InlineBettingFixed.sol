// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./InlineInterface.sol";

contract InlineBettingFixed is Ownable,ReentrancyGuard{
    
    using SafeMath for uint256;
    uint256 constant secondsInADay=24 hours;
    
    uint256 public stakeOffset;
    bool isValued=false;
    address public databaseContractAddress=0x96A0F13597D7DAB5952Cdcf8C8Ca09eAc97a0a75;
    
    
     function betFixed(uint256 amountOfXIV, uint16 typeOfBet, address _betContractAddress, uint256 betSlabeIndex) external nonReentrant{
        /* 0-> defi fixed, 1-> defi flexible, 2-> defi index fixed, 3-> defi index flexible, 
        * 4-> chain coin fixed, 5-> chain coin flexible, 6-> chain index fixed, 7-> chain index flexible
        * 8-> NFT fixed, 9-> NFT flexible, 10-> NFT index fixed, 11-> NFT index flexible
        */
        require(typeOfBet==0 || typeOfBet==2 || typeOfBet==4 || typeOfBet==6 || typeOfBet==8 || typeOfBet==10,"Invalid bet Type");
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        require(!dContract.getExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress),"you can't place bet using these values.");
        Token tokenObj = Token(dContract.getXIVTokenContractAddress());
        require((dContract.getBetFactorLP()).mul(dContract.getTokenStakedAmount())>=
                        ((tokenObj.balanceOf(databaseContractAddress)).sub(dContract.getTokenStakedAmount())).add(amountOfXIV),
                        "Staking Vaults Have EXCEEDED CAPACITY. Please Check Back in 24hrs?");
        require(amountOfXIV>=dContract.getMinStakeXIVAmount() && amountOfXIV<=dContract.getMaxStakeXIVAmount(),"Please enter amount in the specified range");
        uint256 _currentPrice;   
        InlineDatabaseLib.FixedInfo memory fixInfo;
        uint256 _coinType;
        if(typeOfBet==0 || typeOfBet==2){
            _coinType=1;
        }else if(typeOfBet==4 || typeOfBet==6){
            _coinType=2;
        }else if(typeOfBet==8 || typeOfBet==10){
            _coinType=3;
        }
        if(typeOfBet==0 || typeOfBet==4 || typeOfBet==8){
            require(dContract.getFixedDefiCoinArray().length>betSlabeIndex,"Day does not exists.");
            require(dContract.getFixedMapping(_betContractAddress,_coinType).status,"The currency is currently disabled.");
            OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
           _currentPrice=uint256(oWObject.getPrice(dContract.getFixedMapping(_betContractAddress,_coinType).currencySymbol, dContract.getFixedMapping(_betContractAddress,_coinType).oracleType));
            fixInfo=dContract.getFixedDefiCoinArray()[betSlabeIndex];
        }else{
            //index Fixed 
            require(dContract.getFixedDefiIndexArray().length>betSlabeIndex,"Day does not exists.");
            _currentPrice=uint256(calculateIndexValueForFixedInternal(dContract.getBetId(),_coinType));
            fixInfo=dContract.getFixedDefiIndexArray()[betSlabeIndex];
        }
        require(checkTimeForBet(fixInfo.daysCount),"Staking time closed for the selected day");
        
         InlineDatabaseLib.BetInfo memory binfo=InlineDatabaseLib.BetInfo({
                id:uint128(dContract.getBetId()),
                principalAmount:amountOfXIV,
                amount:amountOfXIV,
                userAddress:msg.sender,
                contractAddress:typeOfBet==2?address(0):_betContractAddress,
                betType:typeOfBet,
                currentPrice:_currentPrice,
                betTimePeriod:(uint256(fixInfo.daysCount)).mul(1 days),
                checkpointPercent:fixInfo.upDownPercentage,
                rewardFactor:fixInfo.rewardFactor,
                riskFactor:fixInfo.riskFactor,
                timestamp:block.timestamp,
                coinType:_coinType,
                status:0
            });
            dContract.updateBetArray(binfo);
        dContract.updateFindBetInArrayUsingBetIdMapping(dContract.getBetId(),dContract.getBetArray().length.sub(1));
        if(dContract.getBetsAccordingToUserAddress(msg.sender).length==0){
            dContract.addUserAddressUsedForBetting(msg.sender);
        }
        dContract.updateBetAddressesArray(msg.sender,dContract.getBetId());
        dContract.updateBetId(dContract.getBetId().add(1));
        uint256 betEndTime=(((((binfo.timestamp).div(secondsInADay)).mul(secondsInADay))).add(secondsInADay.div(2)).add(binfo.betTimePeriod).sub(1));
        dContract.emitBetDetails(binfo.id,binfo.status,betEndTime);
        
        dContract.transferFromTokens(dContract.getXIVTokenContractAddress(),msg.sender,databaseContractAddress,amountOfXIV);
        dContract.updateTotalTransactions(dContract.getTotalTransactions().add(amountOfXIV));
        dContract.updateExistingBetCheckMapping(msg.sender,typeOfBet,_betContractAddress,true);
    }
    function checkTimeForBet(uint256 _days) public view returns(bool){
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
    
    function calculateIndexValueForFixedInternal(uint256 _betId,uint256 coinType) internal returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        for(uint256 i=0;i<dContract.getAllIndexContractAddressArray(coinType).length;i++){
            Token tObj=Token(dContract.getAllIndexContractAddressArray(coinType)[i]);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getAllIndexContractAddressArray(coinType)[i],coinType);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
                dContract.updateBetIndexArray(_betId,iCObj);
            }
        }
        InlineDatabaseLib.BetPriceHistory memory bPHObj=InlineDatabaseLib.BetPriceHistory({
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
    function updateStatus(uint256[] memory offerIds) external nonReentrant{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        OracleWrapper oWObject=OracleWrapper(dContract.getOracleWrapperContractAddress());
          for(uint256 i=0;i<offerIds.length;i++){ 
            InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[offerIds[i]];
            if(bObject.status==0){
                uint256 sevenDaysTime=(((((bObject.timestamp).div(secondsInADay)).mul(secondsInADay))).add(secondsInADay.div(2)).add(bObject.betTimePeriod).sub(1));
                if(block.timestamp>=sevenDaysTime){
                    if(!isValued){
                        stakeOffset=stakeOffset.add(dContract.getTokenStakedAmount());
                        isValued=true;
                    }
                     if(bObject.betType==0 || bObject.betType==1 || bObject.betType==4 || bObject.betType==5 || bObject.betType==8 || bObject.betType==9){
                        // defi fixed
                        string memory tempSymbol;
                        uint256 tempOracle;
                        if(bObject.betType==0 || bObject.betType==4 || bObject.betType==8){
                            tempSymbol=dContract.getFixedMapping(bObject.contractAddress,bObject.coinType).currencySymbol;
                            tempOracle=dContract.getFixedMapping(bObject.contractAddress,bObject.coinType).oracleType;
                        }else{
                            tempSymbol=dContract.getFlexibleMapping(bObject.contractAddress,bObject.coinType).currencySymbol;
                            tempOracle=dContract.getFlexibleMapping(bObject.contractAddress,bObject.coinType).oracleType;
                        }
                        uint256 currentprice=uint256(oWObject.getPrice(tempSymbol, tempOracle));
                       
                        if(currentprice>bObject.currentPrice){
                            uint16 percentageValue=uint16(((currentprice.sub(bObject.currentPrice)).mul(10**4))
                                                    .div(currentprice));
                            if(percentageValue>=bObject.checkpointPercent){
                                updateXIVForStakers(offerIds[i], true);
                            }else{
                                updateXIVForStakers(offerIds[i], false);
                            }
                        }else{
                            updateXIVForStakers(offerIds[i], false);
                        }
                    }else{
                        //index  
                      updateXIVForStakersIndex(offerIds[i]);
                        
                    }
                }
            }
        }
    }
    function getUserStakedAddressCount() public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        return dContract.getUserStakedAddress().length;
    }
    
    function incentiveStakers(uint256 pageNo, uint256 pageSize) external nonReentrant{
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
    
    function getCalculateIndexValue(uint256 index) public view returns(uint256){
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap;
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        for(uint256 i=0;i<dContract.getBetIndexArray(bObject.id).length;i++){
            Token tObj=Token(dContract.getBetIndexArray(bObject.id)[i].contractAddress);
            InlineDatabaseLib.IndexCoin memory iCObj=dContract.getIndexMapping(dContract.getBetIndexArray(bObject.id)[i].contractAddress,bObject.coinType);
            if(iCObj.status){
                totalMarketcap=totalMarketcap.add(marketCapValue(iCObj,tObj));
            }
        }
        return totalMarketcap;
    }
    
    function updateXIVForStakersIndex(uint256 index) internal{
        DatabaseContract dContract=DatabaseContract(databaseContractAddress);
        uint256 totalMarketcap=getCalculateIndexValue(index);
        InlineDatabaseLib.BetInfo memory bObject=dContract.getBetArray()[index];
        if(dContract.getBetPriceHistoryMapping(bObject.id).actualIndexValue<totalMarketcap){
             uint16 percentageValue=uint16(((uint256(totalMarketcap)
                                                .sub(dContract.getBetPriceHistoryMapping(bObject.id).actualIndexValue)
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
    
    function updateDatabaseAddress(address _databaseContractAddress) external onlyOwner{
        databaseContractAddress=_databaseContractAddress;
    }
}