/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;


interface LOY {
    function resetNirv(uint _contestBlocks) external;
    function totalSupply() external view returns(uint);
    function ownerOf(uint tokenId) external returns(address);
    
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);
    
    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract YOLOVPromoAirdropper {
    
    
    address internal YOLOV;
    address public deployer;
    
    uint public startID;
    uint public totalRewards;
    uint public finishBlocks;
    
    uint public duration;
    
    LOY public LoyaltyContract = LOY(0x286ba9d9FEA067916254D5C6cCB2A0af7676DA43);
    
    constructor() {
        YOLOV = 0xD084C5a4a621914eD2992310024d2438DFde5BfD;
        deployer = msg.sender;
        duration = 1;
    }
    
    modifier onlyOwner() {
        require(msg.sender == deployer, "UNAUTH");
        _;
    }
    
    function startPromoPeriod(uint totalReward) external onlyOwner {
        IERC20(YOLOV).transferFrom(msg.sender, address(this), totalReward);
        startID = LoyaltyContract.totalSupply();
        totalRewards = IERC20(YOLOV).balanceOf(address(this));
        finishBlocks = block.number + duration;
    }
    
    function endPromoPeriod() external onlyOwner {
        
        require(block.number > finishBlocks, "Period Not Over");
        
        uint rewardEach = this.getRewardsEach();
        
        for(uint start = startID + 1; start <= LoyaltyContract.totalSupply(); start++) {
            IERC20(YOLOV).transfer(LoyaltyContract.ownerOf(start), rewardEach);
        }
        
    }
    
    function getTotalMinted() external view returns(uint nrMinted){
        return LoyaltyContract.totalSupply() - startID > 0 ? LoyaltyContract.totalSupply() - startID : 0;
    }
    
    function getRewardsEach() external view returns(uint rewardEach) {
        return this.getTotalMinted() > 1 ? totalRewards / this.getTotalMinted() : totalRewards;
    }
    
    function setDuration(uint a) external  onlyOwner{
      duration = a;
    }
    
    function wwTokens() external onlyOwner {
        
        IERC20(YOLOV).transfer(deployer, IERC20(YOLOV).balanceOf(address(this)));
    }
    
    
}