//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

import './BEP20.sol';
import './RoundMath.sol';
import './DateLib.sol';
import './SafeMath.sol';

abstract contract SwapInterface {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address who) external view virtual returns (uint256);

    function mintFromRise(address to, uint256 value) public virtual returns (bool);

    function burnFromRise(address tokensOwner, uint256 value) external virtual returns (bool);
}

contract CentricRise is BEP20 {
    using RoundMath for uint256;
    using DateLib for uint256;
    using SafeMath for uint256;

    /**
     * STATE VARIABLES
     */
    address public swapContract;
    uint256 public quarantineBalance;
    uint256 public lastBlockNumber; // number of last created block
    uint256 public lastBalancedHour;

    // Price of Rise in USD has base of PRICE_BASE
    uint256 constant PRICE_BASE = 10**8;

    // Inital price of Rise in USD
    uint256 constant INITIAL_PRICE = 8302083331; // first block to mint is 450895 - $83.04040810

    // Structure of a Price Block
    struct Block {
        uint256 risePrice; // USD price of Rise for the block
        uint256 growthRate; // FutureGrowthRate value at the time of block creation
        //solium-disable-next-line max-len
        uint256 change; // percentage (base of PRICE_BASE), RisePrice change relative to prev. block
        uint256 created; // hours, Unix epoch time
    }

    // Price Blocks for a given hour (number of hours since epoch time)
    mapping(uint256 => Block) public hoursToBlock;

    /**
     * Price factors for months with [28, 29, 30, 31] days,
     * price factors determine compounding hourly growth
     * from the headling monthly growthRate,
     * calculated as (1+r)^(1/t)-1
     * where:
     * r - growthRate,
     * t - number of hours in a given month
     *
     * e.g.: for growthRate=2850 (2850/GROWTH_RATE_BASE=0.285=28.5%)
     * price factors are (considering PRICE_FACTOR_BASE): [37322249, 36035043, 34833666, 33709810]
     */
    mapping(uint256 => uint256[4]) public growthRateToPriceFactors;
    uint256 constant GROWTH_RATE_BASE = 10**4;
    uint256 constant PRICE_FACTOR_BASE = 10**11;

    bool public priceFactorsLocked = false;

    event DoBalance(uint256 indexed currentHour, uint256 riseAmountBurnt);

    event ConvertToSwap(
        address indexed converter,
        uint256 riseAmountSent,
        uint256 swapAmountReceived
    );

    event ConvertToRise(
        address indexed converter,
        uint256 swapAmountSent,
        uint256 riseAmountReceived
    );

    event MintSwap(address receiver, uint256 amount);

    event BurnSwap(uint256 amountBurnt);

    event PriceFactorSet(
        uint256 growthRate,
        uint256 priceFactor0,
        uint256 priceFactor1,
        uint256 priceFactor2,
        uint256 priceFactor3
    );

    event BlockCreated(
        uint256 blockNumber,
        uint256 risePrice,
        uint256 growthRate,
        uint256 change,
        uint256 created
    );

    event QuarantineBalanceBurnt(uint256 amount);

    event LostTokensBurnt(uint256 amount);

    /**
     * Creates Rise contract. Also sets the Swap address
     * to the contract storage to be able to interact with it.
     * Mints 1 billion tokens to _mintSaver address.
     */
    constructor(address _mintSaver, address _swapContract) BEP20('Centric RISE', 'CNR', 8) {
        _mint(_mintSaver, 100000000000000000); // 1 Billion
        swapContract = _swapContract;
    }

    // Returns price of Rise for the current hour
    function getCurrentPrice() external view returns (uint256) {
        require(hoursToBlock[getCurrentHour()].risePrice > 0, 'BLOCK_NOT_DEFINED');
        return hoursToBlock[getCurrentHour()].risePrice;
    }

    // Returns price of Rise at a specified hour
    function getPrice(uint256 _hour) external view returns (uint256) {
        require(hoursToBlock[_hour].risePrice > 0, 'BLOCK_NOT_DEFINED');
        return hoursToBlock[_hour].risePrice;
    }

    /**
     *  Returns Price Block data
     *  uint256 risePrice;     // USD price of Rise for the block
     *  uint256 growthRate;    // growthRate value of the risePrice
     *  uint256 change;        // percentage (base of PRICE_BASE), RisePrice change relative to prev. block
     *  uint256 created;       // hours, unix epoch time
     */
    function getBlockData(uint256 _hoursEpoch)
        external
        view
        returns (
            uint256 _risePrice,
            uint256 _growthRate,
            uint256 _change,
            uint256 _created
        )
    {
        require(_hoursEpoch > 0, 'EMPTY_HOURS_VALUE');
        require(hoursToBlock[_hoursEpoch].risePrice > 0, 'BLOCK_NOT_DEFINED');

        _risePrice = hoursToBlock[_hoursEpoch].risePrice;
        _growthRate = hoursToBlock[_hoursEpoch].growthRate;
        _change = hoursToBlock[_hoursEpoch].change;
        _created = hoursToBlock[_hoursEpoch].created;

        return (_risePrice, _growthRate, _change, _created);
    }

    /**
     * Single call creates ONE Price Block with specified monthly _growthRate.
     * For creating a batch of blocks function needs to be run according amount of times.
     * Admin should always make sure that there is a block for the currentHour
     * and if not - create it. Otherwise users will not be able to convert tokens
     * until a new block is created.
     * _blockNumber - always has to be lastBlockNumber + 1 (works only as a security check)
     * _growthRate - must be specified in growthRateToPriceFactors
     * percentage (fraction of 1, e.g.: 0.3)
     * presented as integer with base of GROWTH_RATE_BASE (to be divided by GROWTH_RATE_BASE to get a fraction of 1)
     */
    function doCreateBlock(uint256 _blockNumber, uint256 _growthRate)
        external
        onlyAdmin()
        returns (bool _success)
    {
        require(priceFactorsLocked, 'PRICE_FACTORS_MUST_BE_LOCKED');

        require(_growthRate != 0, 'GROWTH_RATE_CAN_NOT_BE_ZERO');
        require(_growthRate < GROWTH_RATE_BASE, 'GROWTH_RATE_IS_GREATER_THAN_GROWTH_RATE_BASE');
        require(growthRateToPriceFactors[_growthRate][0] > 0, 'GROWTH_RATE_IS_NOT_SPECIFIED');

        require(_createBlock(_blockNumber, _growthRate), 'FAILED_TO_CREATE_BLOCK');
        return true;
    }

    /**
     * set growthRateToPriceFactors
     * _priceFactors - see comments for mapping growthRateToPriceFactors
     */
    function setPriceFactors(uint256 _growthRate, uint256[4] memory _priceFactors)
        external
        onlyAdmin()
        returns (bool _success)
    {
        require(priceFactorsLocked == false, 'PRICE_FACTORS_ALREADY_LOCKED');

        require(_growthRate != 0, 'GROWTH_RATE_CAN_NOT_BE_ZERO');
        require(_growthRate < GROWTH_RATE_BASE, 'GROWTH_RATE_IS_GREATER_THAN_GROWTH_RATE_BASE');

        require(_priceFactors[0] > 0, 'PRICE_FACTOR_0_CAN_NOT_BE_ZERO');
        require(_priceFactors[0] < 103200117, 'PRICE_FACTOR_0_IS_TOO_BIG');
        require(_priceFactors[1] > 0, 'PRICE_FACTOR_1_CAN_NOT_BE_ZERO');
        require(_priceFactors[1] < 99639720, 'PRICE_FACTOR_1_IS_TOO_BIG');
        require(_priceFactors[2] > 0, 'PRICE_FACTOR_2_CAN_NOT_BE_ZERO');
        require(_priceFactors[2] < 96316797, 'PRICE_FACTOR_2_IS_TOO_BIG');
        require(_priceFactors[3] > 0, 'PRICE_FACTOR_3_CAN_NOT_BE_ZERO');
        require(_priceFactors[3] < 93208356, 'PRICE_FACTOR_3_IS_TOO_BIG');

        require(
            _priceFactors[0] > _priceFactors[1] &&
                _priceFactors[1] > _priceFactors[2] &&
                _priceFactors[2] > _priceFactors[3],
            'PRICE_FACTORS_ARE_NOT_VALID'
        );

        growthRateToPriceFactors[_growthRate] = _priceFactors;

        emit PriceFactorSet(
            _growthRate,
            _priceFactors[0],
            _priceFactors[1],
            _priceFactors[2],
            _priceFactors[3]
        );
        return true;
    }

    /**
     * Call only after all priceFactors have been set
     * Call before creating first block
     */
    function lockPriceFactors() external onlyAdmin() returns (bool _success) {
        priceFactorsLocked = true;
        return true;
    }

    /**
     * Public function that burns Rise from quarantine
     * according to the burnQuarantine() formula.
     * Needed for economic logic of Rise token.
     */
    function doBalance() external returns (bool _success) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');
        require(lastBalancedHour < getCurrentHour(), 'CHANGE_IS_ALREADY_BURNT_IN_THIS_HOUR');

        lastBalancedHour = getCurrentHour();

        uint256 _riseBurnt = _burnQuarantined();

        emit DoBalance(getCurrentHour(), _riseBurnt);
        return true;
    }

    /**
     * Public function that allows users to convert Swap tokens to Rise ones.
     * Amount of received Rise tokens depends on the risePrice of the current block.
     */
    function convertToRise(uint256 _swapAmount) external returns (bool _success) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');

        require(
            SwapInterface(swapContract).balanceOf(msg.sender) >= _swapAmount,
            'INSUFFICIENT_SWAP_BALANCE'
        );

        require(
            SwapInterface(swapContract).burnFromRise(msg.sender, _swapAmount),
            'BURNING_SWAP_FAILED'
        );

        emit BurnSwap(_swapAmount);

        uint256 _riseToDequarantine =
            (_swapAmount.mul(PRICE_BASE)).div(hoursToBlock[getCurrentHour()].risePrice);

        quarantineBalance = quarantineBalance.sub(_riseToDequarantine);
        require(this.transfer(msg.sender, _riseToDequarantine), 'CONVERT_TO_RISE_FAILED');

        emit ConvertToRise(msg.sender, _swapAmount, _riseToDequarantine);
        return true;
    }

    /**
     * Public function that allows users to convert Rise tokens to Swap ones.
     * Amount of received Swap tokens depends on the risePrice of a current block.
     */
    function convertToSwap(uint256 _riseAmount) external returns (uint256) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');

        require(balanceOf(msg.sender) >= _riseAmount, 'INSUFFICIENT_RISE_BALANCE');

        quarantineBalance = quarantineBalance.add(_riseAmount);
        require(transfer(address(this), _riseAmount), 'RISE_TRANSFER_FAILED');

        uint256 _swapToIssue =
            (_riseAmount.mul(hoursToBlock[getCurrentHour()].risePrice)).div(PRICE_BASE);

        require(
            SwapInterface(swapContract).mintFromRise(msg.sender, _swapToIssue),
            'SWAP_MINT_FAILED'
        );

        emit MintSwap(msg.sender, _swapToIssue);

        emit ConvertToSwap(msg.sender, _riseAmount, _swapToIssue);
        return _swapToIssue;
    }

    /**
     * Function is needed to burn lost tokens that probably were sent
     * to the contract address by mistake.
     */
    function burnLostTokens() external onlyContractOwner() returns (bool _success) {
        uint256 _amount = balanceOf(address(this)).sub(quarantineBalance);

        _burn(address(this), _amount);

        emit LostTokensBurnt(_amount);
        return true;
    }

    /**
     * Internal function that implements logic to burn a part of Rise tokens on quarantine.
     * Formula is based on network capitalization rules -
     * Network capitalization of quarantined Rise must be equal to
     * network capitalization of Swap
     * calculated as (q * pRISE - c * pSWAP) / pRISE
     * where:
     * q - quarantined Rise,
     * pRISE - current risePrice
     * c - current swap supply
     * pSwap - Swap pegged price ($1 USD fixed conversion price)
     */
    function _burnQuarantined() internal returns (uint256) {
        uint256 _quarantined = quarantineBalance;
        uint256 _currentPrice = hoursToBlock[getCurrentHour()].risePrice;
        uint256 _swapSupply = SwapInterface(swapContract).totalSupply();

        uint256 _riseToBurn =
            ((((_quarantined.mul(_currentPrice)).div(PRICE_BASE)).sub(_swapSupply)).mul(PRICE_BASE))
                .div(_currentPrice);

        quarantineBalance = quarantineBalance.sub(_riseToBurn);
        _burn(address(this), _riseToBurn);

        emit QuarantineBalanceBurnt(_riseToBurn);
        return _riseToBurn;
    }

    /**
     * Internal function for creating a new Price Block.
     */
    function _createBlock(uint256 _expectedBlockNumber, uint256 _growthRate)
        internal
        returns (bool _success)
    {
        uint256 _lastPrice;
        uint256 _nextBlockNumber;

        if (lastBlockNumber == 0) {
            require(_expectedBlockNumber > getCurrentHour(), 'FIRST_BLOCK_MUST_BE_IN_THE_FUTURE');
            require(
                _expectedBlockNumber < getCurrentHour() + 365 * 24,
                'FIRST_BLOCK_MUST_BE_WITHIN_ONE_YEAR'
            );
            _lastPrice = INITIAL_PRICE;
            _nextBlockNumber = _expectedBlockNumber;
        } else {
            _lastPrice = hoursToBlock[lastBlockNumber].risePrice;
            _nextBlockNumber = lastBlockNumber.add(1);
        }

        require(_nextBlockNumber == _expectedBlockNumber, 'WRONG_BLOCK_NUMBER');

        uint256 _risePriceFactor;

        uint256 _monthBlocks = (_nextBlockNumber * 60 * 60 * 1000).getHoursInMonth();
        if (_monthBlocks == 28 * 24) _risePriceFactor = growthRateToPriceFactors[_growthRate][0];
        else if (_monthBlocks == 29 * 24)
            _risePriceFactor = growthRateToPriceFactors[_growthRate][1];
        else if (_monthBlocks == 30 * 24)
            _risePriceFactor = growthRateToPriceFactors[_growthRate][2];
        else _risePriceFactor = growthRateToPriceFactors[_growthRate][3];

        uint256 _risePrice =
            ((_risePriceFactor.mul(_lastPrice)).add(_lastPrice.mul(PRICE_FACTOR_BASE))).ceilDiv(
                PRICE_FACTOR_BASE
            );

        uint256 _change = (_risePrice.sub(_lastPrice)).mul(PRICE_BASE).roundDiv(_lastPrice);
        uint256 _created = getCurrentHour();

        hoursToBlock[_nextBlockNumber] = Block({
            risePrice: _risePrice,
            growthRate: _growthRate,
            change: _change,
            created: _created
        });

        lastBlockNumber = _nextBlockNumber;

        emit BlockCreated(_nextBlockNumber, _risePrice, _growthRate, _change, _created);
        return true;
    }

    // For testing purposes
    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    // Helper function
    function getCurrentHour() public view returns (uint256) {
        return getCurrentTime().div(1 hours);
    }
}