/**
 *Submitted for verification at Etherscan.io on 2020-12-07
*/

pragma solidity ^0.6.0;

interface IWhirlpool {
    function claim() external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract LeviathanWhirlpool {
    address private _surf = 0xEa319e87Cf06203DAe107Dd8E5672175e3Ee976c;
    address private _whirlpool = 0x999b1e6EDCb412b59ECF0C5e14c20948Ce81F40b;
    address private _leviathanClaim = 0xb4345a489e4aF3a33F81df5FB26E88fFeCEd6489;

    function release()
    external {
        IWhirlpool(_whirlpool).claim();

        uint256 balance = IERC20(_surf).balanceOf(address(this));

        if(balance > 0)
            IERC20(_surf).transfer(_leviathanClaim, balance);
    }
}