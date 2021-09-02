/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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
    function mint(address recipient, uint256 amount) external returns(bool);
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function nonCryptoNFTVault() external returns(address);
    function mainPerecentage() external returns(uint256);
    function authorPercentage() external returns(uint256);
    function platformPerecentage() external returns(uint256);
    function updateAliaBalance(string calldata stringId, uint256 amount) external returns(bool);
    
    //Revenue share
    function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool);
    function transferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool);
    function checkArtistOwner(string calldata artistId, uint256 tokenId) external returns(bool);
    function checkTokenAuthorIsArtist(uint256 tokenId) external returns(bool);
    function getRandomNumber() external returns (bytes32);
    function getRandomVal() external returns (uint256);
    

    //award
     
   function placeBid(uint256 _tokenId, uint256 _amount, bool awardType, address from)  external;
    function claimAuction(uint256 _tokenId, bool awardType, string calldata ownerId, address from) external;
    function updateBidder(uint256 _tokenId,address bidAddr, uint256 _amount) external;

}

// File: contracts/Award.sol

pragma solidity ^0.5.0;


contract Award {
    using SafeMath for uint256;
    mapping(uint256 => bool) public isAwardType;
    struct auctionBid { 
        address bidder; 
        address seller; 
        string  ownerId;
        uint256 placeTime;  
        uint256 bidAmount;  
    } 
  //mapping(uint256 => auctionBid) private _auctionTokensBids;  
  mapping(uint256 => mapping(address  => mapping(string => auctionBid))) private _auctionTokensBids;  
  struct _addressInfo {
    address _address;
    string  _ownerId;
  }
  struct auctionTokenDeat{  
    mapping(uint256=>_addressInfo) addressInfo;  
    uint256 count;  
  } 
  mapping(uint256 => auctionTokenDeat) private _auctionTokensAddressDeatils;
  mapping(uint256 => string) nonCryptoBidder;
  address nftDex;
  address admin;

  event BidAward(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount, bool awardType, string ownerId);
  event ClaimAward(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount, bool awardType, string ownerId);
  

modifier isNftDex() {
    require(msg.sender == nftDex);
    _;
}
  function addAwardType(uint256 _tokenId) isNftDex external {
      isAwardType[_tokenId] = true;
  }


function init1() public {
    nftDex=0xC84E3F06Ae0f2cf2CA782A1cd0F653663c99280d;
    admin =0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859;
}
  

  function placeBidAward(address seller,uint256 _tokenId, uint256 _amount, bool awardType, string memory ownerId) public{
      // require(isAwardType[_tokenId]);
      IERC20(nftDex).placeBid(_tokenId, _amount, awardType, msg.sender);
      auctionBid storage tmp =  _auctionTokensBids[_tokenId][msg.sender][ownerId];
      uint256 count = _auctionTokensAddressDeatils[_tokenId].count++; 
      tmp.bidder = msg.sender; 
      tmp.seller = seller;  
      tmp.bidAmount = _amount; 
      tmp.ownerId = ownerId;
      tmp.placeTime = now;
      nonCryptoBidder[_tokenId] = ownerId;
      _auctionTokensAddressDeatils[_tokenId].addressInfo[count]._address=msg.sender;
      _auctionTokensAddressDeatils[_tokenId].addressInfo[count]._ownerId=ownerId;
     emit BidAward(msg.sender, nftDex, _tokenId, _amount, awardType, ownerId);
  }

  function claimAuctionAward(uint256 _tokenId, bool awardType, string memory ownerId) public {
    IERC20(nftDex).claimAuction(_tokenId, awardType, ownerId, msg.sender);  
    emit ClaimAward(msg.sender, nftDex, _tokenId,  _auctionTokensBids[_tokenId][ msg.sender][ownerId].bidAmount, awardType, ownerId);  
  }


  function updateBidder(uint256 _tokenId, string memory ownerId, address bidAddr) public{
    require(admin == msg.sender);
    IERC20(nftDex).updateBidder(_tokenId, bidAddr,  _auctionTokensBids[_tokenId][bidAddr][ownerId].bidAmount);
    nonCryptoBidder[_tokenId] = ownerId;
  }

  function getNonCryptoHighestBidder(uint256 _tokenId) public view returns(string memory) {
    return nonCryptoBidder[_tokenId];
  }

  function clearMapping(uint256 _tokenId) public{ 
      require(msg.sender == admin );
    for(uint256 i=0;i<_auctionTokensAddressDeatils[_tokenId].count;i++) { 
      delete _auctionTokensBids[_tokenId][_auctionTokensAddressDeatils[_tokenId].addressInfo[i]._address][_auctionTokensAddressDeatils[_tokenId].addressInfo[i]._ownerId]; 
     
      delete _auctionTokensAddressDeatils[_tokenId].addressInfo[i]; 
      delete _auctionTokensAddressDeatils[_tokenId].count;  
    } 
  }

}