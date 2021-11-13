/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts\TestGame.sol



pragma solidity ^0.8.0 ;


interface ITestNft {

  struct Member {
    string name;
    uint256 id;
    uint16[5] points;
  }

  function getMember(uint256 _memberId) external view returns (Member memory member);

  function addPoints(uint256 _memberId, uint8 _pointIndex, uint16 _points) external;

  function getPoints(uint256 _memberId, uint8 _pointIndex) external view returns (uint16);

  function ownerOf(uint256 tokenId) external view returns (address);
}

contract TestGame is Ownable {
  constructor(string memory _name) {
    _contract_name = _name;
  }

  // Token name
  string private _contract_name;

  uint256 SALE_COUNTER;

  mapping(uint256 => address) private _sale_creators;

  mapping(address => uint256) private _sale_counter_of;

  mapping(address => uint256) private _last_sale_of;

  mapping(address => uint256) private _TOKEN_BALANCES;

  struct Sale {
    string name;
    uint256 id;
    string icon;
    uint256[5] members;
    uint256[5] managers;
    uint32[12] subtotalPoints;
    // uint8 saleType;
    uint8 launchPad;
    uint32 totalPoints;
    uint32 totalTokens;
    uint16 hardCap;
    uint8 softCapPercent;
    uint8 liquidityPercent;
    uint8 currentStage;
    uint256 stageEndTime;
    bool ended;
  }

  Sale[] public Sales;

  ITestNft public memberContract;

  address public memberContractAddr;

  event NewSale(address indexed owner, uint256 id);

  function name() public view returns (string memory) {
    return _contract_name;
  }

  function setMemberContract(address _addr) external onlyOwner {
    ITestNft _memberContract = ITestNft(_addr);
    memberContract = _memberContract;
    memberContractAddr = _addr;
  }

  function withdraw() external payable onlyOwner {
    address payable _owner = payable(owner());
    _owner.transfer(address(this).balance);
  }

  function createSale(
    string memory _name,
    string memory _icon,
    // uint8 _saleType,
    uint8 _launchPad,
    uint16 _hardCap,
    uint8 _softCapPercent,
    uint8 _liquidityPercent,
    uint256[5] memory _members
  ) external {
    require(msg.sender != address(0), "Sale owner is zero address");
    require(_hardCap > 999 && _hardCap <= 10000, "HardCap 1000 to 10 000 allowed");
    require(_softCapPercent > 9 && _softCapPercent <= 99, "SoftCap 10% to 99% allowed");
    require(_liquidityPercent > 50 && _liquidityPercent <= 99, "Liquidity 51% to 99% allowed");
    require(_lastSaleEnded(msg.sender), "You have an unfinished sale");
    require(_checkMembersOwner(msg.sender, _members), "Invalid members specified");
    _createSale(_name, _icon,
      // _saleType,
      _launchPad, _hardCap, _softCapPercent, _liquidityPercent, _members);
  }

  function nextStage(uint256 _memberId) external {
    require(!_lastSaleEnded(msg.sender), "No active sales");
    Sale storage sale = Sales[_last_sale_of[msg.sender]];
    require(sale.stageEndTime == 0, "Active stage has not ended");
    _nextStage(sale, _memberId);
  }

  function _nextStage(Sale storage sale, uint256 _memberId) internal {
    uint8 stage = sale.currentStage;
    uint32 points = 0;
    if(stage < 9 && (stage == 0 || stage % 2 == 0)) {
      uint8 mIndex = 0;
      if (stage > 0) {
        mIndex = stage / 2;
      }
      require(_checkSaleMember(_memberId, sale.members, 0), "Member does not exist");
      require(mIndex == 0 || !_checkSaleMember(_memberId, sale.managers, mIndex), "Member is already assigned");
      sale.managers[mIndex] = _memberId;
      points += uint32(memberContract.getPoints(_memberId, mIndex));
    } else if (stage < 10) {
      uint8 mIndex = 0;
      if (stage > 2) {
        mIndex = (stage - 1) / 2;
      }
      for (uint256 i = 0; i < sale.members.length; i++) {
        uint256 _saleMemberId = sale.members[i];
        points += uint32(memberContract.getPoints(_saleMemberId, mIndex));
      }
    }
    sale.subtotalPoints[stage] = points;
    sale.totalPoints += points;
    sale.stageEndTime = block.timestamp + 1;
  }

  function finishStage() external {
    _finishStage(msg.sender);
  }

  function finalizePresale() external {
    _finishStage(msg.sender);
  }

  function getMyCurrentSale() public view returns (Sale memory) {
    Sale memory sale = Sales[_last_sale_of[msg.sender]];
    return sale;
  }

  function collectFeeRewards(uint256 _saleId) external {
    require(msg.sender != address(0) && msg.sender == _sale_creators[_saleId], "No sale access");
    Sale storage sale = Sales[_saleId];
    require(sale.ended && sale.stageEndTime > 0, "Rewards already collected");
    require(sale.stageEndTime < block.timestamp, "Stage has not ended");
    uint256 reward = ( ( (uint256(sale.hardCap) - uint256(sale.liquidityPercent) ) / 100 )  * 10 ) / 100;
    sale.stageEndTime = 0;
    sale.totalTokens += uint32(reward);
    _TOKEN_BALANCES[msg.sender] += reward;
  }

  function _finishStage(address _owner) internal {
    require(!_lastSaleEnded(_owner), "No active sales");
    Sale storage sale = Sales[_last_sale_of[msg.sender]];
    require(sale.stageEndTime > 0, "No active stage");
    require(sale.stageEndTime < block.timestamp, "Stage has not ended");
    uint8 stage = sale.currentStage;
    if(stage == 10) {
      _generateReward(_owner, sale);
      sale.stageEndTime = block.timestamp + 5;
      sale.ended = true;
    } else {
      sale.stageEndTime = 0;
    }
    sale.currentStage++;
  }

  function _generateReward(address _owner, Sale storage sale) internal {
    for (uint8 i = 0; i < sale.managers.length; i++) {
      uint256 _memberID = sale.managers[i];
      memberContract.addPoints(_memberID, i, uint16(5));
    }
    uint256 reward = ( uint256(sale.hardCap) * (100 - uint256(sale.liquidityPercent)) ) / 100;
    sale.totalTokens += uint32(reward);
    _TOKEN_BALANCES[_owner] += reward;
  }

  // Creation
  function _createSale(
    string memory _name,
    string memory _icon,
    // uint8 _saleType,
    uint8 _launchPad,
    uint16 _hardCap,
    uint8 _softCapPercent,
    uint8 _liquidityPercent,
    uint256[5] memory _members
  ) internal {
    uint256[5] memory _managers;
    uint32[12] memory _subtotalPoints;
    Sale memory newSale = Sale(
      _name,
      SALE_COUNTER,
      _icon,
      _members,
      _managers,
      _subtotalPoints,
      // _saleType,
      _launchPad,
      0,
      0,
      _hardCap,
      _softCapPercent,
      _liquidityPercent,
      0,
      0,
      false
    );
    Sales.push(newSale);
    require(!_saleExists(SALE_COUNTER), "Sale already exists");
    _sale_creators[SALE_COUNTER] = msg.sender;
    _last_sale_of[msg.sender] = SALE_COUNTER;
    emit NewSale(msg.sender, SALE_COUNTER);
    SALE_COUNTER++;
  }

  function _saleExists(uint256 saleId) internal view returns (bool) {
    return _sale_creators[saleId] != address(0);
  }

  function _lastSaleEnded(address _owner) internal view returns (bool) {
    uint256 _lastSaleId = _last_sale_of[_owner];
    return _sale_creators[_lastSaleId] != _owner || Sales[_lastSaleId].ended;
  }

  function _checkMembersOwner(address _owner, uint256[5] memory _members) internal view returns (bool) {
    for (uint8 i = 0; i < _members.length; i++) {
      if (memberContract.ownerOf(_members[i]) != _owner) {
        return false;
      }
    }
    return true;
  }

  function _checkSaleMember(
    uint256 _memberId,
    uint256[5] memory _members,
    uint8 _maxIndex
  ) internal pure returns (bool) {
    if (_maxIndex < 1) {
      _maxIndex = uint8(_members.length);
    }
    for (uint8 i = 0; i < _maxIndex; i++) {
      if (_members[i] == _memberId) {
        return true;
      }
    }
    return false;
  }

  // Getters
  function getSalePoints(uint256 saleId) external view returns (uint32[12] memory) {
    return Sales[saleId].subtotalPoints;
  }

  function getSaleMembers(uint256 saleId) external view returns (uint256[5] memory) {
    return Sales[saleId].members;
  }

  function getSaleManagers(uint256 saleId) external view returns (uint256[5] memory) {
    return Sales[saleId].managers;
  }

  function getTokenBalance(address _owner) external view returns (uint256) {
    return _TOKEN_BALANCES[_owner];
  }

  function ownerOfSale(uint256 saleId) external view returns (address) {
    address owner = _sale_creators[saleId];
    require(owner != address(0), "ERC721: owner query for nonexistent sale");
    return owner;
  }

  function countSalesOf(address owner) external view returns (uint256) {
    require(owner != address(0), "ERC721: sale query for the zero address");
    return _sale_counter_of[owner];
  }

  function isFrozenMember(address _owner, uint256 _memberId) external view returns (bool) {
    if (_lastSaleEnded(_owner)) {
      return true;
    }
    Sale storage sale = Sales[_last_sale_of[_owner]];
    return !_checkSaleMember(_memberId, sale.members, 0);
  }

}