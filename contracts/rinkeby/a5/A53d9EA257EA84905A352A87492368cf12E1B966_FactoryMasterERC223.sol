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
        initialSupply
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import './ContractReceiver.sol';
import './TokenRecipient.sol';

// https://www.ethereum.org/token

// ERC20 token with added ERC223 and Ethereum-Token support
//
// Blend of multiple interfaces:
// - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// - https://www.ethereum.org/token (uncontrolled, non-standard)
// - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol

contract ERC223Token {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) balances_;
  mapping(address => mapping(address => uint256)) allowances_;

  // ERC20
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Transfer(address indexed from, address indexed to, uint256 value);
  // bytes    data ); use ERC20 version instead

  // Ethereum Token
  event Burn(address indexed from, uint256 value);

    constructor(
      string memory tokenName,
      string memory tokenSymbol,
      uint8 decimalUnits,
      uint256 initialSupply
    ) {
      totalSupply = initialSupply * 10**uint256(decimalUnits);
      balances_[msg.sender] = totalSupply;
      name = tokenName;
      decimals = decimalUnits;
      symbol = tokenSymbol;
      emit Transfer(address(0), msg.sender, totalSupply);
    }

  function initialize(
    address owner,
    uint256 initialSupply,
    string memory tokenName,
    uint8 decimalUnits,
    string memory tokenSymbol
  ) public {
    totalSupply = initialSupply * 10**uint256(decimalUnits);
    balances_[owner] = totalSupply;
    name = tokenName;
    decimals = decimalUnits;
    symbol = tokenSymbol;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  // receive() external payable {
  //     revert("does not accept eth");
  // }

  // fallback() external payable {
  //     revert("calldata does not match a function");
  // }

  // ERC20
  function balanceOf(address owner) public view returns (uint256) {
    return balances_[owner];
  }

  // ERC20
  //
  // WARNING! When changing the approval amount, first set it back to zero
  // AND wait until the transaction is mined. Only afterwards set the new
  // amount. Otherwise you may be prone to a race condition attack.
  // See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

  function approve(address spender, uint256 value)
    public
    returns (bool success)
  {
    allowances_[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  // recommended fix for known attack on any ERC20
  function safeApprove(
    address _spender,
    uint256 _currentValue,
    uint256 _value
  ) public returns (bool success) {
    // If current allowance for _spender is equal to _currentValue, then
    // overwrite it with _value and return true, otherwise return false.

    if (allowances_[msg.sender][_spender] == _currentValue)
      return approve(_spender, _value);

    return false;
  }

  // ERC20
  function allowance(address owner, address spender)
    public
    view
    returns (uint256 remaining)
  {
    return allowances_[owner][spender];
  }

  // ERC20
  function transfer(address to, uint256 value) public returns (bool success) {
    bytes memory empty; // null
    _transfer(msg.sender, to, value, empty);
    return true;
  }

  // ERC20
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public returns (bool success) {
    require(value <= allowances_[from][msg.sender]);

    allowances_[from][msg.sender] -= value;
    bytes memory empty;
    _transfer(from, to, value, empty);

    return true;
  }

  // Ethereum Token
  function approveAndCall(
    address spender,
    uint256 value,
    bytes calldata context
  ) public returns (bool success) {
    if (approve(spender, value)) {
      tokenRecipient recip = tokenRecipient(spender);
      recip.receiveApproval(msg.sender, value, context);
      return true;
    }
    return false;
  }

  // Ethereum Token
  function burn(uint256 value) public returns (bool success) {
    require(balances_[msg.sender] >= value);
    balances_[msg.sender] -= value;
    totalSupply -= value;

    emit Burn(msg.sender, value);
    return true;
  }

  // Ethereum Token
  function burnFrom(address from, uint256 value) public returns (bool success) {
    require(balances_[from] >= value);
    require(value <= allowances_[from][msg.sender]);

    balances_[from] -= value;
    allowances_[from][msg.sender] -= value;
    totalSupply -= value;

    emit Burn(from, value);
    return true;
  }

  // ERC223 Transfer and invoke specified callback
  function transferERC223(
    address to,
    uint256 value,
    bytes calldata data,
    string calldata custom_fallback
  ) public returns (bool success) {
    _transfer(msg.sender, to, value, data);

    ContractReceiver rx = ContractReceiver(to);
    // https://docs.soliditylang.org/en/v0.5.1/050-breaking-changes.html#semantic-and-syntactic-changes
    (bool resok, bytes memory resdata) = address(rx).call(
      abi.encodeWithSignature(custom_fallback, msg.sender, value, data)
    );

    require(resok, 'custom fallback failed');
    if (resdata.length > 0) {} // suppress warning

    return true;
  }

  // ERC223 Transfer to a contract or externally-owned account
  function transferERC223ToContractOrEOA(
    address to,
    uint256 value,
    bytes calldata data
  ) public returns (bool success) {
    if (isContract(to)) {
      return transferToContract(to, value, data);
    }

    _transfer(msg.sender, to, value, data);
    return true;
  }

  // ERC223 Transfer to contract and invoke tokenFallback() method
  function transferToContract(
    address to,
    uint256 value,
    bytes calldata data
  ) private returns (bool success) {
    _transfer(msg.sender, to, value, data);

    ContractReceiver rx = ContractReceiver(to);
    rx.tokenFallback(msg.sender, value, data);
    return true;
  }

  // ERC223 fetch contract size (must be nonzero to be a contract)
  function isContract(address _addr) private view returns (bool) {
    uint256 length;
    assembly {
      length := extcodesize(_addr)
    }
    return (length > 0);
  }

  function _transfer(
    address from,
    address to,
    uint256 value,
    bytes memory data
  ) internal {
    require(to != address(0x0));
    require(balances_[from] >= value);
    require(balances_[to] + value > balances_[to]); // catch overflow

    balances_[from] -= value;
    balances_[to] += value;

    //Transfer( from, to, value, data ); ERC223-compat version
    bytes memory empty;
    empty = data;
    emit Transfer(from, to, value); // ERC20-compat version
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Config {
  uint256 constant fee_721_mint = 0.2 ether;
  uint256 constant fee_721_burn = 0.3 ether;
  uint256 constant fee_20 = 0.0001 ether;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface tokenRecipient {
    function receiveApproval(
        address from,
        uint256 value,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// ERC223
interface ContractReceiver {
    function tokenFallback(
        address from,
        uint256 value,
        bytes calldata data
    ) external;
}

