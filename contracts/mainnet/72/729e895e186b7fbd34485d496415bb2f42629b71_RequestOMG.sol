pragma solidity ^0.4.23;


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
 * @title Bytes util library.
 * @notice Collection of utility functions to manipulate bytes for Request.
 */
library Bytes {
    /**
     * @notice Extracts an address in a bytes.
     * @param data bytes from where the address will be extract
     * @param offset position of the first byte of the address
     * @return address
     */
    function extractAddress(bytes data, uint offset)
        internal
        pure
        returns (address m) 
    {
        require(offset >= 0 && offset + 20 <= data.length, "offset value should be in the correct range");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            m := and(
                mload(add(data, add(20, offset))), 
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        }
    }

    /**
     * @notice Extract a bytes32 from a bytes.
     * @param data bytes from where the bytes32 will be extract
     * @param offset position of the first byte of the bytes32
     * @return address
     */
    function extractBytes32(bytes data, uint offset)
        internal
        pure
        returns (bytes32 bs)
    {
        require(offset >= 0 && offset + 32 <= data.length, "offset value should be in the correct range");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            bs := mload(add(data, add(32, offset)))
        }
    }

    /**
     * @notice Modifies 20 bytes in a bytes.
     * @param data bytes to modify
     * @param offset position of the first byte to modify
     * @param b bytes20 to insert
     * @return address
     */
    function updateBytes20inBytes(bytes data, uint offset, bytes20 b)
        internal
        pure
    {
        require(offset >= 0 && offset + 20 <= data.length, "offset value should be in the correct range");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let m := mload(add(data, add(20, offset)))
            m := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000)
            m := or(m, div(b, 0x1000000000000000000000000))
            mstore(add(data, add(20, offset)), m)
        }
    }

    /**
     * @notice Extracts a string from a bytes. Extracts a sub-part from the bytes and convert it to string.
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
 * @title FeeCollector
 *
 * @notice FeeCollector is a contract managing the fees for currency contracts
 */
contract FeeCollector is Ownable {
    using SafeMath for uint256;

    uint256 public rateFeesNumerator;
    uint256 public rateFeesDenominator;
    uint256 public maxFees;

    // address of the contract that will burn req token
    address public requestBurnerContract;

    event UpdateRateFees(uint256 rateFeesNumerator, uint256 rateFeesDenominator);
    event UpdateMaxFees(uint256 maxFees);

    /**
     * @param _requestBurnerContract Address of the contract where to send the ether.
     * This burner contract will have a function that can be called by anyone and will exchange ether to req via Kyber and burn the REQ
     */  
    constructor(address _requestBurnerContract) 
        public
    {
        requestBurnerContract = _requestBurnerContract;
    }

    /**
     * @notice Sets the fees rate.
     * @dev if the _rateFeesDenominator is 0, it will be treated as 1. (in other words, the computation of the fees will not use it)
     * @param _rateFeesNumerator        numerator rate
     * @param _rateFeesDenominator      denominator rate
     */  
    function setRateFees(uint256 _rateFeesNumerator, uint256 _rateFeesDenominator)
        external
        onlyOwner
    {
        rateFeesNumerator = _rateFeesNumerator;
        rateFeesDenominator = _rateFeesDenominator;
        emit UpdateRateFees(rateFeesNumerator, rateFeesDenominator);
    }

    /**
     * @notice Sets the maximum fees in wei.
     * @param _newMaxFees new max
     */  
    function setMaxCollectable(uint256 _newMaxFees) 
        external
        onlyOwner
    {
        maxFees = _newMaxFees;
        emit UpdateMaxFees(maxFees);
    }

    /**
     * @notice Set the request burner address.
     * @param _requestBurnerContract address of the contract that will burn req token (probably through Kyber)
     */  
    function setRequestBurnerContract(address _requestBurnerContract) 
        external
        onlyOwner
    {
        requestBurnerContract = _requestBurnerContract;
    }

    /**
     * @notice Computes the fees.
     * @param _expectedAmount amount expected for the request
     * @return the expected amount of fees in wei
     */  
    function collectEstimation(int256 _expectedAmount)
        public
        view
        returns(uint256)
    {
        if (_expectedAmount<0) {
            return 0;
        }

        uint256 computedCollect = uint256(_expectedAmount).mul(rateFeesNumerator);

        if (rateFeesDenominator != 0) {
            computedCollect = computedCollect.div(rateFeesDenominator);
        }

        return computedCollect < maxFees ? computedCollect : maxFees;
    }

    /**
     * @notice Sends fees to the request burning address.
     * @param _amount amount to send to the burning address
     */  
    function collectForREQBurning(uint256 _amount)
        internal
    {
        // .transfer throws on failure
        requestBurnerContract.transfer(_amount);
    }
}


/**
 * @title Administrable
 * @notice Base contract for the administration of Core. Handles whitelisting of currency contracts
 */
