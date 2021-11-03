/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Authorizable.sol

pragma solidity ^0.5.2;


contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0));
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

}

// File: contracts/FlyionBasics.sol

pragma solidity ^0.5.0;

//Set of common functions to import is MSC and ORACLE.



//Common functions, including the method to create flightId and policyId hashes
contract usingFlyionBasics is Authorizable {
    
    
    //Calculation functions
    function createPolicyId(string memory _fltNum, uint256 _depDte, uint _expectedArrDte, uint256 _dlyTime, uint256 _premium, uint _claimPayout, uint256 _expiryDte, uint256 _nbSeatsMax)
    public pure returns (bytes32 ) {
            return keccak256(abi.encodePacked(createFlightId(_fltNum, _depDte), _expectedArrDte, _dlyTime, _premium, _claimPayout, _expiryDte, _nbSeatsMax));
    }
    function createFlightId(string memory _fltNum, uint256 _depDte)
    public pure returns (bytes32) {
      return keccak256(abi.encodePacked(_fltNum, _depDte));
    }

    function updateFlightDelay(int256 _actualArrDte, uint256 _expectedArrDte)
        internal pure returns(uint256 _flightDelay, uint8 _fltSts) {
        uint256 MIN_DELAY_BUFFER = 900; //15 min is the smallest delay to cover
        if (_actualArrDte < 0) { // flight is cancelled
            _flightDelay = 10800;
            _fltSts = 3;
        }
        else if (uint256(_actualArrDte) > (_expectedArrDte + MIN_DELAY_BUFFER)) {
            _flightDelay = (uint256(_actualArrDte) - _expectedArrDte);
            _fltSts = 2;
        }
        else {
            _flightDelay = 0; 
            _fltSts = 1;
        }
    }
    
    function updateFlightDelay(int256 _actualArrDte, uint256 _expectedArrDte, uint256 delayBuffer)
        internal pure returns(uint256 _flightDelay, uint8 _fltSts) {
        if (_actualArrDte < 0) { // flight is cancelled
            _flightDelay = 10800;
            _fltSts = 3;
        }
        else if (uint256(_actualArrDte) > (_expectedArrDte + delayBuffer)) {
            _flightDelay = (uint256(_actualArrDte) - _expectedArrDte);
            _fltSts = 2;
        }
        else {
            _flightDelay = 0; 
            _fltSts = 1;
        }
    }


    //Token Interactions
    function withdrawTokens(address _tokenAddress, address _recipient)
    public onlyOwner returns (uint256 _withdrawal) {
        _withdrawal = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_recipient, _withdrawal);
    }
    function _checkTokenBalances(address _tokenAddress)
    public view returns(uint256 _tokenBalance) {
        _tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
    }

    //Killswitch
    function _killContract(bool _forceKill, address _tokenAddress)
    public onlyOwner {
        if(_forceKill == false){require(IERC20(_tokenAddress).balanceOf(address(this)) == 0, "Please withdraw Tokens");} //Require: TOKEN balances = 0
        selfdestruct(msg.sender); //kill
    }

}

// File: contracts/FlightOracleService.sol

pragma solidity ^0.5.0;



contract MSC_Interface {
    function updateFromOracle(bytes32 _policyId, bytes32 _flightId, int256 _actualArrDte, uint8 _fltStatus) public;
}

contract FlightOracleService is usingFlyionBasics {
    uint256 private requestCount = 1;

    event LogNewFlightServiceQuery(
        bytes32 _queryId,
        bytes32 _policyId,
        string _flight,
        uint256 _departure,
        uint256 _expectedArrival,
        uint256 _updateDelayTime,
        address _MSCaddress
    );
    event LogArrivalUpdated(bytes32 _queryId, string _fltNum, int256 actualArrDte, uint256 flightDelayCalc);

    struct QueryInformation {
        bytes32 policyId;
        bool pendingQuery;
        uint256 lastUpdated;
    }
    mapping (bytes32 => QueryInformation) public Queries;

    struct PolicyInformation {
        address originAddress;
        bytes32 policyId;
        bytes32 flightId;
        bytes32 queryId;
    }
    mapping (bytes32 => PolicyInformation) public Policies;

    struct FlightInformation {
        string fltNum;
        uint256 depDte;
        uint256 expectedArrDte;
        int256 actualArrDte;
        uint256 calculatedDelay;
        uint8 fltSts;
    }
    mapping (bytes32 => FlightInformation) public Flights;

    constructor() public {
    }

    function triggerOracle(
        bytes32 _policyId,
        string memory _flight,
        uint256 _departure,
        uint256 _expectedArrival,
        uint256 _updateDelayTime,
        address _MSCaddress
    )
    public
    onlyAuthorized
    {
        bytes32 _flightId = createFlightId(_flight, _departure);

        Policies[_policyId].originAddress = _MSCaddress;
        Policies[_policyId].flightId = _flightId;

        Flights[_flightId].fltNum = _flight;
        Flights[_flightId].depDte = _departure;
        Flights[_flightId].expectedArrDte = _expectedArrival;

        bytes32 queryId = keccak256(abi.encodePacked(this, requestCount));
        requestCount += 1;

        emit LogNewFlightServiceQuery(queryId, _policyId, _flight, _departure, _expectedArrival, _updateDelayTime, _MSCaddress);

        Queries[queryId].policyId = _policyId;
        Queries[queryId].pendingQuery = true;
        Queries[queryId].lastUpdated = 0;

        Policies[Queries[queryId].policyId].queryId = queryId;
    }

    function fulfill(
        bytes32 _requestId,
        int256 _result
    )
    public
    {
        updateMSC(_requestId, _result);
    }

    function updateMSC(bytes32 queryId, int256 _result) internal {
        int256 actualArrDte = _result;
        bytes32 _policyId = Queries[queryId].policyId;

        Policies[_policyId].queryId = queryId;
        Queries[queryId].pendingQuery = false;
        Queries[queryId].lastUpdated = block.timestamp;

        bytes32 _flightId = Policies[_policyId].flightId;

        (uint256 _flightDelay, uint8 _fltSts) = updateFlightDelay(actualArrDte, Flights[_flightId].expectedArrDte);
        Flights[_flightId].actualArrDte = actualArrDte;
        Flights[_flightId].calculatedDelay = _flightDelay;
        Flights[_flightId].fltSts = _fltSts;

        emit LogArrivalUpdated(queryId, Flights[_flightId].fltNum, actualArrDte, _flightDelay);

        MSC_Interface(Policies[_policyId].originAddress).updateFromOracle(_policyId, _flightId, actualArrDte, _fltSts);
    }
}