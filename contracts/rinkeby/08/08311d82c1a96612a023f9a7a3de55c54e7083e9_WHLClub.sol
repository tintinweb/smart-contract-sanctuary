/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT

/*
    WHALES ROOM CLUB
    WHL Staking Contract
    --------------------
    10% buy fee
    10% sell fee 
    2% referral fee 
    1% transfer fee 
*/

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

abstract contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "!zero address");
        
        owner = newOwner;
        
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract WHLClub is Ownable {

    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 10000e18; // 10k
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    bool public onlyAmbassadors = true;
    uint256 ACTIVATION_TIME = 1617048000; // 4/5/2021 @ 20:00 (UTC)
    
    modifier antiEarlyWhale(uint256 _amountOfSTAT, address _customerAddress) {
        if (block.timestamp >= ACTIVATION_TIME) {
            onlyAmbassadors = false;
        }
        
        if (onlyAmbassadors) {
            require((ambassadors_[_customerAddress] == true && (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfSTAT) <= ambassadorMaxPurchase_), "!required condition");
            ambassadorAccumulatedQuota_[_customerAddress] = ambassadorAccumulatedQuota_[_customerAddress] + _amountOfSTAT;
            _;
        } else {
            onlyAmbassadors = false;
            _;
        }
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0, "!only token holders");
        _;
    }

    modifier onlyDivis {
        require(myDividends(true) > 0, "!only divis");
        _;
    }

    event onDistribute(address indexed customerAddress, uint256 price);
    event onTokenPurchase(address indexed customerAddress, uint256 incomingSTAT, uint256 tokensMinted, address indexed referredBy, uint timestamp);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 statEarned, uint timestamp);
    event onReinvestment(address indexed customerAddress, uint256 statReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 statWithdrawn);
    event onTransfer(address indexed from, address indexed to, uint256 tokens);

    string public name = "WHL Club";
    string public symbol = "WHLC";
    uint8 constant public decimals = 18;
    uint256 internal entryFee_ = 10; // 10%
    uint256 internal transferFee_ = 1;
    uint256 internal exitFee_ = 10; // 10%
    uint256 internal referralFee_ = 20; // 2% of the 10% fee 
    uint256 constant internal magnitude = 2 ** 64;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => uint256) internal payoutsTo_;
    mapping(address => uint256) internal invested_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public totalHolder = 0;
    uint256 public totalDonation = 0;
    address public erc20;

    constructor(address _token) {
        erc20 = _token;
    }

    function checkAndTransferSTAT(uint256 _amount) private {
        require(IERC20(erc20).transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function distribute(uint256 _amount) public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferSTAT(_amount);
        totalDonation += _amount;
        profitPerShare_ = profitPerShare_ + (_amount * magnitude) / tokenSupply_;
        emit onDistribute(msg.sender, _amount);
    }

    function buy(uint256 _amount, address _referredBy) public returns (uint256) {
        checkAndTransferSTAT(_amount);
        
        return purchaseTokens(_referredBy, msg.sender, _amount);
    }

    function buyFor(uint256 _amount, address _customerAddress, address _referredBy) public returns (uint256) {
        checkAndTransferSTAT(_amount);
        return purchaseTokens(_referredBy, _customerAddress, _amount);
    }

    function reinvest() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += _dividends * magnitude;
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(address(0), _customerAddress, _dividends);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += _dividends * magnitude;
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        IERC20(erc20).transfer(_customerAddress, _dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress], "!invalid");
        
        uint256 _dividends = _amountOfTokens * exitFee_ / 100;
        uint256 _taxedSTAT = _amountOfTokens - _dividends;
        
        tokenSupply_ = tokenSupply_ - _amountOfTokens;
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] - _amountOfTokens;
        
        uint256 _updatedPayouts = profitPerShare_ * _amountOfTokens + _taxedSTAT * magnitude;
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        
        if (tokenSupply_ > 0) {
            profitPerShare_ = profitPerShare_ + (_dividends * magnitude) / tokenSupply_;
        }
        
        emit onTransfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedSTAT, block.timestamp);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress], "!transfer failed");
        
        if (myDividends(true) > 0) {
            withdraw();
        }
        
        uint256 _tokenFee = _amountOfTokens * transferFee_ / 100;
        uint256 _taxedTokens = _amountOfTokens - _tokenFee;
        uint256 _dividends = _tokenFee;
        
        tokenSupply_ = tokenSupply_ - _tokenFee;
        
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] - _amountOfTokens;
        tokenBalanceLedger_[_toAddress] = tokenBalanceLedger_[_toAddress] + _taxedTokens;
        
        payoutsTo_[_customerAddress] -= profitPerShare_ * _amountOfTokens;
        payoutsTo_[_toAddress] += profitPerShare_ * _taxedTokens;
        
        profitPerShare_ = profitPerShare_ + (_dividends * magnitude) / tokenSupply_;
        
        emit onTransfer(_customerAddress, _toAddress, _taxedTokens);
        
        return true;
    }

    function setName(string memory _name) onlyOwner public {
        name = _name;
    }
    
    function setSymbol(string memory _symbol) onlyOwner public {
        symbol = _symbol;
    }
    
    function totalPowerBalance() public view returns (uint256) {
        return IERC20(erc20).balanceOf(address(this));
    }
    
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
    }
    
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (profitPerShare_ * tokenBalanceLedger_[_customerAddress] - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    function sellPrice() public view returns (uint256) {
        uint256 _stat = 1e18;
        uint256 _dividends = _stat * exitFee_ / 100;
        uint256 _taxedSTAT = _stat - _dividends;
        
        return _taxedSTAT;
    }

    function buyPrice() public view returns (uint256) {
        uint256 _stat = 1e18;
        
        uint256 _dividends = _stat * entryFee_ / 100;
        uint256 _taxedSTAT = _stat + _dividends;
        
        return _taxedSTAT;
    }
    
    function calculateTokensReceived(uint256 _powerToSpend) public view returns (uint256) {
        uint256 _dividends = _powerToSpend * entryFee_ / 100;
        uint256 _amountOfTokens = _powerToSpend - _dividends;
        
        return _amountOfTokens;
    }
    
    function calculatePowerReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_, "!invalid");
        
        uint256 _dividends = _tokensToSell * exitFee_ / 100;
        uint256 _taxedSTAT = _tokensToSell - _dividends;
        
        return _taxedSTAT;
    }
    
    function getInvested() public view returns (uint256) {
        return invested_[msg.sender];
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingSTAT) internal antiEarlyWhale(_incomingSTAT, _customerAddress) returns (uint256) {
        if (getInvested() == 0) {
            totalHolder++;
        }
        
        invested_[_customerAddress] += _incomingSTAT;
        
        uint256 _undividedDividends = _incomingSTAT * entryFee_ / 100;
        uint256 _referralBonus = _undividedDividends * referralFee_ / 100;
        uint256 _dividends = _undividedDividends - _referralBonus;
        uint256 _amountOfTokens = _incomingSTAT - _undividedDividends;
        uint256 _fee = _dividends * magnitude;
        
        require(_amountOfTokens > 0 && (_amountOfTokens + tokenSupply_) > tokenSupply_, "!invalid");
        
        if (_referredBy != address(0) && _referredBy != _customerAddress) {
            referralBalance_[_referredBy] = referralBalance_[_referredBy] + _referralBonus;
        } else {
            _dividends = _dividends + _referralBonus;
            _fee = _dividends * magnitude;
        }
        
        if (tokenSupply_ > 0) {
            tokenSupply_ = tokenSupply_ + _amountOfTokens;
            uint256 _stepProfitPerShare = (_dividends * magnitude / tokenSupply_);
            profitPerShare_ += _stepProfitPerShare;
            _fee = _fee - (_fee - (_amountOfTokens * _stepProfitPerShare));
        } else {
            tokenSupply_ = _amountOfTokens;
        }
        
        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress] + _amountOfTokens;
        
        uint256 _updatedPayouts = profitPerShare_ * _amountOfTokens - _fee;
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        emit onTransfer(address(0), _customerAddress, _amountOfTokens);
        emit onTokenPurchase(_customerAddress, _incomingSTAT, _amountOfTokens, _referredBy, block.timestamp);
        
        return _amountOfTokens;
    }

    function multiData() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalPowerBalance(), totalSupply(), balanceOf(msg.sender), IERC20(erc20).balanceOf(msg.sender), dividendsOf(msg.sender), buyPrice(), sellPrice());
    }
}