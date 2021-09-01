/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

interface IRewarder {
    function poolInfo(uint256 pid) external view returns (address, uint256, uint256, uint256);
    function poolLength() external view returns (uint256);
}

contract RewarderAllocPoints {
    
    function totalAllocPoint(IRewarder rewarder) public view returns (uint256 total) {
        uint256 len = rewarder.poolLength();
        for (uint256 i; i < len; i++) {
            (,uint256 allocPoint,,) = rewarder.poolInfo(i);
            total += allocPoint;
        }
    }
    
}