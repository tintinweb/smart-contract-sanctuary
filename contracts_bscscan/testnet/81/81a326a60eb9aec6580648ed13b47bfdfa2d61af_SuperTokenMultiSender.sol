/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.5;

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

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;
    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);
    Roles.Role private _whitelistAdmins;
    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }
    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }
    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }
    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }
    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }
    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }
    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;
    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);
    Roles.Role private _whitelisteds;
    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }
    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }
    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }
    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }
    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }
    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract AccessWhitelist is WhitelistedRole {
    constructor() public {
        super.addWhitelisted(msg.sender);
    }
}

contract AccessControls {
    AccessWhitelist public accessWhitelist;
    constructor(AccessWhitelist _accessWhitelist) internal {
        accessWhitelist = _accessWhitelist;
    }
    modifier onlyWhitelisted() {
        require(accessWhitelist.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }
    modifier onlyWhitelistAdmin() {
        require(accessWhitelist.isWhitelistAdmin(msg.sender), "Caller not whitelist admin");
        _;
    }
    function updateAccessWhitelist(AccessWhitelist _accessWhitelist) external onlyWhitelistAdmin {
        accessWhitelist = _accessWhitelist;
    }
}

contract SuperTokenMultiSender is AccessControls {
    using SafeMath for uint256;
    event Transfer(address indexed _token, address indexed _caller, uint256 _recipientCount, uint256 _totalTokensSent);
    event PricePerTxChanged(address indexed _caller, uint256 _oldPrice, uint256 _newPrice);
    event ReferralPerTxChanged(address indexed _caller, uint256 _oldPrice, uint256 _newPrice);
    event EtherMoved(address indexed _caller, address indexed _to, uint256 _amount);
    event TokensMoved(address indexed _caller, address indexed _to, uint256 _amount);
    event CreditsAdded(address indexed _caller, address indexed _to, uint256 _amount);
    event CreditsRemoved(address indexed _caller, address indexed _to, uint256 _amount);
    mapping(address => uint256) public credits;
    uint256 public pricePerTx = 0.03 ether;
    uint256 public referralPerTx = 0.01 ether;
    address payable public feeSplitter;
    constructor(AccessWhitelist _accessWhitelist, address payable _feeSplitter)
        AccessControls(_accessWhitelist) public {
        feeSplitter = _feeSplitter;
    }
    function () external payable {}
    function transfer(address _token, address payable _referral, address[] calldata _addresses, uint256[] calldata _values) payable external returns (bool) {
        require(_addresses.length == _values.length, "Address array and values array must be same length");
        require(credits[msg.sender] > 0 || msg.value >= pricePerTx, "Must have credit or min value");
        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");
            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
            totalTokensSent = totalTokensSent.add(_values[i]);
        }
        if (msg.value == 0 && credits[msg.sender] > 0) {
            credits[msg.sender] = credits[msg.sender].sub(1);
        } else {
            uint256 fee = msg.value;
            if (_referral != address(0)) {
                fee = fee.sub(referralPerTx);
                (bool feeSplitterSuccess,) = _referral.call.value(referralPerTx)("");
                require(feeSplitterSuccess, "Failed to transfer the referral");
            }
            (bool feeSplitterSuccess,) = address(feeSplitter).call.value(fee)("");
            require(feeSplitterSuccess, "Failed to transfer to the fee splitter");
        }
        emit Transfer(_token, msg.sender, _addresses.length, totalTokensSent);
        return true;
    }
    function moveEther(address payable _account) onlyWhitelistAdmin external returns (bool)  {
        uint256 contractBalance = address(this).balance;
        _account.transfer(contractBalance);
        emit EtherMoved(msg.sender, _account, contractBalance);
        return true;
    }
    function moveTokens(address _token, address _account) external onlyWhitelistAdmin returns (bool) {
        uint256 contractTokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_account, contractTokenBalance);
        emit TokensMoved(msg.sender, _account, contractTokenBalance);
        return true;
    }
    function addCredit(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        credits[_to] = credits[_to].add(_amount);
        emit CreditsAdded(msg.sender, _to, _amount);
        return true;
    }
    function reduceCredit(address _to, uint256 _amount) external onlyWhitelisted returns (bool) {
        credits[_to] = credits[_to].sub(_amount);
        emit CreditsRemoved(msg.sender, _to, _amount);
        return true;
    }
    function setPricePerTx(uint256 _pricePerTx) external onlyWhitelisted returns (bool) {
        uint256 oldPrice = pricePerTx;
        pricePerTx = _pricePerTx;
        emit PricePerTxChanged(msg.sender, oldPrice, pricePerTx);
        return true;
    }
    function setReferralPerTx(uint256 _referralPerTx) external onlyWhitelisted returns (bool) {
        uint256 oldPrice = referralPerTx;
        referralPerTx = _referralPerTx;
        emit ReferralPerTxChanged(msg.sender, oldPrice, referralPerTx);
        return true;
    }
    function creditsOfOwner(address _owner) external view returns (uint256) {
        return credits[_owner];
    }
    function updateFeeSplitter(address payable _feeSplitter) external onlyWhitelistAdmin {
        feeSplitter = _feeSplitter;
    }
}