contract Administrable is Pausable {

    // mapping of address of trusted contract
    mapping(address => uint8) public trustedCurrencyContracts;

    // Events of the system
    event NewTrustedContract(address newContract);
    event RemoveTrustedContract(address oldContract);

    /**
     * @notice Adds a trusted currencyContract.
     *
     * @param _newContractAddress The address of the currencyContract
     */
    function adminAddTrustedCurrencyContract(address _newContractAddress)
        external
        onlyOwner
    {
        trustedCurrencyContracts[_newContractAddress] = 1; //Using int instead of boolean in case we need several states in the future.
        emit NewTrustedContract(_newContractAddress);
    }

    /**
     * @notice Removes a trusted currencyContract.
     *
     * @param _oldTrustedContractAddress The address of the currencyContract
     */
    function adminRemoveTrustedCurrencyContract(address _oldTrustedContractAddress)
        external
        onlyOwner
    {
        require(trustedCurrencyContracts[_oldTrustedContractAddress] != 0, "_oldTrustedContractAddress should not be 0");
        trustedCurrencyContracts[_oldTrustedContractAddress] = 0;
        emit RemoveTrustedContract(_oldTrustedContractAddress);
    }

    /**
     * @notice Gets the status of a trusted currencyContract .
     * @dev Not used today, useful if we have several states in the future.
     *
     * @param _contractAddress The address of the currencyContract
     * @return The status of the currencyContract. If trusted 1, otherwise 0
     */
    function getStatusContract(address _contractAddress)
        external
        view
        returns(uint8) 
    {
        return trustedCurrencyContracts[_contractAddress];
    }

    /**
     * @notice Checks if a currencyContract is trusted.
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
 * @title ERC20 interface with no return for approve and transferFrom (like OMG token)
 * @dev see https://etherscan.io/address/0xd26114cd6EE289AccF82350c8d8487fedB8A0C07#code
 */
contract ERC20OMGLike is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public;
  function approve(address spender, uint256 value) public;
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title RequestCore
 *
 * @notice The Core is the main contract which stores all the requests.
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
    // Separated from the Created Event to allow a 4th indexed parameter (subpayees)
    event NewSubPayee(bytes32 indexed requestId, address indexed payee); 
    event UpdateExpectedAmount(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);
    event UpdateBalance(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);

    /**
     * @notice Function used by currency contracts to create a request in the Core.
     *
     * @dev _payees and _expectedAmounts must have the same size.
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
        require(_creator != 0, "creator should not be 0"); // not as modifier to lighten the stack
        // call must come from a trusted contract
        require(isTrustedContract(msg.sender), "caller should be a trusted contract"); // not as modifier to lighten the stack

        // Generate the requestId
        requestId = generateRequestId();

        address mainPayee;
        int256 mainExpectedAmount;
        // extract the main payee if filled
        if (_payees.length!=0) {
            mainPayee = _payees[0];
            mainExpectedAmount = _expectedAmounts[0];
        }

        // Store the new request
        requests[requestId] = Request(
            _payer,
            msg.sender,
            State.Created,
            Payee(
                mainPayee,
                mainExpectedAmount,
                0
            )
        );

        // Declare the new request
        emit Created(
            requestId,
            mainPayee,
            _payer,
            _creator,
            _data
        );
        
        // Store and declare the sub payees (needed in internal function to avoid "stack too deep")
        initSubPayees(requestId, _payees, _expectedAmounts);

        return requestId;
    }

    /**
     * @notice Function used by currency contracts to create a request in the Core from bytes.
     * @dev Used to avoid receiving a stack too deep error when called from a currency contract with too many parameters.
     * @dev Note that to optimize the stack size and the gas cost we do not extract the params and store them in the stack. As a result there is some code redundancy
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
        require(isTrustedContract(msg.sender), "caller should be a trusted contract"); // not as modifier to lighten the stack

        // extract address creator & payer
        address creator = extractAddress(_data, 0);

        address payer = extractAddress(_data, 20);

        // creator must not be null
        require(creator!=0, "creator should not be 0");
        
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
        if (payeesCount!=0) {
            mainPayee = extractAddress(_data, 41);
            mainExpectedAmount = int256(extractBytes32(_data, 61));
        }

        // Generate the requestId
        requestId = generateRequestId();

        // Store the new request
        requests[requestId] = Request(
            payer,
            msg.sender,
            State.Created,
            Payee(
                mainPayee,
                mainExpectedAmount,
                0
            )
        );

        // Declare the new request
        emit Created(
            requestId,
            mainPayee,
            payer,
            creator,
            dataStr
        );

        // Store and declare the sub payees
        for (uint8 i = 1; i < payeesCount; i = i.add(1)) {
            address subPayeeAddress = extractAddress(_data, uint256(i).mul(52).add(41));

            // payees address cannot be 0x0
            require(subPayeeAddress != 0, "subpayee should not be 0");

            subPayees[requestId][i-1] = Payee(subPayeeAddress, int256(extractBytes32(_data, uint256(i).mul(52).add(61))), 0);
            emit NewSubPayee(requestId, subPayeeAddress);
        }

        return requestId;
    }

    /**
     * @notice Function used by currency contracts to accept a request in the Core.
     * @dev callable only by the currency contract of the request
     * @param _requestId Request id
     */ 
    function accept(bytes32 _requestId) 
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 
        r.state = State.Accepted;
        emit Accepted(_requestId);
    }

    /**
     * @notice Function used by currency contracts to cancel a request in the Core. Several reasons can lead to cancel a request, see request life cycle for more info.
     * @dev callable only by the currency contract of the request.
     * @param _requestId Request id
     */ 
    function cancel(bytes32 _requestId)
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 
        r.state = State.Canceled;
        emit Canceled(_requestId);
    }   

    /**
     * @notice Function used to update the balance.
     * @dev callable only by the currency contract of the request.
     * @param _requestId Request id
     * @param _payeeIndex index of the payee (0 = main payee)
     * @param _deltaAmount modifier amount
     */ 
    function updateBalance(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 

        if ( _payeeIndex == 0 ) {
            // modify the main payee
            r.payee.balance = r.payee.balance.add(_deltaAmount);
        } else {
            // modify the sub payee
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.balance = sp.balance.add(_deltaAmount);
        }
        emit UpdateBalance(_requestId, _payeeIndex, _deltaAmount);
    }

    /**
     * @notice Function update the expectedAmount adding additional or subtract.
     * @dev callable only by the currency contract of the request.
     * @param _requestId Request id
     * @param _payeeIndex index of the payee (0 = main payee)
     * @param _deltaAmount modifier amount
     */ 
    function updateExpectedAmount(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request");  

        if ( _payeeIndex == 0 ) {
            // modify the main payee
            r.payee.expectedAmount = r.payee.expectedAmount.add(_deltaAmount);    
        } else {
            // modify the sub payee
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.expectedAmount = sp.expectedAmount.add(_deltaAmount);
        }
        emit UpdateExpectedAmount(_requestId, _payeeIndex, _deltaAmount);
    }

    /**
     * @notice Gets a request.
     * @param _requestId Request id
     * @return request as a tuple : (address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
     */ 
    function getRequest(bytes32 _requestId) 
        external
        view
        returns(address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
    {
        Request storage r = requests[_requestId];
        return (
            r.payer,
            r.currencyContract,
            r.state,
            r.payee.addr,
            r.payee.expectedAmount,
            r.payee.balance
        );
    }

    /**
     * @notice Gets address of a payee.
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return payee address
     */ 
    function getPayeeAddress(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(address)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.addr;
        } else {
            return subPayees[_requestId][_payeeIndex-1].addr;
        }
    }

    /**
     * @notice Gets payer of a request.
     * @param _requestId Request id
     * @return payer address
     */ 
    function getPayer(bytes32 _requestId)
        public
        view
        returns(address)
    {
        return requests[_requestId].payer;
    }

    /**
     * @notice Gets amount expected of a payee.
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return amount expected
     */     
    function getPayeeExpectedAmount(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(int256)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.expectedAmount;
        } else {
            return subPayees[_requestId][_payeeIndex-1].expectedAmount;
        }
    }

    /**
     * @notice Gets number of subPayees for a request.
     * @param _requestId Request id
     * @return number of subPayees
     */     
    function getSubPayeesCount(bytes32 _requestId)
        public
        view
        returns(uint8)
    {
        // solium-disable-next-line no-empty-blocks
        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {}
        return i;
    }

    /**
     * @notice Gets currencyContract of a request.
     * @param _requestId Request id
     * @return currencyContract address
     */
    function getCurrencyContract(bytes32 _requestId)
        public
        view
        returns(address)
    {
        return requests[_requestId].currencyContract;
    }

    /**
     * @notice Gets balance of a payee.
     * @param _requestId Request id
     * @param _payeeIndex payee index (0 = main payee)
     * @return balance
     */     
    function getPayeeBalance(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(int256)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.balance;    
        } else {
            return subPayees[_requestId][_payeeIndex-1].balance;
        }
    }

    /**
     * @notice Gets balance total of a request.
     * @param _requestId Request id
     * @return balance
     */     
    function getBalance(bytes32 _requestId)
        public
        view
        returns(int256)
    {
        int256 balance = requests[_requestId].payee.balance;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            balance = balance.add(subPayees[_requestId][i].balance);
        }

        return balance;
    }

    /**
     * @notice Checks if all the payees balances are null.
     * @param _requestId Request id
     * @return true if all the payees balances are equals to 0
     */     
    function areAllBalanceNull(bytes32 _requestId)
        public
        view
        returns(bool isNull)
    {
        isNull = requests[_requestId].payee.balance == 0;

        for (uint8 i = 0; isNull && subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            isNull = subPayees[_requestId][i].balance == 0;
        }

        return isNull;
    }

    /**
     * @notice Gets total expectedAmount of a request.
     * @param _requestId Request id
     * @return balance
     */     
    function getExpectedAmount(bytes32 _requestId)
        public
        view
        returns(int256)
    {
        int256 expectedAmount = requests[_requestId].payee.expectedAmount;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            expectedAmount = expectedAmount.add(subPayees[_requestId][i].expectedAmount);
        }

        return expectedAmount;
    }

    /**
     * @notice Gets state of a request.
     * @param _requestId Request id
     * @return state
     */ 
    function getState(bytes32 _requestId)
        public
        view
        returns(State)
    {
        return requests[_requestId].state;
    }

    /**
     * @notice Gets address of a payee.
     * @param _requestId Request id
     * @return payee index (0 = main payee) or -1 if not address not found
     */
    function getPayeeIndex(bytes32 _requestId, address _address)
        public
        view
        returns(int16)
    {
        // return 0 if main payee
        if (requests[_requestId].payee.addr == _address) {
            return 0;
        }

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            if (subPayees[_requestId][i].addr == _address) {
                // if found return subPayee index + 1 (0 is main payee)
                return i+1;
            }
        }
        return -1;
    }

    /**
     * @notice Extracts a bytes32 from a bytes.
     * @param _data bytes from where the bytes32 will be extract
     * @param offset position of the first byte of the bytes32
     * @return address
     */
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >= 0 && offset + 32 <= _data.length, "offset value should be in the correct range");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            bs := mload(add(_data, add(32, offset)))
        }
    }

    /**
     * @notice Transfers to owner any tokens send by mistake on this contracts.
     * @param token The address of the token to transfer.
     * @param amount The amount to be transfered.
     */
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }

    /**
     * @notice Extracts an address from a bytes at a given position.
     * @param _data bytes from where the address will be extract
     * @param offset position of the first byte of the address
     * @return address
     */
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m)
    {
        require(offset >= 0 && offset + 20 <= _data.length, "offset value should be in the correct range");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
    
    /**
     * @dev Internal: Init payees for a request (needed to avoid &#39;stack too deep&#39; in createRequest()).
     * @param _requestId Request id
     * @param _payees array of payees address
     * @param _expectedAmounts array of payees initial expected amounts
     */ 
    function initSubPayees(bytes32 _requestId, address[] _payees, int256[] _expectedAmounts)
        internal
    {
        require(_payees.length == _expectedAmounts.length, "payee length should equal expected amount length");
     
        for (uint8 i = 1; i < _payees.length; i = i.add(1)) {
            // payees address cannot be 0x0
            require(_payees[i] != 0, "payee should not be 0");
            subPayees[_requestId][i-1] = Payee(_payees[i], _expectedAmounts[i], 0);
            emit NewSubPayee(_requestId, _payees[i]);
        }
    }

    /**
     * @notice Extracts a string from a bytes. Extracts a sub-part from tha bytes and convert it to string.
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

    /**
     * @notice Generates a new unique requestId.
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
}


/**
 * @title CurrencyContract
 *
 * @notice CurrencyContract is the base for currency contracts. To add a currency to the Request Protocol, create a new currencyContract that inherits from it.
 * @dev If currency contract is whitelisted by core & unpaused: All actions possible
 * @dev If currency contract is not Whitelisted by core & unpaused: Creation impossible, other actions possible
 * @dev If currency contract is paused: Nothing possible
 *
 * Functions that can be implemented by the currency contracts:
 *  - createRequestAsPayeeAction
 *  - createRequestAsPayerAction
 *  - broadcastSignedRequestAsPayer
 *  - paymentActionPayable
 *  - paymentAction
 *  - accept
 *  - cancel
 *  - refundAction
 *  - subtractAction
 *  - additionalAction
 */
contract CurrencyContract is Pausable, FeeCollector {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    RequestCore public requestCore;

    /**
     * @param _requestCoreAddress Request Core address
     */
    constructor(address _requestCoreAddress, address _addressBurner) 
        FeeCollector(_addressBurner)
        public
    {
        requestCore = RequestCore(_requestCoreAddress);
    }

    /**
     * @notice Function to accept a request.
     *
     * @notice msg.sender must be _payer, The request must be in the state CREATED (not CANCELED, not ACCEPTED).
     *
     * @param _requestId id of the request
     */
    function acceptAction(bytes32 _requestId)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {
        // only a created request can be accepted
        require(requestCore.getState(_requestId) == RequestCore.State.Created, "request should be created");

        // declare the acceptation in the core
        requestCore.accept(_requestId);
    }

    /**
     * @notice Function to cancel a request.
     *
     * @dev msg.sender must be the _payer or the _payee.
     * @dev only request with balance equals to zero can be cancel.
     *
     * @param _requestId id of the request
     */
    function cancelAction(bytes32 _requestId)
        public
        whenNotPaused
    {
        // payer can cancel if request is just created
        // payee can cancel when request is not canceled yet
        require(
            // solium-disable-next-line indentation
            (requestCore.getPayer(_requestId) == msg.sender && requestCore.getState(_requestId) == RequestCore.State.Created) ||
            (requestCore.getPayeeAddress(_requestId,0) == msg.sender && requestCore.getState(_requestId) != RequestCore.State.Canceled),
            "payer should cancel a newly created request, or payee should cancel a not cancel request"
        );

        // impossible to cancel a Request with any payees balance != 0
        require(requestCore.areAllBalanceNull(_requestId), "all balanaces should be = 0 to cancel");

        // declare the cancellation in the core
        requestCore.cancel(_requestId);
    }

    /**
     * @notice Function to declare additionals.
     *
     * @dev msg.sender must be _payer.
     * @dev the request must be accepted or created.
     *
     * @param _requestId id of the request
     * @param _additionalAmounts amounts of additional to declare (index 0 is for main payee)
     */
    function additionalAction(bytes32 _requestId, uint256[] _additionalAmounts)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {

        // impossible to make additional if request is canceled
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

        // impossible to declare more additionals than the number of payees
        require(
            _additionalAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _additionalAmounts.length; i = i.add(1)) {
            // no need to declare a zero as additional 
            if (_additionalAmounts[i] != 0) {
                // Store and declare the additional in the core
                requestCore.updateExpectedAmount(_requestId, i, _additionalAmounts[i].toInt256Safe());
            }
        }
    }

    /**
     * @notice Function to declare subtracts.
     *
     * @dev msg.sender must be _payee.
     * @dev the request must be accepted or created.
     *
     * @param _requestId id of the request
     * @param _subtractAmounts amounts of subtract to declare (index 0 is for main payee)
     */
    function subtractAction(bytes32 _requestId, uint256[] _subtractAmounts)
        public
        whenNotPaused
        onlyRequestPayee(_requestId)
    {
        // impossible to make subtracts if request is canceled
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

        // impossible to declare more subtracts than the number of payees
        require(
            _subtractAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _subtractAmounts.length; i = i.add(1)) {
            // no need to declare a zero as subtracts 
            if (_subtractAmounts[i] != 0) {
                // subtract must be equal or lower than amount expected
                require(
                    requestCore.getPayeeExpectedAmount(_requestId,i) >= _subtractAmounts[i].toInt256Safe(),
                    "subtract should equal or be lower than amount expected"
                );

                // Store and declare the subtract in the core
                requestCore.updateExpectedAmount(_requestId, i, -_subtractAmounts[i].toInt256Safe());
            }
        }
    }

    /**
     * @notice Base function for request creation.
     *
     * @dev msg.sender will be the creator.
     *
     * @param _payer Entity expected to pay
     * @param _payeesIdAddress array of payees address (the index 0 will be the payee - must be msg.sender - the others are subPayees)
     * @param _expectedAmounts array of Expected amount to be received by each payees
     * @param _data Hash linking to additional data on the Request stored on IPFS
     *
     * @return Returns the id of the request and the collected fees
     */
    function createCoreRequestInternal(
        address     _payer,
        address[]   _payeesIdAddress,
        int256[]    _expectedAmounts,
        string      _data)
        internal
        whenNotPaused
        returns(bytes32 requestId, uint256 collectedFees)
    {
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1)) {
            // all expected amounts must be positive
            require(_expectedAmounts[i] >= 0, "expected amounts should be positive");

            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

        // store request in the core
        requestId = requestCore.createRequest(
            msg.sender,
            _payeesIdAddress,
            _expectedAmounts,
            _payer,
            _data
        );

        // compute and send fees
        collectedFees = collectEstimation(totalExpectedAmounts);
        collectForREQBurning(collectedFees);
    }

    /**
     * @notice Modifier to check if msg.sender is the main payee.
     * @dev Revert if msg.sender is not the main payee.
     * @param _requestId id of the request
     */ 
    modifier onlyRequestPayee(bytes32 _requestId)
    {
        require(requestCore.getPayeeAddress(_requestId, 0) == msg.sender, "only the payee should do this action");
        _;
    }

    /**
     * @notice Modifier to check if msg.sender is payer.
     * @dev Revert if msg.sender is not payer.
     * @param _requestId id of the request
     */ 
    modifier onlyRequestPayer(bytes32 _requestId)
    {
        require(requestCore.getPayer(_requestId) == msg.sender, "only the payer should do this action");
        _;
    }
}


