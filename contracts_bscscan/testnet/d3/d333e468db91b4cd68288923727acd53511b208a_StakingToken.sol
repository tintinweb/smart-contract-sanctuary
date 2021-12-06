// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract StakingToken is ERC20("SH33P Staking", "xSH33P"), TokensRecoverable {
    using SafeMath for uint256;

    IERC20 public immutable rooted;

    uint256 public totalStakers;
    uint256 public allTimeStaked;
    uint256 public allTimeUnstaked;

    struct AddressRecords {
        uint256 totalStaked;
        uint256 totalUnstaked;
    }

    mapping(address => AddressRecords) public addressRecord;

    event onStakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event onUnstakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);

    constructor(IERC20 _rooted) {
        rooted = _rooted;
    }

    function statsOf(address _user) public view returns (uint256 _totalStaked, uint256 _totalUnstaked) {
        return (
            addressRecord[_user].totalStaked, 
            addressRecord[_user].totalUnstaked
        );
    }

    function baseToStaked(uint256 _amount) public view returns (uint256 _stakedAmount) {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalRooted == 0) {
            return _amount;
        } else {
            return _amount.mul(totalShares).div(totalRooted);
        }
    }

    function stakedToBase(uint256 _amount) public view returns (uint256 _baseAmount) {
        uint256 totalShares = this.totalSupply();
        return _amount.mul(rooted.balanceOf(address(this))).div(totalShares);
    }

    // Stake rooted, get staking shares
    function stake(uint256 amount) public {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (addressRecord[msg.sender].totalStaked == 0) {
            totalStakers += 1;
        }

        if (totalShares == 0 || totalRooted == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 mintAmount = amount.mul(totalShares).div(totalRooted);
            _mint(msg.sender, mintAmount);
        }

        rooted.transferFrom(msg.sender, address(this), amount);

        addressRecord[msg.sender].totalStaked += amount;
        allTimeStaked += amount;

        emit onStakeTokens(msg.sender, amount, block.timestamp);
    }

    // Unstake shares, claim back rooted
    function unstake(uint256 share) public {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = share.mul(rooted.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, share);
        rooted.transfer(msg.sender, unstakeAmount);

        addressRecord[msg.sender].totalUnstaked += unstakeAmount;
        allTimeUnstaked += unstakeAmount;

        emit onUnstakeTokens(msg.sender, share, block.timestamp);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) {
        return address(token) != address(this) && address(token) != address(rooted); 
    }
}