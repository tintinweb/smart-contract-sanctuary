/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

/**
 $TRI - Tritoken
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.10;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner() {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TRI is Context, IERC20, Ownable {


    using SafeMath for uint256;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e8 * 10 ** 9;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string private constant _name = "Tri Token";
    string private constant _symbol = "TRI";
    
    uint private constant _decimals = 9; 
    uint256 private _treasuryFee = 6;
    uint256 private _previousTreasuryFee = _treasuryFee;
    address payable private _feeAddress;

    bool private _initialized = false; // init first
    bool private _noFeeMode = false; // no fee is false, so we take the fee
    bool private _tradingOpen = false; // fail tx if not open
    uint256 private _launchTime;

    modifier handleFees(bool takeFee) {
        if (!takeFee) _removeAllFees();
        _;
        if (!takeFee) _restoreAllFees();
    }
    
    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[payable(0x000000000000000000000000000000000000dEaD)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromTraffic(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        //approve the exhange or someone (spender) to spend amount
        //do not approve spending outside current balance (unlimited allowances), 
        require(amount <= balanceOf(_msgSender()), "Not enough balance to approve unlimited spending" );
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        //check that we have balance, just in case and are allowed
        require(amount <= balanceOf(sender));
        require(amount <= _allowances[sender][msg.sender]);
      
         // reduce allowance in case not all is spent
        if( _allowances[sender][msg.sender] - amount > 0 ){
         _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        } else {
         _allowances[sender][msg.sender] = 0;
        }
        // do transfer 
        _transfer(sender, recipient, amount);
        return true;
    }

    function _tokenFromTraffic(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _removeAllFees() private {
        require(_treasuryFee > 0);
        _previousTreasuryFee = _treasuryFee;
        _treasuryFee = 0;
    }
    
    function _restoreAllFees() private {
        _treasuryFee = _previousTreasuryFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount > 0, "Approve amount must be greater than zero");
        require(!_isBot[owner], "Your address has been marked as a bot, please contact admin");
        require(_tradingOpen, "Trading not open yet!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBot[from], "Your address has been marked as a bot, please contact admin");
        require(_tradingOpen, "Trading not open yet!");
        /* Check balance and uint256 overflows */
        uint256 from_balance = balanceOf(from);
        uint256 to_balance = balanceOf(to);
        require(from_balance >= amount && to_balance + amount >= to_balance, "Error in transaction, balances don't match!");

        // take no fee if is in the list or we are in no-tax more
        // takeFee is local so no re-entrancy states shared
        bool takeFee = false;
        if ( !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !_noFeeMode
        ) {
            takeFee = true;
            if (block.timestamp == _launchTime) _isBot[to] = true;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private handleFees(takeFee) {

        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tTeam) = _getValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        
        _takeTeam(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
     
        (uint256 tTransferAmount, uint256 tTeam) = _getTValues(tAmount, _treasuryFee);
     
        uint256 currentRate =  _getRate();
     
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tTeam, currentRate);
     
        return (rAmount, rTransferAmount, tTransferAmount, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 TreasuryFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(TreasuryFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTeam);
        return (rAmount, rTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    
    function initContract(address payable feeAddress) external onlyOwner() {
        require(!_initialized,"Contract has already been initialized");
        
        _feeAddress = feeAddress;
        _isExcludedFromFee[_feeAddress] = true;
        _initialized = true;
    }

    function openTrading() external onlyOwner() {
        require(_initialized, "Contract must be initialized");
        _tradingOpen = true;
        _launchTime = block.timestamp;
    }

    function setFeeWallet(address payable feeWalletAddress) external onlyOwner() {
        _isExcludedFromFee[_feeAddress] = false;
        _feeAddress = feeWalletAddress;
        _isExcludedFromFee[_feeAddress] = true;
    }

    function excludeFromFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = true;
    }
    
    function includeToFee(address payable ad) external onlyOwner() {
        _isExcludedFromFee[ad] = false;
    }
    
    function setNoFeeMode(bool onoff) external onlyOwner() {
        _noFeeMode = onoff;
    }
    

    function setTreasuryFee(uint256 fee) external onlyOwner() {
        require(fee <= 10, "Treasury fee cannot more than 10%");
        _treasuryFee = fee;
    }

    //setting bots
    function setBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = true;
        }
    }
    
    function delBots(address[] memory bots_) public onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }
    
    function isBot(address ad) public view returns (bool) {
        return _isBot[ad];
    }

    function isExcludedFromFee(address ad) public view returns (bool) {
        return _isExcludedFromFee[ad];
    }
      
    //Manual fee withdraw function
     function withdrawFeesManual() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this)); 
        this.transfer( _feeAddress, contractBalance);
    }

    // get balance
     function listCurrentFees() public onlyOwner view returns (uint256) {
        uint256 contractBalance = balanceOf(address(this)); 
        return contractBalance;
    }

    receive() external payable {}
 
}