/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Expire Traker
 * @dev Keeps track of expired NFTs.
**/
contract ExpireTracker {
    
    using SafeMath for uint64;
    using SafeMath for uint256;

    // 1 day for each step.
    uint64 public constant BUCKET_STEP = 1 days;

    // indicates where to start from 
    // points where TokenInfo with (expiredAt / BUCKET_STEP) == index
    mapping(uint64 => Bucket) public checkPoints;

    struct Bucket {
        uint96 head;
        uint96 tail;
    }

    // points first active nft
    uint96 public head;
    // points last active nft
    uint96 public tail;

    // maps expireId to deposit info
    mapping(uint96 => ExpireMetadata) public infos; 
    
    // pack data to reduce gas
    struct ExpireMetadata {
        uint96 next; // zero if there is no further information
        uint96 prev;
        uint64 expiresAt;
    }

    function expired() internal view returns(bool) {
        if(infos[head].expiresAt == 0) {
            return false;
        }

        if(infos[head].expiresAt <= uint64(now)){
            return true;
        }

        return false;
    }

    // using typecasted expireId to save gas
    function push(uint96 expireId, uint64 expiresAt) 
      internal 
    {
        require(expireId != 0, "info id 0 cannot be supported");

        // If this is a replacement for a current balance, remove it's current link first.
        if (infos[expireId].expiresAt > 0) pop(expireId);

        uint64 bucket = uint64( (expiresAt.div(BUCKET_STEP)).mul(BUCKET_STEP) );
        if (head == 0) {
            // all the nfts are expired. so just add
            head = expireId;
            tail = expireId; 
            checkPoints[bucket] = Bucket(expireId, expireId);
            infos[expireId] = ExpireMetadata(0,0,expiresAt);
            
            return;
        }
            
        // there is active nft. we need to find where to push
        // first check if this expires faster than head
        if (infos[head].expiresAt >= expiresAt) {
            // pushing nft is going to expire first
            // update head
            infos[head].prev = expireId;
            infos[expireId] = ExpireMetadata(head,0,expiresAt);
            head = expireId;
            
            // update head of bucket
            Bucket storage b = checkPoints[bucket];
            b.head = expireId;
                
            if(b.tail == 0) {
                // if tail is zero, this bucket was empty should fill tail with expireId
                b.tail = expireId;
            }
                
            // this case can end now
            return;
        }
          
        // then check if depositing nft will last more than latest
        if (infos[tail].expiresAt <= expiresAt) {
            infos[tail].next = expireId;
            // push nft at tail
            infos[expireId] = ExpireMetadata(0,tail,expiresAt);
            tail = expireId;
            
            // update tail of bucket
            Bucket storage b = checkPoints[bucket];
            b.tail = expireId;
            
            if(b.head == 0){
              // if head is zero, this bucket was empty should fill head with expireId
              b.head = expireId;
            }
            
            // this case is done now
            return;
        }
          
        // so our nft is somewhere in between
        if (checkPoints[bucket].head != 0) {
            //bucket is not empty
            //we just need to find our neighbor in the bucket
            uint96 cursor = checkPoints[bucket].head;
        
            // iterate until we find our nft's next
            while(infos[cursor].expiresAt < expiresAt){
                cursor = infos[cursor].next;
            }
        
            infos[expireId] = ExpireMetadata(cursor, infos[cursor].prev, expiresAt);
            infos[infos[cursor].prev].next = expireId;
            infos[cursor].prev = expireId;
        
            //now update bucket's head/tail data
            Bucket storage b = checkPoints[bucket];
            
            if (infos[b.head].prev == expireId){
                b.head = expireId;
            }
            
            if (infos[b.tail].next == expireId){
                b.tail = expireId;
            }
        } else {
            //bucket is empty
            //should find which bucket has depositing nft's closest neighbor
            // step 1 find prev bucket
            uint64 prevCursor = bucket - BUCKET_STEP;
            
            while(checkPoints[prevCursor].tail == 0){
              prevCursor = uint64( prevCursor.sub(BUCKET_STEP) );
            }
    
            uint96 prev = checkPoints[prevCursor].tail;
            uint96 next = infos[prev].next;
    
            // step 2 link prev buckets tail - nft - next buckets head
            infos[expireId] = ExpireMetadata(next,prev,expiresAt);
            infos[prev].next = expireId;
            infos[next].prev = expireId;
    
            checkPoints[bucket].head = expireId;
            checkPoints[bucket].tail = expireId;
        }
    }

    function _pop(uint96 expireId, uint256 bucketStep) private {
        uint64 expiresAt = infos[expireId].expiresAt;
        uint64 bucket = uint64( (expiresAt.div(bucketStep)).mul(bucketStep) );
        // check if bucket is empty
        // if bucket is empty, end
        if(checkPoints[bucket].head == 0){
            return;
        }
        // if bucket is not empty, iterate through
        // if expiresAt of current cursor is larger than expiresAt of parameter, reverts
        for(uint96 cursor = checkPoints[bucket].head; infos[cursor].expiresAt <= expiresAt; cursor = infos[cursor].next) {
            ExpireMetadata memory info = infos[cursor];
            // if expiresAt is same of paramter, check if expireId is same
            if(info.expiresAt == expiresAt && cursor == expireId) {
                // if yes, delete it
                // if cursor was head, move head to cursor.next
                if(head == cursor) {
                    head = info.next;
                }
                // if cursor was tail, move tail to cursor.prev
                if(tail == cursor) {
                    tail = info.prev;
                }
                // if cursor was head of bucket
                if(checkPoints[bucket].head == cursor){
                    // and cursor.next is still in same bucket, move head to cursor.next
                    if(infos[info.next].expiresAt.div(bucketStep) == bucket.div(bucketStep)) {
                        checkPoints[bucket].head = info.next;
                    } else {
                        // delete whole checkpoint if bucket is now empty
                        delete checkPoints[bucket];
                    }
                } else if(checkPoints[bucket].tail == cursor){
                    // since bucket.tail == bucket.haed == cursor case is handled at the above,
                    // we only have to handle bucket.tail == cursor != bucket.head
                    checkPoints[bucket].tail = info.prev;
                }
                // now we handled all tail/head situation, we have to connect prev and next
                infos[info.prev].next = info.next;
                infos[info.next].prev = info.prev;
                // delete info and end
                delete infos[cursor];
                return;
            }
            // if not, continue -> since there can be same expires at with multiple expireId
        }
        //changed to return for consistency
        return;
        //revert("Info does not exist");
    }

    function pop(uint96 expireId) internal {
        _pop(expireId, BUCKET_STEP);
    }

    function pop(uint96 expireId, uint256 step) internal {
        _pop(expireId, step);
    }

    uint256[50] private __gap;
}

