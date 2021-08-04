/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity = 0.6.12;

interface ISlimeFriends {

    event Referral(address indexed referrer, address indexed farmer);
    event NextOwner(address indexed _owner);
    event AdminStatus(address indexed _admin,bool _status);

    // Standard contract ownership transfer implementation,
    function approveNextOwner(address _nextOwner) external;

    function acceptNextOwner() external ;

    function setSlimeFriend(address farmer, address referrer) external ;

    function getSlimeFriend(address farmer) external view returns (address);

    // Set admin status.
    function setAdminStatus(address _admin, bool _status) external ;

    event EmergencyBEP20Drain(address token, address owner, uint256 amount);

}


contract ReferralsCaller {
    address referralsContractAddress;
    constructor(address _referralsContract) public {    
        referralsContractAddress = _referralsContract;
    }

    function setReferralsContract(address _referralsContract) public {    
        referralsContractAddress = _referralsContract;
    }

    function getReferrals(address farmer) public view returns (address){
        ISlimeFriends slimeFriends = ISlimeFriends(referralsContractAddress);
        return slimeFriends.getSlimeFriend(farmer);
    }

}