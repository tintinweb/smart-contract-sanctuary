/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/
pragma solidity ^0.8.0 ; //SPDX-License-Identifier: UNLICENSED

interface IUSDT {
    function totalSupply() external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IUSDC {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CROWN is Ownable, ERC20 {
    
    constructor(address _usdt, address _usdc) ERC20("CROWN", "CWT") {
        _mint(msg.sender, 140000000 * 10 ** decimals());
        usdt = _usdt;
        usdc = _usdc;
        stableCoinAddress = _usdt; //set default dividend token as USDT
        decimalOfStableCoin = IERC20Metadata(stableCoinAddress).decimals();
    }
    
    //---------------------ERC20 extended functions---------------------
    function transferTokenFrom(address sender, address recipient, uint256 amount) public onlyOwner returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            require(receivers[i] == address(receivers[i]));
            transfer(receivers[i], amounts[i]);
        }
    }
    
    //----------------------------Staking Part-------------------------------
    mapping(address => bool) public isStaking;
    mapping(address => StakeInfo) public stakeInfo;
    mapping(address => Dividend[]) private dividendHistory;
    address[] internal stakeholders;
    uint256 public crownPrice = 1e18; // CROWN token initial price $1 US Dollar.
    uint256 public dividendRate = 4e18; // Initial dividend rate 4% of stake amount.
    uint256 public decimalOfStableCoin = 1e6; // Default decimals point of USDT/USDC token
    uint256 public startDate;
    uint256 public endDate;
    address public usdt;
    address public usdc;
    address public stableCoinAddress; // Current dividend token address.
    Dividend[] private dividendList;
    
    struct StakeInfo {
        uint256 amount;
        uint256 crownReward;
        uint256 dividend;
    }
    
    struct Dividend {
        address from;
        address to;
        uint256 amount;
        string symbol;
        uint256 time; 
    }
    
    //---------------------Staking Events---------------------
    event DepositStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event WithdrawStake(address indexed stakeholder, uint256 amount, uint256 timestamp);
    event DividendWithdrawal(address indexed to, uint256 amount, uint256 timestamp);
    
    //---------------------Modifier functions---------------------
    modifier validAddress(address account){    
        require(account == address(account),"Invalid address");
        require(account != address(0));
        _;
    }
    
