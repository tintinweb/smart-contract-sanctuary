// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./Synth.sol";

// Factory Contract
contract Factory {

    address public immutable POOLS;

    address[] public arraySynths;
    mapping(address => address) private mapToken_Synth;

    event CreateSynth(address indexed token, address indexed pool);

    modifier onlyPOOLS() {
        require(msg.sender == POOLS, "!POOLS");
        _;
    }

    constructor(address _pools) {
        POOLS = _pools;
    }

    //Create a synth asset
    function deploySynth(address token) external onlyPOOLS returns (address synth) {
        require(mapToken_Synth[token] == address(0), "CreateErr");
        synth = address(new Synth(token));
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

    function getSynth(address token) external view returns (address synth){
        return mapToken_Synth[token];
    }
    function isSynth(address token) public view returns (bool _exists){
        return mapToken_Synth[token] != address(0);
    }

    function _addSynth(address _token, address _synth) internal {
        mapToken_Synth[_token] = _synth;
        arraySynths.push(_synth);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iERC677.sol"; 

// Synth Contract
contract Synth is iERC20 {
    address public immutable FACTORY;
    address public immutable TOKEN;

    // Coin Defaults
    string public override name;
    string public override symbol;
    uint8 public constant override decimals = 18;
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
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // iERC20 Transfer function
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // iERC20 Approve, change allowance functions
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]+(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "allowance err");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "sender");
        require(spender != address(0), "spender");
        if (_allowances[owner][spender] < type(uint256).max) { // No need to re-approve if already max
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }

    // iERC20 TransferFrom function
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        // Unlimited approval (saves an SSTORE)
        if (_allowances[sender][msg.sender] < type(uint256).max) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "allowance err");
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }
    //iERC677 approveAndCall
    function approveAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
      _approve(msg.sender, recipient, amount);
      iERC677(recipient).onTokenApproval(address(this), amount, msg.sender, data); // Amount is passed thru to recipient
      return true;
     }

      //iERC677 transferAndCall
    function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
      _transfer(msg.sender, recipient, amount);
      iERC677(recipient).onTokenTransfer(address(this), amount, msg.sender, data); // Amount is passed thru to recipient 
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
        require(_balances[sender] >= amount, "balance err");
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
    function burn(uint256 amount) external virtual override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external virtual override {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "address err");
        require(_balances[account] >= amount, "balance err");
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

    function decimals() external view returns (uint8);

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

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC677 {
 function onTokenApproval(address token, uint amount, address member, bytes calldata data) external;
 function onTokenTransfer(address token, uint amount, address member, bytes calldata data) external;
}

