/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

pragma solidity >=0.4.23;

contract Test {
    function soul(address usr)
        external view
        returns (bytes32 tag)
    {
        assembly { tag := extcodehash(usr) }
    }
}

interface SpotLike {
    function file(bytes32 ilk, bytes32 what, address pip_) external;
}

contract SetSpot {
    function run() external {
        SpotLike(0xFA6388B7980126C2d7d0c5FC02949a2fF40F95DE).file("MATIC-A", "pip", 0x0B80158520d75868019579D109e5C3B10085663E);
        SpotLike(0xFA6388B7980126C2d7d0c5FC02949a2fF40F95DE).file("ETH-A", "pip", 0x5CadE8b6f31f01A7c4aBB2B551A836606e1c8063);
    }
    function test() external pure returns (bytes memory) {
        return abi.encodeWithSignature("run()");
    }
}

interface IERC20 {
    function approve(address guy, uint wad) external returns (bool);
}

contract Approver {
    function run() external {
        IERC20(0xcAD2E1b2257795f0D580d49520741E93654fAaB5).approve(0x838F769B8d1F08f19A016a6EF41FeE40DA6BCe66, uint256(-1));
    }
}

interface VatLike {
    function file(bytes32 ilk, bytes32 what, uint data) external;
}

contract SetDust {
    function run() external {
        VatLike(0x26E0701F5881161043d56eb3Ddfde0b8c6772060).file("MATIC-A", "dust", 0);
    }
    function test() external pure returns (bytes memory) {
        return abi.encodeWithSignature("run()");
    }
}