/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity 0.7.6;
pragma abicoder v2;

interface IERC721 {
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

contract CryptoHouse is IERC721, IERC721Metadata  {

    address author;

	string constant override public name = "CryptoHouse";
	string constant override public symbol = "HOUSE";
	
	uint8 constant public decimals = 0;
	uint256 constant public totalSupply = 700;
	
	uint public nextPunkIndexToAssign = 0;
    uint public punksRemainingToAssign = 0;

    bool public allPunksAssigned = false;
    
    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;      
        address onlySellTo;     
    }

    struct Bid {
        bool hasBid;
        uint punkIndex;
        address bidder;
        uint value;
    }
    
    struct Info {
        uint punkIndex;
        string authorInfo;
        string publicInfo;
    }
    
    mapping (address => uint256) public _balances;
    mapping (uint => address) public _owners;

    mapping (uint => Offer) public punksOfferedForSale;
    mapping (uint => Bid) public punkBids;
    mapping (uint => Info) public punkInfo;

    mapping (address => uint) public pendingWithdrawals;
    mapping (uint256 => address) public _tokenApprovals;
    mapping (address => mapping (address => bool)) public _operatorApprovals;
    
    event PunkTransferAllowance(uint256 indexed punkIndex, address indexed fromAddress, address indexed toAddress);
    event PunkTransferAllowanceForAll(address indexed fromAddress, address indexed toAddress, bool indexed approved);
    event AssignPunk(uint256 indexed punkIndex, address indexed toAddress);
    event PunkTransfer(uint256 indexed punkIndex, address indexed fromAddress, address indexed toAddress);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

    function getAllOwnerOf() public view returns (address[] memory _holder) {
        address[] memory holders = new address[](totalSupply);
         
        for(uint i = 0; i < totalSupply; i++) {
            holders[i] = _owners[i];
        }
        
        return (holders);
    }
    
    function getPunkOfferedForSale() public view returns (bool[] memory _isForSale, uint[] memory _punkIndex, address[] memory _seller, uint[] memory _minValue, address[] memory _onlySellTo) {
        bool[] memory isForSale = new bool[](totalSupply);
        uint[] memory punkIndex = new uint[](totalSupply);
        address[] memory seller = new address[](totalSupply);
        uint[] memory minValue = new uint[](totalSupply);
        address[] memory onlySellTo = new address[](totalSupply);
        
        for(uint i = 0; i < totalSupply; i++) {
            isForSale[i] = punksOfferedForSale[i].isForSale;
            punkIndex[i] = punksOfferedForSale[i].punkIndex;
            seller[i] = punksOfferedForSale[i].seller;
            minValue[i] = punksOfferedForSale[i].minValue;
            onlySellTo[i] = punksOfferedForSale[i].onlySellTo;
        }
        
        return (isForSale, punkIndex, seller, minValue, onlySellTo);
    }

    function getPunkBids() public view returns (bool[] memory _hasBid, uint[] memory _punkIndex, address[] memory _bidder, uint[] memory _value) {
        bool[] memory hasBid = new bool[](totalSupply);
        uint[] memory punkIndex = new uint[](totalSupply);
        address[] memory bidder = new address[](totalSupply);
        uint[] memory value = new uint[](totalSupply);
         
        for(uint i = 0; i < totalSupply; i++) {
            hasBid[i] = punkBids[i].hasBid;
            punkIndex[i] = punkBids[i].punkIndex;
            bidder[i] = punkBids[i].bidder;
            value[i] = punkBids[i].value;
        }
        
        return (hasBid, punkIndex, bidder, value);
    }
    
     function getPunkInfo() public view returns (uint[] memory _punkIndex, string[] memory _authorInfo, string[] memory _publicInfo) {

        uint[] memory punkIndex = new uint[](totalSupply);
        string[] memory authorInfo = new string[](totalSupply);
        string[] memory publicInfo = new string[](totalSupply);
         
        for(uint i = 0; i < totalSupply; i++) {
            punkIndex[i] = punkInfo[i].punkIndex;
            authorInfo[i] = punkInfo[i].authorInfo;
            publicInfo[i] = punkInfo[i].publicInfo;
        }
        
        return (punkIndex, authorInfo, publicInfo);
    }
    
    constructor() {
        author = msg.sender;
        punksRemainingToAssign = totalSupply;
    }

