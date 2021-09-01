/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

interface IRewarder {
    function poolLength() external view returns (uint256);
    function poolIds(uint256 pid) external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (uint128, uint64, uint64);
}

contract Rewarder {
    
    function totalAllocPoint(IRewarder rewarder) public view returns (uint256 total) {
        uint256 len = rewarder.poolLength();
        for (uint256 i; i < len; i++) {
            uint256 pid = rewarder.poolIds(i);
            (,, uint64 allocPoint) = rewarder.poolInfo(pid);
            total += allocPoint;
        }
    }
    
}