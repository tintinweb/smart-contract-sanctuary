//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC20/ERC20.sol";
// import "../token/ERC721/ERC721.sol";
// import "../token/ERC2917/ERC2917.sol";
import "../token/ERC20/extensions/ERC20Burnable.sol";
import "../token/ERC20/ERC20Burnable.sol";
import "../token/ERC20/ERC20Cappable.sol";
import "../token/ERC20/ERC20Mintable.sol";
contract FactoryMaster {
    ERC20[] public childrenErc20;
    ERC20Burn[] public childrenErc20Burn;
    // ERC721[] public childrenErc721;
    // ERC2917[] public childrenErc2917;
    ERC20Cappable[] public childrenErc20Cap;
    ERC20Mintable[] public childrenErc20Mint;
    

    uint constant fee_erc20 = 0.3 ether;
    // uint constant fee_erc721 = 0.4 ether;
    // uint constant fee_erc2917 = 0.5 ether;
   
    event ChildCreatedERC20(address childAddress, string name, string symbol);
    // event ChildCreatedERC721(address childAddress, string name, string symbol);
    // event ChildCreated2917(
    //     address childAddress,
    //     string name,
    //     string symbol,
    //     uint256 _interestsRate
    // );
    event ChildCreatedERC20Burnable(address childAddress, string name, string symbol);
    event ChildCreatedERC20Cappable(address childAddress, string name, string symbol);
    event ChildCreatedERC20Mintable(address childAddress, string name, string symbol);

    enum Types {
        none,
        erc20,
        // erc721,
        // erc2917,
        erc20Burn,
        erc20Mintable
    }

    function createChild(Types types,string memory name,string memory symbol,uint256 _interestsRate) external payable {

        require(types != Types.none, "you must enter the word 1");
        require(keccak256(abi.encodePacked((name))) !=keccak256(abi.encodePacked((""))),"requireed value");
        require(keccak256(abi.encodePacked((symbol))) !=keccak256(abi.encodePacked((""))),"requireed value");

        if (types == Types.erc20) {

            require(msg.value>=fee_erc20,"ERC20:value must be greater than 0.2");

            ERC20 child = new ERC20(name, symbol);
            childrenErc20.push(child);
            emit ChildCreatedERC20(address(child), name, symbol);
            
        }
        if (types == Types.erc20Burn){
            require(msg.value>=fee_erc20,"ERC20:value must be greater than 0.2");

            ERC20Burn child = new ERC20Burn(name, symbol);
            childrenErc20Burn.push(child);
            emit ChildCreatedERC20Burnable(address(child), name, symbol);
        }

          if (types == Types.erc20Mintable){
            require(msg.value>=fee_erc20,"ERC20:value must be greater than 0.2");

            ERC20Mintable child = new ERC20Mintable(name, symbol);
            childrenErc20Mint.push(child);
            emit ChildCreatedERC20Mintable(address(child), name, symbol);
        }

        


        // if (types == Types.erc721) {
            
        //     require(msg.value>=fee_erc721,"ERC721:value must be greater than 0.3");

        //     ERC721 child = new ERC721(name, symbol);
        //     childrenErc721.push(child);
        //     emit ChildCreatedERC721(address(child), name, symbol);
        // }
        // if (types == Types.erc2917) {

        //     require(_interestsRate >= 0, "value must be greater than 0");
        //     require(msg.value>=fee_erc2917,"ERC2917:value must be greater than 0.4");

        //     ERC2917 child = new ERC2917(name, symbol, _interestsRate);
        //     childrenErc2917.push(child);
        //     emit ChildCreated2917(address(child), name, symbol, _interestsRate);
        // }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../../libraries/Context.sol";
import "../../libraries/SafeMath.sol";


contract ERC20 is Context, IERC20, IERC20Metadata {

     using SafeMath for uint256;

    mapping(address => uint256)  _balances;
    mapping(address => mapping(address => uint256))   _allowances;

    uint256  _totalSupply=10000;

    string private _name;
    string private _symbol;
    uint8  private _decimals = 18;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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





      function deposit(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdrawal(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] = accountBalance - amount;
        
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../libraries/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */

 
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./extensions/ERC20Burnable.sol";

contract ERC20Burn is ERC20Burnable {
    

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
    {
   
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./extensions/ERC20Burnable.sol";
import "./ERC20.sol";


contract ERC20Cappable is  ERC20{
     uint256 private _cap;
     constructor(uint256 cap_) ERC20("MinhToken", "MTK") {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }
    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./extensions/ERC20Burnable.sol";
import "./ERC20.sol";


contract ERC20Mintable is  ERC20{
     constructor(string memory name, string memory symbol) ERC20(name,symbol) {
       
    }
     function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    //erc2917 and erc20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

{
  "optimizer": {
    "enabled": true,
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