pragma solidity ^0.4.24;

interface IOracle {

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external view returns(uint256);

}

/**
 * @title Interface to MakerDAO Medianizer contract
 */

interface IMedianizer {

    function peek() constant external returns (bytes32, bool);

    function read() constant external returns (bytes32);

    function set(address wat) external;

    function set(bytes12 pos, address wat) external;

    function setMin(uint96 min_) external;

    function setNext(bytes12 next_) external;

    function unset(bytes12 pos) external;

    function unset(address wat) external;

    function poke() external;

    function poke(bytes32) external;

    function compute() constant external returns (bytes32, bool);

    function void() external;

}

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

contract MakerDAOOracle is IOracle, Ownable {

    address public medianizer;
    address public currencyAddress;
    bytes32 public currencySymbol;

    bool public manualOverride;
    uint256 public manualPrice;

    event ChangeMedianizer(address _newMedianizer, address _oldMedianizer, uint256 _now);
    event SetManualPrice(uint256 _oldPrice, uint256 _newPrice, uint256 _time);
    event SetManualOverride(bool _override, uint256 _time);

    /**
      * @notice Creates a new Maker based oracle
      * @param _medianizer Address of Maker medianizer
      * @param _currencyAddress Address of currency (0x0 for ETH)
      * @param _currencySymbol Symbol of currency
      */
    constructor (address _medianizer, address _currencyAddress, bytes32 _currencySymbol) public {
        medianizer = _medianizer;
        currencyAddress = _currencyAddress;
        currencySymbol = _currencySymbol;
    }

    /**
      * @notice Updates medianizer address
      * @param _medianizer Address of Maker medianizer
      */
    function changeMedianier(address _medianizer) public onlyOwner {
        require(_medianizer != address(0), "0x not allowed");
        emit ChangeMedianizer(_medianizer, medianizer, now);
        medianizer = _medianizer;
    }

    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address) {
        return currencyAddress;
    }

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32) {
        return currencySymbol;
    }

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32) {
        // All MakerDAO oracles are denominated in USD
        return bytes32("USD");
    }

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external view returns(uint256) {
        if (manualOverride) {
            return manualPrice;
        }
        (bytes32 price, bool valid) = IMedianizer(medianizer).peek();
        require(valid, "MakerDAO Oracle returning invalid value");
        return uint256(price);
    }

    /**
      * @notice Set a manual price. NA - this will only be used if manualOverride == true
      * @param _price Price to set
      */
    function setManualPrice(uint256 _price) public onlyOwner {
        emit SetManualPrice(manualPrice, _price, now);
        manualPrice = _price;
    }

    /**
      * @notice Determine whether manual price is used or not
      * @param _override Whether to use the manual override price or not
      */
    function setManualOverride(bool _override) public onlyOwner {
        manualOverride = _override;
        emit SetManualOverride(_override, now);
    }

}