interface IArmorMaster {
    function registerModule(bytes32 _key, address _module) external;
    function getModule(bytes32 _key) external view returns(address);
    function keep() external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev Completely default OpenZeppelin.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private __gap;
}

library Bytes32 {
    function toString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/**
 * @dev Each arCore contract is a module to enable simple communication and interoperability. ArmorMaster.sol is master.
**/
contract ArmorModule {
    IArmorMaster internal _master;

    using Bytes32 for bytes32;

    modifier onlyOwner() {
        require(msg.sender == Ownable(address(_master)).owner(), "only owner can call this function");
        _;
    }

    modifier doKeep() {
        _master.keep();
        _;
    }

    modifier onlyModule(bytes32 _module) {
        string memory message = string(abi.encodePacked("only module ", _module.toString()," can call this function"));
        require(msg.sender == getModule(_module), message);
        _;
    }

    /**
     * @dev Used when multiple can call.
    **/
    modifier onlyModules(bytes32 _moduleOne, bytes32 _moduleTwo) {
        string memory message = string(abi.encodePacked("only module ", _moduleOne.toString()," or ", _moduleTwo.toString()," can call this function"));
        require(msg.sender == getModule(_moduleOne) || msg.sender == getModule(_moduleTwo), message);
        _;
    }

    function initializeModule(address _armorMaster) internal {
        require(address(_master) == address(0), "already initialized");
        require(_armorMaster != address(0), "master cannot be zero address");
        _master = IArmorMaster(_armorMaster);
    }

    function changeMaster(address _newMaster) external onlyOwner {
        _master = IArmorMaster(_newMaster);
    }

    function getModule(bytes32 _key) internal view returns(address) {
        return _master.getModule(_key);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IarNFT is IERC721 {
    function getToken(uint256 _tokenId) external returns (uint256, uint8, uint256, uint16, uint256, address, bytes4, uint256, uint256, uint256);
    function submitClaim(uint256 _tokenId) external;
    function redeemClaim(uint256 _tokenId) external;
}

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) payable external;
}

interface IRewardManager is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeManager) external;
  function stake(address _user, uint256 _coverPrice, uint256 _nftId) external;
  function withdraw(address _user, uint256 _coverPrice, uint256 _nftId) external;
  function getReward(address payable _user) external;
}

