/**
* @title BurnABLE
* @dev ABLE burn contract.
*/
contract ABLEBurned {

    /**
    * @dev Function to contruct.
    */
    function () payable {
    }

    /**
    * @dev Function to Selfdestruct contruct.
    */
    function burnMe () {
        // Selfdestruct and send eth to self, 
        selfdestruct(address(this));
    }
}