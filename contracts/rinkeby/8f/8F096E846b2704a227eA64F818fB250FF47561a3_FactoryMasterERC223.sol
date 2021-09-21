//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC223/ERC223Burnable.sol";
import "../token/ERC223/ERC223Mintable.sol";
import "../token/ERC223/ERC223.sol";

import "../libraries/config-fee.sol";

contract FactoryMasterERC223 {
  
  ERC223Token[] private childrenErc223Token;
  

  enum Types {
    none,
    erc223,
    erc223Mintable,
    erc223Burnable
    }

  function createERC223Types(
    Types types,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply,
    uint256 cap
  ) external payable {
    require(
      keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked(("")))
    );
    require(
      keccak256(abi.encodePacked((symbol))) != keccak256(abi.encodePacked(("")))
    );
    if (types == Types.erc223) {
      // require(
      //   msg.value >= Config.fee_223,
      //   "ERC223:value must be greater than 0.0001"
      // );
      ERC223Token child = new ERC223Token(
        name,
        symbol,
        decimal,
        initialSupply,
        msg.sender
      );
      childrenErc223Token.push(child);
    }

    
  }

  function getLatestChildrenErc223() external view returns (address) {
    if (childrenErc223Token.length > 0) {
      return address(childrenErc223Token[childrenErc223Token.length - 1]);
    }
    return address(childrenErc223Token[0]);
  }
}

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "./ERC223.sol";

// /**
//  * @dev Extension of {ERC223} that allows token holders to destroy both their own
//  * tokens and those that they have an allowance for, in a way that can be
//  * recognized off-chain (via event analysis).
//  */
// contract ERC223Burnable is ERC223Token {
//     /**
//      * @dev Destroys `amount` tokens from the caller.
//      *
//      * See {ERC20-_burn}.
//      */
//     function burn(uint256 _amount) public {
//         balances[msg.sender] = balances[msg.sender] - _amount;
//         _totalSupply = _totalSupply - _amount;
        
//         bytes memory empty = hex"00000000";
//         emit Transfer(msg.sender, address(0), _amount, empty);
//     }
// }

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "./ERC223.sol";

// /**
//  * @dev Extension of {ERC223} that adds a set of accounts with the {MinterRole},
//  * which have permission to mint (create) new tokens as they see fit.
//  *
//  * At construction, the deployer of the contract is the only minter.
//  */
// contract ERC223Mintable is ERC223Token {
    
//     event MinterAdded(address indexed account);
//     event MinterRemoved(address indexed account);

//     mapping (address => bool) public _minters;

//     constructor () {
//         _addMinter(msg.sender);
//     }

//     modifier onlyMinter() {
//         require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
//         _;
//     }

//     function isMinter(address account) public view returns (bool) {
//         return _minters[account];
//     }

//     function addMinter(address account) public onlyMinter {
//         _addMinter(account);
//     }

//     function renounceMinter() public {
//         _removeMinter(msg.sender);
//     }

//     function _addMinter(address account) internal {
//         _minters[account] = true;
//         emit MinterAdded(account);
//     }

//     function _removeMinter(address account) internal {
//         _minters[account] = false;
//         emit MinterRemoved(account);
//     }
//     /**
//      * @dev See {ERC20-_mint}.
//      *
//      * Requirements:
//      *
//      * - the caller must have the {MinterRole}.
//      */
//     function mint(address account, uint256 amount) public onlyMinter returns (bool) {
//         balances[account] = balances[account] + amount;
//         _totalSupply = _totalSupply + amount;
        
