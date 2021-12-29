// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Strategy.sol";

contract Strategy_Native is Strategy {
    address public earned0Address;
    address[] public earned0ToEarnedPath;

    constructor(
        address[] memory _addresses,
        address[] memory _tokenAddresses,
        bool _isSingleVault,
        uint256 _pid,
        address[] memory _earnedToNATIVEPath,
        address[] memory _earnedToToken0Path,
        address[] memory _earnedToToken1Path,
        address[] memory _token0ToEarnedPath,
        address[] memory _token1ToEarnedPath,
        address[] memory _earned0ToEarnedPath,
        uint256 _depositFeeFactor,
        uint256 _withdrawFeeFactor,
        uint256 _entranceFeeFactor
    ) public {
        nativeFarmAddress = _addresses[0];
        farmContractAddress = _addresses[1];
        govAddress = _addresses[2];
        uniRouterAddress = _addresses[3];
        buybackRouterAddress = _addresses[4];

        NATIVEAddress = _tokenAddresses[0];
        wftmAddress = _tokenAddresses[1];
        wantAddress = _tokenAddresses[2];
        earnedAddress = _tokenAddresses[3];
        earned0Address = _tokenAddresses[4];
        token0Address = _tokenAddresses[5];
        token1Address = _tokenAddresses[6];

        pid = _pid;
        isSingleVault = _isSingleVault;
        isAutoComp = false;

        earnedToNATIVEPath = _earnedToNATIVEPath;
        earnedToToken0Path = _earnedToToken0Path;
        earnedToToken1Path = _earnedToToken1Path;
        token0ToEarnedPath = _token0ToEarnedPath;
        token1ToEarnedPath = _token1ToEarnedPath;
        earned0ToEarnedPath = _earned0ToEarnedPath;

        depositFeeFactor = _depositFeeFactor;
        withdrawFeeFactor = _withdrawFeeFactor;
        entranceFeeFactor = _entranceFeeFactor;

        transferOwnership(nativeFarmAddress);
    }

    // not used
    function _farm() internal override {}
    // not used
    function _unfarm(uint256 _wantAmt) internal override {}
    // not used
    function _harvest() internal override {}
    // not used
    function earn() public override {}
    // not used
    function buyBack(uint256 _earnedAmt) internal override returns (uint256) {}
    // not used
    function distributeFees(uint256 _earnedAmt) internal override returns (uint256) {}
    // not used
    function convertDustToEarned() public override {}
}