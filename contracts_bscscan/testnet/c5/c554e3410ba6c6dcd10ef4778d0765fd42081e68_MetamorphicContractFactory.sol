/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// Dependency file: @openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin\contracts\access\Ownable.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "E:\BlockchainWallet\YeSwap\Governance\node_modules\@openzeppelin\contracts\utils\Context.sol";
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
    constructor () {
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


// Root file: contracts\MetamorphicContractFactory.sol

pragma solidity 0.7.5;

// import "E:\BlockchainWallet\YeSwap\Governance\node_modules\@openzeppelin\contracts\access\Ownable.sol";

/**
 * @title Metamorphic Contract Factory
 * @author Derik Lu, simplified from: https://github.com/0age/metamorphic
 * @notice This contract creates metamorphic contracts, which clones the 
 * implementation contract specified in constructor. This metamorphic contract 
 * will be used as the patch of the calling contract with delegatecall.
 */
contract MetamorphicContractFactory is Ownable {
  // fires when a metamorphic contract is deployed by cloning another contract.
  event Metamorphosed(address metamorphicContract, address newImplementation);
  
  // store the initialization code for metamorphic contracts.
  bytes public metamorphicContractInitializationCode;

  // store hash of the initialization code for metamorphic contracts as well.
  bytes32 public metamorphicContractInitializationCodeHash;

  // maintain a mapping of metamorphic contracts to metamorphic implementations.
  mapping(address => address) private _implementations;

  // the list of all metamorphic contractes that have been created. 
  address[] public allMetamorphicContracts;

  /**
   * @dev In the constructor, set up the initialization code for metamorphic contracts.
   * Factory is not sensitive to gas consumption as it is not run at high rate,
   * so the original init code is modified a little to be easily understood.
   *
   * Metamorphic contract initialization code (37 bytes).
   * (8 bytes and 16 gas more than the original code at: 
   *   https://github.com/0age/metamorphic) 
   * 
   * 0x60006020816004601c335a63aaf10f428752fa60185780fd5b808151803b80938091923cf3
   * Description:
   *
   * pc|op|name         | [stack]                                | <memory>
   *
   * ** set the first stack item to zero - used later **
   * 00 60 push1                                                  
   * 01 00                [0]                                       <>
   * ** set second stack item to 32, length of word returned from staticcall **
   * 02 60 push1
   * 03 20 outsize        [0, 32]                                   <>
   *
   * ** set third stack item to 0, position of word returned from staticcall **
   * 04 81 dup2           [0, 32, 0]                                <>
   *
   * ** set fourth stack item to 4, length of selector given to staticcall **
   * 05 60 push1                                                  
   * 06 04                [0, 32, 0, 4]                             <>
   *
   * ** set fifth stack item to 28, position of selector given to staticcall **
   * 07 60 push1
   * 08 1c inpos          [0, 32, 0, 4, 28]                         <>
   *
   * ** set the sixth stack item to msg.sender, target address for staticcall **
   * 09 33 caller         [0, 32, 0, 4, 28, caller]                 <>
   *
   * ** set the seventh stack item to msg.gas, gas to forward for staticcall **
   * 10 5a gas            [0, 32, 0, 4, 28, caller, gas]            <>
   *
   * ** set the eighth stack item to selector, "what" to store via mstore **
   * ** 0xaaf10f42 = first four bytes of keccak256("getImplementation()") **
   * 11 63 push4
   * 12 aaf10f42 selector [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42]    <>
   *
   * ** set the ninth stack item to 0, "where" to store via mstore ***
   * 16 87 dup8           [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42, 0] <>
   *
   * ** call mstore, consume 8 and 9 from the stack, place selector in memory **
   * 17 52 mstore         [0, 32, 0, 4, 0, caller, gas]             <0xaaf10f42>
   *
   * ** call staticcall, consume items 2 through 7, place address in memory **
   * 18 fa staticcall     [0, 0/1 (if successful)]                 (<address>)
   *
   * ** set the jump offsset for success handling **
   * 19 60 push1
   * 20 18 offset         [0, 0/1, 24]                             (<address>)
   *
   * ** jump to following handling if successful **
   * 21 57 jumpi          [0]                                           <>
   *
   * ** set revert data offset **
   * 22 80 dup1           [0, 0]                                        <>
   *
   * ** revert **
   * 23 fd revert         []                                        *reverted!*
   *
   * ** flag the jump target **
   * 24 5b jumpdest       [0]                                       <address>
   *
   * ** set second stack item to set to 0 **
   * 25 80 dup1           [0, 0]                                    <address>
   *
   * ** push a third 0 to the stack, position of address in memory **
   * 26 81 dup2           [0, 0, 0]                                 <address>
   *
   * ** place address from position in memory onto third stack item **
   * 27 51 mload          [0, 0, address]                           <>
   *
   * ** place address to fourth stack item for extcodesize to consume **
   * 28 80 dup1           [0, 0, address, address]                  <>
   *
   * ** get extcodesize on fourth stack item for extcodecopy **
   * 29 3b extcodesize    [0, 0, address, size]                     <>
   *
   * ** dup and swap size for use by return at end of init code **
   * 30 80 dup1           [0, 0, address, size, size]               <> 
   * 31 93 swap4          [size, 0, address, size, 0]               <>
   *
   * ** push code position 0 to stack and reorder stack items for extcodecopy **
   * 32 80 dup1           [size, 0, address, size, 0, 0]            <>
   * 33 91 swap2          [size, 0, address, 0, 0, size]            <>
   * 34 92 swap3          [size, 0, size, 0, 0, address]            <>
   *
   * ** call extcodecopy, consume four items, clone runtime code to memory **
   * 35 3c extcodecopy    [size, 0]                                 <code>
   *
   * ** return to deploy final code in memory **
   * 36 f3 return         []                                        *deployed!*
   */
  constructor() {
    // assign the initialization code for the metamorphic contract.
    metamorphicContractInitializationCode = (
      hex"60006020816004601c335a63aaf10f428752fa60185780fd5b808151803b80938091923cf3"
    );

    // calculate and assign keccak256 hash of metamorphic initialization code.
    metamorphicContractInitializationCodeHash = keccak256(
      abi.encodePacked(
        metamorphicContractInitializationCode
      )
    );
  }

  /**
   * @dev Deploy a metamorphic contract by submitting a given salt or nonce
   * along with the address of an existing implementation contract to clone, and
   * optionally provide calldata for initializing the new metamorphic contract.
   * To replace the contract, first selfdestruct the current contract, then call
   * with the same salt value and a new implementation address (be aware that
   * all existing state will be wiped from the existing contract). Also note
   * that the first 20 bytes of the salt must match the calling address, which
   * prevents contracts from being created by unintended parties.
   * @param salt bytes32 The nonce that will be passed into the CREATE2 call and
   * thus will determine the resulant address of the metamorphic contract.
   * @param implementationContract address The address of the existing
   * implementation contract to clone.
   * @param metamorphicContractInitializationCalldata bytes An optional data
   * parameter that can be used to atomically initialize the metamorphic
   * contract.
   * @return metamorphicContractAddress Address of the metamorphic contract 
   * that will be created.
   */
  function deployMetamorphicContract(
    bytes32 salt,
    address implementationContract,
    bytes calldata metamorphicContractInitializationCalldata
  ) external payable onlyOwner returns (
    address metamorphicContractAddress
  ) {
    // move initialization calldata to memory.
    bytes memory data = metamorphicContractInitializationCalldata;

    // move the initialization code from storage to memory.
    bytes memory initCode = metamorphicContractInitializationCode;

    // declare variable to verify successful metamorphic contract deployment.
    address deployedMetamorphicContract;

    // determine the address of the metamorphic contract.
    metamorphicContractAddress = _getMetamorphicContractAddress(salt);
    
    if(_implementations[metamorphicContractAddress] == address(0))
        allMetamorphicContracts.push(metamorphicContractAddress);

    // store the implementation to be retrieved by the metamorphic contract.
    _implementations[metamorphicContractAddress] = implementationContract;

    // using inline assembly: load data and length of data, then call CREATE2.
    /* solhint-disable no-inline-assembly */
    assembly {
      let encoded_data := add(0x20, initCode) // load initialization code.
      let encoded_size := mload(initCode)     // load the init code's length.
      deployedMetamorphicContract := create2( // call CREATE2 with 4 arguments.
        0,                                    // do not forward any endowment.
        encoded_data,                         // pass in initialization code.
        encoded_size,                         // pass in init code's length.
        salt                                  // pass in the salt value.
      )
    } /* solhint-enable no-inline-assembly */

    // ensure that the contracts were successfully deployed.
    require(
      deployedMetamorphicContract == metamorphicContractAddress,
      "Failed to deploy the new metamorphic contract."
    );

    // initialize the new metamorphic contract if any data or value is provided.
    if (data.length > 0 || msg.value > 0) {
      /* solhint-disable avoid-call-value */
      (bool success,) = metamorphicContractAddress.call{value: msg.value}(data);
      /* solhint-enable avoid-call-value */

      require(success, "Failed to initialize the new metamorphic contract.");
    }

    emit Metamorphosed(deployedMetamorphicContract, implementationContract);
  }
  
  /**
   * @dev Bypass renounceOwnership of Ownable, so ownership cannot be killed.
   */
  function renounceOwnership() public pure override {
      revert("Renounce ownership Disabled!");
  }

  /**
   * @dev View function for retrieving the address of the implementation
   * contract to clone. Called by the constructor of each metamorphic contract.
   */
  function getImplementation() external view returns (address implementation) {
    return _implementations[msg.sender];
  }

  /**
   * @dev View function for retrieving the address of the current implementation
   * contract of a given metamorphic contract, where the address of the contract
   * is supplied as an argument. Be aware that the implementation contract has
   * an independent state and may have been altered or selfdestructed from when
   * it was last cloned by the metamorphic contract.
   * @param metamorphicContractAddress address The address of the metamorphic
   * contract.
   * @return implementationContractAddress Address of the corresponding 
   * implementation contract.
   */
  function getImplementationContractAddress(
    address metamorphicContractAddress
  ) external view returns (address implementationContractAddress) {
    return _implementations[metamorphicContractAddress];
  }

  /**
   * @dev View function for the number of Metamorphic Contracts ever been created.
   */
  function allMetamorphicContractsLength() external view returns (uint) {
        return allMetamorphicContracts.length;
  }

  /**
   * @dev Compute the address of the metamorphic contract that will be created
   * upon submitting a given salt to the contract.
   * @param salt bytes32 The nonce passed into CREATE2 by metamorphic contract.
   * @return metamorphicContractAddress Address of the corresponding metamorphic contract.
   */
  function findMetamorphicContractAddress(
    bytes32 salt
  ) external view returns (address metamorphicContractAddress) {
    // determine the address where the metamorphic contract will be deployed.
    metamorphicContractAddress = _getMetamorphicContractAddress(salt);
  }

  /**
   * @dev Internal view function for calculating a metamorphic contract address
   * given a particular salt.
   */
  function _getMetamorphicContractAddress(
    bytes32 salt
  ) internal view returns (address) {
    // determine the address of the metamorphic contract.
    return address(
      uint160(                      // downcast to match the address type.
        uint256(                    // convert to uint to truncate upper digits.
          keccak256(                // compute the CREATE2 hash using 4 inputs.
            abi.encodePacked(       // pack all inputs to the hash together.
              hex"ff",              // start with 0xff to distinguish from RLP.
              address(this),        // this contract will be the caller.
              salt,                 // pass in the supplied salt value.
              metamorphicContractInitializationCodeHash // the init code hash.
            )
          )
        )
      )
    );
  }
}