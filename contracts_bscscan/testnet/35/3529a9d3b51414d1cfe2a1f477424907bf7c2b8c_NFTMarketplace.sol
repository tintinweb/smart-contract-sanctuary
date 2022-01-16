/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity 0.6.12;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      bytes32 lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1;
      set._values.pop();
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  struct Bytes32Set {
    Set _inner;
  }

  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

interface INFT {
  function approve(address to, uint256 tokenId) external;

  function getBlindBoxOpened(uint256 _tokenId) external view returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract NFTMarketplace is IERC721Receiver {
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeMath for uint256;
  IERC20 public canBuyCoin = IERC20(0x9bA3363253Ff27EDEed2F28d82A0C6BfBad434f3);
  mapping(address => EnumerableSet.UintSet) private _holderonsaleNFTs;
  mapping(address => EnumerableSet.UintSet) private _holderonsaleBlindboxes;
  address private admin;
  uint256 public rate = 10; //10%
  mapping(address => mapping(uint256 => address)) public tokenOwners;
  struct NFTInfo {
    address nftAddress;
    uint256 tokenId;
    address[] allOwners; //历代持有者
    uint256 nftPrice;
    bool whether_to_sell;
  }
  event NFTOwnershipChanged(
    INFT nft,
    uint256 tokenId,
    address ownerBeforeOwnershipTransferred,
    address ownerAfterOwnershipTransferred
  );
  mapping(address => mapping(uint256 => NFTInfo)) public tokenIdNFTInfos;
  modifier onlyAdmin() {
    require(admin == msg.sender, "only owner");
    _;
  }

  constructor() public {
    admin = msg.sender;
  }

  function setRate(uint256 _rate) public onlyAdmin returns (bool) {
    rate = _rate;
    return true;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external virtual override returns (bytes4) {}

  function setCanBuyCoin(address _canBuyCoin) public returns (bool) {
    require(msg.sender == admin, "only admin can do this");
    canBuyCoin = IERC20(_canBuyCoin);
    return true;
  }

  //设置价格
  function setPrice(
    address nftAddress,
    uint256 tokenId,
    uint256 nftPrice
  ) public returns (bool) {
    // INFT nft = INFT(nftAddress);
    address owner = tokenOwners[nftAddress][tokenId];
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    info.nftPrice = nftPrice;
    return true;
  }

  function getHolderOnsaleNFTs(
    address _owner,
    uint256 index,
    uint256 size
  ) public view returns (uint256[] memory) {
    uint256 length = _holderonsaleNFTs[_owner].length();
    require(length + size - size * index >= 0, "forbidden");
    uint256 limit = length < size * index ? length : size * index;
    uint256 arraySize =
      length < size * index ? length + limit - size * index : size;
    uint256[] memory a = new uint256[](arraySize);
    for (uint256 i = size * (index - 1); i < limit; i++) {
      uint256 tokenId = _holderonsaleNFTs[_owner].at(i);
      a[i] = tokenId;
    }
    return a;
  }

  function getHolderOnsaleBlindboxes(
    address _owner,
    uint256 index,
    uint256 size
  ) public view returns (uint256[] memory) {
    uint256 length = _holderonsaleBlindboxes[_owner].length();
    require(length + size - size * index >= 0, "forbidden");
    uint256 limit = length < size * index ? length : size * index;
    uint256 arraySize =
      length < size * index ? length + size - size * index : size;
    uint256[] memory a = new uint256[](arraySize);
    for (uint256 i = size * (index - 1); i < limit; i++) {
      uint256 tokenId = _holderonsaleBlindboxes[_owner].at(i);
      a[i] = tokenId;
    }
    return a;
  }

  function balanceOfOnsaleNFT(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _holderonsaleNFTs[owner].length();
  }

  function balanceOfOnsaleBlindbox(address owner)
    public
    view
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _holderonsaleBlindboxes[owner].length();
  }

  function getPrice(address nftAddress, uint256 tokenId)
    public
    view
    returns (uint256)
  {
    return tokenIdNFTInfos[nftAddress][tokenId].nftPrice;
  }

  function isBalanceEnough(address nftAddress, uint256 tokenId)
    public
    view
    returns (bool)
  {
    uint256 balance = canBuyCoin.balanceOf(msg.sender);
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    if (info.nftPrice == 0) {
      return false;
    } else if (balance > info.nftPrice) {
      return true;
    } else {
      return false;
    }
  }

  function whetherToSell(
    address nftAddress,
    uint256 tokenId,
    bool whether_to_sell,
    uint256 nftPrice
  ) public returns (bool) {
    INFT nft = INFT(nftAddress);
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    info.whether_to_sell = whether_to_sell;
    if (whether_to_sell) {
      require(nftPrice > 0, "too low nftPrice");
      if (nft.getBlindBoxOpened(tokenId)) {
        _holderonsaleNFTs[msg.sender].add(tokenId);
      } else {
        _holderonsaleBlindboxes[msg.sender].add(tokenId);
      }
      nft.transferFrom(msg.sender, address(this), tokenId);
      tokenOwners[nftAddress][tokenId] = msg.sender;
      info.nftPrice = nftPrice;
    } else {
      require(
        tokenOwners[nftAddress][tokenId] == msg.sender,
        "only owner can do this"
      );
      delete tokenOwners[nftAddress][tokenId];
      nft.transferFrom(address(this), msg.sender, tokenId);
      // info.nftPrice = 0;
      if (nft.getBlindBoxOpened(tokenId)) {
        _holderonsaleNFTs[msg.sender].remove(tokenId);
      } else {
        _holderonsaleBlindboxes[msg.sender].remove(tokenId);
      }
    }

    return whether_to_sell;
  }

  function getWhetherToSell(address nftAddress, uint256 tokenId)
    public
    view
    returns (bool)
  {
    return tokenIdNFTInfos[nftAddress][tokenId].whether_to_sell;
  }

  function buyNFT(address nftAddress, uint256 tokenId) public returns (bool) {
    uint256 balance = canBuyCoin.balanceOf(msg.sender);
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    require(info.whether_to_sell, "trade not open,can not buy");
    require(balance >= info.nftPrice, "balance not enough");
    INFT nft = INFT(nftAddress);
    address owner = tokenOwners[nftAddress][tokenId];
    require(
      msg.sender != tokenOwners[nftAddress][tokenId],
      "can not buy yourself nft"
    );
    // nft.transferFrom(owner, address(this), tokenId);
    // nft.approve(msg.sender, tokenId);
    delete tokenOwners[nftAddress][tokenId];
    if (nft.getBlindBoxOpened(tokenId)) {
      _holderonsaleNFTs[owner].remove(tokenId);
    } else {
      _holderonsaleBlindboxes[owner].remove(tokenId);
    }
    // _holderonsaleTokens[owner].remove(tokenId);
    nft.transferFrom(address(this), msg.sender, tokenId);

    canBuyCoin.transferFrom(
      msg.sender,
      owner,
      info.nftPrice.mul(rate).div(100)
    );

    info.allOwners.push(owner);
    emit NFTOwnershipChanged(nft, tokenId, owner, msg.sender);
    return true;
  }
}