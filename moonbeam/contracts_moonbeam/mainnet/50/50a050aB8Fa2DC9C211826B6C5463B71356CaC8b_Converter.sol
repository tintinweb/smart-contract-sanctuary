/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-04-20
*/

// File: contracts/interfaces/tokens/IWETH.sol

pragma solidity 0.8.4;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File: contracts/Converter.sol

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;


library Converter {

    /**
    * @dev converts uint256 to a bytes(32) object
    */
    function _uintToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
    * @dev converts address to a bytes(32) object
    */
    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function ethToWeth(uint256 amount) external {
        bytes memory _data = abi.encodeWithSelector(IWETH.deposit.selector);
        (bool success, ) = address(0xAcc15dC74880C9944775448304B263D191c6077F).call{value:amount}(_data);
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function wethToEth(uint256 amount) external {
        IWETH(0xAcc15dC74880C9944775448304B263D191c6077F).withdraw(amount);
    }
}