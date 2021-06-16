/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// File: contracts/ICarbonInventoryControl.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICarbonInventoryControl {

     /**
     * @dev function to offset carbon foot print on token and inventory.
     * @param _to Wallet from whom will be burned tokens.
     * @param _broker Broker who will burn tokens.
     * @param _carbonTon Amount to burn on carbon tons.
     * @param _receiptId Transaction identifier that represent the offset.
     * @param _onBehalfOf Broker is burning on behalf of someone.
     * @param _token Commmercial carbon credit token which will be burned.
     */
    function offsetTransaction(address _to, address _broker, uint256 _carbonTon, string memory _receiptId, string memory _onBehalfOf, address _token )
        external;

}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/CarbonInstantOffset.sol



pragma solidity 0.6.12;



contract CarbonInstantOffset is Ownable {

    ICarbonInventoryControl public carbonInventoryControl;
       
    address private MCO2;  
    address private broker;

    event BrokerChanged(address newBroker);
    event MCO2Changed(address newMCO2); 
    
    constructor(address _carbonInventoryControl, address _MCO2, address _broker)
        public
        {
            MCO2 = _MCO2;
            broker = _broker;
            carbonInventoryControl = ICarbonInventoryControl(_carbonInventoryControl);
        }
              
     /**
     * @dev function to offset carbon foot print on token and inventory.
     * @param _carbonTon Amount to burn on carbon tons.
     * @param _receiptId Transaction identifier that represent the offset.
     * @param _onBehalfOf Broker is burning on behalf of someone.
     */
    function offsetTransaction( uint256 _carbonTon, string memory _receiptId, string memory _onBehalfOf)
        public  {
        require (_carbonTon > 0, "CarbonInstantOffset: Carbon ton should be greater than zero");
        carbonInventoryControl.offsetTransaction(msg.sender, broker, _carbonTon, _receiptId, _onBehalfOf, MCO2);
    }

    /**
    * @dev Changes a the cMCO2 address on eth network
    * @param newMCO2 New cMCO2 address on eth network
    */
    function changeMCO2(address newMCO2) external onlyOwner returns(bool) {
        _changeMCO2(newMCO2);
        return true;
    }

    /**
    * @dev Changes a the cMCO2 address on eth network (internal)
    * @param newMCO2 New cMCO2 address on eth network
    */
    function _changeMCO2(address newMCO2) internal {
        require(newMCO2 != address(0), "CarbonInstantOffset: Contract is empty");
        MCO2 = newMCO2;
        emit MCO2Changed(MCO2);
    }

    function getMCO2() external view returns(address) {
        return MCO2;
    }


   /**
    * @dev Changes a the broker address on eth network
    * @param newBroker New broker address on eth network
    */
    function changeBroker(address newBroker) external onlyOwner returns(bool) {
        _changeBroker(newBroker);
        return true;
    }

    /**
    * @dev Changes a the Broker address on eth network (internal)
    * @param newBroker New Broker address on eth network
    */
    function _changeBroker (address newBroker) internal {
        require(newBroker != address(0), "CarbonInstantOffset: Contract is empty");
        broker = newBroker;
        emit BrokerChanged(broker);
    }

    function getBroker() external view returns(address) {
        return broker;
    }

}