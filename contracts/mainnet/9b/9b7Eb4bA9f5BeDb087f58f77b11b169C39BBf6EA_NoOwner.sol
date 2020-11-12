pragma solidity 0.6.6;

interface IKP4R { function acceptGovernance() external; }

contract NoOwner {

    IKP4R kp4r = IKP4R(0xA89ac6e529aCf391CfbBD377F3aC9D93eae9664e);
    address mother = 0x86B0F5060Ed1A098bF1FE0508EA4E5a2e3311211;

    function disableGovernance() public {
        require(msg.sender == mother, "only KP4R mother can disable governance!");
        // Once this is called Governance will be disabled forever!
        // Due to community decision, ownership has been renounced.
        // - No KP4R can be minted.
        // - KP4R governance can never be transfered.
        // - Theres no going back.
        //
        // You asked, we listened!
        kp4r.acceptGovernance();
    }

    /* 🚀 🌕 - FUD can't keep us down. */
}