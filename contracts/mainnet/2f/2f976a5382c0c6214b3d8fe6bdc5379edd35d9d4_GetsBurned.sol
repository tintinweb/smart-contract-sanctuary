pragma solidity ^0.4.0;
contract GetsBurned {
    function () payable public {
    }

    function BurnMe() public {
        // Selfdestruct and send eth to self, 
        selfdestruct(address(this));
    }
}