pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
 * @title Base contract for Libre oracles.
 *
 * @dev Base contract for Libre oracles. Not abstract.
 */
contract OwnOracle is Ownable {
    event NewOraclizeQuery();
    event PriceTicker(uint256 rateAmount);
    event BankSet(address bank);
    event UpdaterSet(address updater);

    bytes32 public oracleName = "LibreOracle Omega";
    bytes16 public oracleType = "Libre ETHUSD";
    uint256 public updateTime;
    uint256 public callbackTime;
    address public bankAddress;
    uint256 public rate;
    uint256 public requestPrice = 0;
    bool public waitQuery = false;
    address public updaterAddress;

    modifier onlyBank() {
        require(msg.sender == bankAddress);
        _;
    }

    /**
     * @dev Sets bank address.
     * @param bank Address of the bank contract.
     */
    function setBank(address bank) public onlyOwner {
        bankAddress = bank;
        BankSet(bankAddress);
    }

    /**
     * @dev Sets updateAddress address.
     * @param updater Address of the updateAddress.
     */
    function setUpdaterAddress(address updater) public onlyOwner {
        updaterAddress = updater;
        UpdaterSet(updaterAddress);
    }

    /**
     * @dev Return price of LibreOracle request.
     */
    function getPrice() view public returns (uint256) {
        return updaterAddress.balance < requestPrice ? requestPrice : 0;
    }

    /**
     * @dev oraclize setPrice.
     * @param _requestPriceWei request price in Wei.
     */
    function setPrice(uint256 _requestPriceWei) public onlyOwner {
        requestPrice = _requestPriceWei;
    }

    /**
     * @dev Requests updating rate from LibreOracle node.
     */
    function updateRate() external onlyBank returns (bool) {
        NewOraclizeQuery();
        updateTime = now;
        waitQuery = true;
        return true;
    }


    /**
    * @dev LibreOracle callback.
    * @param result The callback data as-is (1000$ = 1000).
    */
    function __callback(uint256 result) public {
        require(msg.sender == updaterAddress && waitQuery);
        rate = result;
        callbackTime = now;
        waitQuery = false;
        PriceTicker(result);
    }

    /**
    * @dev Method used for funding LibreOracle updater wallet. 
    */    
    function () public payable {
        updaterAddress.transfer(msg.value);
    }

}