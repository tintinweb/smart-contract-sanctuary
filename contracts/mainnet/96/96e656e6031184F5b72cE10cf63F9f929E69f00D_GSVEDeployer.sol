// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFreeFromUpTo.sol";


/**
* @dev the gsve deployer has two purposes
* it deploys gsve smart wrappers, keeping track of the owners
* it allows users to deploy smart contracts using create and create2
*/
contract GSVEDeployer is Ownable{
    mapping(address => uint256) private _compatibleGasTokens;
    mapping(address => uint256) private _freeUpValue;

  constructor (address wchi, address wgst2, address wgst1) public {
    _compatibleGasTokens[wchi] = 1;
    _freeUpValue[wchi] = 30053;

    _compatibleGasTokens[wgst2] = 1;
    _freeUpValue[wgst2] = 30870;

    _compatibleGasTokens[wgst1] = 1;
    _freeUpValue[wgst1] = 20046;
  }

    /**
    * @dev add support for trusted gas tokens - those we wrapped
    */
    function addGasToken(address gasToken, uint256 freeUpValue) public onlyOwner{
        _compatibleGasTokens[gasToken] = 1;
        _freeUpValue[gasToken] = freeUpValue;
    }
    
    /**
    * @dev function to check if a gas token is supported by the deployer
    */
    function compatibleGasToken(address gasToken) public view returns(uint256){
        return _compatibleGasTokens[gasToken];
    }

    /**
    * @dev GSVE moddifier that burns supported gas tokens around a function that uses gas
    * the function calculates the optimal number of tokens to burn, based on the token specified
    */
    modifier discountGas(address gasToken) {
        if(gasToken != address(0)){
            require(_compatibleGasTokens[gasToken] == 1, "GSVE: incompatible token");
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IFreeFromUpTo(gasToken).freeFromUpTo(msg.sender,  (gasSpent + 16000) / _freeUpValue[gasToken]);
        }
        else{
            _;
        }
    }

    /**
    * @dev deploys a smart contract using the create function
    * if the contract is ownable, the contract ownership is passed to the message sender
    * the gas token passed in as argument is burned by the moddifier
    */
    function GsveDeploy(bytes memory data, address gasToken) public discountGas(gasToken) returns(address contractAddress) {
        assembly {
            contractAddress := create(0, add(data, 32), mload(data))
        }
        try Ownable(contractAddress).transferOwnership(msg.sender){
            emit ContractDeployed(msg.sender, contractAddress);
        }
        catch{
            emit ContractDeployed(msg.sender, contractAddress);
        }
    }

    /**
    * @dev deploys a smart contract using the create2 function and a user provided salt
    * if the contract is ownable, the contract ownership is passed to the message sender
    * the gas token passed in as argument is burned by the moddifier
    */
    function GsveDeploy2(uint256 salt, bytes memory data, address gasToken) public discountGas(gasToken) returns(address contractAddress) {
        assembly {
            contractAddress := create2(0, add(data, 32), mload(data), salt)
        }

        try Ownable(contractAddress).transferOwnership(msg.sender){
            emit ContractDeployed(msg.sender, contractAddress);
        }
        catch{
            emit ContractDeployed(msg.sender, contractAddress);
        }
    }
    
    event ContractDeployed(address indexed creator, address deploymentAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @dev interface to allow the burning of gas tokens from an address
*/
interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}