//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./CoD.sol";

contract fiveMinutes is CoD {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    
    constructor() {
            
        _balances[msg.sender] = _totalSupply;
            
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    receive() external payable {}
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function startCODStake(
        uint256 _stakeAmt, 
        uint32 _stakeLength, 
        string calldata _description,
        bool insuranceTrigger) 
        snapshotTrigger 
        public 
        returns (bytes16, uint32)
    {
        require(_stakeLength >= minStakingDays && _stakeLength <= maxStakingDays, "5Minutes: stake duration not in allowed range.");
        require(_stakeAmt >= minStakingAmt, "5Minutes: stake amount too small!");
        
        (Stake memory newStake,
        bytes16 _stakeID,
        uint32 _startDay) = _createCODStake(msg.sender, _stakeAmt, _stakeLength, _description);
        
        if (insuranceTrigger) {
            require(_stakeLength >= 95, "5Minutes: minimum staking days for insurance is 95 days!");
            fiveMinutesInsurance[msg.sender] = true;
        }
        
        stakes[msg.sender][_stakeID] = newStake;
        _increaseStakeCount(msg.sender);
        _increaseGlobals(newStake.stakedAmt, newStake.stakeShares);
        _addShares(newStake.finalDay, newStake.stakeShares);
        
        emit stakeStarted(
            _stakeID,
            msg.sender,
            newStake.stakedAmt,
            newStake.stakeShares,
            newStake.startDay,
            newStake.stakingDays
        );
        
        return (_stakeID, _startDay);
    }
        
    function endStake(bytes16 _stakeID) snapshotTrigger public returns (uint256) {
        (Stake memory endedStake, uint256 penaltyAmt) = _endStake(msg.sender, _stakeID);
        _decreaseGlobals(endedStake.stakedAmt, endedStake.stakeShares);
        _removeShares(endedStake.finalDay, endedStake.stakeShares);
        if (penaltyAmt > 0) {
            totalPenalties[endedStake.closeDay] = totalPenalties[endedStake.closeDay].add(penaltyAmt);
        }
        _sharesPriceUpdate(
            endedStake.stakedAmt > penaltyAmt ? 
            endedStake.stakedAmt - penaltyAmt : 0,
            endedStake.rewardAmt + scrapes[msg.sender][_stakeID],
            endedStake.stakingDays,
            endedStake.stakeShares);
                
        emit stakeEnded(
            _stakeID,
            msg.sender,
            endedStake.stakedAmt,
            endedStake.stakeShares,
            endedStake.rewardAmt,
            endedStake.closeDay
            );
        return endedStake.rewardAmt;
    }

    function withdrawLockedETH(address payable recipient, uint256 amount) external onlyOwner() {
        require(amount <= address(this).balance, "5Minutes: amount should not exceed the contract balance");
        recipient.transfer(amount);
    }
    
    function disableInsuranceFee(address[] memory _addrs) external onlyOwner() {
        for (uint32 _addrIndex = 0; _addrIndex < _addrs.length; _addrIndex++) {
            fiveMinutesInsurance[_addrs[_addrIndex]] = false;
        }
    }
    
    function setStakingAddress(address newAddr) external onlyOwner() {
        require(
            address(stakingAddr) == address(0),
            "Staking address already set"
            );
            
        stakingAddr = Staking(newAddr);
    }
    
    function setNewRouterAddr(address router) external onlyOwner() {
        _router = router;
        
        emit newRouterAddress(router);
    }
    
    function sharksDumpStop(bool enable) external onlyOwner() {
        stopSharkDumps = enable;
    }
    
    function whalesDumpStop(bool enable) external onlyOwner() {
        stopWhaleDumps = enable;
    }
    
    function excludeAddr(address addr, bool isExempt) external onlyOwner() {
        _excludedAddrs[addr] = isExempt;
        
        emit Excluded (addr, isExempt);
    }
    
    function setMarketingWallet(address payable addr) external onlyOwner() {
        marketingWallet = addr;
    }
    
    function setInsuranceWallet(address payable addr) external onlyOwner() {
        insuranceWallet = addr;
    }
}