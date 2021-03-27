/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;



interface ConditionalTokens{
    function getConditionId(address oracle, bytes32 questionId, uint outcomeSlotCount) external pure returns (bytes32) ;
    function prepareCondition(address oracle, bytes32 questionId, uint outcomeSlotCount) external;
    function getOutcomeSlotCount(bytes32 conditionId) external view returns (uint);
    function getList() external view returns(address[] memory );
    function balanceOf(address owner, uint256 id) external view returns (uint256);
    function redeemPositions(IERC20 collateralToken, bytes32 parentCollectionId, bytes32 conditionId, uint[] calldata indexSets, address account) external;
    function reportPayouts(bytes32 questionId, uint[] calldata payouts) external;
    function getIt() external view returns(address,address);
}

interface DollarInterface{
    function recipients_list() external view returns(address[] memory);
    function balanceOf(address account) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function getIt() external view returns(address,address);
}

interface IERC20{
    
}

interface FixedProductMarketMaker{
    function Z_getPoolBalances() external view returns (uint[] memory);
    function z_getAccountBalance(address accouunt) external view returns(uint[] memory);
    function z_fetPositionIds() external view returns(uint[] memory);
    function recipients_list() external view returns(address[] memory );
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function addFunding(uint addedFunds, uint[] calldata distributionHint, address account) external;
    function removeFunding(uint sharesToBurn, address account) external;
    function calcBuyAmount(uint investmentAmount, uint outcomeIndex) external view returns (uint);
    function buy(uint investmentAmount, uint outcomeIndex, uint minOutcomeTokensToBuy, address accouunt) external;
    function sell(uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell, address accouunt) external;
    function z_merg(address account) external;
    function getIt() external view returns(address,address);
}

interface MarketMakerFactory{
    function createFixedProductMarketMaker( 
        ConditionalTokens conditionalTokens,
        IERC20 collateralToken,
        bytes32[] calldata conditionIds,
        uint fee
    )
        external
        returns (FixedProductMarketMaker);
        
        
}

