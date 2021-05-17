/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-12
*/

// File: solidity/contracts/utility/interfaces/IOwned.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;


/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned {
}

// File: solidity/contracts/token/interfaces/IERC20Token.sol


pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/token/interfaces/IDSToken.sol


pragma solidity 0.6.12;




/*
    DSToken interface
*/
interface IDSToken is IConverterAnchor, IERC20Token {
    function issue(address _to, uint256 _amount) external;
    function destroy(address _from, uint256 _amount) external;
}

// File: solidity/contracts/liquidity-protection/interfaces/ILiquidityProtectionStore.sol


pragma solidity 0.6.12;





/*
    Liquidity Protection Store interface
*/
interface ILiquidityProtectionStore is IOwned {
    function addPoolToWhitelist(IConverterAnchor _anchor) external;
    function removePoolFromWhitelist(IConverterAnchor _anchor) external;
    function isPoolWhitelisted(IConverterAnchor _anchor) external view returns (bool);

    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;

    function protectedLiquidity(uint256 _id)
        external
        view
        returns (address, IDSToken, IERC20Token, uint256, uint256, uint256, uint256, uint256);

    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,
        IERC20Token _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        uint256 _reserveRateN,
        uint256 _reserveRateD,
        uint256 _timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(uint256 _id, uint256 _poolNewAmount, uint256 _reserveNewAmount) external;
    function removeProtectedLiquidity(uint256 _id) external;
    
    function lockedBalance(address _provider, uint256 _index) external view returns (uint256, uint256);
    function lockedBalanceRange(address _provider, uint256 _startIndex, uint256 _endIndex) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(address _provider, uint256 _reserveAmount, uint256 _expirationTime) external returns (uint256);
    function removeLockedBalance(address _provider, uint256 _index) external;

    function systemBalance(IERC20Token _poolToken) external view returns (uint256);
    function incSystemBalance(IERC20Token _poolToken, uint256 _poolAmount) external;
    function decSystemBalance(IERC20Token _poolToken, uint256 _poolAmount ) external;
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/SafeMath.sol


pragma solidity 0.6.12;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}

// File: solidity/contracts/utility/TokenHandler.sol


pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
      * @dev executes the ERC20 token's `approve` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _spender approved address
      * @param _value   allowance amount
    */
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
    }

    /**
      * @dev executes the ERC20 token's `transfer` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
    }

    /**
      * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: solidity/contracts/liquidity-protection/LiquidityProtectionStore.sol


pragma solidity 0.6.12;






/**
  * @dev The Liquidity Protection Store contract serves as the storage of the liquidity protection
  * mechanism. It holds the data and tokens and is non upgradable.
  *
*/
contract LiquidityProtectionStore is ILiquidityProtectionStore, Owned, TokenHandler, Utils {
    using SafeMath for uint256;

    struct PoolIndex {
        bool isValid;
        uint256 value;
    }

    struct ProtectedLiquidity {
        address provider;           // liquidity provider
        uint256 index;              // index in the provider liquidity ids array
        IDSToken poolToken;         // pool token address
        IERC20Token reserveToken;   // reserve token address
        uint256 poolAmount;         // pool token amount
        uint256 reserveAmount;      // reserve token amount
        uint256 reserveRateN;       // rate of 1 protected reserve token in units of the other reserve token (numerator)
        uint256 reserveRateD;       // rate of 1 protected reserve token in units of the other reserve token (denominator)
        uint256 timestamp;          // timestamp
    }

    struct LockedBalance {
        uint256 amount;         // amount of network tokens
        uint256 expirationTime; // lock expiration time
    }

    // list of whitelisted pools and mapping of pool anchor address -> index in the pool whitelist for quick access
    IConverterAnchor[] private poolWhitelist;
    mapping(IConverterAnchor => PoolIndex) private poolWhitelistIndices;

    // protected liquidity by provider
    uint256 private nextProtectedLiquidityId;
    mapping (address => uint256[]) private protectedLiquidityIdsByProvider;
    mapping (uint256 => ProtectedLiquidity) private protectedLiquidities;

    // user locked network token balances
    mapping (address => LockedBalance[]) private lockedBalances;

    // system balances
    mapping (IERC20Token => uint256) private systemBalances;

    // total protected pool supplies / reserve amounts
    mapping (IDSToken =>    uint256) private totalProtectedPoolAmounts;
    mapping (IDSToken =>    mapping (IERC20Token => uint256)) private totalProtectedReserveAmounts;

    /**
      * @dev triggered when the pool whitelist is updated
      *
      * @param _poolAnchor  pool anchor
      * @param _added       true if the pool was added to the whitelist, false if it was removed
    */
    event PoolWhitelistUpdated(
        IConverterAnchor indexed _poolAnchor,
        bool _added
    );

    /**
      * @dev triggered when liquidity protection is added
      *
      * @param _provider        liquidity provider
      * @param _poolToken       pool token address
      * @param _reserveToken    reserve token address
      * @param _poolAmount      amount of pool tokens
      * @param _reserveAmount   amount of reserve tokens
    */
    event ProtectionAdded(
        address indexed _provider,
        IDSToken indexed    _poolToken,
        IERC20Token indexed _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount
    );

    /**
      * @dev triggered when liquidity protection is updated
      *
      * @param _provider            liquidity provider
      * @param _prevPoolAmount      previous amount of pool tokens
      * @param _prevReserveAmount   previous amount of reserve tokens
      * @param _newPoolAmount       new amount of pool tokens
      * @param _newReserveAmount    new amount of reserve tokens
    */
    event ProtectionUpdated(
        address indexed _provider,
        uint256 _prevPoolAmount,
        uint256 _prevReserveAmount,
        uint256 _newPoolAmount,
        uint256 _newReserveAmount
    );

    /**
      * @dev triggered when liquidity protection is removed
      *
      * @param _provider        liquidity provider
      * @param _poolToken       pool token address
      * @param _reserveToken    reserve token address
      * @param _poolAmount      amount of pool tokens
      * @param _reserveAmount   amount of reserve tokens
    */
    event ProtectionRemoved(
        address indexed _provider,
        IDSToken indexed    _poolToken,
        IERC20Token indexed _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount
    );

    /**
      * @dev triggered when network tokens are locked
      *
      * @param _provider        provider of the network tokens
      * @param _amount          amount of network tokens
      * @param _expirationTime  lock expiration time
    */
    event BalanceLocked(
        address indexed _provider,
        uint256 _amount,
        uint256 _expirationTime
    );

    /**
      * @dev triggered when network tokens are unlocked
      *
      * @param _provider    provider of the network tokens
      * @param _amount      amount of network tokens
    */
    event BalanceUnlocked(
        address indexed _provider,
        uint256 _amount
    );

    /**
      * @dev triggered when the system balance for a given token is updated
      *
      * @param _token       token address
      * @param _prevAmount  previous amount
      * @param _newAmount   new amount
    */
    event SystemBalanceUpdated(
        IERC20Token _token,
        uint256 _prevAmount,
        uint256 _newAmount
    );

    /**
      * @dev adds a pool to the whitelist
      * can only be called by the contract owner
      *
      * @param _poolAnchor pool anchor
    */
    function addPoolToWhitelist(IConverterAnchor _poolAnchor)
        external
        override
        ownerOnly
        validAddress(address(_poolAnchor))
        notThis(address(_poolAnchor))
    {
        // validate input
        PoolIndex storage poolIndex = poolWhitelistIndices[_poolAnchor];
        require(!poolIndex.isValid, "ERR_POOL_ALREADY_WHITELISTED");

        poolIndex.value = poolWhitelist.length;
        poolWhitelist.push(_poolAnchor);
        poolIndex.isValid = true;

        emit PoolWhitelistUpdated(_poolAnchor, true);
    }

    /**
      * @dev removes a pool from the whitelist
      * can only be called by the contract owner
      *
      * @param _poolAnchor pool anchor
    */
    function removePoolFromWhitelist(IConverterAnchor _poolAnchor)
        external
        override
        ownerOnly
        validAddress(address(_poolAnchor))
        notThis(address(_poolAnchor))
    {
        // validate input
        PoolIndex storage poolIndex = poolWhitelistIndices[_poolAnchor];
        require(poolIndex.isValid, "ERR_POOL_NOT_WHITELISTED");

        uint256 index = poolIndex.value;
        uint256 length = poolWhitelist.length;
        assert(length > 0);

        uint256 lastIndex = length - 1;
        if (index < lastIndex) {
            IConverterAnchor lastAnchor = poolWhitelist[lastIndex];
            poolWhitelistIndices[lastAnchor].value = index;
            poolWhitelist[index] = lastAnchor;
        }

        poolWhitelist.pop();
        delete poolWhitelistIndices[_poolAnchor];

        emit PoolWhitelistUpdated(_poolAnchor, false);
    }

    /**
      * @dev returns the number of whitelisted pools
      *
      * @return number of whitelisted pools
    */
    function whitelistedPoolCount() external view returns (uint256) {
        return poolWhitelist.length;
    }

    /**
      * @dev returns the list of whitelisted pools
      *
      * @return list of whitelisted pools
    */
    function whitelistedPools() external view returns (IConverterAnchor[] memory) {
        return poolWhitelist;
    }

    /**
      * @dev returns the whitelisted pool at a given index
      *
      * @param _index index
      * @return whitelisted pool anchor
    */
    function whitelistedPool(uint256 _index) external view returns (IConverterAnchor) {
        return poolWhitelist[_index];
    }

    /**
      * @dev checks whether a given pool is whitelisted
      *
      * @param _poolAnchor pool anchor
      * @return true if the given pool is whitelisted, false otherwise
    */
    function isPoolWhitelisted(IConverterAnchor _poolAnchor) external view override returns (bool) {
        return poolWhitelistIndices[_poolAnchor].isValid;
    }

    /**
      * @dev withdraws tokens held by the contract
      * can only be called by the contract owner
      *
      * @param _token   token address
      * @param _to      recipient address
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        external
        override
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }

    /**
      * @dev returns the number of protected liquidities for the given provider
      *
      * @param _provider    liquidity provider
      * @return number of protected liquidities
    */
    function protectedLiquidityCount(address _provider) external view returns (uint256) {
        return protectedLiquidityIdsByProvider[_provider].length;
    }

    /**
      * @dev returns the list of protected liquidity ids for the given provider
      *
      * @param _provider    liquidity provider
      * @return protected liquidity ids
    */
    function protectedLiquidityIds(address _provider) external view returns (uint256[] memory) {
        return protectedLiquidityIdsByProvider[_provider];
    }

    /**
      * @dev returns the id of a protected liquidity for the given provider at a specific index
      *
      * @param _provider    liquidity provider
      * @param _index       protected liquidity index
      * @return protected liquidity id
    */
    function protectedLiquidityId(address _provider, uint256 _index) external view returns (uint256) {
        return protectedLiquidityIdsByProvider[_provider][_index];
    }

    /**
      * @dev returns an existing protected liquidity details
      *
      * @param _id  protected liquidity id
      *
      * @return liquidity provider
      * @return pool token address
      * @return reserve token address
      * @return pool token amount
      * @return reserve token amount
      * @return rate of 1 protected reserve token in units of the other reserve token (numerator)
      * @return rate of 1 protected reserve token in units of the other reserve token (denominator)
      * @return timestamp
    */
    function protectedLiquidity(uint256 _id)
        external
        view
        override
        returns (address, IDSToken,    IERC20Token, uint256, uint256, uint256, uint256, uint256) 
    {
        ProtectedLiquidity storage liquidity = protectedLiquidities[_id];
        return (
            liquidity.provider,
            liquidity.poolToken,
            liquidity.reserveToken,
            liquidity.poolAmount,
            liquidity.reserveAmount,
            liquidity.reserveRateN,
            liquidity.reserveRateD,
            liquidity.timestamp
        );
    }

    /**
      * @dev adds protected liquidity
      * can only be called by the contract owner
      *
      * @param _provider        liquidity provider
      * @param _poolToken       pool token address
      * @param _reserveToken    reserve token address
      * @param _poolAmount      pool token amount
      * @param _reserveAmount   reserve token amount
      * @param _reserveRateN    rate of 1 protected reserve token in units of the other reserve token (numerator)
      * @param _reserveRateD    rate of 1 protected reserve token in units of the other reserve token (denominator)
      * @param _timestamp       timestamp
      * @return new protected liquidity id
    */
    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,   
        IERC20Token _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        uint256 _reserveRateN,
        uint256 _reserveRateD,
        uint256 _timestamp
    ) external override ownerOnly returns (uint256) {
        // validate input
        require(
            _provider != address(0) &&
            _provider != address(this) &&
            address(_poolToken) != address(0) &&
            address(_poolToken) != address(this) &&
            address(_reserveToken) != address(0) &&
            address(_reserveToken) != address(this),
            "ERR_INVALID_ADDRESS"
        );
        require(
            _poolAmount > 0 &&
            _reserveAmount > 0 &&
            _reserveRateN > 0 &&
            _reserveRateD > 0 &&
            _timestamp > 0,
            "ERR_ZERO_VALUE"
        );


        // add the protected liquidity
        uint256[] storage ids = protectedLiquidityIdsByProvider[_provider];
        uint256 id = nextProtectedLiquidityId;
        nextProtectedLiquidityId += 1;

        protectedLiquidities[id] = ProtectedLiquidity({
            provider: _provider,
            index: ids.length,
            poolToken: _poolToken,
            reserveToken: _reserveToken,
            poolAmount: _poolAmount,
            reserveAmount: _reserveAmount,
            reserveRateN: _reserveRateN,
            reserveRateD: _reserveRateD,
            timestamp: _timestamp
        });

        ids.push(id);

        // update the total amounts
        totalProtectedPoolAmounts[_poolToken] = totalProtectedPoolAmounts[_poolToken].add(_poolAmount);
        totalProtectedReserveAmounts[_poolToken][_reserveToken] = totalProtectedReserveAmounts[_poolToken][_reserveToken].add(_reserveAmount);

        emit ProtectionAdded(_provider, _poolToken, _reserveToken, _poolAmount, _reserveAmount);
        return id;
    }

    /**
      * @dev updates an existing protected liquidity pool/reserve amounts
      * can only be called by the contract owner
      *
      * @param _id                  protected liquidity id
      * @param _newPoolAmount       new pool tokens amount
      * @param _newReserveAmount    new reserve tokens amount
    */
    function updateProtectedLiquidityAmounts(uint256 _id, uint256 _newPoolAmount, uint256 _newReserveAmount)
        external
        override
        ownerOnly
        greaterThanZero(_newPoolAmount)
        greaterThanZero(_newReserveAmount)
    {
        // update the protected liquidity
        ProtectedLiquidity storage liquidity = protectedLiquidities[_id];

        // validate input
        address provider = liquidity.provider;
        require(provider != address(0), "ERR_INVALID_ID");

        IDSToken poolToken    = liquidity.poolToken;
        IERC20Token reserveToken = liquidity.reserveToken;
        uint256 prevPoolAmount = liquidity.poolAmount;
        uint256 prevReserveAmount = liquidity.reserveAmount;
        liquidity.poolAmount = _newPoolAmount;
        liquidity.reserveAmount = _newReserveAmount;

        // update the total amounts
        totalProtectedPoolAmounts[poolToken] = totalProtectedPoolAmounts[poolToken].add(_newPoolAmount).sub(prevPoolAmount);
        totalProtectedReserveAmounts[poolToken][reserveToken] = totalProtectedReserveAmounts[poolToken][reserveToken].add(_newReserveAmount).sub(prevReserveAmount);

        emit ProtectionUpdated(provider, prevPoolAmount, prevReserveAmount, _newPoolAmount, _newReserveAmount);
    }

    /**
      * @dev removes protected liquidity
      * can only be called by the contract owner
      *
      * @param _id  protected liquidity id
    */
    function removeProtectedLiquidity(uint256 _id) external override ownerOnly {
        // remove the protected liquidity
        ProtectedLiquidity storage liquidity = protectedLiquidities[_id];

        // validate input
        address provider = liquidity.provider;
        require(provider != address(0), "ERR_INVALID_ID");

        uint256 index = liquidity.index;
        IDSToken poolToken    = liquidity.poolToken;
        IERC20Token reserveToken = liquidity.reserveToken;
        uint256 poolAmount = liquidity.poolAmount;
        uint256 reserveAmount = liquidity.reserveAmount;
        delete protectedLiquidities[_id];

        uint256[] storage ids = protectedLiquidityIdsByProvider[provider];
        uint256 length = ids.length;
        assert(length > 0);

        uint256 lastIndex = length - 1;
        if (index < lastIndex) {
            uint256 lastId = ids[lastIndex];
            ids[index] = lastId;
            protectedLiquidities[lastId].index = index;
        }

        ids.pop();

        // update the total amounts
        totalProtectedPoolAmounts[poolToken] = totalProtectedPoolAmounts[poolToken].sub(poolAmount);
        totalProtectedReserveAmounts[poolToken][reserveToken] = totalProtectedReserveAmounts[poolToken][reserveToken].sub(reserveAmount);

        emit ProtectionRemoved(provider, poolToken, reserveToken, poolAmount, reserveAmount);
    }

    /**
      * @dev returns the number of network token locked balances for a given provider
      *
      * @param _provider    locked balances provider
      * @return the number of network token locked balances
    */
    function lockedBalanceCount(address _provider) external view returns (uint256) {
        return lockedBalances[_provider].length;
    }

    /**
      * @dev returns an existing locked network token balance details
      *
      * @param _provider    locked balances provider
      * @param _index       start index
      * @return amount of network tokens
      * @return lock expiration time
    */
    function lockedBalance(address _provider, uint256 _index) external view override returns (uint256, uint256) {
        LockedBalance storage balance = lockedBalances[_provider][_index];
        return (
            balance.amount,
            balance.expirationTime
        );
    }

    /**
      * @dev returns a range of locked network token balances for a given provider
      *
      * @param _provider    locked balances provider
      * @param _startIndex  start index
      * @param _endIndex    end index (exclusive)
      * @return locked amounts
      * @return expiration times
    */
    function lockedBalanceRange(address _provider, uint256 _startIndex, uint256 _endIndex)
        external
        view
        override
        returns (uint256[] memory, uint256[] memory)
    {
        // limit the end index by the number of locked balances
        if (_endIndex > lockedBalances[_provider].length) {
            _endIndex = lockedBalances[_provider].length;
        }

        // ensure that the end index is higher than the start index
        require(_endIndex > _startIndex, "ERR_INVALID_INDICES");

        // get the locked balances for the given range and return them
        uint256 length = _endIndex - _startIndex;
        uint256[] memory amounts = new uint256[](length);
        uint256[] memory expirationTimes = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            LockedBalance storage balance = lockedBalances[_provider][_startIndex + i];
            amounts[i] = balance.amount;
            expirationTimes[i] = balance.expirationTime;
        }

        return (amounts, expirationTimes);
    }

    /**
      * @dev adds new locked network token balance
      * can only be called by the contract owner
      *
      * @param _provider        liquidity provider
      * @param _amount          token amount
      * @param _expirationTime  lock expiration time
      * @return new locked balance index
    */
    function addLockedBalance(address _provider, uint256 _amount, uint256 _expirationTime)
        external
        override
        ownerOnly
        validAddress(_provider)
        notThis(_provider)
        greaterThanZero(_amount)
        greaterThanZero(_expirationTime)
        returns (uint256)
    {
        lockedBalances[_provider].push(LockedBalance({
            amount: _amount,
            expirationTime: _expirationTime
        }));

        emit BalanceLocked(_provider, _amount, _expirationTime);
        return lockedBalances[_provider].length - 1;
    }

    /**
      * @dev removes a locked network token balance
      * can only be called by the contract owner
      *
      * @param _provider    liquidity provider
      * @param _index       index of the locked balance
    */
    function removeLockedBalance(address _provider, uint256 _index)
        external
        override
        ownerOnly
        validAddress(_provider)
    {
        LockedBalance[] storage balances = lockedBalances[_provider];
        uint256 length = balances.length;
        
        // validate input
        require(_index < length, "ERR_INVALID_INDEX");

        uint256 amount = balances[_index].amount;
        uint256 lastIndex = length - 1;
        if (_index < lastIndex) {
            balances[_index] = balances[lastIndex];
        }

        balances.pop();

        emit BalanceUnlocked(_provider, amount);
    }

    /**
      * @dev returns the system balance for a given token
      *
      * @param _token   token address
      * @return system balance
    */
    function systemBalance(IERC20Token _token) external view override returns (uint256) {
        return systemBalances[_token];
    }

    /**
      * @dev increases the system balance for a given token
      * can only be called by the contract owner
      *
      * @param _token   token address
      * @param _amount  token amount
    */
    function incSystemBalance(IERC20Token _token, uint256 _amount)
        external
        override
        ownerOnly
        validAddress(address(_token))
    {
        uint256 prevAmount = systemBalances[_token];
        uint256 newAmount = prevAmount.add(_amount);
        systemBalances[_token] = newAmount;

        emit SystemBalanceUpdated(_token, prevAmount, newAmount);
    }

    /**
      * @dev decreases the system balance for a given token
      * can only be called by the contract owner
      *
      * @param _token   token address
      * @param _amount  token amount
    */
    function decSystemBalance(IERC20Token _token, uint256 _amount)
        external
        override
        ownerOnly
        validAddress(address(_token))
    {
        uint256 prevAmount = systemBalances[_token];
        uint256 newAmount = prevAmount.sub(_amount);
        systemBalances[_token] = newAmount;

        emit SystemBalanceUpdated(_token, prevAmount, newAmount);
    }

    /**
      * @dev returns the total protected pool token amount for a given pool
      *
      * @param _poolToken   pool token address
      * @return total protected amount
    */
    function totalProtectedPoolAmount(IDSToken _poolToken)    external view returns (uint256) {
        return totalProtectedPoolAmounts[_poolToken];
    }

    /**
      * @dev returns the total protected reserve amount for a given pool
      *
      * @param _poolToken       pool token address
      * @param _reserveToken    reserve token address
      * @return total protected amount
    */
    function totalProtectedReserveAmount(IDSToken _poolToken,    IERC20Token _reserveToken) external view returns (uint256) {
        return totalProtectedReserveAmounts[_poolToken][_reserveToken];
    }
}