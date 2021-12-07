//SourceUnit: VGCToken.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract Owner {
    address public owner;
    constructor () {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function isOwner() internal view returns (bool) {
        return owner == msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Round {

    uint private _roundId;
    uint private _roundStartTime;
    uint private _roundEndTime;
    uint private _maxTermId;
    address[] private _addresses;

    constructor (uint roundId, uint startTime, uint endTime){
        _roundId = roundId;
        _roundStartTime = startTime;
        _roundEndTime = endTime;
    }

    function getMaxTermId() public view returns (uint) {
        return _maxTermId;
    }

    function setMaxTermId(uint _newMaxTermId) public {
        _maxTermId = _newMaxTermId;
    }

    function getRoundId() public view returns (uint) {
        return _roundId;
    }

    function getRoundStartTime() public view returns (uint) {
        return _roundStartTime;
    }

    function getRoundEndTime() public view returns (uint) {
        return _roundEndTime;
    }

    function setEndTime(uint endTime) public {
        _roundEndTime = endTime;
    }

    function getAddresses() public view returns (address[] memory) {
        return _addresses;
    }

    function pushAddress(address addr) public {
        _addresses.push(addr);
    }

}

contract Term {

    uint private _termId;
    uint private _amountPerTransaction;
    uint private _transactionQty;
    uint private _goalTransactionQty;
    uint private _termStartTime;
    uint private _termEndTime;
    bool private _settle;
    bool private _out;
    bool private _hasMint;
    bool private _redeem;
    uint private _transactionIndex = 0;
    mapping(uint => address) public joinAddresses;
    mapping(uint => uint) private joinTimeses;
    mapping(uint => bool) private refundStatuss;
    using SafeMath for uint256;


    constructor (uint termId, uint amountPerTransaction, uint transactionQty, uint goalTransactionQty, uint termStartTime, uint termEndTime){
        _termId = termId;
        _amountPerTransaction = amountPerTransaction;
        _transactionQty = transactionQty;
        _goalTransactionQty = goalTransactionQty;
        _termStartTime = termStartTime;
        _termEndTime = termEndTime;
    }

    function getTermId() public view returns (uint) {
        return _termId;
    }

    function getAmountPerTransaction() public view returns (uint) {
        return _amountPerTransaction;
    }

    function getTransactionIndex() public view returns (uint) {
        return _transactionIndex;
    }

    function getTransactionQty() public view returns (uint) {
        return _transactionQty;
    }

    function setTransactionQty(uint _newTransactionQt) public {
        _transactionQty = _newTransactionQt;
    }

    function getGoalTransactionQty() public view returns (uint) {
        return _goalTransactionQty;
    }

    function getTermStartTime() public view returns (uint) {
        return _termStartTime;
    }

    function getTermEndTime() public view returns (uint) {
        return _termEndTime;
    }

    function setTermEndTime(uint termEndTime) public {
        _termEndTime = termEndTime;
    }

    function pushJoinAddresses(address joinAddress, uint256 qty) public {
        _transactionIndex = _transactionIndex.add(1);
        joinAddresses[_transactionIndex] = joinAddress;
        joinTimeses[_transactionIndex] = qty;
        refundStatuss[_transactionIndex] = false;
        _transactionQty = _transactionQty.add(qty);
    }

    function updateRefundStatuss(address joinAddress) public returns (uint) {
        for (uint256 i = 1; i <= _transactionIndex; i++) {
            if (joinAddress == joinAddresses[i] && refundStatuss[i] == false) {
                refundStatuss[i] = true;
                return joinTimeses[i];
            }
        }
        return 0;
    }

    function getJoinTimes(address joinAddress) public view returns (uint) {
        for (uint256 i = 1; i <= _transactionIndex; i++) {
            if (joinAddress == joinAddresses[i]) {
                return joinTimeses[i];
            }
        }
        return 0;
    }

    function getCanRedeemJoinTimes(address joinAddress) public view returns (uint) {
        for (uint256 i = 1; i <= _transactionIndex; i++) {
            if (joinAddress == joinAddresses[i] && refundStatuss[i] == false) {
                return joinTimeses[i];
            }
        }
        return 0;
    }

    function getJoinAddress(uint index) public view returns (address) {
        return joinAddresses[index];
    }


    function isSettle() public view returns (bool){
        return _settle;
    }

    function setSettle(bool settle) public {
        _settle = settle;
    }

    function isOut() public view returns (bool) {
        return _out;
    }

    function setOut(bool out) public {
        _out = out;
    }

    function isMint() public view returns (bool){
        return _hasMint;
    }

    function setMint(bool mint) public {
        _hasMint = mint;
    }

    function isRedeem() public view returns (bool) {
        return _redeem;
    }

    function setRedeem(bool redeem) public {
        _redeem = redeem;
    }
}

contract SwapTerm {

    uint private _termId;
    uint private _termStartTime;
    uint private _termEndTime;
    uint private _amount;
    address[] private joinAddresses;
    
    constructor (uint termId, uint termStartTime, uint termEndTime, uint amount){
        _termId = termId;
        _termStartTime = termStartTime;
        _termEndTime = termEndTime;
        _amount = amount;
    }

    function getTermId() public view returns (uint) {
        return _termId;
    }
    
    function getTermStartTime() public view returns (uint) {
        return _termStartTime;
    }

    function getTermEndTime() public view returns (uint) {
        return _termEndTime;
    }
    
    function getAmount() public view returns (uint) {
        return _amount;
    }

    function setTermEndTime(uint termEndTime) public {
        _termEndTime = termEndTime;
    }

    function pushJoinAddress(address addr) public {
        joinAddresses.push(addr);
    }
    
    function getJoinAddresses() public view returns(address[] memory){
        return joinAddresses;
    }
    
}

contract SwapActivity is Owner {
    using SafeMath for uint256;
    address internal swapPoolAddress;
    address internal swapMainAddress;
    mapping(uint256 => SwapTerm) internal swapTerms;
    uint internal constant initSwapTermTime = 24 hours;
    uint internal currSwapTermId = 0;
    
    function swapTermIsValid(SwapTerm swapTerm) internal view returns (bool){
        return block.timestamp > swapTerm.getTermStartTime() && block.timestamp < swapTerm.getTermEndTime();
    }

    function setSwapMainAddress(address account) public onlyOwner returns (bool success) {
        if(swapMainAddress == address(0)){
            swapMainAddress = account;
            return true;
        }
        return false;
    }
    
    function getSwapMainAddress() public view returns(address){
        return swapMainAddress;
    }
    
    event NewSwapTerm(uint256 indexed swapTermId);
    
    event StopSwapTerm(uint256 indexed swapTermId);
}

contract CrowdFund is Owner {

    using SafeMath for uint256;
    address internal toAddress;
    address internal poolAddress;
    address internal bonusAddress1;
    address internal bonusAddress2;
    uint internal currRoundId = 0;
    mapping(uint256 => Round) internal rounds;
    uint internal constant initRoundTime = 3650 days;
    uint internal constant totalTerm = 39;
    uint[totalTerm] internal amountPerTransactionArr = [20, 20, 20, 20, 20, 40, 40, 40, 80, 80, 80, 160, 160, 160, 320, 320, 320, 320, 320, 400, 400, 400, 400, 500, 500, 500, 500, 800, 800, 800, 800, 1200, 1200, 1200, 1200, 2000, 2000, 2000, 2000];
    uint[totalTerm] internal goalTransactionQtyArr = [200, 260, 338, 439, 571, 370, 488, 625, 408, 530, 689, 448, 583, 757, 492, 640, 832, 1081, 1406, 1462, 1901, 2496, 3212, 3341, 4343, 5645, 7339, 5963, 7752, 10077, 13100, 11353, 14759, 19187, 24943, 19456, 25293, 32880, 42744];
    uint internal constant timePerAdd = 2 minutes;
    uint internal constant initTermTime = 24 hours;
    uint internal constant joinTimesPerTerm = 50;
    address[] internal sysCreators;
    address[] internal sysGenesises;
    address[] internal sysNodes;
    address[] internal specialAddresses;
    address[] internal noProfitAddresses;
    mapping(address => address) internal creators;
    mapping(address => address) internal genesises;
    mapping(address => address) internal nodes;
    mapping(address => address) internal parents;
    mapping(address => address) internal experts;
    mapping(address => address[]) internal children;
    uint internal constant expertChildrenSize = 10;
    uint internal constant creatorFee = 50000000000;
    uint internal constant genesisFee = 10000000000;
    uint internal constant nodeFee = 3000000000;
    Term[100000][100000] internal termInfos;

    function isCreator(address addr) public view returns (bool){
        for (uint256 i = 0; i < sysCreators.length; i++) {
            if (addr == sysCreators[i]) {
                return true;
            }
        }
        return false;
    }

    function isGenesis(address addr) public view returns (bool){
        for (uint256 i = 0; i < sysGenesises.length; i++) {
            if (addr == sysGenesises[i]) {
                return true;
            }
        }
        return false;
    }

    function isNode(address addr) public view returns (bool){
        for (uint256 i = 0; i < sysNodes.length; i++) {
            if (addr == sysNodes[i]) {
                return true;
            }
        }
        return false;
    }

    function isExpert(address addr) public view returns (bool){
        return children[addr].length >= expertChildrenSize;
    }

    function isSpecial(address addr) public view returns (bool){
        for (uint256 i = 0; i < specialAddresses.length; i++) {
            if (addr == specialAddresses[i]) {
                return true;
            }
        }
        return false;
    }

    function isNoProfit(address addr) public view returns (bool){
        for (uint256 i = 0; i < noProfitAddresses.length; i++) {
            if (addr == noProfitAddresses[i]) {
                return true;
            }
        }
        return false;
    }

    function addSpecial(address addr) public onlyOwner returns (bool){
        if (!isSpecial(addr)) {
            specialAddresses.push(addr);
            return true;
        }
        return false;
    }

    function addNoProfit(address addr) public onlyOwner returns (bool){
        if (!isNoProfit(addr)) {
            noProfitAddresses.push(addr);
            return true;
        }
        return false;
    }

    function blockTime() public view returns (uint){
        return block.timestamp;
    }

    function getCurrRoundId() internal view returns (uint){
        return currRoundId;
    }

    function getCurrTermId() internal view returns (uint){
        Round round = rounds[currRoundId];
        return round.getMaxTermId();
    }

    function getToAddress() public view returns (address){
        return toAddress;
    }

    function getPoolAddress() public view returns (address){
        return poolAddress;
    }

    function getBonusAddress1() public view returns (address){
        return bonusAddress1;
    }

    function getBonusAddress2() public view returns (address){
        return bonusAddress2;
    }

    function addTerm() internal returns (bool success) {
        uint currTermId = getCurrTermId();
        if (currTermId < totalTerm) {
            if (currTermId >= 1) {
                require(termIsComplete(currRoundId, currTermId), "term not complete");
            }
            Round round = rounds[currRoundId];
            round.setMaxTermId(round.getMaxTermId() + 1);
            currTermId++;
            uint currTime = blockTime();
            Term term = new Term(currTermId, amountPerTransactionArr[currTermId - 1].mul(10 ** 6), 0, goalTransactionQtyArr[currTermId - 1], currTime, currTime.add(initTermTime));
            termInfos[currRoundId - 1][currTermId - 1] = term;
            emit NewTerm(currRoundId, currTermId);
            return true;
        }
        return false;
    }

    function roundIsValid(Round round) internal view returns (bool){
        return blockTime() >= round.getRoundStartTime() && blockTime() <= round.getRoundEndTime();
    }

    function termIsValid(Term _term) internal view returns (bool){
        return blockTime() >= _term.getTermStartTime() && blockTime() <= _term.getTermEndTime();
    }

    function canJoin(uint256 roundId, uint256 termId, uint qty, address joinAddress) internal view returns (bool) {
        Round round = rounds[roundId];
        Term term = getTermInfo(roundId, termId);
        if (roundIsValid(round) && termIsValid(term)) {
            if (!termIsComplete(term) && term.getTransactionQty().add(qty) <= term.getGoalTransactionQty() && qty <= joinTimesPerTerm && term.getJoinTimes(joinAddress) == 0) {
                return true;
            }
        }
        return false;
    }


    function termIsComplete(Term _term) internal view returns (bool) {
        return _term.getTransactionQty() >= _term.getGoalTransactionQty();
    }

    function termIsComplete(uint256 roundId, uint256 termId) internal view returns (bool) {
        Term term = getTermInfo(roundId, termId);
        return termIsComplete(term);
    }

    function getTermInfo(uint roundId, uint termId) internal view returns (Term){
        return termInfos[roundId - 1][termId - 1];
    }

    function doUpdateRedeem(uint256 roundId, uint256 termId) internal {
        Term term = getTermInfo(roundId, termId);
        if (!term.isRedeem()) {
            term.setRedeem(true);
        }
    }

    function getAmount(uint256 roundId, uint256 termId, uint _type) internal view returns (uint){
        Term term = getTermInfo(roundId, termId);
        uint percent = 0;
        if (_type == 1) {
            percent = 3;
        } else if (_type == 2) {
            percent = 1;
        } else if (_type == 3) {
            percent = 30;
        }
        return term.getAmountPerTransaction().mul(term.getGoalTransactionQty()).mul(percent).div(100);
    }

    function getRefundAmount(uint256 roundId, uint256 termId) internal view returns (uint){
        Round round = rounds[roundId];
        Term term = getTermInfo(roundId, termId);
        uint percent = 0;
        if (round.getMaxTermId() == termId) {
            percent = 100;
        } else if (round.getMaxTermId() > termId + 3) {
            percent = term.isMint() ? 144 : 114;
        } else {
            percent = 70;
        }
        return term.getAmountPerTransaction().mul(percent).div(100);
    }

    function doUpdateAllRedeem() internal {
        for (uint256 i = getCurrTermId(); i > 0; i--) {
            doUpdateRedeem(currRoundId, i);
        }
    }

    event Settle(uint256 indexed roundId, uint256 indexed termId);

    event Mint(uint256 indexed roundId, uint256 indexed termId);

    event Out(uint256 indexed roundId, uint256 indexed termId);

    event Profit(uint256 indexed roundId, uint256 indexed termId, address addr);

    event NewTerm(uint256 indexed roundId, uint256 indexed termId);

    event CompleteTerm(uint256 indexed roundId, uint256 indexed termId);

    event NewRound(uint256 indexed roundId);

    event StopRound(uint256 indexed roundId);
    
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20, CrowdFund, SwapActivity {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 0;
    uint256 private _remainRewardFreeze = 50000000000000;
    uint256 private _remainPoolFreeze = 100000000000000;
    uint256 private planTotalSupply = 200000000000000;

    constructor (address _toAddress, address _poolAddress, address _bonusAddress1, address _bonusAddress2, address _swapPoolAddress, string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        toAddress = _toAddress;
        poolAddress = _poolAddress;
        bonusAddress1 = _bonusAddress1;
        bonusAddress2 = _bonusAddress2;
        swapPoolAddress = _swapPoolAddress;
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function totalRewardFreeze() public view returns (uint256) {
        return _remainRewardFreeze;
    }

    function totalPoolFreeze() public view returns (uint256) {
        return _remainPoolFreeze;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(msg.sender != toAddress);
        require(msg.sender != poolAddress);
        require(msg.sender != swapPoolAddress);
        if (recipient == toAddress) {
            require(canJoin(currRoundId, getCurrTermId(), amount.div(amountPerTransactionArr[getCurrTermId() - 1].mul(10 ** 6)), msg.sender), "transfer revert.");
            require(amount.mod(amountPerTransactionArr[getCurrTermId() - 1].mul(10 ** 6)) == 0, "transfer revert...");
        }
        _transfer(msg.sender, recipient, amount);
        if (recipient == toAddress) {
            joinSuccessBiz(msg.sender, amount.div(amountPerTransactionArr[getCurrTermId() - 1].mul(10 ** 6)));
        }
        if (recipient == bonusAddress1 || recipient == bonusAddress2) {
            if (amount == creatorFee && !isCreator(msg.sender)) {
                creators[msg.sender] = msg.sender;
                sysCreators.push(msg.sender);
            }
            if (amount == genesisFee && !isGenesis(msg.sender)) {
                genesises[msg.sender] = msg.sender;
                sysGenesises.push(msg.sender);
            }
            if (amount == nodeFee && !isNode(msg.sender)) {
                nodes[msg.sender] = msg.sender;
                sysNodes.push(msg.sender);
            }
        }
        if (amount == 1000000 && recipient != toAddress && recipient != poolAddress && !isSpecial(msg.sender)) {
            if (parents[recipient] == address(0)) {
                creators[recipient] = creators[msg.sender];
                genesises[recipient] = genesises[msg.sender];
                nodes[recipient] = nodes[msg.sender];
                parents[recipient] = msg.sender;
                if (isExpert(msg.sender)) {
                    experts[recipient] = msg.sender;
                } else {
                    if (experts[msg.sender] != address(0)) {
                        experts[recipient] = experts[msg.sender];
                    }
                }
                children[msg.sender].push(recipient);
            }
        }
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(msg.sender != toAddress, "approve toAddress revert...");
        require(msg.sender != poolAddress, "approve poolAddress revert...");
        require(msg.sender != swapPoolAddress);
        _approve(msg.sender, spender, value);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != toAddress, "approve toAddress revert...");
        require(sender != poolAddress, "approve poolAddress revert...");
        require(sender != swapPoolAddress);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender != toAddress, "increaseAllowance toAddress revert...");
        require(msg.sender != poolAddress, "increaseAllowance poolAddress revert...");
        require(msg.sender != swapPoolAddress);
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(msg.sender != toAddress, "decreaseAllowance toAddress revert...");
        require(msg.sender != poolAddress, "decreaseAllowance poolAddress revert...");
        require(msg.sender != swapPoolAddress);
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function startNewRound() public returns (bool success) {
        if (currRoundId == 0) {
            require(isOwner());
        }
        if (currRoundId >= 1) {
            bool succ = stopRound();
            if (!succ) {
                return false;
            }
        }
        currRoundId++;
        uint currentTime = blockTime();
        Round round = new Round(currRoundId, currentTime, currentTime.add(initRoundTime));
        rounds[currRoundId] = round;
        emit NewRound(currRoundId);
        addTerm();
        _poolMint(poolAddress, 200000000000);
        return true;
    }

    function stopRound() internal returns (bool success) {
        Round round = rounds[currRoundId];
        if (blockTime() > round.getRoundStartTime()) {
            Term term = getTermInfo(currRoundId, round.getMaxTermId());
            if (blockTime() > term.getTermEndTime()) {
                round.setEndTime(blockTime());
                emit StopRound(currRoundId);
                doUpdateAllRedeem();
                if (_balances[poolAddress] > 0) {
                    address[] memory addresses = round.getAddresses();
                    if (addresses.length > 10) {
                        uint poolBalance = _balances[poolAddress];
                        for (uint256 i = addresses.length - 1; i >= addresses.length - 10; i--) {
                            if (i == addresses.length - 1) {
                                _transfer(poolAddress, addresses[i], poolBalance.mul(50).div(100));
                            } else if (i == addresses.length - 2) {
                                _transfer(poolAddress, addresses[i], poolBalance.mul(10).div(100));
                            } else {
                                _transfer(poolAddress, addresses[i], poolBalance.mul(5).div(100));
                            }
                        }
                    }
                }
                return true;
            }
        }
        return false;
    }

    function joinSuccessBiz(address account, uint256 qty) internal {
        Round round = rounds[currRoundId];
        Term term = getTermInfo(currRoundId, round.getMaxTermId());
        if (roundIsValid(round) && termIsValid(term)) {
            round.pushAddress(account);
            term.pushJoinAddresses(account, qty);
            if (term.getTermEndTime().add(timePerAdd.mul(qty)).sub(blockTime()) < initTermTime) {
                term.setTermEndTime(term.getTermEndTime().add(timePerAdd.mul(qty)));
            } else {
                term.setTermEndTime(blockTime() + initTermTime);
            }
            if (termIsComplete(term)) {
                doCompleteTermBiz(term);
                addTerm();
            }
        }
    }
    
    
    function doCompleteTermBiz(Term term) internal {
        term.setTermEndTime(blockTime());
        doSettle(currRoundId, getCurrTermId());
        emit Settle(currRoundId, getCurrTermId());
        if (getCurrTermId() >= 4) {
            uint bizTermId = getCurrTermId() - 3;
            doMint(currRoundId, bizTermId);
            emit Mint(currRoundId, bizTermId);
            doOut(currRoundId, bizTermId);
            emit Out(currRoundId, bizTermId);
        }
        emit CompleteTerm(currRoundId, getCurrTermId());
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        require(amount != 0);
        if (sender != poolAddress && sender != toAddress && sender != swapPoolAddress && sender != swapMainAddress) {
            require(_balances[sender] >= amount + 1000000, "balance not enough revert...");
        } else {
            require(_balances[sender] >= amount, "balance not enough revert...");
        }
        SwapTerm swapTerm = swapTerms[currSwapTermId];
        if(sender == swapMainAddress && amount >= swapTerm.getAmount()){
            successSwapPoolBiz(recipient);
        }
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _batchTransfer(address[] memory addresses, uint256[] memory amounts) public returns (bool){
        require(addresses.length > 0, "no addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
        return true;
    }

    function _mint(address account, uint256 amount) internal returns (bool){
        if (_totalSupply.add(amount) <= planTotalSupply) {
            _totalSupply = _totalSupply.add(amount);
            _balances[account] = _balances[account].add(amount);
            emit Transfer(address(0), account, amount);
            return true;
        }
        return false;
    }

    function _rewardMint(address account, uint256 amount) internal returns (bool){
        if (_remainRewardFreeze > amount) {
            _remainRewardFreeze = _remainRewardFreeze.sub(amount);
            return _mint(account, amount);
        }
        return false;
    }

    function _poolMint(address account, uint256 amount) internal returns (bool){
        if (_remainPoolFreeze > amount) {
            _remainPoolFreeze = _remainPoolFreeze.sub(amount);
            return _mint(account, amount);
        }
        return false;
    }

    function doSettle(uint256 roundId, uint256 termId) internal returns (bool){
        Term term = getTermInfo(roundId, termId);
        if (!term.isSettle()) {
            _transfer(toAddress, poolAddress, getAmount(roundId, termId, 1));
            _transfer(toAddress, bonusAddress1, getAmount(roundId, termId, 2));
            _transfer(toAddress, bonusAddress2, getAmount(roundId, termId, 2));
            term.setSettle(true);
        }
        return false;
    }

    function doProfit(uint profitAmount) internal {
        if (creators[msg.sender] != address(0) && !isNoProfit(creators[msg.sender])) {
            _transfer(toAddress, creators[msg.sender], profitAmount.mul(2).div(100));
        }
        if (genesises[msg.sender] != address(0) && !isNoProfit(genesises[msg.sender])) {
            _transfer(toAddress, genesises[msg.sender], profitAmount.mul(2).div(100));
        }
        if (nodes[msg.sender] != address(0) && !isNoProfit(nodes[msg.sender])) {
            _transfer(toAddress, nodes[msg.sender], profitAmount.mul(2).div(100));
        }
        if (experts[msg.sender] != address(0) && !isNoProfit(experts[msg.sender])) {
            _transfer(toAddress, experts[msg.sender], profitAmount.mul(5).div(100));
        }
    }

    function doOut(uint256 roundId, uint256 termId) internal returns (bool){
        Term term = getTermInfo(roundId, termId);
        if (!term.isOut()) {
            term.setOut(true);
            term.setRedeem(true);
        }
        return false;
    }

    function doMint(uint256 roundId, uint256 termId) internal returns (bool){
        Term term = getTermInfo(roundId, termId);
        if (!term.isMint()) {
            bool b = _rewardMint(toAddress, getAmount(roundId, termId, 3));
            if (b) {
                term.setMint(b);
                return true;
            }
        }
        return false;
    }

    function balanceInfo() public view returns (uint _toAddressBalance, uint _poolAddressBalance, uint _userBalance){
        _toAddressBalance = _balances[getToAddress()];
        _poolAddressBalance = _balances[getPoolAddress()];
        _userBalance = _balances[msg.sender];
    }

    function currentRoundInfo() public view returns (uint _roundId, uint _roundStartTime, uint _roundEndTime, uint _termId){
        _roundId = currRoundId;
        Round round = rounds[_roundId];
        _roundStartTime = round.getRoundStartTime();
        _roundEndTime = round.getRoundEndTime();
        _termId = round.getMaxTermId();
    }

    function getWinners(uint roundId) public view returns (address winner1, address winner2, address winner3, address winner4, address winner5, address winner6, address winner7, address winner8, address winner9, address winner10){
        Round round = rounds[roundId];
        address[] memory addresses = round.getAddresses();
        uint length = addresses.length;
        if (length >= 1) {
            winner1 = addresses[length - 1];
        }
        if (length >= 2) {
            winner2 = addresses[length - 2];
        }
        if (length >= 3) {
            winner3 = addresses[length - 3];
        }
        if (length >= 4) {
            winner4 = addresses[length - 4];
        }
        if (length >= 5) {
            winner5 = addresses[length - 5];
        }
        if (length >= 6) {
            winner6 = addresses[length - 6];
        }
        if (length >= 7) {
            winner7 = addresses[length - 7];
        }
        if (length >= 8) {
            winner8 = addresses[length - 8];
        }
        if (length >= 9) {
            winner9 = addresses[length - 9];
        }
        if (length >= 10) {
            winner10 = addresses[length - 10];
        }
    }

    function roundInfo(uint roundId) public view returns (uint _roundStartTime, uint _roundEndTime, uint _termId){
        Round round = rounds[roundId];
        _roundStartTime = round.getRoundStartTime();
        _roundEndTime = round.getRoundEndTime();
        _termId = round.getMaxTermId();
    }

    function termInfo(uint roundId, uint termId) public view returns (bool _canJoin, uint _amountPerTransaction, uint _transactionQty, uint _goalTransactionQty, uint _termStartTime, uint _termEndTime, uint _blockTime, bool _settle, bool _out, bool _hasMint, bool _redeem){
        Term term = termInfos[roundId - 1][termId - 1];
        _amountPerTransaction = term.getAmountPerTransaction();
        _transactionQty = term.getTransactionQty();
        _goalTransactionQty = term.getGoalTransactionQty();
        _termStartTime = term.getTermStartTime();
        _termEndTime = term.getTermEndTime();
        _settle = term.isSettle();
        _out = term.isOut();
        _hasMint = term.isMint();
        _redeem = term.isRedeem();
        _canJoin = canJoin(roundId, termId, 1, msg.sender);
        _blockTime = blockTime();
    }

    function userInfo(address addr) public view returns (uint _balance, address _creator, address _genesis, address _node, address _expert, address _parent, bool _isCreator, bool _isGenesis, bool _isNode, bool _isExpert){
        _balance = _balances[addr];
        _creator = creators[addr];
        _genesis = genesises[addr];
        _node = nodes[addr];
        _expert = experts[addr];
        _parent = parents[addr];
        _isCreator = isCreator(addr);
        _isGenesis = isGenesis(addr);
        _isNode = isNode(addr);
        _isExpert = isExpert(addr);
    }

    function userChildren(address addr) public view returns (address[] memory _children){
        _children = children[addr];
    }

    function redeemInfo(uint roundId, uint termId) public view returns (uint _joinTimes, uint _canRedeemJoinTimes, uint _redeemAmount, bool _isRedeem){
        Term term = getTermInfo(roundId, termId);
        _isRedeem = term.isRedeem();
        _joinTimes = term.getJoinTimes(msg.sender);
        _canRedeemJoinTimes = term.getCanRedeemJoinTimes(msg.sender);
        uint refundAmount = getRefundAmount(roundId, termId);
        _redeemAmount = refundAmount.mul(_canRedeemJoinTimes);
    }

    function redeem(uint256 roundId, uint256 termId) public returns (bool){
        Term term = getTermInfo(roundId, termId);
        require(term.isRedeem());
        uint joinTimes = term.updateRefundStatuss(msg.sender);
        require(joinTimes > 0);
        uint refundAmount = getRefundAmount(roundId, termId);
        _transfer(toAddress, msg.sender, refundAmount.mul(joinTimes));
        if (term.isOut()) {
            doProfit(term.getAmountPerTransaction().mul(joinTimes));
            emit Profit(roundId, termId, msg.sender);
        }
        return true;
    }
    
    function addSwapTerm(uint amount) public onlyOwner returns (bool success) {
        if (currSwapTermId >= 1) {
            bool succ = stopSwapTerm();
            if (!succ) {
                return false;
            }
        }
        currSwapTermId++;
        uint currTime = blockTime();
        SwapTerm swapTerm = new SwapTerm(currSwapTermId, currTime, currTime.add(initSwapTermTime), amount);
        swapTerms[currSwapTermId] = swapTerm;
        emit NewSwapTerm(currSwapTermId);
        _poolMint(swapPoolAddress, 200000000000);
        return true;
    }

    function stopSwapTerm() internal returns (bool success) {
        SwapTerm swapTerm = swapTerms[currSwapTermId];
        if (blockTime() > swapTerm.getTermEndTime()) {
            swapTerm.setTermEndTime(blockTime());
            emit StopSwapTerm(currSwapTermId);
            if (_balances[swapPoolAddress] > 0) {
                address[] memory swapTermAddresses = swapTerm.getJoinAddresses();
                if (swapTermAddresses.length > 10) {
                    uint swapPoolBalance = _balances[swapPoolAddress];
                    for (uint256 i = swapTermAddresses.length - 1; i >= swapTermAddresses.length - 10; i--) {
                        if (i == swapTermAddresses.length - 1) {
                            _transfer(swapPoolAddress, swapTermAddresses[i], swapPoolBalance.mul(50).div(100));
                        } else if (i == swapTermAddresses.length - 2) {
                            _transfer(swapPoolAddress, swapTermAddresses[i], swapPoolBalance.mul(10).div(100));
                        } else {
                            _transfer(swapPoolAddress, swapTermAddresses[i], swapPoolBalance.mul(5).div(100));
                        }
                    }
                }
            }
            return true;
        }
        return false;
    }
    
    function successSwapPoolBiz(address account) internal {
        SwapTerm swapTerm = swapTerms[currSwapTermId];
        if (swapTermIsValid(swapTerm)) {
            swapTerm.pushJoinAddress(account);
            if (swapTerm.getTermEndTime().add(5 minutes).sub(blockTime()) < initSwapTermTime) {
                swapTerm.setTermEndTime(swapTerm.getTermEndTime().add(5 minutes));
            } else {
                swapTerm.setTermEndTime(blockTime() + initSwapTermTime);
            }
        }
    }
    
    function swapTermInfo(uint swapTermId) public view returns (uint _startTime, uint _endTime, uint _blockTime, uint _amount){
        SwapTerm swapTerm = swapTerms[swapTermId];
        _startTime = swapTerm.getTermStartTime();
        _endTime = swapTerm.getTermEndTime();
        _amount = swapTerm.getAmount();
        _blockTime = blockTime();
    }
    
    function getSwapWinners(uint swapTermId) public view returns (address winner1, address winner2, address winner3, address winner4, address winner5, address winner6, address winner7, address winner8, address winner9, address winner10){
        SwapTerm swapTerm = swapTerms[swapTermId];
        address[] memory addresses = swapTerm.getJoinAddresses();
        uint length = addresses.length;
        if (length >= 1) {
            winner1 = addresses[length - 1];
        }
        if (length >= 2) {
            winner2 = addresses[length - 2];
        }
        if (length >= 3) {
            winner3 = addresses[length - 3];
        }
        if (length >= 4) {
            winner4 = addresses[length - 4];
        }
        if (length >= 5) {
            winner5 = addresses[length - 5];
        }
        if (length >= 6) {
            winner6 = addresses[length - 6];
        }
        if (length >= 7) {
            winner7 = addresses[length - 7];
        }
        if (length >= 8) {
            winner8 = addresses[length - 8];
        }
        if (length >= 9) {
            winner9 = addresses[length - 9];
        }
        if (length >= 10) {
            winner10 = addresses[length - 10];
        }
    }
}

contract VGCToken is ERC20 {
    constructor (address toAddress, address poolAddress, address bonusAddress1, address bonusAddress2, address totalAddress, address swapPoolAddress) ERC20(toAddress, poolAddress, bonusAddress1, bonusAddress2, swapPoolAddress, "Virgin Coin", "VGC", 6) {
        _mint(totalAddress, 50000000 * (10 ** uint256(decimals())));
    }
}