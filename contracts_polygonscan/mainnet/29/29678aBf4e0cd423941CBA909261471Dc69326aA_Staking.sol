/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface IERC20_LP {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract Staking is Ownable {
    enum DepositTypes { ETNA_TOKEN, ERC20_TOKEN, LP_TOKEN }

    struct DepositProfile {
        address contractAddress;
        uint8 depositType;
        uint16 apr; // apr (% * 100, 2501 means 25.01%)
        uint16 tax; // tax (% * 100, 2501 means 25.01%),
        // for depositType LP_TOKEN tax will be applied before lockTime end
        // when unStake instead of reverting
        uint256 rate; // rate in ETNA * 100
        uint256 weight; // sorting order at UI (asc from left to right)
        uint256 marketIndex; // market index to treat possible rate changes
        uint256 marketIndexLastTime; // timestamp when market index was changed last time
        uint256 tvl;  // total amount of tokens deposited in a pool
        uint256 lockTime; // lock period for erc20 or taxed withdraw period for LP tokens in seconds
        string name;
        string currency;
        string link;
        bool etnaYield;
        bool active;
    }

    mapping (uint256 => DepositProfile) _depositProfiles;

    struct Deposit {
        address userAddress;
        uint256 depositProfileId;
        uint256 amount;
        uint256 unlock;
        uint256 lastMarketIndex;
        uint256 updatedAt; // timestamp, is resettled to block.timestamp when changed
        uint256 accumulatedYield; // used to store reward when changed
    }
    mapping (uint256 => Deposit) _deposits;
    mapping (address => mapping(uint256 => uint256)) _usersDepositIndexes;

    uint256 _depositProfilesNumber;
    uint256 _depositsNumber;
    uint256 _year = 365 * 24 * 3600;
    uint256 _shift = 1 ether; // used for exponent shifting when calculation with decimals
    uint256 _withdrawTaxAmount; // aggregated sum
    IERC20 _etnaContract;
    mapping (address => uint256) _totalDeposit;
    bool _safeMode;

    constructor (
        address etnaAddress,
        address newOwner
    ) {
        require(etnaAddress != address(0), 'Token address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');

        _etnaContract = IERC20(etnaAddress);
        transferOwnership(newOwner);
    }

    function stake (uint256 amount, uint256 depositProfileId) external returns (bool) {
        require(_depositProfiles[depositProfileId].active, 'This deposit profile is disabled');
        require(amount > 0, 'Amount should be greater than zero');
        IERC20 depositTokenContract = IERC20(_depositProfiles[depositProfileId].contractAddress);
        depositTokenContract.transferFrom(msg.sender, address(this), amount);
        uint256 depositIndex = _usersDepositIndexes[msg.sender][depositProfileId];
        if (depositIndex > 0) {
            _updateYield(depositIndex);
            _deposits[depositIndex].amount += amount;
            _deposits[depositIndex].unlock = _depositProfiles[depositProfileId].lockTime
                + block.timestamp;
        } else {
            _depositsNumber ++;
            depositIndex = _depositsNumber;
            _deposits[depositIndex] = Deposit({
                userAddress: msg.sender,
                depositProfileId: depositProfileId,
                amount: amount,
                unlock: _depositProfiles[depositProfileId].lockTime + block.timestamp,
                lastMarketIndex: _depositProfiles[depositProfileId].marketIndex,
                updatedAt: block.timestamp,
                accumulatedYield: 0
            });
            _usersDepositIndexes[msg.sender][depositProfileId] = depositIndex;
        }
        _depositProfiles[depositProfileId].tvl += amount;
        _totalDeposit[_depositProfiles[depositProfileId].contractAddress] += amount;

        return true;
    }

    function unStake (uint256 amount, uint256 depositProfileId) external returns (bool) {
        require(_depositProfiles[depositProfileId].active, 'This deposit profile is disabled');
        require(amount > 0, 'Amount should be greater than zero');
        uint256 depositIndex = _usersDepositIndexes[msg.sender][depositProfileId];
        require(depositIndex > 0, 'Deposit is not found');
        if (_depositProfiles[depositProfileId].depositType == uint8(DepositTypes.ETNA_TOKEN)
            || _depositProfiles[depositProfileId].depositType == uint8(DepositTypes.ERC20_TOKEN)) {
            require(block.timestamp >= _deposits[depositIndex].unlock, 'Deposit is locked');
        }
        _updateYield(depositIndex);
        require(_deposits[depositIndex].amount >= amount, 'Not enough amount at deposit');
        _deposits[depositIndex].amount -= amount;
        _depositProfiles[depositProfileId].tvl -= amount;
        _totalDeposit[_depositProfiles[depositProfileId].contractAddress] -= amount;
        IERC20 depositTokenContract = IERC20(_depositProfiles[depositProfileId].contractAddress);

        depositTokenContract.transfer(msg.sender, amount);

        return true;
    }

    function reStake (uint256 depositProfileId) external returns (bool) {
        uint256 depositIndex = _usersDepositIndexes[msg.sender][depositProfileId];
        require(depositIndex > 0, 'Deposit is not found');
        require(_depositProfiles[depositProfileId].depositType
            == uint8(DepositTypes.ETNA_TOKEN), 'Available for ETNA deposits only');
        require(_depositProfiles[depositProfileId].active, 'This deposit profile is disabled');
        _updateYield(depositIndex);
        uint256 yield = _deposits[depositIndex].accumulatedYield;
        _deposits[depositIndex].accumulatedYield = 0;
        _deposits[depositIndex].amount += yield;
        _depositProfiles[depositProfileId].tvl += yield;
        _totalDeposit[_depositProfiles[depositProfileId].contractAddress] += yield;

        return true;
    }

    function withdrawYield (uint256 amount, uint256 depositProfileId) external returns (bool) {
        uint256 depositIndex = _usersDepositIndexes[msg.sender][depositProfileId];
        require(depositIndex > 0, 'Deposit is not found');
        require(_depositProfiles[depositProfileId].active, 'This deposit profile is disabled');
        require(amount > 0, 'Amount should be greater than zero');
        _updateYield(depositIndex);
        require(_deposits[depositIndex].accumulatedYield >= amount, 'Not enough yield at deposit');
        uint256 taxAmount;
        IERC20 tokenContract = _etnaContract;
        if (_depositProfiles[depositProfileId].depositType
            == uint8(DepositTypes.ERC20_TOKEN)
            && !_depositProfiles[depositProfileId].etnaYield) {
            tokenContract = IERC20(_depositProfiles[depositProfileId].contractAddress);
        } else if (_depositProfiles[depositProfileId].depositType == uint8(DepositTypes.LP_TOKEN)
            && block.timestamp < _deposits[depositIndex].unlock) {
            taxAmount = amount * _depositProfiles[depositProfileId].tax / 10000;
        }
        _deposits[depositIndex].accumulatedYield -= amount;
        uint256 balance = tokenContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        if (_safeMode) {
            require(balance - amount >= _totalDeposit[address(tokenContract)],
                'Not enough contract balance (safe mode)');
        }
        amount -= taxAmount;
        _withdrawTaxAmount += taxAmount;
        tokenContract.transfer(msg.sender, amount);

        return true;
    }

    // admin functions
    function adminAddDepositProfile (
        address contractAddress,
        uint8 depositType,
        uint16 apr,
        uint16 tax,
        uint256 rate,
        uint256 weight,
        uint256 lockTime,
        string calldata name,
        bool etnaYield,
        bool active
    ) external onlyOwner returns (bool) {
        require(depositType >= 0 && depositType <= uint8(DepositTypes.LP_TOKEN), 'Unknown type');
        require(tax <= 9999, 'Not valid withdraw tax');

        _depositProfilesNumber ++;

        if (depositType == uint8(DepositTypes.ETNA_TOKEN)) {
            contractAddress = address(_etnaContract);
            rate = 0;
            tax = 0;
            etnaYield = true;
        } else if (depositType == uint8(DepositTypes.ERC20_TOKEN)) {
            require(rate > 0, 'For ERC20 token rate should be greater than zero');
            tax = 0;
            if (!etnaYield) rate = 100;
        } else if (depositType == uint8(DepositTypes.LP_TOKEN)) {
            rate = 0;
            etnaYield = true;
        }
        IERC20 token = IERC20(contractAddress);
        require(token.decimals() == 18, 'Only for tokens with decimals 18');
        _depositProfiles[_depositProfilesNumber] = DepositProfile({
            contractAddress: contractAddress,
            depositType: depositType,
            apr: apr,
            tax: tax,
            rate: rate,
            weight: weight,
            marketIndex: 1 * _shift,
            marketIndexLastTime: block.timestamp,
            tvl: 0,
            lockTime: lockTime,
            name: name,
            currency: 'ETNA',
            link: '',
            etnaYield: etnaYield,
            active: active
        });
        return true;
    }

    function adminSetDepositApr (
        uint256 depositProfileId,
        uint16 apr
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        uint256 period = block.timestamp - _depositProfiles[depositProfileId].marketIndexLastTime;
        uint256 marketFactor = _shift +
        _shift * _depositProfiles[depositProfileId].apr * period / 10000 / _year;
        _depositProfiles[depositProfileId].marketIndex =
            _depositProfiles[depositProfileId].marketIndex * marketFactor / _shift;
        _depositProfiles[depositProfileId].apr = apr;
        _depositProfiles[depositProfileId].marketIndexLastTime = block.timestamp;

        return true;
    }

    function adminSetDepositTax (
        uint256 depositProfileId,
        uint16 tax
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        require(_depositProfiles[depositProfileId].depositType
            == uint8(DepositTypes.LP_TOKEN), 'Tax can be set for LP tokens only');
        _depositProfiles[depositProfileId].tax = tax;

        return true;
    }

    function adminSetDepositRate (
        uint256 depositProfileId,
        uint256 rate
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        require(_depositProfiles[depositProfileId].depositType
            == uint8(DepositTypes.ERC20_TOKEN), 'Rate can be set for ERC20 tokens only');
        require(rate > 0, 'For ERC20 token rate should be greater than zero');
        _depositProfiles[depositProfileId].rate = rate;

        return true;
    }

    function adminSetDepositWeight (
        uint256 depositProfileId,
        uint256 weight
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].weight = weight;

        return true;
    }

    function adminSetDepositLockTime (
        uint256 depositProfileId,
        uint256 lockTime
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].lockTime = lockTime;

        return true;
    }

    function adminSetDepositName (
        uint256 depositProfileId,
        string calldata name
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].name = name;

        return true;
    }

    function adminSetDepositCurrency (
        uint256 depositProfileId,
        string calldata currency
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].currency = currency;

        return true;
    }

    function adminSetDepositLink (
        uint256 depositProfileId,
        string calldata link
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].link = link;

        return true;
    }

    function adminSetDepositStatus (
        uint256 depositProfileId,
        bool active
    ) external onlyOwner returns (bool) {
        require(depositProfileId > 0 && depositProfileId <= _depositProfilesNumber,
            'Deposit profile is not found');
        _depositProfiles[depositProfileId].active = active;

        return true;
    }

    function adminWithdrawToken (uint256 amount, address tokenAddress) external onlyOwner
        returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        if (_safeMode) {
            require(balance - amount >= _totalDeposit[tokenAddress],
                'Not enough contract balance (safe mode)');
        }
        tokenContract.transfer(msg.sender, amount);
        return true;
    }

    function adminWithdrawEtna (uint256 amount) external onlyOwner
        returns (bool) {
        uint256 balance = _etnaContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        if (_safeMode) {
            require(balance - amount >= _totalDeposit[address(_etnaContract)],
                'Not enough contract balance (safe mode)');
        }
        _etnaContract.transfer(msg.sender, amount);
        return true;
    }

    function adminSetEtnaContract (address tokenAddress) external onlyOwner returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _etnaContract = IERC20(tokenAddress);
        return true;
    }

    function adminSetSafeMode (bool safeMode) external onlyOwner returns (bool) {
        _safeMode = safeMode;

        return true;
    }

    // internal functions
    function _updateYield (uint256 depositIndex) internal returns (bool) {
        uint256 yield = calculateYield(depositIndex);
        _deposits[depositIndex].accumulatedYield += yield;
        _deposits[depositIndex].updatedAt = block.timestamp;
        _deposits[depositIndex].lastMarketIndex =
            _depositProfiles[_deposits[depositIndex].depositProfileId].marketIndex;

        return true;
    }

    // view functions
    function getDepositProfile (uint256 depositProfileIndex) external view
    returns (address, uint8, uint16, uint16, uint256, uint256, bool) {
        return (
            _depositProfiles[depositProfileIndex].contractAddress,
            _depositProfiles[depositProfileIndex].depositType,
            _depositProfiles[depositProfileIndex].apr,
            _depositProfiles[depositProfileIndex].tax,
            _depositProfiles[depositProfileIndex].tvl,
            _depositProfiles[depositProfileIndex].lockTime,
            _depositProfiles[depositProfileIndex].active
        );
    }

    // view functions
    function getDepositProfileExtra (uint256 depositProfileIndex) external view
    returns (uint256, string memory, string memory, bool, string memory) {
        return (
            _depositProfiles[depositProfileIndex].weight,
            _depositProfiles[depositProfileIndex].name,
            _depositProfiles[depositProfileIndex].currency,
            _depositProfiles[depositProfileIndex].etnaYield,
            _depositProfiles[depositProfileIndex].link
        );
    }

    function getDepositProfileRate (uint256 depositProfileIndex) public view
    returns (uint256) {
        if (depositProfileIndex == 0 || depositProfileIndex > _depositProfilesNumber) {
            return 0;
        }
        if (_depositProfiles[depositProfileIndex].depositType
            == uint8(DepositTypes.ETNA_TOKEN)) {
            return 100;
        }
        if (_depositProfiles[depositProfileIndex].depositType
            == uint8(DepositTypes.ERC20_TOKEN)) {
            return _depositProfiles[depositProfileIndex].rate;
        }
        if (_depositProfiles[depositProfileIndex].depositType
            == uint8(DepositTypes.LP_TOKEN)) {
            IERC20_LP lpToken = IERC20_LP(_depositProfiles[depositProfileIndex].contractAddress);
            (uint112 ETNA_Total,,) = lpToken.getReserves();
            uint256 total = lpToken.totalSupply();
            return ETNA_Total * 2 * 100 / total;
        }
        return 0;
    }

    function getDepositsNumber () external view returns (uint256) {
        return _depositsNumber;
    }

    function getDepositProfilesNumber () external view returns (uint256) {
        return _depositProfilesNumber;
    }

    function getDeposit (uint256 depositIndex) external view
        returns (address, uint256, uint256, uint256, uint256, uint256) {
        return (
            _deposits[depositIndex].userAddress,
            _deposits[depositIndex].depositProfileId,
            _deposits[depositIndex].amount,
            _deposits[depositIndex].unlock,
            _deposits[depositIndex].updatedAt,
            _deposits[depositIndex].accumulatedYield
        );
    }

    function getUserDeposit (address userAddress, uint256 depositProfileIndex) external view
        returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        uint256 depositIndex = _usersDepositIndexes[userAddress][depositProfileIndex];
        return (
            depositIndex,
            _deposits[depositIndex].userAddress,
            _deposits[depositIndex].depositProfileId,
            _deposits[depositIndex].amount,
            _deposits[depositIndex].unlock,
            _deposits[depositIndex].updatedAt,
            _deposits[depositIndex].accumulatedYield
        );
    }

    function getEtnaContract () external view returns (address) {
        return address(_etnaContract);
    }

    function calculateYield (uint256 depositIndex) public view returns (uint256) {
        uint256 marketIndex =
            _depositProfiles[_deposits[depositIndex].depositProfileId].marketIndex;

        uint256 extraPeriodStartTime
        = _depositProfiles[_deposits[depositIndex].depositProfileId].marketIndexLastTime;
        if (extraPeriodStartTime < _deposits[depositIndex].updatedAt) {
            extraPeriodStartTime = _deposits[depositIndex].updatedAt;
        }
        uint256 extraPeriod = block.timestamp - extraPeriodStartTime;

        if (extraPeriod > 0) {
            uint256 marketFactor = _shift +
                _shift
                * _depositProfiles[_deposits[depositIndex].depositProfileId].apr
                * extraPeriod / 10000 / _year;
            marketIndex = marketIndex * marketFactor / _shift;
        }

        uint256 newAmount = _deposits[depositIndex].amount
            * marketIndex
            / _deposits[depositIndex].lastMarketIndex;

        uint256 yield = (newAmount - _deposits[depositIndex].amount)
            * getDepositProfileRate(_deposits[depositIndex].depositProfileId)
            / 100;

        return yield;
    }

    function getWithdrawTaxAmount () external view returns (uint256) {
        return _withdrawTaxAmount;
    }

    function getTokenBalance (address tokenAddress) external view returns (uint256) {
        IERC20 tokenContract = IERC20(tokenAddress);
        return tokenContract.balanceOf(address(this));
    }

    function getEtnaBalance () external view returns (uint256) {
        return _etnaContract.balanceOf(address(this));
    }

    function getSafeMode () external view returns (bool) {
        return _safeMode;
    }

    function getTotalDeposit (address contractAddress) external view returns (uint256) {
        return _totalDeposit[contractAddress];
    }
}