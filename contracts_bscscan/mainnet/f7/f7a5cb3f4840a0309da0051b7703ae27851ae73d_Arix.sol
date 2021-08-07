/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
interface IBeaconUpgradeable {
    function implementation() external view returns (address);
}
library AddressUpgradeable {
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
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }
    struct BooleanSlot {
        bool value;
    }
    struct Bytes32Slot {
        bytes32 value;
    }
    struct Uint256Slot {
        uint256 value;
    }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }
    function __ERC1967Upgrade_init_unchained() internal initializer {}
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    event Upgraded(address indexed implementation);
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            _upgradeTo(newImplementation);
        }
    }
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    event AdminChanged(address previousAdmin, address newAdmin);
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    event BeaconUpgraded(address indexed beacon);
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }
    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }
    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
library SafeMathUpgradeable {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20Upgradeable {
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
}
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _taxExclusion;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _liquidityAddress;
    address private _taxRewardsAddress;
    uint256 private _taxFee;
    uint256 private _liqFee;
    uint256 private _burnFee;
    
    function _setTaxFee(uint256 taxFee) internal virtual {
        _taxFee = taxFee ;
    }
    function getTaxFee() internal view virtual returns (uint256) {
        return _taxFee;
    }
    function _setLiqFee(uint256 liqFee) internal virtual {
        _liqFee = liqFee ;
    }
    function getLiqFee() internal view virtual returns (uint256) {
        return _liqFee;
    }
    function _setBurnFee(uint256 burnFee) internal virtual {
        _burnFee = burnFee ;
    }
    function getBurnFee() internal view virtual returns (uint256) {
        return _burnFee;
    }
    function _setLiquidityAddress(address liqAddress) internal virtual {
        _liquidityAddress = liqAddress;   
    }
    function _setTaxRewardAddress(address taxAdress) internal virtual {
        _taxRewardsAddress = taxAdress;   
    }
    function getLiquidityAddress() internal view virtual returns (address){
        return _liquidityAddress;
    }
    function getTaxRewardAddress() internal view virtual returns (address){
        return _taxRewardsAddress;
    }
    function _calcBurnAmount(uint256 amount) internal virtual returns (uint256){
        return amount.mul(_burnFee).div(1000);
    }
    function _calcTaxAmount(uint256 amount) internal virtual returns (uint256){
        return amount.mul(_taxFee).div(1000);
    }
    function _calcLiqAmount(uint256 amount) internal virtual returns (uint256){
        return amount.mul(_liqFee).div(1000);
    }
    function _payInterest(address hodlerAddress,uint256 amount) internal virtual returns (bool){
        _balances[_liquidityAddress]-=amount;
        _balances[hodlerAddress]+=amount;
        return true;
    }
    function _reductionExclusion(address hodlerAddress,bool excluded) internal virtual returns (bool) {
        _taxExclusion[hodlerAddress] = excluded;
        return true;
    }
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
        require(currentAllowance >= amount, "Arix: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "Arix: decreased allowance below zero");
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
        require(sender != address(0), "Arix: transfer from the zero address");
        require(recipient != address(0), "Arix: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Arix: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        if(!_taxExclusion[sender]){
            uint256 tax = _calcTaxAmount(amount);
            uint256 liq = _calcLiqAmount(amount);
            uint256 burn = _calcBurnAmount(amount);
            amount = amount.sub(tax+liq+burn);
            _balances[_liquidityAddress]+= liq;
            _balances[_taxRewardsAddress]+= tax;
            if(_totalSupply>= 500000 * 10 ** decimals()){
                _totalSupply -= burn;
            }
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Arix: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Arix: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Arix: burn amount exceeds balance");
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
        require(owner != address(0), "Arix: approve from the zero address");
        require(spender != address(0), "Arix: approve to the zero address");
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
    uint256[45] private __gap;
}
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }
    function __ERC20Burnable_init_unchained() internal initializer {
    }
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "Arix: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}
contract Arix is Initializable, ERC20Upgradeable,ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    struct Stake {
        uint256 id;
        uint256 amount;
        uint256 stakeTime;
        uint256 interestRate;
        bool stateActive;
    }
    mapping (address => mapping (uint256 => Stake)) private STAKES;
    mapping (address => uint256) private _numberOfStakes;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) private _interestPayTimes;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) private _interestPaidTimes;
    address private _ownerAddress;
    uint256 private _basicRate;
    uint256 private _supermeRate;
    uint256 private _performerRate;
    uint256 private _turboRate;
    uint256 private _minimumAmountForStaking;

    function initialize() initializer public {
        __ERC20_init("Arix", "ARIX");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _ownerAddress = msg.sender;
        _setLiquidityAddress(owner());
        _setTaxRewardAddress(0x185A41064f1993Ba1F1c6F95C3A8cd6115Af7b2C);
        _setBurnFee(10);
        _setLiqFee(10);
        _setTaxFee(10);
        _basicRate = 11;
        setBasicRate(11);
        setSupermeRate(18);
        setPerformerRate(25);
        setTurboRate(30);
        setMinimumAmountForStake(20);
        _reductionExclusion(_ownerAddress,true);
        _reductionExclusion(0xCecB8B0e65CCBF9e1497d599d9D73c675948dA32,true);
        _mint(msg.sender, 2500000 * 10 ** decimals());
    }
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
    function renounceOwnership() public override(OwnableUpgradeable) onlyOwner {
        //do nothing
        transferOwnership(owner());
    }
    function setMinimumAmountForStake(uint256 minimumAmount) public virtual onlyOwner returns(bool){
        require(minimumAmount > 0 && minimumAmount < 100 , "ARIX : Minimum should be between 1 to 99");
        _minimumAmountForStaking = minimumAmount;
        return true;
    }
    function minimumAmountForStake() public virtual view returns (uint256){
        return _minimumAmountForStaking;
    }    
    function setBasicRate(uint256 rate) public virtual onlyOwner returns (bool){
        _basicRate = rate;
        return true;
    }
    function setSupermeRate(uint256 rate) public virtual onlyOwner returns (bool){
        _supermeRate = rate;
        return true;
    }
    function setPerformerRate(uint256 rate) public virtual onlyOwner returns (bool){
        _performerRate = rate;
        return true;
    }
    function setTurboRate(uint256 rate) public virtual onlyOwner returns (bool){
        _turboRate = rate;
        return true;
    }
    function BasicRate() public virtual view returns (uint256){
        return _basicRate;
    }
    function SupermeRate() public virtual view returns (uint256){
        return _supermeRate;
    }
    function PerformerRate() public virtual view returns (uint256){
        return _performerRate;
    }
    function TurboRate() public virtual view returns (uint256){
        return _turboRate;
    }
    function setTaxFee(uint256 taxFee) public virtual onlyOwner{
        _setTaxFee(taxFee);
    }
    function TaxFee() public view virtual returns (uint256){
        return getTaxFee();
    }
    function setLiqFee(uint256 liqFee) public virtual onlyOwner{
        _setLiqFee(liqFee);
    }
    function LiquidityFee() public view virtual returns (uint256){
        return getLiqFee();
    }
    function setBurnFee(uint256 burnFee) public virtual onlyOwner{
        _setBurnFee(burnFee);
    }
    function BurnFee() public view virtual returns (uint256){
        return getBurnFee();
    }
    function setLiquidityAddress(address liqAddress) public virtual onlyOwner{
        _setLiquidityAddress(liqAddress);
    }
    function LiquidityAddress() public view virtual returns (address){
        return getLiquidityAddress();
    }
    function setTaxRewardAddress(address taxAddress) public virtual onlyOwner{
        _setTaxRewardAddress(taxAddress);
    }
    function TaxRewardAddress() public view virtual returns (address){
        return getTaxRewardAddress();
    }
    function setReductionExclusion(address hodlerAddress,bool excluded) public virtual onlyOwner{
        _reductionExclusion(hodlerAddress,excluded);
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(balanceOf(_msgSender()).sub(stakeOf(_msgSender())) >= amount,"Arix : cant transfer more than Stake");
        return super.transfer(recipient,amount);
    }
    function stake(uint256 amount) public virtual returns(uint256) {
        address sender = msg.sender;
        require(amount>=(minimumAmountForStake().mul(10**decimals())),"Arix : minimum amount for staking isn't Meet");
        require(balanceOf(sender)!=0,"Arix : stake address balance not enough for staking");
        require(balanceOf(sender).sub(stakeOf(sender)) >= amount,"Arix : cant transfer more than Stake");
        uint256 stakeTime=block.timestamp;
        uint256 nos = _numberOfStakes[sender];
        uint256 stakeId = nos++;
        calculatePayTimes(sender,stakeTime,stakeId);
        uint256 rate = calculateInterestRate(amount);
        Stake memory newStake = Stake(stakeId ,amount,stakeTime,rate,true);
        _setStake(sender,newStake);
        return newStake.amount;
    }
    function stakeFromTime(address stakeAddress,uint256 amount,uint256 time) public virtual onlyOwner returns(uint256) {
        address sender = stakeAddress;
        require(amount>=(minimumAmountForStake().mul(10**decimals())),"Arix: minimum amount for staking isn't Meet");
        require(balanceOf(sender)!=0,"Arix: stake address balance not enough for staking");
        require(balanceOf(sender).sub(stakeOf(sender)) >= amount,"Arix: cant transfer more than Stake");
        uint256 nos = _numberOfStakes[sender];
        uint256 stakeId = nos++;
        calculateAllTimes(sender,time,stakeId);
        uint256 rate = calculateInterestRate(amount);
        Stake memory newStake = Stake(stakeId,amount,time,rate,true);
        _setStake(sender,newStake);
        return newStake.amount;
    }
    function calculateInterestRate(uint256 stakeAmount) internal virtual returns(uint256){
        uint256 rate;
        if(stakeAmount>=(minimumAmountForStake().mul(10**decimals())) && stakeAmount<=(100*10**decimals())){
            rate = 11;
        }else if(stakeAmount>(100*10**decimals()) && stakeAmount<=(200*10**decimals())){
            rate = 18;
        }else if(stakeAmount>(200*10**decimals()) && stakeAmount<=(500*10**decimals())){
            rate = 25;
        }else if(stakeAmount>(500*10**decimals())){
            rate = 30;
        }
        return rate;
    }
    function calculateAllTimes(address stakeAddress,uint256 time,uint256 stakeId) internal virtual {
        uint256 yearseconds = 12 * ((4 weeks)+(1 days));
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime.sub(time);
        uint256 timeRemained = yearseconds.sub(timePassed);
        uint256 remainigMonth = timeRemained.div((4 weeks)+(1 days))+1;
        uint256 passedMonth = timePassed.div((4 weeks)+(1 days));
        for(uint256 i = 1 ; i <= passedMonth ; i++){
            _interestPayTimes[stakeAddress][stakeId][i] = time.add(i.mul((4 weeks)+(1 days)));
        }
        for(uint256 i = 1 ; i <= remainigMonth ; i++){
            _interestPaidTimes[stakeAddress][stakeId][i] = currentTime.add(i.mul((4 weeks)+(1 days)));
        }
    }
    function calculatePayTimes(address stakeAddress,uint256 stakeTime,uint256 stakeId) internal virtual{
        for(uint256 i=1;i<13;i++){
            _interestPayTimes[stakeAddress][stakeId][i] = stakeTime.add(i.mul((4 weeks)+(1 days)));
        }
    }
    function stakeOf(address account) public view virtual returns (uint256) {
        uint256 nos = _numberOfStakes[account];
        uint256 sum = 0;
        for(uint256 i = 1; i<=nos ; i++){
            sum +=STAKES[account][i].amount;
        }
        return sum;
    }
    function _setStake(address stakeAddress,Stake memory stake1) internal virtual returns(bool){
        _numberOfStakes[stakeAddress]++;
        STAKES[stakeAddress][_numberOfStakes[stakeAddress]] = stake1;
        return true;
    }
    function InterestPay(address stakeAddress) public virtual onlyOwner returns (bool){
        require(balanceOf(stakeAddress)!=0,"Arix: address balance not enough for InterestPayment");
        require(stakeOf(stakeAddress)!=0,"Arix: address stake balance not enough for InterestPayment");
        uint256 nos = _numberOfStakes[stakeAddress];
        for(uint256 i = 1 ; i <= nos ; i++){
            uint256 rate = STAKES[stakeAddress][i].interestRate;
            uint256 stakeAmount = STAKES[stakeAddress][i].amount;
            uint256 interestAmount = stakeAmount.mul(rate).div(10**3);
            uint256 currentTime = block.timestamp;
            for(uint256 j = 1 ; j < 13 ; j++ ){
                if(currentTime >= _interestPayTimes[stakeAddress][STAKES[stakeAddress][i].id][j] && _interestPaidTimes[stakeAddress][STAKES[stakeAddress][i].id][j] == 0){
                    _payInterest(stakeAddress,interestAmount);
                    _interestPaidTimes[stakeAddress][STAKES[stakeAddress][i].id][j] = block.timestamp;
                    if(j==12){
                        STAKES[stakeAddress][i].stateActive = false;
                        STAKES[stakeAddress][i].amount = 0;
                    }
                }
            }
        }
        return true;
        
    }
    
}