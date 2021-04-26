// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iVETHER.sol";

// Token Contract
contract Vether is iVETHER {
    // Coin Defaults
    string public override name; // Name of Coin
    string public override symbol; // Symbol of Coin
    uint256 public override decimals = 18; // Decimals
    uint256 public override totalSupply = 1 * 10**6 * (10**decimals); // 1,000,000 Total

    uint256 public totalFees;
    mapping(address => bool) public mapAddress_Excluded;

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Minting event
    constructor() {
        name = "Vether";
        symbol = "VETH";
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // iERC20 Transfer function
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // iERC20 Approve, change allowance functions
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "iERC20: approve from the zero address");
        require(spender != address(0), "iERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    // Internal transfer function which includes the Fee
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) private {
        require(_balances[_from] >= _value, "Must not send more than balance");
        require(_balances[_to] + _value >= _balances[_to], "Balance overflow");
        _balances[_from] -= _value;
        uint256 _fee = _getFee(_from, _to, _value); // Get fee amount
        _balances[_to] += (_value - _fee); // Add to receiver
        _balances[address(this)] += _fee; // Add fee to self
        totalFees += _fee; // Track fees collected
        emit Transfer(_from, _to, (_value - _fee)); // Transfer event
        if (!mapAddress_Excluded[_from] && !mapAddress_Excluded[_to]) {
            emit Transfer(_from, address(this), _fee); // Fee Transfer event
        }
    }

    // Calculate Fee amount
    function _getFee(
        address _from,
        address _to,
        uint256 _value
    ) private view returns (uint256) {
        if (mapAddress_Excluded[_from] || mapAddress_Excluded[_to]) {
            return 0; // No fee if excluded
        } else {
            return (_value / 1000); // Fee amount = 0.1%
        }
    }

    function addExcluded(address excluded) public {
        mapAddress_Excluded[excluded] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVETHER {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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