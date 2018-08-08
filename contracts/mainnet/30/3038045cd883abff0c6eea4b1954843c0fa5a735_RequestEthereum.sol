pragma solidity 0.4.18;

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
 * @title RequestEthereumCollect
 *
 * @dev RequestEthereumCollect is a contract managing the fees for ethereum currency contract
 */
contract RequestEthereumCollect is Pausable {
    using SafeMath for uint256;

    // fees percentage (per 10 000)
    uint256 public feesPer10000;

    // maximum fees in wei
    uint256 public maxFees;

    // address of the contract that will burn req token (probably through Kyber)
    address public requestBurnerContract;

    /*
     * @dev Constructor
     * @param _requestBurnerContract Address of the contract where to send the ethers. 
     * This burner contract will have a function that can be called by anyone and will exchange ethers to req via Kyber and burn the REQ
     */  
    function RequestEthereumCollect(address _requestBurnerContract) 
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
     * @return 
     */  
    function collectEstimation(int256 _expectedAmount)
        public
        view
        returns(uint256)
    {
        // Force potential negative number to 0
        if (_expectedAmount <= 0) {
            return 0;
        }
        uint256 computedCollect = uint256(_expectedAmount).mul(feesPer10000).div(10000);
        return computedCollect < maxFees ? computedCollect : maxFees;
    }

    /*
     * @dev set the fees rate (per 10 000)
     * @param _newRate new rate
     * @return 
     */  
    function setFeesPerTenThousand(uint256 _newRate) 
        external
        onlyOwner
    {
        feesPer10000=_newRate;
    }

    /*
     * @dev set the maximum fees in wei
     * @param _newMax new max
     * @return 
     */  
    function setMaxCollectable(uint256 _newMax) 
        external
        onlyOwner
    {
        maxFees=_newMax;
    }

    /*
     * @dev set the request burner address
     * @param _requestBurnerContract address of the contract that will burn req token (probably through Kyber)
     * @return 
     */  
    function setRequestBurnerContract(address _requestBurnerContract) 
        external
        onlyOwner
    {
        requestBurnerContract=_requestBurnerContract;
    }
}



/**
 * @title RequestEthereum
 *
 * @dev RequestEthereum is the currency contract managing the request in Ethereum
 * @dev The contract can be paused. In this case, nobody can create Requests anymore but people can still interact with them.
 *
 * @dev Requests can be created by the Payee with createRequestAsPayee(), by the payer with createRequestAsPayer() or by the payer from a request signed offchain by the payee with broadcastSignedRequestAsPayer()
 */
