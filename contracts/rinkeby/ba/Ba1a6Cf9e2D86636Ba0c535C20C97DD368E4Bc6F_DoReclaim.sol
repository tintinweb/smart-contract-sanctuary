/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity 0.5.13;

contract DoReclaim {
    event Reclaim(address indexed target, uint256 amount);
    function doReclaim(address payable target, uint256 amount) external {
        uint256 contractBalance = address(this).balance;
        uint256 reclaimAmount = (contractBalance < amount) ? contractBalance : amount;
        
        address(target).transfer(reclaimAmount);

        emit Reclaim(target, reclaimAmount);
    }
}