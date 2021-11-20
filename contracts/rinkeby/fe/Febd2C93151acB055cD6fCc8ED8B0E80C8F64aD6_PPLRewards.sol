// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../Blimpie/Delegated.sol';
//import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC721{
  function balanceOf( address owner ) external view returns( uint );
  function ownerOf( uint tokenId ) external view returns( address );
  function tokenOfOwnerByIndex(address owner, uint index) external view returns( uint );
  function walletOfOwner(address owner) external view returns(uint[] calldata);
}

interface IPPL20{
  function burnFromAccount( address account, uint pineapples ) external;
  function burnFromToken( address tokenContract, uint tokenId, uint pineapples ) external;

  function mintToAccount( address account, uint pineapples ) external;
  function mintToToken( address tokenContract, uint tokenId, uint pineapples ) external;

  function transferAccount2Token( address sender, address tokenContract, uint tokenId, uint pineapples ) external;
  function transferToken2Account( address tokenContract, uint tokenId, address recipient, uint pineapples ) external;
}


/*
abstract contract WalletOfOwner is IERC721{
  function walletOfOwner( address owner ) xternal view returns(uint[] calldata){
    uint balance = balanceOf( owner );
    uint[] wallet = new uint[balance];
    for( uint i = 0; i < balance; ++i ){
      wallet[i] = tokenOfOwnerByIndex( owner, i );
    }
    delete balance;
    return wallet;
  }
}
*/

contract PPLRewards is Delegated {
  struct Collection {
    uint epoch;
    uint maxPeriods;
    uint period;

    int value;
    bool hasWalletOf;

    //tokenId => timestamp
    mapping(uint => uint) claimed;

    //tokenId => value
    mapping(uint => int) specials;
  }

  string public name = "Pineapple Rewards";
  string public symbol = "PPLX";
  address public pineapplesAddress;
  mapping(address => Collection) public collections;

  constructor()
    Delegated(){
  }

  //external
  fallback() external payable {}

  receive() external payable {}

  //failsafe
  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function checkReward( address account, address[] calldata tokenContracts ) external view returns( uint ){
    uint pineapples;
    for( uint i; i < tokenContracts.length; ++i ){
      Collection storage collection = collections[ tokenContracts[i] ];
      if( collection.value <= 0 )
        continue;


      IERC721 proxy = IERC721( tokenContracts[i] );
      if( collection.hasWalletOf ){
        uint[] memory tokenIds = proxy.walletOfOwner( account );
        for(uint j; j < tokenIds.length; ++j ){
          if( collection.specials[tokenIds[j]] == 0 ){
            pineapples += _calculateReward( collection, tokenIds[j] );
          }
          else if( collection.specials[tokenIds[j]] > 0 ){
            pineapples += uint(collection.specials[tokenIds[j]]);
          }
        }
      }
      else{
        uint tokenId;
        uint balance = proxy.balanceOf( account );
        for(uint j; j < balance; ++j ){
          tokenId = proxy.tokenOfOwnerByIndex( account, j );
          if( collection.specials[tokenId] == 0 ){
            pineapples += _calculateReward( collection, tokenId );
          }
          else if( collection.specials[tokenId] > 0 ){
            pineapples += uint(collection.specials[tokenId]);
          }
        }
      }
    }

    return pineapples;
  }

  function checkToken( address tokenContract, uint tokenId ) external view returns( uint ){
    Collection storage collection = collections[ tokenContract ];
    if( collection.value <= 0 )
      return 0;
    else
      return _calculateReward( collection, tokenId );
  }

  function claimToTokens( address[] calldata tokenContracts, uint[] calldata tokenIds ) external {
    uint pineapples;
    address account = _msgSender();
    IPPL20 pplProxy = IPPL20( pineapplesAddress );
    for( uint i; i < tokenContracts.length; ++i ){
      Collection storage collection = collections[ tokenContracts[i] ];
      if( collection.value <= 0 )
        continue;


      uint tokenId = tokenIds[i];
      IERC721 proxy = IERC721( tokenContracts[i] );
      if( proxy.ownerOf( tokenId ) == account ){
        if( collection.specials[ tokenId ] == 0 ){
          pineapples = _calculateReward( collection, tokenId );
          pplProxy.mintToToken( tokenContracts[i], tokenId, pineapples );
          collection.claimed[ tokenId ] = block.timestamp;
        }
        else if( collection.specials[ tokenId ] > 0 ){
          pineapples = uint(collection.specials[ tokenId ]);
          pplProxy.mintToToken( tokenContracts[i], tokenId, pineapples ); 
          collection.specials[ tokenId ] = -1;
        }
      }
    }
  }

  function getCollection( address tokenContract ) external view returns( uint, uint, uint, int, bool ){
    return (
      collections[ tokenContract ].epoch,
      collections[ tokenContract ].maxPeriods,
      collections[ tokenContract ].period,
      collections[ tokenContract ].value,
      collections[ tokenContract ].hasWalletOf
    );
  }

  function _calculateReward( Collection storage collection, uint tokenId ) private view returns ( uint ){
    uint timestamp = collection.epoch > collection.claimed[ tokenId ] ?
      collection.epoch :
      collection.claimed[ tokenId ];

    uint periods = (block.timestamp - timestamp) / collection.maxPeriods;
    if( periods <= collection.maxPeriods )
      return uint(collection.value) * periods;
    else
      return uint(collection.value) * collection.maxPeriods;
  }

  function setPineappleContract( address pineapplesAddress_ ) external onlyDelegates {
    require( pineapplesAddress != pineapplesAddress_, "New value matches old" );
    pineapplesAddress = pineapplesAddress_;
  }

  function setRewards( address collection,
    uint epoch, uint maxPeriods, uint period, int value,
    uint[] calldata specialTokens, int[] calldata specialRewards ) external onlyDelegates {

      //byref
    Collection storage c = collections[ collection ];
    c.epoch = epoch;
    c.maxPeriods = maxPeriods;
    c.period = period;
    c.value = value;

    for( uint i; i < specialTokens.length; ++i ){
      //NRZ
      if( specialRewards[i] == 0 && c.specials[specialTokens[i]] > 0 )
        c.specials[specialTokens[i]] = -1;
      else
        c.specials[specialTokens[i]] = specialRewards[i];
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/********************
* @author: Squeebo *
********************/

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;

  constructor(){
    _delegates[owner()] = true;
  }

  modifier onlyDelegates {
    require(_delegates[msg.sender], "Invalid delegate" );
    _;
  }

  //onlyOwner
  function isDelegate( address addr ) external view onlyOwner returns ( bool ){
    return _delegates[addr];
  }

  function setDelegate( address addr, bool isDelegate_ ) external onlyOwner{
    _delegates[addr] = isDelegate_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}