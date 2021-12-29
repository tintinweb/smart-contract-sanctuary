/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/Clones.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function copy(address a) internal returns(address){

    /*
    https://gist.github.com/holiman/069de8d056a531575d2b786df3345665
    this is dup, not proxy

    Assembly of the code that we want to use as init-code in the new contract, 
    along with stack values:
	                # bottom [ STACK ] top
	 PUSH1 00       # [ 0 ]
	 DUP1           # [ 0, 0 ]
	 PUSH20         
	 <address>      # [0,0, address] 
	 DUP1		# [0,0, address ,address]
	 EXTCODESIZE    # [0,0, address, size ]
	 DUP1           # [0,0, address, size, size]
	 SWAP4          # [ size, 0, address, size, 0]
	 DUP1           # [ size, 0, address ,size, 0,0]
	 SWAP2          # [ size, 0, address, 0, 0, size]
	 SWAP3          # [ size, 0, size, 0, 0, address]
	 EXTCODECOPY    # [ size, 0]
	 RETURN 
    
    The code above weighs in at 33 bytes, which is _just_ above fitting into a uint. 
    So a modified version is used, where the initial PUSH1 00 is replaced by `PC`. 
    This is one byte smaller, and also a bit cheaper Wbase instead of Wverylow. It only costs 2 gas.

	 PC             # [ 0 ]
	 DUP1           # [ 0, 0 ]
	 PUSH20         
	 <address>      # [0,0, address] 
	 DUP1		# [0,0, address ,address]
	 EXTCODESIZE    # [0,0, address, size ]
	 DUP1           # [0,0, address, size, size]
	 SWAP4          # [ size, 0, address, size, 0]
	 DUP1           # [ size, 0, address ,size, 0,0]
	 SWAP2          # [ size, 0, address, 0, 0, size]
	 SWAP3          # [ size, 0, size, 0, 0, address]
	 EXTCODECOPY    # [ size, 0]
	 RETURN 

	The opcodes are:
	58 80 73 <address> 80 3b 80 93 80 91 92 3c F3
	We get <address> in there by OR:ing the upshifted address into the 0-filled space. 
	  5880730000000000000000000000000000000000000000803b80938091923cF3 
	 +000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx000000000000000000
	 -----------------------------------------------------------------
	  588073xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00000803b80938091923cF3

	This is simply stored at memory position 0, and create is invoked. 

	*/
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 , mul(a,0x1000000000000000000)))
            retval := create(0, 0, 32)
            switch extcodesize(retval) case 0 { revert(0, 0) }
        }
        return retval;
    }  

    function copy2(address a, uint256 salt) internal returns (address) {
        /* this is dup, not proxy */
        address retval;
        assembly {
        mstore(0x0, or(0x5880730000000000000000000000000000000000000000803b80938091923cF3, mul(a, 0x1000000000000000000)))
        retval := create2(0, 0, 0x20, salt)
        switch extcodesize(retval) case 0 { revert(0, 0) }
        }
        return retval;
    }  

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File contracts/Initializable.sol


pragma solidity >=0.6.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    function initialized() internal view returns(bool) {
        return _initialized;
    }
}


// File contracts/Owned.sol


pragma solidity ^0.7.0;
/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned is Initializable {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  // constructor() {
  //   owner = msg.sender;
  // }

  /**
  * @dev Initializes the contract setting the deployer as the initial owner.
  */
  function __Owned_init() internal initializer {
      __Owned_init_unchained();
  }

  function __Owned_init_unchained() internal initializer {
      _setOwner(msg.sender);
  }

  function _setOwner(address newOwner) private {
      address oldOwner = owner;
      owner = payable(newOwner);
      emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}


// File contracts/libocr/contracts/AccessControllerInterface.sol


pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}


// File contracts/libocr/contracts/LinkTokenInterface.sol


pragma solidity ^0.7.1;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}


// File contracts/ChainlinkFactory.sol


