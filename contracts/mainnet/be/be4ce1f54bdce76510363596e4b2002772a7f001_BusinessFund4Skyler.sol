// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibIVesting.sol";
import "LibIVokenTB.sol";
import "LibAuthPause.sol";
import "LibAuthProxy.sol";
import "SkylerVestingPermille1.sol";


contract BusinessFund4Skyler is IVesting, AuthPause, AuthProxy, WithVestingPermille {
    using SafeMath for uint256;

    uint256 private immutable CREDIT = 1_000_000e9;  // credit: 1 million
    uint256 private immutable TOP = 50_000e9;
    uint256 private _vokenIssued;
    IVokenTB private immutable VOKEN_TB = IVokenTB(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);
    mapping (address => uint256) private _minted;

    event Distribute(address indexed account, uint256 amount);

    receive() external payable {}

    function status(address account)
        public
        view
        returns (
            uint256 credit,
            uint256 issued,
            
            uint256 balance,
            uint256 minted,
            uint256 vesting
        )
    {
        credit = CREDIT.sub(_vokenIssued);
        issued = _vokenIssued;
        
        balance = VOKEN_TB.balanceOf(account);
        minted = _minted[account];
        vesting = vestingOf(account);
    }

    function vestingOf(address account)
        public
        override
        view
        returns (uint256 vesting)
    {
        vesting = vesting.add(_getVestingAmountForIssued(_minted[account]));
    }


    function distribute(address account, uint256 amount)
        public
        onlyProxy
        onlyNotPaused
        returns (bool)
    {
        require(_minted[account] == 0, "Already minted before");
        require(amount <= TOP, "Mint greater than 50k");

        _vokenIssued = _vokenIssued.add(amount);
        require(_vokenIssued <= CREDIT, "BusinessFund: credit exceeded");

        _minted[account] = _minted[account].add(amount);

        emit Distribute(account, amount);

        return VOKEN_TB.mintWithVesting(account, amount, address(this));
    }
}