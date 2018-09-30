pragma solidity ^0.4.2;


library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;}

contract  ERC20Token {

    using SafeMath for uint256;
    string public name = "SPY TOKEN";
    string public symbol = "SPY";
    string public standard = "SPY v1.0";
    uint256 public totalSupply;
    uint8 public decimals = 18;
    mapping(address => uint256) public balance_;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(uint256 _initialSupply) public{
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balance_[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balance_[tokenOwner];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balance_[_from] >= _value);
        require(balance_[_to].add(_value) > balance_[_to]);
        uint previousBalances = balance_[_from].add(balance_[_to]);
        balance_[_from] = balance_[_from].sub(_value);
        balance_[_to] = balance_[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balance_[_from].add(balance_[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender] && balance_[_from] >= _value && _value > 0);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balance_[_account]);
        totalSupply = totalSupply.sub(_amount);
        balance_[_account] = balance_[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }

    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowance[_account][msg.sender]);
        allowance[_account][msg.sender] = allowance[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply = totalSupply.add(_amount);
        balance_[_account] = balance_[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

}

contract Owned {
    address public owner;
    constructor () public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract MedallionChainToken is Owned, ERC20Token {
    using SafeMath for uint256;
    uint256 public sellPrice;
    uint256 public buyPrice;
    bool SalesOpen = false;

    mapping(address => bool) public frozenAccount;

    event SalesActivity(uint256 _sellPrice, uint256 _buyPrice, bool _SalesOpen);
    event FrozenFunds(address target, bool frozen);
    constructor(uint256 _initialSupply) ERC20Token(_initialSupply) public{
        owner = msg.sender;
    }

    modifier SalesIsOpen {
        require(SalesOpen);
        _;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balance_[_from] >= _value);
        require(balance_[_to].add(_value) >= balance_[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balance_[_from] = balance_[_from].sub(_value);
        balance_[_to] = balance_[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        _mint(target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, bool newSalesOpen) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        SalesOpen = newSalesOpen;
        emit SalesActivity(newSellPrice, newBuyPrice, newSalesOpen);
    }

    function() payable public {
        require(msg.value > 0);
        buy();
    }

    function buy() payable public returns (uint256 amount){
        amount = (msg.value.div(1 ether)).mul(buyPrice);
        _transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint256 amount) payable public SalesIsOpen {
        address myAddress = this;
        require(myAddress.balance >= amount.mul(sellPrice));
        _transfer(msg.sender, this, amount);
        msg.sender.transfer(amount.mul(sellPrice));
    }

}


contract MedallionChainTokenSale is Owned {
    using SafeMath for uint256;
    MedallionChainToken public tokenContract;
    uint256 public tokenRate;
    uint256 public tokenSold;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public generalRaised;
    uint256 public StartTime;
    uint256 public EndTime;
    string public Stage;
    address public wallet;


    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event Sell(address _buyer, string stage, uint256 _amount);
    event GoalReached(string stage, uint256 totalAmountRaised);
    event ChangeStage(uint256 newStartTime, uint256 newEndTime, uint256 mewtokenRate, string newStage, uint256 newFundingGoal);
    constructor(MedallionChainToken _tokenContract, uint256 _tokenRate, uint256 newStartTime, uint256 endStartTime, string currentStage, uint256 fundingGoalInEthers, address _wallet) public{
        tokenContract = _tokenContract;
        tokenRate = _tokenRate;
        StartTime = now.add(newStartTime).mul(1 days);
        EndTime = now.add(endStartTime).mul(1 days);
        Stage = currentStage;
        fundingGoal = fundingGoalInEthers.mul(1 ether);
        wallet = _wallet;

    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) IsStarted public payable {
        require(crowdsaleClosed);
        uint256 amount = msg.value;
        uint256 etherValue = amount.div(1 ether);
        uint256 _numberOfTokens = etherValue.mul(tokenRate);
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(_beneficiary, _numberOfTokens));
        tokenSold = tokenSold.add(_numberOfTokens);
        amountRaised = amountRaised.add(amount);
        generalRaised = generalRaised.add(amount);
        emit Sell(_beneficiary, Stage, _numberOfTokens);
        _forwardFunds();
        checkGoalReached();
    }

    function ChangeDeadLine(uint256 newStartTime, uint256 newEndTime, uint256 newPrice, string newStage, uint256 newFundingGoal) onlyOwner public {
        StartTime = now.add(newStartTime).mul(1 days);
        EndTime = now.add(newEndTime).mul(1 days);
        tokenRate = newPrice;
        Stage = newStage;
        fundingGoal = newFundingGoal;
        amountRaised = 0;
        emit ChangeStage(StartTime, EndTime, tokenRate, Stage, fundingGoal);
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(Stage, amountRaised);
        }
        crowdsaleClosed = false;
    }
    modifier afterDeadline() {if (now >= EndTime) _;}
    modifier IsStarted() {if (now >= StartTime) _;}
    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getStageTotal() public view returns (uint256){
        return amountRaised;
    }

    function getDistributedTotal() public view returns (uint256){
        return generalRaised;
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}


contract MedallionChainTokenPreSale is Owned {
    using SafeMath for uint256;
    MedallionChainToken public tokenContract;
    uint256 public tokenRate;
    uint256 public tokenSold;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public generalRaised;
    uint256 public StartTime;
    uint256 public EndTime;
    string public Stage;
    address public wallet;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event Sell(address _buyer, string stage, uint256 _amount);
    event GoalReached(string stage, uint256 totalAmountRaised);
    event ChangeStage(uint256 newStartTime, uint256 newEndTime, uint256 mewtokenRate, string newStage, uint256 newFundingGoal);
    constructor(MedallionChainToken _tokenContract, uint256 _tokenRate, uint256 newStartTime, uint256 endStartTime, string currentStage, uint256 fundingGoalInEthers, address _wallet) public{
        tokenContract = _tokenContract;
        tokenRate = _tokenRate;
        StartTime = now.add(newStartTime).mul(1 days);
        EndTime = now.add(endStartTime).mul(1 days);
        Stage = currentStage;
        fundingGoal = fundingGoalInEthers.mul(1 ether);
        wallet = _wallet;
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) IsStarted public payable {
        require(crowdsaleClosed);
        uint256 amount = msg.value;
        uint256 etherValue = amount.div(1 ether);
        uint256 _numberOfTokens = etherValue.mul(tokenRate);
        require(tokenContract.balanceOf(this) >= _numberOfTokens);
        require(tokenContract.transfer(_beneficiary, _numberOfTokens));
        tokenSold = tokenSold.add(_numberOfTokens);
        amountRaised = amountRaised.add(amount);
        generalRaised = generalRaised.add(amount);
        emit Sell(_beneficiary, Stage, _numberOfTokens);
        _forwardFunds();
        checkGoalReached();
    }

    function ChangeDeadLine(uint256 newStartTime, uint256 newEndTime, uint256 newPrice, string newStage, uint256 newFundingGoal) onlyOwner public {
        StartTime = now.add(newStartTime).mul(1 days);
        EndTime = now.add(newEndTime).mul(1 days);
        tokenRate = newPrice;
        Stage = newStage;
        fundingGoal = newFundingGoal;
        amountRaised = 0;
        emit ChangeStage(StartTime, EndTime, tokenRate, Stage, fundingGoal);
    }

    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(Stage, amountRaised);
        }
        crowdsaleClosed = false;
    }

    modifier afterDeadline() {if (now >= EndTime) _;}
    modifier IsStarted() {if (now >= StartTime) _;}

    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getStageTotal() public view returns (uint256){
        return amountRaised;
    }

    function getDistributedTotal() public view returns (uint256){
        return generalRaised;
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

}

contract MedallionChainSelfDrop is Owned {
    using SafeMath for uint256;
    uint256 distributedTotal = 0;
    string SelfDropStage = "Stage 1";
    bool SelfDropState = false;
    uint256 L1;
    uint256 L2;
    uint256 L3;
    uint256 M1;
    uint256 M2;
    uint256 M3;
    address wallet;
    MedallionChainToken public tokenContract;
    mapping(address => uint256) public SelfDropDoneAmountMap;
    address[] public SelfDropDoneList;

    event SelfDrop(address _receiver, uint256 amount);
    event UpdatePhase(address _operator, string _stage, bool _state);
    event UpdateRate(address _operator, uint256 _L1, uint256 _L2, uint256 _L3, uint256 _M1, uint256 _M2, uint256 _M3);
    constructor(MedallionChainToken _tokenContract, string _Stage, bool _State, uint256 _L1, uint256 _L2, uint256 _L3, uint256 _M1, uint256 _M2, uint256 _M3, address _wallet) public{
        tokenContract = _tokenContract;
        SelfDropStage = _Stage;
        SelfDropState = _State;
        L1 = _L1.mul(1 ether);
        L2 = _L2.mul(1 ether);
        L3 = _L3.mul(1 ether);
        M1 = _M1;
        M2 = _M2;
        M3 = _M3;
        wallet = _wallet;
    }
    modifier onlyWhileSelfDropStateOpen {
        require(SelfDropState == true);
        _;
    }
    function() payable public onlyWhileSelfDropStateOpen {
        uint256 amount = msg.value.div(1 ether);
        require(amount >= L1);
        uint256 _numberOfTokens = (amount.mul(M1)).div(L1);
        SelfDropTokens(msg.sender, _numberOfTokens);
    }

    function SelfDropTokens(address _recipient, uint256 amount) public payable onlyWhileSelfDropStateOpen {
        require(amount > 0);
        require(SelfDropDoneAmountMap[_recipient] <= 0);
        uint256 SelfDropBalance = tokenContract.balanceOf(this);
        require(SelfDropBalance >= amount);
        require(tokenContract.transfer(_recipient, amount));
        SelfDropDoneList.push(_recipient);
        uint256 SelfDropAmountThisAddr = 0;
        if (SelfDropDoneAmountMap[_recipient] > 0) {
            SelfDropAmountThisAddr = SelfDropDoneAmountMap[_recipient].add(amount);
        } else {
            SelfDropAmountThisAddr = amount;
        }
        SelfDropDoneAmountMap[_recipient] = SelfDropAmountThisAddr;
        distributedTotal = distributedTotal.add(amount);
        emit SelfDrop(_recipient, amount);
    }

    function transferOutBalance() public onlyOwner returns (bool){
        address creator = msg.sender;
        uint256 _balanceOfThis = tokenContract.balanceOf(this);
        if (_balanceOfThis > 0) {
            MedallionChainToken(tokenContract).approve(this, _balanceOfThis);
            MedallionChainToken(tokenContract).transferFrom(this, creator, _balanceOfThis);
            return true;
        } else {
            return false;
        }
    }

    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getDistributedTotal() public view returns (uint256){
        return distributedTotal;
    }

    function updateSelfDropStageState(string _stage, bool _state) public onlyOwner {
        SelfDropStage = _stage;
        SelfDropState = _state;
        emit UpdatePhase(msg.sender, _stage, _state);
    }

    function updateSelfDropStageState(uint256 _L1, uint256 _L2, uint256 _L3, uint256 _M1, uint256 _M2, uint256 _M3) public onlyOwner {
        L1 = _L1.mul(1 ether);
        L2 = _L2.mul(1 ether);
        L3 = _L3.mul(1 ether);
        M1 = _M1;
        M2 = _M2;
        M3 = _M3;
        emit UpdateRate(msg.sender, _L1, _L2, _L3, _M1, _M2, _M3);
    }

    function getDoneAddresses() public constant returns (address[]){
        return SelfDropDoneList;
    }

    function getDoneSelfDropAmount(address _addr) public view returns (uint256){
        return SelfDropDoneAmountMap[_addr];
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}


contract MedallionChainAirDrop is Owned {
    using SafeMath for uint256;
    uint256 distributedTotal = 0;
    uint256 tokenQuantity;
    uint256 ReductionRate;
    string AirdropStage;
    bool AirdropState;


    MedallionChainToken public tokenContract;
    mapping(address => uint256) public airdropDoneAmountMap;
    address[] public airdropDoneList;

    event Airdrop(address _receiver, uint256 amount);
    event UpdatePhase(address _operator, string _stage, bool _state);
    constructor(MedallionChainToken _tokenContract, string _Stage, bool _State, uint256 _tokenQuantity, uint256 _ReductionRate) public{
        tokenContract = _tokenContract;
        AirdropStage = _Stage;
        AirdropState = _State;
        tokenQuantity = _tokenQuantity;
        ReductionRate = _ReductionRate;
    }
    modifier onlyWhileAirdropStateOpen {
        require(AirdropState == true);
        _;
    }

    function() payable public onlyWhileAirdropStateOpen {
        airdropTokens(msg.sender, tokenQuantity);
    }


    function airdropTokens(address _recipient, uint256 amount) private onlyWhileAirdropStateOpen {
        require(amount > 0);
        require(airdropDoneAmountMap[_recipient] <= 0);
        uint256 airDropBalance = tokenContract.balanceOf(this);
        require(airDropBalance >= amount);
        require(tokenContract.transfer(_recipient, amount));
        airdropDoneList.push(_recipient);
        uint256 airDropAmountThisAddr = 0;
        if (airdropDoneAmountMap[_recipient] > 0) {
            airDropAmountThisAddr = airdropDoneAmountMap[_recipient].add(amount);
        } else {
            airDropAmountThisAddr = amount;
        }
        airdropDoneAmountMap[_recipient] = airDropAmountThisAddr;
        distributedTotal = distributedTotal.add(amount);
        tokenQuantity = tokenQuantity.sub(ReductionRate);
        emit Airdrop(_recipient, amount);

    }

    function transferOutBalance() public onlyOwner returns (bool){
        address creator = msg.sender;
        uint256 _balanceOfThis = tokenContract.balanceOf(this);
        if (_balanceOfThis > 0) {
            MedallionChainToken(tokenContract).approve(this, _balanceOfThis);
            MedallionChainToken(tokenContract).transferFrom(this, creator, _balanceOfThis);
            return true;
        } else {
            return false;
        }
    }

    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getDistributedTotal() public view returns (uint256){
        return distributedTotal;
    }

    function updateAirdropStageState(string _stage, bool _state) public onlyOwner {
        AirdropStage = _stage;
        AirdropState = _state;
        emit UpdatePhase(msg.sender, _stage, _state);
    }

    function getDoneAddresses() public constant returns (address[]){
        return airdropDoneList;
    }

    function getDoneAirdropAmount(address _addr) public view returns (uint256){
        return airdropDoneAmountMap[_addr];
    }
}

contract MedallionChainBounty is Owned {
    using SafeMath for uint256;
    uint256 distributedTotal = 0;
    MedallionChainToken public tokenContract;
    mapping(address => uint256) public bountyDoneAmountMap;
    address[] public bountyDoneList;

    event Bounty(address _receiver, uint256 amount);
    event UpdateState(address _operator, uint256 _state);
    constructor(MedallionChainToken _tokenContract) public{
        tokenContract = _tokenContract;
    }
    function bountyTokens(address _recipient, uint256 amount) public onlyOwner {
        require(amount > 0);
        uint256 bountyBalance = tokenContract.balanceOf(this);
        require(bountyBalance >= amount);
        require(tokenContract.transfer(_recipient, amount));
        bountyDoneList.push(_recipient);
        uint256 bountyAmountThisAddr = 0;
        if (bountyDoneAmountMap[_recipient] > 0) {
            bountyAmountThisAddr = bountyDoneAmountMap[_recipient].add(amount);
        } else {
            bountyAmountThisAddr = amount;
        }
        bountyDoneAmountMap[_recipient] = bountyAmountThisAddr;
        distributedTotal = distributedTotal.add(amount);
        emit Bounty(_recipient, amount);
    }

    function bountyTokensBatch(address[] receivers, uint256[] amounts) public onlyOwner {
        require(receivers.length > 0 && receivers.length == amounts.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bountyTokens(receivers[i], amounts[i]);
        }
    }

    function transferOutBalance() public onlyOwner returns (bool){
        uint256 _balanceOfThis = tokenContract.balanceOf(this);
        if (_balanceOfThis > 0) {
            MedallionChainToken(tokenContract).approve(this, _balanceOfThis);
            MedallionChainToken(tokenContract).transferFrom(this, msg.sender, _balanceOfThis);
            return true;
        } else {
            return false;
        }
    }

    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getDistributedTotal() public view returns (uint256){
        return distributedTotal;
    }

    function getDoneAddresses() public constant returns (address[]){
        return bountyDoneList;
    }

    function getDonebountyAmount(address _addr) public view returns (uint256){
        return bountyDoneAmountMap[_addr];
    }

}

contract MedallionChainRegister is Owned {
    using SafeMath for uint256;
    uint256 RegistrationRate = 0;
    uint256 distributedTotal = 0;
    bool RegistrationState = false;
    MedallionChainToken public tokenContract;
    mapping(address => uint256) public registrationDoneAmountMap;
    address[] public registrationList;

    event Registration(address _receiver, uint256 amount);
    event UpdateState(address _operator, bool _state, uint256 _RegistrationRate);
    constructor(MedallionChainToken _tokenContract, bool _RegistrationState, uint256 _RegistrationRate) public{
        tokenContract = _tokenContract;
        RegistrationState = _RegistrationState;
        RegistrationRate = _RegistrationRate;
    }
    modifier onlyWhileRegistrationStateStateOpen {
        require(RegistrationState == true);
        _;
    }
    function() external payable {
        newRegistration(msg.sender, RegistrationRate);
    }

    function newRegistration(address _recipient, uint256 amount) internal onlyWhileRegistrationStateStateOpen {
        require(amount > 0);
        require(registrationDoneAmountMap[_recipient] <= 0);
        uint256 registrationBalance = tokenContract.balanceOf(this);
        require(registrationBalance >= amount);
        require(tokenContract.transfer(_recipient, amount));
        registrationList.push(_recipient);
        uint256 RegAmountThisAddr = 0;
        if (registrationDoneAmountMap[_recipient] > 0) {
            RegAmountThisAddr = registrationDoneAmountMap[_recipient].add(amount);
        } else {
            RegAmountThisAddr = amount;
        }
        registrationDoneAmountMap[_recipient] = RegAmountThisAddr;
        distributedTotal = distributedTotal.add(amount);
        emit Registration(_recipient, amount);
    }

    function transferOutBalance() public onlyOwner returns (bool){
        address creator = msg.sender;
        uint256 _balanceOfThis = tokenContract.balanceOf(this);
        if (_balanceOfThis > 0) {
            MedallionChainToken(tokenContract).approve(this, _balanceOfThis);
            MedallionChainToken(tokenContract).transferFrom(this, creator, _balanceOfThis);
            return true;
        } else {
            return false;
        }
    }

    function balanceOfThis() public view returns (uint256){
        return tokenContract.balanceOf(this);
    }

    function getDistributedTotal() public view returns (uint256){
        return distributedTotal;
    }

    function updateRegistrationState(bool _RegistrationState, uint256 _RegistrationRate) public onlyOwner {
        RegistrationState = _RegistrationState;
        RegistrationRate = _RegistrationRate;
        emit UpdateState(msg.sender, _RegistrationState, _RegistrationRate);
    }

    function getDoneAddresses() public constant returns (address[]){
        return registrationList;
    }

    function getDoneRegistrationAmount(address _addr) public view returns (uint256){
        return registrationDoneAmountMap[_addr];
    }
}