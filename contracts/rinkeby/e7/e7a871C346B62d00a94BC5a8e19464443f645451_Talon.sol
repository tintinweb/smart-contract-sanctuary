/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity >=0.8.0 <0.9.0;

/*
Nothing contained or implied in this code shall constitute or be deemed to constitute a partnership
among the token holders or node owners or any other persons, nor shall this code constitute or
authorize a person to be the agent or legal representative of another person, nor shall a person
by reason of this code have the right or power to assume, create or incur any commitment, liability
or obligation of any kind, express or implied, against or in the name of or on behalf of another person.
*/


library SafeMath {


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Talon is IERC20, Context {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;



    uint256 private _totalSupply;

    string constant private _name = 'Talon';
    string constant private _symbol = 'TALON';
    uint8 constant private _decimals = 18;
    
    uint256 public burnFee = 2;
    uint256 public donationFee = 2;
    uint256 public devFee = 2;
    
    uint256 private _previousBurnFee = 0;
    uint256 private _previousDonationFee = 0;
    uint256 private _previousDevFee = 0;
    
    address public burnAddress = address(0);
    address private _ppsAddress;
    address public holdingAddress = 0xa3ad767D3832109D7ca7e1baF0be95D29dB328E8;
    address public donationAddress = 0x271eec17Efe6D377ec2026460E42A11D868ed249;
    address public devAddress = 0xe15F35B04f416489CEB4F735C96EeBC2F07d0850;
    
    address[] private _excludedFromFees;
    
    mapping (address => uint256) private _sorenInvestments;
    mapping (address => uint256) private _archimedesInvestments;
    mapping (address => uint256) private _oxInvestments;
    
    mapping (address => bool) private bots;
    
    address public admin;
    address public feeChanger;
    bool public ppsComplete = false;
    
    bool public lockSoren = true;
    bool public lockArchimedes = true;
    bool public lockOx = true;
    
    IUniswapV2Router02 public immutable uniswapRouter;
    address public ethPair;

    uint256 public sorenInitialLockDuration = 31556952;
    uint256 public archimedesInitialLockDuration = 31556952;
    uint256 public oxInitialLockDuration = 31556952;

    uint256 public sorenPercentIncrease = 25;
    uint256 public archimedesPercentIncrease = 25;
    uint256 public oxPercentIncrease = 25;

    uint256 public timeBetweenSorenUnlocks = 2592000;
    uint256 public timeBetweenArchimedesUnlocks = 2592000;
    uint256 public timeBetweenOxUnlocks = 2592000;

    uint256 public currentSorenUnlockPercent = 0;
    uint256 public currentArchimedesUnlockPercent = 0;
    uint256 public currentOxUnlockPercent = 0;

    uint256 public oxRoundStart;
    uint256 public archimedesRoundStart;
    uint256 public sorenRoundStart;

    uint256 public nextSorenUnlockTime;
    uint256 public nextArchimedesUnlockTime;
    uint256 public nextOxUnlockTime;

    bool public secondMintComplete = false;
    
    

    constructor (uint256 initialSupply) {

        _mint(initialSupply);

        admin = _msgSender();
        feeChanger = _msgSender();        
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual   returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burn(uint256 value) public {
      _burn(_msgSender(), value);
    }


    function _approve(address owner, address spender, uint256 amount) private postPPS() {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private postPPS(){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[sender] && !bots[recipient]);

        uint256 lockedAmount = 0;

        if(lockSoren) {
            uint256 sorenInvestment = _sorenInvestments[sender];
            if(sorenInvestment > 0) {
                lockedAmount += _sorenInvestments[sender] * (100 - currentSorenUnlockPercent) / 100;
            }

            require((_balances[sender] - amount) >= lockedAmount , "Transfer Exceeds Unlocked tokens of Soren Member");
        }
        if(lockArchimedes) {
            uint256 archimedesInvestment = _archimedesInvestments[sender];
            if(archimedesInvestment > 0) {
                lockedAmount += _archimedesInvestments[sender] * (100 - currentArchimedesUnlockPercent) / 100;
            }

            require((_balances[sender] - amount) >= lockedAmount , "Transfer Exceeds Unlocked tokens of Owl Member");
        }
        if(lockOx) {
            uint256 oxInvestment = _oxInvestments[sender];
            if(oxInvestment > 0) {
                lockedAmount += _oxInvestments[sender] * (100 - currentOxUnlockPercent) / 100;
            }

            require((_balances[sender] - amount) >= lockedAmount , "Transfer Exceeds Unlocked tokens of Ox and/or Owl Member");
        }
        
        bool recipientExcludedFromFees = isExcludedFromFees(recipient);
        if(recipientExcludedFromFees){
            removeAllFee();
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 burnAmount = amount * burnFee / 100;
        uint256 donationAmount = amount * donationFee / 100;
        uint256 devAmount = amount * devFee / 100;

        _balances[burnAddress] += burnAmount;
        _balances[donationAddress] += donationAmount;
        _balances[devAddress] += devAmount;

        _balances[recipient] += (amount - burnAmount - donationAmount - devAmount);

        emit Transfer(sender, recipient, amount);
        if(recipientExcludedFromFees) {
            restoreAllFee();
        }
        
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply -= value;
        _balances[account] = _balances[account] -= value;
        emit Transfer(account, burnAddress, value);
    }
    
    function handleInvestment(address investor, uint256 tokens, bool isArchimedes, bool isSoren, bool isOx) external returns(bool){
        require(_ppsAddress == _msgSender(), "Only the PPS contract can initiate investments");
        require(!ppsComplete, "PPS is already over");
        if(isSoren){
            _sorenInvestments[investor] += tokens;
            if(sorenRoundStart == 0) {
                sorenRoundStart = block.timestamp;

                nextSorenUnlockTime = sorenRoundStart + sorenInitialLockDuration;
            }
        } else if(isArchimedes){
            _archimedesInvestments[investor] += tokens;
            if(archimedesRoundStart == 0) {
                archimedesRoundStart = block.timestamp;

                nextArchimedesUnlockTime = archimedesRoundStart + archimedesInitialLockDuration;
            }
        } else if(isOx) {
            _oxInvestments[investor] += tokens;
            if(oxRoundStart == 0) {
                oxRoundStart = block.timestamp;

                nextOxUnlockTime = oxRoundStart + oxInitialLockDuration;
            }
        }
        _balances[holdingAddress] -= tokens;
        _balances[investor] += tokens;
        emit Transfer(holdingAddress, investor, tokens);
        return true;
    }  
    
    function isExcludedFromFees(address user) public view returns (bool) {
        for(uint256 i = 0; i < _excludedFromFees.length; i++){
            if(_excludedFromFees[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function excludeFromFees(address newUser) external onlyAdmin(){
        require(!isExcludedFromFees(newUser), "Account is already excluded from fees.");
        _excludedFromFees.push(newUser);
    }
    
    function removeFromExcludeFromFees(address account) external onlyAdmin() {
        require(isExcludedFromFees(account), "Account isn't excluded");
        for (uint256 i = 0; i < _excludedFromFees.length; i++) {
            if (_excludedFromFees[i] == account) {
                _excludedFromFees[i] = _excludedFromFees[_excludedFromFees.length - 1];
                _excludedFromFees.pop();
                break;
            }
        }
    }

    function unLockSoren() external postPPS(){
        require(lockSoren, "Soren investments are unlocked");
        require(currentSorenUnlockPercent < 100, "Soren investments are 100% unlocked");
        require(block.timestamp >= nextSorenUnlockTime, "We have not reached the next Soren unlock time");
        currentSorenUnlockPercent += sorenPercentIncrease;
        nextSorenUnlockTime += timeBetweenSorenUnlocks;

        if(currentSorenUnlockPercent >= 100){
            lockSoren = false;
        }
        
    }

    function overrideSorenUnlock(bool willNowBeLocked) external onlyAdmin() {
        lockSoren = willNowBeLocked;
    }  

    function unLockArchimedes() external postPPS(){
        require(lockArchimedes, "Archimedes investments are unlocked");
        require(currentArchimedesUnlockPercent < 100, "Archimedes investments are 100% unlocked");
        require(block.timestamp >= nextArchimedesUnlockTime, "We have not reached the next Soren unlock time");
        currentArchimedesUnlockPercent += archimedesPercentIncrease;
        nextArchimedesUnlockTime += timeBetweenArchimedesUnlocks;

        if(currentArchimedesUnlockPercent >= 100){
            lockArchimedes = false;
        }
        
    }

    function overrideArchimedesUnlock(bool willNowBeLocked) external onlyAdmin() {
        lockArchimedes = willNowBeLocked;
    }  

    function unLockOx() external postPPS(){
        require(lockOx, "Ox investments are unlocked");
        require(currentOxUnlockPercent < 100, "Ox investments are 100% unlocked");
        require(block.timestamp >= nextOxUnlockTime, "We have not reached the next Ox unlock time");
        currentOxUnlockPercent += oxPercentIncrease;
        nextOxUnlockTime += timeBetweenOxUnlocks;

        if(currentOxUnlockPercent >= 100){
            lockOx = false;
        }
    }

    function overrideOxUnlock(bool willNowBeLocked) external onlyAdmin() {
        lockOx = willNowBeLocked;
    }    
      
    function removeAllFee() private {
        if(burnFee == 0 && donationFee ==0 && donationFee == 0) return;
        
        _previousBurnFee = burnFee;
        _previousDonationFee = donationFee;
        _previousDevFee = devFee;
        
        burnFee = 0;
        donationFee = 0;
        devFee = 0;
    }
    
    function restoreAllFee() private {
        burnFee = _previousBurnFee;
        donationFee = _previousDonationFee;
        devFee = _previousDevFee;
    }
    
    function setDonationFee(uint256 newFee) external onlyFeeChanger() {
        donationFee = newFee;
    }
    
    function setBurnFee(uint256 newFee) external onlyFeeChanger() {
        burnFee = newFee;
    }
    
    function setDevFee(uint256 newFee) external onlyFeeChanger() {
        devFee = newFee;
    }
    
    function setPPSAddress(address newPPS) external onlyAdmin() {
        _ppsAddress = newPPS;
    }

    function setOxInitialDuration(uint256 newDuration) external onlyAdmin() {
        oxInitialLockDuration = newDuration;
    }

    function setSorenInitialDuration(uint256 newDuration) external onlyAdmin() {
        sorenInitialLockDuration = newDuration;
    }

    function setArchimedesInitialDuration(uint256 newDuration) external onlyAdmin() {
        archimedesInitialLockDuration = newDuration;
    }

    function setOxPercentIncrease(uint256 newPercent) external onlyAdmin() {
        oxPercentIncrease = newPercent;
    }

    function setSorenPercentIncrease(uint256 newPercent) external onlyAdmin() {
        sorenPercentIncrease = newPercent;
    }

    function setArchimedesPercentIncrease(uint256 newPercent) external onlyAdmin() {
        archimedesPercentIncrease = newPercent;
    }

    function setOxTimeBetweenUnlocks(uint256 newDuration) external onlyAdmin() {
        timeBetweenOxUnlocks = newDuration;
    }

    function setSorenTimeBetweenUnlocks(uint256 newDuration) external onlyAdmin() {
        timeBetweenSorenUnlocks = newDuration;
    }

    function setArchimedesTimeBetweenUnlocks(uint256 newDuration) external onlyAdmin() {
        timeBetweenArchimedesUnlocks = newDuration;
    }
     
    modifier onlyAdmin() {
        require(admin == _msgSender(), "Caller is not the admin");
        _;
    }

    modifier onlyFeeChanger() {
        require(feeChanger == _msgSender(), "Caller is not the fee changer");
        _;
    }
    
    modifier postPPS() {
        require(ppsComplete || (_msgSender() == admin) || (_msgSender() == holdingAddress) , "The PPS is not complete");
        _;
    }

    modifier prePPS() {
        require(!ppsComplete , "The PPS is already over");
        _;
    }
    
    function publicLaunch(uint256 tokenAmount, address owner) external payable onlyAdmin() prePPS() {
        
        ppsComplete = true;
        
        //createPair
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        ethPair = factory.createPair(address(this),uniswapRouter.WETH());
        
        
        //Transfer to this contract to be ready to add liquidity
        _balances[holdingAddress] -= tokenAmount;
        _balances[address(this)] += tokenAmount;
        
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: msg.value}(address(this),tokenAmount,0,0,owner,block.timestamp);
        
        
    }

    function _mint(uint256 amount) private {
        require(holdingAddress != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[holdingAddress] += amount;
        emit Transfer(address(0), holdingAddress, amount);

        secondMintComplete = true;
    }

    function secondMint(uint256 amount) public onlyAdmin() {
        require(holdingAddress != address(0), "ERC20: mint to the zero address");
        require(!secondMintComplete,"Second mint has already happened");

        _totalSupply += amount;
        _balances[holdingAddress] += amount;
        emit Transfer(address(0), holdingAddress, amount);

        secondMintComplete = true;

    }
    
    function setBots(address[] memory bots_) external onlyAdmin {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) external onlyAdmin {
        bots[notbot] = false;
    }

    function changeAdmin(address newAdmin) external onlyAdmin() {
        admin = newAdmin;
    }

    function changeFeeChanger(address newFeeChanger) external onlyFeeChanger() {
        feeChanger = newFeeChanger;
    }

    function changeHoldingWallet(address newAddress) external onlyAdmin() {
        uint256 currentHoldingBalance = _balances[holdingAddress];

        emit Transfer(holdingAddress, newAddress, currentHoldingBalance); 

        _balances[holdingAddress] -= currentHoldingBalance;
        _balances[newAddress] += currentHoldingBalance;
        holdingAddress = newAddress;

    }

    function changeDonationAddress(address newAddress) external onlyAdmin() {
        donationAddress = newAddress;
    }

    function changeDevAddress(address newAddress) external onlyAdmin() {
        devAddress = newAddress;
    }

    function changeBurnAddress(address newAddress) external onlyAdmin() {
        burnAddress = newAddress;
    }

    function doETETransactions (address dispersingWallet, address[] calldata addresses, uint256[] calldata tokenAmounts) public  {
        for(uint i = 0; i < addresses.length ; i++){
            transferFrom(dispersingWallet, addresses[i], tokenAmounts[i]);
        }
        
    }
    
    
}