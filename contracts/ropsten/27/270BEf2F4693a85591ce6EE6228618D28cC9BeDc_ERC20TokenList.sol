// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./utils/Address.sol";
import "./access/Ownable.sol";

/**
 *
 * @dev 결제용 ERC20 Token List 
 *
 */

contract ERC20TokenList is Ownable {
    using Address for address;

    address[] private _addresses;
    mapping (address => uint256) private _indexes;   // 1-based  1,2,3.....
    
    /**
     * @dev contains : 기존 등록 여부 조회
    */
    function contains(address addr) public view returns (bool) {
        return _indexes[addr] != 0;
    }

    /**
     * @dev addToken : ERC20 Token 추가 
     * 
     * Requirements:
     *
     *   address Not 0 address 
     *   중복여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */
    
    function addToken(address addr) public onlyOwner {

        //console.log("address = %s",addr);
        //console.log("contains = %s",contains(addr));

        require(addr != address(0),"TokenList/address_is_0");
        require(!contains(addr),"TokenList/address_already_exist");
        require(addr.isContract(),"TokenList/address_is_not_contract");

        _addresses.push(addr);
        _indexes[addr] = _addresses.length;
    }
    

    /**
     * @dev removeToken : ERC20 Token 삭제 
     * 
     * Requirements:
     *
     *   기존 존재여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */

    function removeToken(address addr) public  onlyOwner {
        require(contains(addr),"TokenList/address_is_not_exist");
        uint256 idx = _indexes[addr];
        uint256 toDeleteIndex = idx - 1;
        uint256 lastIndex = _addresses.length - 1;
        
        address lastAddress = _addresses[lastIndex];
        
        _addresses[toDeleteIndex] = lastAddress;
        _indexes[lastAddress] = toDeleteIndex + 1;
        
        _addresses.pop();
        delete _indexes[addr];
    }
    
    /**
     * @dev getAddressList : ERC20 Token List return 
     * 
	 */    
    function getAddressList() public view returns (address[] memory) {
        return _addresses;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}