pragma solidity ^0.4.18;

//
// LimeEyes
// Decentralized art on the Ethereum blockchain!
// (https://limeeyes.com/)
/*
             ___                  ___        
         .-&#39;&#39;   &#39;&#39;-.          .-&#39;&#39;   &#39;&#39;-.    
       .&#39;           &#39;.      .&#39;           &#39;.  
      /   . -  ;  - . \    /   . -  ;  - . \ 
     (  &#39; `-._|_,&#39;_,.- )  (  &#39; `-._|_,&#39;_,.- )
      &#39;,,.--_,4"-;_  ,&#39;    &#39;,,.--_,4"-;_  ,&#39; 
        &#39;-.;   \ _.-&#39;        &#39;-.;   \ _.-&#39;   
            &#39;&#39;&#39;&#39;&#39;                &#39;&#39;&#39;&#39;&#39;       
*/
// Welcome to LimeEyes!
//
// This smart contract allows users to purchase shares of any artwork that&#39;s
// been added to the system and it will pay dividends to all shareholders
// upon the purchasing of new shares! It&#39;s special in the way it works because
// the shares can only be bought in certain amounts and the price of those 
// shares is dependant on how many other shares there are already. Each
// artwork starts with 1 share available for purchase and upon each sale,
// the number of shares for purchase will increase by one (1 -> 2 -> 3...),
// each artwork also has an owner and they will always get the dividends from 
// the number of shares up for purchase, for example;
/*
    If the artwork has had shares purchased 4 times, the next purchase will
    be for 5 shares of the artwork. Upon the purchasing of these shares, the
    owner will receive the dividends equivelent to 5 shares worth of the sale
    value. It&#39;s also important to note that the artwork owner cannot purchase
    shares of their own art, instead they just inherit the shares for purchase
    and pass it onto the next buyer at each sale.
*/ 
// The price of the shares also follows a special formula in order to maintain
// stability over time, it uses the base price of an artwork (set by the dev 
// upon the creation of the artwork) and the total number of shares purchased
// of the artwork. From here you simply treat the number of shares as a percentage
// and add that much on top of your base price, for example;
/*
    If the artwork has a base price of 0.01 ETH and there have been 250 shares 
    purchased so far, it would mean that the base price will gain 250% of it&#39;s
    value which comes to 0.035 ETH (100% + 250% of the base price).
*/
// The special thing about this is because the shares are intrinsicly linked with
// the price, the dividends from your shares will trend to a constant value instead
// of continually decreasing over time. Because our sequence of shares is a triangular
// number (1 + 2 + 3...) the steady state of any purchased shares will equal the number
// of shares owned (as a percentage) * the artworks base price, for example;
/*
    If the artwork has a base price of 0.01 ETH and you own 5 shares, in the long run
    you should expect to see 5% * 0.01 ETH = 0.0005 ETH each time the artwork has any
    shares purchased. In contrast, if you own 250 shares of the artwork, you should 
    expect to see 250% * 0.01 ETH = 0.025 ETH each time the artwork has shares bought.
  
    It&#39;s good to point out that if you were the first buyer and owned 1 share, the next
    buyer is going to be purchasing 2 shares which means you have 1 out of the 3 shares
    total and hence you will receive 33% of that sale, at the next step there will be
    6 shares total and your 1 share is now worth 16% of the sale price, as mentioned
    above though, your earnings upon the purchasing of new shares from your original
    1 share will trend towards 1% of the base price over a long period of time.
*/
//
// If you&#39;re an artist and are interested in listing some of your works on the site
// and in this contract, please visit the website (https://limeeyes.com/) and contact
// the main developer via the links on the site!
//