//         bytes memory empty = hex"00000000";
//         emit Transfer(address(0),account, amount, empty);
//         return true;
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC223.sol";
import "./interfaces/IERC223Recipient.sol";
import "../../libraries/Address.sol";

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract ERC223Token is IERC223 {
  /**
   * @dev See `IERC223.totalSupply`.
   */

  uint256 public _totalSupply;
  string public name;
  string public symbol;
  uint8 public decimal;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  mapping(address => uint256) balances; // List of user balances.

//   function initialize(
//     address owner,
//     uint256 initialSupply,
//     string memory tokenName,
//     uint8 decimalUnits,
//     string memory tokenSymbol
//   ) public {
//     _totalSupply = initialSupply * 10**uint256(decimalUnits);
//     balances[owner] = _totalSupply;
//     name = tokenName;
//     decimals = decimalUnits;
//     symbol = tokenSymbol;
//     // emit Transfer(address(0), msg.sender, totalSupply);
//   }

    constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimal_,
    uint256 initialSupply,
    address owner
  ) {
    name = name_;
    symbol = symbol_;
    decimal = decimal_;
    _totalSupply = initialSupply * 10**uint256(decimal);
    balances[owner] = _totalSupply;
  }

  /**
   * @dev Transfer the specified amount of tokens to the specified address.
   *      Invokes the `tokenFallback` function if the recipient is a contract.
   *      The token transfer fails if the recipient is a contract
   *      but does not implement the `tokenFallback` function
   *      or the fallback function to receive funds.
   *
   * @param _to    Receiver address.
   * @param _value Amount of tokens that will be transferred.
   * @param _data  Transaction metadata.
   */
  function transfer(
    address _to,
    uint256 _value,
    bytes memory _data
  ) public override returns (bool success) {
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    if (Address.isContract(_to)) {
      IERC223Recipient receiver = IERC223Recipient(_to);
      receiver.tokenReceived(msg.sender, _value, _data);
    }
    emit Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  /**
   * @dev Transfer the specified amount of tokens to the specified address.
   *      This function works the same with the previous one
   *      but doesn't contain `_data` param.
   *      Added due to backwards compatibility reasons.
   *
   * @param _to    Receiver address.
   * @param _value Amount of tokens that will be transferred.
   */
  function transfer(address _to, uint256 _value)
    public
    override
    returns (bool success)
  {
    bytes memory empty = hex"00000000";
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    if (Address.isContract(_to)) {
      IERC223Recipient receiver = IERC223Recipient(_to);
      receiver.tokenReceived(msg.sender, _value, empty);
    }
    emit Transfer(msg.sender, _to, _value, empty);
    return true;
  }

  /**
   * @dev Returns balance of the `_owner`.
   *
   * @param _owner   The address whose balance will be returned.
   * @return balance Balance of the `_owner`.
   */
  function balanceOf(address _owner)
    public
    view
    override
    returns (uint256 balance)
  {
    return balances[_owner];
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Config {
  uint256 constant fee_721_mint = 0.2 ether;
  uint256 constant fee_721_burn = 0.3 ether;
  uint256 constant fee_20 = 0.0001 ether;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * [ERC1820 registry standard](https://eips.ethereum.org/EIPS/eip-1820) to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See `IERC1820Registry` and
 * `ERC1820Implementer`.
 */

interface IERC223 {
    /**
     * @dev Returns the total supply of the token.
     */
   //uint public _totalSupply;
    
    /**
     * @dev Returns the balance of the `who` address.
     */
    function balanceOf(address who) external view returns (uint);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address
     * and returns `true` on success.
     */
    function transfer(address to, uint value) external returns (bool success);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint value, bytes memory data) external returns (bool success);
     
     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
abstract contract IERC223Recipient {


 struct ERC223TransferInfo
    {
        address token_contract;
        address sender;
        uint256 value;
        bytes   data;
    }
    

    function tokenReceived(address _sender, uint _value, bytes memory _data) public virtual
    {
        /**
         * @dev Note that inside of the token transaction handler the actual sender of token transfer is accessible via the tkn.sender variable
         * (analogue of msg.sender for Ether transfers)
         * 
         * tkn.value - is the amount of transferred tokens
         * tkn.data  - is the "metadata" of token transfer
         * tkn.token_contract is most likely equal to msg.sender because the token contract typically invokes this function
        */
        ERC223TransferInfo memory tkn;
        tkn.token_contract = msg.sender;
        tkn.sender         = _sender;
        tkn.value          = _value;
        tkn.data           = _data;
        
        // ACTUAL CODE
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1
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