contract testWrapper {
    
    address aa1 = 0x126F1Fb23D340C3AF8027261a66BaA2c68f9B4de;
    address aa2 = 0x64A3f27a614a54591dc22bA88bb6785D790ee4f6;
    address aa3 = 0xacCdfE6CEf7409c63f2d6268987a8De9b2818B0B;
    

    DollarInterface demoToken;
    ConditionalTokens ct ;
    MarketMakerFactory mf ;
    
    constructor() public{
        demoToken  = DollarInterface(aa1);
        ct = ConditionalTokens(aa2);
        mf = MarketMakerFactory(aa3);
    }
    
    struct tokenBalnce{
        address holder;
        uint yesBalnce;
        uint noBalance;
    }
    
    struct account_balance{
      address account;
      uint256 balance;
    }
    
    function dollar_balance(address account) external view returns(uint256){
        return demoToken.balanceOf(account);
    }
    
    function dollar_balanceList() external view returns(account_balance[] memory dollarBalances){
        
        address[] memory recipients = demoToken.recipients_list();
        dollarBalances = new account_balance[](recipients.length);
        for(uint256 i=0;i<recipients.length;i++){
            dollarBalances[i] = account_balance({
                account: recipients[i],
                balance: demoToken.balanceOf(recipients[i])
            });
        }
    }
    
    
    
    function dollar_mint(address account, uint256 amount) external{
        return demoToken.mint(account,amount);
    }
    
    
    function isMarketCreated(bytes32 questionId) public view returns (bool){
        FixedProductMarketMaker market = marketFromQ[questionId];
        if(address(market) != address(0)){
            return true;
        }else{
            return false;
        }
    }
    
   
    
   
    
    function yesno_balancePool(bytes32 questionId) external view returns (uint256[] memory){
       return marketFromQ[questionId].Z_getPoolBalances();
    }
    
    function yesno_percentage(bytes32 questionId) external view returns (uint256[] memory){
        uint[] memory yesNo_inpool = marketFromQ[questionId].Z_getPoolBalances();
        uint256 total = yesNo_inpool[0] + yesNo_inpool[1];
        
        uint256[] memory perc = new uint256[](2);
        perc[0] = yesNo_inpool[1] * 100 / total;
        perc[1] = yesNo_inpool[0] * 100 / total;
       return perc;
    }
    
    function yesno_balance(bytes32 questionId,address account) external view returns (uint[] memory){
       return marketFromQ[questionId].z_getAccountBalance(account);
    }
    
    function yesno_balanceList(bytes32 questionId) external view returns(tokenBalnce[] memory balancesList){
        
        uint[] memory positionIds = marketFromQ[questionId].z_fetPositionIds();
        address[] memory holders = ct.getList();
        balancesList = new tokenBalnce[](holders.length);
        for(uint i=0;i<holders.length;i++){
            uint y =  ct.balanceOf(holders[i], positionIds[0]);
            uint n =  ct.balanceOf(holders[i], positionIds[1]);
            
            balancesList[i] = tokenBalnce({
                holder: holders[i],
                yesBalnce: y,
                noBalance:n
            });
        }
        
    }
    
    function share_balance(bytes32 questionId ,address account) external view returns(uint256){
        return marketFromQ[questionId].balanceOf(account);
    }
    
    
    function share_totalBalance(bytes32 questionId) external view returns(uint256){
        FixedProductMarketMaker market = marketFromQ[questionId];
        return market.totalSupply();
    }
    
    
    function share_balanceList(bytes32 questionId) external view returns(account_balance[] memory sharesBalances){
        address[] memory recipients = marketFromQ[questionId].recipients_list();
        sharesBalances = new account_balance[](recipients.length);
        for(uint256 i=0;i<recipients.length;i++){
            sharesBalances[i] = account_balance({
                account: recipients[i],
                balance: marketFromQ[questionId].balanceOf(recipients[i])
            });
        }
    }
    
    mapping(bytes32 => FixedProductMarketMaker) marketFromQ;
    
    

    function marketCreate(bytes32 questionId) public{
       require(isMarketCreated(questionId) == false,"Market alreay opened");
        ct.prepareCondition(address(this), questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(address(this), questionId, 2);
        FixedProductMarketMaker m = mf.createFixedProductMarketMaker(ct,IERC20(address(demoToken)),conditionIds,0);
        marketFromQ[questionId] = m;
        
    }
    
    function getConditionId(bytes32 questionId) public view returns(bytes32){
        return ct.getConditionId(address(this), questionId, 2);
    }
    
    function getMarket(bytes32 questionId) public view returns(FixedProductMarketMaker){
        return marketFromQ[questionId];
    }
    
    function addLiquidity(bytes32 questionId, uint256 dollarAmount, address account) external {
        FixedProductMarketMaker market = marketFromQ[questionId];
        uint[] memory tmpM;
        if(market.totalSupply() >0){
            
            market.addFunding(dollarAmount,tmpM,account);
        }else{
            tmpM = new uint[](2);
            tmpM[0] = 1;
            tmpM[1] = 1;
            market.addFunding(dollarAmount,tmpM,account);
        }
    }
    
    function removeLiquidity(bytes32 questionId, uint256 shareAmount, address account) external {
        FixedProductMarketMaker market = marketFromQ[questionId];
        market.removeFunding(shareAmount,account);
        //todo merge
    }
    
    
    function mergeTheYesNo(bytes32 questionId, address account) public{
        FixedProductMarketMaker market = marketFromQ[questionId];
        market.z_merg(account);
    }
    
    function calcBuyAmount(bytes32 questionId, uint investmentAmount, uint outcomeIndex) external view returns (uint){
        return marketFromQ[questionId].calcBuyAmount(investmentAmount,outcomeIndex);
    }
    
    function buy(bytes32 questionId, uint256 index, uint256 dollarAmount, address account) external {
        return marketFromQ[questionId].buy(dollarAmount,index,0,account);
    }
    
    function sell(bytes32 questionId, uint256 indx, uint256 amount, address account) external{
        uint256 expectedRet = calcSellReturnInv(questionId,indx,amount);
        //function sell(uint returnAmount, uint outcomeIndex, uint maxOutcomeTokensToSell, address accouunt)
        marketFromQ[questionId].sell(expectedRet,indx,amount*105/100,account);
    }
    
    
    function resolve(bytes32 questionId, uint256 correctIndx) external{
        //function reportPayouts(bytes32 questionId, uint[] calldata payouts) external
        uint256[] memory indxs = new uint256[](2);
        indxs[0]=0;
        indxs[1]=0;
        indxs[correctIndx] =1;
        ct.reportPayouts(questionId,indxs);
    }
    
    function redeem(bytes32 questionId, address account) external{
        uint256[] memory indexSet = new uint256[](2);
        indexSet[0] =1;
        indexSet[1] =2;
        ct.redeemPositions(IERC20(address(demoToken)),0x0000000000000000000000000000000000000000000000000000000000000000,ct.getConditionId(address(this), questionId, 2),indexSet,account);
    }
    function sqrt(uint x) private pure returns  (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    function sqrtMyMY(uint x) private pure returns  (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        z = z+1;
    }
   
    
    function calcSellReturnInv(bytes32 questionId, uint inputIndex, uint amount) public view returns(uint256 ret){
         uint256[] memory poolBalnce0 = marketFromQ[questionId].Z_getPoolBalances();
         
        uint256  c = poolBalnce0[0] * poolBalnce0[1];

        uint256 m=0;
         if(inputIndex == 0){
             m = amount + poolBalnce0[0] -poolBalnce0[1];
             
         }else{
             m = amount + poolBalnce0[1] -poolBalnce0[0];
         }
         
         uint256 f= sqrtMyMY((m * m) + 4*c);
         
         if(inputIndex == 0){
            ret = ((2* poolBalnce0[1]) -  (f - m)) /2;
         }else{
             ret = ((2* poolBalnce0[0]) - (f - m)) /2;
         }
         
         
    }
    
    
    function calcSellReturnInv2(bytes32 questionId, uint inputIndex, uint amount) public view returns(uint256 c, uint256 m, uint256 f, uint256 np1,uint256 ret){
         uint256[] memory poolBalnce0 = marketFromQ[questionId].Z_getPoolBalances();
         
         c = poolBalnce0[0] * poolBalnce0[1];

         if(inputIndex == 0){
             m = amount + poolBalnce0[0] -poolBalnce0[1];
             
         }else{
             m = amount + poolBalnce0[1] -poolBalnce0[0];
         }
         
         f= sqrtMyMY((m * m) + 4*c);
         np1 = (f-m)/2;
         
         if(inputIndex == 0){
            ret = ((2* poolBalnce0[1]) -  (f - m)) /2;
         }else{
             ret = ((2* poolBalnce0[0]) - (f - m)) /2;
         }
         
         
    }
}