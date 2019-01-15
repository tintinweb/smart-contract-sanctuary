pragma solidity 0.4.24;


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


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract EternalStorageInterface {
    function getShipById(uint256 _shipId) public view returns(uint256, string, uint256, uint256, uint256);
    function buyItem(uint256 _itemId, address _newOwner, string _itemTitle, string _itemTypeTitle, string _itemIdTitle) public returns(uint256);
    function getItemPriceById(string _itemType, uint256 _itemId) public view returns(uint256);
    function getNumberOfItemsByTypeAndOwner(string _itemType, address _owner) public view returns(uint256);
    function getItemsByTypeAndOwner(string _itemTypeTitle, address _owner) public view returns(uint256[]);
    function getItemsIdsByTypeAndOwner(string _itemIdsTitle, address _owner) public view returns(uint256[]);
    function getOwnerByItemTypeAndId(string _itemType, uint256 _itemId) public view returns(address);
    function setNewPriceToItem(string _itemType, uint256 _itemTypeId, uint256 _newPrice) public;
    function addReferrer(address _referrerWalletAddress, uint256 referrerPrize) public;
    function widthdrawRefunds(address _referrerWalletAddress) public returns(uint256);
    function checkRefundExistanceByOwner(address _ownerAddress) public view returns(uint256);
}


contract ItemsStorageInterface {
    function getShipsIds() public view returns(uint256[]);
    function getRadarsIds() public view returns(uint256[]);
    function getScannersIds() public view returns(uint256[]);
    function getDroidsIds() public view returns(uint256[]);
    function getFuelsIds() public view returns(uint256[]);
    function getGeneratorsIds() public view returns(uint256[]);
    function getEnginesIds() public view returns(uint256[]);
    function getGunsIds() public view returns(uint256[]);
    function getMicroModulesIds() public view returns(uint256[]);
    function getArtefactsIds() public view returns(uint256[]);

    function getUsersShipsIds() public view returns(uint256[]);
    function getUsersRadarsIds() public view returns(uint256[]);
    function getUsersScannersIds() public view returns(uint256[]);
    function getUsersDroidsIds() public view returns(uint256[]);
    function getUsersEnginesIds() public view returns(uint256[]);
    function getUsersFuelsIds() public view returns(uint256[]);
    function getUsersGeneratorsIds() public view returns(uint256[]);
    function getUsersGunsIds() public view returns(uint256[]);
    function getUsersMicroModulesIds() public view returns(uint256[]);
    function getUsersArtefactsIds() public view returns(uint256[]);
}

contract LogicContract is Ownable {

    /* ------ EVENTS ------ */

    event ShipWasBought(uint256 shipId);

    EternalStorageInterface private eternalStorageContract;
    ItemsStorageInterface private itemsStorageContract;

    constructor() public {
        eternalStorageContract = EternalStorageInterface(0x89eB6e29d81B98A4b88111e0d82924E6CBDc4AE4);
        itemsStorageContract = ItemsStorageInterface(0xf1fd447DAc5AbEAba356cD0010Bac95daA37C265);
    }

    /* ------ MODIFIERS ------ */

    modifier addressIsNotNull(address _newOwner) {
		require(_newOwner != address(0));
		_;
	}

    /* ------ FUNCTIONALITY FUNCTIONS ------ */

    function destroyLogicContract() public onlyOwner {
        selfdestruct(0xd135377eB20666725D518c967F23e168045Ee11F);
    }

    // Buying new ship
	function buyShip(uint256 _shipId, address _referrerWalletAddress) public payable addressIsNotNull(msg.sender)  {
        uint256 referrerPrize = 0;

        uint256 price = eternalStorageContract.getItemPriceById("ships", _shipId);
        require(msg.value == price);

        if (_referrerWalletAddress != address(0) && _referrerWalletAddress != msg.sender && price > 0) {
            referrerPrize = SafeMath.div(price, 10);
            if (referrerPrize < price) {
                eternalStorageContract.addReferrer(_referrerWalletAddress, referrerPrize);
            }
        }

        _buyShip(_shipId, msg.sender);
	}

    function _buyShip(uint256 _shipId, address _newOwner) private {
        uint256 myShipId = eternalStorageContract.buyItem(_shipId, _newOwner, "ship", "ship_types", "ship_ids");
        emit ShipWasBought(myShipId);
    }

    function withdrawRefund() external addressIsNotNull(msg.sender) {
        uint256 curRefVal = eternalStorageContract.checkRefundExistanceByOwner(msg.sender);
        if (curRefVal > 0 && address(this).balance > curRefVal && SafeMath.sub(address(this).balance, curRefVal) > 0) {
            uint256 refund = eternalStorageContract.widthdrawRefunds(msg.sender);
            msg.sender.transfer(refund);
        }
    }

    function checkRefundExistanceByOwner() external addressIsNotNull(msg.sender) view returns(uint256) {
        return eternalStorageContract.checkRefundExistanceByOwner(msg.sender);
    }

    /* ------ READING METHODS FOR USERS ITEMS ------ */

    function getNumberOfShipsByOwner() public view returns(uint256) {
        return eternalStorageContract.getNumberOfItemsByTypeAndOwner("ship", msg.sender);
    }

    function getShipsByOwner() public view returns(uint256[]) {
        return eternalStorageContract.getItemsByTypeAndOwner("ship_types", msg.sender);
    }
    
    function getShipIdsByOwner() public view returns(uint256[]) {
        return eternalStorageContract.getItemsIdsByTypeAndOwner("ship_ids", msg.sender);
    }

    function getOwnerByShipId(uint256 _shipId) public view returns(address) {
        return eternalStorageContract.getOwnerByItemTypeAndId("ship", _shipId);
    }

    /* ------ READING METHODS FOR ALL USERS ITEMS ------ */

    // Ships
    function getUsersShipsIds() public view returns(uint256[]) {
        return itemsStorageContract.getUsersShipsIds();
    }

    /* ------ READING METHODS FOR ALL ITEMS ------ */

    // Get item price
    function getShipPriceById(uint256 _shipId) public view returns(uint256) {
        return eternalStorageContract.getItemPriceById("ships", _shipId);
    }

    // Ships
    function getShipsIds() public view returns(uint256[]) {
        return itemsStorageContract.getShipsIds();
    }

    function getShipById(uint256 _shipId) public view returns(
        uint256,
        string,
        uint256,
        uint256,
        uint256
    ) {
        return eternalStorageContract.getShipById(_shipId);
    }

    /* ------ DEV FUNCTIONS ------ */

    function getBalanceOfLogicContract() public onlyOwner view returns(uint256) {
        return address(this).balance;
    }

    function getPayOut() public onlyOwner returns(uint256) {
		_getPayOut();
	}

	function _getPayOut() private returns(uint256){
		if (msg.sender != address(0)) {
			msg.sender.transfer(address(this).balance);
            return address(this).balance;
		}
	}

    function setNewPriceToItem(string _itemType, uint256 _itemTypeId, uint256 _newPrice) public onlyOwner {
        eternalStorageContract.setNewPriceToItem(_itemType, _itemTypeId, _newPrice);
    }
}