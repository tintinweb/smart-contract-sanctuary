// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/IZBOOFI_Staking.sol";

contract WellOfSoulsHelper {
    IZBOOFI_Staking private ZBOOFI_STAKING = IZBOOFI_Staking(0x14c323348e798da2dbBc79AcbCA34c7221E8148D);
    struct UserInfo {
        address userAddress;
        uint256 share;
        uint256 harvested;
    }

    function batchUserInfo(address[] memory userAddresses) external view returns(UserInfo[] memory) {
        UserInfo[] memory usersInfo = new UserInfo[](userAddresses.length);
        for (uint256 i = 0; i < userAddresses.length; i++) {
            UserInfo memory userInfo;
            userInfo.userAddress = userAddresses[i];
            userInfo.share = ZBOOFI_STAKING.shares(userAddresses[i]);
            userInfo.harvested = ZBOOFI_STAKING.harvested(userAddresses[i]);
            usersInfo[i] = userInfo;
        }
        return usersInfo;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IZBOOFI_Staking {
    function shares(address userAddress) external view returns(uint256);
    function harvested(address userAddress) external view returns(uint256);
    function depositTo(address to, uint256 amount) external;
    function depositToWithPermit(address to, uint256 amount, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function NUMBER_TOP_HARVESTERS() external view returns (uint256);
    function topHarvesters(uint256) external view returns (address);
}