    function setInitialOwner(address to, uint punkIndex) public {
        require (msg.sender == author);
        require (!allPunksAssigned);
        require (punkIndex < totalSupply);
        if (_owners[punkIndex] != to) {
            if (_owners[punkIndex] != address(0)) {
                _balances[_owners[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            _owners[punkIndex] = to;
            _balances[to]++;
           emit AssignPunk(punkIndex, to);
        }
    }

    function setInitialOwners(address[] memory addresses, uint[] memory indices) public {
        require (msg.sender == author);
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }
    
    function setAllToAuthor() public {
        require (msg.sender == author);
        for (uint i = 0; i < totalSupply; i++) {
            setInitialOwner(author, i);
        }
    }

    function allInitialOwnersAssigned() public {
        require (msg.sender == author);
        allPunksAssigned = true;
    }

    function getPunk(uint punkIndex) public {
        require (allPunksAssigned);
        require (punksRemainingToAssign != 0);
        require (_owners[punkIndex] == address(0));
        require (punkIndex < totalSupply);
        _owners[punkIndex] = msg.sender;
        _balances[msg.sender]++;
        punksRemainingToAssign--;
        emit AssignPunk(punkIndex, msg.sender);
        emit Transfer(address(0), msg.sender, punkIndex);
    }
    
    function approve(address to, uint256 tokenId) public virtual override {
        require (allPunksAssigned);
        address owner = _owners[tokenId];
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
        _approve(to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit PunkTransferAllowance(tokenId, _owners[tokenId], to);
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require (allPunksAssigned);
        require(operator != msg.sender);

        _operatorApprovals[msg.sender][operator] = approved;
        emit PunkTransferAllowanceForAll(msg.sender, operator, approved);
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId));
        address owner = _owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
     function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        return owner;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require (allPunksAssigned);
        _transferPunk(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require (allPunksAssigned);
        require(_isApprovedOrOwner(msg.sender, tokenId));
         _transferPunk(from, to, tokenId);
    }
    
    function transfer(address to, uint punkIndex) public {
        require (allPunksAssigned);
        _transferPunk(msg.sender, to, punkIndex);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require (allPunksAssigned);
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _transferPunk(from, to, tokenId);
    }
    
    function _transferPunk(address from, address to, uint punkIndex) public {
        require (allPunksAssigned);
        require (_owners[punkIndex] == from);
        require (punkIndex < totalSupply);
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        
        _approve(address(0), punkIndex);
        
        _owners[punkIndex] = to;
        _balances[from]--;
        _balances[to]++;
        emit Transfer(from, to, punkIndex);
        emit PunkTransfer(punkIndex, from, to);

        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == to) {
  
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function punkNoLongerForSale(uint punkIndex) public {
        require (allPunksAssigned);
        require (_owners[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public {
        require (allPunksAssigned);
        require (_owners[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
    }

    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public {
        require (allPunksAssigned);
        require (_owners[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint punkIndex) payable public {
        require (allPunksAssigned);
        Offer memory offer = punksOfferedForSale[punkIndex];
        require (punkIndex < totalSupply);
        require (offer.isForSale);              
        require (offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender);  
        require (msg.value >= offer.minValue);    
        require (offer.seller == _owners[punkIndex]); 

        address seller = offer.seller;

        _owners[punkIndex] = msg.sender;
        _balances[seller]--;
        _balances[msg.sender]++;
        emit Transfer(seller, msg.sender, punkIndex);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function withdraw() public {
        require (allPunksAssigned);
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint punkIndex) payable public {
        require (allPunksAssigned);
        require (punkIndex < totalSupply);
        require (_owners[punkIndex] != address(0));
        require (_owners[punkIndex] != msg.sender);
        require (msg.value != 0);
        Bid memory existing = punkBids[punkIndex];
        require (msg.value > existing.value);
        if (existing.value > 0) {
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint punkIndex, uint minPrice) public {
        require (allPunksAssigned);
        require (punkIndex < totalSupply);
        require (_owners[punkIndex] == msg.sender);
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        require (bid.value != 0);
        require (bid.value >= minPrice);

        _owners[punkIndex] = bid.bidder;
        _balances[seller]--;
        _balances[bid.bidder]++;
        emit Transfer(seller, bid.bidder, punkIndex);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, address(0));
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint punkIndex) public {
        require (allPunksAssigned);
        require (punkIndex < totalSupply);
        require (_owners[punkIndex] != address(0));
        require (_owners[punkIndex] != msg.sender);
        Bid memory bid = punkBids[punkIndex];
        require (bid.bidder == msg.sender);
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        msg.sender.transfer(amount);
    }
    
    function addPunkInformation(uint punkIndex, string memory authorInfo, string memory publicInfo) public {
        require (allPunksAssigned);
        require (punkIndex < totalSupply);
        require (_owners[punkIndex] == msg.sender || author == msg.sender);
      
        if(msg.sender == author){
            punkInfo[punkIndex] = Info(punkIndex, authorInfo, publicInfo);
        }else{
            punkInfo[punkIndex] = Info(punkIndex, "", publicInfo);
        }
    }
    
    function tokenURI(uint256 punkIndex) override public view returns (string memory) {
        return punkInfo[punkIndex].authorInfo;
    }
}