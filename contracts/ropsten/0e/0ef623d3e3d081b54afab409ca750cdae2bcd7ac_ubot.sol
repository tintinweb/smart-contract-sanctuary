/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;

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


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.0;

abstract contract Sales is Ownable {

    uint256 private privateSaleTimestamp;
    uint256 private ICOSaleTimestamp;
    uint256 private publicSaleTimestamp;
    
    struct SalesInfo{
        uint256 numberofToken;
        uint256 StartSaleTimestamp;
        uint256 EndSaleTimestamp;
        uint256 Raised;
        uint256 minSale;
        uint256 maxSale;
        uint256 Rate;
        uint256 maxSaleRate;
        uint256 releaseTimestamp;
    }
    
    mapping(uint => SalesInfo) private SalesInfos;
    
    constructor() {
        privateSaleTimestamp = block.timestamp;
        ICOSaleTimestamp = block.timestamp + 70 days;
        publicSaleTimestamp = block.timestamp + 100 days;
        
        _setSalesInfo(1, 6000000000 * (uint256(10) ** 18), privateSaleTimestamp, privateSaleTimestamp + 15 days, 0, 0.05 ether, 2 ether, 25000000, 31250000, publicSaleTimestamp + 60 days);
        _setSalesInfo(2, 6000000000 * (uint256(10) ** 18), privateSaleTimestamp + 15 days, privateSaleTimestamp + 30 days, 0, 0.05 ether, 1.5 ether, 12500000, 15000000, publicSaleTimestamp + 45 days);
        _setSalesInfo(3, 6000000000 * (uint256(10) ** 18), privateSaleTimestamp + 30 days, privateSaleTimestamp + 45 days, 0, 0.05 ether, 1 ether, 8333333, 9583332, publicSaleTimestamp + 30 days);
        _setSalesInfo(4, 6000000000 * (uint256(10) ** 18), privateSaleTimestamp+ 45 days, privateSaleTimestamp + 60 days, 0, 0.05 ether, 0.5 ether, 6250000, 6875000, publicSaleTimestamp + 15 days);
        _setSalesInfo(5, 42000000000 * (uint256(10) ** 18), ICOSaleTimestamp, ICOSaleTimestamp + 30 days, 0, 1, 0.5 ether, 5000000, 5000000, publicSaleTimestamp);
        _setSalesInfo(6, 120000000000 * (uint256(10) ** 18), publicSaleTimestamp, publicSaleTimestamp + 90 days, 0, 1, 1000 ether, 4166666, 4166666, publicSaleTimestamp);
    }
    
    
    function buyTokens(uint index_, address Referrer_, address Beneficiary_) external virtual payable returns (bool) {}
    
    function setSalesInfo(uint index_, uint256 numberofToken_, uint256 StartSaleTimestamp_, uint256 EndSaleTimestamp_, uint256 Raised_, uint256 minSale_, uint256 maxSale_, uint256 Rate_, uint256 maxSaleRate_, uint256 releaseTimestamp_) public virtual onlyOwner {
        _setSalesInfo(index_, numberofToken_, StartSaleTimestamp_, EndSaleTimestamp_, Raised_, minSale_, maxSale_, Rate_, maxSaleRate_, releaseTimestamp_);
    }
    
    function _setSalesInfo(uint index_, uint256 numberofToken_, uint256 StartSaleTimestamp_, uint256 EndSaleTimestamp_, uint256 Raised_, uint256 minSale_, uint256 maxSale_, uint256 Rate_, uint256 maxSaleRate_, uint256 releaseTimestamp_) internal virtual {
        SalesInfos[index_].numberofToken = numberofToken_;
        SalesInfos[index_].StartSaleTimestamp = StartSaleTimestamp_;
        SalesInfos[index_].EndSaleTimestamp = EndSaleTimestamp_;
        SalesInfos[index_].Raised = Raised_;
        SalesInfos[index_].minSale = minSale_;
        SalesInfos[index_].maxSale = maxSale_;
        SalesInfos[index_].Rate = Rate_;
        SalesInfos[index_].maxSaleRate = maxSaleRate_;
        SalesInfos[index_].releaseTimestamp = releaseTimestamp_;
    }
    
    function getSalesInfo(uint index) public view virtual returns (SalesInfo memory sale) {
        return SalesInfos[index];
    }
    
    
    
    function _setnumberofToken(uint index, uint256 numberofToken_) internal virtual {
        SalesInfos[index].numberofToken = numberofToken_;
    }
    
    function _setRaised(uint index, uint256 Raised_) internal virtual {
        SalesInfos[index].Raised = Raised_;
    }
    
    function getnumberofToken(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].numberofToken;
    }
    
    function getStartSaleTimestamp(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].StartSaleTimestamp;
    }
    
    function getEndSaleTimestamp(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].EndSaleTimestamp;
    }
    
    function getRaised(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].Raised;
    }
    
    function getminSale(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].minSale;
    }
    
    function getmaxSale(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].maxSale;
    }
    
    function getRate(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].Rate;
    }
    
    function getmaxSaleRate(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].maxSaleRate;
    }
    
    function getReleaseTimestamp(uint index) internal view virtual returns (uint256) {
        return SalesInfos[index].releaseTimestamp;
    }
}


