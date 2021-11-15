// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "../token/ERC20/ERC20Burnable.sol";
// import "../token/ERC20/ERC20Mintable.sol";
// import "../token/ERC20/ERC20MintableBurnable.sol";
// import "../token/ERC20/ERC20FixedSupply.sol";

// contract FactoryMasterERC20 {
//   ERC20FixedSupply[] private childrenErc20;
//   ERC20Burnable[] private childrenErc20Burn;
//   ERC20Mintable[] private childrenErc20Mint;
//   ERC20MintableBurnable[] private childrenErc20MintBurn;

//   // uint256 constant fee_erc20 = 0.00001 ether;
//   // address masterContract;
//   // event ChildCreatedERC20(
//   //   address childAddress,
//   //   address _owner,
//   //   string name,
//   //   string symbol,
//   //   uint8 decimal,
//   //   uint256 initialSuplly
//   // );

//   // event ChildCreatedERC20Burnable(
//   //   address childAddress,
//   //   address _owner,
//   //   string name,
//   //   string symbol,
//   //   uint8 decimal,
//   //   uint256 initialSuplly
//   // );
//   // event ChildCreatedERC20Mintable(
//   //   address childAddress,
//   //   address _owner,
//   //   uint256 cap_,
//   //   string name,
//   //   string symbol,
//   //   uint8 decimal,
//   //   uint256 initialSupply
//   // );
//   // event ChildCreatedERC20MintableBurnable(
//   //   address childAddress,
//   //   address _owner,
//   //   uint256 cap_,
//   //   string name,
//   //   string symbol,
//   //   uint8 decimal,
//   //   uint256 initialSupply
//   // );

//   enum Types {
//     none,
//     erc20,
//     erc20Burn,
//     erc20Mintable,
//     erc20MintableBurnable
//   }

//   function createChild(
//     Types types,
//     uint256 cap_,
//     string memory name,
//     uint8 decimal,
//     string memory symbol,
//     uint256 initialSupply
//   ) external  {
//     require(
//       keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked(("")))
//     );
//     require(
//       keccak256(abi.encodePacked((symbol))) != keccak256(abi.encodePacked(("")))
//     );

//     if (types == Types.erc20) {
//       //require(msg.value >= fee_erc20, "ERC20:value must be greater than 0.2");

//       ERC20FixedSupply child = new ERC20FixedSupply(
//         msg.sender,
//         name,
//         symbol,
//         decimal,
//         initialSupply
//       );
//       childrenErc20.push(child);
//       // emit ChildCreatedERC20(
//       //   address(child),
//       //   msg.sender,
//       //   name,
//       //   symbol,
//       //   decimal,
//       //   initialSupply
//       // );
//     }
//     if (types == Types.erc20Burn) {
//       //require(msg.value >= fee_erc20, "ERC20:value must be greater than 0.2");

//       ERC20Burnable child = new ERC20Burnable(
//         msg.sender,
//         name,
//         symbol,
//         decimal,
//         initialSupply
//       );
//       childrenErc20Burn.push(child);
//       // emit ChildCreatedERC20Burnable(
//       //   address(child),
//       //   msg.sender,
//       //   name,
//       //   symbol,
//       //   decimal,
//       //   initialSupply
//       // );
//     }

//     if (types == Types.erc20Mintable) {
//       //require(msg.value >= fee_erc20, "ERC20:value must be greater than 0.2");

//       ERC20Mintable child = new ERC20Mintable(
//         msg.sender,
//         cap_,
//         name,
//         symbol,
//         decimal,
//         initialSupply
//       );
//       childrenErc20Mint.push(child);
//       // emit ChildCreatedERC20Mintable(
//       //   address(child),
//       //   msg.sender,
//       //   cap_,
//       //   name,
//       //   symbol,
//       //   decimal,
//       //   initialSupply
//       // );
//     }

//     if (types == Types.erc20MintableBurnable) {
//       //require(msg.value >= fee_erc20, "ERC20:value must be greater than 0.2");

