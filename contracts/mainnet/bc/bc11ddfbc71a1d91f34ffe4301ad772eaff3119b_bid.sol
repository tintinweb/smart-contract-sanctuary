/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.6.12;

//import "@openzeppelin/contracts/access/Ownable.sol";
/* openzeppelin*/
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/* openzeppelin*/

library TransferHelper {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }

    
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
	function approve(address guy, uint256 wad) external returns (bool);
	function transferFrom(
		address src,
		address dst,
		uint256 wad
	) external returns (bool);
}

contract bid  is Ownable ,Pausable {

    using SafeMath for uint256;

    uint256 maintainerPayment;
    uint256 creatorPayment;
    uint256 ownerPayment;

    address private aart;
    address private platformAddress;

    // Percentage to owner of SupeRare. (* 10) to allow for < 1% 
    uint256 public maintainerPercentage = 150;

    // Percentage to creator of artwork. (* 10) to allow for tens decimal. 
    uint256 public creatorPercentage = 100;

    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    
    struct currentbidder{
        address   token;
        address   curr;
        uint256   price;
        uint256   lastbid;
        uint256   addpercentage;
        bool      status;
    }

    receive() external payable {}

      constructor(address _aart,address _platformAddress) public {  
        require(_aart != address(0),"_aart is zero");
        aart = _aart;
        platformAddress = _platformAddress;
    }
    

    event PlatformAddressUpdated (address platformAddress);
    event AcceptBid(address from,address to, uint256 id,uint256 value);
    event Bid(address bidder,uint256 value,uint256 id);
    //event Bid2(address from,address owner ,uint256 id);
    event SaleBidSet(address token,uint256 tokenId, uint256 salePrice);
    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
   
    mapping(uint256 => currentbidder) public cb;

    // Mapping from token ID to the owner sale price
    mapping(uint256 => uint256) private tokenSalePrice;


    //Check that the sender is the owner or maintainer
    modifier ownerOrtokenof(uint256 _tokenid) {
        require( msg.sender == IERC721(aart).ownerOf(_tokenid) || owner() == msg.sender,"must be owner or admin" );
        _;      
    }

    //Check that the sender is the token of owner
    modifier onlyOwnerOf(uint256 _tokenid) {
        require( msg.sender == IERC721(aart).ownerOf(_tokenid) ,"must be token of owner" );
        _;
    }

    /**
     * @dev Guarantees msg.sender is not the owner of the given token
     * @param _tokenid uint256 ID of the token to validate its ownership does not belongs to msg.sender
     */
    modifier notOwnerOf(uint256 _tokenid) {
        require(IERC721(aart).ownerOf(_tokenid) != msg.sender,"only other accounts are allowed");
        _;
    }

    
    function pause() public onlyOwner() {
        _pause();
    }

    function unpause() public onlyOwner() {
        _unpause();
    }

    /**
     * @dev Set the bid price of the token
     * @param _tokenid uint256 ID of the token with the standing bid
     */
    function setbid(address _token,uint256 _tokenid,uint256 _price,uint256 _addpercentage) public onlyOwnerOf(_tokenid) whenNotPaused() {
        require(cb[_tokenid].status != true,"Repeat setting");
        require(_price > 0,"must gt zero");
        require(_addpercentage > 0,"must gt zero");
        cb[_tokenid].token = _token;
        cb[_tokenid].price = _price;
        cb[_tokenid].addpercentage = _addpercentage;
        cb[_tokenid].status = true;
        emit SaleBidSet(_token,_tokenid, _price);
    }

    // update the Platform Address
    function updatePlatformAddress(address newPlatformAddress) public onlyOwner() {
        require(newPlatformAddress != address(0));
        platformAddress = newPlatformAddress;

        emit PlatformAddressUpdated(newPlatformAddress);
    }

    /**
    * @dev Gets the sale price of the token
    * @param _tokenid uint256 ID of the token
    * @return sale price of the token
    */
    function SalePriceOfToken(uint256 _tokenid) public view returns (uint256) {
        return tokenSalePrice[_tokenid];
    }

     /**
    * @dev Gets the current bid and bidder of the token
    * @param _tokenid uint256 ID of the token to get bid details
    * @return bid amount and last bid amount and bidder address of token
    */
    function currentBidDetailsOfToken(uint256 _tokenid) public view returns (uint256, address,uint256) {
        return (cb[_tokenid].price, cb[_tokenid].curr,cb[_tokenid].lastbid);
    }


    /**
     * @dev Cancels the bid on the token, returning the bid amount to the bidder.
     * @param _tokenid uint256 ID of the token with a bid
     */
    function cacelbid(uint256 _tokenid) public ownerOrtokenof(_tokenid) whenNotPaused() {
        require(cb[_tokenid].status,"status is not true");

        address tk = cb[_tokenid].token;
        address cur = cb[_tokenid].curr;
        uint value = cb[_tokenid].lastbid;

        returnCurrentBid(tk,cur,0,value,_tokenid);

        // add 210615 delete
        delete cb[_tokenid];
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'AART BID: TRANSFER_FAILED');
    }

     /**
     * @dev Set the maintainer Percentage. Needs to be 10 * target percentage
     * @param _percentage uint256 percentage * 10.
     */
    function setMaintainerPercentage(uint256 _percentage) public onlyOwner() {
       maintainerPercentage = _percentage;
    }

    /**
     * @dev Set the creator Percentage. Needs to be 10 * target percentage
     * @param _percentage uint256 percentage * 10.
     */
    function setCreatorPercentage(uint256 _percentage) public onlyOwner() {
       creatorPercentage = _percentage;
    }

    /**
     * @dev Set the sale price of the token
     * @param _tokenid uint256 ID of the token with the standing bid
     */
    function setSalePrice(uint256 _tokenid, uint256 _salePrice) public onlyOwnerOf(_tokenid) {
        tokenSalePrice[_tokenid] = _salePrice;
        emit SalePriceSet(_tokenid, _salePrice);
    }

     /**
     * @dev Purchase the token if there is a sale price; transfers ownership to buyer and pays out owner.
     * @param _tokenid uint256 ID of the token to be purchased
     */
    function buy(uint256 _tokenid) public payable whenNotPaused() notOwnerOf(_tokenid) {
        uint256 salePrice = tokenSalePrice[_tokenid];
        uint256 sentPrice = msg.value;
        address buyer = msg.sender;
        require(salePrice > 0);
        require(sentPrice >= salePrice);

        maintainerPayment = sentPrice.mul(maintainerPercentage).div(1000);
        ownerPayment = sentPrice.sub(maintainerPayment);

        address tokenOwner = IERC721(aart).ownerOf(_tokenid);

        TransferHelper.safeTransferETH(platformAddress,maintainerPayment);
        TransferHelper.safeTransferETH(tokenOwner,ownerPayment);

        IERC721(aart).transferFrom(tokenOwner,buyer,_tokenid);

        tokenSalePrice[_tokenid] = 0;
        emit Sold(buyer, tokenOwner, sentPrice, _tokenid);
    }

     /**
    * @dev Internal function to check that the bid is larger than current bid
    * @param _tokenid uint256 ID of the token with the standing bid
    */
    function isGreaterBid(address _token,uint256 _tokenid,uint256 _value) private view returns (bool) {
    
        uint256  addbid = cb[_tokenid].lastbid.mul(cb[_tokenid].addpercentage ).div(1000);  
        uint256  currbid = cb[_tokenid].lastbid.add(addbid);

          //Check bid amount
        if (_token == address(0)) {
            //require(msg.value > cb[_tokenid].price && msg.value > cb[_tokenid].lastbid,"Bid must be greater than price or lastbid ");
            require(msg.value > cb[_tokenid].price && msg.value >= currbid,"Bid must be greater than price or lastbid");
        } else {
            //require(_value > cb[_tokenid].price && _value > cb[_tokenid].lastbid,"Bid must be greater than price or lastbid");
            require(_value > cb[_tokenid].price && _value >= currbid,"Bid must be greater than price or lastbid");
        }

        return true;
    }

    /**
     * @dev Accept the bid on the token, transferring ownership to the current bidder and paying out the owner.
     * @param _tokenid uint256 ID of the token with the standing bid
     */
    function acceptbid(uint256 _tokenid) public payable ownerOrtokenof(_tokenid) whenNotPaused() {
        // Get the nft token of owner
        address own = IERC721(aart).ownerOf(_tokenid);

        address tk = cb[_tokenid].token;
        address to = cb[_tokenid].curr;
        uint256 value  = cb[_tokenid].lastbid;

        //transfer nft to the last bidder
        IERC721(aart).transferFrom(own,to,_tokenid);

        maintainerPayment = value.mul(maintainerPercentage).div(1000);
        ownerPayment = value.sub(maintainerPayment);       

        //transfer token
        if (tk == address(0)) {
            TransferHelper.safeTransferETH(platformAddress,maintainerPayment);
            TransferHelper.safeTransferETH(own,ownerPayment);
        } else {
            // token transfer to the receiver
            _safeTransfer(tk, platformAddress, maintainerPayment);
            _safeTransfer(tk, own, ownerPayment);
        }

        // add 210615 delete
        delete cb[_tokenid];

        emit AcceptBid(msg.sender,to,_tokenid,value);
    }


    /**
    * @dev Internal function to return funds to current bidder.
    * @param _tokenid uint256 ID of the token with the standing bid
    */
    function returnCurrentBid(address _token,address _receiver,uint256 _value,uint256 _rvalue,uint256 _tokenid) private returns(uint256) {

        uint256  value;       
        if (_token == address(0)) {
            //require(msg.value > cp,"msg.value must be greater than");
            TransferHelper.safeTransferETH(_receiver,_rvalue);
            cb[_tokenid].lastbid = msg.value;
            value = msg.value;
        } else {
            // token transfer to this contract
            if (_value > 0){
            TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _value);
            }
            // token refund to ths last bider
            if (_rvalue > 0){
                _safeTransfer(_token, _receiver, _rvalue);
            }
            
            cb[_tokenid].lastbid = _value;
            value = _value;
        }
        return value;

    }

    /**
    * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
    * @param _tokenid uint256 ID of the token to bid on
    * @param _token erc20 token contract address
    * @param _value erc20 token current bid,others is 0
    */
    function bid1(address _token,uint256 _value,uint256 _tokenid) public payable whenNotPaused()  notOwnerOf(_tokenid) returns(bool) {

        // check nft token status
        require(cb[_tokenid].status,"status is false");
        require(cb[_tokenid].token == _token,"token check failed");
        require(IERC721(aart).ownerOf(_tokenid) != msg.sender,"only other accounts are allowed");
        
        //Check bid amount
        require(isGreaterBid(_token,_tokenid,_value),"check bid amount failed");

        // last bidder
        address  lastbidder = cb[_tokenid].curr;
        uint256  cp = cb[_tokenid].lastbid;

        //return funds to current bidder
        uint256 value = returnCurrentBid(_token,lastbidder,_value,cp,_tokenid);

        
        cb[_tokenid].token = _token;
        cb[_tokenid].curr = msg.sender;
        
        // emit event
        emit Bid(msg.sender,value,_tokenid);
        return true;
    }

 
}