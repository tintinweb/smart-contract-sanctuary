pragma solidity ^0.4.11;

/* Ethart unindexed Factory Contract &#39;COSIMA&#39; v1.0 2017-07-08

	https://ethart.com - The Ethereum Art Network

	Ethart ARCHITECTURE
	-------------------
						_________________________________________
						V										V
	Controller --> Registrar <--> Factory Contract1 --> Artwork Contract1
								  Factory Contract2		Artwork Contract2
										...					...
								  Factory ContractN		Artwork ContractN

	Controller: The controller contract is the owner of the Registrar contract and can
		- Set a new owner
		- Control the assets of the Registrar (withdraw ETH, transfer, sell, burn pieces owned by the Registrar)
		- The plan is to have the controller contract be a DAO in preparation for a possible ICO
	
	Registrar:
		- The Registrar contract acts as the central registry for all sha256 hashes in the Ethart factory contract network.
		- Approved Factory Contracts can register sha256 hashes using the Registrar interface.
		- ethartArtReward of the art produced and ethartRevenueReward of turnover of the contract network will be awarded to the Registrar.
	
	Factory Contracts:
		- Factory Contracts can spawn Artwork Contracts in line with artists specifications
		- Factory Contracts will only spawn Artwork Contracts who&#39;s sha256 hashes are unique per the Registrar&#39;s sha256 registry
		- Factory Contracts will register every new Artwork Contract with it&#39;s details with the Registrar contract
	
	Artwork Contracts:
		- Artwork Contracts act as minimalist decentralised exchanges for their pieces in line with specified conditions
		- Artwork Contracts will interact with the Registrar to issue buyers of pieces a predetermined amount of Patron tokens based on the transaction value 
		- Artwork Contracts can be interacted with by the Controller via the Registrar using their interfaces to transfer, sell, burn etc pieces
	
	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.

Artworks created with this factory have the following ABI:

[{"constant":true,"inputs":[],"name":"pieceForSale","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"referrerReward","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"proofSet","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ownerCommission","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_proofLink","type":"string"}],"name":"setProof","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"proofLink","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"totalSupply","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"lowestAskAddress","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"customText","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"fillBid","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_amount","type":"uint256"}],"name":"burn","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"highestBidPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"title","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ethartArtAwarded","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"highestBidAddress","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"highestBidTime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ethartArtReward","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"referrer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_value","type":"uint256"}],"name":"burnFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"lowestAskPrice","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"cancelBid","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"changeOwner","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"pieceWanted","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"SHA256ofArtwork","outputs":[{"name":"","type":"bytes32"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_price","type":"uint256"}],"name":"offerPieceForSale","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"buyPiece","outputs":[],"payable":true,"type":"function"},{"constant":true,"inputs":[],"name":"activationTime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"piecesOwned","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"cancelSale","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"ethartRevenueReward","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"fileLink","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"placeBid","outputs":[],"payable":true,"type":"function"},{"constant":true,"inputs":[],"name":"editionSize","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"lowestAskTime","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[{"name":"_SHA256ofArtwork","type":"bytes32"},{"name":"_editionSize","type":"uint256"},{"name":"_title","type":"string"},{"name":"_fileLink","type":"string"},{"name":"_customText","type":"string"},{"name":"_ownerCommission","type":"uint256"},{"name":"_owner","type":"address"}],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"name":"price","type":"uint256"},{"indexed":false,"name":"seller","type":"address"}],"name":"NewLowestAsk","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"price","type":"uint256"},{"indexed":false,"name":"bidder","type":"address"}],"name":"NewHighestBid","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"amount","type":"uint256"},{"indexed":false,"name":"from","type":"address"},{"indexed":false,"name":"to","type":"address"}],"name":"PieceTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"from","type":"address"},{"indexed":false,"name":"to","type":"address"},{"indexed":false,"name":"price","type":"uint256"}],"name":"PieceSold","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Burn","type":"event"}]

*/

