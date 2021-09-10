// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract TeamSplitter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public admin;

    struct TeamMember {
        address wallet;
        uint256 baseBalance;
        uint256 tokenBalance;
    }

    mapping(uint256 => TeamMember) _teamMember;

    IERC20 token;

    event onUpdateAddress(address indexed _caller, address indexed _newAddress, uint256 _timestamp);
    event onPushPayment(address indexed _recipient, uint256 _amount, uint256 _timestamp);
    event onDistribute(address indexed _caller, uint256 _amount, uint256 _timestamp);

    constructor(address _token) {
        token = IERC20(_token);

        _teamMember[1].wallet = 0xfa51D924eEe28bF07e63eA009b0843353258ca63; // DonFunction (Main Dev)
        _teamMember[2].wallet = 0x4C85973AA4D667497FEd1556eE3b3A2D27aE8224; // KingCozz (SideKick Devs)
        _teamMember[3].wallet = 0x4E039e818AE3c48f84cfc3C1E6DC1963f4C98A5a; // MadFeli
        _teamMember[4].wallet = 0xAAa5aB102f3d9e169667F9aa7e2B8C3441582904; // CryptoKnightsIbi
        _teamMember[5].wallet = 0x673fB4196FE931c1b6cC1d6e1D958f0ddEf60d65; // BankRoller
        _teamMember[6].wallet = 0xf64ba078E6732B6Ba29b398B4F04759b43cc9911; // Michal845
        _teamMember[7].wallet = 0x03416C0440f80c86B374DD59E7FCeB2f58d3b43C; // Roller4Life
        _teamMember[8].wallet = 0xa2539aedE99bC5c88b48AFDd59426e70BB219bCF; // CryptoBuddy
        _teamMember[9].wallet = 0x495306d588cD8194beb1460328E20A36DD6d9d9d; // DabsGalore
    }

    receive() external payable {

    }

    function distribute() public returns (bool _success) {
        uint256 base = address(this).balance;

        _teamMember[1].baseBalance += base.mul(1000).div(9000);
        _teamMember[2].baseBalance += base.mul(1000).div(9000);
        _teamMember[3].baseBalance += base.mul(1000).div(9000);
        _teamMember[4].baseBalance += base.mul(1000).div(9000);
        _teamMember[5].baseBalance += base.mul(1000).div(9000);
        _teamMember[6].baseBalance += base.mul(1000).div(9000);
        _teamMember[7].baseBalance += base.mul(1000).div(9000);
        _teamMember[8].baseBalance += base.mul(1000).div(9000);
        _teamMember[9].baseBalance += base.mul(1000).div(9000);

        emit onPushPayment(msg.sender, base, block.timestamp);
        return true;
    }

    function distributeTokens() public returns (bool _success) {
        uint256 tokens = token.balanceOf(address(this));

        _teamMember[1].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[2].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[3].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[4].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[5].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[6].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[7].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[8].tokenBalance += tokens.mul(1000).div(9000);
        _teamMember[9].tokenBalance += tokens.mul(1000).div(9000);

        emit onPushPayment(msg.sender, tokens, block.timestamp);
        return true;
    }

    function updateAddress(uint256 _teamMemberId, address _newAddress) public returns (bool _success) {
        address _oldAddress = _teamMember[_teamMemberId].wallet;
        require(msg.sender == _oldAddress, "CANNOT_CHANGE_FROM_OTHER_WALLET");

        _teamMember[_teamMemberId].wallet = _newAddress;

        emit onUpdateAddress(_oldAddress, _newAddress, block.timestamp);
        return true;
    }

    function pushTokenPayment(uint256 _teamMemberId) public returns (bool _success) {
        uint256 _entitlement = _teamMember[_teamMemberId].tokenBalance;
        require(_entitlement > 0, "NO_BALANCE");

        uint256 _payout = _entitlement;
        _teamMember[_teamMemberId].tokenBalance = 0;

        address _recipient = _teamMember[_teamMemberId].wallet;
        token.transfer(_recipient, _payout);

        emit onPushPayment(_recipient, _payout, block.timestamp);
        return true;
    }

    function pushPayment(uint256 _teamMemberId) public returns (bool _success) {
        uint256 _entitlement = _teamMember[_teamMemberId].tokenBalance;
        require(_entitlement > 0, "NO_BALANCE");

        uint256 _payout = _entitlement;
        _teamMember[_teamMemberId].baseBalance = 0;

        address _recipient = _teamMember[_teamMemberId].wallet;
        token.transfer(_recipient, _payout);

        emit onPushPayment(_recipient, _payout, block.timestamp);
        return true;
    }
}