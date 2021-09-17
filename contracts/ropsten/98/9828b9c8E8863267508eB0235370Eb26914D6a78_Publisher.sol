// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./IPublish.sol";

contract Publisher is IPublish {
    /**
     * @param publications Array of Publication structs to publish
     */
    function publish(Publication[] calldata publications) external override {
        require(publications.length < 100, "gas consumption is high");
        for (uint256 i = 0; i < publications.length; i++) {
            emit DSNPBatchPublication(
                publications[i].announcementType,
                publications[i].fileHash,
                publications[i].fileUrl
            );
        }
    }
}