/**
 *Submitted for verification at arbiscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface ILiquidationBotHelper {
    function getInfoFlat(address[] memory accounts, address comptroller, address[] memory bamms)
        external view returns(address[] memory users, address[] memory bamm, uint[] memory repayAmount);
}

contract CheapHelper {
    function getInfo(bytes memory code, address[] calldata accounts, address comptroller, address[] calldata bamms)
        external returns(address[] memory users, address[] memory bamm, uint[] memory repayAmount)
    {
        address proxy;
        bytes32 salt = bytes32(0);
        assembly {
            proxy := create2(0, add(code, 0x20), mload(code), salt)
        }

        return ILiquidationBotHelper(proxy).getInfoFlat(accounts, comptroller, bamms);        
    }
}