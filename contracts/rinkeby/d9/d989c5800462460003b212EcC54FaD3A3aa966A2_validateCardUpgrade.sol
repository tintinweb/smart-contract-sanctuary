pragma solidity >=0.6.0 <0.8.0;


import "../interfaces/traitsOnChain.sol";
import "./Ivalidator.sol";
import "./validatorRoot.sol";

contract validateCardUpgrade is Ivalidator, validatorRoot  {

    uint16  constant public trait_AlphaUpgrade = 5;
    uint16  constant public trait_OGUpgrade    = 6;


    TraitsOnChain                 public     _toc;
    address                       public     token;
    mapping (uint256 => uint256)  public     validTokens;

    constructor(TraitsOnChain toc,address _token) {
        token = _token;
        _toc = toc;
    }

//
// function setTrait(uint16 traitID, uint16 tokenId, bool _value) public onlyAllowedOrSpecificTraitController(traitID) {
// function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result) {
// traits 0 - 50

    function is_valid(address _token, uint256 tokenid) external override notChuckNorris returns (uint256,bool) {
        // get traits of card
        if (_token != token) return (0,false);
        if (tokenid < 1000) return (0,false);
        uint16 _tokenid = uint16(tokenid);
        //
        if (_toc.hasTrait(trait_AlphaUpgrade,_tokenid)) {
            _toc.setTrait(trait_AlphaUpgrade,_tokenid,false);
            return (1,true);
        } else if (_toc.hasTrait(trait_OGUpgrade,_tokenid)) {
            _toc.setTrait(trait_OGUpgrade,_tokenid,false);
            return (0,true);
        } else return (0,false);
    }
}

pragma solidity ^0.7.0;


interface TraitsOnChain {
    function hasTrait(uint16 traitID, uint16 tokenId) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external;
}

pragma solidity >=0.6.0 <0.8.0;


interface Ivalidator {
    function setAccess(address, bool) external;
    function hasAccess(address) external view returns (bool);
    function is_valid(address _token, uint256 _tokenid) external returns (uint256,bool);
}

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ivalidator.sol";

abstract contract validatorRoot is Ivalidator, Ownable {
    mapping (address => bool) public access;

    modifier notChuckNorris {
        require(access[msg.sender],"Unauthorised access to this validator");
        _;
    }

    function setAccess(address actor, bool status) external override onlyOwner {
        access[actor] = status;
    }

    function hasAccess(address actor) external view override returns (bool) {
        return access[actor];
    }

    function getCardType(uint256 tokenid) internal pure returns (uint256) {
        if(10 <= tokenid && tokenid < 100) {
            return 0;
        } else if(100 <= tokenid && tokenid < 1000) {
            return 1;
        } else if (1000 <= tokenid ) {
            return 2;
        }
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

