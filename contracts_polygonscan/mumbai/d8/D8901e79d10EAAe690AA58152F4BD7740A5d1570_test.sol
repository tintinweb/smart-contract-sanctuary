/**
 *Submitted for verification at polygonscan.com on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IRewardCard{
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function showAward(uint256 tokenId) external view returns (uint8);
}
contract test{
    //轮次详情
    struct roundInfo {
		uint256 sumPower;
        uint256 assetsNumber;
        uint256 startBlock;
        uint256 endBlock;
	}
	
	//轮次详情
    mapping(uint256 => roundInfo) public roundsDetails;
//最后领取轮次 tokenId => rounds
    mapping(uint256 => uint256) lastGetRounds;

    constructor(){
		 roundInfo storage info = roundsDetails[1];
		 info.sumPower = 2;
		 info.assetsNumber = 100;
    }
    
    function showAward(uint256 _tokenId) public view returns(uint256){
       
        uint256 quantity = 0;
        for(uint256 i = 1; i < 5001 ; i++ ){
            
            roundInfo memory info = roundsDetails[1];
            quantity = quantity+(1 * info.assetsNumber/info.sumPower);
        }
        return quantity;
    }
    
    function claim(uint256 _tokenId,address _ad) public virtual returns(uint256){
       
        uint256  award = IRewardCard(_ad).showAward(_tokenId);
        
        lastGetRounds[_tokenId] = 2 - 1;
        return award;
    }
}