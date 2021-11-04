/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/BNBereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor () {
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
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, "");
  }

  function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, "", "");
  }

  function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
    return strConcat(_a, _b, "", "", "");
  }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

abstract contract ReentrancyGuarded {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.BNBereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract ERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external virtual view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) virtual external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) virtual external;

    function isApprovedForAll(address account, address operator) virtual external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) virtual external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) virtual external;
}
contract tokenAuction is ReentrancyGuarded, Ownable
{
    uint256 private tokenID;
    uint256 private auctionStartTime;
    uint256 private auctionDuration;
    uint256 private auctionEndTime;
    address public highestBidder;
    bool public AuctionOpen;
    uint256 numberOfBidders;
    address seller;
    struct participant{
        uint256 serial;
        uint256 bidamount;
        uint256 bidtime;
        bool locked;
        bool exist;
    }
    mapping (address => participant) public bidders;
    constructor(uint256 _tokenid, uint256 _start, uint256 _duration, address _tokenOwner)
    {
        tokenID = _tokenid;
        auctionStartTime = _start;
        auctionDuration = _duration;
        auctionEndTime = auctionStartTime + auctionDuration;
        highestBidder = address(0);
        numberOfBidders = 0;
        AuctionOpen = true;
        seller = _tokenOwner;
    }
    function participateInAuction(uint256 _amount, address _bidder) payable public returns (bool _success){
        require(!bidders[_bidder].exist, "Your already have placed your token for auction");
        require(_bidder != address(0));
        //require(_amount <= msg.value, "ambiguous bid");
        require(AuctionOpen, "Auction is over");
        if((auctionStartTime + block.timestamp) >= auctionEndTime)
          {
              AuctionOpen = false;
              return AuctionOpen;
          }
        bidders[_bidder].exist = true;
        bidders[_bidder].bidamount = _amount;
        bidders[_bidder].locked = true;
        bidders[_bidder].bidtime = block.timestamp;
        if(bidders[highestBidder].bidamount < _amount)
         highestBidder = _bidder;
        numberOfBidders += 1; 
         bidders[_bidder].serial = numberOfBidders;
    }
    function declareWinner() public view returns (address _winner) {
        require((auctionStartTime + block.timestamp) >= auctionEndTime, "Auction is still going on");
        require(highestBidder != address(0));
        return highestBidder;
        
    }
    function claimBackLockedBidAmount(address _claimer) public {
        require((auctionStartTime + block.timestamp) >= auctionEndTime, "Auction is still going on");
        require(bidders[_claimer].exist,"The claimer address does not match with any bidder in this auction");
        if(AuctionOpen)
         AuctionOpen = false;
        require(_claimer != highestBidder, "Winner can't get back bid amount, it will be transferred to seller");
        payable(_claimer).transfer(bidders[_claimer].bidamount);
    }
    
    function sendWinningamountToSeller(address _claimer, address _creator, address _feeRecipient, uint256 _adminFeePercent, uint256 _royaltyFeePercent) public {
        require((auctionStartTime + block.timestamp) >= auctionEndTime, "Auction is still going on");
        if(AuctionOpen)
         AuctionOpen = false;
        require(_claimer == highestBidder, "Only winner's bidamount will be transferred to seller");
        uint256 sellerFee = bidders[_claimer].bidamount;
        uint256 adminFee = (sellerFee * _adminFeePercent) / 100;
       uint256 creatorFee = 0;
       if(seller != _creator)
        {
           creatorFee = (sellerFee * _royaltyFeePercent) / 100;
           payable(_creator).transfer(creatorFee);
       }
        sellerFee -= adminFee + creatorFee;
        payable(_feeRecipient).transfer(adminFee);
        payable(seller).transfer(sellerFee);
        
    }
    function isHighestBidder(address _bidholder) public view returns(bool ){
        
        if(_bidholder == highestBidder)
         return true;
        return false; 
    }
    
    function isAuctionTimeOver() public view returns(bool _stat){
        if((auctionStartTime + block.timestamp) >= auctionEndTime)
        return true;
        
    }
    function setAuctionClose() public onlyOwner{
        if(isAuctionTimeOver())
            AuctionOpen = false;
    }
    

}