interface IPlanManager {
  // Event to notify frontend of plan update.
  event PlanUpdate(address indexed user, address[] protocols, uint256[] amounts, uint256 endTime);
  function initialize(address _armorManager) external;
  function changePrice(address _scAddress, uint256 _pricePerAmount) external;
  function updatePlan(address[] calldata _protocols, uint256[] calldata _coverAmounts) external;
  function checkCoverage(address _user, address _protocol, uint256 _hacktime, uint256 _amount) external view returns (uint256, bool);
  function coverageLeft(address _protocol) external view returns(uint256);
  function getCurrentPlan(address _user) external view returns(uint128 start, uint128 end);
  function updateExpireTime(address _user, uint256 _expiry) external;
  function planRedeemed(address _user, uint256 _planIndex, address _protocol) external;
  function totalUsedCover(address _scAddress) external view returns (uint256);
}

interface IClaimManager {
    function initialize(address _armorMaster) external;
    function transferNft(address _to, uint256 _nftId) external;
    function exchangeWithdrawal(uint256 _amount) external;
}

interface IStakeManager {
    function totalStakedAmount(address protocol) external view returns(uint256);
    function protocolAddress(uint64 id) external view returns(address);
    function protocolId(address protocol) external view returns(uint64);
    function initialize(address _armorMaster) external;
    function allowedCover(address _newProtocol, uint256 _newTotalCover) external view returns (bool);
    function subtractTotal(uint256 _nftId, address _protocol, uint256 _subtractAmount) external;
}

interface IUtilizationFarm is IRewardDistributionRecipient {
  function initialize(address _rewardToken, address _stakeManager) external;
  function stake(address _user, uint256 _coverPrice) external;
  function withdraw(address _user, uint256 _coverPrice) external;
  function getReward(address payable _user) external;
}

