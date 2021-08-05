/**
 *Submitted for verification at Etherscan.io on 2021-01-09
*/

pragma solidity <=0.6.2;

interface IRelease {
    function release() external;
}

interface IERC20 {
	function balanceOf(address) external view returns (uint256);
}

contract SurfBoardTask {
    address private constant _surf = 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c;
    address private constant _surfBoards = 0xc456c79213D0d39Fbb2bec1d8Ec356c6d3970A2f;

    function check(uint _requirement)
    external view returns (uint256) {
        uint balance = IERC20(_surf).balanceOf(_surfBoards);

        if(balance >= _requirement)
            return 0;
        else
            return _requirement - balance;
    }

    function execute()
    external {
        IRelease(_surfBoards).release();
    }
}