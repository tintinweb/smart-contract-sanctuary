/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Create2.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address payable) {
        address payable addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

// File: @openzeppelin/contracts/proxy/Proxy.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// File: contracts/proxy/BaseUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;



/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract BaseUpgradeabilityProxy is Proxy {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: contracts/proxy/BaseAdminUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;


/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }
}

// File: contracts/proxy/InitializableAdminUpgradeabilityProxy.sol

//  
pragma solidity ^0.7.3;


/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));

    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }

    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

// File: contracts/interfaces/IZoom.sol

//  
pragma solidity ^0.7.3;


/**
 * @dev IZoom contract interface. See {IZoom}.
 * @author bit-zoom
 */
interface IZoom {

  //the params about the fee for zoom option
  function baseFeeNumerator() external view returns (uint256 _baseFeeNumerator);
  function optionFeeNumerator() external view returns (uint256 _optionFeeNumerator);
  function optionFeeDenominator() external view returns (uint256 _optionFeeDenominator);
  function orderFinishDelay() external view returns (uint256 _orderFinishDelay );

  //contract implementation
  function zoomERC20Implementation() external view returns (address _zoomERC20Implementation);
  function optionImplementation() external view returns (address _optionImplementation);

  function rewardPool() external view returns (address _rewardPool);
  function optionFactory() external view returns (address _optionFactory);
  function governance() external view returns (address _governance);
  function orderMarket() external view returns (address _orderMarket);

  //check the address is in the whitelist, it works when the enableWhiteListFn sets with true
  function isInWhiteList( address _user ) external view returns (bool);

  //return contract address, the contract may not be deployed yet
  function getOptionAddress(bytes32 _optionName, uint256 _expirationTimestamp, address _targetToken, uint256 _optionNonce) external view returns (address);
  //return contract address, the contract may not be deployed yet
  function getZoomTokenAddress(bytes32 _optionName, uint256 _expirationTimestamp, address _targetToken, uint256 _optionNonce, bool _isOptionToken) external view returns (address);
  
  //access restriction - owner (dev)
  //start zoom 
  function startZoom() external;
  //update this will only affect contracts deployed after
  function updateOptionImplementation(address _newImplementation) external returns (bool);
  //update this will only affect contracts deployed after
  function updateZoomERC20Implementation(address _newImplementation) external returns (bool);
 
  //access restriction - governance
  function updateRewardPool(address _address) external returns (bool);
  function updateOptionFactory(address _address) external returns (bool);
  function updateOrderMarket(address _address) external returns (bool);

  function updateFees(uint256 _baseFeeNumerator,uint256 _optionFeeNumerator, uint256 _optionFeeDenominator) external returns (bool);
  function updateOrderFinishDelay( uint256 _delaySeconds ) external returns (bool);
  function updateGovernance(address _address) external returns (bool);
  function setWhiteList( address _user, bool _openTag ) external;
  function enableWhiteListFn( bool _enable ) external;
}

// File: contracts/interfaces/IOption.sol

//  
pragma solidity ^0.7.3;

pragma experimental ABIEncoderV2;

/**
 * @dev Option contract interface. See {Option}.
 * @author bit-zoom
 */
interface IOption {

  struct OptionDetails {
        string name;
        address baseToken;
        address targetToken;
        address optionToken;
        address proofToken;
        uint256 baseAmount;
        uint256 targetAmout;
        uint256 totalSupply;
        uint64 expirationTimestamp;
        uint64 expirationDelay;    
        uint64 optionNonce;
    }

  function getOptionDetails()
    external view returns (
        string memory _name,
        address _baseToken,
        address _targetToken,
        address _optionToken,
        address _proofToken,
        uint256 _baseAmount,   
        uint256 _targetAmout,  
        uint256 _totalSupply,
        uint64 _expirationTimestamp,
        uint64 _expirationDelay,
        uint64 _optionNonce
    );

  function getOptionDetailsEx()
    external view 
    returns (IOption.OptionDetails memory _option);

  function subscribeOption( uint256 _amount ) external;
  function unsubscribeOption( uint256 _amount ) external;
  function subscribeOptionByContract(uint256 _amount ) external returns ( uint256 _mintAmount );
  function unsubscribeOptionByContract(uint256 _amount ) external returns ( uint256 _burnAmount );
  function excuteOption( uint256 _amount ) external;
  function collectOption( uint256 _amount ) external;
 
  //valid the status
  function validStatus() external view;

}

// File: contracts/interfaces/IOptionFactory.sol

//  
pragma solidity ^0.7.3;

/**
 * @dev IOptionFactory contract interface. See {OptionFactory}.
 * @author bit-zoom
 */
interface IOptionFactory {

