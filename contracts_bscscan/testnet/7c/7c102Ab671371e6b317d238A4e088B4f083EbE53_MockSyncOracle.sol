// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract MockSyncOracle {
    event withdrawSeedmonRequested(address requester, uint256 requestId, address withdrawer, uint256 tokenId, uint256 provideGas);
    event downloadSeedRequested(address requester, uint256 requestId, address downloader, uint256 amount, uint256 provideGas);

    function withdraw(address requester, uint256 requestId, address withdrawer, uint256 tokenId, uint256 provideGas) external {
        emit withdrawSeedmonRequested(requester, requestId, withdrawer, tokenId, provideGas);
    }
    function download(address requester, uint256 requestId, address downloader, uint256 amount, uint256 provideGas) external {
        emit downloadSeedRequested(requester, requestId, downloader, amount, provideGas);
    }
}