/**
 * @dev Encompasses all functions taken by stakers.
**/
contract StakeManager is ArmorModule, ExpireTracker, IStakeManager {
    
    using SafeMath for uint;
    
    bytes4 public constant ETH_SIG = bytes4(0x45544800);
    
    // Whether or not utilization farming is on.
    bool ufOn;
    
    // Amount of time--in seconds--a user must wait to withdraw an NFT.
    uint256 withdrawalDelay;
    
    // Protocols that staking is allowed for. We may not allow all NFTs.
    mapping (address => bool) public allowedProtocol;
    mapping (address => uint64) public override protocolId;
    mapping (uint64 => address) public override protocolAddress;
    uint64 protocolCount;
    
    // The total amount of cover that is currently being staked. scAddress => cover amount
    mapping (address => uint256) public override totalStakedAmount;
    
    // Mapping to keep track of which NFT is owned by whom. NFT ID => owner address.
    mapping (uint256 => address) public nftOwners;

    // When the NFT can be withdrawn. NFT ID => Unix timestamp.
    mapping (uint256 => uint256) public pendingWithdrawals;

    // Track if the NFT was submitted, in which case total staked has already been lowered.
    mapping (uint256 => bool) public submitted;

    // Event launched when an NFT is staked.
    event StakedNFT(address indexed user, address indexed protocol, uint256 nftId, uint256 sumAssured, uint256 secondPrice, uint16 coverPeriod, uint256 timestamp);

    // Event launched when an NFT expires.
    event RemovedNFT(address indexed user, address indexed protocol, uint256 nftId, uint256 sumAssured, uint256 secondPrice, uint16 coverPeriod, uint256 timestamp);

    event ExpiredNFT(address indexed user, uint256 nftId, uint256 timestamp);
    
    // Event launched when an NFT expires.
    event WithdrawRequest(address indexed user, uint256 nftId, uint256 timestamp, uint256 withdrawTimestamp);
    
    /**
     * @dev Construct the contract with the yNft contract.
    **/
    function initialize(address _armorMaster)
      public
      override
    {
        initializeModule(_armorMaster);
        // Let's be explicit.
        withdrawalDelay = 7 days;
        ufOn = true;
    }

    /**
     * @dev Keep function can be called by anyone to remove any NFTs that have expired. Also run when calling many functions.
     *      This is external because the doKeep modifier calls back to ArmorMaster, which then calls back to here (and elsewhere).
    **/
    function keep() external {
        for (uint256 i = 0; i < 2; i++) {
            if (infos[head].expiresAt != 0 && infos[head].expiresAt <= now) _removeExpiredNft(head);
            else return;
        }
    }
    
    /**
     * @dev stakeNft allows a user to submit their NFT to the contract and begin getting returns.
     *      This yNft cannot be withdrawn!
     * @param _nftId The ID of the NFT being staked.
    **/
    function stakeNft(uint256 _nftId)
      public
      // doKeep
    {
        _stake(_nftId, msg.sender);
    }

    /**
     * @dev stakeNft allows a user to submit their NFT to the contract and begin getting returns.
     * @param _nftIds The ID of the NFT being staked.
    **/
    function batchStakeNft(uint256[] memory _nftIds)
      public
      // doKeep
    {
        // Loop through all submitted NFT IDs and stake them.
        for (uint256 i = 0; i < _nftIds.length; i++) {
            _stake(_nftIds[i], msg.sender);
        }
    }

    /**
     * @dev A user may call to withdraw their NFT. This may have a delay added to it.
     * @param _nftId ID of the NFT to withdraw.
    **/
    function withdrawNft(uint256 _nftId)
      external
      // doKeep
    {
        // Check when this NFT is allowed to be withdrawn. If 0, set it.
        uint256 withdrawalTime = pendingWithdrawals[_nftId];
        
        if (withdrawalTime == 0) {
            require(nftOwners[_nftId] == msg.sender, "Sender does not own this NFT.");
            
            (/*coverId*/,  uint8 coverStatus, uint256 sumAssured, /*uint16 coverPeriod*/, /*uint256 validUntil*/, address scAddress, 
            /*bytes4 coverCurrency*/, /*premiumNXM*/, /*uint256 coverPrice*/, /*claimId*/) = IarNFT( getModule("ARNFT") ).getToken(_nftId);
            
            uint256 totalUsedCover = IPlanManager( getModule("PLAN") ).totalUsedCover(scAddress);
            bool withdrawable = totalUsedCover <= totalStakedAmount[scAddress].sub(sumAssured * 1e18);
            require(coverStatus == 0 && withdrawable, "May not withdraw NFT if it will bring staked amount below borrowed amount.");
            
            withdrawalTime = block.timestamp + withdrawalDelay;
            pendingWithdrawals[_nftId] = withdrawalTime;
            _removeNft(_nftId);
            
            emit WithdrawRequest(msg.sender, _nftId, block.timestamp, withdrawalTime);
        } else if (withdrawalTime <= block.timestamp) {
            (/*coverId*/,  uint8 coverStatus, /*uint256 sumAssured*/, /*uint16 coverPeriod*/, /*uint256 validUntil*/, /*address scAddress*/, 
            /*bytes4 coverCurrency*/, /*premiumNXM*/, /*uint256 coverPrice*/, /*claimId*/) = IarNFT(getModule("ARNFT")).getToken(_nftId);
            
            // Added after update in case someone initiated withdrawal before update, then executed after update, in which case their NFT is never removed.
            if (ExpireTracker.infos[uint96(_nftId)].next > 0) _removeNft(_nftId);

            require(coverStatus == 0, "May not withdraw while claim is occurring.");
            
            address nftOwner = nftOwners[_nftId];
            IClaimManager(getModule("CLAIM")).transferNft(nftOwner, _nftId);
            delete pendingWithdrawals[_nftId];
            delete nftOwners[_nftId];
        }
        
    }

    /**
     * @dev Subtract from total staked. Used by ClaimManager in case NFT is submitted.
     * @param _protocol Address of the protocol to subtract from.
     * @param _subtractAmount Amount of staked to subtract.
    **/
    function subtractTotal(uint256 _nftId, address _protocol, uint256 _subtractAmount)
      external
      override
      onlyModule("CLAIM")
    {
        totalStakedAmount[_protocol] = totalStakedAmount[_protocol].sub(_subtractAmount);
        submitted[_nftId] = true;
    }

    /**
     * @dev Check whether a new TOTAL cover is allowed.
     * @param _protocol Address of the smart contract protocol being protected.
     * @param _totalBorrowedAmount The new total amount that would be being borrowed.
     * returns Whether or not this new total borrowed amount would be able to be covered.
    **/
    function allowedCover(address _protocol, uint256 _totalBorrowedAmount)
      external
      override
      view
    returns (bool)
    {
        return _totalBorrowedAmount <= totalStakedAmount[_protocol];
    }
    
    /**
     * @dev Internal function for staking--this allows us to skip updating stake multiple times during a batch stake.
     * @param _nftId The ID of the NFT being staked. == coverId
     * @param _user The user who is staking the NFT.
    **/
    function _stake(uint256 _nftId, address _user)
      internal
    {
        (/*coverId*/,  uint8 coverStatus, uint256 sumAssured, uint16 coverPeriod, uint256 validUntil, address scAddress, 
         bytes4 coverCurrency, /*premiumNXM*/, uint256 coverPrice, /*claimId*/) = IarNFT( getModule("ARNFT") ).getToken(_nftId);
        
        _checkNftValid(validUntil, scAddress, coverCurrency, coverStatus);
        
        // coverPrice must be determined by dividing by length.
        uint256 secondPrice = coverPrice / (uint256(coverPeriod) * 1 days);

        // Update PlanManager to use the correct price for the protocol.
        // Find price per amount here to update plan manager correctly.
        uint256 pricePerEth = secondPrice / sumAssured;
        
        IPlanManager(getModule("PLAN")).changePrice(scAddress, pricePerEth);
        
        IarNFT(getModule("ARNFT")).transferFrom(_user, getModule("CLAIM"), _nftId);

        ExpireTracker.push(uint96(_nftId), uint64(validUntil));
        // Save owner of NFT.
        nftOwners[_nftId] = _user;

        uint256 weiSumAssured = sumAssured * (10 ** 18);
        _addCovers(_user, _nftId, weiSumAssured, secondPrice, scAddress);
        
        // Add to utilization farming.
        if (ufOn) IUtilizationFarm(getModule("UFS")).stake(_user, secondPrice);
        
        emit StakedNFT(_user, scAddress, _nftId, weiSumAssured, secondPrice, coverPeriod, block.timestamp);
    }
    
    /**
     * @dev removeExpiredNft is called on many different interactions to the system overall.
     * @param _nftId The ID of the expired NFT.
    **/
    function _removeExpiredNft(uint256 _nftId)
      internal
    {
        address user = nftOwners[_nftId];
        _removeNft(_nftId);
        delete nftOwners[_nftId];
        emit ExpiredNFT(user, _nftId, block.timestamp);
    }

    /**
     * @dev Internal main removal functionality.
    **/
    function _removeNft(uint256 _nftId)
      internal
    {
        (/*coverId*/, /*status*/, uint256 sumAssured, uint16 coverPeriod, /*uint256 validuntil*/, address scAddress, 
         /*coverCurrency*/, /*premiumNXM*/, uint256 coverPrice, /*claimId*/) = IarNFT(getModule("ARNFT")).getToken(_nftId);
        address user = nftOwners[_nftId];
        require(user != address(0), "NFT does not belong to this contract.");

        ExpireTracker.pop(uint96(_nftId));

        uint256 weiSumAssured = sumAssured * (10 ** 18);
        uint256 secondPrice = coverPrice / (uint256(coverPeriod) * 1 days);
        _subtractCovers(user, _nftId, weiSumAssured, secondPrice, scAddress);
        
        // Exit from utilization farming.
        if (ufOn) IUtilizationFarm(getModule("UFS")).withdraw(user, secondPrice);

        emit RemovedNFT(user, scAddress, _nftId, weiSumAssured, secondPrice, coverPeriod, block.timestamp);
    }
    
    /**
     * @dev Need a force remove--at least temporarily--where owner can remove data relating to an NFT.
     *      This necessity came about when updating the contracts and some users started withdrawal when _removeNFT
     *      was in the second step of withdrawal, then executed the second step of withdrawal after _removeNFT had
     *      been moved to the first step of withdrawal.
    **/
    function forceRemoveNft(address[] calldata _users, uint256[] calldata _nftIds)
      external
      onlyOwner
    {
        require(_users.length == _nftIds.length, "Array lengths must match.");
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 nftId = _nftIds[i];
            address user = _users[i];
            (/*coverId*/, /*status*/, uint256 sumAssured, uint16 coverPeriod, /*uint256 validuntil*/, address scAddress, 
            /*coverCurrency*/, /*premiumNXM*/, uint256 coverPrice, /*claimId*/) = IarNFT(getModule("ARNFT")).getToken(nftId);
            //address user = nftOwners[_nftId];
            // require(user != address(0), "NFT does not belong to this contract.");
            require(nftOwners[nftId] == address(0) && ExpireTracker.infos[uint96(nftId)].next > 0, "NFT may not be force removed.");

            ExpireTracker.pop(uint96(nftId));

            uint256 weiSumAssured = sumAssured * (10 ** 18);
            uint256 secondPrice = coverPrice / (uint256(coverPeriod) * 1 days);
            _subtractCovers(user, nftId, weiSumAssured, secondPrice, scAddress);
            
            // Exit from utilization farming.
            if (ufOn) IUtilizationFarm(getModule("UFS")).withdraw(user, secondPrice);

            emit RemovedNFT(user, scAddress, nftId, weiSumAssured, secondPrice, coverPeriod, block.timestamp);
        }
    }

    /**
     * @dev Some NFT expiries used a different bucket step upon update and must be reset. 
    **/
    function forceResetExpires(uint256[] calldata _nftIds)
      external
      onlyOwner
    {
        uint64[] memory validUntils = new uint64[](_nftIds.length);
        for (uint256 i = 0; i < _nftIds.length; i++) {
            (/*coverId*/, /*status*/, /*uint256 sumAssured*/, /*uint16 coverPeriod*/, uint256 validUntil, /*address scAddress*/, 
            /*coverCurrency*/, /*premiumNXM*/, /*uint256 coverPrice*/, /*claimId*/) = IarNFT(getModule("ARNFT")).getToken(_nftIds[i]);
            require(nftOwners[_nftIds[i]] != address(0), "this nft does not belong here");
            ExpireTracker.pop(uint96(_nftIds[i]), 86400);
            ExpireTracker.pop(uint96(_nftIds[i]), 86400*3);
            validUntils[i] = uint64(validUntil);
        }
        for (uint256 i = 0; i < _nftIds.length; i++) {
            ExpireTracker.push(uint96(_nftIds[i]),uint64(validUntils[i]));
        }
    }
    // set desired head and tail
    function _resetBucket(uint64 _bucket, uint96 _head, uint96 _tail) internal {
        require(_bucket % BUCKET_STEP == 0, "INVALID BUCKET");
        checkPoints[_bucket].tail = _tail;
        checkPoints[_bucket].head = _head;
    }

    function resetBuckets(uint64[] calldata _buckets, uint96[] calldata _heads, uint96[] calldata _tails) external onlyOwner{
        for(uint256 i = 0 ; i< _buckets.length; i++){
            _resetBucket(_buckets[i], _heads[i], _tails[i]);
        }
    }

    /**
     * @dev Add to the cover amount for the user and contract overall.
     * @param _user The user who submitted.
     * @param _nftId ID of the NFT being staked (used for events on RewardManager).
     * @param _coverAmount The amount of cover being added.
     * @param _coverPrice Price paid by the user for the NFT per second.
     * @param _protocol Address of the protocol that is having cover added.
    **/
    function _addCovers(address _user, uint256 _nftId, uint256 _coverAmount, uint256 _coverPrice, address _protocol)
      internal
    {
        IRewardManager(getModule("REWARD")).stake(_user, _coverPrice, _nftId);
        totalStakedAmount[_protocol] = totalStakedAmount[_protocol].add(_coverAmount);
    }
    
    /**
     * @dev Subtract from the cover amount for the user and contract overall.
     * @param _user The user who is having the token removed.
     * @param _nftId ID of the NFT being used--must check if it has been submitted.
     * @param _coverAmount The amount of cover being removed.
     * @param _coverPrice Price that the user was paying per second.
     * @param _protocol The protocol that this NFT protected.
    **/
    function _subtractCovers(address _user, uint256 _nftId, uint256 _coverAmount, uint256 _coverPrice, address _protocol)
      internal
    {
        IRewardManager(getModule("REWARD")).withdraw(_user, _coverPrice, _nftId);
        if (!submitted[_nftId]) totalStakedAmount[_protocol] = totalStakedAmount[_protocol].sub(_coverAmount);
    }
    
    /**
     * @dev Check that the NFT should be allowed to be added. We check expiry and claimInProgress.
     * @param _validUntil The expiration time of this NFT.
     * @param _scAddress The smart contract protocol that the NFt is protecting.
     * @param _coverCurrency The currency that this NFT is protected in (must be ETH_SIG).
     * @param _coverStatus status of cover, only accepts Active
    **/
    function _checkNftValid(uint256 _validUntil, address _scAddress, bytes4 _coverCurrency, uint8 _coverStatus)
      internal
      view
    {
        require(_validUntil > now + 20 days, "NFT is expired or within 20 days of expiry.");
        require(_coverStatus == 0, "arNFT claim is already in progress.");
        require(allowedProtocol[_scAddress], "Protocol is not allowed to be staked.");
        require(_coverCurrency == ETH_SIG, "Only Ether arNFTs may be staked.");
    }
    
    /**
     * @dev Allow the owner (DAO soon) to allow or disallow a protocol from being used in Armor.
     * @param _protocol The address of the protocol to allow or disallow.
     * @param _allow Whether to allow or disallow the protocol.
    **/
    function allowProtocol(address _protocol, bool _allow)
      external
      // doKeep
      onlyOwner
    {
        if(protocolId[_protocol] == 0){
            protocolId[_protocol] = ++protocolCount;
            protocolAddress[protocolCount] = _protocol;
        }
        allowedProtocol[_protocol] = _allow;
    }
    
    /**
     * @dev Allow the owner to change the amount of delay to withdraw an NFT.
     * @param _withdrawalDelay The amount of time--in seconds--to delay an NFT withdrawal.
    **/
    function changeWithdrawalDelay(uint256 _withdrawalDelay)
      external
      // doKeep
      onlyOwner
    {
        withdrawalDelay = _withdrawalDelay;
    }
    
    /**
     * @dev Toggle whether utilization farming should be on or off.
    **/
    function toggleUF()
      external
      onlyOwner
    {
        ufOn = !ufOn;
    }

}