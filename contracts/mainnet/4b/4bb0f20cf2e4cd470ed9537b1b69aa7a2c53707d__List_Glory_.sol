// The list below in the array listTINAmotley is recited in the video
// "List, Glory" by Greg Smith. The elements of listTINAmotley can be 
// claimed, transferred, bought, and sold. Users can also add to the 
// original list.

// Code is based on CryptoPunks, by Larva Labs.

// List elements in listTINAmotley contain text snippets from 
// Margaret Thatcher, Donna Haraway (A Cyborg Manfesto), Francois 
// Rabelias (Gargantua and Pantagruel), Walt Whitman (Germs), and 
// Miguel de Cervantes (Don Quixote).

// This is part of exhibitions at the John Michael Kohler Art Center in
// Sheboygan, WI, and at Susan Inglett Gallery in New York, NY.

// A list element associated with _index can be claimed if 
// gift_CanBeClaimed(_index) returns true. For inquiries
// about receiving lines owned by info_ownerOfContract for free, 
// email <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="afe3c6dcdbfbe6e1eec2c0dbc3cad6efc8c2cec6c381ccc0c281">[email&#160;protected]</a> 

// In general, the functions that begin with "gift_" are used for 
// claiming, transferring, and creating script lines without cost beyond 
// the transaction fee. For example, to claim an available list element 
// associated with _index, execute the gift_ClaimTINAmotleyLine(_index) 
// function.

// The functions that begin with "info_" are used to obtain information 
// about aspects of the program state, including the address that owns 
// a list element, and the "for sale" or "bid" status of a list element. 

// The functions that begin with "market_" are used for buying, selling, and
// placing bids on a list element. For example, to bid on the list element
// associated with _index, send the bid (in wei, not ether) along with
// the function execution of market_DeclareBid(_index).

// Note that if there&#39;s a transaction involving ether (successful sale, 
// accepted bid, etc..), the ether (don&#39;t forget: in units of wei) is not
// automatically credited to an account; it has to be withdrawn by
// calling market_WithdrawWei().

// Source code and code used to test the contract are available at 
// https://github.com/ListTINAmotley/_List_Glory_

// EVERYTHING IS IN UNITS OF WEI, NOT ETHER!


pragma solidity ^0.4.24;

