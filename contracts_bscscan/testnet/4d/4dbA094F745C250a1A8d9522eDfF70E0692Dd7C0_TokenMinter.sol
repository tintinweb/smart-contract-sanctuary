/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// File: interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}
// File: TokenMinter.sol


pragma solidity 0.8.10;


contract TokenMinter {

    IERC20 public fhtn;
    IERC20 public gil;

    constructor(address _fhtn,address _gil) {
        fhtn = IERC20(_fhtn);
        gil = IERC20(_gil);
    }

    function mintFHTN() external {
        fhtn.mint(msg.sender, 10000 ether);
    }

    function mintGil() external {
        gil.mint(msg.sender, 10000 ether);
    }

}