    modifier onlyOwnerOrContract() {
        require(msg.sender == owner() || msg.sender == address(this), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyWithinStakePeriod() {    
        require(startDate > 0 && endDate > 0, "Invalid stake date!");
        require(block.timestamp >= startDate && block.timestamp <= endDate, "Please stake in the staking period!");
        _;
    }
    
    modifier onlyAfterPeriod() {    
        require(startDate > 0 && endDate > 0, "Invalid stake end date!");
        require(block.timestamp >= endDate, "Please wait until the stake removal date!");
        _;
    }
    
    //---------------------Getter functions---------------------

    function totalStakes() public view returns (uint256) {
       uint256 _totalStakes = 0;
       for (uint256 i = 0; i < stakeholders.length; i += 1) {
           _totalStakes += (stakeInfo[stakeholders[i]].amount);
       }
       return _totalStakes;
    }
   
    function totalDividends() public view returns (uint256) {
       uint256 _totalDividends = 0;
       for (uint256 i = 0; i < stakeholders.length; i += 1) {
           _totalDividends += (stakeInfo[stakeholders[i]].dividend);
       }
       return _totalDividends;
    }
   
    function getDividendSupply() public view returns (uint256) {
       if (address(stableCoinAddress) == address(usdc)) {
           return IUSDC(usdc).balanceOf(address(this));
       } else {
           return IUSDT(usdt).balanceOf(address(this));
       }
    }
   
    function stakeOf(address stakeHolder) external view returns (uint256) {
       return stakeInfo[stakeHolder].amount;
    }
   
    function dividendOf(address stakeHolder) external view returns (uint256) {
       return stakeInfo[stakeHolder].dividend;
    }
    
    function getDividendHistoryByAddress(address stakeHolder) public view returns (Dividend[] memory) {
        return dividendHistory[stakeHolder];
    } 
    
    function getDividendHistory() public view returns (Dividend[] memory) {
        return dividendList;
    }
    
    //---------------------Setter functions---------------------
    
    function updateDividendRate(uint256 _newDividendRate) public onlyOwnerOrContract {
        require(_newDividendRate > 0, "Dividend rate can not be zero!");
        dividendRate = _newDividendRate;
        massUpdateDividend();
    }
    
    function massUpdateDividend() internal {
        for (uint256 i; i < stakeholders.length; i+=1){
            address stakeholder = stakeholders[i];
            updateDividend(stakeholder);
        }
    }
    
    function updateCrownPrice(uint256 _crownPrice) public onlyOwnerOrContract {
       require(_crownPrice > 0, "Price must be more than 0!");
       crownPrice = _crownPrice;
    }
    
    function updateUSDTAddress(address addressOfUSDT) public validAddress(addressOfUSDT) onlyOwner returns (bool){
        usdt = addressOfUSDT;
        decimalOfStableCoin = IERC20Metadata(usdt).decimals();
        return true;
    }
    
    function updateUSDCAddress(address addressOfUSDC) public validAddress(addressOfUSDC) onlyOwner returns (bool){
        usdc = addressOfUSDC;
        decimalOfStableCoin = IERC20Metadata(usdc).decimals();
        return true;
    }
    
    function updateDividend(address stakeHolder) internal {
       uint256 reward = stakeInfo[stakeHolder].crownReward;
       uint256 crownReward = ((reward * dividendRate) / 1e2) / 1e18;
       require(crownPrice > 0, "CROWN price can not be zero!");
       if (crownReward > 0) { 
           uint256 dividendAmount = ((crownReward * crownPrice) / 1e18) / (1e18 / 10 ** decimalOfStableCoin);
           stakeInfo[stakeHolder].dividend += dividendAmount; // If admin execute distribute function multiple times will lead to overflow dividend amount
           stakeInfo[stakeHolder].crownReward -= reward;
       }
    }
   
    function updateStableCoin(string memory currency) internal {
       if (keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC"))) {
            stableCoinAddress = address(usdc);
       } else {
            stableCoinAddress = address(usdt);
       }
    }
    
    function setStakingPeriod (uint256 periodInDay) public onlyOwner returns(bool) {
        startDate = block.timestamp;
        endDate = startDate + (periodInDay * 1 minutes);
        return true;
    } 

    function addStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
        bool _isStaking = isStaking[stakeHolder];
        if(!_isStaking) {
           stakeholders.push(stakeHolder);
           isStaking[stakeHolder] = true;
       }
    }

    function removeStakeholder(address stakeHolder) internal validAddress(stakeHolder) {
        bool _isStaking = isStaking[stakeHolder];
        if(_isStaking){
           isStaking[stakeHolder] = false;
        }
    }
    
//-------------------------------- Main Staking Functions ---------------------------------------------

   function depositStake(address stakeHolder, uint256 amount) public validAddress(stakeHolder) onlyWithinStakePeriod {
       uint256 crownBalance = balanceOf(stakeHolder);
       if (amount > 0) {
           require(crownBalance >= amount,"Not enough token to stake!");
           require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
           _transfer(stakeHolder, address(this), amount);
           if (stakeInfo[stakeHolder].amount == 0) {
               addStakeholder(stakeHolder);
           }
           stakeInfo[stakeHolder].amount += amount;
           stakeInfo[stakeHolder].crownReward += amount;
           emit DepositStake(stakeHolder, amount, block.timestamp);
       }
   }

   function withdrawStake(address stakeHolder, uint256 amount) public validAddress(stakeHolder) onlyAfterPeriod {
       if (amount > 0) { 
           require(stakeInfo[stakeHolder].amount >= amount, "Not enough staking to be removed!");
           require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
           (bool success) = transfer(stakeHolder, amount); 
           require(success);
           stakeInfo[stakeHolder].amount -= amount;
           if (stakeInfo[stakeHolder].amount == 0) { 
               removeStakeholder(stakeHolder);
           }
           emit WithdrawStake(stakeHolder, amount, block.timestamp);
       }
   }
   
   function emergencyWithdrawStake(address stakeHolder) public validAddress(stakeHolder) onlyAfterPeriod {
       uint256 stakeAmount = stakeInfo[stakeHolder].amount;
       require(stakeAmount > 0, "Not enough crown staked to be withdraw!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       (bool success) = transfer(stakeHolder, stakeAmount); 
       require(success);
       stakeInfo[stakeHolder].amount -= stakeAmount;
       if (stakeInfo[stakeHolder].amount == 0) { 
           removeStakeholder(stakeHolder);
       }
       emit WithdrawStake(stakeHolder, stakeAmount, block.timestamp);
   }
   
   function distributeDividend(string memory currency, uint256 dividendRate, uint256 crownUSDPrice) public onlyOwner {
       assert(keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC")) || keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDT")));
       updateStableCoin(currency);
       uint256 dividendSupply = getDividendSupply();
       require(dividendSupply > 0, "Insufficient dividend supply!");
       require(dividendRate > 0, "Dividend rate can not be zero!");
       require(crownUSDPrice > 0, "Crown token price can not be zero!");
       updateCrownPrice(crownUSDPrice);
       updateDividendRate(dividendRate);
   }
   
