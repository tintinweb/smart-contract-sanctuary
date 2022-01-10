// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./interfaces/ILiquidity.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// import "hardhat/console.sol";


contract BloxMoveLiquidity is ILiquidity, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint;
    using SafeMathUpgradeable for uint112;
    using AddressUpgradeable for address;


    bytes4 private constant TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFER_FROM = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant BALANCE_OF = bytes4(keccak256(bytes("balanceOf(address)")));
    bytes4 private constant GET_RESERVES = bytes4(keccak256(bytes("getReserves()")));

    address public constant TOKEN = 0x0d98492eA6235156B320EdD90Cc9A9FDAca406E3;

    address public constant PAIR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public treasury;

    uint private initialDay;

    uint private tokenReserve;
    uint private currencyReserve;

    uint public totalRewards;
    uint public totalLiquidity;

    struct LiquidityPosition {
        uint liquidityIn;
        uint liquidityOut;
        uint startDate;
        uint16 lockedDays;
    }

    struct Liquidity {
        uint total;
        uint unlocked;
        uint locked30Days;
        uint locked60Days;
        uint locked90Days;
    }

    // user address => user's liquidity position
    mapping(address => LiquidityPosition[]) private LiquidityPositions;

    // days => total rewards per day
    mapping(uint => uint) private dayRewards;

    // days => total liquidity per day
    mapping(uint => Liquidity) private dayLiquiditys;

    // locked days => rate
    mapping(uint16 => uint) private lockedRewardRate;


    modifier onlyTreasury() {
        assert(treasury != address(0) && treasury == _msgSender());
        _;
    }

    receive() external payable {
        depositFromTreasury(0);
    }

    // Replace constract
    function initialize(uint _rate0, uint _rate30, uint _rate60, uint _rate90) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        lockedRewardRate[0] = _rate0;
        lockedRewardRate[30] = _rate30;
        lockedRewardRate[60] = _rate60;
        lockedRewardRate[90] = _rate90;

        initialDay = block.timestamp.div(1 days);
    }

    /**
    * @dev Add daily rewards
    * @param _rewards Total rewards added
    * @param _startDate Put in rewards start time (milliseconds)
    * @param _endDate Put in rewards end time (milliseconds)
    * @return rewardsPerDay rewards per day
    * @return durationDays rewards duration days
    */
    function addRewards(uint _rewards, uint _startDate, uint _endDate) external override returns(uint rewardsPerDay, uint durationDays) {
        
        uint startDay = _startDate.div(1000).div(1 days);
        uint endDay = _endDate.div(1000).div(1 days);

        require(startDay >= block.timestamp.div(1 days) && endDay > startDay);

        _transferFrom(_msgSender(), address(this), _rewards);

        totalRewards += _rewards;

        durationDays = endDay.sub(startDay);
        rewardsPerDay = _rewards.div(durationDays);

        for (uint i = startDay; i < endDay; i++) {
            dayRewards[i] = rewardsPerDay;
        }

        emit AddRewards(_msgSender(), rewardsPerDay, durationDays);
    }

    /**
    * @dev Update locked reward rate
    * @param _lockedDays Lock days
    * @param _rate Rewards rate after lock expires
    * @return unlocked New unlocked rewards rate
    * @return locked30Days New locked 30 days rewards rate
    * @return locked60Days New locked 60 days rewards rate
    * @return locked90Days New locked 90 days rewards rate
    */
    function updateLockedRewardRate(uint16 _lockedDays, uint _rate) external override onlyOwner returns(uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days) {
        require(_rate != 0);
        require(lockedRewardRate[_lockedDays] != 0);
        lockedRewardRate[_lockedDays] = _rate;
        
        (unlocked, locked30Days, locked60Days, locked90Days) = getLockedRewardRate();
        emit UpdateLockedRewardRate(_msgSender(), unlocked, locked30Days, locked60Days, locked90Days);
    }

    /**
    * @dev Get locked reward rate
    * @return unlocked Unlocked rewards rate
    * @return locked30Days Locked 30 days rewards rate
    * @return locked60Days Locked 60 days rewards rate
    * @return locked90Days Locked 90 days rewards rate
    */
    function getLockedRewardRate() public view override returns(uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days) {
        unlocked = lockedRewardRate[0];
        locked30Days = lockedRewardRate[30];
        locked60Days = lockedRewardRate[60];
        locked90Days = lockedRewardRate[90];
    }

    /**
    * @dev Add token and ether to provide liquidity (a relative ratio of ether must be carried)
    * @param _amount Added token amount, must be approved first
    * @param _lockedDays Locked 0 ,30, 60, 90 days
    * @param _ratioMax Maximum ratio, prevent the ratio shift too much
    * @param _ratioMin Minimum ratio, prevent the ratio shift too much
    * @return liquidity Added liquidity
    */
    function addLiquidity(uint _amount, uint16 _lockedDays, uint _ratioMax, uint _ratioMin) external override payable nonReentrant returns(uint liquidity) {
        require(_amount != 0 && msg.value != 0);
        uint rate = lockedRewardRate[_lockedDays];
        require(rate != 0);

        uint ratio = getRatio();
        require(ratio <= _ratioMax && ratio >= _ratioMin);

        (uint amountToken, uint amountWei) = _getDesiredAmount(_amount, msg.value, ratio);
        require(amountToken != 0 && amountWei != 0);

        _transferFrom(_msgSender(), address(this), amountToken);

        liquidity = sqrt(amountToken.mul(amountWei));

        _setLiquidity(liquidity, _lockedDays);

        totalLiquidity += liquidity;
        tokenReserve += amountToken;
        currencyReserve += amountWei;

        // refund
        if (msg.value > amountWei) _transferCurrency(_msgSender(), msg.value - amountWei);

        emit AddLiquidity(_msgSender(), amountToken, amountWei);
    }

    function _setLiquidity(uint _amount, uint16 _lockedDays) private {
        LiquidityPositions[_msgSender()].push(LiquidityPosition(_amount, 0, block.timestamp, _lockedDays));

        uint target = block.timestamp.div(1 days).add(1);
        Liquidity memory liquidity = dayLiquiditys[target];
        if (liquidity.total == 0) {
            (uint total, uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days) = _getLiquiditys(target);
            liquidity.total = total;
            liquidity.unlocked = unlocked;
            liquidity.locked30Days = locked30Days;
            liquidity.locked60Days = locked60Days;
            liquidity.locked90Days = locked90Days;
        }
        liquidity.total += _amount;
        if (_lockedDays == 0) {
            liquidity.unlocked += _amount;
            
        } else if (_lockedDays == 30) {
            liquidity.locked30Days += _amount;

        } else if (_lockedDays == 60) {
            liquidity.locked60Days += _amount;

        } else if(_lockedDays == 90) {
            liquidity.locked90Days += _amount;
        }
        dayLiquiditys[target] = liquidity;
    }

    /**
    * @dev Get total count of address' position
    * @param _address Query address
    * @return Total count of position
    */
    function countPositions(address _address) public override view returns(uint) {
        return LiquidityPositions[_address].length;
    }

    /**
    * @dev Get ratio of token : currency
    * @return Ratio of token : currency
    */
    function getRatio() public override view returns(uint) {
        (uint112 reserve0, uint112 reserve1,) = abi.decode(PAIR.functionStaticCall(abi.encodeWithSelector(GET_RESERVES)), (uint112, uint112, uint32));
        return reserve0.mul(10 ** decimals()).div(reserve1);
    }

    function _getDesiredAmount(uint _amountToken, uint _amountWei, uint _ratio) private pure returns(uint amountToken, uint amountWei) {
        require(_amountToken != 0 && _amountWei != 0 && _ratio != 0);

        uint amountWeiDesired = _amountToken.mul(10 ** decimals()).div(_ratio);
        if (_amountWei >= amountWeiDesired) {
            amountToken = _amountToken;
            amountWei = amountWeiDesired;
        } else {
            amountToken = _amountWei.mul(_ratio).div(10 ** decimals());
            amountWei = _amountWei;
        }
    }

    /**
    * @dev Remove liquidity to get token, ether and rewards
    * @param _idx Position's index
    * @param _liquidityOut Remove liquidity amount
    * @return amountToken Retrieve token
    * @return amountWei Retrieve ether
    * @return rewards Total rewards
    */
    function removeLiquidity(uint _idx, uint _liquidityOut) external override nonReentrant returns(uint amountToken, uint amountWei, uint rewards) {
        require(_idx < countPositions(_msgSender()));

        (uint liquidityIn, uint liquidityOut, uint startDate, uint16 lockedDays) = getLiquidityPosition(_msgSender(), _idx);
        require(liquidityIn >= liquidityOut.add(_liquidityOut));

        (amountToken, amountWei) = _liquidityToTokenAmount(_liquidityOut);
        rewards = _calcRewards(startDate, lockedDays, _liquidityOut);

        (uint token, uint currency) = getBalance();
        require(currency >= amountWei && token >= amountToken.add(rewards));

        LiquidityPositions[_msgSender()][_idx].liquidityOut += _liquidityOut;

        totalRewards -= rewards;
        totalLiquidity -= _liquidityOut;
        tokenReserve -= amountToken;
        currencyReserve -= amountWei;

        _transfer(_msgSender(), amountToken.add(rewards));
        _transferCurrency(_msgSender(), amountWei);

        emit RemoveLiquidity(_msgSender(), amountToken, amountWei, rewards);
    }

    function _liquidityToTokenAmount(uint _liquidity) private view returns(uint amountToken, uint amountWei) {
        (uint token, uint currency) = getReserves();
        amountToken = token.mul(_liquidity).div(totalLiquidity);
        amountWei = currency.mul(_liquidity).div(totalLiquidity);
    }

    function _calcRewards(uint _startDate, uint16 _lockedDays, uint _liquidityOut) private view returns(uint) {

        uint startDay = _startDate.div(1 days).add(1);
        uint endDay = block.timestamp.div(1 days);

        if (startDay.add(_lockedDays) < endDay) {
            return 0;
        }

        uint rewards;
        Liquidity memory tempLiquidity;
        for (uint i = startDay; i < endDay; i++) {
            if (dayLiquiditys[i].total != 0) {
                tempLiquidity = dayLiquiditys[i];
            }
            
            uint rewardPacket = _getRewardPacket(tempLiquidity, dayRewards[i], _lockedDays);
            
            uint totalLiquidityByDay = _lockedDays == 0 ? tempLiquidity.unlocked : _lockedDays == 30 ? tempLiquidity.locked30Days : _lockedDays == 60 ? tempLiquidity.locked60Days : _lockedDays == 90 ? tempLiquidity.locked90Days : 0;
            rewards += rewardPacket.mul(_liquidityOut).div(totalLiquidityByDay);
        }
        return rewards;
    }

    function _getRewardPacket(Liquidity memory _liquidity, uint _totalReward, uint16 _lockedDays) private view returns(uint) {
        (uint raw0, uint raw30, uint raw60, uint raw90) = _getRawWeight(_liquidity.unlocked, _liquidity.locked30Days, _liquidity.locked60Days, _liquidity.locked90Days);
        uint target = _lockedDays == 0 ? raw0 : _lockedDays == 30 ? raw30 : _lockedDays == 60 ? raw60 : _lockedDays == 90 ? raw90 : 0;
        uint weight = _normalizedWeight(target, raw0, raw30, raw60, raw90);

        // day's total reward in selected lock pool
        return _totalReward.mul(weight).div(10 ** decimals());
    }

    function _getRawWeight(uint _share0, uint _share30, uint _share60, uint _share90) private view returns(uint raw0, uint raw30, uint raw60, uint raw90) {
            uint total = _share0.add(_share30).add(_share60).add(_share90);
            raw0 = _calcRawWeight(_share0, total, 0);
            raw30 = _calcRawWeight(_share30, total, 30);
            raw60 = _calcRawWeight(_share60, total, 60);
            raw90 = _calcRawWeight(_share90, total, 90);
    }

    function _calcRawWeight(uint _tokens, uint _total, uint16 _lockedDays) private view returns(uint) {
            uint percentage = _tokens.mul(10 ** decimals()).div(_total);
            uint rate = lockedRewardRate[_lockedDays];
            return percentage.mul(rate).div(10 ** decimals());
    }

    function _normalizedWeight(uint _target, uint _raw0, uint _raw30, uint _raw60, uint _raw90) private pure returns(uint) {
        uint totalWeight = _raw0.add(_raw30).add(_raw60).add(_raw90);
        return _target.mul(10 ** decimals()).div(totalWeight);
    }

    /**
    * @dev Get provide daily total rewards by timestamp
    * @param _timestamp Milliseconds
    * @return Total rewards by day
    */
    function getRewards(uint _timestamp) external override view returns(uint) {
        require(_timestamp != 0);
        uint day = _timestamp.div(1000).div(1 days);
        require(day >= initialDay);
        return dayRewards[day];
    }

    /**
    * @dev Get total liquidty by timestamp
    * @param _timestamp Milliseconds
    * @return total Total liquidity by day
    * @return unlocked Total unlocked liquidity by day
    * @return locked30Days Total locked 30 days liquidity by day
    * @return locked60Days Total locked 30 days liquidity by day
    * @return locked90Days Total locked 30 days liquidity by day
    */
    function getLiquiditys(uint _timestamp) external override view returns(uint total, uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days) {
        require(_timestamp != 0);
        return _getLiquiditys(_timestamp.div(1000).div(1 days));
    }

    function _getLiquiditys(uint _day) private view returns(uint total, uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days) {
        require(_day >= initialDay);
        uint day = _day;
        while (dayLiquiditys[day].total == 0 && day > initialDay) {
            day--;
        }
        Liquidity storage liquidity = dayLiquiditys[day];
        total = liquidity.total;
        unlocked = liquidity.unlocked;
        locked30Days = liquidity.locked30Days;
        locked60Days = liquidity.locked60Days;
        locked90Days = liquidity.locked90Days;
    }

    /**
    * @dev Get liquidity position
    * @param _address Query address
    * @param _idx Position's index
    * @return liquidityIn Total provides liquidity by position
    * @return liquidityOut Retrieve liquidity in this position
    * @return startDate Start date(seconds)
    * @return lockedDays Locked days
    */
    function getLiquidityPosition(address _address, uint _idx) public override view returns(uint liquidityIn, uint liquidityOut, uint startDate, uint16 lockedDays) {
        LiquidityPosition storage position = LiquidityPositions[_address][_idx];
        liquidityIn = position.liquidityIn;
        liquidityOut = position.liquidityOut;
        startDate = position.startDate;
        lockedDays = position.lockedDays;
    }

    /**
    * @dev Update treasury contract's address
    * @param _address Treasury contract's address
    */
    function updateTreasury(address _address) external override onlyOwner {
        treasury = _address;

        emit UpdateTreasury(_msgSender(), treasury);
    }

    /**
    * @dev Deposit token and ether from treasury contract
    * @param _amountToken Treasury deposit token amount, must be approved first
    * @return amountToken Treasury deposit token amount
    * @return amountWei Treasury deposit ether amount
    */
    function depositFromTreasury(uint _amountToken) public override payable onlyTreasury returns(uint amountToken, uint amountWei) {
        if (_amountToken > 0) {
            _transferFrom(_msgSender(), address(this), _amountToken);
        }

        amountToken = _amountToken;
        amountWei = msg.value;
        emit DepositFromTreasury(_msgSender(), _amountToken, msg.value);
    }

    /**
    * @dev Withdraw token and ether to treasury contract
    * @param _amountToken Withdraw token amount
    * @param _amountWei Withdraw ether amount
    * @return amountToken Withdraw token amount
    * @return amountWei Withdraw ether amount
    */
    function withdrawToTreasury(uint _amountToken, uint _amountWei) external override onlyTreasury returns(uint amountToken, uint amountWei) {
        if (_amountToken > 0) {
            _transfer(_msgSender(), _amountToken);
        }
        if (_amountWei > 0) {
            _transferCurrency(_msgSender(), _amountWei);
        }

        amountToken = _amountToken;
        amountWei = _amountWei;
        emit WithdrawToTreasury(_msgSender(), amountToken, amountWei);
    }

    function _transferFrom(address _from, address _to, uint _amount) private {
        require(_to != address(0) && _amount > 0);
        TOKEN.functionCall(abi.encodeWithSelector(TRANSFER_FROM, _from, _to, _amount));
    }

    function _transfer(address _to, uint _amount) private {
        require(_to != address(0) && _amount > 0);
        TOKEN.functionCall(abi.encodeWithSelector(TRANSFER, _to, _amount));
    }

    function _transferCurrency(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}(new bytes(0));
        require(success);
    }

    /**
    * @dev Get reserves token and ether
    * @return token Total reserves of token
    * @return currency Total reserves of ether(wei)
    */
    function getReserves() public override view returns(uint token, uint currency) {
        token = tokenReserve;
        currency = currencyReserve;
    }

    /**
    * @dev Get real-time balance
    * @return token Real-time balance of token
    * @return currency Real-time balance of ether(wei)
    */
    function getBalance() public override view returns(uint token, uint currency) {
        token = abi.decode(TOKEN.functionStaticCall(abi.encodeWithSelector(BALANCE_OF, address(this))), (uint));
        currency = address(this).balance;
    }

    /**
    * @dev Get the number of decimals 
    * @return The number of decimals 
    */
    function decimals() public override pure returns(uint8) {
        return 18;
    }

    /**
    * @dev Math sqrt
    * @param x Input number
    * @return The number of sqrt(x)
    */
    function sqrt(uint x) public pure returns(uint) {
        uint z = (x + 1 ) / 2;
        uint y = x;
        while (z < y) {
            y = z;
            z = ( x / z + z ) / 2;
        }
        return y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ILiquidity {

    event AddRewards(address indexed sender, uint rewardsPerDay, uint durationDays);
    event UpdateLockedRewardRate(address indexed sender, uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days);

    event AddLiquidity(address indexed sender, uint amountToken, uint amountWei);
    event RemoveLiquidity(address indexed sender, uint amountToken, uint amountWei, uint rewards);

    event UpdateTreasury(address indexed sender, address treasuryAddress);
    event DepositFromTreasury(address indexed sender, uint leftToken, uint leftWei);
    event WithdrawToTreasury(address indexed sender, uint leftToken, uint leftWei);

    
    function addRewards(uint _rewards, uint _startDate, uint _endDate) external returns(uint rewardsPerDay, uint durationDays);
    function updateLockedRewardRate(uint16 _lockedDays, uint _rate) external returns(uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days);
    function getLockedRewardRate() external view returns(uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days);
    function addLiquidity(uint _amount, uint16 _lockedDays, uint _ratioMax, uint _ratioMin) external payable returns(uint liquidity) ;
    function countPositions(address _address) external view returns(uint);
    function getRatio() external view returns(uint);
    function removeLiquidity(uint _idx, uint _liquidityOut) external returns(uint amountToken, uint amountWei, uint rewards);
    function getRewards(uint _timestamp) external view returns(uint);
    function getLiquiditys(uint _timestamp) external view returns(uint total, uint unlocked, uint locked30Days, uint locked60Days, uint locked90Days);
    function getLiquidityPosition(address _address, uint _idx) external view returns(uint liquidityIn, uint liquidityOut, uint startDate, uint16 lockedDays);
    function updateTreasury(address _address) external;
    function depositFromTreasury(uint _amountToken) external payable returns(uint leftToken, uint leftWei);
    function withdrawToTreasury(uint _amountToken, uint _amountWei) external returns(uint leftToken, uint leftWei);
    function getReserves() external view returns(uint token, uint currency);
    function getBalance() external view returns(uint token, uint currency);
    function decimals() external pure returns(uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}