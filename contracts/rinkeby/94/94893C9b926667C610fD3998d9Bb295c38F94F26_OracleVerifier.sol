// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AuthorityGranter.sol";

/** @title Oracle Verifier -- This contract controls the adding to and removal from the list of verified oracles.
  * 
  */  
contract OracleVerifier is AuthorityGranter {

    address mevuAccount;
    mapping (address => bytes32) phoneHashAtAddress;
    mapping (bytes32 => address) addressAtPhonehash;
    mapping (address => bool) public verified;
    mapping (address => uint256) public timesRemoved;
    bytes32 empty;

    constructor() {
        mevuAccount = msg.sender;
    }
    
    /** @dev Registers an address as a verified Oracle so the user may register to report event outcomes.
      * @param newOracle - address of the new oracle.
      * @param phoneNumber - ten digit phone number belonging to Oracle which has already been verified.
      */
    function addVerifiedOracle(address newOracle, uint256 phoneNumber) onlyAuth external  {
        bytes32 phoneHash = keccak256(abi.encodePacked(phoneNumber));
        if (verified[newOracle]) {
            revert();
        } else {
            if (addressAtPhonehash[phoneHash] == address(0)
            && phoneHashAtAddress[newOracle] == empty) {
                verified[newOracle] = true;
                addressAtPhonehash[phoneHash] = newOracle;
                phoneHashAtAddress[newOracle] = phoneHash;
            }
        }       
    }
    
    /** @dev Removes an address as a verified Oracle so the user may no longer register to report event outcomes.
      * @param oracle - address of the oracle to be removed.
      */
    function removeVerifiedOracle (address oracle) onlyAuth external {
        verified[oracle] = false;
        timesRemoved[oracle] += 1;
    }
    
    function checkVerification (address oracle) external view returns (bool) {
        return verified[oracle];        
    }

   function toBytes(uint256 x) external pure returns (bytes memory c)  {
        bytes32 b = bytes32(x);
        c = new bytes(32);
        for (uint256 i=0; i < 32; i++) {
            c[i] = b[i];
        }      
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthorityGranter is Ownable {

    mapping (address => bool) internal isAuthorized;  

    modifier onlyAuth () {
        require(isAuthorized[msg.sender], "Only authorized sender will be allowed");               
        _;
    }

    function grantAuthority (address nowAuthorized) external onlyOwner {
        require(isAuthorized[nowAuthorized] == false, "Already granted");
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) external onlyOwner {
        require(isAuthorized[unauthorized] == true, "Already unauthorized");
        isAuthorized[unauthorized] = false;
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

