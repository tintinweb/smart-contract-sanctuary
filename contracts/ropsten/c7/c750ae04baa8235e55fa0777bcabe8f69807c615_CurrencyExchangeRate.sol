pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title Currency exchange rate contract
 */
contract CurrencyExchangeRate is Ownable {

    struct Currency {
        uint256 exRateToEther; // Exchange rate: currency to Ether
        uint8 exRateDecimals;  // Exchange rate decimals
    }

    Currency[] public currencies;

    event CurrencyExchangeRateAdded(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    event CurrencyExchangeRateSet(
        address indexed setter, uint256 index, uint256 rate, uint256 decimals
    );

    constructor() public {
        // Add Ether to index 0
        currencies.push(
            Currency ({
                exRateToEther: 1,
                exRateDecimals: 0
            })
        );
        // Add USD to index 1
        currencies.push(
            Currency ({
                exRateToEther: 30000,
                exRateDecimals: 2
            })
        );
    }

    function addCurrencyExchangeRate(
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateAdded(
            msg.sender, currencies.length, _exRateToEther, _exRateDecimals);
        currencies.push(
            Currency ({
                exRateToEther: _exRateToEther,
                exRateDecimals: _exRateDecimals
            })
        );
    }

    function setCurrencyExchangeRate(
        uint256 _currencyIndex,
        uint256 _exRateToEther, 
        uint8 _exRateDecimals
    ) external onlyOwner {
        emit CurrencyExchangeRateSet(
            msg.sender, _currencyIndex, _exRateToEther, _exRateDecimals);
        currencies[_currencyIndex].exRateToEther = _exRateToEther;
        currencies[_currencyIndex].exRateDecimals = _exRateDecimals;
    }
}