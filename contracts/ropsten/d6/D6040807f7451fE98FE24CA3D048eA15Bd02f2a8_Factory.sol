// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./Synth.sol";

// Factory Contract
contract Factory {
    bool private inited;
    address public VADER;
    address public USDV;
    address public POOLS;

    address[] public arraySynths;
    mapping(address => address) public getSynth;
    mapping(address => bool) public isSynth;

    event CreateSynth(address indexed token, address indexed pool);

    modifier onlyPOOLS() {
        require(msg.sender == POOLS, "!POOLS");
        _;
    }

    constructor() {}

    function init(address _pool) public {
        require(inited == false);
        inited = true;
        POOLS = _pool;
    }

    //Create a synth asset
    function deploySynth(address token) external onlyPOOLS returns (address synth) {
        require(getSynth[token] == address(0), "CreateErr");
        Synth newSynth;
        newSynth = new Synth(token);
        synth = address(newSynth);
        _addSynth(token, synth);
        emit CreateSynth(token, synth);
    }

    function mintSynth(
        address synth,
        address member,
        uint256 amount
    ) external onlyPOOLS returns (bool) {
        Synth(synth).mint(member, amount);
        return true;
    }

    // function getSynth(address token) public view returns (address synth){
    //     return mapToken_Synth[token];
    // }
    // function isSynth(address token) public view returns (bool _isSynth){
    //     if(_isListedSynth[token] == true){
    //         return true;
    //     }
    // }

    function _addSynth(address _token, address _synth) internal {
        getSynth[_token] = _synth;
        arraySynths.push(_synth);
        isSynth[_synth] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";

// Synth Contract
contract Synth is iERC20 {
    address public FACTORY;
    address public TOKEN;

    // Coin Defaults
    string public override name;
    string public override symbol;
    uint256 public override decimals = 18;
    uint256 public override totalSupply;

    // ERC-20 Mappings
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyFACTORY() {
        require(msg.sender == FACTORY, "!FACTORY");
        _;
    }

    // Minting event
    constructor(address _token) {
        TOKEN = _token;
        FACTORY = msg.sender;
        string memory synthName = " - vSynth";
        string memory synthSymbol = ".v";
        name = string(abi.encodePacked(iERC20(_token).name(), synthName));
        symbol = string(abi.encodePacked(iERC20(_token).symbol(), synthSymbol));
    }

    //========================================iERC20=========================================//
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
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

    // TransferTo function
    // Risks: User can be phished, or tx.origin may be deprecated, optionality should exist in the system.
    function transferTo(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(tx.origin, recipient, amount);
        return true;
    }

    // Internal transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "sender");
        require(recipient != address(this), "recipient");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Only FACTORY can mint
    function mint(address account, uint256 amount) external virtual onlyFACTORY {
        require(account != address(0), "recipient");
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Burn supply
    function burn(uint256 amount) public virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        _balances[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
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

    function transferTo(address, uint256) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

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