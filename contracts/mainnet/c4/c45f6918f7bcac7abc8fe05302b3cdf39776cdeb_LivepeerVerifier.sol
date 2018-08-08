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
  function transferOwnership(address newOwner) public onlyOwner {
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

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner());
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        require(!controller.paused());
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        require(controller.paused());
        _;
    }

    function Manager(address _controller) public {
        controller = IController(_controller);
    }

    /*
     * @dev Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        SetController(_controller);
    }
}

/**
 * @title Interface for a Verifier. Can be backed by any implementaiton including oracles or Truebit
 */
contract IVerifier {
    function verify(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber,
        string _transcodingOptions,
        string _dataStorageHash,
        bytes32[2] _dataHashes
    )
        external
        payable;

    function getPrice() public view returns (uint256);
}

/*
 * @title Interface for contract that receives verification results
 */
contract IVerifiable {
    // External functions
    function receiveVerification(uint256 _jobId, uint256 _claimId, uint256 _segmentNumber, bool _result) external;
}

contract LivepeerVerifier is Manager, IVerifier {
    // IPFS hash of verification computation archive
    string public verificationCodeHash;
    // Solvers that can submit results for requests
    address[] public solvers;
    // Track if an address is a solver
    mapping (address => bool) public isSolver;

    struct Request {
        uint256 jobId;
        uint256 claimId;
        uint256 segmentNumber;
        bytes32 commitHash;
    }

    mapping (uint256 => Request) public requests;
    uint256 public requestCount;

    event VerifyRequest(uint256 indexed requestId, uint256 indexed jobId, uint256 indexed claimId, uint256 segmentNumber, string transcodingOptions, string dataStorageHash, bytes32 dataHash, bytes32 transcodedDataHash);
    event Callback(uint256 indexed requestId, uint256 indexed jobId, uint256 indexed claimId, uint256 segmentNumber, bool result);

    // Check if sender is JobsManager
    modifier onlyJobsManager() {
        require(msg.sender == controller.getContract(keccak256("JobsManager")));
        _;
    }

    // Check if sender is a solver
    modifier onlySolvers() {
        require(isSolver[msg.sender]);
        _;
    }

    function LivepeerVerifier(address _controller, address[] _solvers, string _verificationCodeHash) public Manager(_controller) {
        // Set solvers
        for (uint256 i = 0; i < _solvers.length; i++) {
            // Address must not already be a solver and must not be a null address
            require(!isSolver[_solvers[i]] && _solvers[i] != address(0));

            isSolver[_solvers[i]] = true;
        }
        solvers = _solvers;
        // Set verification code hash
        verificationCodeHash = _verificationCodeHash;
    }

    function setVerificationCodeHash(string _verificationCodeHash) external onlyControllerOwner {
        verificationCodeHash = _verificationCodeHash;
    }

    function addSolver(address _solver) external onlyControllerOwner {
        // Must not be null address
        require(_solver != address(0));
        // Must not already be a solver
        require(!isSolver[_solver]);

        solvers.push(_solver);
        isSolver[_solver] = true;
    }

    /*
     * @dev Fire VerifyRequest event which solvers should listen for to retrieve verification parameters
     */
    function verify(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber,
        string _transcodingOptions,
        string _dataStorageHash,
        bytes32[2] _dataHashes
    )
        external
        payable
        onlyJobsManager
        whenSystemNotPaused
    {
        // Store request parameters
        requests[requestCount].jobId = _jobId;
        requests[requestCount].claimId = _claimId;
        requests[requestCount].segmentNumber = _segmentNumber;
        requests[requestCount].commitHash = keccak256(_dataHashes[0], _dataHashes[1]);

        VerifyRequest(
            requestCount,
            _jobId,
            _claimId,
            _segmentNumber,
            _transcodingOptions,
            _dataStorageHash,
            _dataHashes[0],
            _dataHashes[1]
        );

        // Update request count
        requestCount++;
    }

    /*
     * @dev Callback function invoked by a solver to submit the result of a verification computation
     * @param _requestId Request identifier
     * @param _result Result of verification computation - keccak256 hash of transcoded segment data
     */
    // solium-disable-next-line mixedcase
    function __callback(uint256 _requestId, bytes32 _result) external onlySolvers whenSystemNotPaused {
        Request memory q = requests[_requestId];

        // Check if transcoded data hash returned by solver matches originally submitted transcoded data hash
        if (q.commitHash == _result) {
            IVerifiable(controller.getContract(keccak256("JobsManager"))).receiveVerification(q.jobId, q.claimId, q.segmentNumber, true);
            Callback(_requestId, q.jobId, q.claimId, q.segmentNumber, true);
        } else {
            IVerifiable(controller.getContract(keccak256("JobsManager"))).receiveVerification(q.jobId, q.claimId, q.segmentNumber, false);
            Callback(_requestId, q.jobId, q.claimId, q.segmentNumber, false);
        }

        // Remove request
        delete requests[_requestId];
    }

    /*
     * @dev Return price of verification which is zero for this implementation
     */
    function getPrice() public view returns (uint256) {
        return 0;
    }
}