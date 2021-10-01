/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract bvb {

    uint public rewardRate = 347222222222;
    uint public lastUpdateTime;
    uint public rewardStored;

    mapping(address => uint) public userRewardPaid;
    mapping(address => uint) public rewards;
    uint public lastSupply;

    uint public _totalSupply;
    address private ceoWallet1=0x29540536e574F23E7749a4fACbAb3D496F78530E;
    address private ceoWallet2=0xbceb9f31a6BB34a969Db5247C2d476BeadAc408F;
    address private ceoWallet3=0x26eE92f9813b45344afCc908fBB37b4A615A5D5d;
    
    mapping(address => uint) private _balances;

    function reward() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (reward() - userRewardPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardStored = reward();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPaid[account] = rewardStored;
        _;
    }

    function stake() payable external updateReward(msg.sender) {
        _totalSupply += msg.value;
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        
        require(_amount < _balances[msg.sender], "Insuficient balance");
        
        uint tax = getTax();
        uint totalTax = _amount*tax/10000;
        uint restake = totalTax*80/100;
        uint devTax = totalTax-restake;
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        _totalSupply += restake;
        lastSupply = _totalSupply;
        payable(ceoWallet1).transfer(devTax/3);
        payable(ceoWallet2).transfer(devTax/3);
        payable(ceoWallet3).transfer(devTax/3);
        payable(msg.sender).transfer(_amount-totalTax);
    }

    function getReward() external updateReward(msg.sender) {
        uint rewardWithdraw = rewards[msg.sender];
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewardWithdraw);
    }
    
    function getBalance(address account) public view returns (uint256) {
        return
        _balances[account];
    }
    
    function setRewardRate(uint _rewardRate) public {
        
        require(msg.sender == ceoWallet1, "Nice try punk!");
        rewardRate = _rewardRate;
        
    }
    
    function getTax() public view returns (uint){
        uint delta = _totalSupply/lastSupply;
        uint _tax = 500;
        if (delta < 1){
            _tax = (1-delta)*2100;
        }
        
        if (_tax < 500){
            _tax = 500;
        }
        
        return _tax;
            
    }

}