  //create option for zoom
  function createOption(
      address _baseToken,
      address _targetToken,
      uint256 _baseAmount,   
      uint256 _targetAmout,  
      uint256 _totalSupply,
      uint64  _expirationTimestamp,
      uint64  _expirationDelay
  ) external;


  //valid the status of an option address
  function validOptionStatus(address _optionAddress) external view;
  
  function getActiveOptionAddresses() external view  returns (address[] memory) ;
  function getAllOptionAddresses() external view  returns (address[] memory) ;

  function optionNonce() external view  returns (uint256 _optionNonce) ;
  function activeCount() external view  returns (uint256 _activeCount) ;
  function zoom() external view  returns (address _zoom) ;

   //access restriction - dev
  //set the status of option
  function setActive(address _optionAddress, bool _active) external returns (bool);
  //when start the zoom or update the option factory by calling hookZoom to make the factory contract work normal 
  function hookZoom(address _zoom) external  returns (bool);
  
}

// File: contracts/interfaces/IOrderMarket.sol

//  
pragma solidity ^0.7.3;


// pragma experimental ABIEncoderV2;

/**
 * @dev IOrderMarket contract interface. See {OrderMarket}.
 * @author bit-zoom
 */
interface IOrderMarket {


  struct OrderDetails {
        string name;
        address optionAddress;
        uint256 orderId;
        address marketMaker;
        uint256 price;
        uint256 amount;
        uint256 acceptableUserNonce;
        uint256 finishTimeStamp;
        uint256 userNonce;
        uint256 commitAmount;
    }

  struct UserDetails {
        uint256 orderId;
        address user;
        uint256 index;
        uint256 price;
        uint256 amount;
        uint256 commitTimeStamp;
        uint256 acceptTimeStamp;
        uint256 commitAmount;
    }

  
  function orderNonce() external view  returns (uint256 _orderNonce) ;
  function zoom() external view  returns (address _zoom) ;

  function getOrderDetails(uint256 _orderId)
    external view returns (
        string memory _name,
        address _optionAddress,
        address _marketMaker,
        uint256 _price,
        uint256 _amount,
        uint256 _acceptableUserNonce,
        uint256 _finishTimeStamp,
        uint256 _userNonce,
        uint256 _commitAmount
    );

  function getOrderDetailsEx(uint256 _orderId)
    external view 
    returns (IOrderMarket.OrderDetails memory _order);


  function getUserDetails( uint256 _orderId, uint256 _userNonce )
    external view returns (
        address _user,
        uint256 _index,
        uint256 _price,
        uint256 _amount,
        uint256 _commitTimeStamp,
        uint256 _acceptTimeStamp,
        uint256 _commitAmount
    );

  function getUserDetailsEx(uint256 _orderId, uint256 _userNonce )
    external view 
    returns (IOrderMarket.UserDetails memory _order);


  //for market maker
  function createOrder(address _optionAddress,uint256 _price, uint256 _amount ) external;
  function addOrder( uint256 _orderId, uint256 _amount ) external;
  function finishOrder( uint256 _orderId, uint256 _acceptableUserNonce ) external;
 
  //for user
  function subscribeOrder(uint256 _orderId, uint256 _amount ) external;
  function acceptOrder(uint256 _orderId, uint256 _userNonce )  external;
  function unsubscribeOrder( uint256 _orderId, uint256 _userNonce ) external;
 
  //valid the status
  function validStatus(uint256 _orderId) external view;

  function getMarketMakerOrders( address _marketMaker ) external view  returns (uint256[] memory) ;
  function getUserOrders( address _user ) external view  returns (uint256[] memory ) ;
  function getUserOrderIndexs( address _user, uint256 _orderId ) external view  returns (uint256[] memory ) ;
  
  //access restriction - dev
  //when start the zoom or update the option factory by calling hookZoom to make the factory contract work normal 
  function hookZoom(address _zoom) external  returns (bool);
  
}

// File: contracts/interfaces/IOwnable.sol

//  
pragma solidity ^0.7.3;


/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}

// File: @openzeppelin/contracts/proxy/Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/src/Ownable.sol

