// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/* Contract Imports */
/* External Imports */

import { iMVM_DiscountOracle } from "./iMVM_DiscountOracle.sol";
import { Lib_AddressResolver } from "../libraries/resolver/Lib_AddressResolver.sol";

contract MVM_DiscountOracle is iMVM_DiscountOracle, Lib_AddressResolver{
    // Current l2 gas price
    uint256 public discount;
    uint256 public minL2Gas;
    mapping (address => bool) public xDomainWL;
    bool allowAllXDomainSenders;
    string constant public CONFIG_OWNER_KEY = "METIS_MANAGER";

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyManager() {
        require(
            msg.sender == resolve(CONFIG_OWNER_KEY),
            "MVM_DiscountOracle: Function can only be called by the METIS_MANAGER."
        );
        _;
    }


    constructor(
      address _addressManager,
      uint256 _initialDiscount
    )
      Lib_AddressResolver(_addressManager)
    {
      discount = _initialDiscount;
      minL2Gas = 200_000;
      allowAllXDomainSenders = false;
    }


    function getMinL2Gas() view public override returns (uint256){
      return minL2Gas;
    }

    function getDiscount() view public override returns (uint256){
      return discount;
    }

    function setDiscount(
        uint256 _discount
    )
        public
        override
        onlyManager
    {
        discount = _discount;
    }

    function setMinL2Gas(
        uint256 _minL2Gas
    )
        public
        override
        onlyManager
    {
        minL2Gas = _minL2Gas;
    }

    function setWhitelistedXDomainSender(
        address _sender,
        bool _isWhitelisted
    )
        external
        override
        onlyManager
    {
        xDomainWL[_sender] = _isWhitelisted;
    }

    function isXDomainSenderAllowed(
        address _sender
    )
        view
        override
        public
        returns (
            bool
        )
    {
        return (
            allowAllXDomainSenders == true
            || xDomainWL[_sender]
        );
    }

    function setAllowAllXDomainSenders(
        bool _allowAllXDomainSenders
    )
        public
        override
        onlyManager
    {
        allowAllXDomainSenders = _allowAllXDomainSenders;
    }

    function processL2SeqGas(address sender, uint256 _chainId)
    public payable override {
        require(isXDomainSenderAllowed(sender), "sender is not whitelisted");
        string memory ch = string(abi.encodePacked(uint2str(_chainId),"_MVM_Sequencer"));

        address sequencer = resolve(ch);
        require (sequencer != address(0), string(abi.encodePacked("sequencer address not available: ", ch)));

        //take the fee
        (bool sent, ) = sequencer.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface iMVM_DiscountOracle{

    function setDiscount(
        uint256 _discount
    ) external;
    
    function setMinL2Gas(
        uint256 _minL2Gas
    ) external;
    
    function setWhitelistedXDomainSender(
        address _sender,
        bool _isWhitelisted
    ) external;
    
    function isXDomainSenderAllowed(
        address _sender
    ) view external returns(bool);
    
    function setAllowAllXDomainSenders(
        bool _allowAllXDomainSenders
    ) external;
    
    function getMinL2Gas() view external returns(uint256);
    function getDiscount() view external returns(uint256);
    function processL2SeqGas(address sender, uint256 _chainId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {
    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(address _libAddressManager) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(string memory _name) public view returns (address) {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {
    /**********
     * Events *
     **********/

    event AddressSet(string indexed _name, address _newAddress, address _oldAddress);

    /*************
     * Variables *
     *************/

    mapping(bytes32 => address) private addresses;

    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(string memory _name, address _address) external onlyOwner {
        bytes32 nameHash = _getNameHash(_name);
        address oldAddress = addresses[nameHash];
        addresses[nameHash] = _address;

        emit AddressSet(_name, _address, oldAddress);
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(string memory _name) external view returns (address) {
        return addresses[_getNameHash(_name)];
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
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