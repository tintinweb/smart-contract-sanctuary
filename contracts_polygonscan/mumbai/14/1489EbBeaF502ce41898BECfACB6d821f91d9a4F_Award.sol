/**
 *Submitted for verification at polygonscan.com on 2021-08-31
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
  mapping(uint256 => mapping(address => auctionBid)) private _auctionTokensBids;  
  struct auctionTokenDeat{  
    mapping(uint256=>address) addressInfo;  
    uint256 count;  
  } 
  mapping(uint256 => auctionTokenDeat) private _auctionTokensAddressDeatils;
  mapping(uint256 => string) nonCryptoBidder;
  address nftDex;
  address admin;

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
  

  function placeBid(address seller,uint256 _tokenId, uint256 _amount, bool awardType, string calldata ownerId, address ownerAddress) isNftDex external{
      require(isAwardType[_tokenId]);
      auctionBid storage tmp =  _auctionTokensBids[_tokenId][ownerAddress];
      uint256 count = _auctionTokensAddressDeatils[_tokenId].count++; 
      tmp.bidder = ownerAddress; 
      tmp.seller = seller;  
      tmp.bidAmount = _amount; 
      tmp.placeTime = now; 
      nonCryptoBidder[_tokenId]= ownerId;
      _auctionTokensAddressDeatils[_tokenId].addressInfo[count]=ownerAddress;
  }

  function getBidAmount(uint256 _tokenId, address ownerAddress) external view returns(uint256, string memory){
       return(_auctionTokensBids[_tokenId][ownerAddress].bidAmount,  nonCryptoBidder[_tokenId]);
  }


  function updateBidder(uint256 _tokenId, string calldata ownerId) isNftDex external{ 
        nonCryptoBidder[_tokenId]= ownerId;
  }

  function clearMapping(uint256 _tokenId) public{ 
      require(msg.sender == admin );
    for(uint256 i=0;i<_auctionTokensAddressDeatils[_tokenId].count;i++) { 
      delete _auctionTokensBids[_tokenId][_auctionTokensAddressDeatils[_tokenId].addressInfo[i]]; 
      delete _auctionTokensAddressDeatils[_tokenId].addressInfo[i]; 
      delete _auctionTokensAddressDeatils[_tokenId].count;  
    } 
  }

}