pragma solidity >=0.7.0;
pragma abicoder v2;
//import "./libocr/contracts/AccessControlledOffchainAggregator.sol";
interface AccessControlledOffchainAggregatorInterface {
    function initialize(    
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microLinkPerEth,
    uint32 _linkGweiPerObservation,
    uint32 _linkGweiPerTransmission,
    LinkTokenInterface _link,
    int192 _minAnswer,
    int192 _maxAnswer,
    AccessControllerInterface _billingAccessController,
    AccessControllerInterface _requesterAccessController,
    uint8 _decimals,
    string memory _description,
    address _newOwner
  ) external;

  function transferOwnership(address _to) external;
}

interface KeeperRegistryInterface {
  function initialize(
    address link,
    address linkEthFeed,
    address fastGasFeed,
    uint32 paymentPremiumPPB,
    uint24 blockCountPerTurn,
    uint32 checkGasLimit,
    uint24 stalenessSeconds,
    uint16 gasCeilingMultiplier,
    uint256 fallbackGasPrice,
    uint256 fallbackLinkPrice,
    address newOwner
  ) external; 
  function transferOwnership(address _to) external;
}

interface VRFCoordinatorInterface {
  function initialize(
    address _link, 
    address _blockHashStore,
    address newOwner
  ) external;
  function transferOwnership(address _to) external;
}

interface OperatorInterface {
  function initialize(address link, address owner) external;
  function transferOwnership(address _to) external;
}

struct NewAggregatorParams {
    int192 minValue;
    int192 maxValue;
    uint8 decimals;
    LinkTokenInterface linkToken;
    AccessControllerInterface billingAccessController;
    AccessControllerInterface requesterAccessController;
    string description;
}

struct SharedSecretEncryptions {
    bytes32 diffieHellmanPoint;
    bytes32 sharedSecretHash;
    bytes16[] encryptions;
}

struct SetConfigEncodedComponents {
    uint64 deltaProgress;
    uint64 deltaResend;
    uint64 deltaRound;
    uint64 deltaGrace;
    uint64 deltaC;
    uint64 alphaPPB;
    uint64 deltaStage;
    uint8 rMax;
    uint8[] s;
    bytes32[] offchainPublicKeys;
    string peerIDs;
    SharedSecretEncryptions sharedSecretEncryptions;
}

