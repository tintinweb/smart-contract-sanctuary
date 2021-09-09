/**
 *Submitted for verification at Etherscan.io on 2021-09-09
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
    
    event PolicyMade(uint256 _coverage, uint256 id, uint256 effectiveUntil);
    
    
   // constructor(address _robot) public {
   //     robot = _robot;
   // }
    
   // modifier onlyRobot{
   //     require(msg.sender == robot);
   //     _;
   // }
    
    function insure(uint _coverage) public  {
        policies.push(policyInfo({
            coverage: _coverage,
            effectiveUntil: now+3600,
            id: policyCount,
            isClaimed: false,
            inClaimApplying: false
        }));
        
        policyCount++;
        totalCoverage += _coverage;
        
        emit PolicyMade(_coverage, policyCount-1, now+3600);
        
        //return(_coverage, policyCount-1 , now+3600 );
    }
    
    function _totalCoverageSub(uint256 _id) internal {
        policyInfo storage policy = policies[_id];
        if(policy.effectiveUntil>=now){return;}
        if(policy.isClaimed == true){return;}
        if(policy.inClaimApplying == true){return;}
        totalCoverage -= policy.coverage;
    }
    
    function totalCoverageSubstractionExternal(uint256 _id) external  {
        _totalCoverageSub(_id);
    }
    
    
}