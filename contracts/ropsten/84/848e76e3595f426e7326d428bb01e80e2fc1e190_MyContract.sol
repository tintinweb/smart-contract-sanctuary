/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

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

interface IConverterAnchor is IOwned {

}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IConverter is IOwned {
    function converterType() external pure returns (uint16);

    function anchor() external view returns (IConverterAnchor);

    function isActive() external view returns (bool);

    function targetAmountAndFee(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount
    ) external view returns (uint256, uint256);

    function convert(
        IERC20 _sourceToken,
        IERC20 _targetToken,
        uint256 _amount,
        address _trader,
        address payable _beneficiary
    ) external payable returns (uint256);

    function conversionFee() external view returns (uint32);

    function maxConversionFee() external view returns (uint32);

    function reserveBalance(IERC20 _reserveToken) external view returns (uint256);

    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;

    function acceptAnchorOwnership() external;

    function setConversionFee(uint32 _conversionFee) external;

    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function withdrawETH(address payable _to) external;

    function addReserve(IERC20 _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);

    function transferTokenOwnership(address _newOwner) external;

    function acceptTokenOwnership() external;

    function connectors(IERC20 _address)
        external
        view
        returns (
            uint256,
            uint32,
            bool,
            bool,
            bool
        );

    function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);

    function connectorTokens(uint256 _index) external view returns (IERC20);

    function connectorTokenCount() external view returns (uint16);

    /**
     * @dev triggered when the converter is activated
     *
     * @param _type        converter type
     * @param _anchor      converter anchor
     * @param _activated   true if the converter was activated, false if it was deactivated
     */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
     * @dev triggered when a conversion between two tokens occurs
     *
     * @param _fromToken       source ERC20 token
     * @param _toToken         target ERC20 token
     * @param _trader          wallet that initiated the trade
     * @param _amount          input amount in units of the source token
     * @param _return          output amount minus conversion fee in units of the target token
     * @param _conversionFee   conversion fee in units of the target token
     */
    event Conversion(
        IERC20 indexed _fromToken,
        IERC20 indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
     * @dev triggered when the rate between two tokens in the converter changes
     * note that the event might be dispatched for rate updates between any two tokens in the converter
     *
     * @param  _token1 address of the first token
     * @param  _token2 address of the second token
     * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
     * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
     */
    event TokenRateUpdate(IERC20 indexed _token1, IERC20 indexed _token2, uint256 _rateN, uint256 _rateD);

    /**
     * @dev triggered when the conversion fee is updated
     *
     * @param  _prevFee    previous fee percentage, represented in ppm
     * @param  _newFee     new fee percentage, represented in ppm
     */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);
}

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

interface IContractRegistry {
    function addressOf(
        bytes32 contractName
    ) external returns(address);
}

interface IConverterRegistry {
    function newConverter (
        uint16 _type,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint32 _maxConversionFee,
        IERC20Token[] memory _reserveTokens,
        uint32[] memory _reserveWeights
    ) external returns (IConverter);
}

contract MyContract {
    
    bytes32 converterRegistryName = 'BancorConverterRegistry';
    
    function deployNewConverter(
        uint16 _type,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint32 _maxConversionFee,
        IERC20Token[] memory _reserveTokens,
        uint32[] memory _reserveWeights 
    ) external returns(address) {
        //IContractRegistry contractRegistry = IContractRegistry(contractRegistry);
        //address converterRegistry = contractRegistry.addressOf(converterRegistryName);
        IConverter converter = IConverterRegistry(0xFD95E724962fCfC269010A0c6700Aa09D5de3074).newConverter(
            _type,
            _name,
            _symbol,
            _decimals,
            _maxConversionFee,
            _reserveTokens,
            _reserveWeights
        );
        return address(converter);
    }
}