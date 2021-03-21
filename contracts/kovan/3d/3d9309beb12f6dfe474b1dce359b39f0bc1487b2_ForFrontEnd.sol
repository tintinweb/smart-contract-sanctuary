/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface MonkeyNFT{
   function mintMonkey(address to,uint256 generation,uint256 mininggift) external;
   function totalSupply() external view returns (uint256);
   function updateWeight(uint256 tokenId,uint256 weight) external;
   function updateMininggift(uint256 tokenId,uint256 mininggift) external;
   function getMininggift(uint256 tokenId) external view  returns (uint256);
   function getWeight(uint256 tokenId) external view  returns (uint256);
   function ownerOf(uint256 tokenId) external view returns (address owner);
   function getGeneration(uint256 tokenId) external view  returns (uint256);
   function isApprovedForAll(address owner, address operator) external view returns (bool);
   function transferFrom(address from, address to, uint256 tokenId) external;
   function balanceOf(address owner) external view returns (uint256 balance);
   function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

}

interface Feed{
    function getTokenIDWeight(uint256 tokenId,uint256 day) external view returns (uint256 weight,uint256 feedtimes);
    function getUserScore(address userAddress,uint256 day) external view returns (uint256 userWeightScore,uint256 userMiningScore,bool userClaimStatus);
    function getTotalScore(uint256 day) external view returns(uint256 totalWeightScore, uint256 totalMiningScore, uint256 FeedRewardPerScore,uint256 MKYRewardPerToken);
    function today() external view returns(uint256);
    function claimable(address userAddress) view external returns (uint256 FeedReward,uint256 MKYRewar);
}

interface Market{
    function marketDetail() view external returns(uint256[] memory);
    function orderDetail(uint256 orderId) view external returns(address seller,uint256 tokenId,uint256 price ,bool haveBroughtOrCancel);
}
contract ForFrontEnd {
 

    address public _tokenToPay = 0x5E8A819CCF47E3a83864c6c8cb6328cbe223093C;
    address public _monkeyNFT = 0x5E8A819CCF47E3a83864c6c8cb6328cbe223093C;
    address public _boxesToken = 0x1FcB262dbD2Cc462091714517819448Ea754C5E8;    
    address public _boxesV1 =0x34253a0bF7E13aaC135BFBe93Db07557Ff6451b4;
    address public _feed=0xE53bd7e4E26D4a6A932Be6a1E85632C33Ed9B529;
    address public _market = 0x7E57cADC97014986954D6828304d78e1BD014197;
    address public _monkeyToken =0x5243a416BF3EccAFA1A560F0C8A5E748EE4ED730;
    MonkeyNFT public monkeyNFT;
    Feed public feed;
    Market public market;
    constructor(){ 
        monkeyNFT = MonkeyNFT(_monkeyNFT);
        feed =Feed(_feed);
        market=Market(_market);
    }       
    function myMonkeyNFTMore(address myaddress) view public returns(uint256[] memory ,uint256[] memory ,uint256[] memory ,uint256[] memory ,uint256[] memory ,uint256[] memory  ){
        uint256[] memory tokenids = myMonkeyNFTList(myaddress);
        uint256 amount=tokenids.length;
        uint256[] memory generations=new uint256[](amount);
        uint256[] memory mininggifts=new uint256[](amount);
        uint256[] memory weights=new uint256[](amount);  
        uint256[] memory todayweights=new uint256[](amount); 
        uint256[] memory feedtimes =new uint256[](amount); 
        for (uint256 i = 0; i < amount; ++i) {
            uint256 tokenid=tokenids[i];
            generations[i]=monkeyNFT.getGeneration(tokenid);
            mininggifts[i]=monkeyNFT.getMininggift(tokenid);
            weights[i]=monkeyNFT.getWeight(tokenid);
           (todayweights[i],feedtimes[i])=feed.getTokenIDWeight(tokenid,feed.today());            
        }
        return(tokenids, generations,mininggifts, weights, todayweights, feedtimes );

    }
    
    function myMonkeyNFTList(address myaddress) view public returns(uint256[] memory){
        uint256 amount =monkeyNFT.balanceOf(myaddress);
        uint256[] memory tokenids=new uint256[](amount); 
        for (uint256 i = 0; i < amount; ++i) {
             uint256 tokenid = monkeyNFT.tokenOfOwnerByIndex(myaddress,i);
             tokenids[i]=tokenid;
        }
        return (tokenids);
    }
    
    function getScoreAndReward(address myaddress) view public returns(uint256 todayUserScore,uint256  todayuserMiningScore,uint256 yesterdayUserScore,uint256 yesterdayuserMiningScore,bool yesterdayuserClaimStatus,uint256 FeedReward,uint256 MKYRewar){
         (todayUserScore ,todayuserMiningScore,)=feed.getUserScore(myaddress,feed.today());
         (yesterdayUserScore ,yesterdayuserMiningScore,yesterdayuserClaimStatus)=feed.getUserScore(myaddress,feed.today()-1);
         (FeedReward,MKYRewar)=feed.claimable(myaddress);
    
    }
    
    function getMarketMore() view public returns(uint256[] memory ,address[] memory  ,uint256[] memory ,uint256[] memory ,bool[] memory ){
        uint256[] memory orderIds = market.marketDetail();
        address[] memory seller =new address[](orderIds.length); 
        uint256[] memory tokenId =new uint256[](orderIds.length); 
        uint256[] memory price =new uint256[](orderIds.length); 
        bool[] memory haveBroughtOrCancel =new bool[](orderIds.length); 
        for (uint256 i = 0; i < orderIds.length; ++i) {
            (seller[i],tokenId[i], price[i] , haveBroughtOrCancel[i])=market.orderDetail(i);
        }  
        return(orderIds, seller,tokenId,price,haveBroughtOrCancel);
    }
    
}