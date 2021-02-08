//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./helpers/Ownable.sol";
import "./helpers/CloneFactory.sol";
import "./interfaces/IDYCO.sol";


/// @title DYCO factory contract
/// @author DAOMAKER
/// @notice It is the main contract, which allows to create and manage DYCOs
/// @dev It should be listened by TheGraph, as it provides all data related to child DYCOs
contract DYCOFactory is CloneFactory, Ownable {
  address public burnValley;
  address public dycoContractTemplate;

  // DYCO address => operator
  mapping(address => address) public dycoOperators;
  // DYCO address => DYCO used token
  mapping(address => address) public dycoToken;

  event DycoPaused(address dyco);
  event DycoResumed(address dyco);
  event DycoExited(address dyco, address receiver);
  event WhitelistedUsersAdded(address dyco, address[] users, uint256[] amounts);
  event TokensClaimed(address dyco, address receiver, uint256 burned, uint256 received);
  event DycoCreated(
    address dyco,
    address operator,
    address token,
    uint256 tollFee,
    uint256[] distributionDelays,
    uint256[] distributionPercents,
    bool initialDistributionEnabled,
    bool isBurnableToken
  );

  modifier ifValidDyco(address dyco) {
    require(dycoOperators[dyco] != address(0), "ifValidDyco: Dyco does not exists!");
    _;
  }

  modifier onlyDycoOperator(address dyco) {
    require(dycoOperators[dyco] == msg.sender, "onlyDycoOperator: Access to this project declined!");
    _;
  }

  // ------------------
  // CONSTRUCTOR
  // ------------------

  /// @param _dycoContractTemplate Template of DYCO logic, which should be used for future clones
  /// @param _burnValley Smart contract, which will hold all burned tokens (if some tokens not support burn method)
  constructor(address _dycoContractTemplate, address _burnValley) {
    dycoContractTemplate = _dycoContractTemplate;
    burnValley = _burnValley;
  }

  // ------------------
  // OWNER PUBLIC METHODS
  // ------------------

  /// @dev If some bug found, owner can deploy a new template and upgrade it
  /// Interface of the upgraded DYCO template should be the same!
  function upgradeDycoTemplate(address newTemplate) external onlyOwner {
    dycoContractTemplate = newTemplate;
  }

  // ------------------
  // PUBLIC METHODS
  // ------------------

  /// @dev Clone and init a new DYCO project, available for everyone
  function cloneDyco(
    address _token,
    address _operator,
    uint256 _tollFee,
    uint256[] calldata _distributionDelays,
    uint256[] calldata _distributionPercents,
    bool _initialDistributionEnabled,
    bool _isBurnableToken
  ) external returns (address) {
    address dyco = createClone(dycoContractTemplate);
    IDYCO(dyco).init(
      _token,
      _operator,
      _tollFee,
      _distributionDelays,
      _distributionPercents,
      _initialDistributionEnabled,
      _isBurnableToken,
      burnValley
    );

    dycoOperators[dyco] = _operator;
    dycoToken[dyco] = _token;

    emit DycoCreated(dyco, _operator, _token, _tollFee, _distributionDelays, _distributionPercents, _initialDistributionEnabled, _isBurnableToken);
    return dyco;
  }

  // ------------------
  // OPERATORS PUBLIC METHODS
  // ------------------

  /// @dev Check on DYCO.sol > addWhitelistedUsers()
  function addWhitelistedUsers(
    address _dyco,
    address[] memory _users,
    uint256[] memory _amounts
  ) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).addWhitelistedUsers(_users, _amounts);

    emit WhitelistedUsersAdded(_dyco, _users, _amounts);
  }

  /// @dev Check on DYCO.sol > pause()
  function pause(address _dyco) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).pause();

    emit DycoPaused(_dyco);
  }

  /// @dev Check on DYCO.sol > unpause()
  function unpause(address _dyco) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).unpause();

    emit DycoResumed(_dyco);
  }

  /// @dev Check on DYCO.sol > emergencyExit()
  function emergencyExit(
    address _dyco,
    address _receiver
  ) public onlyDycoOperator(_dyco) {
    IDYCO(_dyco).emergencyExit(_receiver);

    emit DycoResumed(_dyco);
  }

  // ------------------
  // PUBLIC METHODS
  // ------------------

  /// @dev Check on DYCO.sol > claimTokens()
  function claimTokens(
    address _dyco,
    uint256 _amount
  ) public ifValidDyco(_dyco) returns (uint256, uint256) {
    (uint256 burnedTokens, uint256 transferredTokens) = IDYCO(_dyco).claimTokens(msg.sender, _amount);

    emit TokensClaimed(_dyco, msg.sender, burnedTokens, transferredTokens);
    return (
      burnedTokens,
      transferredTokens
    );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "@openzeppelin/contracts/GSN/Context.sol";


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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface IDYCO {
  function pause() external;
  function unpause() external;
  function emergencyExit(address receiver) external;
  function claimTokens(address receiver, uint256 amount) external returns (uint256, uint256);
  function init(
    address token,
    address operator,
    uint256 tollFee,
    uint256[] calldata distributionDelays,
    uint256[] calldata distributionPercents,
    bool initialDistributionEnabled,
    bool isBurnableToken,
    address burnValley
  ) external;
  function addWhitelistedUsers(
    address[] calldata users,
    uint256[] calldata amounts
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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