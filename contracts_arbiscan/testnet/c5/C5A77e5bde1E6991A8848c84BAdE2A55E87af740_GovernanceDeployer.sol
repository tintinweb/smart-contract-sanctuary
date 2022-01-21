/**
 *Submitted for verification at arbiscan.io on 2022-01-20
*/

pragma solidity 0.5.16;


contract GovernanceDeployer {

	//event Deployed(address _timelockAddress, address _forwarderAddress, address _governatorAddress, address _gFryAddress, address _governorAlphaAddress);
    
    constructor() 
        public 
    {
        uint fourTwenty = 420;
        // address _guardian = 0x7E1d0353063F01CfFa92f4a9C8A100cFE37d8264;
        // IERC20 _FRY = IERC20(0x0c03Cbda17a4FbdA5F95aB0787c2A242DC14313e);
        // uint _votingPeriod = 5;
        // uint _votingDelay = 5;

        // Timelock timelock = new Timelock(address(this), 0);
        // Forwarder forwarder = new Forwarder(address(timelock));
        // Governator governator = new Governator(_FRY);
        // gFRY gFry = governator.gFry();
		// GovernorAlpha governorAlpha = new GovernorAlpha(address(timelock), address(gFry), _guardian, _votingPeriod, _votingDelay);
        
		// emit Deployed(address(timelock), address(forwarder), address(governator), address(gFry), address(governorAlpha));
        
        // bytes memory adminPayload = abi.encodeWithSignature("setPendingAdmin(address)", address(governorAlpha));
        
        // uint256 eta = block.timestamp + timelock.delay(); 
        // timelock.queueTransaction(address(timelock), 0, "", adminPayload, eta);
        
        // bytes memory delayPayload = abi.encodeWithSignature("setDelay(uint256)", 2 );
        
        // timelock.queueTransaction(address(timelock), 0, "", delayPayload, eta);
        
        // timelock.executeTransaction(address(timelock), 0, "", adminPayload, eta);
        // timelock.executeTransaction(address(timelock), 0, "", delayPayload, eta);
         
     }
}