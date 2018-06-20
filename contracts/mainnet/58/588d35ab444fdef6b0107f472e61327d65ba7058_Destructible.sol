contract Destructible {

/**
* @dev mapping of security => (investorEthAddress, investerInfo)
*/
    address _owner; //owner of this contract

 /*
 * event emitted when ethers received in this contract
 */
    event receipt(address indexed investor, uint value);

/**
* @dev Modifier to make a function callable only by the owner of the contract
*/
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

  /**
   * @dev Constructor of the Destructible
   */ 
    constructor() public {
        _owner = msg.sender;
    }

    /**
    * @dev 
    * Payable fallback function. 
    * Function just emits event to be inline with 2300 gas limitation for fallback functions
    */
    function() payable public {
        emit receipt(msg.sender, msg.value);
    }
       
    /**
    * @dev 
    * destroyAndSend 
    * @param _recipient is the recipient address to which fund held by this contract are to be remitted on selfdestruction
    */

    function destroyAndSend(address _recipient) onlyOwner() public {
        selfdestruct(_recipient);
    }

}