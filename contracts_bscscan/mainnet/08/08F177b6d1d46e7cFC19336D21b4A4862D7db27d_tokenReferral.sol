// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IReferral.sol";
import "./Ownable.sol";

contract tokenReferral is IReferral, Ownable {
    using SafeBEP20 for IBEP20;

    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => address) public referrersIFO; // user address => referrer address FOR EDXA IFO
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public referralsCountIFO; // referrer address => referrals count FOR EDXA IFO
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(address => uint256) public totalReferralIFO; // referrer address => total referral commissions for EDXA IFO

    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function recordReferral(address _user, address _referrer) public override onlyOperator {
        if (_user != address(0)
        && _referrer != address(0)
        && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;

        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public override view returns (address) {
        return referrers[_user];
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    //WILL BE IMPLEMENT DURING EDXA IFO ONLY
    function recordReferralIFO(address _user, address _referrer, uint256 _amount) public override onlyOperator {

        // If user have deposit before during IFO
        if (referrersIFO[_user]== _referrer){
            totalReferralIFO[_referrer] +=_amount;
        }

        if (_user != address(0)
        && _referrer != address(0)
        && _user != _referrer
            && referrersIFO[_user] == address(0)
        ) {
            // Capture for normal referral
            referrers[_user] = _referrer;
            referralsCount[_referrer]+=1;

            // Capture for EDXA IFO only
            referrersIFO[_user] = _referrer;
            referralsCountIFO[_referrer]+= 1;
            totalReferralIFO[_referrer]+=_amount;

        }


    }
}