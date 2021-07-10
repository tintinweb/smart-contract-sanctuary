/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity ^0.4.24;




interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}


contract MyContract {
    
    function senddUSDT(address _to, uint256 _amount) external {
        IERC20 dUSDT = IERC20(address(0x6279fa1A1497D3B21764A81ab9d18eC8dCabd3B1));
        dUSDT.transfer(_to, _amount);
    }
    
}