contract _List_Glory_{

    string public info_Name;
    string public info_Symbol;

    address public info_OwnerOfContract;
    // Contains the list
    string[] private listTINAmotley;
    // Contains the total number of elements in the list
    uint256 private listTINAmotleyTotalSupply;
    
    mapping (uint => address) private listTINAmotleyIndexToAddress;
    mapping(address => uint256) private listTINAmotleyBalanceOf;
 
    // Put list element up for sale by owner. Can be linked to specific 
    // potential buyer
    struct forSaleInfo {
        bool isForSale;
        uint256 tokenIndex;
        address seller;
        uint256 minValue;          //in wei.... everything in wei
        address onlySellTo;     // specify to sell only to a specific person
    }

    // Place bid for specific list element
    struct bidInfo {
        bool hasBid;
        uint256 tokenIndex;
        address bidder;
        uint256 value;
    }

    // Public info about tokens for sale.
    mapping (uint256 => forSaleInfo) public info_ForSaleInfoByIndex;
    // Public info about highest bid for each token.
    mapping (uint256 => bidInfo) public info_BidInfoByIndex;
    // Information about withdrawals (in units of wei) available  
    //  ... for addresses due to failed bids, successful sales, etc...
    mapping (address => uint256) public info_PendingWithdrawals;

//Events


    event Claim(uint256 tokenId, address indexed to);
    event Transfer(uint256 tokenId, address indexed from, address indexed to);
    event ForSaleDeclared(uint256 indexed tokenId, address indexed from, 
        uint256 minValue,address indexed to);
    event ForSaleWithdrawn(uint256 indexed tokenId, address indexed from);
    event ForSaleBought(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    event BidDeclared(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidWithdrawn(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidAccepted(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    
    constructor () public {
        info_OwnerOfContract = msg.sender;
	    info_Name = "List, Glory";
	    info_Symbol = "L, G";
        listTINAmotley.push("Now that, that there, that&#39;s for everyone");
        listTINAmotleyIndexToAddress[0] = address(0);
        listTINAmotley.push("Everyone&#39;s invited");
        listTINAmotleyIndexToAddress[1] = address(0);
        listTINAmotley.push("Just bring your lists");
        listTINAmotleyIndexToAddress[2] = address(0);
 	listTINAmotley.push("The for godsakes of surveillance");
        listTINAmotleyIndexToAddress[3] = address(0);
 	listTINAmotley.push("The shitabranna of there is no alternative");
        listTINAmotleyIndexToAddress[4] = address(0);
 	listTINAmotley.push("The clew-bottom of trustless memorials");
        listTINAmotleyIndexToAddress[5] = address(0);
	listTINAmotley.push("The churning ballock of sadness");
        listTINAmotleyIndexToAddress[6] = address(0);
	listTINAmotley.push("The bagpiped bravado of TINA");
        listTINAmotleyIndexToAddress[7] = address(0);
	listTINAmotley.push("There T");
        listTINAmotleyIndexToAddress[8] = address(0);
	listTINAmotley.push("Is I");
        listTINAmotleyIndexToAddress[9] = address(0);
	listTINAmotley.push("No N");
        listTINAmotleyIndexToAddress[10] = address(0);
	listTINAmotley.push("Alternative A");
        listTINAmotleyIndexToAddress[11] = address(0);
	listTINAmotley.push("TINA TINA TINA");
        listTINAmotleyIndexToAddress[12] = address(0);
	listTINAmotley.push("Motley");
        listTINAmotleyIndexToAddress[13] = info_OwnerOfContract;
	listTINAmotley.push("There is no alternative");
        listTINAmotleyIndexToAddress[14] = info_OwnerOfContract;
	listTINAmotley.push("Machines made of sunshine");
        listTINAmotleyIndexToAddress[15] = info_OwnerOfContract;
	listTINAmotley.push("Infidel heteroglossia");
        listTINAmotleyIndexToAddress[16] = info_OwnerOfContract;
	listTINAmotley.push("TINA and the cyborg, Margaret and motley");
        listTINAmotleyIndexToAddress[17] = info_OwnerOfContract;
	listTINAmotley.push("Motley fecundity, be fruitful and multiply");
        listTINAmotleyIndexToAddress[18] = info_OwnerOfContract;
	listTINAmotley.push("Perverts! Mothers! Leninists!");
        listTINAmotleyIndexToAddress[19] = info_OwnerOfContract;
	listTINAmotley.push("Space!");
        listTINAmotleyIndexToAddress[20] = info_OwnerOfContract;
	listTINAmotley.push("Over the exosphere");
        listTINAmotleyIndexToAddress[21] = info_OwnerOfContract;
	listTINAmotley.push("On top of the stratosphere");
        listTINAmotleyIndexToAddress[22] = info_OwnerOfContract;
	listTINAmotley.push("On top of the troposphere");
        listTINAmotleyIndexToAddress[23] = info_OwnerOfContract;
	listTINAmotley.push("Over the chandelier");
        listTINAmotleyIndexToAddress[24] = info_OwnerOfContract;
	listTINAmotley.push("On top of the lithosphere");
        listTINAmotleyIndexToAddress[25] = info_OwnerOfContract;
	listTINAmotley.push("Over the crust");
        listTINAmotleyIndexToAddress[26] = info_OwnerOfContract;
	listTINAmotley.push("You&#39;re the top");
        listTINAmotleyIndexToAddress[27] = info_OwnerOfContract;
	listTINAmotley.push("You&#39;re the top");
        listTINAmotleyIndexToAddress[28] = info_OwnerOfContract;
	listTINAmotley.push("Be fruitful!");
        listTINAmotleyIndexToAddress[29] = info_OwnerOfContract;
	listTINAmotley.push("Fill the atmosphere, the heavens, the ether");
        listTINAmotleyIndexToAddress[30] = info_OwnerOfContract;
	listTINAmotley.push("Glory! Glory. TINA TINA Glory.");
        listTINAmotleyIndexToAddress[31] = info_OwnerOfContract;
	listTINAmotley.push("Over the stratosphere");
        listTINAmotleyIndexToAddress[32] = info_OwnerOfContract;
	listTINAmotley.push("Over the mesosphere");
        listTINAmotleyIndexToAddress[33] = info_OwnerOfContract;
	listTINAmotley.push("Over the troposphere");
        listTINAmotleyIndexToAddress[34] = info_OwnerOfContract;
	listTINAmotley.push("On top of bags of space");
        listTINAmotleyIndexToAddress[35] = info_OwnerOfContract;
	listTINAmotley.push("Over backbones and bags of ether");
        listTINAmotleyIndexToAddress[36] = info_OwnerOfContract;
	listTINAmotley.push("Now TINA, TINA has a backbone");
        listTINAmotleyIndexToAddress[37] = info_OwnerOfContract;
	listTINAmotley.push("And motley confetti lists");
        listTINAmotleyIndexToAddress[38] = info_OwnerOfContract;
	listTINAmotley.push("Confetti arms, confetti feet, confetti mouths, confetti faces");
        listTINAmotleyIndexToAddress[39] = info_OwnerOfContract;
	listTINAmotley.push("Confetti assholes");
        listTINAmotleyIndexToAddress[40] = info_OwnerOfContract;
	listTINAmotley.push("Confetti cunts and confetti cocks");
        listTINAmotleyIndexToAddress[41] = info_OwnerOfContract;
	listTINAmotley.push("Confetti offspring, splendid suns");
        listTINAmotleyIndexToAddress[42] = info_OwnerOfContract;
	listTINAmotley.push("The moon and rings, the countless combinations and effects");
        listTINAmotleyIndexToAddress[43] = info_OwnerOfContract;
	listTINAmotley.push("Such-like, and good as such-like");
        listTINAmotleyIndexToAddress[44] = info_OwnerOfContract;
	listTINAmotley.push("(Mumbled)");
        listTINAmotleyIndexToAddress[45] = info_OwnerOfContract;
	listTINAmotley.push("Everything&#39;s for sale");
        listTINAmotleyIndexToAddress[46] = info_OwnerOfContract;
	listTINAmotley.push("Just bring your lists");
        listTINAmotleyIndexToAddress[47] = info_OwnerOfContract;
	listTINAmotley.push("Micro resurrections");
        listTINAmotleyIndexToAddress[48] = info_OwnerOfContract;
	listTINAmotley.push("Paddle steamers");
        listTINAmotleyIndexToAddress[49] = info_OwnerOfContract;
	listTINAmotley.push("Windmills");
        listTINAmotleyIndexToAddress[50] = info_OwnerOfContract;
	listTINAmotley.push("Anti-anti-utopias");
        listTINAmotleyIndexToAddress[51] = info_OwnerOfContract;
	listTINAmotley.push("Rocinante lists");
        listTINAmotleyIndexToAddress[52] = info_OwnerOfContract;
	listTINAmotley.push("In memoriam lists");
        listTINAmotleyIndexToAddress[53] = info_OwnerOfContract;
	listTINAmotley.push("TINA TINA TINA");
        listTINAmotleyIndexToAddress[54] = info_OwnerOfContract;
       

        listTINAmotleyBalanceOf[info_OwnerOfContract] = 42;
        listTINAmotleyBalanceOf[address(0)] = 13;
        listTINAmotleyTotalSupply = 55;
     }
     
    function info_TotalSupply() public view returns (uint256 total){
        total = listTINAmotleyTotalSupply;
        return total;
    }

    //Number of list elements owned by an account.
    function info_BalanceOf(address _owner) public view 
            returns (uint256 balance){
        balance = listTINAmotleyBalanceOf[_owner];
        return balance;
    }
    
    //Shows text of a list element.
    function info_SeeTINAmotleyLine(uint256 _tokenId) external view 
            returns(string){
        require(_tokenId < listTINAmotleyTotalSupply);
        return listTINAmotley[_tokenId];
    }
    
    function info_OwnerTINAmotleyLine(uint256 _tokenId) external view 
            returns (address owner){
        require(_tokenId < listTINAmotleyTotalSupply);
        owner = listTINAmotleyIndexToAddress[_tokenId];
        return owner;
    }

    // Is the line available to be claimed?
    function info_CanBeClaimed(uint256 _tokenId) external view returns(bool){
 	require(_tokenId < listTINAmotleyTotalSupply);
	if (listTINAmotleyIndexToAddress[_tokenId] == address(0))
	  return true;
	else
	  return false;
	  }
	
    // Claim line owned by address(0).
    function gift_ClaimTINAmotleyLine(uint256 _tokenId) external returns(bool){
        require(_tokenId < listTINAmotleyTotalSupply);
        require(listTINAmotleyIndexToAddress[_tokenId] == address(0));
        listTINAmotleyIndexToAddress[_tokenId] = msg.sender;
        listTINAmotleyBalanceOf[msg.sender]++;
        listTINAmotleyBalanceOf[address(0)]--;
        emit Claim(_tokenId, msg.sender);
        return true;
    }

   // Create new list element. 
    function gift_CreateTINAmotleyLine(string _text) external returns(bool){ 
        require (msg.sender != address(0));
        uint256  oldTotalSupply = listTINAmotleyTotalSupply;
        listTINAmotleyTotalSupply++;
        require (listTINAmotleyTotalSupply > oldTotalSupply);
        listTINAmotley.push(_text);
        uint256 _tokenId = listTINAmotleyTotalSupply - 1;
        listTINAmotleyIndexToAddress[_tokenId] = msg.sender;
        listTINAmotleyBalanceOf[msg.sender]++;
        return true;
    }

    // Transfer by owner to address. Transferring to address(0) will
    // make line available to be claimed.
    function gift_Transfer(address _to, uint256 _tokenId) public returns(bool) {
        address initialOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (initialOwner == msg.sender);
        require (_tokenId < listTINAmotleyTotalSupply);
        // Remove for sale.
        market_WithdrawForSale(_tokenId);
        rawTransfer (initialOwner, _to, _tokenId);
        // Remove new owner&#39;s bid, if it exists.
        clearNewOwnerBid(_to, _tokenId);
        return true;
    }

    // Let anyone interested know that the owner put a token up for sale. 
    // Anyone can obtain it by sending an amount of wei equal to or
    // larger than  _minPriceInWei. 
    function market_DeclareForSale(uint256 _tokenId, uint256 _minPriceInWei) 
            external returns (bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address tokenOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (msg.sender == tokenOwner);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(true, _tokenId, 
            msg.sender, _minPriceInWei, address(0));
        emit ForSaleDeclared(_tokenId, msg.sender, _minPriceInWei, address(0));
        return true;
    }
    
    // Let anyone interested know that the owner put a token up for sale. 
    // Only the address _to can obtain it by sending an amount of wei equal 
    // to or larger than _minPriceInWei.
    function market_DeclareForSaleToAddress(uint256 _tokenId, uint256 
            _minPriceInWei, address _to) external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address tokenOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (msg.sender == tokenOwner);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(true, _tokenId, 
            msg.sender, _minPriceInWei, _to);
        emit ForSaleDeclared(_tokenId, msg.sender, _minPriceInWei, _to);
        return true;
    }

    // Owner no longer wants token for sale, or token has changed owner, 
    // so previously posted for sale is no longer valid.
    function market_WithdrawForSale(uint256 _tokenId) public returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (msg.sender == listTINAmotleyIndexToAddress[_tokenId]);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(false, _tokenId, 
            address(0), 0, address(0));
        emit ForSaleWithdrawn(_tokenId, msg.sender);
        return true;
    }
    
    // I&#39;ll take it. Must send at least as many wei as minValue in 
    // forSale structure.
    function market_BuyForSale(uint256 _tokenId) payable external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        forSaleInfo storage existingForSale = info_ForSaleInfoByIndex[_tokenId];
        require(existingForSale.isForSale);
        require(existingForSale.onlySellTo == address(0) || 
            existingForSale.onlySellTo == msg.sender);
        require(msg.value >= existingForSale.minValue); 
        require(existingForSale.seller == 
            listTINAmotleyIndexToAddress[_tokenId]); 
        address seller = listTINAmotleyIndexToAddress[_tokenId];
        rawTransfer(seller, msg.sender, _tokenId);
        // must withdrawal for sale after transfer to make sure msg.sender
        //  is the current owner.
        market_WithdrawForSale(_tokenId);
        // clear bid of new owner, if it exists
        clearNewOwnerBid(msg.sender, _tokenId);
        info_PendingWithdrawals[seller] += msg.value;
        emit ForSaleBought(_tokenId, msg.value, seller, msg.sender);
        return true;
    }
    
    // Let anyone interested know that potential buyer put up money for a token.
    function market_DeclareBid(uint256 _tokenId) payable external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (listTINAmotleyIndexToAddress[_tokenId] != address(0));
        require (listTINAmotleyIndexToAddress[_tokenId] != msg.sender);
        require (msg.value > 0);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        // Keep only the highest bid.
        require (msg.value > existingBid.value);
        if (existingBid.value > 0){
            info_PendingWithdrawals[existingBid.bidder] += existingBid.value;
        }
        info_BidInfoByIndex[_tokenId] = bidInfo(true, _tokenId, 
            msg.sender, msg.value);
        emit BidDeclared(_tokenId, msg.value, msg.sender);
        return true;
    }
    
    // Potential buyer changes mind and withdrawals bid.
    function market_WithdrawBid(uint256 _tokenId) external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (listTINAmotleyIndexToAddress[_tokenId] != address(0));
        require (listTINAmotleyIndexToAddress[_tokenId] != msg.sender);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        require (existingBid.hasBid);
        require (existingBid.bidder == msg.sender);
        uint256 amount = existingBid.value;
        // Refund
        info_PendingWithdrawals[existingBid.bidder] += amount;
        info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, address(0), 0);
        emit BidWithdrawn(_tokenId, amount, msg.sender);
        return true;
    }
    
    // Accept bid, and transfer money and token. All money in wei.
    function market_AcceptBid(uint256 _tokenId, uint256 minPrice) 
            external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address seller = listTINAmotleyIndexToAddress[_tokenId];
        require (seller == msg.sender);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        require (existingBid.hasBid);
        //Bid must be larger than minPrice
        require (existingBid.value > minPrice);
        address buyer = existingBid.bidder;
        // Remove for sale.
        market_WithdrawForSale(_tokenId);
        rawTransfer (seller, buyer, _tokenId);
        uint256 amount = existingBid.value;
        // Remove bid.
        info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, address(0),0);
        info_PendingWithdrawals[seller] += amount;
        emit BidAccepted(_tokenId, amount, seller, buyer);
        return true;
    }
    
    // Retrieve money to successful sale, failed bid, withdrawn bid, etc.
    //  All in wei. Note that refunds, income, etc. are NOT automatically
    // deposited in the user&#39;s address. The user must withdraw the funds.
    function market_WithdrawWei() external returns(bool) {
       uint256 amount = info_PendingWithdrawals[msg.sender];
       require (amount > 0);
       info_PendingWithdrawals[msg.sender] = 0;
       msg.sender.transfer(amount);
       return true;
    } 
    
    function clearNewOwnerBid(address _to, uint256 _tokenId) internal {
        // clear bid when become owner via transfer or forSaleBuy
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        if (existingBid.bidder == _to){
            uint256 amount = existingBid.value;
            info_PendingWithdrawals[_to] += amount;
            info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, 
                address(0), 0);
            emit BidWithdrawn(_tokenId, amount, _to);
        }
      
    }
    
    function rawTransfer(address _from, address _to, uint256 _tokenId) 
            internal {
        listTINAmotleyBalanceOf[_from]--;
        listTINAmotleyBalanceOf[_to]++;
        listTINAmotleyIndexToAddress[_tokenId] = _to;
        emit Transfer(_tokenId, _from, _to);
    }
    
    
}