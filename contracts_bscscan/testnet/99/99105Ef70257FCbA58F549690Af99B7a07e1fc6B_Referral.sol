/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract Referral is Auth {
    mapping(address => address) public referrers;
    mapping(address => uint256) public referralsCount;
    mapping(address => uint256) public totalReferralCommissions;

    constructor() Auth(msg.sender) {
    }

    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }

    function recordReferral(address _user, address _referrer) public authorized {
        if (_user != address(0)
        && _referrer != address(0)
        && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission) public authorized {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    function retrieveTokens(address _token, uint _amount) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));

        if(_amount > balance){
            _amount = balance;
        }

        require(IERC20(_token).transfer(msg.sender, _amount), "Transfer failed");
    }

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);
}