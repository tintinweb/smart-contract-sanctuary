pragma solidity 0.5.7;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import './IERC20Template.sol';
import './SafeMath.sol';

/**
 * @title FixedRateExchange
 * @dev FixedRateExchange is a fixed rate exchange Contract
 *      Marketplaces uses this contract to allow consumers 
 *      exchanging datatokens with ocean token using a fixed 
 *      exchange rate.
 */
contract FixedRateExchange {
    using SafeMath for uint256;
    uint256 private constant BASE = 10 ** 18;
    struct Exchange {
        bool active;
        address exchangeOwner;
        address dataToken;
        address baseToken;
        uint256 fixedRate;
    }

    // maps an exchangeId to an exchange
    mapping(bytes32 => Exchange) private exchanges;
    bytes32[] private exchangeIds;

    modifier onlyActiveExchange(
        bytes32 exchangeId
    )
    {
        require(
            exchanges[exchangeId].fixedRate != 0 &&
            exchanges[exchangeId].active == true,
            'FixedRateExchange: Exchange does not exist!'
        );
        _;
    }

    modifier onlyExchangeOwner(
        bytes32 exchangeId
    )
    {
        require(
            exchanges[exchangeId].exchangeOwner == msg.sender,
            'FixedRateExchange: invalid exchange owner'
        );
        _;
    }

    event ExchangeCreated(
        bytes32 indexed exchangeId,
        address indexed baseToken,
        address indexed dataToken,
        address exchangeOwner,
        uint256 fixedRate
    );

    event ExchangeRateChanged(
        bytes32 indexed exchangeId,
        address indexed exchangeOwner,
        uint256 newRate
    );

    event ExchangeActivated(
        bytes32 indexed exchangeId,
        address indexed exchangeOwner
    );

    event ExchangeDeactivated(
        bytes32 indexed exchangeId,
        address indexed exchangeOwner
    );

    event Swapped(
        bytes32 indexed exchangeId,
        address indexed by,
        uint256 baseTokenSwappedAmount,
        uint256 dataTokenSwappedAmount
    );

    /**
     * @dev create
     *      creates new exchange pairs between base token
     *      (ocean token) and data tokens.
     * @param baseToken refers to a ocean token contract address
     * @param dataToken refers to a data token contract address
     * @param fixedRate refers to the exact fixed exchange rate in wei
     */
    function create(
        address baseToken,
        address dataToken,
        uint256 fixedRate
    )
        external
    {
        require(
            baseToken != address(0),
            'FixedRateExchange: Invalid basetoken,  zero address'
        );
        require(
            dataToken != address(0),
            'FixedRateExchange: Invalid datatoken,  zero address'
        );
        require(
            baseToken != dataToken,
            'FixedRateExchange: Invalid datatoken,  equals basetoken'
        );
        require(
            fixedRate != 0, 
            'FixedRateExchange: Invalid exchange rate value'
        );
        bytes32 exchangeId = generateExchangeId(
            baseToken,
            dataToken,
            msg.sender
        );
        require(
            exchanges[exchangeId].fixedRate == 0,
            'FixedRateExchange: Exchange already exists!'
        );
        exchanges[exchangeId] = Exchange({
            active: true,
            exchangeOwner: msg.sender,
            dataToken: dataToken,
            baseToken: baseToken,
            fixedRate: fixedRate
        });
        exchangeIds.push(exchangeId);

        emit ExchangeCreated(
            exchangeId,
            baseToken,
            dataToken,
            msg.sender,
            fixedRate
        );

        emit ExchangeActivated(
            exchangeId,
            msg.sender
        );
    }

    /**
     * @dev generateExchangeId
     *      creates unique exchange identifier for two token pairs.
     * @param baseToken refers to a ocean token contract address
     * @param dataToken refers to a data token contract address
     * @param exchangeOwner exchange owner address
     */
    function generateExchangeId(
        address baseToken,
        address dataToken,
        address exchangeOwner
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                baseToken,
                dataToken,
                exchangeOwner
            )
        );
    }
    
    /**
     * @dev CalcInGivenOut
     *      Calculates how many basetokens are needed to get specifyed amount of datatokens
     * @param exchangeId a unique exchange idnetifier 
     * @param dataTokenAmount the amount of data tokens to be exchanged
     */
    function CalcInGivenOut(
        bytes32 exchangeId,
        uint256 dataTokenAmount
    )
        public
        view
        onlyActiveExchange(
            exchangeId
        )
        returns (uint256 baseTokenAmount)
    {
        baseTokenAmount = dataTokenAmount.mul(
            exchanges[exchangeId].fixedRate).div(BASE);
    }
    
    /**
     * @dev swap
     *      atomic swap between two registered fixed rate exchange.
     * @param exchangeId a unique exchange idnetifier 
     * @param dataTokenAmount the amount of data tokens to be exchanged
     */
    function swap(
        bytes32 exchangeId,
        uint256 dataTokenAmount
    )
        external
        onlyActiveExchange(
            exchangeId
        )
    {
        require(
            dataTokenAmount != 0,
            'FixedRateExchange: zero data token amount'
        );
        uint256 baseTokenAmount = CalcInGivenOut(exchangeId,dataTokenAmount);
        require(
            IERC20Template(exchanges[exchangeId].baseToken).transferFrom(
                msg.sender,
                exchanges[exchangeId].exchangeOwner,
                baseTokenAmount
            ),
            'FixedRateExchange: transferFrom failed in the baseToken contract'
        );
        require(
            IERC20Template(exchanges[exchangeId].dataToken).transferFrom(
                exchanges[exchangeId].exchangeOwner,
                msg.sender,
                dataTokenAmount
            ),
            'FixedRateExchange: transferFrom failed in the dataToken contract'
        );

        emit Swapped(
            exchangeId,
            msg.sender,
            baseTokenAmount,
            dataTokenAmount
        );
    }

    /**
     * @dev getNumberOfExchanges
     *      gets the total number of registered exchanges
     * @return total number of registered exchange IDs
     */
    function getNumberOfExchanges()
        external
        view
        returns (uint256)
    {
        return exchangeIds.length;
    }

    /**
     * @dev setRate
     *      changes the fixed rate for an exchange with a new rate
     * @param exchangeId a unique exchange idnetifier
     * @param newRate new fixed rate value
     */
    function setRate(
        bytes32 exchangeId,
        uint256 newRate
    )
        external
        onlyExchangeOwner(exchangeId)
    {
        require(
            newRate != 0,
            'FixedRateExchange: Ratio must be >0'
        );

        exchanges[exchangeId].fixedRate = newRate;
        emit ExchangeRateChanged(
            exchangeId,
            msg.sender,
            newRate
        );
    }

     /**
     * @dev toggleExchangeState
     *      toggles the active state of an existing exchange
     * @param exchangeId a unique exchange idnetifier
     */
    function toggleExchangeState(
        bytes32 exchangeId
    )
        external
        onlyExchangeOwner(exchangeId)
    {
        if(exchanges[exchangeId].active){
            exchanges[exchangeId].active = false;
            emit ExchangeDeactivated(
                exchangeId,
                msg.sender
            );
        } else {
            exchanges[exchangeId].active = true;
            emit ExchangeActivated(
                exchangeId,
                msg.sender
            );
        }
    }

    /**
     * @dev getRate
     *      gets the current fixed rate for an exchange
     * @param exchangeId a unique exchange idnetifier
     * @return fixed rate value
     */
    function getRate(
        bytes32 exchangeId
    )
        external
        view
        returns(uint256)
    {
        return exchanges[exchangeId].fixedRate;
    }

    /**
     * @dev getSupply
     *      gets the current supply of datatokens in an fixed
     *      rate exchagne
     * @param  exchangeId the exchange ID
     * @return supply
     */
    function getSupply(bytes32 exchangeId)
        public
        view
        returns (uint256 supply)
    {
        if(exchanges[exchangeId].active == false)
            supply = 0;
        else {
            uint256 balance = IERC20Template(exchanges[exchangeId].dataToken)
                .balanceOf(exchanges[exchangeId].exchangeOwner);
            uint256 allowance = IERC20Template(exchanges[exchangeId].dataToken)
                .allowance(exchanges[exchangeId].exchangeOwner, address(this));
            if(balance < allowance)
                supply = balance;
            else
                supply = allowance;
        }
    }

    /**
     * @dev getExchange
     *      gets all the exchange details
     * @param exchangeId a unique exchange idnetifier
     * @return all the exchange details including  the exchange Owner
     *         the dataToken contract address, the base token address, the 
     *         fixed rate, whether the exchange is active and the supply or the 
     *         the current data token liquidity.
     */
    function getExchange(
        bytes32 exchangeId
    )
        external
        view
        returns (
            address exchangeOwner,
            address dataToken,
            address baseToken,
            uint256 fixedRate,
            bool active,
            uint256 supply
        )
    {
        Exchange memory exchange = exchanges[exchangeId];
        exchangeOwner = exchange.exchangeOwner;
        dataToken = exchange.dataToken;
        baseToken = exchange.baseToken;
        fixedRate = exchange.fixedRate;
        active = exchange.active;
        supply = getSupply(exchangeId);
    }

    /**
     * @dev getExchanges
     *      gets all the exchanges list
     * @return a list of all registered exchange Ids
     */
    function getExchanges()
        external 
        view 
        returns (bytes32[] memory)
    {
        return exchangeIds;
    }

    /**
     * @dev isActive
     *      checks whether exchange is active
     * @param exchangeId a unique exchange idnetifier
     * @return true if exchange is true, otherwise returns false
     */
    function isActive(
        bytes32 exchangeId
    )
        external
        view
        returns (bool)
    {
        return exchanges[exchangeId].active;
    }
}