/**
 * @title Request Signature util library.
 * @notice Collection of utility functions to handle Request signatures.
 */
library Signature {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    /**
     * @notice Checks the validity of a signed request & the expiration date.
     * @param requestData bytes containing all the data packed :
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
     * @param payeesPaymentAddress array of payees payment addresses (the index 0 will be the payee the others are subPayees)
     * @param expirationDate timestamp after that the signed request cannot be broadcasted
     * @param signature ECDSA signature containing v, r and s as bytes
     *
     * @return Validity of order signature.
     */ 
    function checkRequestSignature(
        bytes       requestData,
        address[]   payeesPaymentAddress,
        uint256     expirationDate,
        bytes       signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = getRequestHash(requestData, payeesPaymentAddress, expirationDate);

        // extract "v, r, s" from the signature
        uint8 v = uint8(signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = Bytes.extractBytes32(signature, 0);
        bytes32 s = Bytes.extractBytes32(signature, 32);

        // check signature of the hash with the creator address
        return isValidSignature(
            Bytes.extractAddress(requestData, 0),
            hash,
            v,
            r,
            s
        );
    }

    /**
     * @notice Checks the validity of a Bitcoin signed request & the expiration date.
     * @param requestData bytes containing all the data packed :
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
     * @param payeesPaymentAddress array of payees payment addresses (the index 0 will be the payee the others are subPayees)
     * @param expirationDate timestamp after that the signed request cannot be broadcasted
     * @param signature ECDSA signature containing v, r and s as bytes
     *
     * @return Validity of order signature.
     */ 
    function checkBtcRequestSignature(
        bytes       requestData,
        bytes       payeesPaymentAddress,
        uint256     expirationDate,
        bytes       signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = getBtcRequestHash(requestData, payeesPaymentAddress, expirationDate);

        // extract "v, r, s" from the signature
        uint8 v = uint8(signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = Bytes.extractBytes32(signature, 0);
        bytes32 s = Bytes.extractBytes32(signature, 32);

        // check signature of the hash with the creator address
        return isValidSignature(
            Bytes.extractAddress(requestData, 0),
            hash,
            v,
            r,
            s
        );
    }
    
    /**
     * @notice Calculates the Keccak-256 hash of a BTC request with specified parameters.
     *
     * @param requestData bytes containing all the data packed
     * @param payeesPaymentAddress array of payees payment addresses
     * @param expirationDate timestamp after what the signed request cannot be broadcasted
     *
     * @return Keccak-256 hash of (this, requestData, payeesPaymentAddress, expirationDate)
     */
    function getBtcRequestHash(
        bytes       requestData,
        bytes   payeesPaymentAddress,
        uint256     expirationDate)
        private
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                this,
                requestData,
                payeesPaymentAddress,
                expirationDate
            )
        );
    }

    /**
     * @dev Calculates the Keccak-256 hash of a (not BTC) request with specified parameters.
     *
     * @param requestData bytes containing all the data packed
     * @param payeesPaymentAddress array of payees payment addresses
     * @param expirationDate timestamp after what the signed request cannot be broadcasted
     *
     * @return Keccak-256 hash of (this, requestData, payeesPaymentAddress, expirationDate)
     */
    function getRequestHash(
        bytes       requestData,
        address[]   payeesPaymentAddress,
        uint256     expirationDate)
        private
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                this,
                requestData,
                payeesPaymentAddress,
                expirationDate
            )
        );
    }
    
    /**
     * @notice Verifies that a hash signature is valid. 0x style.
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
        private
        pure
        returns (bool)
    {
        return signer == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            v,
            r,
            s
        );
    }
}

/**
 * @title RequestOMG
 * @notice Currency contract managing the requests in ERC20 tokens like OMG (without returns).
 * @dev Requests can be created by the Payee with createRequestAsPayeeAction(), by the payer with createRequestAsPayerAction() or by the payer from a request signed offchain by the payee with broadcastSignedRequestAsPayer
 */