pragma solidity ^0.8.0;

contract ubot is Context, IERC20, IERC20Metadata, Ownable, Sales {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    struct UserInfo {
        uint256 amount;
        uint256 raised;
    }
    
    mapping(address => mapping(uint => UserInfo)) private UserInfos;
    mapping(address => address) private UserReferrer;
    
    uint256[] private refIncomePercent;
    
    uint256 private TotalMint;
    //*******
    uint256 private TotalStake;
    uint256 private TotalShare;
    mapping(address => mapping(uint => uint256)) private SnapShare;
    
    
    constructor() {
        _name = "ubot test7";
        _symbol = "ubot7";
        _totalSupply = 910000000000 * (uint256(10) ** 18);
        
        refIncomePercent.push(10);
        refIncomePercent.push(6);
        refIncomePercent.push(5);
        refIncomePercent.push(4);
        refIncomePercent.push(3);
        refIncomePercent.push(2);

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function burn(uint256 amount) public virtual onlyOwner {
        _burn(_msgSender(), amount);
    }
    
    function mint(uint256 amount) public virtual onlyOwner {
        _mint(_msgSender(), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
    
    function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(_msgSender(), amount);
    }
    
    function transferAnyETH(uint256 amount) public onlyOwner {
        (bool sent, ) = _msgSender().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    
    //*****
    function Distribute(uint256 RewardperShare) public virtual onlyOwner returns (bool) {
        require(TotalMint <= 210000000000 * (uint256(10) ** 18), "no mint");
        require(TotalStake > 0, "no stake");
        TotalShare += RewardperShare;
        
        emit Distributed(RewardperShare, TotalShare);
        return true;
    }
    
    function buyTokens(uint index_, address Referrer_, address Beneficiary_) public virtual override payable returns (bool) {
        require(msg.value >= getminSale(index_), "buyTokens: min");
        require(msg.value <= getmaxSale(index_), "buyTokens: max");
        require(block.timestamp >= getStartSaleTimestamp(index_), "buyTokens: start");
        require(block.timestamp <= getEndSaleTimestamp(index_), "buyTokens: end");
        
        uint256 amountTokens = 0;
        uint256 amountTokenswithoutbonus = 0;
        
        if (msg.value == getmaxSale(index_)) {
            amountTokens = msg.value * getmaxSaleRate(index_);
            amountTokenswithoutbonus = msg.value * getRate(index_);
        }
        else {
            amountTokens = msg.value * getRate(index_);
            amountTokenswithoutbonus = amountTokens;
        }
        
        require(amountTokens <= getnumberofToken(index_), "buyTokens: empty");
        //require(UserInfos[Beneficiary_][index_].raised + msg.value <= getmaxSale(index_), "buyTokens: max buy");
        require(UserInfos[Beneficiary_][index_].amount == 0, "buyTokens: double buy");
        
        _setnumberofToken(index_, getnumberofToken(index_) - amountTokenswithoutbonus);
        _setRaised(index_, getRaised(index_) + msg.value);


        UserReferrer[Beneficiary_] = Referrer_;
        
        UserInfos[Beneficiary_][index_].raised += msg.value;
        UserInfos[Beneficiary_][index_].amount = amountTokens;
        
        distributeReferralIncome(Beneficiary_, amountTokens, index_);
        
        SnapShare[Beneficiary_][index_] = TotalShare;
        TotalStake += amountTokens;

        emit TokenBought(Beneficiary_, index_, amountTokens, Referrer_);
        return true;
    }
    
    function distributeReferralIncome(address _user, uint256 _amount, uint _phaseNo) internal returns (uint256) {
        uint256 sumDistributed = 0;
        address ref = UserReferrer[_user];
        
        for (uint256 i = 0; i < 6; i++) {
            if (ref == address(0)) {
                break;
            }
            
            uint256 income = _amount * refIncomePercent[i] / 100;
            
            UserInfos[ref][_phaseNo].amount += income;
            TotalStake += income;
            sumDistributed += income;
            emit ReferralIncomeDistributed(_user, int256(i+1), income, ref);
            
            ref = UserReferrer[ref];
        }
        
        return sumDistributed;
    }
    
    function getUserInfo(uint _phaseNo, address _user) public view returns (UserInfo memory user) {
        return UserInfos[_user][_phaseNo];
    }
    
    function getTotalStake() public view returns (uint256) {
        return TotalStake;
    }
    
    function getTotalMint() public view returns (uint256) {
        return TotalMint;
    }
    
    function withdraw(uint _phaseNo) public virtual returns (bool) {
        require(block.timestamp > getReleaseTimestamp(_phaseNo), "withdraw: time");
        require(UserInfos[_msgSender()][_phaseNo].amount > 0, "withdraw: token");
        
        uint256 reward = UserInfos[_msgSender()][_phaseNo].amount * (TotalShare - SnapShare[_msgSender()][_phaseNo]) / (uint256(10) ** 18);
        uint256 amount = UserInfos[_msgSender()][_phaseNo].amount;
        
        _transfer(address(this), _msgSender(), UserInfos[_msgSender()][_phaseNo].amount + reward);
        TotalStake -= UserInfos[_msgSender()][_phaseNo].amount;
        UserInfos[_msgSender()][_phaseNo].amount = 0;
        
        uint256 referrerReward = distributeReferralIncome(_msgSender(), reward, _phaseNo);
        TotalMint += reward + referrerReward;
        
        emit withdrawed(_msgSender(), _phaseNo, amount, reward);
        return true;
    }
    
    //only phase 7
    function StakeToken(uint _phaseNo, uint256 amountTokens) public virtual returns (bool) {
        require(UserInfos[_msgSender()][_phaseNo].amount == 0, "StakeToken: double stake");
        
        _transfer(_msgSender(), address(this), amountTokens);
        UserInfos[_msgSender()][_phaseNo].amount = amountTokens;
        
        SnapShare[_msgSender()][_phaseNo] = TotalShare;
        TotalStake += amountTokens;
        
        emit TokenStaked(_msgSender(), _phaseNo, amountTokens);
        return true;
    }
    
    event TokenStaked(address Sender, uint phaseNo, uint256 amountTokens);
    event withdrawed(address Sender, uint phaseNo, uint256 amountTokens, uint256 reward);
    event ReferralIncomeDistributed(address sender, int256 level, uint256 income, address ref);
    event Distributed(uint256 RewardperShare, uint256 TotalShare);
    event TokenBought(address Sender, uint phaseNo, uint256 amountTokens, address Referrer);
}