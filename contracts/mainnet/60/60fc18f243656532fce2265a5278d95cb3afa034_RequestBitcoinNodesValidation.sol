pragma solidity 0.4.18;

// From https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;

    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    assert(b >= 0);
    return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that throw on error
 * @dev SafeMath adapted for int256
 */
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    assert(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    assert((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    assert(!(a == - 2**255 && b == -1));

    // assert(b > 0); // Solidity automatically throws when dividing by 0
    int256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    assert((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    assert((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    assert(a>=0);
    return uint256(a);
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev SafeMath adapted for uint96
 */
library SafeMathUint96 {
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint96 a, uint96 b) internal pure returns (uint96) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint96 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
    assert(b <= a);
    return a - b;
  }

  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev SafeMath adapted for uint8
 */
library SafeMathUint8 {
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

/**
 * @title Administrable
 * @dev Base contract for the administration of Core. Handles whitelisting of currency contracts
 */
contract Administrable is Pausable {

    // mapping of address of trusted contract
    mapping(address => uint8) public trustedCurrencyContracts;

    // Events of the system
    event NewTrustedContract(address newContract);
    event RemoveTrustedContract(address oldContract);

    /**
     * @dev add a trusted currencyContract 
     *
     * @param _newContractAddress The address of the currencyContract
     */
    function adminAddTrustedCurrencyContract(address _newContractAddress)
        external
        onlyOwner
    {
        trustedCurrencyContracts[_newContractAddress] = 1; //Using int instead of boolean in case we need several states in the future.
        NewTrustedContract(_newContractAddress);
    }

    /**
     * @dev remove a trusted currencyContract 
     *
     * @param _oldTrustedContractAddress The address of the currencyContract
     */
    function adminRemoveTrustedCurrencyContract(address _oldTrustedContractAddress)
        external
        onlyOwner
    {
        require(trustedCurrencyContracts[_oldTrustedContractAddress] != 0);
        trustedCurrencyContracts[_oldTrustedContractAddress] = 0;
        RemoveTrustedContract(_oldTrustedContractAddress);
    }

    /**
     * @dev get the status of a trusted currencyContract 
     * @dev Not used today, useful if we have several states in the future.
     *
     * @param _contractAddress The address of the currencyContract
     * @return The status of the currencyContract. If trusted 1, otherwise 0
     */
    function getStatusContract(address _contractAddress)
        view
        external
        returns(uint8) 
    {
        return trustedCurrencyContracts[_contractAddress];
    }

    /**
     * @dev check if a currencyContract is trusted
     *
     * @param _contractAddress The address of the currencyContract
     * @return bool true if contract is trusted
     */
    function isTrustedContract(address _contractAddress)
        public
        view
        returns(bool)
    {
        return trustedCurrencyContracts[_contractAddress] == 1;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title RequestCore
 *
 * @dev The Core is the main contract which stores all the requests.
 *
 * @dev The Core philosophy is to be as much flexible as possible to adapt in the future to any new system
 * @dev All the important conditions and an important part of the business logic takes place in the currency contracts.
 * @dev Requests can only be created in the currency contracts
 * @dev Currency contracts have to be allowed by the Core and respect the business logic.
 * @dev Request Network will develop one currency contracts per currency and anyone can creates its own currency contracts.
 */
contract RequestCore is Administrable {
    using SafeMath for uint256;
    using SafeMathUint96 for uint96;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    enum State { Created, Accepted, Canceled }

    struct Request {
        // ID address of the payer
        address payer;

        // Address of the contract managing the request
        address currencyContract;

        // State of the request
        State state;

        // Main payee
        Payee payee;
    }

    // Structure for the payees. A sub payee is an additional entity which will be paid during the processing of the invoice.
    // ex: can be used for routing taxes or fees at the moment of the payment.
    struct Payee {
        // ID address of the payee
        address addr;

        // amount expected for the payee. 
        // Not uint for evolution (may need negative amounts one day), and simpler operations
        int256 expectedAmount;

        // balance of the payee
        int256 balance;
    }

    // Count of request in the mapping. A maximum of 2^96 requests can be created per Core contract.
    // Integer, incremented for each request of a Core contract, starting from 0
    // RequestId (256bits) = contract address (160bits) + numRequest
    uint96 public numRequests; 
    
    // Mapping of all the Requests. The key is the request ID.
    // not anymore public to avoid "UnimplementedFeatureError: Only in-memory reference type can be stored."
    // https://github.com/ethereum/solidity/issues/3577
    mapping(bytes32 => Request) requests;

    // Mapping of subPayees of the requests. The key is the request ID.
    // This array is outside the Request structure to optimize the gas cost when there is only 1 payee.
    mapping(bytes32 => Payee[256]) public subPayees;

    /*
     *  Events 
     */
    event Created(bytes32 indexed requestId, address indexed payee, address indexed payer, address creator, string data);
    event Accepted(bytes32 indexed requestId);
    event Canceled(bytes32 indexed requestId);

    // Event for Payee & subPayees
    event NewSubPayee(bytes32 indexed requestId, address indexed payee); // Separated from the Created Event to allow a 4th indexed parameter (subpayees)
    event UpdateExpectedAmount(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);
    event UpdateBalance(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);

    /*
     * @dev Function used by currency contracts to create a request in the Core
     *
     * @dev _payees and _expectedAmounts must have the same size
     *
     * @param _creator Request creator. The creator is the one who initiated the request (create or sign) and not necessarily the one who broadcasted it
     * @param _payees array of payees address (the index 0 will be the payee the others are subPayees). Size must be smaller than 256.
     * @param _expectedAmounts array of Expected amount to be received by each payees. Must be in same order than the payees. Size must be smaller than 256.
     * @param _payer Entity expected to pay
     * @param _data data of the request
     * @return Returns the id of the request
     */
    function createRequest(
        address     _creator,
        address[]   _payees,
        int256[]    _expectedAmounts,
        address     _payer,
        string      _data)
        external
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        // creator must not be null
        require(_creator!=0); // not as modifier to lighten the stack
        // call must come from a trusted contract
        require(isTrustedContract(msg.sender)); // not as modifier to lighten the stack

        // Generate the requestId
        requestId = generateRequestId();

        address mainPayee;
        int256 mainExpectedAmount;
        // extract the main payee if filled
        if(_payees.length!=0) {
            mainPayee = _payees[0];
            mainExpectedAmount = _expectedAmounts[0];
        }

        // Store the new request
        requests[requestId] = Request(_payer, msg.sender, State.Created, Payee(mainPayee, mainExpectedAmount, 0));

        // Declare the new request
        Created(requestId, mainPayee, _payer, _creator, _data);
        
        // Store and declare the sub payees (needed in internal function to avoid "stack too deep")
        initSubPayees(requestId, _payees, _expectedAmounts);

        return requestId;
    }

    /*
     * @dev Function used by currency contracts to create a request in the Core from bytes
     * @dev Used to avoid receiving a stack too deep error when called from a currency contract with too many parameters.
     * @audit Note that to optimize the stack size and the gas cost we do not extract the params and store them in the stack. As a result there is some code redundancy
     * @param _data bytes containing all the data packed :
            address(creator)
            address(payer)
            uint8(number_of_payees)
            [
                address(main_payee_address)
                int256(main_payee_expected_amount)
                address(second_payee_address)
                int256(second_payee_expected_amount)
                ...
            ]
            uint8(data_string_size)
            size(data)
     * @return Returns the id of the request 
     */ 
    function createRequestFromBytes(bytes _data) 
        external
        whenNotPaused 
        returns (bytes32 requestId) 
    {
        // call must come from a trusted contract
        require(isTrustedContract(msg.sender)); // not as modifier to lighten the stack

        // extract address creator & payer
        address creator = extractAddress(_data, 0);

        address payer = extractAddress(_data, 20);

        // creator must not be null
        require(creator!=0);
        
        // extract the number of payees
        uint8 payeesCount = uint8(_data[40]);

        // get the position of the dataSize in the byte (= number_of_payees * (address_payee_size + int256_payee_size) + address_creator_size + address_payer_size + payees_count_size
        //                                              (= number_of_payees * (20+32) + 20 + 20 + 1 )
        uint256 offsetDataSize = uint256(payeesCount).mul(52).add(41);

        // extract the data size and then the data itself
        uint8 dataSize = uint8(_data[offsetDataSize]);
        string memory dataStr = extractString(_data, dataSize, offsetDataSize.add(1));

        address mainPayee;
        int256 mainExpectedAmount;
        // extract the main payee if possible
        if(payeesCount!=0) {
            mainPayee = extractAddress(_data, 41);
            mainExpectedAmount = int256(extractBytes32(_data, 61));
        }

        // Generate the requestId
        requestId = generateRequestId();

        // Store the new request
        requests[requestId] = Request(payer, msg.sender, State.Created, Payee(mainPayee, mainExpectedAmount, 0));

        // Declare the new request
        Created(requestId, mainPayee, payer, creator, dataStr);

        // Store and declare the sub payees
        for(uint8 i = 1; i < payeesCount; i = i.add(1)) {
            address subPayeeAddress = extractAddress(_data, uint256(i).mul(52).add(41));

            // payees address cannot be 0x0
            require(subPayeeAddress != 0);

            subPayees[requestId][i-1] =  Payee(subPayeeAddress, int256(extractBytes32(_data, uint256(i).mul(52).add(61))), 0);
            NewSubPayee(requestId, subPayeeAddress);
        }

        return requestId;
    }

    /*
     * @dev Function used by currency contracts to accept a request in the Core.
     * @dev callable only by the currency contract of the request
     * @param _requestId Request id
     */ 
    function accept(bytes32 _requestId) 
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender); 
        r.state = State.Accepted;
        Accepted(_requestId);
    }

    /*
     * @dev Function used by currency contracts to cancel a request in the Core. Several reasons can lead to cancel a request, see request life cycle for more info.
     * @dev callable only by the currency contract of the request
     * @param _requestId Request id
     */ 
    function cancel(bytes32 _requestId)
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender);
        r.state = State.Canceled;
        Canceled(_requestId);
    }   

    /*
     * @dev Function used to update the balance
     * @dev callable only by the currency contract of the request
     * @param _requestId Request id
     * @param _payeeIndex index of the payee (0 = main payee)
     * @param _deltaAmount modifier amount
     */ 
    function updateBalance(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender);

        if( _payeeIndex == 0 ) {
            // modify the main payee
            r.payee.balance = r.payee.balance.add(_deltaAmount);
        } else {
            // modify the sub payee
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.balance = sp.balance.add(_deltaAmount);
        }
        UpdateBalance(_requestId, _payeeIndex, _deltaAmount);
    }

    /*
     * @dev Function update the expectedAmount adding additional or subtract
     * @dev callable only by the currency contract of the request
     * @param _requestId Request id
     * @param _payeeIndex index of the payee (0 = main payee)
     * @param _deltaAmount modifier amount
     */ 
    function updateExpectedAmount(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender); 

        if( _payeeIndex == 0 ) {
            // modify the main payee
            r.payee.expectedAmount = r.payee.expectedAmount.add(_deltaAmount);    
        } else {
            // modify the sub payee
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.expectedAmount = sp.expectedAmount.add(_deltaAmount);
        }
        UpdateExpectedAmount(_requestId, _payeeIndex, _deltaAmount);
    }

    /*
     * @dev Internal: Init payees for a request (needed to avoid &#39;stack too deep&#39; in createRequest())
     * @param _requestId Request id
     * @param _payees array of payees address
     * @param _expectedAmounts array of payees initial expected amounts
     */ 
    function initSubPayees(bytes32 _requestId, address[] _payees, int256[] _expectedAmounts)
        internal
    {
        require(_payees.length == _expectedAmounts.length);
     
        for (uint8 i = 1; i < _payees.length; i = i.add(1))
        {
            // payees address cannot be 0x0
            require(_payees[i] != 0);
            subPayees[_requestId][i-1] = Payee(_payees[i], _expectedAmounts[i], 0);
            NewSubPayee(_requestId, _payees[i]);
        }
    }


    /* GETTER */
    /*
     * @dev Get address of a payee
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return payee address
     */ 
    function getPayeeAddress(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(address)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.addr;
        } else {
            return subPayees[_requestId][_payeeIndex-1].addr;
        }
    }

    /*
     * @dev Get payer of a request
     * @param _requestId Request id
     * @return payer address
     */ 
    function getPayer(bytes32 _requestId)
        public
        constant
        returns(address)
    {
        return requests[_requestId].payer;
    }

    /*
     * @dev Get amount expected of a payee
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return amount expected
     */     
    function getPayeeExpectedAmount(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(int256)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.expectedAmount;
        } else {
            return subPayees[_requestId][_payeeIndex-1].expectedAmount;
        }
    }

    /*
     * @dev Get number of subPayees for a request
     * @param _requestId Request id
     * @return number of subPayees
     */     
    function getSubPayeesCount(bytes32 _requestId)
        public
        constant
        returns(uint8)
    {
        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            // nothing to do
        }
        return i;
    }

    /*
     * @dev Get currencyContract of a request
     * @param _requestId Request id
     * @return currencyContract address
     */
    function getCurrencyContract(bytes32 _requestId)
        public
        constant
        returns(address)
    {
        return requests[_requestId].currencyContract;
    }

    /*
     * @dev Get balance of a payee
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return balance
     */     
    function getPayeeBalance(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(int256)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.balance;    
        } else {
            return subPayees[_requestId][_payeeIndex-1].balance;
        }
    }

    /*
     * @dev Get balance total of a request
     * @param _requestId Request id
     * @return balance
     */     
    function getBalance(bytes32 _requestId)
        public
        constant
        returns(int256)
    {
        int256 balance = requests[_requestId].payee.balance;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            balance = balance.add(subPayees[_requestId][i].balance);
        }

        return balance;
    }


    /*
     * @dev check if all the payees balances are null
     * @param _requestId Request id
     * @return true if all the payees balances are equals to 0
     */     
    function areAllBalanceNull(bytes32 _requestId)
        public
        constant
        returns(bool isNull)
    {
        isNull = requests[_requestId].payee.balance == 0;

        for (uint8 i = 0; isNull && subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            isNull = subPayees[_requestId][i].balance == 0;
        }

        return isNull;
    }

    /*
     * @dev Get total expectedAmount of a request
     * @param _requestId Request id
     * @return balance
     */     
    function getExpectedAmount(bytes32 _requestId)
        public
        constant
        returns(int256)
    {
        int256 expectedAmount = requests[_requestId].payee.expectedAmount;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            expectedAmount = expectedAmount.add(subPayees[_requestId][i].expectedAmount);
        }

        return expectedAmount;
    }

    /*
     * @dev Get state of a request
     * @param _requestId Request id
     * @return state
     */ 
    function getState(bytes32 _requestId)
        public
        constant
        returns(State)
    {
        return requests[_requestId].state;
    }

    /*
     * @dev Get address of a payee
     * @param _requestId Request id
     * @return payee index (0 = main payee) or -1 if not address not found
     */
    function getPayeeIndex(bytes32 _requestId, address _address)
        public
        constant
        returns(int16)
    {
        // return 0 if main payee
        if(requests[_requestId].payee.addr == _address) return 0;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            if(subPayees[_requestId][i].addr == _address) {
                // if found return subPayee index + 1 (0 is main payee)
                return i+1;
            }
        }
        return -1;
    }

    /*
     * @dev getter of a request
     * @param _requestId Request id
     * @return request as a tuple : (address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
     */ 
    function getRequest(bytes32 _requestId) 
        external
        constant
        returns(address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
    {
        Request storage r = requests[_requestId];
        return ( r.payer, 
                 r.currencyContract, 
                 r.state, 
                 r.payee.addr, 
                 r.payee.expectedAmount, 
                 r.payee.balance );
    }

    /*
     * @dev extract a string from a bytes. Extracts a sub-part from tha bytes and convert it to string
     * @param data bytes from where the string will be extracted
     * @param size string size to extract
     * @param _offset position of the first byte of the string in bytes
     * @return string
     */ 
    function extractString(bytes data, uint8 size, uint _offset) 
        internal 
        pure 
        returns (string) 
    {
        bytes memory bytesString = new bytes(size);
        for (uint j = 0; j < size; j++) {
            bytesString[j] = data[_offset+j];
        }
        return string(bytesString);
    }

    /*
     * @dev generate a new unique requestId
     * @return a bytes32 requestId 
     */ 
    function generateRequestId()
        internal
        returns (bytes32)
    {
        // Update numRequest
        numRequests = numRequests.add(1);
        // requestId = ADDRESS_CONTRACT_CORE + numRequests (0xADRRESSCONTRACT00000NUMREQUEST)
        return bytes32((uint256(this) << 96).add(numRequests));
    }

    /*
     * @dev extract an address from a bytes at a given position
     * @param _data bytes from where the address will be extract
     * @param _offset position of the first byte of the address
     * @return address
     */
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m)
    {
        require(offset >=0 && offset + 20 <= _data.length);
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /*
     * @dev extract a bytes32 from a bytes
     * @param data bytes from where the bytes32 will be extract
     * @param offset position of the first byte of the bytes32
     * @return address
     */
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >=0 && offset + 32 <= _data.length);
        assembly {
            bs := mload(add(_data, add(32, offset)))
        }
    }

    /**
     * @dev transfer to owner any tokens send by mistake on this contracts
     * @param token The address of the token to transfer.
     * @param amount The amount to be transfered.
     */
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }
}

