/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155Receiver is IERC165 {


    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}


contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
  
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
       

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC1155 {
  
   function balanceOf(address account, uint256 id) external view returns (uint256);
   function setApprovalForAll(address operator, bool approved) external;
   function isApprovedForAll(address account, address operator) external view returns (bool);
   function getNFTCount() external view returns (uint256);
   function getCreator(uint256 _tokenId) external view returns (address);
   function getFee(uint256 _tokenId) external view returns (uint256);
   function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
   
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

   
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

   
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

  
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

   
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

  
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

   
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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC1155 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 amount, uint256 value, bytes calldata data) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.safeTransferFrom.selector, from, to, id, amount, value, data)
        );
    }

    function setApprovalForAll(IERC1155 token, address operator, bool approved) internal {
          require(msg.sender != operator, "ERC1155: setting approval status for self");
        callOptionalReturn(token, abi.encodeWithSelector(token.setApprovalForAll.selector, operator, approved));
    }


   function isApprovedForAll(IERC1155 token, address account, address operator) internal {
          require(msg.sender != operator, "ERC1155: setting approval status for self");
        callOptionalReturn(token, abi.encodeWithSelector(token.setApprovalForAll.selector, account, operator));
   }


   function balanceOf(IERC1155 token, uint256 id) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.setApprovalForAll.selector, id));
   }

    function callOptionalReturn(IERC1155 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
         
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract BundNFTMarketPlace is Ownable, IERC1155, ERC1155Holder {
    using SafeMath for uint256;
    using Address for address;
   
   struct StructAuction {
        uint auctionEndTime;
        address highestBidder;
        uint highestBid;
        mapping(address => uint) pendingReturns;
        uint256 startPrice;
        bool finished;
        mapping(address => uint256) myCurrendBid;
   }
   
   //-----| 50 for 5 % |------| 80 for 8% |----| 100 for 10% |------ 
   uint256 public feePercent = 50; 
   address public feeCollector;

   mapping (address => mapping (uint256 => uint256)) internal mappingForNFTPrice;
   mapping (address => mapping (uint256 => uint256)) internal mappingForNFTQuantity;

   mapping (address => mapping (uint256 => uint256)) internal mappingQuantitySold; 
   mapping (address => mapping (uint256 => uint256)) internal mappingQuantityAuctioned;  
   mapping (address => mapping (uint256 => StructAuction)) mappingAuction;
   mapping (address => mapping (uint256 => uint256)) mappingApproval;
   mapping (uint256 => address[]) internal _mappingSellers;
   mapping (address => mapping (uint256 => bool)) internal _mappingCheckSellerExists;
   mapping (uint256 => address[]) public _mappingBidCreators;  // store bidCreators for tokenId
   mapping (address => mapping (uint256 => bool)) public _mappingCheckBidExists;  // returns true or false if exists

   mapping (address => string[]) public mappingSalesHistory; // returns => tokenId, price, quantity, timestamp 
   mapping (address => string[]) public mappingAuctionData; // returns => tokenId, price, quantity, timestamp 


   mapping (address => string[]) public mappingAuctionDetails; // returns => tokenId, price, quantity, timestamp 
   
   event NFTPurchased(address indexed seller, address indexed receiver, uint256 nftId, uint256 quantity);
   event HighestBidIncreased(address indexed bidder, uint amount);
   event AuctionFinalized(address indexed winner, uint amount);

    IERC1155 public nftInstance;

       constructor(address _bundNFTFactory) {
        nftInstance = IERC1155(_bundNFTFactory); 
    }
  
    function setFeeCollector(address _feeCollector) public onlyOwner{
      feeCollector = _feeCollector;
    }

    //------------| Currently set to 5% |---------------
    function setPlatformFee(uint256 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }
    
    function findFeePercent(uint256 _feePercent, uint256 amount) internal pure returns (uint256) {
        return amount.mul(_feePercent).div(1000);
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        return nftInstance.balanceOf(account, id);
    }

    function setApprovalForAll(address account, bool approved) public override{
        nftInstance.setApprovalForAll(account, approved); 
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return nftInstance.isApprovedForAll(account, operator);
    }

    function safeTransferFrom(address from,address to, uint256 id, uint256 amount, bytes memory data)public virtual override {
        return nftInstance.safeTransferFrom(from, to, id, amount, data);  
    }

    function getNFTCount() public view virtual override returns (uint256) {
        return nftInstance.getNFTCount();
    }

    function getCreator(uint256 _tokenId) public view virtual override returns (address) {
        return nftInstance.getCreator(_tokenId);
    }

    function getFee(uint256 _tokenId) public view virtual override returns (uint256) {
        return nftInstance.getFee(_tokenId);
    }

    // --------| Get the sellers |----| By Id |---------- 
    function getSellersById(uint256 _tokenId) public view virtual returns (address[] memory) {
        return _mappingSellers[_tokenId];
    }

      // --------| Get the sellers |----| By Id |---------- 
    function getSellerCountById(uint256 _tokenId) public view virtual returns (uint256) {
        return _mappingSellers[_tokenId].length;
    }


    function getBidCreatorsById(uint256 _tokenId) public view virtual returns (address[] memory) {
        return _mappingBidCreators[_tokenId];
    }
    

    function getBidCreatorCountById(uint256 _tokenId) public view virtual returns (uint256) {
        return _mappingBidCreators[_tokenId].length;
    }
    


    //----------------| Seller management |----------------
    function recordSeller(uint256 _tokenId) internal returns(bool){
        if(_mappingCheckSellerExists[msg.sender][_tokenId] == false){
           _mappingSellers[_tokenId].push(msg.sender); 
           _mappingCheckSellerExists[msg.sender][_tokenId] = true;
        }
        return true;
    }
  
    function removeSeller(uint256 _tokenId, uint _indexAt, address _seller) internal {
        while (_indexAt < _mappingSellers[_tokenId].length-1) {
            _mappingSellers[_tokenId][_indexAt] = _mappingSellers[_tokenId][_indexAt+1];
            _indexAt++;
        }
        _mappingSellers[_tokenId].pop();
        _mappingCheckSellerExists[_seller][_tokenId] = false;
      
    }
     
    function find(address _acount, address[] memory inputArray) public pure returns(uint) {
        uint loop = 0;
        while (inputArray[loop] != _acount) {
            loop++;
        }
        return loop;
    }

    //------------| Bid creator management |--------------
    function recordBidCreator(uint256 _tokenId) internal returns(bool){
        if(_mappingCheckBidExists[msg.sender][_tokenId] == false){
           _mappingBidCreators[_tokenId].push(msg.sender); 
           _mappingCheckBidExists[msg.sender][_tokenId] = true;
        }
         return true;
    }
     
    function removeBidCreator(uint256 _tokenId, uint _indexAt, address _seller) internal {
        while (_indexAt < _mappingBidCreators[_tokenId].length-1) {
            _mappingBidCreators[_tokenId][_indexAt] = _mappingBidCreators[_tokenId][_indexAt+1];
            _indexAt++;
        }
        _mappingBidCreators[_tokenId].pop();
        _mappingCheckBidExists[_seller][_tokenId] = false;
      
    }
    
    // ** On setting the price, NFT will be transferred to this contract.
    function setSellingPriceForNFT(uint256 _id, uint256 _quantity, uint256 _priceInWeiForm) public {
     require(feeCollector != address(0), "Fee collector is not set");
     require(_id < getNFTCount(), "This NFT does not exists");
     require(recordSeller(_id) == true, "Seller was not recorded");
     
     mappingForNFTPrice[msg.sender][_id] = _priceInWeiForm;
     mappingForNFTQuantity[msg.sender][_id] = _quantity;
     mappingQuantitySold[msg.sender][_id] += _quantity; // count NFT
   
    //  mappingClaim[msg.sender][_id][true] = _quantity; 
      
     safeTransferFrom(msg.sender, address(this), _id , _quantity, ""); // transfer to contract
     
    }

    function calculateSellerSpecificNFTPrice(address _seller, uint256 _id) public view returns (uint256){
     return mappingForNFTPrice[_seller][_id];
    }

    function calculateSellerSpecificNFTQuantity(uint256 _id, address _seller) public view returns (uint256){
     return mappingForNFTQuantity[_seller][_id];
    }

    function getNFTForSold(uint256 _id, address _seller) public view returns (uint256){
     return mappingQuantitySold[_seller][_id];
    }

    function getNFTForAuction(uint256 _id, address _seller) public view returns (uint256){
     return mappingQuantityAuctioned[_seller][_id];
    }

    //---------------------------------------------------------------------------------------------

    // Returns a string containing all details
    function getSalesHistory() public view returns(string[] memory){
      return mappingSalesHistory[msg.sender];
    }

    function getAuctionData() public view returns(string[] memory){
      return mappingAuctionData[msg.sender];
    }

    // Set Sales history as a single string with all the details
    function setSalesHistory(string memory tokenId, string memory price, string memory quantity, string memory timestamp, string memory types, address _user) public {
      string memory sample = string(abi.encodePacked(tokenId,"|", price, "|", quantity, "|", timestamp, "|", types));
      mappingSalesHistory[_user].push(sample);

    }

    function setAuctionData(string memory tokenId, string memory price, string memory duration, string memory timestamp, address _user) public {
      string memory dataString = string(abi.encodePacked(tokenId,"|", price, "|", duration, "|", timestamp));
      mappingAuctionData[_user].push(dataString);

    }
     
    function devCounter() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    //-----------------------------------------------------------------------------------------
    function getAuctionDetails() public view returns(string[] memory){
      return mappingAuctionDetails[msg.sender];
    }

    function setAuctionDetails(string memory tokenId, string memory seller) public {
      string memory sample = string(abi.encodePacked(tokenId,"|", seller));
      mappingAuctionDetails[msg.sender].push(sample);
    }

    //------------------------------------------------------------------------------------------

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function addressToString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toString(address account) internal pure returns(string memory) {
        return addressToString(abi.encodePacked(account));
    }


    /**
      => Once NFT is sold, storing updated "claimable NFT".
    */
    function purchaseNFTForETH(uint256 _id, uint256 _quantity, address _seller) public payable {
        require(msg.value >= _quantity.mul(calculateSellerSpecificNFTPrice(_seller, _id)), "Less than net ETH amount sent");
        require(_quantity <= calculateSellerSpecificNFTQuantity( _id, _seller), "Amount exceeding quantity set by seller.");
        uint256 sumAmt;
        uint256 sellerETH;
       
        payable(getCreator(_id)).transfer(findFeePercent(getFee(_id), msg.value));  // Royality to NFT creator 
       
        payable(feeCollector).transfer(findFeePercent(feePercent, msg.value));      // Platform fee 
        sumAmt = findFeePercent(feePercent, msg.value).add(findFeePercent(getFee(_id), msg.value));
       
        sellerETH = msg.value.sub(sumAmt);  // ETH received - Overall deductions

        payable(_seller).transfer(sellerETH);  // Rest of amount
        mappingForNFTQuantity[_seller][_id] -= _quantity;    
        
        safeTransferFrom(address(this), msg.sender, _id , _quantity, ""); 
        
        if( mappingForNFTQuantity[_seller][_id] == 0){
         removeSeller(_id, find(_seller, _mappingSellers[_id]), _seller);   // Remove seller if they dont have tokens.
        }
 
        // Stores => tokenId , price, quantity, timestamp, types |for user and seller|
        setSalesHistory(uint2str(_id), uint2str(msg.value), uint2str(_quantity), uint2str(block.timestamp), "buy", msg.sender);
        setSalesHistory(uint2str(_id), uint2str(msg.value), uint2str(_quantity), uint2str(block.timestamp), "sale", _seller);

        mappingQuantitySold[_seller][_id] -= _quantity;

        emit NFTPurchased(_seller, msg.sender, _id, _quantity);

    }

    function getAuctionEndTime(address _seller, uint256 _tokenId) public view returns (uint256) {
     return mappingAuction[_seller][_tokenId].auctionEndTime;
    }

    function getPendingReturns(address _seller, uint256 _tokenId) public view returns (uint256) {
     return mappingAuction[_seller][_tokenId].pendingReturns[msg.sender];
    }

    function getMyCurrentBid(address _seller, uint256 _tokenId) public view returns (uint256) {
     return mappingAuction[_seller][_tokenId].myCurrendBid[msg.sender];
    }

    function getHighestBid(address _seller, uint256 _tokenId) public view returns (uint256) {
     return mappingAuction[_seller][_tokenId].highestBid;
    }

    function getHighestBidder(address _seller, uint256 _tokenId) public view returns (address) {
     return mappingAuction[_seller][_tokenId].highestBidder;
    }
 
    // False = Auction finished || True = Auction Running
    function checkIfAuctionFinished(address _seller, uint256 _tokenId) public view returns (bool) {
     return mappingAuction[_seller][_tokenId].finished;
    }

    function checkAuctionStartPrice(address _seller, uint256 _tokenId) public view returns (uint256) {
     return mappingAuction[_seller][_tokenId].startPrice;
    }

    
    /** 
        => Every auction start , 1 NFT will be transferred to contract |---
        => Finished value must be false to start the auction
    */
    function startAuction(uint256 _duration, uint256 _tokenId, uint256 _startPrice) public {      
        
        require(!mappingAuction[msg.sender][_tokenId].finished, "Current session is running"); // must be false
        require(feeCollector != address(0), "Fee collector is not set");
        require(balanceOf(msg.sender, _tokenId) > 0, "You do not possess this NFT");
        require(recordBidCreator(_tokenId) == true, "Bid creator not recorded");
        
        mappingAuction[msg.sender][_tokenId].auctionEndTime = block.timestamp.add(_duration);
        mappingAuction[msg.sender][_tokenId].startPrice = _startPrice;
        mappingAuction[msg.sender][_tokenId].finished = true;

        safeTransferFrom(msg.sender, address(this), _tokenId , 1, ""); 
        mappingQuantityAuctioned[msg.sender][_tokenId] += 1;           // count NFT

        setAuctionData(uint2str(_tokenId), uint2str(_startPrice), uint2str(mappingAuction[msg.sender][_tokenId].auctionEndTime), uint2str(block.timestamp), msg.sender);
        mappingAuction[msg.sender][_tokenId].highestBidder = msg.sender; // If no one bid, NFT is not lost

    }

    /**  
       => Next bid amount > current + msg.value
       => Withdrawable amount (pendingReturns)
       => My Bid Current : withdrawable + msg.value

    */  
    function bid(address _seller, uint256 _tokenId) public payable {
        
        require(mappingAuction[_seller][_tokenId].finished, "This auction has not been started yet!.");
        require(block.timestamp <= mappingAuction[_seller][_tokenId].auctionEndTime, "Invalid seller or auction already finished.");
        
        uint256 discarded = mappingAuction[_seller][_tokenId].pendingReturns[msg.sender]; 

        require(discarded.add(msg.value) > mappingAuction[_seller][_tokenId].startPrice, "Bid must be higher than start price");
        require(discarded.add(msg.value) > mappingAuction[_seller][_tokenId].highestBid, "There already is a higher bid.");
       
        if (mappingAuction[_seller][_tokenId].highestBid != 0) {
            
            address highestBDR = mappingAuction[_seller][_tokenId].highestBidder;  // Record payment for discarded bidder
            mappingAuction[_seller][_tokenId].pendingReturns[highestBDR] = mappingAuction[_seller][_tokenId].highestBid;
        }

        // my curent bid | Reset this ** | Once auction finalised
        mappingAuction[_seller][_tokenId].myCurrendBid[msg.sender] = discarded.add(msg.value);

        mappingAuction[_seller][_tokenId].highestBidder = msg.sender;
        // Highest bid = previous bid + current fund 
        mappingAuction[_seller][_tokenId].highestBid = discarded.add(msg.value);
            
        // store tokenID and seller as => string
        // ** then reset it once auction finalized

        setAuctionDetails(uint2str(_tokenId), toString(_seller));

        emit HighestBidIncreased(msg.sender, discarded.add(msg.value));
            
    }


    // Discarded bidder can withdraw their fund. 
    function withdraw(address _seller, uint256 _tokenId) public {
        require(block.timestamp >= mappingAuction[_seller][_tokenId].auctionEndTime, "Can withdraw once auction finished.");
        uint amount = mappingAuction[_seller][_tokenId].pendingReturns[msg.sender];
        require(amount > 0, " You bid history is not available");
        mappingAuction[_seller][_tokenId].pendingReturns[msg.sender] = 0; //____| Reset Amount |_____
        payable(msg.sender).transfer(amount);

        mappingAuction[_seller][_tokenId].myCurrendBid[msg.sender] = 0 ; // Reset my current bid if fund was withdrawn
                
    }

    function finalizeAuction(address _seller, uint256 _tokenId) public {
        require(block.timestamp >= mappingAuction[_seller][_tokenId].auctionEndTime, "Auction not yet started or finished.");
        require(mappingAuction[_seller][_tokenId].finished, "Auction already finished!.");
       
        mappingAuction[_seller][_tokenId].finished = false;
        address winner = mappingAuction[_seller][_tokenId].highestBidder;            
        safeTransferFrom(address(this), winner, _tokenId , 1, ""); // transfer from contract
        uint256 bidAmount = mappingAuction[_seller][_tokenId].highestBid;
        mappingQuantityAuctioned[_seller][_tokenId] -= 1; // Remove count once Auction is finished
       
        //----| Royality to NFT creator |---------------
        payable(getCreator(_tokenId)).transfer(findFeePercent(getFee(_tokenId), bidAmount)); 
        payable(feeCollector).transfer(findFeePercent(feePercent, bidAmount)); // 5 %
        payable(_seller).transfer(bidAmount.sub(findFeePercent(feePercent, bidAmount)).sub(findFeePercent(getFee(_tokenId), bidAmount))); // 95%

        removeBidCreator(_tokenId, find(_seller, _mappingBidCreators[_tokenId]), _seller); // remove the bid Creator
    
        
        setSalesHistory(uint2str(_tokenId), uint2str(bidAmount), "1", uint2str(block.timestamp), "auction", msg.sender); 
        
        mappingAuction[_seller][_tokenId].myCurrendBid[winner] = 0 ;

        emit AuctionFinalized(winner, mappingAuction[_seller][_tokenId].highestBid);
     }


}