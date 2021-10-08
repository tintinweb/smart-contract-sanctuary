// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract MockSyncBridge {
    event seedmonDeposited(uint256 tokenId, address depositor);
    event seedUploaded(uint256 amount, address uploader);

    function deposit(uint256 tokenId, address depositor) external {
        emit seedmonDeposited(tokenId, depositor);
    }
    function upload(uint256 amount, address uploader) external {
        emit seedUploaded(amount, uploader);
    }
}