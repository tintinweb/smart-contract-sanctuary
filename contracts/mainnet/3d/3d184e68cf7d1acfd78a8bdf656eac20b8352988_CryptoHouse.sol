/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
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
            if (returndata.length > 0) {

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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract CryptoHouse is ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;
   
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    
    string private _baseURI;
    address payable public author;

	string constant public _name = "CryptoHouse";
	string constant public _symbol = "HOUSE";
	uint256 public _totalSupply = 250;
	
    uint public houseRemainingToAssign = 0;
    
    struct Offer {
        bool isForSale;
        uint houseIndex;
        address seller;
        uint minValue;      
        address onlySellTo;     
    }

    struct Bid {
        bool hasBid;
        uint houseIndex;
        address bidder;
        uint value;
    }
    
    struct Info {
        uint houseIndex;
        string authorInfo;
        string publicInfo;
    }
    
    mapping (uint256 => string) private _tokenURIs;
        
    mapping (address => uint256) public _balances;
    mapping (uint => address) public _owners;

    mapping (uint => Offer) public houseOfferedForSale;
    mapping (uint => Bid) public houseBids;
    mapping (uint => Info) public houseInfo;

    mapping (address => uint) public pendingWithdrawals;
    mapping (uint256 => address) public _tokenApprovals;
    mapping (address => mapping (address => bool)) public _operatorApprovals;
    
    event HouseTransferAllowance(uint256 indexed houseIndex, address indexed fromAddress, address indexed toAddress);
    event HouseTransferAllowanceForAll(address indexed fromAddress, address indexed toAddress, bool indexed approved);
    event AssignHouse(uint256 indexed houseIndex, address indexed toAddress);
    event HouseTransfer(uint256 indexed houseIndex, address indexed fromAddress, address indexed toAddress);
    event HouseOffered(uint indexed houseIndex, uint minValue, address indexed toAddress);
    event HouseBidEntered(uint indexed houseIndex, uint value, address indexed fromAddress);
    event HouseBidWithdrawn(uint indexed houseIndex, uint value, address indexed fromAddress);
    event HouseBought(uint indexed houseIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event HouseNoLongerForSaleEvent(uint indexed houseIndex);
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owners[tokenId];
    }
    
    function getAllOwnerOf() public view returns (address[] memory _holder) {
        address[] memory holders = new address[](totalSupply());
         
        for(uint i = 0; i < totalSupply(); i++) {
            holders[i] = _owners[i];
        }
        
        return (holders);
    }
    
    function getHouseOfferedForSale() public view returns (bool[] memory _isForSale, uint[] memory _houseIndex, address[] memory _seller, uint[] memory _minValue, address[] memory _onlySellTo) {
        bool[] memory isForSale = new bool[](totalSupply());
        uint[] memory houseIndex = new uint[](totalSupply());
        address[] memory seller = new address[](totalSupply());
        uint[] memory minValue = new uint[](totalSupply());
        address[] memory onlySellTo = new address[](totalSupply());
        
        for(uint i = 0; i < totalSupply(); i++) {
            isForSale[i] = houseOfferedForSale[i].isForSale;
            houseIndex[i] = houseOfferedForSale[i].houseIndex;
            seller[i] = houseOfferedForSale[i].seller;
            minValue[i] = houseOfferedForSale[i].minValue;
            onlySellTo[i] = houseOfferedForSale[i].onlySellTo;
        }
        
        return (isForSale, houseIndex, seller, minValue, onlySellTo);
    }

    function getHouseBids() public view returns (bool[] memory _hasBid, uint[] memory _houseIndex, address[] memory _bidder, uint[] memory _value) {
        bool[] memory hasBid = new bool[](totalSupply());
        uint[] memory houseIndex = new uint[](totalSupply());
        address[] memory bidder = new address[](totalSupply());
        uint[] memory value = new uint[](totalSupply());
         
        for(uint i = 0; i < totalSupply(); i++) {
            hasBid[i] = houseBids[i].hasBid;
            houseIndex[i] = houseBids[i].houseIndex;
            bidder[i] = houseBids[i].bidder;
            value[i] = houseBids[i].value;
        }
        
        return (hasBid, houseIndex, bidder, value);
    }
    
     function getHouseInfo() public view returns (uint[] memory _houseIndex, string[] memory _authorInfo, string[] memory _publicInfo) {

        uint[] memory houseIndex = new uint[](totalSupply());
        string[] memory authorInfo = new string[](totalSupply());
        string[] memory publicInfo = new string[](totalSupply());
         
        for(uint i = 0; i < totalSupply(); i++) {
            houseIndex[i] = houseInfo[i].houseIndex;
            authorInfo[i] = houseInfo[i].authorInfo;
            publicInfo[i] = houseInfo[i].publicInfo;
        }
        
        return (houseIndex, authorInfo, publicInfo);
    }
    
    constructor() {
        author = msg.sender;
        houseRemainingToAssign = totalSupply();
        
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual {
         require (author == msg.sender);

        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
    
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    function setBaseURI(string memory baseURI_) public virtual {
         require (author == msg.sender);
        _baseURI = baseURI_;
    }
    
      function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _owners[tokenId];
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _approve(to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit HouseTransferAllowance(tokenId, _owners[tokenId], to);
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender);

        _operatorApprovals[msg.sender][operator] = approved;
        emit HouseTransferAllowanceForAll(msg.sender, operator, approved);
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
   
        return _tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
      
        address owner = _owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }  
  
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _safeTransfer(from, to, tokenId, _data);
    }
      
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transferHouse(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
 
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }
    
    function transfer(address to, uint houseIndex) public {
        _transferHouse(msg.sender, to, houseIndex);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _transferHouse(from, to, tokenId);
    }
    
    function _transferHouse(address from, address to, uint houseIndex) public {
        require (_owners[houseIndex] == from);
        require (houseIndex < totalSupply());
        if (houseOfferedForSale[houseIndex].isForSale) {
            houseNoLongerForSale(houseIndex);
        }
        
        _approve(address(0), houseIndex);
        
        _owners[houseIndex] = to;
        _balances[from]--;
        _balances[to]++;
        emit Transfer(from, to, houseIndex);
        emit HouseTransfer(houseIndex, from, to);

        Bid memory bid = houseBids[houseIndex];
        if (bid.bidder == to) {
  
            pendingWithdrawals[to] += bid.value;
            houseBids[houseIndex] = Bid(false, houseIndex, address(0), 0);
        }
    }

    function houseNoLongerForSale(uint houseIndex) public {
        require (_owners[houseIndex] == msg.sender);
        require (houseIndex < totalSupply());
        houseOfferedForSale[houseIndex] = Offer(false, houseIndex, msg.sender, 0, address(0));
        emit HouseNoLongerForSaleEvent(houseIndex);
    }

    function offerHouseForSale(uint houseIndex, uint minSalePriceInWei) public {
        require (_owners[houseIndex] == msg.sender);
        require (houseIndex < totalSupply());
        houseOfferedForSale[houseIndex] = Offer(true, houseIndex, msg.sender, minSalePriceInWei, address(0));
        emit HouseOffered(houseIndex, minSalePriceInWei, address(0));
    }

    function offerHouseForSaleToAddress(uint houseIndex, uint minSalePriceInWei, address toAddress) public {
        require (_owners[houseIndex] == msg.sender);
        require (houseIndex < totalSupply());
        houseOfferedForSale[houseIndex] = Offer(true, houseIndex, msg.sender, minSalePriceInWei, toAddress);
        emit HouseOffered(houseIndex, minSalePriceInWei, toAddress);
    }

    function buyHouse(uint houseIndex) payable public {
        Offer memory offer = houseOfferedForSale[houseIndex];
        require (houseIndex < totalSupply());
        require (offer.isForSale);              
        require (offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender);  
        require (msg.value >= offer.minValue);    
        require (offer.seller == _owners[houseIndex]); 

        address seller = offer.seller;

        _owners[houseIndex] = msg.sender;
        _balances[seller]--;
        _balances[msg.sender]++;
        emit Transfer(seller, msg.sender, houseIndex);

        houseNoLongerForSale(houseIndex);
        pendingWithdrawals[seller] += msg.value;
        emit HouseBought(houseIndex, msg.value, seller, msg.sender);

        Bid memory bid = houseBids[houseIndex];
        if (bid.bidder == msg.sender) {
            pendingWithdrawals[msg.sender] += bid.value;
            houseBids[houseIndex] = Bid(false, houseIndex, address(0), 0);
        }
    }

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForHouse(uint houseIndex) payable public {
        require (houseIndex < totalSupply());
        require (_owners[houseIndex] != address(0));
        require (_owners[houseIndex] != msg.sender);
        require (msg.value != 0);
        Bid memory existing = houseBids[houseIndex];
        require (msg.value > existing.value);
        if (existing.value > 0) {
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        houseBids[houseIndex] = Bid(true, houseIndex, msg.sender, msg.value);
        emit HouseBidEntered(houseIndex, msg.value, msg.sender);
    }

    function acceptBidForHouse(uint houseIndex, uint minPrice) public {
        require (houseIndex < totalSupply());
        require (_owners[houseIndex] == msg.sender);
        address seller = msg.sender;
        Bid memory bid = houseBids[houseIndex];
        require (bid.value != 0);
        require (bid.value >= minPrice);

        _owners[houseIndex] = bid.bidder;
        _balances[seller]--;
        _balances[bid.bidder]++;
        emit Transfer(seller, bid.bidder, houseIndex);

        houseOfferedForSale[houseIndex] = Offer(false, houseIndex, bid.bidder, 0, address(0));
        uint amount = bid.value;
        houseBids[houseIndex] = Bid(false, houseIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit HouseBought(houseIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForHouse(uint houseIndex) public {
        require (houseIndex < totalSupply());
        require (_owners[houseIndex] != address(0));
        require (_owners[houseIndex] != msg.sender);
        Bid memory bid = houseBids[houseIndex];
        require (bid.bidder == msg.sender);
        emit HouseBidWithdrawn(houseIndex, bid.value, msg.sender);
        uint amount = bid.value;
        houseBids[houseIndex] = Bid(false, houseIndex, address(0), 0);
        msg.sender.transfer(amount);
    }
    
    function addHouseInformation(uint houseIndex, string memory authorInfo, string memory publicInfo) public {
        require (houseIndex < totalSupply());
        require (_owners[houseIndex] == msg.sender || author == msg.sender);
      
        if(msg.sender == author){
            houseInfo[houseIndex] = Info(houseIndex, authorInfo, publicInfo);
        }else{
            houseInfo[houseIndex] = Info(houseIndex, "", publicInfo);
        }
    }
    
    function offerHouseForSaleInBatch(uint[] memory houseIndex, uint[] memory minSalePriceInWei) public {
        require (msg.sender == author);
        uint n = houseIndex.length;
        for (uint i = 0; i < n; i++) {
            offerHouseForSale(houseIndex[i], minSalePriceInWei[i]);
        }
    }
    
    function getHouse(uint houseIndex) public payable {
        require (houseRemainingToAssign != 0);
        require (_owners[houseIndex] == address(0));
        
        if(msg.sender != author)
        {
            require (houseIndex < totalSupply() - 25);
            require(msg.value >= 0.05 ether);
            
            author.transfer(msg.value);
        }
                
        _owners[houseIndex] = msg.sender;
        _balances[msg.sender]++;
        houseRemainingToAssign--;
        emit AssignHouse(houseIndex, msg.sender);
        emit Transfer(address(0), msg.sender, houseIndex);
    }
}