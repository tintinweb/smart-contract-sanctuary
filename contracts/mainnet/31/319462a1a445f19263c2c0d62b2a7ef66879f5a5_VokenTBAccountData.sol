/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

/**
 * @title Interface of VokenTB.
 */
interface IVokenTB {
    function address2voken(address account) external view returns (uint160);
    function balanceOf(address account) external view returns (uint256);
    function vestingOf(address account) external view returns (uint256);
    function availableOf(address account) external view returns (uint256);
    function isBank(address account) external view returns (bool);
    function referrer(address account) external view returns (address payable);
}

/**
 * @dev VokenTB Account Data
 */
contract VokenTBAccountData {
    IVokenTB private immutable VOKEN_TB = IVokenTB(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);

    function query(address account)
        public
        view
        returns (
            uint160 voken,
            uint256 balance,
            uint256 vesting,
            uint256 available,
            bool isBank,
            address payable referrer
        )
    {
        voken = VOKEN_TB.address2voken(account);
        balance = VOKEN_TB.balanceOf(account);
        vesting = VOKEN_TB.vestingOf(account);
        available = VOKEN_TB.availableOf(account);
        isBank = VOKEN_TB.isBank(account);
        referrer = VOKEN_TB.referrer(account);
    }
}