/**
 * @title RequestCollectInterface
 *
 * @dev RequestCollectInterface is a contract managing the fees for currency contracts
 */
contract RequestCollectInterface is Pausable {
  using SafeMath for uint256;

    uint256 public rateFeesNumerator;
    uint256 public rateFeesDenominator;
    uint256 public maxFees;

  // address of the contract that will burn req token (through Kyber)
  address public requestBurnerContract;

    /*
     *  Events 
     */
    event UpdateRateFees(uint256 rateFeesNumerator, uint256 rateFeesDenominator);
    event UpdateMaxFees(uint256 maxFees);

  /*
   * @dev Constructor
   * @param _requestBurnerContract Address of the contract where to send the ethers. 
   * This burner contract will have a function that can be called by anyone and will exchange ethers to req via Kyber and burn the REQ
   */  
  function RequestCollectInterface(address _requestBurnerContract) 
    public
  {
    requestBurnerContract = _requestBurnerContract;
  }

  /*
   * @dev send fees to the request burning address
   * @param _amount amount to send to the burning address
   */  
  function collectForREQBurning(uint256 _amount)
    internal
    returns(bool)
  {
    return requestBurnerContract.send(_amount);
  }

  /*
   * @dev compute the fees
   * @param _expectedAmount amount expected for the request
     * @return the expected amount of fees in wei
   */  
  function collectEstimation(int256 _expectedAmount)
    public
    view
    returns(uint256)
  {
    if(_expectedAmount<0) return 0;

    uint256 computedCollect = uint256(_expectedAmount).mul(rateFeesNumerator);

    if(rateFeesDenominator != 0) {
      computedCollect = computedCollect.div(rateFeesDenominator);
    }

    return computedCollect < maxFees ? computedCollect : maxFees;
  }

  /*
   * @dev set the fees rate
     * NB: if the _rateFeesDenominator is 0, it will be treated as 1. (in other words, the computation of the fees will not use it)
   * @param _rateFeesNumerator    numerator rate
   * @param _rateFeesDenominator    denominator rate
   */  
  function setRateFees(uint256 _rateFeesNumerator, uint256 _rateFeesDenominator)
    external
    onlyOwner
  {
    rateFeesNumerator = _rateFeesNumerator;
        rateFeesDenominator = _rateFeesDenominator;
    UpdateRateFees(rateFeesNumerator, rateFeesDenominator);
  }

  /*
   * @dev set the maximum fees in wei
   * @param _newMax new max
   */  
  function setMaxCollectable(uint256 _newMaxFees) 
    external
    onlyOwner
  {
    maxFees = _newMaxFees;
    UpdateMaxFees(maxFees);
  }

  /*
   * @dev set the request burner address
   * @param _requestBurnerContract address of the contract that will burn req token (probably through Kyber)
   */  
  function setRequestBurnerContract(address _requestBurnerContract) 
    external
    onlyOwner
  {
    requestBurnerContract=_requestBurnerContract;
  }

}


