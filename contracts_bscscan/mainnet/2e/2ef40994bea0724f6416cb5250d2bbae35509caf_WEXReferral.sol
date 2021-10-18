// SPDX-License-Identifier: MIT
import "./Ownable.sol";

pragma solidity >=0.4.0;

// File: contracts\libs\IWEXReferral.sol

// Adding-Identifier: MIT

pragma solidity 0.6.12;

interface IWedexReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address _user, address _referrer,bool _vipBranch, uint256 _leaderCommission) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
    
    function addTotalFund(address _referrer, uint256 _amount, uint256 _loop) external;
    
    function reduceTotalFund(address _referrer, uint256 _amount, uint256 _loop) external;
    
    function getTeam(address _user) external view returns (address [] memory);
    
    function totalFund(address _referrer) external view returns (uint256);
    
}

// File: contracts\libs\IWEXReferral.sol

// Adding-Identifier: MIT

pragma solidity 0.6.12;

interface IWexProfile {

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getUserStatus(address _userAddress) external view returns (bool);
    
}
// File: contracts\WEXReferral.sol

// Adding-Identifier: MIT

pragma solidity 0.6.12;


contract WEXReferral is IWedexReferral, Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    
    struct ReferrersInfo {
        address referrer;
        bool vipBranch; 
        uint256 leaderCommission;
    }
    
    mapping(address => bool) public operators;
    mapping(address => ReferrersInfo) public referrers; // user address => referrerInfo
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public override totalFund; // referrer address => referrals count
    mapping(address => uint256) public referalsTier; // referrer address => referrals Tier
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(address => address[]) public team; // return alll member in the team
    mapping(address => bool) public blacklist; //mapping address to blacklist
    mapping(address => bool) public migrated;
    uint256 public maximumLoop = 10;
    uint256 public vipRequirement = 2e5*1e18;
    IWexProfile public wexProfile;
    IWedexReferral public oldReferralContract;
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator, bool indexed status);
    event TotalFundAdd(address _referrer, uint256 _amount, uint256 _loop);
    event ReduceTotalFund(address _referrer, uint256 _amount, uint256 currentLoop);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }
    constructor(
        IWedexReferral _oldWedexreferral,
        IWexProfile _wexProfile
        ) public
        {
        wexProfile = _wexProfile;
        oldReferralContract = _oldWedexreferral;
        operators[_msgSender()] = true;
     }
    function noLoop(address _user,address _referrer) public returns(bool){
        if(referrers[_referrer].referrer==_user) {
            return false;
        }
        if(referrers[_referrer].referrer==address(0)) {
            return true;
        }
        else {
            return noLoop(_referrer,referrers[_referrer].referrer);
        }
    }
    function recordReferral(address _user, address _referrer,bool _vipBranch, uint256 _leaderCommission) public override onlyOperator {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user].referrer == address(0)
            && noLoop(_user,_referrer)
        ) {
            
            if(referrers[_referrer].vipBranch){
                _vipBranch = true;
                _leaderCommission = referrers[_referrer].leaderCommission;
            } else if(!isVip(_referrer) && _vipBranch) {
                _vipBranch = false;
                _leaderCommission = 0;
            }
            
            referrers[_user] = ReferrersInfo(
                {
                    referrer: _referrer,
                    vipBranch: _vipBranch,
                    leaderCommission: _leaderCommission
                    
                });
            referralsCount[_referrer] += 1;
            team[_referrer].push(_user);
            emit ReferralRecorded(_user, _referrer);
        }
    }
    
    function recordReferralCommission(address _referrer, uint256 _commission) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }
    function addTotalFund(address _referrer, uint256 _amount, uint256 _loop) public override onlyOperator {
        if (_referrer != address(0) && _amount > 0 && _loop<maximumLoop) {
            uint256 currentLoop = _loop.add(1);
            totalFund[_referrer] = totalFund[_referrer].add(_amount);
            if(totalFund[_referrer]>referalsTier[_referrer]){
                referalsTier[_referrer] = totalFund[_referrer];
            }
            if(referrers[_referrer].referrer != address(0)){
                addTotalFund(referrers[_referrer].referrer, _amount, currentLoop);
            }
            emit TotalFundAdd(_referrer, _amount, _loop);
        }
    }
    function reduceTotalFund(address _referrer, uint256 _amount, uint256 _loop) public override onlyOperator {
        if (_referrer != address(0) && _amount > 0 && _loop<maximumLoop && totalFund[_referrer]>_amount) {
            uint256 currentLoop = _loop.add(1);
            totalFund[_referrer] = totalFund[_referrer].sub(_amount);
            if(referrers[_referrer].referrer != address(0)){
                reduceTotalFund(referrers[_referrer].referrer, _amount, currentLoop);
            }
            emit ReduceTotalFund(_referrer, _amount, currentLoop);
        }
    }
    function setMaxloop(uint256 _maximumLoop) public onlyOperator {
        maximumLoop = _maximumLoop;
    }
    function addBlacklist(address user) external onlyOwner {
        blacklist[user] = true;
    }
    function removeReferrer(address _user) external onlyOwner {
        referrers[_user].referrer = address(0);
    }
    //
    function getReferrer(address _user) public override view returns(address) {
        return referrers[_user].referrer;
    }
    function isVip(address user) public view returns(bool){
        if(referalsTier[user]>vipRequirement)
            return true;
        return false;
    }

    function setTotalFund(address _referrer, uint256 _amount) external onlyOperator{
        totalFund[_referrer] = _amount;
        referalsTier[_referrer] = _amount;
    }
    function getTeam(address _user) public override view returns (address [] memory){
        return team[_user];
    }
    function setWexProfile(IWexProfile _wexProfile) public onlyOwner {
        wexProfile = _wexProfile;
    }
    function setVipRequirement(uint256 _vipRequirement) public onlyOwner {
        vipRequirement = _vipRequirement;
    }
    function updateMigration(address _referrer, bool _status) external {
        migrated[_referrer] = _status;
    }
    function migration(address[] memory _referrers, bool _vipBranch, uint256 _leaderCommission ) public onlyOperator {
        if(_referrers.length>0) {
            for(uint256 j =0; j< _referrers.length;j++){
                if(!migrated[_referrers[j]]){
                    address[] memory oldteam = oldReferralContract.getTeam(_referrers[j]);
                    if(oldteam.length>0){
                        for(uint256 i = 0; i<oldteam.length;++i){
                            referrers[oldteam[i]] = ReferrersInfo({
                              referrer: _referrers[j],
                              vipBranch: _vipBranch,
                              leaderCommission: _leaderCommission
                            });
                            
                        }
                        migration(oldteam,_vipBranch,_leaderCommission);
                        team[_referrers[j]] = oldteam;
                    }
                    migrated[_referrers[j]] = true;
                }
            }
        }
    }
    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
    // Owner can drain tokens that are sent here by mistake
    function drainBEP20Token(IBEP20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }
}