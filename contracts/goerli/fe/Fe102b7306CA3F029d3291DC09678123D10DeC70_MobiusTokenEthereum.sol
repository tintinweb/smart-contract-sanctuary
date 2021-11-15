// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

contract Constants {
    bytes32 internal constant MOT = 'MOT';
    bytes32 internal constant USD = 'moUSD';

    bytes32 internal constant CONTRACT_RESOLVER = 'Resolver';
    bytes32 internal constant CONTRACT_ASSET_PRICE = 'AssetPrice';
    bytes32 internal constant CONTRACT_SETTING = 'Setting';

    bytes32 internal constant CONTRACT_MOBIUS = 'Mobius';
    bytes32 internal constant CONTRACT_ESCROW = 'Escrow';
    bytes32 internal constant CONTRACT_ISSUER = 'Issuer';

    bytes32 internal constant CONTRACT_STAKER = 'Staker';
    bytes32 internal constant CONTRACT_TRADER = 'Trader';
    bytes32 internal constant CONTRACT_TEAM = 'Team';

    bytes32 internal constant CONTRACT_MOBIUS_TOKEN = 'MobiusToken';

    bytes32 internal constant CONTRACT_LIQUIDATOR = 'Liquidator';

    bytes32 internal constant CONTRACT_REWARD_COLLATERAL = 'RewardCollateral';
    bytes32 internal constant CONTRACT_REWARD_STAKING = 'RewardStaking';
    bytes32 internal constant CONTRACT_REWARD_TRADING = 'RewardTradings';

    bytes32 internal constant TRADING_FEE_ADDRESS = 'TradingFeeAddress';
    bytes32 internal constant LIQUIDATION_FEE_ADDRESS = 'LiquidationFeeAddress';

    bytes32 internal constant CONTRACT_DYNCMIC_TRADING_FEE = 'DynamicTradingFee';
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './Ownable.sol';
import '../lib/Strings.sol';

contract ExternalStorable is Ownable {
    using Strings for string;
    address private _storage;

    event StorageChanged(address indexed previousValue, address indexed newValue);

    modifier onlyStorageSetup() {
        require(_storage != address(0), contractName.concat(': Storage not set'));
        _;
    }

    function setStorage(address value) public onlyOwner {
        require(value != address(0), "storage is a zero address");
        emit StorageChanged(_storage, value);
        _storage = value;
    }

    function getStorage() public view onlyStorageSetup returns (address) {
        return _storage;
    }
}

pragma solidity =0.8.0;

// SPDX-License-Identifier: MIT
import '../lib/Strings.sol';
import './Constants.sol';
import '../interfaces/IOwnable.sol';

contract Ownable is Constants, IOwnable {
    using Strings for string;

    string public override contractName;
    address public owner;
    address public manager;

    constructor() {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, contractName.concat(': caller is not the owner'));
        _;
    }

    modifier onlyManager(bytes32 managerName) {
        require(msg.sender == manager, contractName.concat(': caller is not the ', managerName));
        _;
    }

    modifier allManager() {
        require(
            msg.sender == manager || msg.sender == owner,
            contractName.concat(': caller is not the manager or the owner')
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        require(_owner != address(0), contractName.concat(': new owner is the zero address'));
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    function setManager(address _manager) public virtual onlyOwner {
        require(_manager != address(0), contractName.concat(': new manager is the zero address'));
        emit ManagerChanged(manager, _manager);
        manager = _manager;
    }

    function setContractName(bytes32 _contractName) internal {
        contractName = string(abi.encodePacked(_contractName));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import '../lib/Strings.sol';
import './ExternalStorable.sol';
import '../interfaces/storages/ITokenStorage.sol';
import '../interfaces/IERC20.sol';

contract Token is ExternalStorable, IERC20 {
    using Strings for string;
    
    bytes32 private constant TOTAL = 'Total';
    bytes32 private constant BALANCE = 'Balance';

    string internal _name;
    string internal _symbol;

    constructor(string memory __name,string memory __symbol,bytes32 contractName) {
        setContractName(contractName);
        _name = __name;
        _symbol = __symbol;
    }

    function Storage() internal view returns (ITokenStorage) {
        return ITokenStorage(getStorage());
    }

    function name() external override view returns (string memory) {
        return _name;
    }

    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function totalSupply() public override view returns (uint256) {
        return Storage().getUint(TOTAL, address(0));
    }

    function balanceOf(address account) public override view returns (uint256) {
        return Storage().getUint(BALANCE, account);
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return Storage().getAllowance(owner, spender);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 delta = Storage().getAllowance(sender, msg.sender) - amount;
        _approve(sender, msg.sender, delta);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        Storage().setAllowance(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        Storage().decrementUint(BALANCE, sender, amount);
        Storage().incrementUint(BALANCE, recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        Storage().incrementUint(BALANCE, account, amount);
        Storage().incrementUint(TOTAL, address(0), amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        Storage().decrementUint(BALANCE, account, amount);
        Storage().decrementUint(TOTAL, address(0), amount);
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function transfer(address recipient, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IOwnable {
    function contractName() external view returns (string memory);

    event OwnerChanged(address indexed previousValue, address indexed newValue);
    event ManagerChanged(address indexed previousValue, address indexed newValue);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface ITokenStorage {
    function setAllowance(
        address key,
        address field,
        uint256 value
    ) external;

    function getAllowance(address key, address field) external view returns (uint256);

    function incrementUint(
        bytes32 key,
        address field,
        uint256 value
    ) external returns (uint256);

    function decrementUint(
        bytes32 key,
        address field,
        uint256 value
    ) external returns (uint256);

    function setUint(
        bytes32 key,
        address field,
        uint256 value
    ) external;

    function getUint(bytes32 key, address field) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

library Strings {
    function toBytes32(string memory a) internal pure returns (bytes32) {
        bytes32 b;
        assembly {
            b := mload(add(a, 32))
        }
        return b;
    }

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function concat(
        string memory a,
        string memory b,
        bytes32 c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import '../base/Token.sol';

contract MobiusTokenEthereum is Token {
    address PREDICATE_ROLE;

    constructor(address addr) Token('Mobius Token','MOT',CONTRACT_MOBIUS_TOKEN) {
        PREDICATE_ROLE = addr;
    }

    function setPredicate(address addr) external onlyOwner {
        PREDICATE_ROLE = addr;
    }

    function mint(address account, uint256 amount) external onlyPredicateRole returns (bool) {
        _mint(account, amount);
        return true;
    }

    modifier onlyPredicateRole() {
        require(msg.sender == PREDICATE_ROLE, "msg.sender not PREDICATE_ROLE");
        _;
    }
}