/**
 * @title RequestCurrencyContractInterface
 *
 * @dev RequestCurrencyContractInterface is the currency contract managing the request in Ethereum
 * @dev The contract can be paused. In this case, nobody can create Requests anymore but people can still interact with them or withdraw funds.
 *
 * @dev Requests can be created by the Payee with createRequestAsPayee(), by the payer with createRequestAsPayer() or by the payer from a request signed offchain by the payee with broadcastSignedRequestAsPayer
 */
contract RequestCurrencyContractInterface is RequestCollectInterface {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    // RequestCore object
    RequestCore public requestCore;

    /*
     * @dev Constructor
     * @param _requestCoreAddress Request Core address
     */
    function RequestCurrencyContractInterface(address _requestCoreAddress, address _addressBurner) 
        RequestCollectInterface(_addressBurner)
        public
    {
        requestCore=RequestCore(_requestCoreAddress);
    }

    function createCoreRequestInternal(
        address     _payer,
        address[]   _payeesIdAddress,
        int256[]    _expectedAmounts,
        string      _data)
        internal
        whenNotPaused
        returns(bytes32 requestId, int256 totalExpectedAmounts)
    {
        totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1))
        {
            // all expected amount must be positive
            require(_expectedAmounts[i]>=0);
            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

        // store request in the core
        requestId= requestCore.createRequest(msg.sender, _payeesIdAddress, _expectedAmounts, _payer, _data);
    }

    function acceptAction(bytes32 _requestId)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {
        // only a created request can be accepted
        require(requestCore.getState(_requestId)==RequestCore.State.Created);

        // declare the acceptation in the core
        requestCore.accept(_requestId);
    }

    function cancelAction(bytes32 _requestId)
        public
        whenNotPaused
    {
        // payer can cancel if request is just created
        // payee can cancel when request is not canceled yet
        require((requestCore.getPayer(_requestId)==msg.sender && requestCore.getState(_requestId)==RequestCore.State.Created)
                || (requestCore.getPayeeAddress(_requestId,0)==msg.sender && requestCore.getState(_requestId)!=RequestCore.State.Canceled));

        // impossible to cancel a Request with any payees balance != 0
        require(requestCore.areAllBalanceNull(_requestId));

        // declare the cancellation in the core
        requestCore.cancel(_requestId);
    }

    function additionalAction(bytes32 _requestId, uint256[] _additionalAmounts)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {

        // impossible to make additional if request is canceled
        require(requestCore.getState(_requestId)!=RequestCore.State.Canceled);

        // impossible to declare more additionals than the number of payees
        require(_additionalAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        for(uint8 i = 0; i < _additionalAmounts.length; i = i.add(1)) {
            // no need to declare a zero as additional 
            if(_additionalAmounts[i] != 0) {
                // Store and declare the additional in the core
                requestCore.updateExpectedAmount(_requestId, i, _additionalAmounts[i].toInt256Safe());
            }
        }
    }

    function subtractAction(bytes32 _requestId, uint256[] _subtractAmounts)
        public
        whenNotPaused
        onlyRequestPayee(_requestId)
    {
        // impossible to make subtracts if request is canceled
        require(requestCore.getState(_requestId)!=RequestCore.State.Canceled);

        // impossible to declare more subtracts than the number of payees
        require(_subtractAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        for(uint8 i = 0; i < _subtractAmounts.length; i = i.add(1)) {
            // no need to declare a zero as subtracts 
            if(_subtractAmounts[i] != 0) {
                // subtract must be equal or lower than amount expected
                require(requestCore.getPayeeExpectedAmount(_requestId,i) >= _subtractAmounts[i].toInt256Safe());
                // Store and declare the subtract in the core
                requestCore.updateExpectedAmount(_requestId, i, -_subtractAmounts[i].toInt256Safe());
            }
        }
    }
    // ----------------------------------------------------------------------------------------

    /*
     * @dev Modifier to check if msg.sender is the main payee
     * @dev Revert if msg.sender is not the main payee
     * @param _requestId id of the request
     */ 
    modifier onlyRequestPayee(bytes32 _requestId)
    {
        require(requestCore.getPayeeAddress(_requestId, 0)==msg.sender);
        _;
    }

    /*
     * @dev Modifier to check if msg.sender is payer
     * @dev Revert if msg.sender is not payer
     * @param _requestId id of the request
     */ 
    modifier onlyRequestPayer(bytes32 _requestId)
    {
        require(requestCore.getPayer(_requestId)==msg.sender);
        _;
    }
}

/**
 * @title RequestBitcoinNodesValidation
 *
 * @dev RequestBitcoinNodesValidation is the currency contract managing the request in Bitcoin
 * @dev The contract can be paused. In this case, nobody can create Requests anymore but people can still interact with them or withdraw funds.
 *
 * @dev Requests can be created by the Payee with createRequestAsPayee(), by the payer with createRequestAsPayer() or by the payer from a request signed offchain by the payee with broadcastSignedRequestAsPayer
 */
contract RequestBitcoinNodesValidation is RequestCurrencyContractInterface {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    // bitcoin addresses for payment and refund by requestid
    // every time a transaction is sent to one of these addresses, it will be interpreted offchain as a payment (index 0 is the main payee, next indexes are for sub-payee)
    mapping(bytes32 => string[256]) public payeesPaymentAddress;
    // every time a transaction is sent to one of these addresses, it will be interpreted offchain as a refund (index 0 is the main payee, next indexes are for sub-payee)
    mapping(bytes32 => string[256]) public payerRefundAddress;

    /*
     * @dev Constructor
     * @param _requestCoreAddress Request Core address
     * @param _requestBurnerAddress Request Burner contract address
     */
    function RequestBitcoinNodesValidation(address _requestCoreAddress, address _requestBurnerAddress) 
        RequestCurrencyContractInterface(_requestCoreAddress, _requestBurnerAddress)
        public
    {
        // nothing to do here
    }

    /*
     * @dev Function to create a request as payee
     *
     * @dev msg.sender must be the main payee
     *
     * @param _payeesIdAddress array of payees address (the index 0 will be the payee - must be msg.sender - the others are subPayees)
     * @param _payeesPaymentAddress array of payees bitcoin address for payment as bytes (bitcoin address don&#39;t have a fixed size)
     *                                           [
     *                                            uint8(payee1_bitcoin_address_size)
     *                                            string(payee1_bitcoin_address)
     *                                            uint8(payee2_bitcoin_address_size)
     *                                            string(payee2_bitcoin_address)
     *                                            ...
     *                                           ]
     * @param _expectedAmounts array of Expected amount to be received by each payees
     * @param _payer Entity expected to pay
     * @param _payerRefundAddress payer bitcoin addresses for refund as bytes (bitcoin address don&#39;t have a fixed size)
     *                                           [
     *                                            uint8(payee1_refund_bitcoin_address_size)
     *                                            string(payee1_refund_bitcoin_address)
     *                                            uint8(payee2_refund_bitcoin_address_size)
     *                                            string(payee2_refund_bitcoin_address)
     *                                            ...
     *                                           ]
     * @param _data Hash linking to additional data on the Request stored on IPFS
     *
     * @return Returns the id of the request
     */
    function createRequestAsPayeeAction(
        address[]    _payeesIdAddress,
        bytes        _payeesPaymentAddress,
        int256[]     _expectedAmounts,
        address      _payer,
        bytes        _payerRefundAddress,
        string       _data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender == _payeesIdAddress[0] && msg.sender != _payer && _payer != 0);

        int256 totalExpectedAmounts;
        (requestId, totalExpectedAmounts) = createCoreRequestInternal(_payer, _payeesIdAddress, _expectedAmounts, _data);
        
        // compute and send fees
        uint256 fees = collectEstimation(totalExpectedAmounts);
        require(fees == msg.value && collectForREQBurning(fees));
    
        extractAndStoreBitcoinAddresses(requestId, _payeesIdAddress.length, _payeesPaymentAddress, _payerRefundAddress);
        
        return requestId;
    }

    /*
     * @dev Internal function to extract and store bitcoin addresses from bytes
     *
     * @param _requestId                id of the request
     * @param _payeesCount              number of payees
     * @param _payeesPaymentAddress     array of payees bitcoin address for payment as bytes
     *                                           [
     *                                            uint8(payee1_bitcoin_address_size)
     *                                            string(payee1_bitcoin_address)
     *                                            uint8(payee2_bitcoin_address_size)
     *                                            string(payee2_bitcoin_address)
     *                                            ...
     *                                           ]
     * @param _payerRefundAddress       payer bitcoin addresses for refund as bytes
     *                                           [
     *                                            uint8(payee1_refund_bitcoin_address_size)
     *                                            string(payee1_refund_bitcoin_address)
     *                                            uint8(payee2_refund_bitcoin_address_size)
     *                                            string(payee2_refund_bitcoin_address)
     *                                            ...
     *                                           ]
     */
    function extractAndStoreBitcoinAddresses(
        bytes32     _requestId,
        uint256     _payeesCount,
        bytes       _payeesPaymentAddress,
        bytes       _payerRefundAddress) 
        internal
    {
        // set payment addresses for payees
        uint256 cursor = 0;
        uint8 sizeCurrentBitcoinAddress;
        uint8 j;
        for (j = 0; j < _payeesCount; j = j.add(1)) {
            // get the size of the current bitcoin address
            sizeCurrentBitcoinAddress = uint8(_payeesPaymentAddress[cursor]);

            // extract and store the current bitcoin address
            payeesPaymentAddress[_requestId][j] = extractString(_payeesPaymentAddress, sizeCurrentBitcoinAddress, ++cursor);

            // move the cursor to the next bicoin address
            cursor += sizeCurrentBitcoinAddress;
        }

        // set payment address for payer
        cursor = 0;
        for (j = 0; j < _payeesCount; j = j.add(1)) {
            // get the size of the current bitcoin address
            sizeCurrentBitcoinAddress = uint8(_payerRefundAddress[cursor]);

            // extract and store the current bitcoin address
            payerRefundAddress[_requestId][j] = extractString(_payerRefundAddress, sizeCurrentBitcoinAddress, ++cursor);

            // move the cursor to the next bicoin address
            cursor += sizeCurrentBitcoinAddress;
        }
    }

    /*
     * @dev Function to broadcast and accept an offchain signed request (the broadcaster can also pays and makes additionals )
     *
     * @dev msg.sender will be the _payer
     * @dev only the _payer can additionals
     *
     * @param _requestData nested bytes containing : creator, payer, payees|expectedAmounts, data
     * @param _payeesPaymentAddress array of payees bitcoin address for payment as bytes
     *                                           [
     *                                            uint8(payee1_bitcoin_address_size)
     *                                            string(payee1_bitcoin_address)
     *                                            uint8(payee2_bitcoin_address_size)
     *                                            string(payee2_bitcoin_address)
     *                                            ...
     *                                           ]
     * @param _payerRefundAddress payer bitcoin addresses for refund as bytes
     *                                           [
     *                                            uint8(payee1_refund_bitcoin_address_size)
     *                                            string(payee1_refund_bitcoin_address)
     *                                            uint8(payee2_refund_bitcoin_address_size)
     *                                            string(payee2_refund_bitcoin_address)
     *                                            ...
     *                                           ]
     * @param _additionals array to increase the ExpectedAmount for payees
     * @param _expirationDate timestamp after that the signed request cannot be broadcasted
     * @param _signature ECDSA signature in bytes
     *
     * @return Returns the id of the request
     */
    function broadcastSignedRequestAsPayerAction(
        bytes         _requestData, // gather data to avoid "stack too deep"
        bytes         _payeesPaymentAddress,
        bytes         _payerRefundAddress,
        uint256[]     _additionals,
        uint256       _expirationDate,
        bytes         _signature)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        // check expiration date
        require(_expirationDate >= block.timestamp);

        // check the signature
        require(checkRequestSignature(_requestData, _payeesPaymentAddress, _expirationDate, _signature));

        return createAcceptAndAdditionalsFromBytes(_requestData, _payeesPaymentAddress, _payerRefundAddress, _additionals);
    }

    /*
     * @dev Internal function to create, accept and add additionals to a request as Payer
     *
     * @dev msg.sender must be _payer
     *
     * @param _requestData nasty bytes containing : creator, payer, payees|expectedAmounts, data
     * @param _payeesPaymentAddress array of payees bitcoin address for payment
     * @param _payerRefundAddress payer bitcoin address for refund
     * @param _additionals Will increase the ExpectedAmount of the request right after its creation by adding additionals
     *
     * @return Returns the id of the request
     */
    function createAcceptAndAdditionalsFromBytes(
        bytes         _requestData,
        bytes         _payeesPaymentAddress,
        bytes         _payerRefundAddress,
        uint256[]     _additionals)
        internal
        returns(bytes32 requestId)
    {
        // extract main payee
        address mainPayee = extractAddress(_requestData, 41);
        require(msg.sender != mainPayee && mainPayee != 0);
        // creator must be the main payee
        require(extractAddress(_requestData, 0) == mainPayee);

        // extract the number of payees
        uint8 payeesCount = uint8(_requestData[40]);
        int256 totalExpectedAmounts = 0;
        for(uint8 i = 0; i < payeesCount; i++) {
            // extract the expectedAmount for the payee[i]
            int256 expectedAmountTemp = int256(extractBytes32(_requestData, uint256(i).mul(52).add(61)));
            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(expectedAmountTemp);
            // all expected amount must be positive
            require(expectedAmountTemp>0);
        }

        // compute and send fees
        uint256 fees = collectEstimation(totalExpectedAmounts);
        // check fees has been well received
        require(fees == msg.value && collectForREQBurning(fees));

        // insert the msg.sender as the payer in the bytes
        updateBytes20inBytes(_requestData, 20, bytes20(msg.sender));
        // store request in the core
        requestId = requestCore.createRequestFromBytes(_requestData);
        
        // set bitcoin addresses
        extractAndStoreBitcoinAddresses(requestId, payeesCount, _payeesPaymentAddress, _payerRefundAddress);

        // accept and pay the request with the value remaining after the fee collect
        acceptAndAdditionals(requestId, _additionals);

        return requestId;
    }

    /*
     * @dev Internal function to accept and add additionals to a request as Payer
     *
     * @param _requestId id of the request
     * @param _additionals Will increase the ExpectedAmounts of payees
     *
     */    
    function acceptAndAdditionals(
        bytes32     _requestId,
        uint256[]   _additionals)
        internal
    {
        acceptAction(_requestId);
        
        additionalAction(_requestId, _additionals);
    }
    // -----------------------------------------------------------------------------

    /*
     * @dev Check the validity of a signed request & the expiration date
     * @param _data bytes containing all the data packed :
            address(creator)
            address(payer)
            uint8(number_of_payees)
            [
                address(main_payee_address)
                int256(main_payee_expected_amount)
                address(second_payee_address)
                int256(second_payee_expected_amount)
                ...
            ]
            uint8(data_string_size)
            size(data)
     * @param _payeesPaymentAddress array of payees payment addresses (the index 0 will be the payee the others are subPayees)
     * @param _expirationDate timestamp after that the signed request cannot be broadcasted
       * @param _signature ECDSA signature containing v, r and s as bytes
       *
     * @return Validity of order signature.
     */    
    function checkRequestSignature(
        bytes         _requestData,
        bytes         _payeesPaymentAddress,
        uint256       _expirationDate,
        bytes         _signature)
        public
        view
        returns (bool)
    {
        bytes32 hash = getRequestHash(_requestData, _payeesPaymentAddress, _expirationDate);

        // extract "v, r, s" from the signature
        uint8 v = uint8(_signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = extractBytes32(_signature, 0);
        bytes32 s = extractBytes32(_signature, 32);

        // check signature of the hash with the creator address
        return isValidSignature(extractAddress(_requestData, 0), hash, v, r, s);
    }

    /*
     * @dev Function internal to calculate Keccak-256 hash of a request with specified parameters
     *
     * @param _data bytes containing all the data packed
     * @param _payeesPaymentAddress array of payees payment addresses
     * @param _expirationDate timestamp after what the signed request cannot be broadcasted
     *
     * @return Keccak-256 hash of (this,_requestData, _payeesPaymentAddress, _expirationDate)
     */
    function getRequestHash(
        bytes       _requestData,
        bytes       _payeesPaymentAddress,
        uint256     _expirationDate)
        internal
        view
        returns(bytes32)
    {
        return keccak256(this,_requestData, _payeesPaymentAddress, _expirationDate);
    }

    /*
     * @dev Verifies that a hash signature is valid. 0x style
     * @param signer address of signer.
     * @param hash Signed Keccak-256 hash.
     * @param v ECDSA signature parameter v.
     * @param r ECDSA signature parameters r.
     * @param s ECDSA signature parameters s.
     * @return Validity of order signature.
     */
    function isValidSignature(
        address     signer,
        bytes32     hash,
        uint8       v,
        bytes32     r,
        bytes32     s)
        public
        pure
        returns (bool)
    {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }

    /*
     * @dev extract an address in a bytes
     * @param data bytes from where the address will be extract
     * @param offset position of the first byte of the address
     * @return address
     */
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m) 
    {
        require(offset >=0 && offset + 20 <= _data.length);
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /*
     * @dev extract a bytes32 from a bytes
     * @param data bytes from where the bytes32 will be extract
     * @param offset position of the first byte of the bytes32
     * @return address
     */
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >=0 && offset + 32 <= _data.length);
        assembly {
            bs := mload(add(_data, add(32, offset)))
        }
    }

    /*
     * @dev modify 20 bytes in a bytes
     * @param data bytes to modify
     * @param offset position of the first byte to modify
     * @param b bytes20 to insert
     * @return address
     */
    function updateBytes20inBytes(bytes data, uint offset, bytes20 b)
        internal
        pure
    {
        require(offset >=0 && offset + 20 <= data.length);
        assembly {
            let m := mload(add(data, add(20, offset)))
            m := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000)
            m := or(m, div(b, 0x1000000000000000000000000))
            mstore(add(data, add(20, offset)), m)
        }
    }

    /*
     * @dev extract a string from a bytes. Extracts a sub-part from tha bytes and convert it to string
     * @param data bytes from where the string will be extracted
     * @param size string size to extract
     * @param _offset position of the first byte of the string in bytes
     * @return string
     */ 
    function extractString(bytes data, uint8 size, uint _offset) 
        internal 
        pure 
        returns (string) 
    {
        bytes memory bytesString = new bytes(size);
        for (uint j = 0; j < size; j++) {
            bytesString[j] = data[_offset+j];
        }
        return string(bytesString);
    }
}