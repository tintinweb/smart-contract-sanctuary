/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IOracle {
    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address currency);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32 symbol);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32 denominatedCurrency);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external returns(uint256 price);

}

interface IMedianizer {
    function peek() external view returns(bytes32, bool);

    function read() external view returns(bytes32);

    function set(address wat) external;

    function set(bytes12 pos, address wat) external;

    function setMin(uint96 min_) external;

    function setNext(bytes12 next_) external;

    function unset(bytes12 pos) external;

    function unset(address wat) external;

    function poke() external;

    function poke(bytes32) external;

    function compute() external view returns(bytes32, bool);

    function void() external;

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract MakerDAOOracle is IOracle, Ownable {
    IMedianizer public medianizer;
    address public currencyAddress;
    bytes32 public currencySymbol;

    bool public manualOverride;
    uint256 public manualPrice;

    /*solium-disable-next-line security/no-block-members*/
    event ChangeMedianizer(address _newMedianizer, address _oldMedianizer);
    event SetManualPrice(uint256 _oldPrice, uint256 _newPrice);
    event SetManualOverride(bool _override);

    /**
      * @notice Creates a new Maker based oracle
      * @param _medianizer Address of Maker medianizer
      * @param _currencyAddress Address of currency (0x0 for ETH)
      * @param _currencySymbol Symbol of currency
      */
    constructor(address _medianizer, address _currencyAddress, bytes32 _currencySymbol) {
        medianizer = IMedianizer(_medianizer);
        currencyAddress = _currencyAddress;
        currencySymbol = _currencySymbol;
    }

    /**
      * @notice Updates medianizer address
      * @param _medianizer Address of Maker medianizer
      */
    function changeMedianier(address _medianizer) public onlyOwner {
        require(_medianizer != address(0), "0x not allowed");
        /*solium-disable-next-line security/no-block-members*/
        emit ChangeMedianizer(_medianizer, address(medianizer));
        medianizer = IMedianizer(_medianizer);
    }

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view override returns(address) {
        return currencyAddress;
    }

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view override returns(bytes32) {
        return currencySymbol;
    }

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external pure override returns(bytes32) {
        // All MakerDAO oracles are denominated in USD
        return bytes32("USD");
    }

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external view override returns(uint256) {
        if (manualOverride) {
            return manualPrice;
        }
        (bytes32 price, bool valid) = medianizer.peek();
        require(valid, "MakerDAO Oracle returning invalid value");
        return uint256(price);
    }

    /**
      * @notice Set a manual price. NA - this will only be used if manualOverride == true
      * @param _price Price to set
      */
    function setManualPrice(uint256 _price) public onlyOwner {
        /*solium-disable-next-line security/no-block-members*/
        emit SetManualPrice(manualPrice, _price);
        manualPrice = _price;
    }

    /**
      * @notice Determine whether manual price is used or not
      * @param _override Whether to use the manual override price or not
      */
    function setManualOverride(bool _override) public onlyOwner {
        manualOverride = _override;
        /*solium-disable-next-line security/no-block-members*/
        emit SetManualOverride(_override);
    }

}