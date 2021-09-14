/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: Unlicensed
interface IDOSCii {
    function readAuthorizedAddress(address sender) external view returns (address);
    function readEndChangeTime(address sender) external view returns (uint);
    function RegisterCall(address sender, string memory scname, string memory funcname) external returns(bool);
}


pragma solidity ^0.8.6;

contract LENNY {

    // burning address
    address public burningAddress;

    // democratic IDO
    address public addressDOSC;
    address public LastAuthorizedAddress;
    uint public LastChangingTime;

    // All string state variables
    string private _name = "Lenny Face Coin"; //
    string private _symbol = "LENNY"; //

    // All address state variables 
    address public contributionAddress; //

    // All boolean state variables
    bool public communityContributionEnabled = true; //

    // All integer variables
    uint8 private _decimals = 8; //
    uint256 public maxTokenPerAddress = 5000000000 * 10 ** 8; //
    uint256 private _totalSupply = 115000000000 * 10 ** 8; //
    uint8 public contribution = 50; //

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

    function excludedContribution() public view returns (address[] memory) {
        return _excludedContribution;
    }

    function isExcludedFromContribution(address account) public view returns (bool) {
        return _isExcludedFromContribution[account];
    }

    function isExcludedFromRestriction(address account) public view returns (bool) {
        return _isExcludedFromRestriction[account];
    }

    function excludedRestriction() public view returns (address[] memory) {
        return _excludedRestriction;
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

    function burn(address account, uint256 amount) public Demokratia {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public Demokratia {
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

    function excludeFromContribution(address account) public Demokratia {
        require(!_isExcludedFromContribution[account], "Account is already excluded from contribution");
        _isExcludedFromContribution[account] = true;
        _excludedContribution.push(account);
    }

    function includeInContribution(address account) public Demokratia {
        _isExcludedFromContribution[account] = false;
        for (uint256 i = 0; i < _excludedContribution.length; i++) {
            if(_excludedContribution[i]==account){
                delete _excludedContribution[i];
            }
        }
    }

    function excludeFromRestriction(address account) public Demokratia {
        require(!_isExcludedFromRestriction[account], "Account is already excluded from restriction");
        _isExcludedFromRestriction[account] = true;
        _excludedRestriction.push(account);
    }
    
    function includeInRestriction(address account) public Demokratia {
        _isExcludedFromRestriction[account] = false;
        for (uint256 i = 0; i < _excludedRestriction.length; i++) {
            if(_excludedRestriction[i]==account){
                delete _excludedRestriction[i];
            }
        }
    }


    function setCommunityContribution(bool _enabled) public Demokratia {
        communityContributionEnabled = _enabled;
    }

    function setContributionFeePerThousand(uint8 contributionFee) public Demokratia {
        require(contributionFee<=50, "Contribution Fee can not be higher than 5%.");
        require(contributionFee < contribution, "Contribution Fee can only decrease.");
        contribution = contributionFee;
    }

    function setContributionAddress(address _newAddress) public Demokratia {
        contributionAddress = _newAddress;
    }

    function setMaxTokenPerAddress(uint256 _maxToken) public Demokratia {
        require(maxTokenPerAddress >= 1000000000*10**10, 'Must be a minimum of 1 billion');
        require(maxTokenPerAddress >= 5000000000*10**10, 'Must be a maximum of 5 billion');
        maxTokenPerAddress = _maxToken;
    }

    function _calculateContributionFee(address _sender, uint256 _amount) private view returns (uint256) {
        uint fee ;
        if(communityContributionEnabled && !_isExcludedFromContribution[_sender]){
            fee = _amount * contribution / 1000;
        } else {
            fee = 0;
        }
        return fee;
    }

    function _takeContribution (uint tContribution) private {
        _balances[contributionAddress] += tContribution;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        uint256 recipientBalance = _balances[recipient];

        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 feePaid = _calculateContributionFee(sender, amount);
        uint256 amount_to_receive = amount - feePaid;

        require(recipientBalance <= maxTokenPerAddress, "The account will own to much tokens");

        if (feePaid > 0){
            _takeContribution(feePaid);
        }

        _balances[sender] = senderBalance - amount;

        _balances[recipient] += amount_to_receive;

        emit Transfer(sender, recipient, amount_to_receive);
    }


    // Democratic Ownership functions

    function UpdateSC () public {
        IDOSCii dosc = IDOSCii(addressDOSC);
        LastAuthorizedAddress = dosc.readAuthorizedAddress(_msgSender());
        LastChangingTime = dosc.readEndChangeTime(_msgSender());
    }

    // Context

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // DemocraticOwnership

    modifier Demokratia() {
        require(LastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(LastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }

    constructor () {

        // set burning Address
        burningAddress = 0x9d1FB8204090EeEC8345aC85fE3cA6554E32Ad7E;
        
        _isExcludedFromContribution[burningAddress] = true;
        _excludedContribution.push(burningAddress);
        _isExcludedFromRestriction[burningAddress] = true;
        _excludedRestriction.push(burningAddress);
        _balances[burningAddress] = 15000000000 * 10**8;
        emit Transfer(address(0), burningAddress, 15000000000 * 10**8);

        // set owner Address
        _isExcludedFromContribution[0x3B848d5Dd18Fb71E73dAdb93541929e2cE1eF2E6] = true;
        _excludedContribution.push(0x3B848d5Dd18Fb71E73dAdb93541929e2cE1eF2E6);
        _isExcludedFromRestriction[0x3B848d5Dd18Fb71E73dAdb93541929e2cE1eF2E6] = true;
        _excludedRestriction.push(0x3B848d5Dd18Fb71E73dAdb93541929e2cE1eF2E6);
        _balances[_msgSender()] = 100000000000 * 10**8;
        emit Transfer(address(0), 0x3B848d5Dd18Fb71E73dAdb93541929e2cE1eF2E6, 100000000000 * 10**8);

        // contribution address
        contributionAddress = 0xcEB2355D1d8DC0DE813A45Dd8dcA8A852EB16A75;

        // address democratic IDO
        addressDOSC = 0xC3cd6Fa8C135dC53BA927AfD8D8FC07e6Bdd288A;


    }

}