//       ERC20MintableBurnable child = new ERC20MintableBurnable(
//         msg.sender,
//         cap_,
//         name,
//         symbol,
//         decimal,
//         initialSupply
//       );
//       childrenErc20MintBurn.push(child);
//       // emit ChildCreatedERC20MintableBurnable(
//       //   address(child),
//       //   msg.sender,
//       //   cap_,
//       //   name,
//       //   symbol,
//       //   decimal,
//       //   initialSupply
//       // );
//     }
//   }

//   // function setMasterContract(address _masterContract) external {
//   //   masterContract = _masterContract;
//   // }

//   function getLatestChildrenErc20() external view returns (address) {
//     if (childrenErc20.length > 0) {
//       return address(childrenErc20[childrenErc20.length - 1]);
//     }
//     return address(childrenErc20[0]);
//   }

//   function getLatestChildrenErc20Burnable() external view returns (address) {
//     if (childrenErc20Burn.length > 0) {
//       return address(childrenErc20Burn[childrenErc20Burn.length - 1]);
//     }
//     return address(childrenErc20Burn[0]);
//   }

//   function getLatestChildrenErc20Mintable() external view returns (address) {
//     if (childrenErc20Mint.length > 0) {
//       return address(childrenErc20Mint[childrenErc20Mint.length - 1]);
//     }
//     return address(childrenErc20Mint[0]);
//   }

//   function getLatestChildrenErc20MintableBurnable()
//     external
//     view
//     returns (address)
//   {
//     if (childrenErc20MintBurn.length > 0) {
//       return address(childrenErc20MintBurn[childrenErc20MintBurn.length - 1]);
//     }
//     return address(childrenErc20MintBurn[0]);
//   }
// }

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Mintable.sol";
import "../token/ERC20/ERC20MintableBurnable.sol";
import "../token/ERC20/ERC20FixedSupply.sol";