contract LimeEyes {

	//////////////////////////////////////////////////////////////////////
	//  Variables, Storage and Events


	address private _dev;

	struct Artwork {
		string _title;
		address _owner;
		bool _visible;
		uint256 _basePrice;
		uint256 _purchases;
		address[] _shareholders;
		mapping (address => bool) _hasShares;
		mapping (address => uint256) _shares;
	}
	Artwork[] private _artworks;

	event ArtworkCreated(
		uint256 artworkId,
		string title,
		address owner,
		uint256 basePrice);
	event ArtworkSharesPurchased(
		uint256 artworkId,
		string title,
		address buyer,
		uint256 sharesBought);


	//////////////////////////////////////////////////////////////////////
	//  Constructor and Admin Functions


	function LimeEyes() public {
		_dev = msg.sender;
	}

	modifier onlyDev() {
		require(msg.sender == _dev);
		_;
	}

	// This function will create a new artwork within the contract,
	// the title is changeable later by the dev but the owner and
	// basePrice cannot be changed once it&#39;s been created.
	// The owner of the artwork will start off with 1 share and any
	// other addresses may now purchase shares for it.
	function createArtwork(string title, address owner, uint256 basePrice) public onlyDev {

		require(basePrice != 0);
		_artworks.push(Artwork({
			_title: title,
			_owner: owner,
			_visible: true,
			_basePrice: basePrice,
			_purchases: 0,
			_shareholders: new address[](0)
		}));
		uint256 artworkId = _artworks.length - 1;
		Artwork storage newArtwork = _artworks[artworkId];
		newArtwork._hasShares[owner] = true;
		newArtwork._shareholders.push(owner);
		newArtwork._shares[owner] = 1;

		ArtworkCreated(artworkId, title, owner, basePrice);

	}

	// Simple renaming function for the artworks, it is good to
	// keep in mind that when the website syncs with the blockchain,
	// any titles over 32 characters will be clipped.
	function renameArtwork(uint256 artworkId, string newTitle) public onlyDev {
		
		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];
		artwork._title = newTitle;

	}

	// This function is only for the website and whether or not
	// it displays a certain artwork, any user may still buy shares
	// for an invisible artwork although it&#39;s not really art unless
	// you can view it.
	// This is exclusively reserved for copyright cases should any
	// artworks be flagged as such.
	function toggleArtworkVisibility(uint256 artworkId) public onlyDev {
		
		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];
		artwork._visible = !artwork._visible;

	}

	// The two withdrawal functions below are here so that the dev
	// can access the dividends of the contract if it owns any
	// artworks. As all ETH is transferred straight away upon the
	// purchasing of shares, the only ETH left in the contract will
	// be from dividends or the rounding errors (although the error
	// will only be a few wei each transaction) due to the nature
	// of dividing and working with integers.
	function withdrawAmount(uint256 amount, address toAddress) public onlyDev {

		require(amount != 0);
		require(amount <= this.balance);
		toAddress.transfer(amount);

	}

	// Used to empty the contracts balance to an address.
	function withdrawAll(address toAddress) public onlyDev {
		toAddress.transfer(this.balance);
	}


	//////////////////////////////////////////////////////////////////////
	//  Main Artwork Share Purchasing Function


	// This is the main point of interaction in this contract,
	// it will allow a user to purchase shares in an artwork
	// and hence with their investment, they pay dividends to
	// all the current shareholders and then the user themselves
	// will become a shareholder and earn dividends on any future
	// purchases of shares.
	// See the getArtwork() function for more information on pricing
	// and how shares work.
	function purchaseSharesOfArtwork(uint256 artworkId) public payable {

		// This makes sure only people, and not contracts, can buy shares.
		require(msg.sender == tx.origin);

		require(_exists(artworkId));
		Artwork storage artwork = _artworks[artworkId];

		// The artwork owner is not allowed to purchase shares of their
		// own art, instead they will earn dividends automatically.
		require(msg.sender != artwork._owner);

		uint256 totalShares;
		uint256[3] memory prices;
		( , , , prices, totalShares, , ) = getArtwork(artworkId);
		uint256 currentPrice = prices[1];

		// Make sure the buyer sent enough ETH
		require(msg.value >= currentPrice);

		// Send back the excess if there&#39;s any.
		uint256 purchaseExcess = msg.value - currentPrice;
		if (purchaseExcess > 0)
			msg.sender.transfer(purchaseExcess);

		// Now pay all the shareholders accordingly.
		// (this will potentially cost a lot of gas)
		for (uint256 i = 0; i < artwork._shareholders.length; i++) {
			address shareholder = artwork._shareholders[i];
			if (shareholder != address(this)) { // transfer ETH if the shareholder isn&#39;t this contract
				shareholder.transfer((currentPrice * artwork._shares[shareholder]) / totalShares);
			}
		}

		// Add the buyer to the registry.
		if (!artwork._hasShares[msg.sender]) {
			artwork._hasShares[msg.sender] = true;
			artwork._shareholders.push(msg.sender);
		}

		artwork._purchases++; // track our purchase
		artwork._shares[msg.sender] += artwork._purchases; // add the shares to the sender
		artwork._shares[artwork._owner] = artwork._purchases + 1; // set the owners next shares

		ArtworkSharesPurchased(artworkId, artwork._title, msg.sender, artwork._purchases);
		
	}


	//////////////////////////////////////////////////////////////////////
	//  Getters


	function _exists(uint256 artworkId) private view returns (bool) {
		return artworkId < _artworks.length;
	}

	function getArtwork(uint256 artworkId) public view returns (string artworkTitle, address ownerAddress, bool isVisible, uint256[3] artworkPrices, uint256 artworkShares, uint256 artworkPurchases, uint256 artworkShareholders) {
		
		require(_exists(artworkId));

		Artwork memory artwork = _artworks[artworkId];

		// As at each step we are simply increasing the number of shares given by 1, the resulting
		// total from adding up consecutive numbers from 1 is the same as the triangular number
		// series (1 + 2 + 3 + ...). the formula for finding the nth triangular number is as follows;
		// Tn = (n * (n + 1)) / 2
		// For example the 10th triangular number is (10 * 11) / 2 = 55
		// In our case however, the owner of the artwork always inherits the shares being bought
		// before transferring them to the buyer but the owner cannot buy shares of their own artwork.
		// This means that when calculating how many shares, we need to add 1 to the total purchases
		// in order to accommodate for the owner. from here we just need to adjust the triangular
		// number formula slightly to get;
		// Shares After n Purchases = ((n + 1) * (n + 2)) / 2
		// Let&#39;s say the art is being purchased for a second time which means the purchaser is
		// buying 3 shares and therefore the owner will get 3 shares worth of dividends from the
		// overall purchase value. As it&#39;s the 2nd purchase, there are (3 * 4) / 2 = 6 shares total
		// according to our formula which is as expected.
		uint256 totalShares = ((artwork._purchases + 1) * (artwork._purchases + 2)) / 2;

		// Set up our prices array;
		// 0: base price
		// 1: current price
		// 2: next price
		uint256[3] memory prices;
		prices[0] = artwork._basePrice;
		// The current price is also directly related the total number of shares, it simply treats
		// the total number of shares as a percentage and adds that much on top of the base price.
		// For example if the base price was 0.01 ETH and there were 250 shares total it would mean
		// that the price would gain 250% of it&#39;s value = 0.035 ETH (100% + 250%);
		// Current Price = (Base Price * (100 + Total Shares)) / 100
		prices[1] = (prices[0] * (100 + totalShares)) / 100;
		// The next price would just be the same as the current price but we have a few extra shares.
		// If there are 0 purchases then you are buying 1 share (purchases + 1) so the next buyer would
		// be purchasing 2 shares (purchases + 2) so therefore;
		prices[2] = (prices[0] * (100 + totalShares + (artwork._purchases + 2))) / 100;

		return (
				artwork._title,
				artwork._owner,
				artwork._visible,
				prices,
				totalShares,
				artwork._purchases,
				artwork._shareholders.length
			);

	}

	function getAllShareholdersOfArtwork(uint256 artworkId) public view returns (address[] shareholders, uint256[] shares) {

		require(_exists(artworkId));

		Artwork storage artwork = _artworks[artworkId];

		uint256[] memory shareholderShares = new uint256[](artwork._shareholders.length);
		for (uint256 i = 0; i < artwork._shareholders.length; i++) {
			address shareholder = artwork._shareholders[i];
			shareholderShares[i] = artwork._shares[shareholder];
		}

		return (
				artwork._shareholders,
				shareholderShares
			);

	}

	function getAllArtworks() public view returns (bytes32[] titles, address[] owners, bool[] isVisible, uint256[3][] artworkPrices, uint256[] artworkShares, uint256[] artworkPurchases, uint256[] artworkShareholders) {

		bytes32[] memory allTitles = new bytes32[](_artworks.length);
		address[] memory allOwners = new address[](_artworks.length);
		bool[] memory allIsVisible = new bool[](_artworks.length);
		uint256[3][] memory allPrices = new uint256[3][](_artworks.length);
		uint256[] memory allShares = new uint256[](_artworks.length);
		uint256[] memory allPurchases = new uint256[](_artworks.length);
		uint256[] memory allShareholders = new uint256[](_artworks.length);

		for (uint256 i = 0; i < _artworks.length; i++) {
			string memory tmpTitle;
			(tmpTitle, allOwners[i], allIsVisible[i], allPrices[i], allShares[i], allPurchases[i], allShareholders[i]) = getArtwork(i);
			allTitles[i] = stringToBytes32(tmpTitle);
		}

		return (
				allTitles,
				allOwners,
				allIsVisible,
				allPrices,
				allShares,
				allPurchases,
				allShareholders
			);

	}

	function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
		bytes memory tmpEmptyStringTest = bytes(source);
		if (tmpEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly {
			result := mload(add(source, 32))
		}
	}

	
	//////////////////////////////////////////////////////////////////////

}