pragma solidity 0.4.18;


/*
 * https://github.com/OpenZeppelin/zeppelin-solidity
 *
 * The MIT License (MIT)
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/*
 * https://github.com/OpenZeppelin/zeppelin-solidity
 *
 * The MIT License (MIT)
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title Token pools registry
 * @dev Allows to register multiple pools of token with lockup period
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Jakub Stefanski (https://github.com/jstefanski)
 */
contract TokenPool is Ownable {

    using SafeMath for uint256;

    /**
     * @dev Represents registered pool
     */
    struct Pool {
        uint256 availableAmount;
        uint256 lockTimestamp;
    }

    /**
     * @dev Address of mintable token instance
     */
    MintableToken public token;

    /**
     * @dev Indicates available token amounts for each pool
     */
    mapping (string => Pool) private pools;

    modifier onlyNotZero(uint256 amount) {
        require(amount != 0);
        _;
    }

    modifier onlySufficientAmount(string poolId, uint256 amount) {
        require(amount <= pools[poolId].availableAmount);
        _;
    }

    modifier onlyUnlockedPool(string poolId) {
        /* solhint-disable not-rely-on-time */
        require(block.timestamp > pools[poolId].lockTimestamp);
        /* solhint-enable not-rely-on-time */
        _;
    }

    modifier onlyUniquePool(string poolId) {
        require(pools[poolId].availableAmount == 0);
        _;
    }

    modifier onlyValid(address _address) {
        require(_address != address(0));
        _;
    }

    function TokenPool(MintableToken _token)
        public
        onlyValid(_token)
    {
        token = _token;
    }

    /**
     * @dev New pool registered
     * @param poolId string The unique pool id
     * @param amount uint256 The amount of available tokens
     */
    event PoolRegistered(string poolId, uint256 amount);

    /**
     * @dev Pool locked until the specified timestamp
     * @param poolId string The unique pool id
     * @param lockTimestamp uint256 The lock timestamp as Unix Epoch (seconds from 1970)
     */
    event PoolLocked(string poolId, uint256 lockTimestamp);

    /**
     * @dev Tokens transferred from pool
     * @param poolId string The unique pool id
     * @param amount uint256 The amount of transferred tokens
     */
    event PoolTransferred(string poolId, address to, uint256 amount);

    /**
     * @dev Register a new pool and mint its tokens
     * @param poolId string The unique pool id
     * @param availableAmount uint256 The amount of available tokens
     * @param lockTimestamp uint256 The optional lock timestamp as Unix Epoch (seconds from 1970),
     *                              leave zero if not applicable
     */
    function registerPool(string poolId, uint256 availableAmount, uint256 lockTimestamp)
        public
        onlyOwner
        onlyNotZero(availableAmount)
        onlyUniquePool(poolId)
    {
        pools[poolId] = Pool({
            availableAmount: availableAmount,
            lockTimestamp: lockTimestamp
        });

        token.mint(this, availableAmount);

        PoolRegistered(poolId, availableAmount);

        if (lockTimestamp > 0) {
            PoolLocked(poolId, lockTimestamp);
        }
    }

    /**
     * @dev Transfer given amount of tokens to specified address
     * @param to address The address to transfer to
     * @param poolId string The unique pool id
     * @param amount uint256 The amount of tokens to transfer
     */
    function transfer(string poolId, address to, uint256 amount)
        public
        onlyOwner
        onlyValid(to)
        onlyNotZero(amount)
        onlySufficientAmount(poolId, amount)
        onlyUnlockedPool(poolId)
    {
        pools[poolId].availableAmount = pools[poolId].availableAmount.sub(amount);
        require(token.transfer(to, amount));

        PoolTransferred(poolId, to, amount);
    }

    /**
     * @dev Get available amount of tokens in the specified pool
     * @param poolId string The unique pool id
     * @return The available amount of tokens in the specified pool
     */
    function getAvailableAmount(string poolId)
        public
        view
        returns (uint256)
    {
        return pools[poolId].availableAmount;
    }

    /**
     * @dev Get lock timestamp of the pool or zero
     * @param poolId string The unique pool id
     * @return The lock expiration timestamp of the pool or zero if not specified
     */
    function getLockTimestamp(string poolId)
        public
        view
        returns (uint256)
    {
        return pools[poolId].lockTimestamp;
    }
}


/**
 * https://github.com/OpenZeppelin/zeppelin-solidity
 *
 * The MIT License (MIT)
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Mintable token interface
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Jakub Stefanski (https://github.com/jstefanski)
 */
contract MintableToken is ERC20Basic {
    function mint(address to, uint256 amount) public;
}