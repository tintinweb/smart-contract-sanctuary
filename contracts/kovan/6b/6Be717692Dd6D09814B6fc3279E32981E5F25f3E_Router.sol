/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.8.0;

interface IRulerZap{
    function depositAndSwapToPaired(
        address _col, 
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt,
        uint256 _minPairedOut,
        address[] calldata _path,
        uint256 _deadline
    ) external;
}

contract Router{
    IRulerZap rulerZap;

    constructor(address _rulerZap){
        rulerZap = IRulerZap(_rulerZap);
    }

    function refinance() external{
        address _col = 0x90ec9Fe476a51Bd846238a5c79D78a23152Fc9CD;
        address _paired = 0x558B5CE2f1c1Fed4F25457A73A6C49A2d309958E;
        uint48 _expiry = 1640908800;
        uint256 _mintRatio = 600000000000000000000;
        uint256 _colAmt = 1000000000000000000;
        uint256 _minPairedOut = 588690000000000000000;
        address[] memory _path = new address[](2);
        _path[0] = 0x04078A1Bf5af6C63EEE69d32AED15bF3B4B72468;
        _path[1] = 0x558B5CE2f1c1Fed4F25457A73A6C49A2d309958E;
        uint256 _deadline = 1616674128;
        rulerZap.depositAndSwapToPaired(_col, _paired, _expiry, _mintRatio, _colAmt, _minPairedOut, _path, _deadline);
    }
}