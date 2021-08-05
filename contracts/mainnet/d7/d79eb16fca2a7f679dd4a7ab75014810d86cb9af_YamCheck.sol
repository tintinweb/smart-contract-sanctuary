/**
 *Submitted for verification at Etherscan.io on 2020-08-12
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}


contract YamCheck {
    IERC20 private _YAM = IERC20(0x0e2298E3B3390e3b945a5456fBf59eCc3f55DA16);
    
    function balanceOf(address account) external view returns (uint256) {
        return _YAM.balanceOf(account);
    }
}