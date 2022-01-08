// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMasterChefV2UserInfo {
    function userInfo(uint256 pid, address account) external view returns (uint256, uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IOpenDAOStaking is IERC20 {
    function getSOSPool() external view returns(uint256);
}

contract OpenDAOCombined {
    IMasterChefV2UserInfo public constant _chefV2 = IMasterChefV2UserInfo(0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d);
    IERC20 public constant _sosWETHPair = IERC20(0xB84C45174Bfc6b8F3EaeCBae11deE63114f5c1b2);
    IERC20 public constant _sosToken = IERC20(0x3b484b82567a09e2588A13D54D032153f0c0aEe0);
    IOpenDAOStaking public constant _vesosToken = IOpenDAOStaking(0xEDd27C961CE6f79afC16Fd287d934eE31a90D7D1);

    uint256 private constant SOS_WETH_POOL_ID = 45;

    function balanceOf(address account) external view returns (uint256) {
        return getBalance(account, _chefV2, _sosToken, _sosWETHPair, _vesosToken);
    }

    function getBalance(address account, IMasterChefV2UserInfo chefV2, IERC20 sosToken, IERC20 sosWETHPair, IOpenDAOStaking vesosToken) public view returns (uint256) {
        uint256 sosBalance = sosToken.balanceOf(account);

        // veSOS Balance
        uint256 _stakedSOS = 0;
        {
            uint256 totalSOS = vesosToken.getSOSPool();
            uint256 totalShares = vesosToken.totalSupply();
            uint256 _share = vesosToken.balanceOf(account);
            if (totalShares != 0) {
                _stakedSOS = _share * totalSOS / totalShares;
            }
        }

        // LP Provider

        (uint256 lpStakedBalance, ) = chefV2.userInfo(SOS_WETH_POOL_ID, account);
        uint256 lpUnstaked = sosWETHPair.balanceOf(account);
        uint256 lpBalance = lpStakedBalance + lpUnstaked;

        uint256 lpAdjustedBalance = lpBalance * sosToken.balanceOf(address(sosWETHPair)) / sosWETHPair.totalSupply() * 2;

        // Sum them up!

        uint256 combinedSOSBalance = sosBalance + lpAdjustedBalance + _stakedSOS;
        return combinedSOSBalance;
    }

    function totalSupply() external view returns (uint256) {
        return getSupply(_sosToken, _sosWETHPair);
    }

    function getSupply(IERC20 sosToken, IERC20 sosWETHPair) public view returns (uint256) {
        return sosToken.totalSupply() + sosToken.balanceOf(address(sosWETHPair));
    }

    function name() external pure returns (string memory) { return "cSOS"; }
    function symbol() external pure returns (string memory) { return "OpenDAOCombined"; }
    function decimals() external view returns (uint8) { return _sosToken.decimals(); }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }
}