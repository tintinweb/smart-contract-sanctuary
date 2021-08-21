//SourceUnit: contract.sol

pragma solidity 0.6.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IJustswapExchange {
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
}

contract ERC20 {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    address private _owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (uint256 totalSupply, string memory name, string memory symbol) public {
        _owner = msg.sender;
        _totalSupply = totalSupply;
        _name = name;
        _symbol = symbol;
    }
    
    modifier onlyOwner() {
        require(_msgSender() == _owner, "require owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        _owner = newOwner;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
    
    function mint(address to, uint256 amount) public onlyOwner {
        require(amount>0, "bad amount");
        
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        require(from != address(0), "bad from");
        
        _burn(from, amount);
    }
}


contract TronExBankUsd {
    
    using SafeMath for uint256;
    
    uint256 internal deposited;                                                
    uint256 internal withdrawn;                                                
    uint256 internal bonus;
    uint256 internal usersNumber; 
    
    uint256 constant internal INTERVAL = 86400;
    
    uint256 constant internal DEPOSIT_MIN = 100e6; //100 usdt
    uint256 constant internal PRIMARY_DEPOSIT_LIMIT = 10000e6;
    uint256 constant internal DEPOSIT_LIMIT_STEP = 1000e6;
    
    uint256 constant internal VOLUME_STEP_FOR_INTEREST = 100e6;
    
    uint256 constant internal p_MARKETING_FEE_POINTS = 800;                     
    uint256 constant internal p_DEVOPS_FEE_POINTS = 200;                        
    uint256 constant internal p_WITHDRAWAL_FEE_POINTS = 200; 
    
    uint256 internal p_MARKETING_BONUS_POINTS1 = 1000;
    uint256 internal p_MARKETING_BONUS_POINTS2 = 1500;
    uint256 internal p_MARKETING_BONUS_POINTS3 = 2000;
    uint256[] internal p_BONUS_POINTS_LIST = [3000,1500,500,500,500,500,500,500,500,500,500,500,500,500,500,500,500,500,500,500];                                     
                  
    uint256 constant internal p10000 = 10000; 
    
    uint256 constant internal p_TT_POINTS = 7000;
    uint256 constant internal p_TBT_POINTS = p10000 - p_TT_POINTS;
    
    uint256 public tbtPrice = 0;
    
    IERC20 constant usdtToken = IERC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c); //usdt contract address
    IJustswapExchange constant usdtExchange = IJustswapExchange(0x41a2726afbecbd8e936000ed684cef5e2f5cf43008); //The usdt exchange address in Justswap
    
    
    ERC20 public _tbt;
    ERC20 public _ttusd;
    
    bool private _initialized = false;
    
    InsuranceFundPool internal insuranceFundPool;
    SafeguardFundPool internal safeguardFundPool;
    mapping (address => User) internal users;
    
    address private _owner;
    address payable internal ifAddr;
    address payable internal mkAddr;                              
    address payable internal doAddr;                                 
    address payable internal wsAddr; 
    address payable internal dfAddr;
    
    struct Deposit { 
        uint32 time; 
        uint256 amount;                                        
    }
    
    struct User {
        uint16 downlineCount;
        uint256 downlineDeposited;
        uint256 downlineWithdrawn;
        uint32 lastCheckPoint;                                           
        uint256 deposited;                                               
        uint256 withdrawn; 
        uint256 bonus;
        uint256 activeValue;
        uint256 surplus;
        address upline;
        Deposit[] deposits;
    }
    
    struct InsuranceFundPool {
        uint256 balance;
        uint256 collected;
    }
    
    struct SafeguardFundMember{
        uint256 input;
        uint256 output;
    }
    
    struct SafeguardFundPool {
        uint256 totalInput;
        uint256 totalOutput;
        mapping (address => SafeguardFundMember) members;
    }
    
    event NewUser(address indexed addr, uint256 amt);
    event NewDeposit(address indexed addr, uint256 amt);
    event Withdrawn(address indexed addr, uint256 amt);
    event DepositFeePaid(address indexed addr, uint256 m,uint256 d);
    event WithdrawalFeePaid(address indexed addr, uint256 amt,uint256 wdnAmt);
    event BonusReceived(address indexed addr, address dpAddr, uint256 level, uint256 amt);
    event InsuranceFundTransfer(uint256 amt);
    event SafeguardFundInput(address indexed addr,uint256 amt);
    event SafeguardFundOutput(address indexed addr,uint256 amt);
    
    //------------------------------------------public functions--------------------------------------------------------------    
    
    constructor(address payable insuranceFundAddress,address payable defaultAddress,address payable marketingAddress, address payable devopsAddress, address payable withdrawalServiceAddress) public{
        require(!isContract(defaultAddress),"A wallet address requires");
        _owner = msg.sender;
        _ttusd = new ERC20(100000000e6, "TT-USD", "TT-USD");
        _tbt = new ERC20(100000000e6, "TBT", "TBT");
        _tbt.mint(msg.sender, 30000000e6);
        
        ifAddr = insuranceFundAddress;
        dfAddr = defaultAddress;
        mkAddr = marketingAddress;
        doAddr = devopsAddress;
        wsAddr = withdrawalServiceAddress;
        
        insuranceFundPool = InsuranceFundPool(0,0);
        safeguardFundPool = SafeguardFundPool(0,0);
    }
    
    
    function deposit(address uplineAddress, uint256 amount) public {
        require(!isContract(msg.sender) && msg.sender == tx.origin && msg.sender!=dfAddr,"Auth fails");
        uint32 time = uint32(now);
        
        //1.
        require(amount >= DEPOSIT_MIN, "There is a minimum deposit amount limit");
        require(amount <= availableDepositLimit(msg.sender), "The request exceeds available deposit limit");
        usdtToken.transferFrom(msg.sender, address(this), amount);
        
        
        //2.
        uint256 marketingFee = amount.mul(p_MARKETING_FEE_POINTS).div(p10000);
        uint256 devopsFee = amount.mul(p_DEVOPS_FEE_POINTS).div(p10000);
        
        usdtToken.transfer(mkAddr, marketingFee);
        usdtToken.transfer(doAddr, devopsFee);
        
        emit DepositFeePaid(msg.sender,marketingFee,devopsFee);
        
        //3.
        User storage user = users[msg.sender];
        if(user.upline == address(0)){
            //a.
            User storage uplUser = users[uplineAddress];
            if(msg.sender!=uplineAddress && uplUser.deposited>0){
                uplUser.downlineCount++;
                uplUser.activeValue = amount.add(uplUser.activeValue);
                uplUser.downlineDeposited = uplUser.downlineDeposited.add(amount);
                user.upline = uplineAddress;
                
                address upln = uplUser.upline;
                for(uint8 i = 0 ; i < 20; i++) {
                    if(upln==dfAddr) break;
                    User storage uplUs = users[upln];
                    uplUs.downlineDeposited = uplUs.downlineDeposited.add(amount);
                    upln = uplUs.upline;
                }
            }else{
                user.upline = dfAddr;
            }
            //b.
            user.lastCheckPoint = time;
            usersNumber++;
            emit NewUser(msg.sender,amount);
        }else{
            uint256 inst = calInst(user);
            if(inst > 0){
                user.surplus = inst.add(user.surplus);
                user.lastCheckPoint = time;
            }
        }
        user.deposits.push(Deposit(time,amount));
        user.deposited = user.deposited.add(amount);
        user.activeValue = amount.add(user.activeValue);
        
        deposited = deposited.add(amount);
        uint256 mkBonus = sendMarketingBonus(user.upline, amount);
        if(mkBonus > 0) bonus = bonus.add(mkBonus);
        
        emit NewDeposit(msg.sender,amount);
    }
    
    function withdraw() public returns (uint256,uint256,uint256,uint256){
        require(msg.sender == tx.origin,"Auth fails");
        //1.
        User storage user = checkUser(msg.sender);
        uint256 interest = calInst(user);
        require(interest > 0, "No interest available to withdraw");
        cntBalCheck(user,interest);
        
        //2.
        uint32 time = uint32(now);
        uint256 wf = time < uint(user.lastCheckPoint).add(INTERVAL.mul(7)) ? interest.div(5) : interest.mul(p_WITHDRAWAL_FEE_POINTS).div(p10000);
        usdtToken.transfer(wsAddr, wf);
        emit WithdrawalFeePaid(msg.sender,wf,interest);
        uint256 amount = interest.sub(wf);
        
        //3.
        user.withdrawn = user.withdrawn.add(interest);
        user.activeValue = user.activeValue > interest ? user.activeValue.sub(interest) : 0 ;
        user.lastCheckPoint = time;
        
        //4.
        uint256 fund = amount.mul(3000).div(p10000);
        amount = amount.sub(fund);
        
        uint256 bonusBase = amount.div(p10000);
        uint256 totalBonus = 0;
        address upline = user.upline;
        for(uint8 i = 0 ; i < 20 ; i++){
            if(upline==dfAddr) break;
            uint8 level = i + 1;
            uint256 mkBonus = bonusBase.mul(p_BONUS_POINTS_LIST[i]);
            User storage uplUser = users[upline];
            uplUser.downlineWithdrawn = uplUser.downlineWithdrawn.add(interest);
            uint256 maxBonus = uplUser.deposited.mul(3);
            if(uplUser.withdrawn<uplUser.deposited.mul(5) && uplUser.bonus<maxBonus && uplUser.downlineCount>=level){   
                if(mkBonus.add(uplUser.bonus) > maxBonus) mkBonus = maxBonus.sub(uplUser.bonus);
                uplUser.bonus = mkBonus.add(uplUser.bonus);
                totalBonus = totalBonus.add(mkBonus);
                
                uint256 bouns = mkBonus.mul(7000).div(p10000);
                uint256 bounsTT = bouns.mul(p_TT_POINTS).div(p10000);
                uint256 bounsTBT = usdToTbt(bouns.mul(p_TBT_POINTS).div(p10000));
                _ttusd.mint(upline, bounsTT);
                _tbt.mint(upline, bounsTBT);
                
                emit BonusReceived(upline,msg.sender,level,mkBonus);
            }
            upline = uplUser.upline;
        }
        fund = fund.add(totalBonus.mul(3000).div(p10000));
        insuranceFundPool.balance = fund.add(insuranceFundPool.balance);
        insuranceFundPool.collected = fund.add(insuranceFundPool.collected);
        
        uint256 amountTT = amount.mul(p_TT_POINTS).div(p10000);
        uint256 amountTBT = usdToTbt(amount.mul(p_TBT_POINTS).div(p10000));
        
        //5.
        bonus = bonus.add(totalBonus);
        withdrawn = withdrawn.add(interest);
        
        _ttusd.mint(msg.sender, amountTT);
        _tbt.mint(msg.sender, amountTBT);
        
        emit Withdrawn(msg.sender,interest);
        
        return (interest,wf,fund,totalBonus);
    }
    
    function usdToTbt(uint256 amount) internal view returns (uint256) {
        return amount*10000/tbtPrice;
    }
    
    function updateTbtPrice(uint256 price) public onlyOwner {
        require(price > 0, "bad price");
        tbtPrice = price;
    }
    
    function redeemTT(uint256 amount) public {
        _ttusd.burn(msg.sender, amount);
        usdtToken.transfer(msg.sender, amount);
    }
    
    function mintTbt(uint256 amount) public onlyOwner {
        _tbt.mint(msg.sender, amount);
    }
    
    function mintTT(uint256 amount) public onlyOwner {
        _ttusd.mint(msg.sender, amount);
    }
    
    function transferOwnership(address to) public onlyOwner {
        require(to != address(0), "bad address");
        
        _owner = msg.sender;
    }

    //>>                                   ----->user statistics<-----
       
    function userStatistics(address addr) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256,uint256){
        User storage user = checkUser(addr);
        return (calInst(user), user.deposited , user.withdrawn , user.bonus , user.activeValue , user.surplus , user.upline , user.downlineCount ,  user.lastCheckPoint , user.deposits.length,user.downlineDeposited,user.downlineWithdrawn);
    }
    
    function depositInfo(address addr,uint index) public view returns (uint256,uint256) {
        User storage user = checkUser(addr);
        require(user.deposits.length>0,"No deposit found.");
        Deposit[] storage deposits = user.deposits;
        uint last = deposits.length-1;
        if(index>last)index=last;
        Deposit storage dp = deposits[index];
        return (dp.amount,dp.time);
    }
    
    function calculateInterest(uint256 amtDpd , uint256 amtWdn , uint256 actVal , uint256 surplus , uint256 periods) public pure returns (uint256) {
        if(periods == 0) return 0;
        if(periods > 180) periods = 180;
        
        uint256 deduction = amtWdn.div(5);
        if(deduction >= amtDpd) return 0;
        uint256 dpd = amtDpd;
        uint256 wdn = amtWdn;
        uint256 cdl = dpd.sub(deduction);
        
        uint256 pRawInstPts =  actVal.div(VOLUME_STEP_FOR_INTEREST).add(50);
        if(pRawInstPts>600) pRawInstPts = 600;
        
        for(uint8 i = 0 ; i < periods ; i++){
            uint256 pInstPts = pRawInstPts;
            if(wdn >= dpd){
                pInstPts = pInstPts.div(2**(wdn.div(dpd))); 
            }
            uint256 inst = cdl.mul(pInstPts).div(p10000);
            wdn = wdn.add(inst);
            cdl = cdl.sub(inst.div(5));
        }
        uint256 maxWithdrawal = dpd.mul(5);
        uint256 interest = wdn.sub(amtWdn).add(surplus);
        if(periods>=30) interest = interest.add(interest.div(10));
        if(wdn > maxWithdrawal) interest = maxWithdrawal.sub(amtWdn);
        return interest;
    }
    
    //>>                                   ----->contract statistics<-----    
    
    function contractStatistics() public view returns (uint256,uint256,uint256,uint256,uint256,uint256){
        return (cntBal() , availableContractBalance() , deposited , withdrawn , bonus , usersNumber);
    }
    
    function supportTeam() public view returns (address,address,address,address,address,address){
        return (ifAddr,dfAddr,mkAddr,doAddr,wsAddr,_owner);
    }
    
    //>>                                    ----->insurance fund<-----
    
    function insuranceFundPoolInfo() public view returns (uint256,uint256){
        require((msg.sender == ifAddr || msg.sender == _owner) && msg.sender == tx.origin,"Auth fails");
        return (insuranceFundPool.balance,insuranceFundPool.collected);
    }
    
    function deployInsuranceFund(uint256 amt) public {
        require(msg.sender == ifAddr && msg.sender == tx.origin,"Auth fails");
        require(amt <= insuranceFundPool.balance,"The insurance fund balance is not enough to deploy");
        insuranceFundPool.balance = insuranceFundPool.balance.sub(amt);
        usdtToken.transfer(ifAddr, amt);
        emit InsuranceFundTransfer(amt);
    }
    
    //>>                                    ----->insurance fund<-----
    
    function safeguardFundPoolInfo() public view returns (uint256,uint256){
        require(msg.sender == _owner && msg.sender == tx.origin,"Auth fails");
        return (safeguardFundPool.totalInput,safeguardFundPool.totalOutput);
    }
    
    function sdfMbrInfo() public view returns (uint256,uint256,uint256){
        SafeguardFundMember storage sfdMbr = safeguardFundPool.members[msg.sender];
        uint256 available = sfdMbr.input > sfdMbr.output ? uint256(sfdMbr.input).sub(sfdMbr.output) : 0;
        return (available,sfdMbr.input,sfdMbr.output);
    }
    
    function sfd_in(uint256 amount) public returns (uint256,uint256){
        require(!isContract(msg.sender) && msg.sender == tx.origin,"Auth fails");
        
        usdtToken.transferFrom(msg.sender, address(this), amount);
        SafeguardFundMember storage sfdMbr = safeguardFundPool.members[msg.sender];
        sfdMbr.input = amount.add(sfdMbr.input);
        safeguardFundPool.totalInput = amount.add(safeguardFundPool.totalInput);
        
        emit SafeguardFundInput(msg.sender, amount);
        
        return (sfdMbr.input, sfdMbr.output);
    }
    
    function sfd_out(uint256 amt) public returns (uint256,uint256) {
        require(msg.sender == tx.origin,"Auth fails");
        
        SafeguardFundMember storage sfdMbr = safeguardFundPool.members[msg.sender];
        require(sfdMbr.input>0,"Access denied");
        
        uint256 out = amt.add(sfdMbr.output);
        require(sfdMbr.input>=out,"No sufficient fund to transfer outwards");
        
        require(amt <= availableContractBalance(),"The available contract balance is not enough");
        
        sfdMbr.output = out;
        safeguardFundPool.totalOutput = amt.add(safeguardFundPool.totalOutput);
        
        usdtToken.transfer(msg.sender, amt);
        emit SafeguardFundOutput(msg.sender,amt);
        
        return (sfdMbr.input,sfdMbr.output);
    }
    
    //------------------------------------------internel functions--------------------------------------------------------------

    function calInst(User memory user) internal view returns (uint256) {
        return calculateInterest(user.deposited , user.withdrawn , user.activeValue , user.surplus , now.sub(user.lastCheckPoint).div(INTERVAL));
    }
    
    function cntBal() internal view returns (uint256){
        return usdtToken.balanceOf(address(this));
    }
    
    function availableContractBalance() internal view returns (uint256){
        uint256 bal = cntBal();
        return bal>insuranceFundPool.balance ? bal.sub(insuranceFundPool.balance) : 0;
    }
    
    function usdtBalance() public view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }
    
    function availableDepositLimit(address addr) internal view returns (uint256) {
        User memory user = users[addr];
        if(user.deposited==0)return PRIMARY_DEPOSIT_LIMIT;
        return PRIMARY_DEPOSIT_LIMIT.add(uint256(user.downlineCount).mul(DEPOSIT_LIMIT_STEP)).sub(user.deposited);
    }
    
    function checkUser(address addr) internal view returns (User storage){
        User storage user = users[addr];
        require(user.deposited>0,"The address provided hasn't been registered in this contract.");
        return user;
    }
    
    function sendMarketingBonus(address addr,uint256 amtDpd) internal returns (uint256){
       
        uint256 mkBonus;
        User storage user = users[addr];
        if(user.downlineCount >= 3) {
            mkBonus = amtDpd.mul(p_MARKETING_BONUS_POINTS3).div(p10000);
        } else if (user.downlineCount == 2) {
            mkBonus = amtDpd.mul(p_MARKETING_BONUS_POINTS2).div(p10000);
        } else {
            mkBonus = amtDpd.mul(p_MARKETING_BONUS_POINTS1).div(p10000);
        }
        
        if(mkBonus > availableContractBalance()) return 0;
        address receiver;
        if(addr == dfAddr){
            receiver = dfAddr;
        }else{
            
            uint256 dpd = user.deposited;
            uint256 maxBonus = dpd.mul(3);
            if(user.withdrawn<dpd.mul(5) && user.bonus<maxBonus){   
                if(mkBonus.add(user.bonus) > maxBonus) mkBonus = maxBonus.sub(user.bonus);
                user.bonus = uint64(mkBonus.add(user.bonus));
                receiver = addr;
            }else{
                receiver = dfAddr;
            }
        }
        
        uint256 bounsTT = mkBonus.mul(p_TT_POINTS).div(p10000);
        uint256 bounsTBT = usdToTbt(mkBonus.mul(p_TT_POINTS).div(p10000));
        _ttusd.mint(receiver, bounsTT);
        _tbt.mint(receiver, bounsTBT);
        
        emit BonusReceived(receiver,tx.origin,0,mkBonus);
        return mkBonus;
    }
    
    function cntBalCheck(User storage user,uint256 amt) internal view returns (uint){
        uint256 bal = availableContractBalance();
        require(amt < bal ,"Contract balance is not enough to pay the withdrawal amount.");
        if(bal < 50000e6) require(user.withdrawn < user.deposited , "Withdraw limit happens when your accumulative total withdraw has been more than 100% of your deposit and the contract balance available is less than 50000 USDT.");
        if(bal < 20000e6) require(user.withdrawn.mul(2) < user.deposited , "Withdraw limit happens when your accumulative total withdraw has been more than 50% of your deposit and the contract balance available is less than 20000 USDT.");
        return bal;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "require owner");
        _;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}