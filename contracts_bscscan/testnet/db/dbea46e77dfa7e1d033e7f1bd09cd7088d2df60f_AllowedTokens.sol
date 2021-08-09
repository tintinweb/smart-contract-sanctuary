/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/*
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


interface IAllowedTokens {
    function getPrice(address token) external view returns (int256);

    function getTokens() external view returns (address[] memory);

    function countTokens() external view returns (uint256);

    function existToken(address token) external view returns (bool);

    function getPriceDecimals(address token)
        external
        view
        returns (uint8 decimals);

    function getOneTokenInWei(address token) external view returns (uint256);

    function amountInUSDToAmountInToken(address token, uint256 amountInUSD)
        external
        view
        returns (uint256 tokenInWei);

    function amountInTokenToAmountInUSD(address token, uint256 amountInWei)
        external
        view
        returns (uint256 tokenInUSD);
}


contract AllowedTokens is IAllowedTokens, Ownable {
    mapping(address => AggregatorV3Interface) internal priceInterface;

    address[] private tokens;
    mapping(address => bool) isToken;
    mapping(address => uint256) tokenWei;

    modifier onlyToken(address token) {
        require(isToken[token], "Permission: only accepted token");
        _;
    }

    function _getPrice(address token) internal view returns (int256) {
        (, int256 price, , , ) = priceInterface[token].latestRoundData();

        return price;
    }

    function getPrice(address token)
        external
        view
        override
        onlyToken(token)
        returns (int256)
    {
        return _getPrice(token);
    }

    function getPriceDecimals(address token)
        external
        view
        override
        onlyToken(token)
        returns (uint8 decimals)
    {
        return priceInterface[token].decimals();
    }

    function getTokens() external view override returns (address[] memory) {
        return tokens;
    }

    function _countTokens() internal view returns (uint256) {
        return tokens.length;
    }

    function countTokens() external view override returns (uint256) {
        return _countTokens();
    }

    function existToken(address token) external view override returns (bool) {
        uint256 tokensLength = _countTokens();
        for (uint256 i = 0; i < tokensLength; i++) {
            if (tokens[i] == token) return true;
        }
        return false;
    }

    function _getOneTokenInWei(address token) internal view returns (uint256) {
        return tokenWei[token];
    }

    function getOneTokenInWei(address token)
        external
        view
        override
        onlyToken(token)
        returns (uint256)
    {
        return _getOneTokenInWei(token);
    }

    function add(
        address token,
        address chainlinkProxy,
        uint256 weiUnit
    ) public onlyOwner {
        require(
            token != address(0) && isToken[token] == false,
            "token invalid or already set"
        );
        isToken[token] = true;

        tokens.push(token);
        priceInterface[token] = AggregatorV3Interface(chainlinkProxy);
        tokenWei[token] = weiUnit;
    }

    function amountInUSDToAmountInToken(address token, uint256 amountInUSD)
        external
        view
        override
        onlyToken(token)
        returns (uint256 tokenInWei)
    {
        require(amountInUSD > 0, "Required: amount is zero");
        int256 price = _getPrice(token);

        uint256 oneTokenInWei = _getOneTokenInWei(token);
        return (amountInUSD * oneTokenInWei) / uint256(price);
    }

    function amountInTokenToAmountInUSD(address token, uint256 amountInWei)
        external
        view
        override
        onlyToken(token)
        returns (uint256 tokenInUSD)
    {
        require(amountInWei > 0, "Required: amount is zero");
        int256 price = _getPrice(token);

        uint256 oneTokenInWei = _getOneTokenInWei(token);
        return (amountInWei * uint256(price)) / oneTokenInWei;
    }
}