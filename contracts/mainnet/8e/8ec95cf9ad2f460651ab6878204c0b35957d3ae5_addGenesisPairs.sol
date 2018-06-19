pragma solidity ^0.4.10;

// The Timereum Project

// Test

contract addGenesisPairs {
    
address[] newParents;
address[] newChildren;

function addGenesisPairs()    {
    // Set tmed contract address
    timereumDelta tmedContract=timereumDelta(0x4fC550Cd2312ed67CB3938378C90c2A76FAE0142);

    newParents=[0x76Ed51dB1F503482C582B611f1c7Ac0eD2A74414,0x9Ba61187a085D9ADaEe628EF053945D68f0E2894];
    newChildren=[0x4Ba83570bc502BA82274AF2D4240E68C78Edb528,0x81c323255958336ad35bb8e3826c4111a5faBb49];
    
    tmedContract.importGenesisPairs(newParents,newChildren);
 
}

}

contract timereumDelta {
    function importGenesisPairs(address[] newParents,address[] newChildren) public;
}