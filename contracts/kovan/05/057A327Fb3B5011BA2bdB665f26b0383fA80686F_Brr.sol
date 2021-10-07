/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.0;

interface IPolyLocker {
    
    function limitLock(string calldata _meshAddress, uint256 _lockedValue) external;   
}

interface IERC20 {
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function balanceOf(address who) external returns (uint256);
    
}

contract Brr {
    
    address polylocker;
    
    address constant polyToken = 0xB347b9f5B56b431B2CF4e1d90a5995f7519ca792;
    
    constructor(address _polyLocker) {
        polylocker = _polyLocker;
    }
    
    function multiPolyLocking(string[] calldata _meshAddress, uint256[] calldata _lockedValue ) external {
        uint256 totalSum;
        
        for (uint256 i = 0; i<_lockedValue.length; i++) {
            totalSum +=  _lockedValue[i];
        }
        require(IERC20(polyToken).balanceOf(address(this)) >= totalSum, "Brr: Insufficient balance");
        require(IERC20(polyToken).approve(polylocker, totalSum), "Brr: Incorrect approval");
        
        for(uint256 i = 0; i<_lockedValue.length; i++) {
            IPolyLocker(polylocker).limitLock(_meshAddress[i], _lockedValue[i]);
        }
    }
}