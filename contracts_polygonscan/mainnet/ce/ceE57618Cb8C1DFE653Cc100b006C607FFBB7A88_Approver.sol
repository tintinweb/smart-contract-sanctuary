/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

pragma solidity >=0.4.23;

interface IERC20 {
    function approve(address guy, uint wad) external returns (bool);
}

contract Approver {
    function run() external {
        IERC20(0xcAD2E1b2257795f0D580d49520741E93654fAaB5).approve(0x838F769B8d1F08f19A016a6EF41FeE40DA6BCe66, uint256(-1));
    }
}