//  
pragma solidity ^0.7.3;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author bit-zoom
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferCompleted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ZOOM: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferCompleted(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferInitiated(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function claimOwnership() public virtual {
        require(_newOwner == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransferCompleted(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// File: contracts/src/Zoom.sol

//  
pragma solidity ^0.7.3;








/**
 * @title Zoom contract
 * @author bit-zoom
 */
contract Zoom is IZoom, Ownable {

  uint256 public  override baseFeeNumerator = 0; 
  uint256 public  override optionFeeNumerator = 10; 
  uint256 public  override optionFeeDenominator = 10000; 

  uint256 public  override orderFinishDelay = 3600;//s; 

  address public  override optionImplementation;
  address public  override zoomERC20Implementation;

  address public  override optionFactory;
  address public  override orderMarket;
  address public  override rewardPool;
  address public  override governance;


  /// tags show address can create option
  mapping (address => bool) public whiteList;
  bool public enableWhiteList = true;

  modifier onlyGovernance() {
    require(msg.sender == governance, "ZOOM: caller not governance");
    _;
  }

  constructor (
    address _optionImplementation,
    address _zoomERC20Implementation,
    address _optionFactory,
    address _orderMarket,
    address _rewardPool,
    address _governance
  ) {

    optionImplementation = _optionImplementation;
    zoomERC20Implementation = _zoomERC20Implementation;
    optionFactory = _optionFactory;
    orderMarket = _orderMarket;
    rewardPool = _rewardPool;
    governance = _governance;

    initializeOwner();
  }

  /// @notice return option contract address, the contract may not be deployed yet
  function getOptionAddress(
    bytes32 _optionName,
    uint256 _expirationTimestamp,
    address _targetToken,
    uint256 _optionNonce
  )
   public view override returns (address)
  {
    return _computeAddress(
      keccak256(abi.encodePacked(_optionName, _expirationTimestamp, _targetToken, _optionNonce)),optionFactory
    );
  }

  /// @notice return zoomToken contract address, the contract may not be deployed yet
  function getZoomTokenAddress(
    bytes32 _optionName,
    uint256 _expirationTimestamp,
    address _targetToken,
    uint256 _optionNonce,
    bool _isOptionToken
  )external view override returns (address) 
  {
    return _computeAddress(
      keccak256(abi.encodePacked(
        _optionName,
        _expirationTimestamp,
        _targetToken,
        _optionNonce,
        _isOptionToken ? "OPTION" : "PROOF")
      ),
      getOptionAddress(_optionName, _expirationTimestamp, _targetToken, _optionNonce)
    );
  }

  function startZoom() 
  external override onlyOwner{
    IOptionFactory(optionFactory).hookZoom(address(this));
    IOrderMarket(orderMarket).hookZoom(address(this));
  }

  /// if openTag <=0, removed 
  function setWhiteList( address _user, bool _openTag)
      external override onlyGovernance{
      whiteList[_user] = _openTag;
  }

  //enable whitelist function
  function enableWhiteListFn( bool _enable ) 
  external override onlyGovernance{
    enableWhiteList = _enable;
  }

  /// @dev update this will only affect options deployed after
  function updateOptionImplementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "ZOOM: new implementation is not a contract");
    optionImplementation = _newImplementation;
    return true;
  }

  /// @dev update this will only affect zoomTokens of zooms of protocols deployed after
  function updateZoomERC20Implementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "ZOOM: new implementation is not a contract");
    zoomERC20Implementation = _newImplementation;
    return true;
  }
  
  function updateRewardPool(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "ZOOM: address cannot be 0");
    rewardPool = _address;
    return true;
  }

  function updateOptionFactory(address _address)
   external override onlyGovernance returns (bool)
  {

    require(_address != address(0), "ZOOM: address cannot be 0");
    optionFactory = _address;
    IOptionFactory(optionFactory).hookZoom(address(this));
    return true;

  }

  function updateOrderMarket(address _address)
   external override onlyGovernance returns (bool)
  {

    require(_address != address(0), "ZOOM: address cannot be 0");
    orderMarket = _address;
    IOrderMarket(orderMarket).hookZoom(address(this));
    return true;

  }

  function updateGovernance(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "ZOOM: address cannot be 0");
    require(_address != owner(), "ZOOM: governance cannot be owner");
    governance = _address;
    return true;
  }

  function updateFees(
    uint256 _baseFeeNumerator,
    uint256 _optionFeeNumerator,
    uint256 _optionFeeDenominator
  )external override onlyGovernance returns (bool)
  {
    require(_optionFeeDenominator > 0, "ZOOM: denominator cannot be 0");
    baseFeeNumerator = _baseFeeNumerator;
    optionFeeNumerator = _optionFeeNumerator;
    optionFeeDenominator = _optionFeeDenominator;
    return true;
  }

  function updateOrderFinishDelay( uint256 _delaySeconds ) 
  external override onlyGovernance returns (bool)
  {
    require(_delaySeconds > 0, "ZOOM: delaySeconds cannot be 0");
    orderFinishDelay = _delaySeconds;
    return true;
  }

  function isInWhiteList(
    address _user
  )external view override  returns (bool)
  { 
    if(!enableWhiteList){
      return true;
    }
    return whiteList[_user];
  }

  function _computeAddress(bytes32 salt, address deployer) private pure returns (address) {
    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    return Create2.computeAddress(salt, keccak256(bytecode), deployer);
  }
}