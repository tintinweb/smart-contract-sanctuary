/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.5.17;

contract test{
    
    struct policyInfo{
        uint coverage;
        uint effectiveUntil;
        uint id;
        bool isClaimed;
        bool inClaimApplying;
    }
    
    
    uint public policyCount;
    uint public totalCoverage;
    address internal robot;
    
    policyInfo[] public policies;
    
    event policyMade(uint256 coverage, uint256 id, uint256 effectiveUntil);
    
    constructor(address _robot) public {
        robot = _robot;
    }
    
    modifier onlyRobot{
        require(msg.sender == robot);
        _;
    }
    
    function insure(uint _coverage) public {
        policies.push(policyInfo({
            coverage: _coverage,
            effectiveUntil: now+3600,
            id: policyCount,
            isClaimed: false,
            inClaimApplying: false
        }));
        
        emit policyMade(_coverage, policyCount, now+3600);
        
        policyCount++;
        totalCoverage += _coverage;
    }
    
    function _totalCoverageSub(uint256 _id) internal {
        policyInfo storage policy = policies[_id];
        if(policy.effectiveUntil>=now){return;}
        if(policy.isClaimed == true){return;}
        if(policy.inClaimApplying == true){return;}
        totalCoverage -= policy.coverage;
    }
    
    function totalCoverageSubstractionExternal(uint256 _id) external onlyRobot {
        _totalCoverageSub(_id);
    }
    
    
}