/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;


contract LENNY {

    // All string state variables
    string private _name = "Lenny Face Coin"; //
    string private _symbol = "LENNY"; //

    // All address state variables 
    address private _contributionAddress; //

    // All boolean state variables
    bool private _communityContributionEnabled = true; //

    // All integer variables
    uint8 private _decimals = 10; //
    uint256 private _maxTokenPerAddress = 5000000000 * 10 ** 10; //
    uint256 private _totalSupply = 115000000000 * 10**10; //
    uint8 public _contribution = 1; //
    uint256 _maxContribution = 100000 * 10 ** 10; //

    // All mapping
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromContribution;
    mapping (address => bool) private _isExcludedFromRestriction;

    // All arrays
    address[] private _excludedContribution;
    address[] private _excludedRestriction;

    // All events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // All functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address sender, address spender) public view virtual returns (uint256) {
        return _allowances[sender][spender];
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

    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address sender, address spender, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Lenny Face Coin DeFi functions
    
    function communityContributionEnabled() public view returns (bool) {
        return _communityContributionEnabled;
    }

    function contribution() public view returns (uint256) {
        return _contribution;
    }
    function maxContribution() public view returns (uint256) {
        return _maxContribution;
    }
    function maxTokenPerAddress() public view returns (uint256) {
        return _maxTokenPerAddress;
    }

    function excludedContribution() public view returns (address[] memory) {
        return _excludedContribution;
    }

    function contributionAddress() public view returns (address){
        return _contributionAddress;
    }

    function isExcludedFromContribution(address account) public view returns (bool) {
        return _isExcludedFromContribution[account];
    }

    function excludeFromContribution(address account) public onlyOwner {
        require(!_isExcludedFromContribution[account], "Account is already excluded from contribution");
        _isExcludedFromContribution[account] = true;
        _excludedContribution.push(account);
    }

    function includeInContribution(address account) public onlyOwner {
        _isExcludedFromContribution[account] = false;
        for (uint256 i = 0; i < _excludedContribution.length; i++) {
            if(_excludedContribution[i]==account){
                delete _excludedContribution[i];
            }
        }
    }

    function isExcludedFromRestriction(address account) public view returns (bool) {
        return _isExcludedFromRestriction[account];
    }

    function excludeFromRestriction(address account) public onlyOwner {
        require(!_isExcludedFromRestriction[account], "Account is already excluded from restriction");
        _isExcludedFromRestriction[account] = true;
        _excludedRestriction.push(account);
    }
    
    function includeInRestriction(address account) public onlyOwner {
        _isExcludedFromRestriction[account] = false;
        for (uint256 i = 0; i < _excludedRestriction.length; i++) {
            if(_excludedRestriction[i]==account){
                delete _excludedRestriction[i];
            }
        }
    }

    function excludedRestriction() public view returns (address[] memory) {
        return _excludedRestriction;
    }

    function setCommunityContribution(bool _enabled) external onlyOwner {
        _communityContributionEnabled = _enabled;
    }

    function setContributionFeePerThousand(uint8 contributionFee) external onlyOwner() {
        require(contributionFee<=50, "Contribution Fee can not be higher than 5%");
        _contribution = contributionFee;
    }

    function setMaxContribution(uint256 _maxCont) public onlyOwner {
        _maxContribution = _maxCont;
    }

    function setContributionAddress(address _newAddress) public onlyOwner {
        _contributionAddress = _newAddress;
    }

    function setMaxTokenPerAddress(uint256 _maxToken) public onlyOwner {
        _maxTokenPerAddress = _maxToken;
    }

    function _calculateContributionFee(address _sender, uint256 _amount) private view returns (uint256) {
        uint fee ;
        if(_communityContributionEnabled && !_isExcludedFromContribution[_sender]){
            fee = _amount * _contribution / 1000;
        } else {
            fee = 0;
        }
        if (fee >= _maxContribution){
            fee = _maxContribution;
        }
        return fee;
    }

    function _takeContribution (uint tContribution) private {
        _balances[_contributionAddress] += tContribution;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        uint256 recipientBalance = _balances[recipient];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 feePaid = _calculateContributionFee(sender, amount);
        uint256 amount_to_receive = amount - feePaid;

        require(recipientBalance <= _maxTokenPerAddress, "The account will own to much tokens");

        if (feePaid > 0){
            _takeContribution(feePaid);
        }

        _balances[sender] = senderBalance - amount;

        _balances[recipient] += amount_to_receive;

        emit Transfer(sender, recipient, amount_to_receive);
    }

    // Context
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // Ownership
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    

    function owner() public view virtual returns (address) {
        return _owner;
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

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Function reserved to Admin");
        _;
    }
    
    
    constructor () {

        _setOwner(_msgSender());

        _balances[_msgSender()] = _totalSupply;

        _contributionAddress = 0x79B9C03fdab99b27A249251236cbFFf7178fed71;

        _isExcludedFromContribution[owner()] = true;
        _isExcludedFromContribution[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

}