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