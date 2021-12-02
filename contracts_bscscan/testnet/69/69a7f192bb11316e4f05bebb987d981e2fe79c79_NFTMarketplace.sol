/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

pragma solidity 0.6.12;

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
interface INFT {
  function ownerOf(uint256 tokenId) external view returns (address);

  function approve(address to, uint256 tokenId) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mySafeMint(address to, uint256 tokenId) external;

  function mySetTokenURI(uint256 tokenId, string memory _tokenURI) external;
}

contract NFTMarketplace {
  using SafeMath for uint256;
  IERC20 public canBuyCoin = IERC20(0x1e0c73A22F5f121E5486a77e99c7e756f21569Ef);
  address private admin;
  uint256 public rate = 10; //10%
  struct NFTInfo {
    address nftAddress;
    uint256 tokenId;
    address[] allOwners; //历代持有者
    uint256 nftPrice;
    bool whether_to_sell;
    uint256 level; //级别
    uint256 color; //颜色
  }
  event NFTOwnershipChanged(
    INFT nft,
    uint256 tokenId,
    address ownerBeforeOwnershipTransferred,
    address ownerAfterOwnershipTransferred
  );
  mapping(address=>mapping(uint256 => NFTInfo)) public tokenIdNFTInfos;

  constructor() public {
    admin = msg.sender;
  }

  function setCanBuyCoin(address _canBuyCoin) public {
    require(msg.sender == admin, "only admin can do this");
    canBuyCoin = IERC20(_canBuyCoin);
  }

  //设置价格
  function setPrice(address nftAddress,uint256 tokenId, uint256 nftPrice) public {
    INFT nft=INFT(nftAddress);
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    info.nftPrice = nftPrice;
  }
  function getPrice(address nftAddress,uint256 tokenId)public view returns(uint){
    return tokenIdNFTInfos[nftAddress][tokenId].nftPrice;
  }
  function whetherToSell(address nftAddress,uint256 tokenId, bool whether_to_sell) public {
    INFT nft=INFT(nftAddress);
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    info.whether_to_sell = whether_to_sell;
  }
  function getWhetherToSell(address nftAddress,uint256 tokenId)public view returns(bool){
    return tokenIdNFTInfos[nftAddress][tokenId].whether_to_sell;
  }
  function setLevel(address nftAddress,uint256 tokenId, uint256 level) public {
    INFT nft=INFT(nftAddress);
    address owner = nft.ownerOf(tokenId);
    require(
      msg.sender == owner || msg.sender == admin,
      "only owner can do this"
    );
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    info.level = level;
  }

  function buyNFT(address nftAddress,uint256 tokenId) public payable returns (bool) {

    uint256 balance = canBuyCoin.balanceOf(msg.sender);
    NFTInfo storage info = tokenIdNFTInfos[nftAddress][tokenId];
    require(info.whether_to_sell, "trade not open,can not buy");
    require(balance >= info.nftPrice, "balance not enough");
    INFT nft=INFT(nftAddress);
    address owner = nft.ownerOf(tokenId);
    nft.safeTransferFrom(owner, address(this), tokenId);
    nft.approve(msg.sender, tokenId);
    nft.safeTransferFrom(address(this), msg.sender, tokenId);
    canBuyCoin.transfer(
      owner,
      info.nftPrice.sub(info.nftPrice.mul(rate).div(100))
    );
    uint256 length = info.allOwners.length;
    for (uint256 i; i < length; i++) {
      canBuyCoin.transfer(
        info.allOwners[i],
        info.nftPrice.mul(rate).div(100).div(length)
      );
    }
    info.allOwners.push(owner);
    emit NFTOwnershipChanged(nft, tokenId, owner, msg.sender);
  }
}