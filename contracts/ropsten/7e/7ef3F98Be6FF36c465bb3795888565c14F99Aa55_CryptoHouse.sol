/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.7.6;
pragma abicoder v2;

contract CryptoHouse {

    address owner;

	string constant public name = "CryptoHouse";
	string constant public symbol = unicode"He🏠llo ⚗️🏠😃";
	uint8 constant public decimals = 0;
	uint256 constant public totalSupply = 1000;

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
        string ownerInfo;
        string publicInfo;
    }
    
    mapping (address => uint256) public balanceOf;
    
    mapping (uint => address) public punkIndexToAddress;
    
    function getPunkIndexToAddress() public view returns (address[] memory _holder) {
        address[] memory holders = new address[](totalSupply);
         
        for(uint i = 0; i < totalSupply; i++) {
            holders[i] = punkIndexToAddress[i];
        }
        
        return (holders);
    }

    mapping (uint => Offer) public punksOfferedForSale;
    
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

    mapping (uint => Bid) public punkBids;
    
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
    
    mapping (uint => Info) public punkInfo;
    
      function getPunkInfo() public view returns (uint[] memory _punkIndex, string[] memory _ownerInfo, string[] memory _publicInfo) {

        uint[] memory punkIndex = new uint[](totalSupply);
        string[] memory ownerInfo = new string[](totalSupply);
        string[] memory publicInfo = new string[](totalSupply);
         
        for(uint i = 0; i < totalSupply; i++) {
            punkIndex[i] = punkInfo[i].punkIndex;
            ownerInfo[i] = punkInfo[i].ownerInfo;
            publicInfo[i] = punkInfo[i].publicInfo;
        }
        
        return (punkIndex, ownerInfo, publicInfo);
    }
    

    mapping (address => uint) public pendingWithdrawals;

    event Transfer(address indexed fromAddress, address indexed toAddress, uint256 value);
    
    event AssignPunk(uint256 indexed punkIndex, address indexed toAddress);
    event PunkTransfer(uint256 indexed punkIndex, address indexed fromAddress, address indexed toAddress);
    event PunkOffered(uint indexed punkIndex, uint minValue, address indexed toAddress);
    event PunkBidEntered(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBidWithdrawn(uint indexed punkIndex, uint value, address indexed fromAddress);
    event PunkBought(uint indexed punkIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event PunkNoLongerForSale(uint indexed punkIndex);

   constructor() public {
        //balanceOf[msg.sender] = initialSupply;
        owner = msg.sender;
        punksRemainingToAssign = totalSupply;
    }

    function setInitialOwner(address to, uint punkIndex) public {
        require (msg.sender == owner);
        require (!allPunksAssigned);
        require (punkIndex < totalSupply);
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != address(0)) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
           emit AssignPunk(punkIndex, to);
        }
    }

    function setInitialOwners(address[] memory addresses, uint[] memory indices) public {
        require (msg.sender == owner);
        uint n = addresses.length;
        for (uint i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() public {
        require (msg.sender == owner);
        allPunksAssigned = true;
    }

    function getPunk(uint punkIndex) public {
        require (allPunksAssigned);
        require (punksRemainingToAssign != 0);
        require (punkIndexToAddress[punkIndex] == address(0));
        require (punkIndex < totalSupply);
        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;
        emit AssignPunk(punkIndex, msg.sender);
    }

    // emit Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) public {
        require (allPunksAssigned);
        require (punkIndexToAddress[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(punkIndex, msg.sender, to);
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function punkNoLongerForSale(uint punkIndex) public {
        require (allPunksAssigned);
        require (punkIndexToAddress[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint punkIndex, uint minSalePriceInWei) public {
        require (allPunksAssigned);
        require (punkIndexToAddress[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0));
        emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
    }

    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) public {
        require (allPunksAssigned);
        require (punkIndexToAddress[punkIndex] == msg.sender);
        require (punkIndex < totalSupply);
        punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);
        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint punkIndex) payable public {
        require (allPunksAssigned);
        Offer memory offer = punksOfferedForSale[punkIndex];
        require (punkIndex < totalSupply);
        require (offer.isForSale);                // punk not actually for sale
        require (offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender);  // punk not supposed to be sold to this user
        require (msg.value >= offer.minValue);      // Didn't send enough ETH
        require (offer.seller == punkIndexToAddress[punkIndex]); // Seller no longer owner of punk

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;
        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;
        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function withdraw() public {
        require (allPunksAssigned);
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function enterBidForPunk(uint punkIndex) payable public {
        require (punkIndex < totalSupply);
        require (allPunksAssigned);                
        require (punkIndexToAddress[punkIndex] != address(0));
        require (punkIndexToAddress[punkIndex] != msg.sender);
        require (msg.value != 0);
        Bid memory existing = punkBids[punkIndex];
        require (msg.value > existing.value);
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);
        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint punkIndex, uint minPrice) public {
        require (punkIndex < totalSupply);
        require (allPunksAssigned);                
        require (punkIndexToAddress[punkIndex] == msg.sender);
        address seller = msg.sender;
        Bid memory bid = punkBids[punkIndex];
        require (bid.value != 0);
        require (bid.value >= minPrice);

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;
        emit Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, address(0));
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;
        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint punkIndex) public {
        require (punkIndex < totalSupply);
        require (allPunksAssigned);               
        require (punkIndexToAddress[punkIndex] != address(0));
        require (punkIndexToAddress[punkIndex] != msg.sender);
        Bid memory bid = punkBids[punkIndex];
        require (bid.bidder == msg.sender);
        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);
        uint amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        // Refund the bid money
        msg.sender.transfer(amount);
    }
    
    function addPunkInformation(uint punkIndex, string memory ownerInfo, string memory publicInfo) public {
        require (punkIndex < totalSupply);
        require (allPunksAssigned);               
        require (punkIndexToAddress[punkIndex] == msg.sender || owner == msg.sender);
      
        if(msg.sender == owner){
            punkInfo[punkIndex] = Info(punkIndex, ownerInfo, publicInfo);
        }else{
            punkInfo[punkIndex] = Info(punkIndex, "", publicInfo);
        }
    }

}