contract ArtileoTradeEngine is ReentrancyGuarded, Ownable
{

   ERC1155 private ARTILEOToken; 
   mapping(uint256 => bool) public tokenOnSale;
   
   struct TokenOnAuction{
        uint256 start;
        uint256 duration;
        tokenAuction auctionContract;
        bool auctionOpen;
    }
    
     mapping (uint256 => TokenOnAuction) public auctionOf;

   
   constructor()
   {
       ARTILEOToken = ERC1155(0x4690c5A407c3B515Ec4c1Acf0DC603A35ab412ca);
       
   }
   function enlistForSale(uint256 _id) public{
       require(!tokenOnSale[_id],"token is already on sale");
       require(!auctionOf[_id].auctionOpen, "Token is on auction");
       // call approval to approve this contract to transfer token with token id from msg_sender account
       require(ARTILEOToken.isApprovedForAll(msg.sender, address(this)),"Give approval to this trade engine first");
        tokenOnSale[_id] = true;
       
       
   }
   function enlistForAuction(uint256 _id, uint256 _start, uint256 _duration) public returns(tokenAuction _contract){
       require(!auctionOf[_id].auctionOpen, "Auction is already listed");
       require(!tokenOnSale[_id],"token is on sale");
       require(ARTILEOToken.isApprovedForAll(msg.sender, address(this)),"Please approve our trade engine app to use your token");
        
        tokenAuction auction = new tokenAuction(_id, _start, _duration, msg.sender);    
        auctionOf[_id] = TokenOnAuction({
                                        start: _start,
                                        duration: _duration,
                                        auctionContract: auction,
                                        auctionOpen: true
                                    });
        return auction;                            
        
       
   }
   function isTokenOnAuction(uint256 _id) public view returns(bool _status)
   {
       
       if(auctionOf[_id].auctionOpen)
        return true;
       return false;
        
   }
   function isTokenOnSale(uint256 _id) public view returns(bool _status)
   {
       if(tokenOnSale[_id])
        return true;
       return false;   
   }
   function buyToken(uint256 _id, address _buyfrom, address _feeRecipient, address _creator, uint256 _adminFeePercent, uint256 _royaltyFeePercent, bytes calldata data) public payable nonReentrant{
       require(ARTILEOToken.isApprovedForAll(_buyfrom, address(this)) && tokenOnSale[_id],"The token is not on sale");
          //address buyer = msg.sender;
          //address seller = _buyfrom;
       //send received wei to seller
       uint256 sellerFee = msg.value;
       uint256 adminFee = (msg.value * _adminFeePercent) / 10000;
       uint256 creatorFee = 0;
       if(_buyfrom != _creator)
        {
           creatorFee = (msg.value * _royaltyFeePercent) / 10000;
           payable(_creator).transfer(creatorFee);
       }
        sellerFee = sellerFee - (adminFee + creatorFee);
        payable(_feeRecipient).transfer(adminFee);
        payable(_buyfrom).transfer(sellerFee);
        tokenOnSale[_id] = false;
        //transfer token from seller to buyer
        ARTILEOToken.safeTransferFrom(_buyfrom, msg.sender, _id, 1, data);
   }
   
   function bidFor(uint256 _id, address _seller) external payable nonReentrant{
       require(auctionOf[_id].auctionOpen, "Token is not listed for auction");
        //check if this contract is apporovd to send tokens on behalf of seller
        require(ARTILEOToken.isApprovedForAll(_seller, address(this)) && auctionOf[_id].auctionOpen,"The token auction is either closed or not listed");
      //
      tokenAuction auctionContract = tokenAuction(auctionOf[_id].auctionContract);
       if(auctionContract.participateInAuction(msg.value,msg.sender))
         payable(address(auctionContract)).transfer(msg.value);
        else
            auctionOf[_id].auctionOpen = false;
         
   }
   
   function claimBackBidAmountFor(uint256 _id) public{
       require(!auctionOf[_id].auctionOpen, "When auction is going your bidamount is locked");
       tokenAuction auctionContract = tokenAuction(auctionOf[_id].auctionContract);
       if(auctionContract.isAuctionTimeOver())
         auctionContract.setAuctionClose();
       else     
         revert();
       auctionContract.claimBackLockedBidAmount(msg.sender);
   
   }
   function settleWithAuctionWinner(uint256 _id,address _creator, address _feeRecipient, uint256 _adminFeePercent, uint256 _royaltyFeePercent) public
   {
       require(!auctionOf[_id].auctionOpen, "When auction is going your bidamount is locked");
       tokenAuction auctionContract = tokenAuction(auctionOf[_id].auctionContract);
       require(auctionContract.isHighestBidder(msg.sender), "only winner can settle");
       if(auctionContract.isAuctionTimeOver())
         auctionContract.setAuctionClose();
       else     
         revert();
       auctionContract.sendWinningamountToSeller(msg.sender, _creator, _feeRecipient, _adminFeePercent, _royaltyFeePercent);       
   }
   
   
}