contract ChainlinkFactory is Owned {

    address public ocrImplementation;
    address public keeperImplementation;
    address public operatorImplementation;
    address public vrfImplementation;
    uint256 public ocrFee;
    uint256 public keeperFee;
    uint256 public operatorFee;
    uint256 public vrfFee;

    event OCRAggregatorCreated(
        address indexed aggregator,
        address indexed owner,
        address indexed sender
    );
    event KeeperRegistryCreated(
        address indexed keeperRegistry,
        address indexed owner,
        address indexed sender
    );
    event VRFCoordinatorCreated(
        address indexed vrfCoordinator,
        address indexed owner,
        address indexed sender
    );
    event OperatorCreated(
        address indexed operator,
        address indexed owner,
        address indexed sender
    );
    event NewContractCreated(
        address indexed implementation,
        address indexed newAddress
    );

    constructor() {
        initialize();
    }
    
    function initialize() public initializer {
        __Owned_init();
    }

    function setImpl(address[] calldata impl, uint256[] calldata fees) public onlyOwner {
        setOCRImpl(impl[0], fees[0]);
        setKeeperImpl(impl[1], fees[1]);
        setOperatorImpl(impl[2], fees[2]);
        setVRFImpl(impl[3], fees[3]);
    }

    function setOCRImpl(address impl, uint256 fee) public onlyOwner {
        ocrImplementation = impl;
        ocrFee = fee;
    }
    function setKeeperImpl(address impl, uint256 fee) public onlyOwner {
        keeperImplementation = impl;
        keeperFee = fee;
    }
    function setOperatorImpl(address impl, uint256 fee) public onlyOwner {
        operatorImplementation = impl;
        operatorFee = fee;
    }
    function setVRFImpl(address impl, uint256 fee) public onlyOwner {
        vrfImplementation = impl;
        vrfFee = fee;
    }

    function withdraw(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }

    function cloneAndInit(address implementation, bool copy, bytes calldata init) public returns(address) {
        address newContract = copy ? Clones.copy(implementation) : Clones.clone(implementation);
        if (init.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool result, ) = newContract.call(init);
            require(result,"failed to call init");
        }
        emit NewContractCreated(implementation, newContract);
        return newContract;
    }

    function cloneKeeperRegistry(    
        address link,
        address linkEthFeed,
        address fastGasFeed,
        uint32 paymentPremiumPPB,
        uint24 blockCountPerTurn,
        uint32 checkGasLimit,
        uint24 stalenessSeconds,
        uint16 gasCeilingMultiplier,
        uint256 fallbackGasPrice,
        uint256 fallbackLinkPrice,
        bool copy
    ) external payable returns (address) {
        require(msg.value >= keeperFee,"need fee to clone");
        KeeperRegistryInterface cloned = KeeperRegistryInterface(copy ? Clones.copy(keeperImplementation) : Clones.clone(keeperImplementation));
        cloned.initialize(
            link, 
            linkEthFeed, 
            fastGasFeed, 
            paymentPremiumPPB, 
            blockCountPerTurn, 
            checkGasLimit, 
            stalenessSeconds, 
            gasCeilingMultiplier, 
            fallbackGasPrice, 
            fallbackLinkPrice, 
            msg.sender);
        emit KeeperRegistryCreated(
            address(cloned),
            msg.sender,
            msg.sender
        );
        return address(cloned);
    }
    function cloneVRFCoordinator(
        address _link, 
        address _blockHashStore,
        bool copy
    ) external payable returns (address) {
        require(msg.value >= vrfFee,"need fee to clone");
        VRFCoordinatorInterface cloned = VRFCoordinatorInterface(copy ? Clones.copy(vrfImplementation) : Clones.clone(vrfImplementation));
        cloned.initialize(_link, _blockHashStore, msg.sender);
        emit VRFCoordinatorCreated(
            address(cloned),
            msg.sender,
            msg.sender
        );
        return address(cloned);
    }
    function cloneOperator(
        address link,
        bool copy
    ) external payable returns (address) {
        require(msg.value >= operatorFee,"need fee to clone");
        OperatorInterface cloned = OperatorInterface(copy ? Clones.copy(operatorImplementation) : Clones.clone(operatorImplementation));
        cloned.initialize(link, msg.sender);
        emit OperatorCreated(
            address(cloned),
            msg.sender,
            msg.sender
        );
        return address(cloned);
    }

    function cloneOCRAggregator(
        LinkTokenInterface _link,
        int192 _minValue,
        int192 _maxValue,
        AccessControllerInterface _billingAccessController,
        AccessControllerInterface _requesterAccessController,
        uint8 _decimals,
        string memory _description,
        bool copy
    ) external payable returns (address) {
        require(msg.value >= ocrFee,"need fee to clone");
        NewAggregatorParams memory params = NewAggregatorParams(_minValue, _maxValue, _decimals, _link, _billingAccessController, _requesterAccessController, _description);
        return _cloneOCRAggregator(params, copy);
    }

    function _cloneOCRAggregator(NewAggregatorParams memory params, bool copy) internal returns(address) {
        AccessControlledOffchainAggregatorInterface cloned = AccessControlledOffchainAggregatorInterface(
                copy ? Clones.copy(ocrImplementation) : Clones.clone(ocrImplementation)
                );
        _setupAggregator(cloned, params);
        return address(cloned);
    }

    function _makeConfigEncodedComponents( 
        uint64[7] memory config,
        uint8 rMax,
        uint8[] memory s,
        bytes32[] memory offchainPublicKeys,
        string memory peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] memory encryptions
        ) private pure returns(SetConfigEncodedComponents memory encodedComponenents) {            
        SharedSecretEncryptions memory sse = SharedSecretEncryptions(diffieHellmanPoint,sharedSecretHash,encryptions);
        encodedComponenents = SetConfigEncodedComponents({
            deltaProgress : uint64(config[0]),
            deltaResend : uint64(config[1]),
            deltaRound : uint64(config[2]),
            deltaGrace : uint64(config[3]),
            deltaC : uint64(config[4]),
            alphaPPB : uint64(config[5]),
            deltaStage : uint64(config[6]),
            rMax : rMax,
            s : s,
            offchainPublicKeys: offchainPublicKeys,
            peerIDs: peerIDs,
            sharedSecretEncryptions: sse
        });
    }
    function packDeltaComponent(
        uint64 deltaProgressNS,
        uint64 deltaResendNS,
        uint64 deltaRoundNS,
        uint64 deltaGraceNS,
        uint64 deltaC,
        uint64 alphaPPB,
        uint64 deltaStage
    ) public pure returns(uint64[7] memory packed) {
        /* chainlink used default: 35, 17, 30, 12(first 4, mainly retry related for each round, i.e. transmit)
           deltaC(control transmit frequency) and deltaStage controls frequency between submission 
           alphaPPB(%) controls 'rate change submit', in 1e9 so 1% is 1e7
         */
        require(deltaGraceNS < deltaRoundNS, "deltaGrace < deltaRound");
        require(deltaRoundNS < deltaProgressNS, "deltaRound < deltaProgress");
        packed[0] = deltaProgressNS;
        packed[1] = deltaResendNS;
        packed[2] = deltaRoundNS;
        packed[3] = deltaGraceNS;
        packed[4] = deltaC;
        packed[5] = alphaPPB;
        packed[6] = deltaStage;
    }

    function getDeltaParams(
        uint8 networkType,
        uint64 alphaPPB
    ) public pure returns(uint64[7] memory packed) {
        /* chainlink used default: 35, 17, 30, 12(first 4, mainly retry related for each round, i.e. transmit), 
           should never > deltaC but has must >= limit set in libocr depending on network
           the default is generally fine so the min deltaC is 60s
           deltaC(control transmit frequency) and deltaStage controls frequency between submission 
           alphaPPB(%) controls 'rate change submit', in 1e9 so 1% is 1e7
         */
        uint64 secondInNS = 1000000000;
        // these are the limits hardcoded inside libocr by chainId, value must be <= given with further restriction for grace/round/progress(see pack above)
        if (networkType == 1) {
            // moderate most POA
            // return packDeltaComponent(23 * secondInNS, 10 * secondInNS, 20 * secondInNS, 15 * secondInNS, 1 * 60 * secondInNS, alphaPPB, 5 * secondInNS);
            return packDeltaComponent(35 * secondInNS, 17 * secondInNS, 30 * secondInNS, 12 * secondInNS, 10 * 60 * secondInNS, alphaPPB, 10 * secondInNS);
        }
        else if (networkType == 2) {
            // fast say BSC
            // return packDeltaComponent(8 * secondInNS, 5 * secondInNS, 5 * secondInNS, 3 * secondInNS, 10 * secondInNS, alphaPPB, 5 * secondInNS);
            return packDeltaComponent(35 * secondInNS, 17 * secondInNS, 30 * secondInNS, 12 * secondInNS, 1 * 60 * secondInNS, alphaPPB, 10 * secondInNS);
        }
        else if (networkType == 3) {
            // public testnet(most, this is very fast)
            // return packDeltaComponent(2 * secondInNS, 2 * secondInNS, 1 * secondInNS, (1 * secondInNS)/2, 10 * secondInNS, alphaPPB, 5 * secondInNS);
            return packDeltaComponent(35 * secondInNS, 17 * secondInNS, 30 * secondInNS, 12 * secondInNS, 1 * 60 * secondInNS, alphaPPB, 10 * secondInNS);
        }
        else if (networkType == 4) {
            // super slow(no time based, 50 years between rounds)
            // return packDeltaComponent(23 * secondInNS, 10 * secondInNS, 20 * secondInNS, 15 * secondInNS, 10 * 60 * secondInNS, alphaPPB, 10 * secondInNS);
            return packDeltaComponent(35 * secondInNS, 17 * secondInNS, 30 * secondInNS, 12 * secondInNS, 60 * 60 * 24 * (3650 * 5 - 1) * secondInNS, alphaPPB, 30 * secondInNS);
        }
        else {
           // default slow, mainnet and private unknown
            // return packDeltaComponent(23 * secondInNS, 10 * secondInNS, 20 * secondInNS, 15 * secondInNS, 10 * 60 * secondInNS, alphaPPB, 10 * secondInNS);
            return packDeltaComponent(35 * secondInNS, 17 * secondInNS, 30 * secondInNS, 12 * secondInNS, 60 * 60 * secondInNS, alphaPPB, 30 * secondInNS);
        }
    }

    function makeSlowSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(0, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeModerateSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(1, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeFastSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(2, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }
    function makeTestnetSetConfigEncodedComponents(
        uint64 alphaPPB,
        uint8 rMax,
        uint8[] calldata s,
        bytes32[] calldata offchainPublicKeys,
        string calldata peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] calldata encryptions
        ) public pure returns(bytes memory encodedComponenents) {  
        return makeSetConfigEncodedComponents(getDeltaParams(3, alphaPPB), rMax, s, offchainPublicKeys, peerIDs, diffieHellmanPoint, sharedSecretHash, encryptions);  
    }

    function makeSetConfigEncodedComponents( 
        // uint64 deltaProgress,
        // uint64 deltaResend,
        // uint64 deltaRound,
        // uint64 deltaGrace,
        // uint64 deltaC,
        // uint64 alphaPPB,
        // uint64 deltaStage,
        uint64[7] memory config,
        uint8 rMax,
        uint8[] memory s,
        bytes32[] memory offchainPublicKeys,
        string memory peerIDs,
        bytes32 diffieHellmanPoint,
        bytes32 sharedSecretHash,
        bytes16[] memory encryptions
        ) public pure returns(bytes memory encodedComponenents) {   
        encodedComponenents = abi.encode(
            SetConfigEncodedComponents({
            deltaProgress : uint64(config[0]),
            deltaResend : uint64(config[1]),
            deltaRound : uint64(config[2]),
            deltaGrace : uint64(config[3]),
            deltaC : uint64(config[4]),
            alphaPPB : uint64(config[5]),
            deltaStage : uint64(config[6]),
            rMax : rMax,
            s : s,
            offchainPublicKeys: offchainPublicKeys,
            peerIDs: peerIDs,
            sharedSecretEncryptions: SharedSecretEncryptions(diffieHellmanPoint,sharedSecretHash,encryptions)
        }));
    }

    function setConfigEncodedComponents(
        SetConfigEncodedComponents calldata components
    ) public pure returns(bytes memory) {
        return abi.encode(components);
    }

    function _setupAggregator(AccessControlledOffchainAggregatorInterface aggregator, NewAggregatorParams memory params) internal {
        aggregator.initialize(
            /* billing params(5 below) can be revised later, here are the default */
            1000,             // _maximumGasPrice uint32(GWei?),
            20,              //_reasonableGasPrice uint32(GWei?),
            3.6e7,            // _microLinkPerEth, 3.6e7 microLINK, or 36 LINK
            1e8,              // _linkGweiPerObservation uint32,
            4e8,              // _linkGweiPerTransmission uint32,
            params.linkToken,          //_link Token Address,
            params.minValue,              // -2**191 
            params.maxValue,              // 2**191 - 1
            params.billingAccessController,       // _billingAccessController,
            params.requesterAccessController,       // _requesterAccessController,
            params.decimals,                   // _decimals,
            params.description,           // description
            msg.sender
            );

        //aggregator.transferOwnership(msg.sender);
        emit OCRAggregatorCreated(
            address(aggregator),
            msg.sender,
            msg.sender
        );
    }
}