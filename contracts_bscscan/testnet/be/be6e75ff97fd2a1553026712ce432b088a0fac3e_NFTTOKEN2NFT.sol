/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}


pragma solidity >=0.6.0 <0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NFTTOKEN2NFT is  IERC721Receiver, Ownable {
    
    using SafeMath for uint256;
    
    address public nftStake;
    address public nftredeem;
    address public staketoken;
    
    mapping (address => bool) public existinguser;
          
    uint256 public claimtime;
        
    address[] public users;
    
    uint256 [] public stakedNFt;
               
    uint256 public stakingstarttingrange;
    uint256 public stakingendrange;
    
    uint256 public stakingamount; 
     
    uint256 public redeemstarttingrange;
    uint256 public redeemendrange;
      
    uint256 public claimindex;
           
    // mappings
    mapping (uint256 => uint256) public nftclaimtime;     
    mapping (uint256 => address) public nftStaked; 

    event stake(address from, address to, uint256 id, uint256 amount);
    event unstake(address from, address to, uint256 id, uint256 amount);
    event redeem(address from, address to, uint256 id);
    
    function stakeNftandTokens(uint256 _id) public {
        
        require (_id >= stakingstarttingrange && _id <= stakingendrange, "Incorrect token id ");
        
        IERC721 nft;
        IERC20 stk;
        nft = IERC721(nftStake);   
        stk = IERC20(staketoken);
    
        require(nft.ownerOf(_id) == msg.sender, "Sender has to be owner of the token.");
    
        if (existinguser[msg.sender] == false) {
            existinguser[msg.sender] = true;
            users.push(msg.sender);
        }
        
         nftclaimtime[_id] = block.timestamp.add(claimtime);
         nftStaked[_id] = msg.sender;
         stakedNFt.push(_id);
        
        nft.safeTransferFrom(msg.sender, address(this), _id); 
        stk.transferFrom(msg.sender, address(this), stakingamount); 
    
     emit stake(msg.sender, address(this), _id, stakingamount);  
    }
    
    
    function emergencyunstakenft(uint256 _id) public {
        
       IERC721 nft;
       nft = IERC721(nftStake);  
       IERC20 stk;
       stk = IERC20(staketoken); 
       
       require (nftStaked[_id] == msg.sender, "User not Staked this Token Id");
       require (nftclaimtime[_id] > block.timestamp, "Claim Time reached");
        
       nftStaked[_id] = 0x0000000000000000000000000000000000000000;
       nftclaimtime[_id] = 0;
       
       uint256[] memory allnfts = stakedNFt; 
       
       for (uint256 i=0; i < allnfts.length; i++) {
           
        if (allnfts[i] == _id) {
            
             stakedNFt[i] = stakedNFt[stakedNFt.length - 1];
             stakedNFt.pop();
             break;
        }   
       }
           
       nft.safeTransferFrom(address(this),msg.sender ,_id);     
       stk.transfer(msg.sender, stakingamount); 
     
     emit unstake(address(this), msg.sender, _id, stakingamount);  
    }
    
    
    function redeemNft(uint256 _id) public {
        
       IERC721 nft;
       nft = IERC721(nftredeem);
       
       require (nftStaked[_id] == msg.sender, "User not Staked this Token Id");
       require (nftclaimtime[_id] <= block.timestamp, "Claim Time not reached");
       
       uint256 nftid = redeemstarttingrange + claimindex; 
       assert (nftid <= redeemendrange);    
       
       nftStaked[_id] = 0x0000000000000000000000000000000000000000;
       nftclaimtime[_id] = 0;
       claimindex += 1; 
       
       uint256[] memory allnfts = stakedNFt; 
       
       for (uint256 i=0; i < allnfts.length; i++) {
           
        if (allnfts[i] == _id) {
            
             stakedNFt[i] = stakedNFt[stakedNFt.length - 1];
             stakedNFt.pop();
             break;
        }   
       }
       
       nft.safeTransferFrom(address(this), msg.sender, nftid);  
       
     emit redeem(address(this), msg.sender, nftid); 
    } 
    

     function onERC721Received(address, address, uint, bytes calldata) public  override returns (bytes4) {
        return 0x150b7a02;
    }
    
    
    // function setstakeNftaddress(address _add) public onlyOwner {
        
    //     require(getTotalStakedNft() == 0, "Nft staked");    
    //     nftStake = _add; 
    // }
    
    // function setstakingamount(uint256 _value) public onlyOwner {
        
    //     require(getTotalStakedNft() == 0, "Nft staked");    
    //     stakingamount = _value; 
    // }
    
    // function setredeemNftaddress(address _add) public onlyOwner {
        
    //     nftredeem = _add;
    // }
    
    function changestakingrange(uint256 _start, uint256 _end) public onlyOwner {
        
     require (_end > _start , "Incorrect range");    
     
     stakingstarttingrange = _start;
     stakingendrange = _end;
    }
    
    function changesredeemrange(uint256 _start, uint256 _end) public onlyOwner {
        
     require (_end > _start , "Incorrect range");  
     require (_start > stakingendrange , "Incorrect range");
     
     redeemstarttingrange = _start;
     redeemendrange = _end;
     claimindex = 0;
     
    }
    
    function changeClaimTime(uint256 _newtime) public onlyOwner {
        
     claimtime = _newtime;
    }
    
    function withdrawAdmin(address _nftaddress, uint256 _id, address admin) external onlyOwner {
          
      IERC721 nft;
      nft = IERC721(_nftaddress);  
      
    //   if (_nftaddress == nftStake) {
          
    //       require(nftStaked[_id] == 0x0000000000000000000000000000000000000000, "Nft not mature");
    //   }
      
      nft.safeTransferFrom(address(this), admin, _id); 
    }
    
    function batchwithdrawAdmin(address _nftaddress, address admin, uint256[] calldata ids) external onlyOwner {
      
      IERC721 nft;
      nft = IERC721(_nftaddress); 
      
      for (uint256 i = 0; i < ids.length; i++) {
      
    //   if (_nftaddress == nftStake) {
          
    //       require(nftStaked[ids[i]] == 0x0000000000000000000000000000000000000000, "Nft not mature");
    //   }
      nft.safeTransferFrom(address(this), admin, ids[i]); 
      }
    }
    
    
    function withdrawtokens(address _admin, uint256 _amount) public onlyOwner {
        
       IERC20 stk;
       stk = IERC20(staketoken);
       stk.transfer(_admin , _amount);  
    }
    
    
    function getTotalStakedNft() public view returns(uint256) {
        
        return stakedNFt.length;
    }
    
    
    function reset() external onlyOwner {
        
     IERC721 nfts;
     IERC721 nftr;
     IERC20 stk;
     nfts = IERC721(nftStake);   
     nftr = IERC721(nftredeem);  
     stk = IERC20(staketoken);   
     
     require (nfts.balanceOf(address(this)) == 0 , "Contract not empty");
     require (nftr.balanceOf(address(this)) == 0 , "Contract not empty");
     require (stk.balanceOf(address(this)) == 0 , "Contract not empty");
     
       for (uint256 i=0; i < stakedNFt.length; i++) {
        
        nftStaked[stakedNFt[i]] = 0x0000000000000000000000000000000000000000;
        nftclaimtime[stakedNFt[i]] = 0;
       }
     
     stakingstarttingrange = 0;
     stakingendrange = 0;
     redeemstarttingrange =0;
     redeemendrange =0;
     claimindex =0;
     stakingamount = 0;
     
     delete stakedNFt;  
    }
    
    
    function insertNFT(uint256[] calldata ids) external onlyOwner {
        
      IERC721 nft;                 
      nft = IERC721(nftredeem);      
      
      for (uint256 i = 0; i < ids.length; i++) {
      nft.safeTransferFrom(msg.sender, address(this), ids[i]); 
      }
        
    }
    
    
    function initialiaze(address _nftstakingadress, address _nftredeemaddress, address _stakingtoken, uint256 _claimtime, uint256 _stakingStart, uint256 _stakingend, uint256 _redeemstarting, uint256 _redeemend, uint256 _stakingamount) public onlyOwner {
       
       require(getTotalStakedNft() == 0, "Nft already staked");  
       require(_stakingamount > 0, "Incorrect staking amount");
        
       nftStake = _nftstakingadress;
       nftredeem = _nftredeemaddress;
       staketoken = _stakingtoken;
       claimtime = _claimtime;
       
       require (_stakingStart < _stakingend, "Incorrect staking range");
       stakingstarttingrange = _stakingStart;
       stakingendrange = _stakingend;
       stakingamount = _stakingamount;
       
       require (_redeemstarting > _stakingend && _redeemend > _redeemstarting, "Incorrect redeem range");
       redeemstarttingrange = _redeemstarting;     
       redeemendrange = _redeemend; 
       claimindex = 0;
   }
    
    
}