contract Interface {

	// Ethart network interface

	// Get Ethart reward variables
	function getEthartRevenueReward () returns (uint256 _ethartRevenueReward);
	function getEthartArtReward () returns (uint256 _ethartArtReward);

	// Registers a new artwork.
	function registerArtwork (address _contract, bytes32 _SHA256Hash, uint256 _editionSize, string _title, string _fileLink, uint256 _ownerCommission, address _artist, bool _indexed, bool _ouroboros);
	
	// Check if a sha256 hash is registered
	function isSHA256HashRegistered (bytes32 _SHA256Hash) returns (bool _registered);
	
	// Check if an address is a registered factory contract
	function isFactoryApproved (address _factory) returns (bool _approved);
	
	// Issues Patron tokens according to conditions specified in factory contracts
	function issuePatrons (address _to, uint256 _amount);

	// Safe transfer alternative from Open Zeppelin
	function asyncSend(address _owner, uint256 _amount);

	// Retrieve referrer and referrer reward information from the registrar
	function getReferrer (address _artist) returns (address _referrer);
	function getReferrerReward () returns (uint256 _referrerReward);

	// ERC20 interface
    function totalSupply() constant returns (uint256 totalSupply);
	function balanceOf(address _owner) constant returns (uint256 balance);
 	function transfer(address _to, uint256 _value) returns (bool success);
 	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
	function approve(address _spender, uint256 _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	function burn(uint256 _amount) returns (bool success);
	function burnFrom(address _from, uint256 _amount) returns (bool success);
}

contract Factory {

  // index of created artworks

  address[] public artworks;

  // Registrar contract address
  address registrar = 0x5f68698245e8c8949450E68B8BD8acef37faaE7D;   // set after deployment of Registrar contract

  // useful to know the row count in artworks index

  function getContractCount() 
    public
    constant
    returns(uint contractCount)
  {
    return artworks.length;
  }

  // deploy a new artwork

  function newArtwork (bytes32 _SHA256ofArtwork, uint256 _editionSize, string _title, string _fileLink, string _customText, uint256 _ownerCommission) public returns (address newArt)
  {
	Interface a = Interface(registrar);
	if (!a.isSHA256HashRegistered(_SHA256ofArtwork)) {
		Artwork c = new Artwork(_SHA256ofArtwork, _editionSize, _title, _fileLink, _customText, _ownerCommission, msg.sender);
		a.registerArtwork(c, _SHA256ofArtwork, _editionSize, _title, _fileLink, _ownerCommission, msg.sender, false, false);
		artworks.push(c);
		return c;
	}
	else {throw;}
	}
}

contract Artwork {

/* Ethart unindexed Artwork Contract &#39;COSIMA&#39; v1.0 2017-07-08

1. Introduction

This text is a plain English translation of the artwork smart contract&#39;s &#39;COSIMA&#39; programming logic and represent its terms of use (terms). This plain English translation is a best effort only and while all reasonable precautions - including significant bug bounties - have been taken to ensure that the smart contract will behave in the exact way outlined in these terms, mistakes do happen (see The DAO) which may result in unexpected and unintended contract behaviour which may include the total loss of invested funds (Ether), other tokens sent to it as well as accessibility of the contract itself. Due to the nature of smart contracts, once it is deployed on the blockchain it becomes immutably imbedded in it which means that any bugs and/or exploits discovered after deployment are unfixable. Should the code behave differently than outlined in these terms, the code - by the very nature of smart contracts - takes precedent over the terms. By deploying, interacting or otherwise using the smart contract you acknowledge and accept all associated risks while at the same time waive all rights to hold the creator of the smart contract, the artists who deployed the smart contract, its current owner as well as any other parties responsible for potential damages suffered by or caused by you through your interaction with the smart contract to yourself or others. No backsies.

2. Contract deployment

This smart contract enables its owner to issue limited edition pieces of art (pieces) that are cryptographically embedded in the Ethereum blockchain. Every piece can be owned, offered for sale, sold, bought, transferred and burned. The contract accepts bids from interested buyers and allows for the cancelation of bids as well as the cancelation of pieces offered for sale and filling of bids. In addition the owner of the contract as well as Ethart will earn a commission for every future sales of pieces irrespective of who owns, buys or sells them using the contract.

The contract creation costs approximately 2.4 Mgas - assuming a gas price of 20 Gwei, contract creation will cost ~0.05 ETH or about $15 (@$300/ETH) on the Ethereum main net. If contract creation is not urgent and Ethereum&#39;s pending transactions pool is not congested gas prices can be lowered to ~4 Gwei which would reduce the cost of deployment to ~$3 per artwork at current prices. Please make sure you understand the implications of gas cost, gas price and Ether price before you engage with this contract as the price of Ether and gas prices accepted by miners can and do change on a daily basis.

During creation the contract asks for the following parameters:

	- The SHA256 hash of your piece (the cryptographic link of your artwork to the Ethereum blockchain)
	- Edition size (the maximum number of pieces you plan to issue)
	- Title (the title or name of your artwork, if any)
	- The link to your file (if any)
	- Custom text (if any)
	- The owner&#39;s commission in basis points (i.e. 1/100th of a percent)

SHA256 hash: A SHA256 hash is a fixed length cryptographic digest of a file. On Mac and Linux it can be calculated by opening a terminal window and typing "openssl sha -sha256" followed by a space and the filename (i.e. "openssl sha -sha256 <FILENAME>") one wants to calculate the hash for. An online tool that serves the same purpose can be found at http://hash.online-convert.com/sha256-generator. By the nature of the cryptographic math the resulting hash is a) a unique fingerprint of the input file which can be independently verified by whomever has access to the original file, b) different for (almost) every file as long as at least one bit is different and c) almost impossible to reverse, meaning you can calculate a SHA256 hash from a file very easily but you can not generate the file from the SHA256 hash. Embedding the SHA256 hash in the contract at it&#39;s deployment therefore proofs that the limited edition pieces controlled by the smart contract&#39;s logic are linked to a particular file: the artwork.

Edition size: The maximum number of pieces you wish your artwork to have.

Title: the title is stored as a public string in the contract

File link: So people can independently verify that a particular file is associated with a particular instance of a smart contract you can here specify the publicly accessible link to the file. Note that providing a link is not mandatory and some artists may decide to only provide the SHA256 hash and reveal the actual file associated with it at a later point in time or never.

Custom text: This field can be whatever you want it to be. One use case could be a set of custom attributes for limited edition collectible playing cards. In this case you would format your game card attributes in a standard manner for later use e.g. Strength, Constitution, Dexterity, Intelligence, Wisdom as "12,8,6,9,3" which a later application can then read and interpreted according to your game&#39;s rules.

Owner&#39;s commission: the account that deploys/ed the smart contract can set a commission for future sales that will be paid out to the current owner of smart contract. The commission is specified in basis points where 1 basis point equals 0.01%. The commission must be greater than 0 and lower than 10000 - Ethart&#39;s reward. If the owner wants to receive 5% for all future sales for example the commission will have to be set as 500.

At deployment the owner of the smart contract will be set as the account that deployed it. Please make sure to carefully note down your account details including your address, private key, password, JSON file etc and keep it safe and secret. Remember: whoever has access to this information has access to the contract and all the funds and rights associated with it. If you loose this information it is almost certainly going to be lost forever and your funds and artwork with it. Make at least one backup and keep it in a safe location. After contract deployment it is important for you to carefully note down the contract creation transaction receipt number, contract address and ABI for later reference. You and others will require this information to interact with the contract once it is live. If you created an artwork and lost your artwork&#39;s contract address you can look up the sha256 hash of your artwork in the registrar&#39;s artwok registry which will return your artwork&#39;s contract address to you.

The artwork contract acts as it&#39;s own decentralised exchange with an on chain order book of the lowest ask and highest bid for a piece and allows for trustless trade of the pieces of art via the Ethereum blockchain.

3. Providing a proof

After deployment and before the first pieces can be bought or sold the owner has to provide a proof. This proof demonstrates that the artwork was in fact deployed by the artist. The proof can be in the form of a link to a blog post, a tweet or press release, providing at the very least the artwork&#39;s contract address or contract creation transaction number.

4. Ethart commission

The fee for letting you deploy your artworks is set by the registrar contract and will be between 0 and 10% of the edition size as well as between 0 and 10% of future revenues. Please make sure to check these numbers before you deploy your artwork&#39;s contarct as these values will be fixed after contract deployment. After you have provided the proof, the contract issues a percent of the edition size to Ethart automatically as following:

- 1 piece for every (10000 / ethartArtReward) pieces increase in edition size
- a (remainder / (10000 / ethartArtReward)) chance of an additional piece

Example: Say you create a 100 piece limited edition artwork and the ethartArtReward is set as 250 (2.5%). The contract will then issue at least 2 pieces to Ethart. In addition there will be a 20 in 40 (i.e. 50%) chance that one additional piece will be issued to Ethart. In other words, if you create a limited edition of 1 piece there is always a chance that after you provide the proof this one piece will be transferred to Ethart. To avoid disappointment we therefore recommend a minimum edition size of 2 - then you are guaranteed to keep at least one piece with an additional small chance of loosing the other. The way the math works out Ethart will on average retain ethartArtReward in basis points of all pieces.

The pieces transferred to Ethart can not be sold or transferred by Ethart for a minimum of one year (31,556,926 seconds) giving you plenty of time to monopolise the market.

5. Changing the owner

The current owner of the artwork contract can transfer ownership of the contract to another account.

6. Transferring pieces

Your artworks is in fact an ERC20 token (https://theethereum.wiki/w/index.php/ERC20_Token_Standard) and supports all ERC20 features. Pieces can be transferred to other addresses (as long as they are not being offered for sale) by their respective owners. Make sure that pieces are only being transferred to accounts that have access to their private keys. Pieces send to exchanges or other accounts that do not have access to their private keys will be lost - most likely forever.

7. Offering a piece for sale

The owner of a piece can offer it for sale. The price for which it is offered (the ask) has to be lower than the current lowest ask. Once a piece is offered for sale by its owner for a lower price than the currently lowest ask it will become the lowest ask and replace the previous lowest ask. The sale price has to be specified in wei (1000000000000000000 wei = 1 ETH).

8. Canceling a sale

The owner of a piece offered for sale can cancel the sale 24 hours after having offered the piece for sale. The 24 hour limited is intended to prevent owners to offer a piece at an artificially low price, displacing the currently lowest ask and then immediately canceling the sale.

10. Buying a piece

As long as a piece is being offered for sale, anyone can buy it as long as the buyer sends at least the current lowest ask price with the buy order. Any buy orders that do not send at least the current lowest ask price will be rejects. All the funds send with a buy order will be paid out to the seller of the piece, the contract owner as well as Ethart respectively and in proportion to the commission rules outlined above. There will be no refunds for funds sent in excess of the lowest ask price. Once a piece has been sold the lowest ask will be reset and the next piece offered for sale will become the lowest ask if any. Patrons that buy pieces via the artwork’s smart contract will be issuedpatronRewardMultiplier Patron tokens for every Ether spend in the transaction.

11. Placing a bid

Buyers can place bids in ether. Bids have to be higher than the currently highest bid. Placing a bid that is higher than the current lowest ask price will result in the bidder instantly buying the piece offered by the lowest ask seller for the bid amount.

12. Cancelling a bid

Bids can be canceled by the buyer 24 hours after they have been placed. The 24 hour limited is intended to prevent buyers from placing an artificially high bid, displacing the currently highest bid and then immediately canceling the bid.

13. Filling a bid

Bids can be filled by anyone who owns a piece.

14. Burning a piece

The owner of a piece can burn it, removing it permanently from the pool of available pieces and thereby reducing the edition size. Artists may choose to do so to increase the value of the remaining pieces or for any other reason.

15. Referral reward

The referrer of an artist receives referrerReward basis points of ethartRevenueReward as their referral reward for every piece sold using this contract. The referrer has to be set by the artist prior to creating their first artwork.

16. Withdrawing funds

For security reasons Ethart contracts&#39; handling of ether transfers have been implemented following the best practise pull payment method from Open Zeppelin (https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/payment/PullPayment.sol). This means that all funds used in placing bids and buying pieces are being transfered to the registrar contract. Sellers, artists, owners, referrer and buyers canceling their bids or those who are being outbid can claim their funds by executing the withdrawPayments method of the registrar contract. Not only does this mitigate several security concerns but at the same time provides a single location for everyone to claim their funds in one transaction.

17. Standing bug bounty

The factory contract this contract has been spawned from has a standing bug bounty of 1,000 Patrons for all practical and demonstrable exploits that cause the unintentional loss of ether and/or tokens. If you feel you have discovered an exploit path or vulnerability please contact us at http://ethart.com and claim your reward.

	(c) Stefan Pernar 2017 - all rights reserved
	(c) ERC20 functions BokkyPooBah 2017. The MIT Licence.

*/

/* Public variables */
	address public owner;						// Contract owner.
	bytes32 public SHA256ofArtwork;				// sha256 hash of the artwork.
	uint256 public editionSize;					// The edition size of the artwork.
	string public title;						// The title of the artwork.
	string public fileLink;						// The link to the file of the artwork.
	string public proofLink;					// Link to the creation proof by the artist -> this has to be done after contract creation
	string public customText;					// Custom text
	uint256 public ownerCommission;				// Percent given to the contract owner for every sale - must be >=0 && <=975 1000 = 100%.
	
	uint256 public lowestAskPrice;				// The lowest price an owner of a piece is willing to sell it for.
	address public lowestAskAddress;			// The address of the lowest ask.
	uint256 public lowestAskTime;				// The time by which the ask can be withdrawn.
	bool public pieceForSale;					// Is a piece for sale?

	uint256 public highestBidPrice;				// The highest price a buyer is willing to pay for a piece.
	address public highestBidAddress;			// The address of the highest bidder
	uint256 public highestBidTime;				// The time by which the bid can be withdrawn
	uint public activationTime;					// Time this contract has been activated.
	bool public pieceWanted;					// Is a buyer interested in a piece?

	/* Events */
	
	// Informs watchers of the contract when a new lowest ask price has been set. (price, seller)
	event NewLowestAsk (uint256 price, address seller);
	
	// Informs watchers of the contract when a new highest bid price has been placed. (price, bidder)
	event NewHighestBid (uint256 price, address bidder);
	
	// Informs watchers of the contract when a piece has been transferred. (amount, from, to)
	event PieceTransferred (uint256 amount, address from, address to);
	
	// Informs watchers of the contract when a piece has been sold. (from, to, price)
	event PieceSold (address from, address to, uint256 price);

	event Transfer (address indexed _from, address indexed _to, uint256 _value);
	event Approval (address indexed _owner, address indexed _spender, uint256 _value);
	event Burn (address indexed _owner, uint256 _amount);

	/* Other variables */
	
	// Has the proof been set yet?
	bool public proofSet;
	
	// # of pieces awarded to Ethart.
	uint256 public ethartArtAwarded;

	// Maps the number of pieces owned by an address
	mapping (address => uint256) public piecesOwned;
	
	// Used in burnFrom and transferFrom
 	mapping (address => mapping (address => uint256)) allowed;
	
	// set after deployment of Registrar contract
    address registrar = 0x5f68698245e8c8949450E68B8BD8acef37faaE7D;
	
	// Ethart reward variables - fixed after contract creation
	uint256 public ethartRevenueReward;
	uint256 public ethartArtReward;
	address public referrer;
	
	// Referrer receives referrerReward basis points of ethartRevenueReward
	uint256 public referrerReward;

	// Constructor
	function Artwork (
		bytes32 _SHA256ofArtwork,
		uint256 _editionSize,
		string _title,
		string _fileLink,
		string _customText,
		uint256 _ownerCommission,
		address _owner
	) {
		if (_ownerCommission > (10000 - ethartRevenueReward)) {throw;}
		Interface a = Interface(registrar);
		ethartRevenueReward = a.getEthartRevenueReward();
		ethartArtReward = a.getEthartArtReward();
		referrer = a.getReferrer (_owner);
		referrerReward = a.getReferrerReward ();
		// Owner is set as the address spawning the contract
		owner = _owner;
		SHA256ofArtwork = _SHA256ofArtwork;
		editionSize = _editionSize;
		title = _title;
		fileLink = _fileLink;
		customText = _customText;
		ownerCommission = _ownerCommission;
		activationTime = now;	
	}

	modifier onlyBy(address _account)
	{
		require(msg.sender == _account);
		_;
	}

	// The registrar can execute certain functions only after one year
	modifier ethArtOnlyAfterOneYear()
	{
		require(msg.sender != registrar || now > activationTime + 31536000);
		_;
	}

	// Sales / approvals have to be cancelled first for certain functions
	modifier notLocked(address _owner, uint256 _amount)
	{
		require(_owner != lowestAskAddress || piecesOwned[_owner] > _amount);
		_;
	}

	// Mitigating ERC20 short address attacks (http://vessenes.com/the-erc20-short-address-attack-explained/)
	modifier onlyPayloadSize(uint size)
	{
		require(msg.data.length >= size + 4);
		_;
	}

	// allows the current owner to assign a new owner
	function changeOwner (address newOwner) onlyBy (owner) {
		owner = newOwner;
		}

	function setProof (string _proofLink) onlyBy (owner) {
		if (!proofSet) {
			uint256 remainder;
			proofLink = _proofLink;
			proofSet = true;
			remainder = editionSize % (10000 / ethartArtReward);
			ethartArtAwarded = (editionSize - remainder) / (10000 / ethartArtReward);
			// Yes - this is gameable - if it is that important to you: go ahead.
			if (remainder > 0 && now % ((10000 / ethartArtReward) - 1) <= remainder) {ethartArtAwarded++;}
			piecesOwned[registrar] = ethartArtAwarded;
			piecesOwned[owner] = editionSize - ethartArtAwarded;
			}
		else {throw;}
		}

	function transfer(address _to, uint256 _amount) notLocked(msg.sender, _amount) onlyPayloadSize(2 * 32) returns (bool success) {
		if (piecesOwned[msg.sender] >= _amount 
			&& _amount > 0
			&& piecesOwned[_to] + _amount > piecesOwned[_to]
			// use burn() instead
			&& _to != 0x0)
			{
			piecesOwned[msg.sender] -= _amount;
			piecesOwned[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
			}
			else { return false;}
 		 }

	function totalSupply() constant returns (uint256 totalSupply) {
		totalSupply = editionSize;
		}

	function balanceOf(address _owner) constant returns (uint256 balance) {
 		return piecesOwned[_owner];
		}

	function transferFrom(address _from, address _to, uint256 _amount) notLocked(_from, _amount) onlyPayloadSize(3 * 32)returns (bool success)
		{
			if (piecesOwned[_from] >= _amount
				&& allowed[_from][msg.sender] >= _amount
				&& _amount > 0
				&& piecesOwned[_to] + _amount > piecesOwned[_to]
				// use burn() instead
				&& _to != 0x0
				&& (_from != lowestAskAddress || piecesOwned[_from] > _amount))
					{
					piecesOwned[_from] -= _amount;
					allowed[_from][msg.sender] -= _amount;
					piecesOwned[_to] += _amount;
					Transfer(_from, _to, _amount);
					return true;
					} else {return false;}
		}

	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	// To be extra secure set allowance to 0 and check that none of our allowance was spend between you sending the tx and it getting mined. Only then decrease/increase the allowance.
	// See https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.m9fhqynw2xvt
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
		}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
		}

	function burn(uint256 _amount) notLocked(msg.sender, _amount) returns (bool success) {
			if (piecesOwned[msg.sender] >= _amount) {
				piecesOwned[msg.sender] -= _amount;
				editionSize -= _amount;
				Burn(msg.sender, _amount);
				return true;
			}
			else {throw;}
		}

	function burnFrom(address _from, uint256 _value) notLocked(_from, _value) onlyPayloadSize(2 * 32) returns (bool success) {
		if (piecesOwned[_from] >= _value && allowed[_from][msg.sender] >= _value) {
			piecesOwned[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			editionSize -= _value;
			Burn(_from, _value);
			return true;
		}
		else {throw;}
	}

	function buyPiece() payable {
		if (pieceForSale && msg.value >= lowestAskPrice) {
			uint256 _amountOwner;
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 _amountReferrer;
			_amountOwner = (msg.value / 10000) * ownerCommission;
			_amountEthart = (msg.value / 10000) * ethartRevenueReward;
			_amountSeller = msg.value - _amountOwner - _amountEthart;
			Interface a = Interface(registrar);
			if (referrer != 0x0) {
				_amountReferrer = _amountEthart / 10000 * referrerReward;
				_amountEthart -= _amountReferrer;
				// Async send the referrer reward to the referrer
				a.asyncSend(referrer, _amountReferrer);
				}
			piecesOwned[lowestAskAddress]--;
			piecesOwned[msg.sender]++;
			PieceSold (lowestAskAddress, msg.sender, msg.value);
			pieceForSale = false;
			lowestAskPrice = 0;
			// Reward the buyer with Patron tokens
			a.issuePatrons(msg.sender, msg.value);
			// Async send the contract owner&#39;s commission
			a.asyncSend(owner, _amountOwner);
			// Async send the buy price - commissions to seller
			a.asyncSend(lowestAskAddress, _amountSeller);
			lowestAskAddress = 0x0;
			// Async send Ethart commission to Ethart
			a.asyncSend(registrar, _amountEthart);
			// Transfer the sale price to the registrar contract
			registrar.transfer(msg.value);
		}
		else {throw;}
	}

	// Offer a piece for sale at a fixed price - the price has to be lower than the current lowest price
	function offerPieceForSale (uint256 _price) ethArtOnlyAfterOneYear {
		if ((_price < lowestAskPrice || !pieceForSale) && piecesOwned[msg.sender] >= 1) {
				if (_price <= highestBidPrice) {fillBid();}
				else
				{
					pieceForSale = true;
					lowestAskPrice = _price;
					lowestAskAddress = msg.sender;
					lowestAskTime = now;
					NewLowestAsk (_price, lowestAskAddress);			// alerts contract watchers about new lowest ask price.
				}
		}
		else {throw;}
	}

	// place a bid for a piece - bid has to be higher than current highest bid
	function placeBid () payable {
		if (msg.value > highestBidPrice || (pieceForSale && msg.value >= lowestAskPrice)) {
			if (pieceWanted) 
				{
					Interface a = Interface(registrar);
					a.asyncSend(highestBidAddress, highestBidPrice);
				}
			if (pieceForSale && msg.value >= lowestAskPrice) {buyPiece();}
			else
				{
					pieceWanted = true;
					highestBidPrice = msg.value;
					highestBidAddress = msg.sender;
					highestBidTime = now;
					NewHighestBid (msg.value, highestBidAddress);
					registrar.transfer(msg.value);
				}
		}
		else {throw;}
	}

	// If the current lowest ask address wants to fill a bid it has to either cancel it&#39;s sale first and then
	// fill the bid or lower the lowest ask price to be equal or lower than the highest bid.
	function fillBid () ethArtOnlyAfterOneYear notLocked(msg.sender, 1) {
		if (pieceWanted && piecesOwned[msg.sender] >= 1) {
			uint256 _amountOwner;														
			uint256 _amountEthart;
			uint256 _amountSeller;
			uint256 _amountReferrer;
			_amountOwner = (highestBidPrice / 10000) * ownerCommission;
			_amountEthart = (highestBidPrice / 10000) * ethartRevenueReward;
			_amountSeller = highestBidPrice - _amountOwner - _amountEthart;
			Interface a = Interface(registrar);
			if (referrer != 0x0) {
				_amountReferrer = _amountEthart / 10000 * referrerReward;
				_amountEthart -= _amountReferrer;
				// Async send the referrer reward to the referrer
				a.asyncSend(referrer, _amountReferrer);
				}
			piecesOwned[highestBidAddress]++;
			// Reward the buyer with Patron tokens
			a.issuePatrons(highestBidAddress, highestBidPrice);				
			piecesOwned[msg.sender]--;
			PieceSold (msg.sender, highestBidAddress, highestBidPrice);
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			// Async send the contract owner&#39;s commission
			a.asyncSend(owner, _amountOwner);
			// Async send the buy price - commissions to seller
			a.asyncSend(msg.sender, _amountSeller);
			// Async send Ethart commission to Ethart
			a.asyncSend(registrar, _amountEthart);
		}
		else {throw;}
	}

	// withdraw a bid - bids can only be withdrawn after 24 hours of being placed
	function cancelBid () onlyBy (highestBidAddress){
		if (pieceWanted && now > highestBidTime + 86400) {
			pieceWanted = false;
			highestBidPrice = 0;
			highestBidAddress = 0x0;
			NewHighestBid (0, 0x0);
			Interface a = Interface(registrar);
			a.asyncSend(msg.sender, highestBidPrice);			
		}
		else {throw;}
	}

	// cancels sales - sales can only be canceled 24 hours after it has been offered for sale
	function cancelSale () onlyBy (lowestAskAddress){
		if(pieceForSale && now > lowestAskTime + 86400) {
			pieceForSale = false;
			lowestAskPrice = 0;
			lowestAskAddress = 0x0;
			NewLowestAsk (0, 0x0);
		}
		else {throw;}
	}

}