contract RequestEthereum is RequestEthereumCollect {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    // RequestCore object
    RequestCore public requestCore;

    // payment addresses by requestId (optional). We separate the Identity of the payee/payer (in the core) and the wallet address in the currency contract
    mapping(bytes32 => address[256]) public payeesPaymentAddress;
    mapping(bytes32 => address) public payerRefundAddress;

    /*
     * @dev Constructor
     * @param _requestCoreAddress Request Core address
     * @param _requestBurnerAddress Request Burner contract address
     */
    function RequestEthereum(address _requestCoreAddress, address _requestBurnerAddress) RequestEthereumCollect(_requestBurnerAddress) public
    {
        requestCore=RequestCore(_requestCoreAddress);
    }

    /*
     * @dev Function to create a request as payee
     *
     * @dev msg.sender will be the payee
     * @dev if _payeesPaymentAddress.length > _payeesIdAddress.length, the extra addresses will be stored but never used
     * @dev If a contract is given as a payee make sure it is payable. Otherwise, the request will not be payable.
     *
     * @param _payeesIdAddress array of payees address (the index 0 will be the payee - must be msg.sender - the others are subPayees)
     * @param _payeesPaymentAddress array of payees address for payment (optional)
     * @param _expectedAmounts array of Expected amount to be received by each payees
     * @param _payer Entity expected to pay
     * @param _payerRefundAddress Address of refund for the payer (optional)
     * @param _data Hash linking to additional data on the Request stored on IPFS
     *
     * @return Returns the id of the request
     */
    function createRequestAsPayee(
        address[]   _payeesIdAddress,
        address[]   _payeesPaymentAddress,
        int256[]    _expectedAmounts,
        address     _payer,
        address     _payerRefundAddress,
        string      _data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender == _payeesIdAddress[0] && msg.sender != _payer && _payer != 0);

        uint256 fees;
        (requestId, fees) = createRequest(_payer, _payeesIdAddress, _payeesPaymentAddress, _expectedAmounts, _payerRefundAddress, _data);

        // check if the value send match exactly the fees (no under or over payment allowed)
        require(fees == msg.value);

        return requestId;
    }

    /*
     * @dev Function to create a request as payer. The request is payed if _payeeAmounts > 0.
     *
     * @dev msg.sender will be the payer
     * @dev If a contract is given as a payee make sure it is payable. Otherwise, the request will not be payable.
     *
     * @param _payeesIdAddress array of payees address (the index 0 will be the payee the others are subPayees)
     * @param _expectedAmounts array of Expected amount to be received by each payees
     * @param _payerRefundAddress Address of refund for the payer (optional)
     * @param _payeeAmounts array of amount repartition for the payment
     * @param _additionals array to increase the ExpectedAmount for payees
     * @param _data Hash linking to additional data on the Request stored on IPFS
     *
     * @return Returns the id of the request
     */
    function createRequestAsPayer(
        address[]   _payeesIdAddress,
        int256[]    _expectedAmounts,
        address     _payerRefundAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals,
        string      _data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender != _payeesIdAddress[0] && _payeesIdAddress[0] != 0);

        // payeesPaymentAddress is not offered as argument here to avoid scam
        address[] memory emptyPayeesPaymentAddress = new address[](0);
        uint256 fees;
        (requestId, fees) = createRequest(msg.sender, _payeesIdAddress, emptyPayeesPaymentAddress, _expectedAmounts, _payerRefundAddress, _data);

        // accept and pay the request with the value remaining after the fee collect
        acceptAndPay(requestId, _payeeAmounts, _additionals, msg.value.sub(fees));

        return requestId;
    }


    /*
     * @dev Function to broadcast and accept an offchain signed request (can be paid and additionals also)
     *
     * @dev _payer will be set msg.sender
     * @dev if _payeesPaymentAddress.length > _requestData.payeesIdAddress.length, the extra addresses will be stored but never used
     * @dev If a contract is given as a payee make sure it is payable. Otherwise, the request will not be payable.
     *
     * @param _requestData nested bytes containing : creator, payer, payees, expectedAmounts, data
     * @param _payeesPaymentAddress array of payees address for payment (optional) 
     * @param _payeeAmounts array of amount repartition for the payment
     * @param _additionals array to increase the ExpectedAmount for payees
     * @param _expirationDate timestamp after that the signed request cannot be broadcasted
     * @param _signature ECDSA signature in bytes
     *
     * @return Returns the id of the request
     */
    function broadcastSignedRequestAsPayer(
        bytes       _requestData, // gather data to avoid "stack too deep"
        address[]   _payeesPaymentAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals,
        uint256     _expirationDate,
        bytes       _signature)
        external
        payable
        whenNotPaused
        returns(bytes32)
    {
        // check expiration date
        require(_expirationDate >= block.timestamp);

        // check the signature
        require(checkRequestSignature(_requestData, _payeesPaymentAddress, _expirationDate, _signature));

        // create accept and pay the request
        return createAcceptAndPayFromBytes(_requestData,  _payeesPaymentAddress, _payeeAmounts, _additionals);
    }

    /*
     * @dev Internal function to create, accept, add additionals and pay a request as Payer
     *
     * @dev msg.sender must be _payer
     *
     * @param _requestData nasty bytes containing : creator, payer, payees|expectedAmounts, data
     * @param _payeesPaymentAddress array of payees address for payment (optional)
     * @param _payeeAmounts array of amount repartition for the payment
     * @param _additionals Will increase the ExpectedAmount of the request right after its creation by adding additionals
     *
     * @return Returns the id of the request
     */
    function createAcceptAndPayFromBytes(
        bytes       _requestData,
        address[]   _payeesPaymentAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals)
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
            // NB: no need of SafeMath here because 0 < i < 256 (uint8)
            int256 expectedAmountTemp = int256(extractBytes32(_requestData, 61 + 52 * uint256(i)));
            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(expectedAmountTemp);
            // all expected amount must be positibe
            require(expectedAmountTemp>0);
        }

        // collect the fees
        uint256 fees = collectEstimation(totalExpectedAmounts);

        // check fees has been well received
        // do the action and assertion in one to save a variable
        require(collectForREQBurning(fees));

        // insert the msg.sender as the payer in the bytes
        updateBytes20inBytes(_requestData, 20, bytes20(msg.sender));
        // store request in the core,
        requestId = requestCore.createRequestFromBytes(_requestData);

        // set payment addresses for payees
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }

        // accept and pay the request with the value remaining after the fee collect
        acceptAndPay(requestId, _payeeAmounts, _additionals, msg.value.sub(fees));

        return requestId;
    }


    /*
     * @dev Internal function to create a request
     *
     * @dev msg.sender is the creator of the request
     *
     * @param _payer Payer identity address
     * @param _payees Payees identity address
     * @param _payeesPaymentAddress Payees payment address
     * @param _expectedAmounts Expected amounts to be received by payees
     * @param _payerRefundAddress payer refund address
     * @param _data Hash linking to additional data on the Request stored on IPFS
     *
     * @return Returns the id of the request
     */
    function createRequest(
        address     _payer,
        address[]   _payees,
        address[]   _payeesPaymentAddress,
        int256[]    _expectedAmounts,
        address     _payerRefundAddress,
        string      _data)
        internal
        returns(bytes32 requestId, uint256 fees)
    {
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1))
        {
            // all expected amount must be positive
            require(_expectedAmounts[i]>=0);
            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

        // collect the fees
        fees = collectEstimation(totalExpectedAmounts);
        // check fees has been well received
        require(collectForREQBurning(fees));

        // store request in the core
        requestId= requestCore.createRequest(msg.sender, _payees, _expectedAmounts, _payer, _data);

        // set payment addresses for payees
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }
        // set payment address for payer
        if(_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }
    }

    /*
     * @dev Internal function to accept, add additionals and pay a request as Payer
     *
     * @param _requestId id of the request
     * @param _payeesAmounts Amount to pay to payees (sum must be equals to _amountPaid)
     * @param _additionals Will increase the ExpectedAmounts of payees
     * @param _amountPaid amount in msg.value minus the fees
     *
     */ 
    function acceptAndPay(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionals,
        uint256 _amountPaid)
        internal
    {
        requestCore.accept(_requestId);
        
        additionalInternal(_requestId, _additionals);

        if(_amountPaid > 0) {
            paymentInternal(_requestId, _payeeAmounts, _amountPaid);
        }
    }

    // ---- INTERFACE FUNCTIONS ------------------------------------------------------------------------------------

    /*
     * @dev Function to accept a request
     *
     * @dev msg.sender must be _payer
     * @dev A request can also be accepted by using directly the payment function on a request in the Created status
     *
     * @param _requestId id of the request
     */
    function accept(bytes32 _requestId)
        external
        whenNotPaused
        condition(requestCore.getPayer(_requestId)==msg.sender)
        condition(requestCore.getState(_requestId)==RequestCore.State.Created)
    {
        requestCore.accept(_requestId);
    }

    /*
     * @dev Function to cancel a request
     *
     * @dev msg.sender must be the _payer or the _payee.
     * @dev only request with balance equals to zero can be cancel
     *
     * @param _requestId id of the request
     */
    function cancel(bytes32 _requestId)
        external
        whenNotPaused
    {
        // payer can cancel if request is just created
        bool isPayerAndCreated = requestCore.getPayer(_requestId)==msg.sender && requestCore.getState(_requestId)==RequestCore.State.Created;

        // payee can cancel when request is not canceled yet
        bool isPayeeAndNotCanceled = requestCore.getPayeeAddress(_requestId,0)==msg.sender && requestCore.getState(_requestId)!=RequestCore.State.Canceled;

        require(isPayerAndCreated || isPayeeAndNotCanceled);

        // impossible to cancel a Request with any payees balance != 0
        require(requestCore.areAllBalanceNull(_requestId));

        requestCore.cancel(_requestId);
    }

    // ----------------------------------------------------------------------------------------


    // ---- CONTRACT FUNCTIONS ------------------------------------------------------------------------------------
    /*
     * @dev Function PAYABLE to pay a request in ether.
     *
     * @dev the request will be automatically accepted if msg.sender==payer.
     *
     * @param _requestId id of the request
     * @param _payeesAmounts Amount to pay to payees (sum must be equal to msg.value) in wei
     * @param _additionalsAmount amount of additionals per payee in wei to declare
     */
    function paymentAction(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionalAmounts)
        external
        whenNotPaused
        payable
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        condition(_additionalAmounts.length == 0 || msg.sender == requestCore.getPayer(_requestId))
    {
        // automatically accept request if request is created and msg.sender is payer
        if(requestCore.getState(_requestId)==RequestCore.State.Created && msg.sender == requestCore.getPayer(_requestId)) {
            requestCore.accept(_requestId);
        }

        additionalInternal(_requestId, _additionalAmounts);

        paymentInternal(_requestId, _payeeAmounts, msg.value);
    }

    /*
     * @dev Function PAYABLE to pay back in ether a request to the payer
     *
     * @dev msg.sender must be one of the payees
     * @dev the request must be created or accepted
     *
     * @param _requestId id of the request
     */
    function refundAction(bytes32 _requestId)
        external
        whenNotPaused
        payable
    {
        refundInternal(_requestId, msg.sender, msg.value);
    }

    /*
     * @dev Function to declare a subtract
     *
     * @dev msg.sender must be _payee
     * @dev the request must be accepted or created
     *
     * @param _requestId id of the request
     * @param _subtractAmounts amounts of subtract in wei to declare (index 0 is for main payee)
     */
    function subtractAction(bytes32 _requestId, uint256[] _subtractAmounts)
        external
        whenNotPaused
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        onlyRequestPayee(_requestId)
    {
        for(uint8 i = 0; i < _subtractAmounts.length; i = i.add(1)) {
            if(_subtractAmounts[i] != 0) {
                // subtract must be equal or lower than amount expected
                require(requestCore.getPayeeExpectedAmount(_requestId,i) >= _subtractAmounts[i].toInt256Safe());
                // store and declare the subtract in the core
                requestCore.updateExpectedAmount(_requestId, i, -_subtractAmounts[i].toInt256Safe());
            }
        }
    }

    /*
     * @dev Function to declare an additional
     *
     * @dev msg.sender must be _payer
     * @dev the request must be accepted or created
     *
     * @param _requestId id of the request
     * @param _additionalAmounts amounts of additional in wei to declare (index 0 is for main payee)
     */
    function additionalAction(bytes32 _requestId, uint256[] _additionalAmounts)
        external
        whenNotPaused
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        onlyRequestPayer(_requestId)
    {
        additionalInternal(_requestId, _additionalAmounts);
    }
    // ----------------------------------------------------------------------------------------


    // ---- INTERNAL FUNCTIONS ------------------------------------------------------------------------------------
    /*
     * @dev Function internal to manage additional declaration
     *
     * @param _requestId id of the request
     * @param _additionalAmounts amount of additional to declare
     */
    function additionalInternal(bytes32 _requestId, uint256[] _additionalAmounts)
        internal
    {
        // we cannot have more additional amounts declared than actual payees but we can have fewer
        require(_additionalAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        for(uint8 i = 0; i < _additionalAmounts.length; i = i.add(1)) {
            if(_additionalAmounts[i] != 0) {
                // Store and declare the additional in the core
                requestCore.updateExpectedAmount(_requestId, i, _additionalAmounts[i].toInt256Safe());
            }
        }
    }

    /*
     * @dev Function internal to manage payment declaration
     *
     * @param _requestId id of the request
     * @param _payeesAmounts Amount to pay to payees (sum must be equals to msg.value)
     * @param _value amount paid
     */
    function paymentInternal(
        bytes32     _requestId,
        uint256[]   _payeeAmounts,
        uint256     _value)
        internal
    {
        // we cannot have more amounts declared than actual payees
        require(_payeeAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        uint256 totalPayeeAmounts = 0;

        for(uint8 i = 0; i < _payeeAmounts.length; i = i.add(1)) {
            if(_payeeAmounts[i] != 0) {
                // compute the total amount declared
                totalPayeeAmounts = totalPayeeAmounts.add(_payeeAmounts[i]);

                // Store and declare the payment to the core
                requestCore.updateBalance(_requestId, i, _payeeAmounts[i].toInt256Safe());

                // pay the payment address if given, the id address otherwise
                address addressToPay;
                if(payeesPaymentAddress[_requestId][i] == 0) {
                    addressToPay = requestCore.getPayeeAddress(_requestId, i);
                } else {
                    addressToPay = payeesPaymentAddress[_requestId][i];
                }

                //payment done, the money was sent
                fundOrderInternal(addressToPay, _payeeAmounts[i]);
            }
        }

        // check if payment repartition match the value paid
        require(_value==totalPayeeAmounts);
    }

    /*
     * @dev Function internal to manage refund declaration
     *
     * @param _requestId id of the request

     * @param _fromAddress address from where the refund has been done
     * @param _amount amount of the refund in wei to declare
     *
     * @return true if the refund is done, false otherwise
     */
    function refundInternal(
        bytes32 _requestId,
        address _fromAddress,
        uint256 _amount)
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        internal
    {
        // Check if the _fromAddress is a payeesId
        // int16 to allow -1 value
        int16 payeeIndex = requestCore.getPayeeIndex(_requestId, _fromAddress);
        if(payeeIndex < 0) {
            uint8 payeesCount = requestCore.getSubPayeesCount(_requestId).add(1);

            // if not ID addresses maybe in the payee payments addresses
            for (uint8 i = 0; i < payeesCount && payeeIndex == -1; i = i.add(1)) {
                if(payeesPaymentAddress[_requestId][i] == _fromAddress) {
                    // get the payeeIndex
                    payeeIndex = int16(i);
                }
            }
        }
        // the address must be found somewhere
        require(payeeIndex >= 0); 

        // Casting to uin8 doesn&#39;t lose bits because payeeIndex < 256. payeeIndex was declared int16 to allow -1
        requestCore.updateBalance(_requestId, uint8(payeeIndex), -_amount.toInt256Safe());

        // refund to the payment address if given, the id address otherwise
        address addressToPay = payerRefundAddress[_requestId];
        if(addressToPay == 0) {
            addressToPay = requestCore.getPayer(_requestId);
        }

        // refund declared, the money is ready to be sent to the payer
        fundOrderInternal(addressToPay, _amount);
    }

    /*
     * @dev Function internal to manage fund mouvement
     * @dev We had to chose between a withdrawal pattern, a transfer pattern or a transfer+withdrawal pattern and chose the transfer pattern.
     * @dev The withdrawal pattern would make UX difficult. The transfer+withdrawal pattern would make contracts interacting with the request protocol complex.
     * @dev N.B.: The transfer pattern will have to be clearly explained to users. It enables a payee to create unpayable requests.
     *
     * @param _recipient address where the wei has to be sent to
     * @param _amount amount in wei to send
     *
     */
    function fundOrderInternal(
        address _recipient,
        uint256 _amount)
        internal
    {
        _recipient.transfer(_amount);
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
        // _requestData is from the core
        bytes       _requestData,

        // _payeesPaymentAddress and _expirationDate are not from the core but needs to be signed
        address[]   _payeesPaymentAddress,
        uint256     _expirationDate)
        internal
        view
        returns(bytes32)
    {
        return keccak256(this, _requestData, _payeesPaymentAddress, _expirationDate);
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
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s)
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
        bytes       _requestData,
        address[]   _payeesPaymentAddress,
        uint256     _expirationDate,
        bytes       _signature)
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

    //modifier
    modifier condition(bool c)
    {
        require(c);
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