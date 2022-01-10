// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";

contract ExampleToken is ERC20 {
    constructor () 
        ERC20(
            "Example", 
            "EXMPL", 
            1000000, 
            18, 
            5,
            0x1fa4f0dC6269C3D30d5b7F71810f70bE255422E5
        ) {}
    
    function _transfer(address _from, address _to, uint256 _amount) internal override isFrozen isPaused {
        require(_from != address(0), "You can't transfer from the zero address");
        require(_to != address(0), "You can't transfer to the zero address");
        require(_balances[_from] >= _amount, "Not enough tokens on balance");
        uint256 feeFromTransfer = _amount * _fee / 100; 
        _balances[_from] -= _amount;
        _balances[_treasury] += feeFromTransfer;
        _balances[_to] += _amount - feeFromTransfer;

        emit Transfer(_from, _to, _amount);
        emit TreasuryFee(_from, feeFromTransfer);
    }

    function getTreasuryAddress() public view returns(address) {
        return _treasury;
    }

    function balanceOfTreasury() public view returns(uint256) {
        return _balances[_treasury];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./helpers/Owned.sol";
import "./helpers/Freezing.sol";
import "./helpers/Pausable.sol";

contract ERC20 is IERC20, IERC20Metadata, Owned, Freezing, Pausable {
    /*Keeps track of accounts balances*/
    mapping(address => uint256) public _balances;
    mapping(address =>mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply;
    uint256 public _fee;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public count = 1;
    address public _treasury;
    
    event TreasuryFee(address indexed from, uint256 amount);
    /*  TS = 1,000,000;
        decimals = 18;
        Final number = 1,000,000 * 10**18;
    */
    constructor (
        string memory name, 
        string memory symbol, 
        uint256 supply, 
        uint8 decimals, 
        uint256 fee, 
        address treasury
        ) 
    {
        _decimals = decimals;
        _name = name;
        _symbol = symbol;
        _fee = fee;
        _treasury = treasury;
        _mint(msg.sender, supply*10**decimals);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view virtual override returns(uint256) {
        return _totalSupply;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _account) public view virtual override returns (uint256) {
        return _balances[_account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    //This function mints fixed total supply and can be called only one time by constructor.
    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "Can't mint tokens to 0 address");
        require(count != 0, "Total supply already minted");
        count--;
        _totalSupply += _amount;
        _balances[_to] = _amount;
    }

    function transfer(address _to, uint256 _amount) public virtual override returns(bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, msg.sender, currentAllowance - _amount);
        }
        _transfer(_sender, _recipient, _amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
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

    /* With this function x% of all trades goes to Treasury Contract;
    For example:
    _fee = 5%;
    Alice sends 100 TOKENS to Bob
    after all requires passed, function calculates fee from sended amount;
    In our case it would be 5 tokens, so then balance of ALice decreases to 100
    and balance of Bob and Treasury increases by 95 and 5 respectively;
    */
    function _transfer(address _from, address _to, uint256 _amount) internal virtual isFrozen isPaused {
        require(_from != address(0), "You can't transfer from the zero address");
        require(_to != address(0), "You can't transfer to the zero address");
        require(_balances[_from] >= _amount, "Not enough tokens on balance");
        uint256 feeFromTransfer = _amount * _fee / 100; 
        _balances[_from] -= _amount;
        _balances[_to] += _amount - feeFromTransfer;

        emit Transfer(_from, _to, _amount);
        emit TreasuryFee(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns(uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public _owner;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Access denied");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";

contract Freezing is Owned{
    mapping (address => bool) public frozenAccounts;
    
    event FreezeAccount(address indexed account, bool frozen);

    modifier isFrozen {
        require(!frozenAccounts[msg.sender], "Your account is currently frozen!");
        _;
    }

    //Function to freeze an account for some reasons;
    function freezeAccount(address _account) public onlyOwner {
        frozenAccounts[_account] = true;
        emit FreezeAccount(_account, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";

contract Pausable is Owned {
    bool private _paused;

    constructor () {
        _paused = false;
    }

    modifier isPaused {
        require(_paused == false, "Token transfers is paused");
        _;
    }

    function pause() external onlyOwner {
        _paused = true;
    }

    function unpause() external onlyOwner {
        _paused = false;
    }
}