contract RequestOMG is CurrencyContract {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    // payment addresses by requestId (optional). We separate the Identity of the payee/payer (in the core) and the wallet address in the currency contract
    mapping(bytes32 => address[256]) public payeesPaymentAddress;
    mapping(bytes32 => address) public payerRefundAddress;

    // token address
    ERC20OMGLike public erc20Token;

    /**
     * @param _requestCoreAddress Request Core address
     * @param _requestBurnerAddress Request Burner contract address
     * @param _erc20Token ERC20 token contract handled by this currency contract
     */
    constructor (address _requestCoreAddress, address _requestBurnerAddress, ERC20OMGLike _erc20Token) 
        CurrencyContract(_requestCoreAddress, _requestBurnerAddress)
        public
    {
        erc20Token = _erc20Token;
    }

    /**
     * @notice Function to create a request as payee.
     *
     * @dev msg.sender must be the main payee.
     * @dev if _payeesPaymentAddress.length > _payeesIdAddress.length, the extra addresses will be stored but never used.
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
    function createRequestAsPayeeAction(
        address[] 	_payeesIdAddress,
        address[] 	_payeesPaymentAddress,
        int256[] 	_expectedAmounts,
        address 	_payer,
        address 	_payerRefundAddress,
        string 		_data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(
            msg.sender == _payeesIdAddress[0] && msg.sender != _payer && _payer != 0,
            "caller should be the payee"
        );

        uint256 collectedFees;
        (requestId, collectedFees) = createCoreRequestInternal(
            _payer,
            _payeesIdAddress,
            _expectedAmounts,
            _data
        );
        
        // Additional check on the fees: they should be equal to the about of ETH sent
        require(collectedFees == msg.value, "fees should be the correct amout");

        // set payment addresses for payees
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }
        // set payment address for payer
        if (_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }

        return requestId;
    }

    /**
     * @notice Function to broadcast and accept an offchain signed request (the broadcaster can also pays and makes additionals).
     *
     * @dev msg.sender will be the _payer.
     * @dev only the _payer can make additionals.
     * @dev if _payeesPaymentAddress.length > _requestData.payeesIdAddress.length, the extra addresses will be stored but never used.
     *
     * @param _requestData nasty bytes containing : creator, payer, payees|expectedAmounts, data
     * @param _payeesPaymentAddress array of payees address for payment (optional) 
     * @param _payeeAmounts array of amount repartition for the payment
     * @param _additionals array to increase the ExpectedAmount for payees
     * @param _expirationDate timestamp after that the signed request cannot be broadcasted
     * @param _signature ECDSA signature in bytes
     *
     * @return Returns the id of the request
     */
    function broadcastSignedRequestAsPayerAction(
        bytes 		_requestData, // gather data to avoid "stack too deep"
        address[] 	_payeesPaymentAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals,
        uint256 	_expirationDate,
        bytes 		_signature)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        // check expiration date
        // solium-disable-next-line security/no-block-members
        require(_expirationDate >= block.timestamp, "expiration should be after current time");

        // check the signature
        require(
            Signature.checkRequestSignature(
                _requestData,
                _payeesPaymentAddress,
                _expirationDate,
                _signature
            ),
            "signature should be correct"
        );

        return createAcceptAndPayFromBytes(
            _requestData,
            _payeesPaymentAddress,
            _payeeAmounts,
            _additionals
        );
    }

    /**
     * @notice Function to pay a request in ERC20 token.
     *
     * @dev msg.sender must have a balance of the token higher or equal to the sum of _payeeAmounts.
     * @dev msg.sender must have approved an amount of the token higher or equal to the sum of _payeeAmounts to the current contract.
     * @dev the request will be automatically accepted if msg.sender==payer. 
     *
     * @param _requestId id of the request
     * @param _payeeAmounts Amount to pay to payees (sum must be equal to msg.value) in wei
     * @param _additionalAmounts amount of additionals per payee in wei to declare
     */
    function paymentAction(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionalAmounts)
        external
        whenNotPaused
    {
        // automatically accept request if request is created and msg.sender is payer
        if (requestCore.getState(_requestId)==RequestCore.State.Created && msg.sender == requestCore.getPayer(_requestId)) {
            acceptAction(_requestId);
        }

        if (_additionalAmounts.length != 0) {
            additionalAction(_requestId, _additionalAmounts);
        }

        paymentInternal(_requestId, _payeeAmounts);
    }

    /**
     * @notice Function to pay back in ERC20 token a request to the payees.
     *
     * @dev msg.sender must have a balance of the token higher or equal to _amountToRefund.
     * @dev msg.sender must have approved an amount of the token higher or equal to _amountToRefund to the current contract.
     * @dev msg.sender must be one of the payees or one of the payees payment address.
     * @dev the request must be created or accepted.
     *
     * @param _requestId id of the request
     */
    function refundAction(bytes32 _requestId, uint256 _amountToRefund)
        external
        whenNotPaused
    {
        refundInternal(_requestId, msg.sender, _amountToRefund);
    }

    /**
     * @notice Function to create a request as payer. The request is payed if _payeeAmounts > 0.
     *
     * @dev msg.sender will be the payer.
     * @dev If a contract is given as a payee make sure it is payable. Otherwise, the request will not be payable.
     * @dev Is public instead of external to avoid "Stack too deep" exception.
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
    function createRequestAsPayerAction(
        address[] 	_payeesIdAddress,
        int256[] 	_expectedAmounts,
        address 	_payerRefundAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals,
        string 		_data)
        public
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender != _payeesIdAddress[0] && _payeesIdAddress[0] != 0, "caller should not be the main payee");

        uint256 collectedFees;
        (requestId, collectedFees) = createCoreRequestInternal(
            msg.sender,
            _payeesIdAddress,
            _expectedAmounts,
            _data
        );

        // Additional check on the fees: they should be equal to the about of ETH sent
        require(collectedFees == msg.value, "fees should be the correct amout");

        // set payment address for payer
        if (_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }
        
        // compute the total expected amount of the request
        // this computation is also made in createCoreRequestInternal but we do it again here to have better decoupling
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1)) {
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

        // accept and pay the request with the value remaining after the fee collect
        acceptAndPay(
            requestId,
            _payeeAmounts,
            _additionals,
            totalExpectedAmounts
        );

        return requestId;
    }

    /**
     * @dev Internal function to create, accept, add additionals and pay a request as Payer.
     *
     * @dev msg.sender must be _payer.
     *
     * @param _requestData nasty bytes containing : creator, payer, payees|expectedAmounts, data
     * @param _payeesPaymentAddress array of payees address for payment (optional)
     * @param _payeeAmounts array of amount repartition for the payment
     * @param _additionals Will increase the ExpectedAmount of the request right after its creation by adding additionals
     *
     * @return Returns the id of the request
     */
    function createAcceptAndPayFromBytes(
        bytes 		_requestData,
        address[] 	_payeesPaymentAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals)
        internal
        returns(bytes32 requestId)
    {
        // extract main payee
        address mainPayee = Bytes.extractAddress(_requestData, 41);
        require(msg.sender != mainPayee && mainPayee != 0, "caller should not be the main payee");

        // creator must be the main payee
        require(Bytes.extractAddress(_requestData, 0) == mainPayee, "creator should be the main payee");

        // extract the number of payees
        uint8 payeesCount = uint8(_requestData[40]);
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < payeesCount; i++) {
            // extract the expectedAmount for the payee[i]
            int256 expectedAmountTemp = int256(Bytes.extractBytes32(_requestData, uint256(i).mul(52).add(61)));
            
            // compute the total expected amount of the request
            totalExpectedAmounts = totalExpectedAmounts.add(expectedAmountTemp);
            
            // all expected amount must be positive
            require(expectedAmountTemp > 0, "expected amount should be > 0");
        }

        // compute and send fees
        uint256 fees = collectEstimation(totalExpectedAmounts);
        require(fees == msg.value, "fees should be the correct amout");
        collectForREQBurning(fees);

        // insert the msg.sender as the payer in the bytes
        Bytes.updateBytes20inBytes(_requestData, 20, bytes20(msg.sender));
        // store request in the core
        requestId = requestCore.createRequestFromBytes(_requestData);
        
        // set payment addresses for payees
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }

        // accept and pay the request with the value remaining after the fee collect
        acceptAndPay(
            requestId,
            _payeeAmounts,
            _additionals,
            totalExpectedAmounts
        );

        return requestId;
    }

    /**
     * @dev Internal function to manage payment declaration.
     *
     * @param _requestId id of the request
     * @param _payeeAmounts Amount to pay to payees (sum must be equals to msg.value)
     */
    function paymentInternal(
        bytes32 	_requestId,
        uint256[] 	_payeeAmounts)
        internal
    {
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

        // we cannot have more amounts declared than actual payees
        require(
            _payeeAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _payeeAmounts.length; i = i.add(1)) {
            if (_payeeAmounts[i] != 0) {
                // Store and declare the payment to the core
                requestCore.updateBalance(_requestId, i, _payeeAmounts[i].toInt256Safe());

                // pay the payment address if given, the id address otherwise
                address addressToPay;
                if (payeesPaymentAddress[_requestId][i] == 0) {
                    addressToPay = requestCore.getPayeeAddress(_requestId, i);
                } else {
                    addressToPay = payeesPaymentAddress[_requestId][i];
                }

                // payment done, the token need to be sent
                fundOrderInternal(msg.sender, addressToPay, _payeeAmounts[i]);
            }
        }
    }

    /**
     * @dev Internal function to accept, add additionals and pay a request as Payer
     *
     * @param _requestId id of the request
     * @param _payeeAmounts Amount to pay to payees (sum must be equals to _amountPaid)
     * @param _additionals Will increase the ExpectedAmounts of payees
     * @param _payeeAmountsSum total of amount token send for this transaction
     *
     */	
    function acceptAndPay(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionals,
        int256 _payeeAmountsSum)
        internal
    {
        acceptAction(_requestId);
        
        additionalAction(_requestId, _additionals);

        if (_payeeAmountsSum > 0) {
            paymentInternal(_requestId, _payeeAmounts);
        }
    }

    /**
     * @dev Internal function to manage refund declaration
     *
     * @param _requestId id of the request
     * @param _address address from where the refund has been done
     * @param _amount amount of the refund in ERC20 token to declare
     */
    function refundInternal(
        bytes32 _requestId,
        address _address,
        uint256 _amount)
        internal
    {
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

        // Check if the _address is a payeesId
        int16 payeeIndex = requestCore.getPayeeIndex(_requestId, _address);

        // get the number of payees
        uint8 payeesCount = requestCore.getSubPayeesCount(_requestId).add(1);

        if (payeeIndex < 0) {
            // if not ID addresses maybe in the payee payments addresses
            for (uint8 i = 0; i < payeesCount && payeeIndex == -1; i = i.add(1)) {
                if (payeesPaymentAddress[_requestId][i] == _address) {
                    // get the payeeIndex
                    payeeIndex = int16(i);
                }
            }
        }
        // the address must be found somewhere
        require(payeeIndex >= 0, "fromAddress should be a payee"); 

        // useless (subPayee size <256): require(payeeIndex < 265);
        requestCore.updateBalance(_requestId, uint8(payeeIndex), -_amount.toInt256Safe());

        // refund to the payment address if given, the id address otherwise
        address addressToPay = payerRefundAddress[_requestId];
        if (addressToPay == 0) {
            addressToPay = requestCore.getPayer(_requestId);
        }

        // refund declared, the money is ready to be sent to the payer
        fundOrderInternal(_address, addressToPay, _amount);
    }

    /**
     * @dev Internal function to manage fund mouvement.
     *
     * @param _from address where the token will get from
     * @param _recipient address where the token has to be sent to
     * @param _amount amount in ERC20 token to send
     */
    function fundOrderInternal(
        address _from,
        address _recipient,
        uint256 _amount)
        internal
    {	
        erc20Token.transferFrom(_from, _recipient, _amount);
    }
}