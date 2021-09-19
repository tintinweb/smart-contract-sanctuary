//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Dependencies.sol";
import "./ERC20.sol";
import "./uniswapInterfaces.sol";

contract fiveMinutes is Context, Ownable, IERC20, IERC20Metadata, Additions {
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    
    mapping(address => uint256) public _balances;
    mapping (address => bool) public _excludedAddrs;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping (address => uint256) public saleRecord;
    mapping(uint32 => SnapShot) public snapshots;
    
    uint256 lastPumpDay = launchTime + 1296*10**3;
    
    address public _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address payable private marketingWallet = 
        payable(address(0xe00386a30c75e340D6bAF3636E91691AE70b22F3));
        
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WETH());
    
    uint8 private constant _sellTaxPercent = 10;
    uint8 private constant _buyTaxPercent = 2;
    uint256 private minSwapAmt = 5*10**9;
    uint256 private pumperETHBalance;

    Staking public stakingAddr;
    
    string internal _name;
    string internal _symbol;
    
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    
    struct SnapShot {
        uint256 totalShares;
        uint256 inflationAmt;
        uint256 scheduledToEnd;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_) {
            _name = name_;
            _symbol = symbol_;
            _decimals = decimals_;
            _totalSupply = totalSupply_ * 10 ** _decimals;
            
            _balances[msg.sender] = _totalSupply;
            
            emit Transfer(address(0), _msgSender(), _totalSupply);
    }
        
    bool stopSharkDumps = true;
    bool stopWhaleDumps = true;

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    modifier snapshotTrigger() {
        _dailySnapshotPoint(_currrent5MinutesDay());
        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero.");
        
        uint256 _currentTime = block.timestamp;
        uint256 _multiplier = _current5MinutesHour();
        uint256 buyTime = buyTimeStamp + (_multiplier * secsInHour);
        uint256 hourTimeStamp = launchTime + (_multiplier * secsInHour);
        uint256 senderBalance = _balances[sender];
        uint256 sharkLimit = (totalSupply()) / (10**3);
        uint256 whaleLimit = (totalSupply()) * 5 /(10**3);
        
        if(_currentTime <= buyTime && _currentTime > hourTimeStamp){
            require(recipient != address(uniswapV2Pair) || recipient != address(uniswapV2Router), "5Minutes: it's pump time! Buy more.");
        }

        _beforeTokenTransfer(sender, recipient, amount);
        
        if(stopSharkDumps || stopWhaleDumps) {
            
            if(recipient == address(uniswapV2Pair) || recipient == address(uniswapV2Router)) {

                if (senderBalance >= sharkLimit && senderBalance < whaleLimit) {
                    require(amount <= senderBalance / (3), "5Minutes: max sell for a shark is 33% per 24 hours");
                    require(_currentTime - saleRecord[sender] > 1 days, "5Minutes: you need to wait for 24 hours before selling again");
                }
                
                else if (senderBalance >= whaleLimit) {
                    require(amount <= senderBalance / (5), "5Minutes: max sell for a whale is 20% per 24 hours");
                    require(_currentTime - saleRecord[sender] > 1 days, "5Minutes: you have to wait for 24 hours before selling again");
                }
            }
        }

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        {
            if (recipient == address(0) ||
            (sender != _router &&
            recipient != _router) ||
            _excludedAddrs[sender])
            {
                _taxlessTransfer(sender, recipient, amount);
            }
            else {
                _taxedTransfer(sender, recipient, amount);
            }
        }
        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    
    receive() external payable {}

    function _taxedTransfer(address sender, address recipient, uint256 amount) private {
        _swap(sender, recipient);
        uint256 sellTax = (amount * _sellTaxPercent) / 100;
        uint256 buyTax = (amount * _buyTaxPercent) / 100;
        
        if (sender == address(uniswapV2Pair) || sender == address(uniswapV2Router)) {
            _balances[address(this)] += buyTax;
            _balances[sender] -= amount;
            _balances[recipient] += amount - buyTax;
        }
        
        else {
            _balances[address(this)] += sellTax;
            _balances[sender] -= amount;
            _balances[recipient] += amount - sellTax;
        }
    }
    
    function _taxlessTransfer(address sender, address recipient, uint256 amount) private {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
    }
    
    function _swap(address sender, address recipient) private {
        uint256 contractBalance = _balances[address(this)];
        
        bool distributeTax = contractBalance >= minSwapAmt;
        contractBalance = minSwapAmt;
        uint256 _currentTime = block.timestamp;
        
        
        if (
            distributeTax &&
            sender != _router &&
            !(sender == address(this) && recipient == _router)
            ) 
            {
                uint256 pumperShare =  (33 * contractBalance) / 100 ;
                uint256 stakingShare = (33 * contractBalance) / 100;
                uint256 marketingShare = (12 * contractBalance) / 100;
                uint256 liquidityShare = (22 * contractBalance) / 100;
                uint256 swappedTax = stakingShare + marketingShare + (liquidityShare / 2) + pumperShare;
        
                swapTokensForETH(swappedTax);
                
                uint256 ETHBalance = address(this).balance - pumperETHBalance;
                
                uint256 stakeETHShare = (ETHBalance*4706) / 10000;
                uint256 marketingETHShare = (ETHBalance*1176) / 10000;
                uint256 liquidityETHShare = (ETHBalance*1765) / 10000;
                pumperETHBalance += (ETHBalance*2353) / 10000;
                
                if (pumperETHBalance >= 10 ether && _currentTime >= lastPumpDay) {
                    swapETHForTokens(pumperETHBalance);
                        
                    pumperETHBalance = 0;
                }
                
                marketingWallet.transfer(marketingETHShare);
                stakingAddr.distribute{value: stakeETHShare}();
                addLiquidity(liquidityShare / 2, liquidityETHShare);
                
                emit Swap(contractBalance, ETHBalance);
            }
    }
    
    function addLiquidity(uint256 tokenAmt, uint256 ETHAmt) private {
        _approve(address(this), _router, tokenAmt);
        
        uniswapV2Router.addLiquidityETH{value: ETHAmt}(
            address(this),
            tokenAmt,
            0,
            0,
            address(this),
            block.timestamp
        );
    } 
    
    function swapTokensForETH(uint256 tokenAmt) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), _router, tokenAmt);
        
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmt,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapETHForTokens(uint256 ETHAmt) private {
        address[] memory _path = new address[] (2);
        _path[0] = uniswapV2Router.WETH();
        _path[1] = address(this);
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ETHAmt} (
            0,
            _path,
            address(0),
            lastPumpDay + 1296*10**3
        );
    }
    
    function withdrawLockedETH(address payable recipient, uint256 amount) external onlyOwner() {
        require(recipient != address(0), "5Minutes: cannot withdraw to the zero address");
        require(amount <= address(this).balance, "5Minutes: amount should not exceed the contract balance");
        recipient.transfer(amount);
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
    
    function manualDailySnapshot()
        external
    {
        _dailySnapshotPoint(_currrent5MinutesDay());
    }

    function manualDailySnapshotPoint(
        uint32 _updateDay
    )
        external
    {
        require(
            _updateDay > 0 &&
            _updateDay < _currrent5MinutesDay(),
            '5Minutes: day has not reached yet.'
        );

        require(
            _updateDay > codStats.fiveMinutesDay,
            '5Minutes: snapshot already taken for that day'
        );

        _dailySnapshotPoint(_updateDay);
    }

    function _dailySnapshotPoint(
        uint32 _updateDay
    )
        private
    {
        uint256 totalStakedToday = codStats.totalStakedAmt;
        uint256 scheduledToEndToday;

        for (uint32 _day = codStats.fiveMinutesDay; _day < _updateDay; _day++) {

            scheduledToEndToday = scheduledToEnd[_day] + snapshots[_day - 1].scheduledToEnd;
            SnapShot memory snapshot = snapshots[_day];
            snapshot.scheduledToEnd = scheduledToEndToday;

            snapshot.totalShares =
                codStats.totalShares > scheduledToEndToday ?
                codStats.totalShares - scheduledToEndToday : 0;
            
            snapshot.inflationAmt = snapshot.totalShares
                .mul(precisionRate)
                .div(
                    _inflationAmt(
                        totalStakedToday,
                        totalSupply(),
                        totalPenalties[_day]
                        )
                    );

            snapshots[_day] = snapshot;

            codStats.fiveMinutesDay++;

        }
    }
    
    function _inflationAmt(uint256 _staked, uint256 _supply, uint256 _penalties) private pure returns (uint256) {
        return (_staked + _supply) * inflationDivisor / inflationRate + _penalties;
    }
    
    function startCODStake(
        uint256 _stakeAmt, 
        uint32 _stakeLength, 
        string calldata _description) 
        snapshotTrigger 
        public returns (bytes16, uint32)
    {
        require(_stakeLength >= minStakingDays && _stakeLength <= maxStakingDays, "5Minutes: stake duration not in allowed range.");
        require(_stakeAmt >= minStakingAmt, "5Minutes: stake amount too small!");
        
        (stake memory newStake,
        bytes16 stakeID,
        uint32 _startDay)
        = 
        _createCODStake(msg.sender, _stakeAmt, _stakeLength, _description);
        
        stakes[msg.sender][stakeID] = newStake;
        _increaseStakeCount(msg.sender);
        _increaseGlobals(newStake.stakedAmt, newStake.stakeShares);
        
        emit stakeStarted(
            stakeID,
            msg.sender,
            newStake.stakedAmt,
            newStake.stakeShares,
            newStake.startDay,
            newStake.stakingDays
        );
        
        return (stakeID, _startDay);
    }
    
    function _createCODStake(
        address _staker,
        uint256 _stakeAmt,
        uint32 _stakeLength,
        string memory _description)
    private
    returns (
        stake memory _newCODStake,
        bytes16 _stakeID,
        uint32 _startDay
    ) 
    {
        _burn(_staker, _stakeAmt);
        total5MinutesActiveStakes[_staker] = total5MinutesActiveStakes[_staker].add(_stakeAmt);
            
        _startDay = _next5MinutesDay();
        _stakeID = generateStakeID(_staker);
        _newCODStake.stakingDays = _stakeLength;
        _newCODStake.startDay = _startDay;
        _newCODStake.finalDay = _startDay + _stakeLength;
        _newCODStake.details = _description;
        _newCODStake.isActive = true;
        _newCODStake.stakedAmt = _stakeAmt;
        _newCODStake.stakeShares = _stakeShares(_stakeAmt, _stakeLength, codStats.sharePrice);
    }
        
    function endStake(bytes16 _stakeID) snapshotTrigger external returns (uint256) {
        (stake memory endedStake, uint256 penaltyAmt) = _endStake(msg.sender, _stakeID);
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
        
    function _endStake(address _staker, bytes16 _stakeID) private returns (stake storage _stake, uint256 penaltyAmt){
        require(stakes[_staker][_stakeID].isActive, "5Minutes: not an active stake");
            
        _stake = stakes[_staker][_stakeID];
        _stake.closeDay = _currrent5MinutesDay();
        _stake.rewardAmt = _calcRewardAmt(_stake);
        penaltyAmt = _calcPenaltyAmt(_stake);
        _stake.penaltyAmt = penaltyAmt;
        _stake.isActive = false;
            
        total5MinutesActiveStakes[_staker] = 
            total5MinutesActiveStakes[_staker] >= _stake.stakedAmt ?
            total5MinutesActiveStakes[_staker].sub(_stake.stakedAmt) : 0;
        //Principal _ penalty    
        _mint(
            _staker, 
            _stake.stakedAmt > penaltyAmt ?
            _stake.stakedAmt - penaltyAmt : 0);
        //Reward    
        _mint(_staker, _stake.rewardAmt);
    }

    function moveStake(bytes16 _stakeID, address to, uint256 amount) snapshotTrigger external {
        require(stakes[msg.sender][_stakeID].isActive, "5Minutes: not an active stake");
        require(total5MinutesActiveStakes[msg.sender] >= amount, "5Minutes: amount surpasses total stake.");
        require(amount >= minStakingAmt, "5Minutes: amount cannot be less than minimum allowed.");
        require(stakes[msg.sender][_stakeID].scrapeDay == 0, "5Minutes: not possible if scraped interest.");
        require(_notContract(to), "5Minutes: receiver not an address");
        require(to != msg.sender, "5Minutes: cannot send to your own address");
            
        stake memory oldStake = stakes[msg.sender][_stakeID];
        stake memory newStake;
            
        newStake.stakeShares = 
        _stakeShares(
            amount, 
            oldStake.stakingDays, 
            _getNewSharePrice(amount, _calcRewardAmt(oldStake), oldStake.stakeShares, oldStake.stakingDays)
        );
        newStake.stakedAmt = amount;
        newStake.startDay = oldStake.startDay;
        newStake.stakingDays = oldStake.stakingDays;
        newStake.finalDay = oldStake.finalDay;
        newStake.closeDay = oldStake.closeDay;
        newStake.scrapeDay = oldStake.scrapeDay;
        newStake.isActive = oldStake.isActive;
        newStake.isSplit = oldStake.isSplit;
        newStake.details = oldStake.details;
            
        stake storage stakeStat = stakes[msg.sender][_stakeID];
        stakeStat.closeDay = _currrent5MinutesDay();
        stakeStat.details = unicode'MOVED TO ANOTHER ADDRESS';
        stakeStat.isActive = false;
            
        total5MinutesActiveStakes[msg.sender] = total5MinutesActiveStakes[msg.sender] > amount ?
            total5MinutesActiveStakes[msg.sender].sub(amount) : 0;
        total5MinutesActiveStakes[to] = total5MinutesActiveStakes[to].add(amount);
            
        bytes16 _newStakeID = generateStakeID(to);
        stakes[to][_newStakeID] = newStake;
        _increaseStakeCount(to);
    }
        
    function renameStake(bytes16 _stakeID, string calldata _desc) snapshotTrigger external {
        require(stakes[msg.sender][_stakeID].isActive, "5Minutes: not an active stake.");
        stake storage _stake = stakes[msg.sender][_stakeID];
        _stake.details = _desc;
    }
        
    function splitStake(bytes16 _stakeID, uint8 divisor) snapshotTrigger external {
        require(stakes[msg.sender][_stakeID].isActive, "5Minutes: not an active stake.");
        require(stakes[msg.sender][_stakeID].isSplit == false, "5Minutes: already split.");
        require(stakes[msg.sender][_stakeID].scrapeDay == 0, "5Minutes: not possible if scraped interest.");
        require(stakes[msg.sender][_stakeID].stakedAmt >= 10*minStakingAmt, "5Minutes: too small to split.");
        require(divisor <= 10, "5Minutes: cannot split to less than a tenth of stake.");
            
        stake memory oldStake = stakes[msg.sender][_stakeID];
        stake memory newStake;
            
        newStake.stakeShares = oldStake.stakeShares / divisor;
        newStake.stakedAmt = oldStake.stakedAmt / divisor;
        newStake.startDay = oldStake.startDay;
        newStake.stakingDays = oldStake.stakingDays;
        newStake.finalDay = oldStake.finalDay;
        newStake.closeDay = oldStake.closeDay;
        newStake.isActive = true;
        newStake.isSplit = true;
        newStake.details = oldStake.details;
            
        stake storage _stake = stakes[msg.sender][_stakeID];
        _stake.isSplit = true;
        _stake.stakeShares = _stake.stakeShares - newStake.stakeShares;
        _stake.stakedAmt = _stake.stakedAmt - newStake.stakedAmt;
            
        bytes16 _newStakeID = generateStakeID(msg.sender);
        stakes[msg.sender][_newStakeID] = newStake;
        _increaseStakeCount(msg.sender);
    }
        
    function scrapeInterest(
        bytes16 _stakeID, 
        uint32 _scrapeDay) 
        snapshotTrigger 
    external 
    returns(
            uint32 scrapeDay,
            uint256 scrapeAmt,
            uint32 remDays,
            uint256 stakerPenalty)
    {
        require(stakes[msg.sender][_stakeID].isActive, "5Minutes: not an active stake");
        require(stakes[msg.sender][_stakeID].finalDay > _currrent5MinutesDay(), "5Minutes: stake is mature.");
        require(stakes[msg.sender][_stakeID].stakingDays > 2, "5Minutes: stake too short.");
            
        stake memory _stake = stakes[msg.sender][_stakeID];
                
        scrapeDay = _scrapeDay > 0 ?
            _startDay(_stake).add(_scrapeDay) :
            _dayCalculation(_stake);
                
        scrapeDay = scrapeDay > _currrent5MinutesDay() ?
            _dayCalculation(_stake) :
            scrapeDay;
                    
        scrapeAmt = _loopRewardAmt(
            _stake.stakeShares,
            _startDay(_stake),
            scrapeDay);
                    
        remDays = _daysLeft(_stake);
            
        stakerPenalty = _stakeShares(scrapeAmt, remDays, codStats.sharePrice);
            
        uint256 _sharesTemp = _stake.stakeShares;
                
        _stake.stakeShares = _stake.stakeShares > stakerPenalty ?
            _stake.stakeShares.sub(stakerPenalty) : 0;
                    
        _removeShares(
            _stake.finalDay,
            _sharesTemp > stakerPenalty ? stakerPenalty : _sharesTemp);
                    
        _decreaseGlobals(0, _sharesTemp > stakerPenalty ? stakerPenalty : _sharesTemp);
                
        _sharesPriceUpdate(
            _stake.stakedAmt,
            scrapeAmt,
            _stake.stakingDays,
            _stake.stakeShares);
                    
        scrapes[msg.sender][_stakeID] = scrapes[msg.sender][_stakeID].add(scrapeAmt);
                
        _stake.scrapeDay = scrapeDay;
        stakes[msg.sender][_stakeID] = _stake;
                
        _mint(msg.sender, scrapeAmt);
                
        emit interestScraped(
            _stakeID,
            msg.sender,
            scrapeAmt,
            scrapeDay,
            stakerPenalty,
            _currrent5MinutesDay()
        );
    }
        
    function _addShares(uint32 _finalDay, uint256 _shares) internal {
        scheduledToEnd[_finalDay] = scheduledToEnd[_finalDay].add(_shares);
    }
        
    function _removeShares(uint32 _finalDay, uint256 _shares) internal {
        if (_notPast(_finalDay)) {
            scheduledToEnd[_finalDay] = scheduledToEnd[_finalDay] > _shares ?
            scheduledToEnd[_finalDay] - _shares : 0;
        }
        
        else {
            uint32 _lastDay = _previous5MinutesDay();
            snapshots[_lastDay].scheduledToEnd = 
            snapshots[_lastDay].scheduledToEnd > _shares ?
            snapshots[_lastDay].scheduledToEnd - _shares : 0;
        }
    }
        
    function _sharesPriceUpdate(
        uint256 _stakedAmt,
        uint256 _rewardAmt,
        uint32 _stakingDays,
        uint256 _stakesShares
        )
        private
    {
        if (_stakesShares > 0 && _currrent5MinutesDay() > 1) {
                
            uint256 _newSharePrice = _getNewSharePrice(
                _stakedAmt,
                _rewardAmt,
                _stakesShares,                    
                _stakingDays
                );
                    
            if (_newSharePrice > codStats.sharePrice) {
                    
                _newSharePrice = _newSharePrice < codStats.sharePrice.mul(230).div(100) ?
                _newSharePrice : codStats.sharePrice.mul(230).div(100);
                    
                emit newSharePrice(
                    _newSharePrice,
                    codStats.sharePrice,
                    _currrent5MinutesDay()
                );
                
                codStats.sharePrice = _newSharePrice;
            }
        }
    }
        
    function _getNewSharePrice(
        uint256 _stakedAmt,
        uint256 _rewardAmt,
        uint256 _stakesShares,
        uint32 _stakingDays)
        private
        pure 
        returns (uint256) {
                
            uint256  _bonusAmt = _getBonus(_stakingDays);
                
            return
                _stakedAmt
                    .add(_rewardAmt)
                    .mul(_bonusAmt)
                    .mul(bonusPrecision)
                    .div(_stakesShares);
    }
        
    function _stakeShares(
        uint256 _stakedAmt,
        uint32 _stakingDays,
        uint256 _sharePrice)
        private
        pure
        returns (uint256)
    {
        return _sharesAmt(_stakedAmt, _stakingDays, _sharePrice);
    }
        
    function _sharesAmt(
        uint256 _stakedAmt,
        uint32 _stakingDays,
        uint256 _sharePrice)
        private
        pure 
        returns (uint256)
    {
        return _baseAmt(_stakedAmt, _sharePrice)
            .mul(sharesPrecision + _getBonus(_stakingDays))
            .div(sharesPrecision);
    }
        
    function _getBonus(uint32 _stakingLength) private pure returns (uint256) {
        return _stakingLength.div(365) == 0 ?
            _stakingLength :
            getHigherDays(_stakingLength);
    }
        
    function getHigherDays(uint32 _stakingLength) private pure returns (uint256 _days) {
        for (uint32 i = 0; i < _stakingLength.div(365); i++) {
            _days += _stakingLength - (i * 365);
        }
        _days += _stakingLength - (_stakingLength.div(365) * 365);
        return uint256(_days);
    }
        
    function _baseAmt(
        uint256 _stakedAmt,
        uint256 _sharePrice
    )
        private
        pure
        returns (uint256)
    {
        return
            _stakedAmt
                .mul(precisionRate)
                .div(_sharePrice);
    }
        
    function _checkRewardAmtbyID(address _staker, bytes16 _stakeID) public view returns (uint256 rewardAmt) {
        stake memory stake = stakes[_staker][_stakeID];
        return stake.isActive ? _detectReward(stake) : stake.rewardAmt;
    }
        
    function _checkPenaltyAmtbyID(address _staker, bytes16 _stakeID) public view returns (uint256 penaltyAmt) {
        stake memory stake = stakes[_staker][_stakeID];
        return stake.isActive ? _calcPenaltyAmt(stake) : stake.penaltyAmt;
    }
        
    function _detectReward(stake memory _stake) private view returns (uint256) {
        return _stakeNotStarted(_stake) ? 0 : _calcRewardAmt(_stake);
    }
        
    function _calcPenaltyAmt(
        stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _stakeNotStarted(_stake) || _isMatureStake(_stake) ? 0 : _getPenalty(_stake);
    }
        
    function _getPenalty(stake memory _stake) private view returns (uint256) {
        return (_stake.stakingDays - _daysLeft(_stake)) >= (_stake.stakingDays / 2) 
            ? 0
            : ( _stake.stakedAmt - ((_stake.stakedAmt * (_stake.stakingDays - _daysLeft(_stake))) / (_stake.stakingDays / 2)));
    }
        
    function _calcRewardAmt(
        stake memory _stake
    )
        private
        view
        returns (uint256)
    {
        return _loopRewardAmt(
            _stake.stakeShares,
            _startDay(_stake),
            _dayCalculation(_stake)
        );
    }
        
    function _loopRewardAmt(
        uint256 _stakesShares,
        uint32 _startDay,
        uint32 _finalDay
    )
        private
        view
        returns (uint256 _rewardAmt)
    {
        for (uint32 _day = _startDay; _day < _finalDay; _day++) {
            _rewardAmt += _stakesShares * precisionRate / snapshots[_day].inflationAmt;
        }
            
        if (_currrent5MinutesDay() > (_finalDay + uint32(14)) && _rewardAmt > 0) {
            uint256 _reductionPercent = ((uint256(_currrent5MinutesDay()) - uint256(_finalDay) - uint256(14)) / uint256(7)) + uint256(1);
            if (_reductionPercent > 100) {_reductionPercent = 100; }
            _rewardAmt = _rewardAmt
                .mul(uint256(100).sub(_reductionPercent))
                .div(100);
        }
            
        if (_currrent5MinutesDay() < _finalDay && _rewardAmt > 0) {
            if (_finalDay != _startDay) {
                _rewardAmt = _rewardAmt * rewardPrecision * (uint256(_currrent5MinutesDay()) - uint256(_startDay)) 
                    / (uint256(_finalDay) - uint256(_startDay)) / rewardPrecision;
            }
        }
    }
        
    function compareStrings(string memory x, string memory z) private pure returns (bool) {
        return (keccak256(abi.encodePacked(x))) == (keccak256(abi.encodePacked(z)));
    }
        
    function getTokensStaked(address _staker) external view returns (uint256) {
        return total5MinutesActiveStakes[_staker];
    }
}