contract FactoryMasterERC20 {
  ERC20FixedSupply[] private childrenErc20;
  ERC20Mintable[] private childrenErc20Mintable;
  ERC20Burnable[] private childrenErc20Burnable;
  ERC20MintableBurnable[] private childrenErc20MintableBurnable;


  enum Types {
    none,
    erc20,
    erc20Mintable,
    erc20Burnable,
    erc20MintableBurnable
  }

  function createERC20Types(
    Types types,
    string memory name,
    string memory symbol,
    uint256 initialSupply,
    uint256 cap,
    uint8 decimal
  ) external {
    require(
      keccak256(abi.encodePacked((name))) != keccak256(abi.encodePacked(("")))
    );
    require(
      keccak256(abi.encodePacked((symbol))) != keccak256(abi.encodePacked(("")))
    );
    if (types == Types.erc20) {
      ERC20FixedSupply child = new ERC20FixedSupply(
        msg.sender,
        name,
        symbol,
        decimal,
        initialSupply
      );
      childrenErc20.push(child);
    }

    if (types == Types.erc20Mintable) {
      ERC20Mintable child = new ERC20Mintable(
        msg.sender,
        cap,
        name,
        symbol,
        decimal,
        initialSupply
      );
      childrenErc20Mintable.push(child);
    }

    if (types == Types.erc20Burnable) {
      ERC20Burnable child = new ERC20Burnable(
        msg.sender,
        name,
        symbol,
        decimal,
        initialSupply
      );
      childrenErc20Burnable.push(child);
    }

      if (types == Types.erc20MintableBurnable) {
      ERC20MintableBurnable child = new ERC20MintableBurnable(
        msg.sender,
        cap,
        name,
        symbol,
        decimal,
        initialSupply
      );
      childrenErc20MintableBurnable.push(child);
    }
  }

  function getLatestChildrenErc20() external view returns (address) {
    if (childrenErc20.length > 0) {
      return address(childrenErc20[childrenErc20.length - 1]);
    }
    return address(childrenErc20[0]);
  }

  function getLatestChildrenErc20Mintable() external view returns (address) {
    if (childrenErc20Mintable.length > 0) {
      return address(childrenErc20Mintable[childrenErc20Mintable.length - 1]);
    }
    return address(childrenErc20Mintable[0]);
  }

 
  function getLatestChildrenErc20Burnable() external view returns (address) {
    if (childrenErc20Burnable.length > 0) {
      return address(childrenErc20Burnable[childrenErc20Burnable.length - 1]);
    }
    return address(childrenErc20Burnable[0]);
  }

  function getLatestChildrenErc20MintableBurnable()
    external
    view
    returns (address)
  {
    if (childrenErc20MintableBurnable.length > 0) {
      return address(childrenErc20MintableBurnable[childrenErc20MintableBurnable.length - 1]);
    }
    return address(childrenErc20MintableBurnable[0]);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//import "./extensions/ERC20Burnable.sol";
import "./ERC20Ownable.sol";
import "./ERC20.sol";

contract ERC20Burnable is ERC20 {
  //mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor(
    address _owner,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol, decimal) {
    _mint(_owner, initialSupply);
    _totalSupply = initialSupply * 10**uint8(decimal);
    _balances[_owner] = _totalSupply;
    emit Transfer(address(0), _owner, _totalSupply);
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//import "./extensions/ERC20Burnable.sol";
import "./ERC20.sol";
import "./ERC20Ownable.sol";

contract ERC20Mintable is ERC20 {
  string private _name;
  string private _symbol;
  uint256 private _cap;

  // mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor(
    address _owner,
    uint256 cap_,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol, decimal) {
    _name = name;
    _symbol = symbol;
    _cap = cap_ * 10 ** uint8(decimal);
    _mint(_owner, initialSupply);
    _totalSupply = initialSupply * 10**uint8(decimal);
    _balances[_owner] = _totalSupply;
    emit Transfer(address(0), _owner, _totalSupply);
  }

  function mint(address recipient, uint256 amount) external {
    _mint(recipient, amount);
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  function _mint(address account, uint256 amount) internal virtual override {
    require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
    super._mint(account, amount);
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

import "./ERC20Ownable.sol";
//import "./ERC20Mintable.sol";
import "./ERC20.sol";

contract ERC20MintableBurnable is ERC20 {
  //mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) allowed;

  uint256 private _cap;

  constructor(
    address _owner,
    uint256 cap_,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol, decimal) {
    _cap = cap_ * 10**uint8(decimal);
    _mint(_owner, initialSupply);
    _totalSupply = initialSupply * 10**uint8(decimal);
    _balances[_owner] = _totalSupply;
    emit Transfer(address(0), _owner, _totalSupply);
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function mint(address recipient, uint256 amount) external {
    _mint(recipient, amount);
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  function _mint(address account, uint256 amount) internal virtual override {
    require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
    super._mint(account, amount);
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./ERC20Ownable.sol";

contract ERC20FixedSupply is ERC20 {
  //mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor(
    address _owner,
    string memory name,
    string memory symbol,
    uint8 decimal,
    uint256 initialSupply
  ) ERC20(name, symbol, decimal) {
    require(_owner != address(0));
    //owner = _owner;
    _mint(_owner, initialSupply);
    
    _balances[_owner] = _totalSupply;
    
  }

  function balanceOf(address _owner) public view override returns (uint256) {
    return _balances[_owner];
  }

  function allowance(address _owner, address _spender)
    public
    view
    override
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Ownable {
  address public owner;

  // constructor() public{
  //     owner = msg.sender;
  // }

  // modifier onlyOwner {
  //     require(msg.sender == owner);
  //     _;
  // }
  function transferOwnership(address newOwner) public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../../libraries/Context.sol";
import "../../libraries/SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) public _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 public _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimal;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimal_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimal = decimal_;
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimal;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply * 10**uint8(_decimal);
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[sender] = senderBalance - amount;
    }
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  function deposit(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    require(account != address(0), "ERC20: mint to the zero address");

    _balances[account] += amount;
    _totalSupply = _totalSupply.add(amount);

    emit Transfer(address(0), account, amount);
    return true;
  }

  function withdrawal(address account, uint256 amount)
    external
    override
    returns (bool)
  {
    require(account != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

    _balances[account] = accountBalance - amount;

    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);
    return true;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  //erc2917 and erc20
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function deposit(address account, uint256 amount) external returns (bool);

  function withdrawal(address account, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
}

