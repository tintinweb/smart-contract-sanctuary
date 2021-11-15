// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './base/Token.sol';
import './base/Importable.sol';
import './interfaces/IMobiusToken.sol';
import './interfaces/IIssuer.sol';
import './interfaces/IResolver.sol';

contract MobiusToken is Importable, Token, IMobiusToken {
    bytes32[] private MINTABLE_CONTRACTS = [CONTRACT_REWARD_COLLATERAL, CONTRACT_REWARD_STAKING,CONTRACT_REWARD_TRADING];
    uint256 public MAX_SUPPLY = 1e8;
    uint256 public AIRDROP_LIMIT = 55000000 * (10 ** uint256(decimals()));
    address DEPOSITOR_ROLE;

    modifier onlyResolver() {
        require(msg.sender == address(resolver), 'MobiusToken: caller is not the Resolver');
        _;
    }

    constructor(IResolver _resolver) Importable(_resolver) Token('Mobius Token','MOT',CONTRACT_MOBIUS_TOKEN) {
        imports = [
            CONTRACT_REWARD_COLLATERAL,
            CONTRACT_REWARD_STAKING,
            CONTRACT_REWARD_TRADING
        ];
    }

    function setDepositor(address addr) external onlyOwner {
        DEPOSITOR_ROLE = addr;
    }

    function mint(address account, uint256 amount) external override containAddress(MINTABLE_CONTRACTS) returns (bool) {
        require(totalSupply() + amount <= MAX_SUPPLY * (10 ** uint256(decimals())),'can not mint more');
        _mint(account, amount);
        return true;
    }

    function migrate(address from, address to) external override onlyResolver returns (bool) {
        uint256 amount = balanceOf(from);
        if (amount == 0) return true;
        _transfer(from, to, amount);
        return true;
    }
    
    function airdrop(address to,uint256 amount) external onlyOwner returns (bool) {
        require(AIRDROP_LIMIT  >= amount, 'can not airdrop more');
        AIRDROP_LIMIT = AIRDROP_LIMIT - amount;
        _mint(to, amount);
        return true;
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == DEPOSITOR_ROLE, "caller is not DEPOSITOR_ROLE");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './Ownable.sol';
import '../interfaces/IResolver.sol';
import '../lib/Strings.sol';

contract Importable is Ownable {
    using Strings for string;

    IResolver public resolver;
    bytes32[] internal imports;

    mapping(bytes32 => address) private _cache;

    constructor(IResolver _resolver) {
        resolver = _resolver;
    }

    modifier onlyAddress(bytes32 name) {
        require(msg.sender == _cache[name], contractName.concat(': caller is not the ', name));
        _;
    }

    modifier containAddress(bytes32[] memory names) {
        require(names.length < 20, contractName.concat(': cannot have more than 20 items'));

        bool contain = false;
        for (uint256 i = 0; i < names.length; i++) {
            if (msg.sender == _cache[names[i]]) {
                contain = true;
                break;
            }
        }
        require(contain, contractName.concat(': caller is not in contains'));
        _;
    }

    modifier containAddressOrOwner(bytes32[] memory names) {
        require(names.length < 20, contractName.concat(': cannot have more than 20 items'));

        bool contain = false;
        for (uint256 i = 0; i < names.length; i++) {
            if (msg.sender == _cache[names[i]]) {
                contain = true;
                break;
            }
        }
        if (!contain) contain = (msg.sender == owner);
        require(contain, contractName.concat(': caller is not in dependencies'));
        _;
    }

    function refreshCache() external onlyOwner {
        for (uint256 i = 0; i < imports.length; i++) {
            bytes32 item = imports[i];
            _cache[item] = resolver.getAddress(item);
        }
    }

    function getImports() external view returns (bytes32[] memory) {
        return imports;
    }

    function requireAsset(bytes32 assetType, bytes32 assetName) internal view returns (address) {
        (bool exist, address assetAddress) = resolver.getAsset(assetType, assetName);
        require(exist, contractName.concat(': Missing Asset Token ', assetName));
        return assetAddress;
    }

    function assets(bytes32 assetType) internal view returns (bytes32[] memory) {
        return resolver.getAssets(assetType);
    }

    function addAddress(bytes32 name) external onlyOwner {
        _cache[name] = resolver.getAddress(name);
        imports.push(name);
    }

    function requireAddress(bytes32 name) internal view returns (address) {
        require(_cache[name] != address(0), contractName.concat(': Missing ', name));
        return _cache[name];
    }

    function getAddress(bytes32 name) external view returns (address) {
        return _cache[name];
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

interface IIssuer {
    function issueDebt(
        bytes32 stake,
        address account,
        bytes32 debtType,
        uint256 amountInUSD,
        uint256 amountInSynth
    ) external;

    function issueDebtWithPreviousStake(
        bytes32 stake, 
        address account, 
        bytes32 debtType, 
        uint256 amountInSynth
    ) external;

    function getIssuable(bytes32 stake, address account, bytes32 debtType) external view returns (uint256);

    function burnDebt(
        bytes32 stake,
        address account,
        bytes32 debtType,
        uint256 amount,
        address payer
    ) external returns (uint256);

    function issueSynth(
        bytes32 synth,
        address account,
        uint256 amount
    ) external;

    function burnSynth(
        bytes32 synth,
        address account,
        uint256 amount
    ) external;

    function getDebt(bytes32 stake, address account, bytes32 debtType) external view returns (uint256);
    function getDebtOriginal(bytes32 stake, address account, bytes32 debtType) external view returns (uint256, uint256, uint256);
    function getUsersTotalDebtInSynth(bytes32 synth) external view returns (uint256);

    function getDynamicTotalDebt() external view returns (uint256 platTotalDebt, uint256 usersTotalDebt, uint256 usersTotalDebtOriginal);

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import './IERC20.sol';

interface IMobiusToken is IERC20 {
    function mint(address account, uint256 amount) external returns (bool);
    function migrate(address from, address to) external returns (bool);
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

interface IResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getAsset(bytes32 assetType, bytes32 assetName) external view returns (bool, address);

    function getAssets(bytes32 assetType) external view returns (bytes32[] memory);

    event AssetChanged(bytes32 indexed assetType, bytes32 indexed assetName, address previousValue, address newValue);
    event AddressChanged(bytes32 indexed name, address indexed previousValue, address indexed newValue);
    event MobiusTokenMigrated(bytes32 indexed name, address indexed previousValue, address indexed newValue);
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

