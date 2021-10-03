//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./Ownable.sol";

contract Referral is Ownable {
    using SafeMath for uint256;

    uint8 public decimals;

    uint256 public totalCommissionReward;

    mapping(address => address) private userSponsors; // map[memberAddress]sponsorAddress

    mapping(uint8 => uint256) private percentCommissions;

    mapping(address => uint256) private userCommissionsReward;

    mapping(address => mapping(address => bool)) private _allowances; //map[owner]map[spender]boolean

    // constructor() {}

    function setPercentCommission(uint8 level, uint256 percent)
        public
        onlyOwner
        returns (bool)
    {
        percentCommissions[level] = percent;
        return true;
    }

    function commissionOf(address user) external view returns (uint256) {
        return userCommissionsReward[user];
    }

    function sponsorOf(address user) external view returns (address) {
        return userSponsors[user];
    }

    function isAllow(address owner, address spender)
        external
        view
        returns (bool)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender) public {
        _approve(msg.sender, spender);
    }

    function _approve(address owner, address spender) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = true;
    }

    function withdrawFrom(address user, uint256 amount) public returns (bool) {
        require(
            _isAllow(msg.sender, user) == false,
            "User not approve for you"
        );

        return _withdraw(user, amount);
    }

    function _withdraw(address user, uint256 amount) private returns (bool) {
        require(userSponsors[user] == address(0), "User not found");
        require(
            userCommissionsReward[user] < amount,
            "withdraw amount exceeds"
        );

        userCommissionsReward[user] = userCommissionsReward[user] - amount;

        return true;
    }

    function _isAllow(address owner, address spender) private returns (bool) {
        return _allowances[owner][spender];
    }

    function payCommissionFrom(address user, uint256 amount) public {
        require(
            _isAllow(msg.sender, user) == false,
            "User not approve for you"
        );

        _payCommission(user, amount);
    }

    function payCommission(uint256 amount) public {
        _payCommission(msg.sender, amount);
    }

    function _payCommission(address user, uint256 amount) public {
        require(userSponsors[user] == address(0), "User not found");
        uint8 level = 1;

        address sponsor = user;
        while (true) {
            uint256 percent = percentCommissions[level];
            if (percent == 0) {
                break;
            }

            sponsor = userSponsors[sponsor];
            if (sponsor == address(0)) {
                break;
            }

            uint256 reward = percent.mul(amount);
            totalCommissionReward = totalCommissionReward.add(reward);
            userCommissionsReward[sponsor] = userCommissionsReward[sponsor].add(
                reward
            );
            level++;
        }
        return;
    }

    function newUserFrom(address user, address sponsor) public returns (bool) {
        require(
            _isAllow(msg.sender, user) == false,
            "User not approve for you"
        );

        return _newUser(user, sponsor);
    }

    function newUser(address sponsor) public returns (bool) {
        return _newUser(msg.sender, sponsor);
    }

    function _newUser(address user, address sponsor) private returns (bool) {
        require(userSponsors[user] != address(0), "User existed");

        userSponsors[user] = sponsor;

        return true;
    }
}