   function emergencyWithdrawDividend(address stakeHolder, string memory currency) public {
       uint256 dividendAmount = stakeInfo[stakeHolder].dividend;
       uint256 dividendSupply = getDividendSupply();
       require(dividendSupply > 0, "Withdraw amount exceed dividend supply!");
       require(dividendAmount > 0, "Withdraw amount exceed dividend balance!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       assert(keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC")) || keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDT")));
       if (dividendAmount > 0) {
           if (keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC"))) {
                (bool success) = IUSDC(usdc).transfer(stakeHolder, dividendAmount);
                require(success);
           } else {
                IUSDT(usdt).transfer(stakeHolder, dividendAmount);
           }
           stakeInfo[stakeHolder].dividend -= dividendAmount;
           dividendList.push(Dividend(address(this), stakeHolder, dividendAmount, currency, block.timestamp));
           dividendHistory[stakeHolder].push(Dividend(address(this), stakeHolder, dividendAmount, currency, block.timestamp));
           emit DividendWithdrawal(stakeHolder, dividendAmount, block.timestamp); 
       } else {
           revert("Withdraw amount can not be zero!");
       }
   }
   
   function withdrawDividend(address stakeHolder, string memory currency, uint256 amount) public validAddress(stakeHolder) onlyAfterPeriod {
       uint256 dividendAmount = stakeInfo[stakeHolder].dividend;
       uint256 dividendSupply = getDividendSupply();
       require(dividendSupply >= amount && dividendSupply > 0, "Withdraw amount exceed dividend supply!");
       require(dividendAmount >= amount && dividendAmount > 0, "Withdraw amount exceed dividend balance!");
       require(msg.sender == owner() || msg.sender == stakeHolder, "Just an admin & stakeHolder can remove stake!");
       assert(keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC")) || keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDT")));
       if (amount > 0) {
           if (keccak256(abi.encodePacked(currency)) == keccak256(abi.encodePacked("USDC"))) {
                (bool success) = IUSDC(usdc).transfer(stakeHolder, amount);
                require(success);
           } else {
                IUSDT(usdt).transfer(stakeHolder, amount);
           }
           stakeInfo[stakeHolder].dividend -= amount;
           dividendList.push(Dividend(address(this), stakeHolder, amount, currency, block.timestamp));
           dividendHistory[stakeHolder].push(Dividend(address(this), stakeHolder, amount, currency, block.timestamp));
           emit DividendWithdrawal(stakeHolder, amount, block.timestamp); 
       } else {
           revert("Withdraw amount can not be zero!");
       }
   }
}