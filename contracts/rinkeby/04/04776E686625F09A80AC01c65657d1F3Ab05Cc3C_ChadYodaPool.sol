// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./util.sol";

contract ChadYodaPool is Context {
    mapping (uint => address) private _tokenHolders;
    mapping (address => bool) private _isHolder;

    bool private _inRewardDistribution = false;

    address private _tokenOwner;
    address private _tokenContract;

    uint private _holdersCount = 0;

    event DistributeRewards(address winner, uint256 amount);

    modifier onlyOwner() {
        require(_tokenContract == _msgSender() || _tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address tokenContract, address tokenOwner) {
        _tokenContract = tokenContract;
        _tokenOwner    = tokenOwner;
    }

    function setOwner(address tokenContract, address tokenOwner) external onlyOwner {
        _tokenContract = tokenContract;
        _tokenOwner    = tokenOwner;
    }

    function addHolder(address h) public onlyOwner {
        if ( !_isHolder[h] 
            && h != 0x000000000000000000000000000000000000dEaD 
            && h != _tokenOwner
            && h != _tokenContract
            && h != address(this)
        ) {
            _tokenHolders[_holdersCount+1] = h;
            _isHolder[h] = true;
            _holdersCount++;
        }
    }

    function addHolders(address[] calldata hs) external onlyOwner {
        for ( uint i = 0; i < hs.length; i++ ) {
            addHolder(hs[i]);
        }
    }

    function getHolder(uint i) external view onlyOwner returns(address) {
        return _tokenHolders[i];
    }

    function getHoldersCount() external view onlyOwner returns(uint) {
        return _holdersCount;
    }

    function isIncluded(address a) public view onlyOwner returns(bool) {
        return _isHolder[a];
    }

    function distributeRewardsManual(
        uint index1,
        uint index2,
        uint index3,
        uint index4,
        uint index5,
        uint index6,
        uint index7,
        uint index8,
        uint index9,
        uint index10,
        uint256 amount
    ) external onlyOwner {
        if ( _inRewardDistribution ) { return; }
        if ( _holdersCount < 10 ) { return; }
        if ( _tokenContract == address(0) ) { return; }

        _inRewardDistribution = true;

        IBEP20 goldfishToken = IBEP20(_tokenContract);

        uint256 rewardAmount;
        
        if (amount != 0) {
            rewardAmount = amount;
        } else {
            rewardAmount = goldfishToken.balanceOf(address(this)) / 10;
        }

        sendReward(goldfishToken, index1,  rewardAmount);
        sendReward(goldfishToken, index2,  rewardAmount);
        sendReward(goldfishToken, index3,  rewardAmount);
        sendReward(goldfishToken, index4,  rewardAmount);
        sendReward(goldfishToken, index5,  rewardAmount);
        sendReward(goldfishToken, index6,  rewardAmount);
        sendReward(goldfishToken, index7,  rewardAmount);
        sendReward(goldfishToken, index8,  rewardAmount);
        sendReward(goldfishToken, index9,  rewardAmount);
        sendReward(goldfishToken, index10, rewardAmount);

        _inRewardDistribution = false;
    }

    function sendReward(IBEP20 token, uint index, uint256 rewardAmount) private {
        token.transfer(_tokenHolders[index], rewardAmount);
        emit DistributeRewards(_tokenHolders[index], rewardAmount);
    }
}