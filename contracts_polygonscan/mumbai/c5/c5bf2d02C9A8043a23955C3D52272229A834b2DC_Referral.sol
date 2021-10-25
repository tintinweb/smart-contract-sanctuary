// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Referral {
    // Archimedes
    address public immutable farm;

    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint) public referralsCount; // referrer address => referrals count
    // Total paid to referrals in PiToken
    uint public totalPaid;
    mapping(address => uint) public referralsPaid; // referrer address => paid

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralPaid(address indexed user, uint amount);

    constructor(address _farm) {
        require(_farm != address(0), "Zero address for farm");
        farm = _farm;
    }

    modifier onlyFarm {
        require(farm == msg.sender, "!Farm");
        _;
    }

    function recordReferral(address _user, address _referrer) external onlyFarm {
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

    function referralPaid(address _referrer, uint _amount) external onlyFarm {
        totalPaid += _amount;
        referralsPaid[_referrer] += _amount;

        emit ReferralPaid(_referrer, _amount);
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }
}