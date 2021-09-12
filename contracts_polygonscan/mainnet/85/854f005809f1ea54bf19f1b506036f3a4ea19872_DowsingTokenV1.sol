// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/

import "./IPoolV1.sol";
import "./PoolDowserV1.sol";
import "./IERC20Metadata.sol";

contract DowsingTokenV1 {
    
    IPoolV1 public pool;
    PoolDowserV1 public dowser;
    bool public forPending;
    mapping (address => uint) internal lastKnownBalance;
    
    function initialize(IPoolV1 _pool, bool _forPending) external {
        require(address(dowser) == address(0));
        dowser = PoolDowserV1(msg.sender);
        pool = _pool;
        forPending = _forPending;
    }
    
    function name() external view returns (string memory _name) {
        if (forPending) return dowser.getNamePending(pool);
        else return dowser.getNameStaked(pool);
    }
    function symbol() external view returns (string memory _symbol) {
        if (forPending) return dowser.getSymbolPending(pool);
        else return dowser.getSymbolStaked(pool);
    }
    function decimals() external view returns (uint8 _decimals) {
        IERC20 token = forPending ? pool.REWARD_TOKEN() : pool.STAKE_TOKEN();
        return IERC20Metadata(address(token)).decimals();
    }
    function totalSupply() public view returns (uint256) {
        if (forPending) {
            uint totalReward = (pool.bonusEndBlock() - pool.startBlock()) * pool.rewardPerBlock();
            uint rewardBalance = pool.rewardBalance();
            return rewardBalance < totalReward ? rewardBalance : totalReward;
        }
        else return pool.totalStaked();
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        if (forPending) return pool.pendingReward(account);
        else (balance, ) = pool.userInfo(account);
    }

    function transfer(address recipient, uint256) external returns (bool success) {
        update(msg.sender);
        update(recipient);
        return false;
    }

    function approve(address spender, uint256) external returns (bool success) {
        update(msg.sender);
        update(spender);
        return false;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256
    ) external returns (bool success) {
        update(recipient);
        update(sender);
        update(msg.sender);
        return false;
    }
    
    function update(address account) public {
        
        uint oldBalance = lastKnownBalance[account];
        uint newBalance = balanceOf(account);
        lastKnownBalance[account] = newBalance;
        
        if (newBalance < oldBalance) emit Transfer(account, address(0), oldBalance - newBalance);
        else if (newBalance > oldBalance) emit Transfer(address(0), account, newBalance - oldBalance);
    }
    function update(address[] calldata accounts) external {
        for (uint i; i < accounts.length; i++) {
            update(accounts[i]);
        }
    }
    
    function destroy() external {
        require(msg.sender == address(dowser) || msg.sender == dowser.owner());
        selfdestruct(payable(dowser.owner()));
    }
    
    function sweepToken(IERC20 token) external {
        require(msg.sender == dowser.owner());
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }    
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
}