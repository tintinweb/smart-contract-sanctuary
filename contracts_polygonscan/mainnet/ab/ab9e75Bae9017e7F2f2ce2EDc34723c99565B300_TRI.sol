/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

/**
 $TRI
*/

// SPDX-License-Identifier: MIT

// time of writing warning
// Version 0.8.11 necessitates a version too recent to be trusted. Deployed with 0.8.7
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view returns (address) {
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

    function transferOwnership(address newOwner) external virtual onlyOwner() {
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

    // removing dead code warning
    //Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    /*
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    */
}

contract TRI is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    uint256 private constant _MAX_INT = 2**256 - 1;
    mapping (address => uint256) internal balance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBot;

    uint256 private constant  _CIRCULATION = 1e8 * 10 ** 9;
   
    string private constant _NAME = "Triangle";
    string private constant _SYMBOL = "TRI";
    
    uint private constant _DECIMALS = 9; 
    uint256 private _treasuryFee = 6; // init with same
    uint256 private _previousTreasuryFee = 6; // init with same
    address payable private _feeAddress; 

    bool private _initialized = false; // init first
    bool private _noFeeMode = false; // no fee is false, so we take the fee
    bool private _tradingOpen = false; // fail tx if not open
    bool private _autoWithDraw = false; // autowithdraw to treasury 
   

    // events which are emitted in case transfer fee is changed or autoupdate for transparency
    // Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-events-arithmetic 
    event TreasuryFeeChanged(uint256 newValue); // Event
    event AutoWithDrawLimitpdated(bool onoff); // Event

    modifier handleFees(bool takeFee) {
        if (!takeFee) _removeAllFees();
        _;
        if (!takeFee) _restoreAllFees();
    }
    
    constructor () {
        balance[_msgSender()] = _CIRCULATION;
        _isExcludedFromFee[owner()] = true;
        emit Transfer(address(0), _msgSender(), _CIRCULATION);
    }

    function name() external pure returns (string memory) {
        return _NAME;
    }

    function symbol() external pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() external pure returns (uint) {
        return _DECIMALS;
    }

    function totalSupply() external pure override returns (uint256) {
        return _CIRCULATION;
    }

    function balanceOf(address account) public view override returns (uint256) {
        require(account != address(0), "Address cannot be zero");
        return balance[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address a1, address spender) external view override returns (uint256) {
        return _allowances[a1][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        // workaround as defined in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_allowances[_msgSender()][spender] == 0);
        //do not approve spending outside current balance (unlimited allowances), 
        require(amount <= balanceOf(_msgSender()), "Not enough balance to approve unlimited spending" );
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // slither 0.8.2 requires the function to be called increaseApproval for 
    // race_condition_mitigated is passed
    function increaseApproval(address spender, uint256 value) external virtual returns (bool) {
        uint256 current_allowance = _allowances[_msgSender()][spender];
        require(current_allowance + value <= _MAX_INT , "Cannot request this much!");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + value);
        return true;
    }

    function decreaseApproval(address spender, uint256 value) external virtual returns (bool) {
        uint256 current_allowance = _allowances[_msgSender()][spender]; 
        require(current_allowance >= value, "ERC20: decreased allowance below zero");
        unchecked {
        _approve(_msgSender(), spender, current_allowance - value);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        //check that we have balance, just in case and are allowed
        require(amount <= balanceOf(sender));
        require(amount <= _allowances[sender][msg.sender]);
      
        // reduce allowance from N to 0 and as adviced in approve
        _allowances[sender][msg.sender] = 0;
        
        // do transfer 
        _transfer(sender, recipient, amount);
        return true;
    }
    

    function _removeAllFees() private {
        require(_treasuryFee > 0);
        _previousTreasuryFee = _treasuryFee;
        _treasuryFee = 0;
    }
    
    function _restoreAllFees() private {
        _treasuryFee = _previousTreasuryFee;
    }

    function _approve(address a1, address spender, uint256 amount) private {
        require(a1 != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount > 0, "Approve amount must be greater than zero");
        require(!_isBot[a1], "Your address has been marked as a bot, please contact admin");
        require(_tradingOpen, "Trading not open yet!");

        _allowances[a1][spender] = amount;
        emit Approval(a1, spender, amount);
    }
    

    function _transfer(address from, address to, uint256 tamount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tamount > 0, "Transfer amount must be greater than zero");
        require(!_isBot[from], "Your address has been marked as a bot, please contact admin");
        require(_tradingOpen, "Trading not open yet!");
        
        //Check balance and uint256 overflows 
        uint256 from_balance = balanceOf(from);
        uint256 to_balance = balanceOf(to);
        require(from_balance >= tamount && to_balance + tamount >= to_balance, "Error in transaction, balances don't match!");
    
        // take no fee if is in the list or we are in no-tax more
        // takeFee is local so no re-entrancy states shared
        bool takeFee = false;
        if ( !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !_noFeeMode
        ) {
            takeFee = true;
        }
        
        _tokenTransfer(from, to, tamount, takeFee);
        
        //withdraw automatically to treasury if flag is set 
        //for future automation
        if (_autoWithDraw) {
            withdrawFees();
        }    
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private handleFees(takeFee) {

        (uint256 tTransferAmount, uint256 tTeam) = _calculateValues(tAmount);
        
        balance[sender] = balance[sender].sub(tAmount);
        balance[recipient] = balance[recipient].add(tTransferAmount); 
        _takeTeam(tTeam);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _calculateValues(uint256 tAmount) private view returns (uint256, uint256) {
        
        // transfer and treasury
        (uint256 tTransferAmount, uint256 tTeam) = _getTransferValues(tAmount, _treasuryFee);   
        return (tTransferAmount, tTeam);
    }

    function _getTransferValues(uint256 tAmount, uint256 TreasuryFee) private pure returns (uint256, uint256) {
        uint256 tTeam = tAmount.mul(TreasuryFee).div(100); // 
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
    }


    function _takeTeam(uint256 tTeam) private {
        balance[address(this)] = balance[address(this)].add(tTeam);
    }


    function initContract(address payable feeAddress) external onlyOwner() {
        require(!_initialized,"Contract has already been initialized");
        //Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
        require(feeAddress != address(0), "ERC20: Cannot init withzero address");
        _feeAddress = feeAddress;
        _isExcludedFromFee[_feeAddress] = true;
        _initialized = true;
    }

    function openTrading() external onlyOwner() {
        require(_initialized, "Contract must be initialized");
        _tradingOpen = true;
    }

    function setFeeWallet(address payable feeWalletAddress) external onlyOwner() {
        //Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation
        require(feeWalletAddress != address(0), "Feee wallet cannot be zero address");       
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

    function setAutoWithDraw(bool onoff) external onlyOwner() {
        _autoWithDraw = onoff;
        emit AutoWithDrawLimitpdated(_autoWithDraw);
    }

    function setTreasuryFee(uint256 fee) external onlyOwner() {
        require(fee <= 10, "Treasury fee cannot more than 10%");
        _previousTreasuryFee = _treasuryFee; // store old
        _treasuryFee = fee; // change current 
        emit TreasuryFeeChanged(_treasuryFee);
    }

    //setting bots
    function setBots(address[] memory bots_) external onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = true;
        }
    }
    
    function delBots(address[] memory bots_) external onlyOwner() {
        for (uint i = 0; i < bots_.length; i++) {
            _isBot[bots_[i]] = false;
        }
    }
    
    //Allow to check
    function isBot(address ad) external view returns (bool) {
        return _isBot[ad];
    }

    //Allow to check
    function isExcludedFromFee(address ad) external view returns (bool) {
        return _isExcludedFromFee[ad];
    }

    //Manual fee withdraw function
    function withdrawFeesManual() external onlyOwner() {
        withdrawFees();
    }

    //Manual fee withdraw function
     function withdrawFees() private {
        uint256 contractBalance = balanceOf(address(this));
        balance[_feeAddress] = balance[_feeAddress] + contractBalance;
        balance[address(this)] = 0;
        emit Transfer(address(this), _feeAddress, contractBalance);
    }

    // get balance
     function listCurrentFees() external onlyOwner view returns (uint256) {
        uint256 contractBalance = balanceOf(address(this)); 
        return contractBalance;
    }

}