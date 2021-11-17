/**
 *Submitted for verification at arbiscan.io on 2021-11-17
*/

// This governance contract calculcates total STBZ held by a particular address
// It first gets the STBZ tokens held in wallet
// Then LP tokens held in wallet to calculate STBZ held by user
// Then LP tokens held in operator contract pool
// Then STBZ as unclaimed rewards

pragma solidity =0.6.6;

interface Operator {
    function poolBalance(uint256, address) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function rewardEarned(uint256, address) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract StabilizeGovernanceCalculator {
    
    address constant OPERATOR_ADDRESS = address(0xCE820d0E671d30f4ac0a5007346c0E85fE12039F);
    address constant STBZ_ADDRESS = address(0x2C110867CA90e43D372C1C2E92990B00EA32818b);
    address constant LP_ADDRESS = address(0x835a1BcA3e5da0752dD73BD3f89AC0357fD34943);
    
    function calculateTotalSTBZ(address _address) external view returns (uint256) {
        IERC20 stbz = IERC20(STBZ_ADDRESS);
        uint256 mySTBZ = stbz.balanceOf(_address); // First get the token balance of STBZ in the wallet
        IERC20 lp = IERC20(LP_ADDRESS);
        uint256 myLP = lp.balanceOf(_address); // Get amount of LP in wallet
        myLP = myLP + Operator(OPERATOR_ADDRESS).poolBalance(0, _address);
        // Now we have our LP balance and must calculate how much STBZ we have in it
        uint256 stbzInLP = stbz.balanceOf(LP_ADDRESS);
        stbzInLP = stbzInLP * myLP / lp.totalSupply();
        mySTBZ = mySTBZ + stbzInLP;
        // Now calculate the unclaimed rewards in all the pools
        uint256 _poolLength = Operator(OPERATOR_ADDRESS).poolLength();
        for(uint256 i = 0; i < _poolLength; i++){
            mySTBZ = mySTBZ + Operator(OPERATOR_ADDRESS).rewardEarned(i, _address);
        }
        return mySTBZ;
    }

}