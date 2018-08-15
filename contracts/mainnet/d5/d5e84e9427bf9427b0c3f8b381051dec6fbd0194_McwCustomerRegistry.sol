pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/TxRegistry.sol

/**
* @title Transaction Registry for Customer
* @dev Registry of customer&#39;s payments for MCW and payments for KWh.
*/
contract TxRegistry is Ownable {
    address public customer;

    // @dev Structure for TX data
    struct TxData {
        bytes32 txOrigMcwTransfer;
        uint256 amountMCW;
        uint256 amountKWh;
        uint256 timestampPaymentMCW;
        bytes32 txPaymentKWh;
        uint256 timestampPaymentKWh;
    }

    // @dev Customer&#39;s Tx of payment for MCW registry    
    mapping (bytes32 => TxData) private txRegistry;

    // @dev Customer&#39;s list of Tx   
    bytes32[] private txIndex;

    /**
    * @dev Constructor
    * @param _customer the address of a customer for whom the TxRegistry contract is creating
    */    
    constructor(address _customer) public {
        customer = _customer;
    }

    /**
    * @dev Owner can add a new Tx of payment for MCW to the customer&#39;s TxRegistry
    * @param _txPaymentForMCW the Tx of payment for MCW which will be added
    * @param _txOrigMcwTransfer the Tx of original MCW transfer in Ethereum network which acts as source for this Tx of payment for MCW
    * @param _amountMCW the amount of MCW tokens which will be recorded to the new Tx
    * @param _amountKWh the amount of KWh which will be recorded to the new Tx
    * @param _timestamp the timestamp of payment for MCW which will be recorded to the new Tx
    */
    function addTxToRegistry(
        bytes32 _txPaymentForMCW,
        bytes32 _txOrigMcwTransfer,
        uint256 _amountMCW,
        uint256 _amountKWh,
        uint256 _timestamp
        ) public onlyOwner returns(bool)
    {
        require(
            _txPaymentForMCW != 0 && _txOrigMcwTransfer != 0 && _amountMCW != 0 && _amountKWh != 0 && _timestamp != 0,
            "All parameters must be not empty."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentMCW == 0,
            "Tx with such hash is already exist."
        );

        txRegistry[_txPaymentForMCW].txOrigMcwTransfer = _txOrigMcwTransfer;
        txRegistry[_txPaymentForMCW].amountMCW = _amountMCW;
        txRegistry[_txPaymentForMCW].amountKWh = _amountKWh;
        txRegistry[_txPaymentForMCW].timestampPaymentMCW = _timestamp;
        txIndex.push(_txPaymentForMCW);
        return true;
    }

    /**
    * @dev Owner can mark a customer&#39;s Tx of payment for MCW as spent
    * @param _txPaymentForMCW the Tx of payment for MCW which will be marked as spent
    * @param _txPaymentForKWh the additional Tx of payment for KWh which will be recorded to the original Tx as proof of spend
    * @param _timestamp the timestamp of payment for KWh which will be recorded to the Tx
    */
    function setTxAsSpent(bytes32 _txPaymentForMCW, bytes32 _txPaymentForKWh, uint256 _timestamp) public onlyOwner returns(bool) {
        require(
            _txPaymentForMCW != 0 && _txPaymentForKWh != 0 && _timestamp != 0,
            "All parameters must be not empty."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentMCW != 0,
            "Tx with such hash doesn&#39;t exist."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentKWh == 0,
            "Tx with such hash is already spent."
        );

        txRegistry[_txPaymentForMCW].txPaymentKWh = _txPaymentForKWh;
        txRegistry[_txPaymentForMCW].timestampPaymentKWh = _timestamp;
        return true;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW amount
    */   
    function getTxCount() public view returns(uint256) {
        return txIndex.length;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW from customer&#39;s Tx list by index
    * @param _index the index of a customer&#39;s Tx of payment for MCW in the customer&#39;s Tx list
    */  
    function getTxAtIndex(uint256 _index) public view returns(bytes32) {
        return txIndex[_index];
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - Tx of original MCW transfer in Ethereum network which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxOrigMcwTransfer(bytes32 _txPaymentForMCW) public view returns(bytes32) {
        return txRegistry[_txPaymentForMCW].txOrigMcwTransfer;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - amount of MCW tokens which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxAmountMCW(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].amountMCW;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - amount of KWh which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxAmountKWh(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].amountKWh;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - timestamp of payment for MCW which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxTimestampPaymentMCW(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].timestampPaymentMCW;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - Tx of payment for KWh which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxPaymentKWh(bytes32 _txPaymentForMCW) public view returns(bytes32) {
        return txRegistry[_txPaymentForMCW].txPaymentKWh;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - timestamp of payment for KWh which is recorded in the Tx
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getTxTimestampPaymentKWh(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].timestampPaymentKWh;
    }

    /**
    * @dev Check the customer&#39;s Tx of payment for MCW
    * @param _txPaymentForMCW the Tx of payment for MCW which need to be checked
    */  
    function isValidTxPaymentForMCW(bytes32 _txPaymentForMCW) public view returns(bool) {
        bool isValid = false;
        if (txRegistry[_txPaymentForMCW].timestampPaymentMCW != 0) {
            isValid = true;
        }
        return isValid;
    }

    /**
    * @dev Check if the customer&#39;s Tx of payment for MCW is spent
    * @param _txPaymentForMCW the Tx of payment for MCW which need to be checked
    */
    function isSpentTxPaymentForMCW(bytes32 _txPaymentForMCW) public view returns(bool) {
        bool isSpent = false;
        if (txRegistry[_txPaymentForMCW].timestampPaymentKWh != 0) {
            isSpent = true;
        }
        return isSpent;
    }

    /**
    * @dev Check the customer&#39;s Tx of payment for KWh
    * @param _txPaymentForKWh the Tx of payment for KWh which need to be checked
    */
    function isValidTxPaymentForKWh(bytes32 _txPaymentForKWh) public view returns(bool) {
        bool isValid = false;
        for (uint256 i = 0; i < getTxCount(); i++) {
            if (txRegistry[getTxAtIndex(i)].txPaymentKWh == _txPaymentForKWh) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW by Tx payment for KWh 
    * @param _txPaymentForKWh the Tx of payment for KWh
    */
    function getTxPaymentMCW(bytes32 _txPaymentForKWh) public view returns(bytes32) {
        bytes32 txMCW = 0;
        for (uint256 i = 0; i < getTxCount(); i++) {
            if (txRegistry[getTxAtIndex(i)].txPaymentKWh == _txPaymentForKWh) {
                txMCW = getTxAtIndex(i);
                break;
            }
        }
        return txMCW;
    }
}

// File: contracts/McwCustomerRegistry.sol

/**
* @title Customers Registry
* @dev Registry of all customers
*/
contract McwCustomerRegistry is Ownable {
    // @dev Key: address of customer wallet, Value: address of customer TxRegistry contract
    mapping (address => address) private registry;

    // @dev Customers list
    address[] private customerIndex;

    // @dev Events for dashboard
    event NewCustomer(address indexed customer, address indexed txRegistry);
    event NewCustomerTx(
        address indexed customer,
        bytes32 txPaymentForMCW,
        bytes32 txOrigMcwTransfer,
        uint256 amountMCW,
        uint256 amountKWh,
        uint256 timestamp
    );
    event SpendCustomerTx(address indexed customer, bytes32 txPaymentForMCW, bytes32 txPaymentForKWh, uint256 timestamp);

    // @dev Constructor
    constructor() public {}

    /**
    * @dev Owner can add a new customer to registry
    * @dev Creates a related TxRegistry contract for the new customer
    * @dev Related event will be generated
    * @param _customer the address of a new customer to add
    */
    function addCustomerToRegistry(address _customer) public onlyOwner returns(bool) {
        require(
            _customer != address(0),
            "Parameter must be not empty."
        );
        require(
            registry[_customer] == address(0),
            "Customer is already in the registry."
        );

        address txRegistry = new TxRegistry(_customer);
        registry[_customer] = txRegistry;
        customerIndex.push(_customer);
        emit NewCustomer(_customer, txRegistry);
        return true;
    }

    /**
    * @dev Owner can add a new Tx of payment for MCW to the customer&#39;s TxRegistry
    * @dev Generates the Tx of payment for MCW (hash as proof of payment) and writes the Tx data to the customer&#39;s TxRegistry
    * @dev Related event will be generated
    * @param _customer the address of a customer to whom to add a new Tx
    * @param _txOrigMcwTransfer the Tx of original MCW transfer in Ethereum network which acts as source for a new Tx of payment for MCW
    * @param _amountMCW the amount of MCW tokens which will be recorded to the new Tx
    * @param _amountKWh the amount of KWh which will be recorded to the new Tx
    */
    function addTxToCustomerRegistry(
        address _customer,
        bytes32 _txOrigMcwTransfer,
        uint256 _amountMCW,
        uint256 _amountKWh
        ) public onlyOwner returns(bool)
    {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txOrigMcwTransfer != 0 && _amountMCW != 0 && _amountKWh != 0,
            "All parameters must be not empty."
        );

        uint256 timestamp = now;
        bytes32 txPaymentForMCW = keccak256(
            abi.encodePacked(
                _customer,
                _amountMCW,
                _amountKWh,
                timestamp)
            );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        require(
            txRegistry.getTxTimestampPaymentMCW(txPaymentForMCW) == 0,
            "Tx with such hash is already exist."
        );

        if (!txRegistry.addTxToRegistry(
            txPaymentForMCW,
            _txOrigMcwTransfer,
            _amountMCW,
            _amountKWh,
            timestamp))
            revert ("Something went wrong.");
        emit NewCustomerTx(
            _customer,
            txPaymentForMCW,
            _txOrigMcwTransfer,
            _amountMCW,
            _amountKWh,
            timestamp);
        return true;
    }

    /**
    * @dev Owner can mark a customer&#39;s Tx of payment for MCW as spent
    * @dev Generates an additional Tx of paymant for KWh (hash as proof of spend), which connected to the original Tx.
    * @dev Related event will be generated
    * @param _customer the address of a customer to whom to spend a Tx
    * @param _txPaymentForMCW the Tx of payment for MCW which will be marked as spent
    */
    function setCustomerTxAsSpent(address _customer, bytes32 _txPaymentForMCW) public onlyOwner returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        require(
            txRegistry.getTxTimestampPaymentMCW(_txPaymentForMCW) != 0,
            "Tx with such hash doesn&#39;t exist."
        );
        require(
            txRegistry.getTxTimestampPaymentKWh(_txPaymentForMCW) == 0,
            "Tx with such hash is already spent."
        );

        uint256 timestamp = now;
        bytes32 txPaymentForKWh = keccak256(
            abi.encodePacked(
                _txPaymentForMCW,
                timestamp)
            );

        if (!txRegistry.setTxAsSpent(_txPaymentForMCW, txPaymentForKWh, timestamp))
            revert ("Something went wrong.");
        emit SpendCustomerTx(
            _customer,
            _txPaymentForMCW,
            txPaymentForKWh,
            timestamp);
        return true;
    }

    /**
    * @dev Get the current amount of customers
    */
    function getCustomerCount() public view returns(uint256) {
        return customerIndex.length;
    }

    /**
    * @dev Get the customer&#39;s address from customers list by index
    * @param _index the index of a customer in the customers list
    */    
    function getCustomerAtIndex(uint256 _index) public view returns(address) {
        return customerIndex[_index];
    }

    /**
    * @dev Get the customer&#39;s TxRegistry contract
    * @param _customer the address of a customer for whom to get TxRegistry contract 
    */   
    function getCustomerTxRegistry(address _customer) public view returns(address) {
        return registry[_customer];
    }

    /**
    * @dev Check the customer&#39;s address
    * @param _customer the address of a customer which need to be checked
    */   
    function isValidCustomer(address _customer) public view returns(bool) {
        require(
            _customer != address(0),
            "Parameter must be not empty."
        );

        bool isValid = false;
        address txRegistry = registry[_customer];
        if (txRegistry != address(0)) {
            isValid = true;
        }
        return isValid;
    }

    // wrappers on TxRegistry contract

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW amount
    * @param _customer the address of a customer for whom to get
    */   
    function getCustomerTxCount(address _customer) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 txCount = txRegistry.getTxCount();
        return txCount;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW from customer&#39;s Tx list by index
    * @param _customer the address of a customer for whom to get
    * @param _index the index of a customer&#39;s Tx of payment for MCW in the customer&#39;s Tx list
    */       
    function getCustomerTxAtIndex(address _customer, uint256 _index) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txIndex = txRegistry.getTxAtIndex(_index);
        return txIndex;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - Tx of original MCW transfer in Ethereum network which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxOrigMcwTransfer(address _customer, bytes32 _txPaymentForMCW) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txOrigMcwTransfer = txRegistry.getTxOrigMcwTransfer(_txPaymentForMCW);
        return txOrigMcwTransfer;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - amount of MCW tokens which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxAmountMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 amountMCW = txRegistry.getTxAmountMCW(_txPaymentForMCW);
        return amountMCW;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - amount of KWh which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxAmountKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 amountKWh = txRegistry.getTxAmountKWh(_txPaymentForMCW);
        return amountKWh;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - timestamp of payment for MCW which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxTimestampPaymentMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 timestampPaymentMCW = txRegistry.getTxTimestampPaymentMCW(_txPaymentForMCW);
        return timestampPaymentMCW;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - Tx of payment for KWh which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxPaymentKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txPaymentKWh = txRegistry.getTxPaymentKWh(_txPaymentForMCW);
        return txPaymentKWh;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW data - timestamp of payment for KWh which is recorded in the Tx
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForMCW the Tx of payment for MCW for which to get data
    */  
    function getCustomerTxTimestampPaymentKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 timestampPaymentKWh = txRegistry.getTxTimestampPaymentKWh(_txPaymentForMCW);
        return timestampPaymentKWh;
    }

    /**
    * @dev Check the customer&#39;s Tx of payment for MCW
    * @param _customer the address of a customer for whom to check
    * @param _txPaymentForMCW the Tx of payment for MCW which need to be checked
    */  
    function isValidCustomerTxPaymentForMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isValid = txRegistry.isValidTxPaymentForMCW(_txPaymentForMCW);
        return isValid;
    }

    /**
    * @dev Check if the customer&#39;s Tx of payment for MCW is spent
    * @param _customer the address of a customer for whom to check
    * @param _txPaymentForMCW the Tx of payment for MCW which need to be checked
    */
    function isSpentCustomerTxPaymentForMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isSpent = txRegistry.isSpentTxPaymentForMCW(_txPaymentForMCW);
        return isSpent;
    }

    /**
    * @dev Check the customer&#39;s Tx of payment for KWh
    * @param _customer the address of a customer for whom to check
    * @param _txPaymentForKWh the Tx of payment for KWh which need to be checked
    */
    function isValidCustomerTxPaymentForKWh(address _customer, bytes32 _txPaymentForKWh) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForKWh != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isValid = txRegistry.isValidTxPaymentForKWh(_txPaymentForKWh);
        return isValid;
    }

    /**
    * @dev Get the customer&#39;s Tx of payment for MCW by Tx payment for KWh 
    * @param _customer the address of a customer for whom to get
    * @param _txPaymentForKWh the Tx of payment for KWh
    */
    function getCustomerTxPaymentMCW(address _customer, bytes32 _txPaymentForKWh) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForKWh != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txMCW = txRegistry.getTxPaymentMCW(_txPaymentForKWh);
        return txMCW;
    }
}