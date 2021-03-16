/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;



interface ITornadoProxy {
    enum InstanceState { Disabled, Enabled, Mineable }

    function updateInstance(address _instance, InstanceState _state) external;
}

contract ProposalTestnetSetup {
    function executeProposal() public {
        ITornadoProxy tornadoProxy = ITornadoProxy(0x720fFb58b4965D2C0BD2b827FA8316C2002A98aa);
        address[3] memory wBTCs = [
            address(0x242654336ca2205714071898f67E254EB49ACdCe),
            address(0x776198CCF446DFa168347089d7338879273172cF),
            address(0xeDC5d01286f99A066559F60a585406f3878a033e)
        ];
        for(uint256 i = 0; i < wBTCs.length; i++) {
            tornadoProxy.updateInstance(wBTCs[i], ITornadoProxy.InstanceState.Enabled); 
        }
    }   
}