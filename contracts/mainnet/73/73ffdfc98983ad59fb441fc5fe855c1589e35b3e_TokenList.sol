/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: contracts/ownership/Ownable.sol

pragma solidity <6.0 >=0.4.0;


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// File: contracts/iotube/UniqueAppendOnlyAddressList.sol

pragma solidity <6.0 >=0.4.24;


contract UniqueAppendOnlyAddressList is Ownable {
    struct ExistAndActive {
        bool exist;
        bool active;
    }
    uint256 internal num;
    address[] internal items;
    mapping(address => ExistAndActive) internal existAndActives;

    function count() public view returns (uint256) {
        return items.length;
    }

    function numOfActive() public view returns (uint256) {
        return num;
    }

    function isExist(address _item) public view returns (bool) {
        return existAndActives[_item].exist;
    }

    function isActive(address _item) public view returns (bool) {
        return existAndActives[_item].active;
    }

    function activateItem(address _item) internal returns (bool) {
        if (existAndActives[_item].active) {
            return false;
        }
        if (!existAndActives[_item].exist) {
            items.push(_item);
        }
        num++;
        existAndActives[_item] = ExistAndActive(true, true);
        return true;
    }

    function deactivateItem(address _item) internal returns (bool) {
        if (existAndActives[_item].exist && existAndActives[_item].active) {
            num--;
            existAndActives[_item].active = false;
            return true;
        }
        return false;
    }

    function getActiveItems(uint256 offset, uint8 limit) public view returns (uint256 count_, address[] memory items_) {
        require(offset < items.length && limit != 0);
        items_ = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (offset + i >= items.length) {
                break;
            }
            if (existAndActives[items[offset + i]].active) {
                items_[count_] = items[offset + i];
                count_++;
            }
        }
    }
}
// File: contracts/iotube/TokenList.sol

pragma solidity <6.0 >=0.4.24;



contract TokenList is Ownable, UniqueAppendOnlyAddressList {
    event TokenAdded(address indexed token, uint256 minAmount, uint256 maxAmount);
    event TokenUpdated(address indexed token, uint256 minAmount, uint256 maxAmount);
    event TokenRemoved(address indexed token);

    struct Setting {
        uint256 minAmount;
        uint256 maxAmount;
    }

    mapping(address => Setting) private settings;

    function isAllowed(address _token) public view returns (bool) {
        return isActive(_token);
    }

    function addToken(address _token, uint256 _min, uint256 _max) public onlyOwner returns (bool success_) {
        if (activateItem(_token)) {
            require(_min > 0 && _max > _min, "invalid parameters");
            settings[_token] = Setting(_min, _max);
            emit TokenAdded(_token, _min, _max);
            success_ = true;
        }
    }

    function addTokens(address[] memory _tokens, uint256[] memory _mins, uint256[] memory _maxs) public onlyOwner returns (bool success_) {
        require(_tokens.length == _mins.length && _mins.length == _maxs.length, "invalid parameters");
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (addToken(_tokens[i], _mins[i], _maxs[i])) {
                success_ = true;
            }
        }
    }

    function removeToken(address _token) public onlyOwner returns (bool success_) {
        if (deactivateItem(_token)) {
            emit TokenRemoved(_token);
            success_ = true;
        }
    }

    function setMinAmount(address _token, uint256 _minAmount) public onlyOwner {
        require(isExist(_token), "token not added");
        require(settings[_token].maxAmount >= _minAmount);
        require(_minAmount > 0);
        settings[_token].minAmount = _minAmount;
    }

    function setMaxAmount(address _token, uint256 _maxAmount) public onlyOwner {
        require(isExist(_token), "token not added");
        require(_maxAmount >= settings[_token].minAmount);
        settings[_token].maxAmount = _maxAmount;
    }

    function minAmount(address _token) public view returns (uint256 minAmount_) {
        if (isExist(_token)) {
            minAmount_ = settings[_token].minAmount;
        }
    }

    function maxAmount(address _token) public view returns (uint256 maxAmount_) {
        if (isExist(_token)) {
            maxAmount_ = settings[_token].maxAmount;
        }
    }

}