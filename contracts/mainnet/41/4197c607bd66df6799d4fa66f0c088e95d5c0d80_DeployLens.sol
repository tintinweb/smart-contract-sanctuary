/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.8.0;

contract DeployLens {

    address constant IMPL = 0x67Db14E73C2Dce786B5bbBfa4D010dEab4BBFCF9;
    bytes data;

    function deployMarketCalldata(
        address underlying,
        address comptroller,
        address irm,
        string calldata name,
        string calldata symbol,
        uint256 reserveFactor,
        uint256 adminFee
    ) external view returns (bytes memory) {
        return abi.encode(
            underlying,
            comptroller,
            irm,
            name,
            symbol,
            IMPL,
            data,
            reserveFactor,
            adminFee
        );
    }
}