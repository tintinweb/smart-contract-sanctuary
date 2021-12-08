// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PianoKingWhitelist.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/IPianoKingRNConsumer.sol";

/**
 * @dev The contract of Piano King NFTs.
 */
contract PianoKing is ERC721, Ownable, IERC2981 {
  using Address for address payable;
  using Strings for uint256;

  uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
  // The amount in Wei (0.2 ETH by default) required to give to this contract
  // in order to premint an NFT for the 7000 tokens following the 1000 in presale
  uint256 public constant MIN_PRICE = 200000000000000000;
  // The royalties taken on each sale. Can range from 0 to 10000
  // 500 => 5%
  uint16 internal constant ROYALTIES = 500;
  // The current minted supply
  uint256 public totalSupply;
  // The base url for the metadata of each token
  string public baseURI =
    "ipfs://QmX1wiZB72EnXdTxQCeZhRxtmT9GkBuWpD7TtDrfAcSio4/";
  // The supply left before next batch mint
  // Start at 0 as there is no premint for presale
  uint256 public supplyLeft = 0;

  // Address => how many tokens this address will receive on the next batch mint
  mapping(address => uint256) public preMintAllowance;

  // Addresses that have paid to get a token in the next batch mint
  address[] public preMintAddresses;

  // The random number used as a seed for the random sequence for batch mint
  uint256 internal randomSeed;
  // The random number used as the base for the incrementor in the sequence
  uint256 internal randomIncrementor;
  // Indicate if the random number is ready to be used
  bool internal canUseRandomNumber;
  // Allow to keep track of iterations through multiple consecutives
  // transactions for batch mints
  uint16 internal lastBatchIndex;

  IPianoKingRNConsumer public pianoKingRNConsumer;
  PianoKingWhitelist public pianoKingWhitelist;
  // Address authorized to withdraw the funds
  address public pianoKingWallet = 0xA263f5e0A44Cb4e22AfB21E957dE825027A1e586;
  // Address where the royalties should be sent to
  address public pianoKingFunds;

  // Doesn't have to be defined straight away, can be defined later
  // at least before phase 2
  address public pianoKingDutchAuction;

  constructor(
    address _pianoKingWhitelistAddress,
    address _pianoKingRNConsumer,
    address _pianoKingFunds
  ) ERC721("Piano King NFT", "PK") {
    require(_pianoKingWhitelistAddress != address(0), "Invalid address");
    require(_pianoKingRNConsumer != address(0), "Invalid address");
    require(_pianoKingFunds != address(0), "Invalid address");
    pianoKingWhitelist = PianoKingWhitelist(_pianoKingWhitelistAddress);
    pianoKingRNConsumer = IPianoKingRNConsumer(_pianoKingRNConsumer);
    pianoKingFunds = _pianoKingFunds;
  }

  /**
   * @dev Let anyone premint a random token as long as they send at least
   * the min price required to do so
   * The actual minting will happen later in a batch to reduce the fees
   * of random number request to off-chain oracles
   */
  function preMint() external payable {
    // The sender must send at least the min price to mint
    // and acquire the NFT
    preMintFor(msg.sender);
  }

  /**
   * @dev Premint a token for a given address.
   * Meant to be used by the Dutch Auction contract or anyone wishing to
   * offer a token to someone else or simply paying the gas fee for that person
   */
  function preMintFor(address addr) public payable {
    require(addr != address(0), "Invalid address");
    // The presale mint has to be completed before this function can be called
    require(totalSupply >= 1000, "Presale mint not completed");
    bool isDutchAuction = totalSupply >= 8000;
    // After the first phase only the Piano King Dutch Auction contract
    // can mint
    if (isDutchAuction) {
      require(msg.sender == pianoKingDutchAuction, "Only through auction");
    }
    uint256 amountOfToken = isDutchAuction ? 1 : msg.value / MIN_PRICE;
    // If the result is 0 then not enough funds was sent
    require(amountOfToken > 0, "Not enough funds");

    // We check there is enough supply left
    require(supplyLeft >= amountOfToken, "Not enough tokens left");
    // Check that the amount desired by the sender is below or
    // equal to the maximum per address
    require(
      amountOfToken + preMintAllowance[addr] <= MAX_TOKEN_PER_ADDRESS,
      "Above maximum"
    );

    // Add the address to the list if it's not in there yet
    if (preMintAllowance[addr] == 0) {
      preMintAddresses.push(addr);
    }
    // Assign the number of token to the sender
    preMintAllowance[addr] += amountOfToken;

    // Remove the newly acquired tokens from the supply left before next batch mint
    supplyLeft -= amountOfToken;
  }

  /**
   * @dev Do a batch mint for the tokens after the first 1000 of presale
   * This function is meant to be called multiple times in row to loop
   * through consecutive ranges of the array to spread gas costs as doing it
   * in one single transaction may cost more than a block gas limit
   * @param count How many addresses to loop through
   */
  function batchMint(uint256 count) external onlyOwner {
    _batchMint(preMintAddresses, count);
  }

  /**
   * @dev Mint all the token pre-purchased during the presale
   * @param count How many addresses to loop through
   */
  function presaleMint(uint256 count) external onlyOwner {
    _batchMint(pianoKingWhitelist.getWhitelistedAddresses(), count);
  }

  /**
   * @dev Fetch the random numbers from RNConsumer contract
   */
  function fetchRandomNumbers() internal {
    // Will revert if the numbers are not ready
    (uint256 seed, uint256 incrementor) = pianoKingRNConsumer
      .getRandomNumbers();
    // By checking this we enforce the use of a different random number for
    // each batch mint
    // There is still the case in which two subsequent random number requests
    // return the same random number. However since it's a true random number
    // using the full range of a uint128 this has an extremely low chance of occuring.
    // And if it does we can still request another number.
    // We can't use the randomSeed for comparison as it changes during the batch mint
    require(incrementor != randomIncrementor, "Cannot use old random numbers");
    randomIncrementor = incrementor;
    randomSeed = seed;
    canUseRandomNumber = true;
  }

  /**
   * @dev Generic batch mint
   * We don't use neither the _mint nor the _safeMint function
   * to optimize the process as much as possible in terms of gas
   * @param addrs Addresses meant to receive tokens
   * @param count How many addresses to loop through in this call
   */
  function _batchMint(address[] memory addrs, uint256 count) internal {
    // To mint a batch all of its tokens need to have been preminted
    require(supplyLeft == 0, "Batch not yet sold out");
    if (!canUseRandomNumber) {
      // Will revert the transaction if the random numbers are not ready
      fetchRandomNumbers();
    }
    // Get the ending index from the start index and the number of
    // addresses to loop through
    uint256 end = lastBatchIndex + count;
    // Check that the end is not longer than the addrs array
    require(end <= addrs.length, "Out of bounds");
    // Get the bounds of the current phase/slot
    (uint256 lowerBound, uint256 upperBound) = getBounds();
    // Set the token id to the value of the random number variable
    // If it's the start, then it will be the random number returned
    // by Chainlink VRF. If not it will be the last token id generated
    // in the batch needed to continue the sequence
    uint256 tokenId = randomSeed;
    uint256 incrementor = randomIncrementor;
    for (uint256 i = lastBatchIndex; i < end; i++) {
      address addr = addrs[i];
      uint256 allowance = getAllowance(addr);
      for (uint256 j = 0; j < allowance; j++) {
        // Generate a number from the random number for the given
        // address and this given token to be minted
        tokenId = generateTokenId(tokenId, lowerBound, upperBound, incrementor);
        _owners[tokenId] = addr;
        emit Transfer(address(0), addr, tokenId);
      }
      // Update the balance of the address
      _balances[addr] += allowance;
      if (lowerBound >= 1000) {
        // We clear the mapping at this address as it's no longer needed
        delete preMintAllowance[addr];
      }
    }
    if (end == addrs.length) {
      // We've minted all the tokens of this batch, so this random number
      // cannot be used anymore
      canUseRandomNumber = false;
      if (lowerBound >= 1000) {
        // And we can clear the preMintAddresses array to free it for next batch
        // It's always nice to free unused storage anyway
        delete preMintAddresses;
      }
      // Add the supply at the end to minimize interactions with storage
      // It's not critical to know the actual current evolving supply
      // during the batch mint so we can do that here
      totalSupply += upperBound - lowerBound;
      // Get the bounds of the next range now that this batch mint is completed
      (lowerBound, upperBound) = getBounds();
      // Assign the supply available to premint for the next batch
      supplyLeft = upperBound - lowerBound;
      // Set the index back to 0 so that next batch mint can start at the beginning
      lastBatchIndex = 0;
    } else {
      // Save the token id in the random number variable to continue the sequence
      // on next call
      randomSeed = tokenId;
      // Save the index to set as start of next call
      lastBatchIndex = uint16(end);
    }
  }

  /**
   * @dev Get the allowance of an address depending of the current supply
   * @param addr Address to get the allowance of
   */
  function getAllowance(address addr) internal view virtual returns (uint256) {
    // If the supply is below a 1000 then we're getting the white list allowance
    // otherwise it's the premint allowance
    return
      totalSupply < 1000
        ? pianoKingWhitelist.getWhitelistAllowance(addr)
        : preMintAllowance[addr];
  }

  /**
   * @dev Generate a number from a random number for the tokenId that is guarranteed
   * not to repeat within one cycle (defined by the size of the modulo) if we call
   * this function many times in a row.
   * We use the properties of prime numbers to prevent collisions naturally without
   * manual checks that would be expensive since they would require writing the
   * storage or the memory.
   * @param randomNumber True random number which has been previously provided by oracles
   * or previous tokenId that was generated from it. Since we're generating a sequence
   * of numbers defined by recurrence we need the previous number as the base for the next.
   * @param lowerBound Lower bound of current batch
   * @param upperBound Upper bound of current batch
   * @param incrementor Random incrementor based on the random number provided by oracles
   */
  function generateTokenId(
    uint256 randomNumber,
    uint256 lowerBound,
    uint256 upperBound,
    uint256 incrementor
  ) internal pure returns (uint256 tokenId) {
    if (lowerBound < 8000) {
      // For the presale of 1000 tokens and the 7 batches of
      // 1000 after  that
      tokenId = getTokenIdInRange(
        randomNumber,
        1009,
        incrementor,
        lowerBound,
        upperBound
      );
    } else {
      // Dutch auction mints of 200 tokens
      tokenId = getTokenIdInRange(
        randomNumber,
        211,
        incrementor,
        lowerBound,
        upperBound
      );
    }
  }

  /**
   * @dev Get a token id in a given range
   * @param randomNumber True random number which has been previously provided by oracles
   * or previous tokenId that was generated from it. Since we're generating a sequence
   * of numbers defined by recurrence we need the previous number as the base for the next.
   * @param lowerBound Lower bound of current batch
   * @param upperBound Upper bound of current batch
   * @param incrementor Random incrementor based on the random number provided by oracles
   */
  function getTokenIdInRange(
    uint256 randomNumber,
    uint256 modulo,
    uint256 incrementor,
    uint256 lowerBound,
    uint256 upperBound
  ) internal pure returns (uint256 tokenId) {
    // Special case in which the incrementor would be equivalent to 0
    // so we need to add 1 to it.
    if (incrementor % modulo == modulo - 1 - (lowerBound % modulo)) {
      incrementor += 1;
    }
    tokenId = lowerBound + ((randomNumber + incrementor) % modulo) + 1;
    // Shouldn't trigger too many iterations
    while (tokenId > upperBound) {
      tokenId = lowerBound + ((tokenId + incrementor) % modulo) + 1;
    }
  }

  /**
   * @dev Get the bounds of the range to generate the ids in
   * @return lowerBound The starting position from which the tokenId will be randomly picked
   * @return upperBound The ending position until which the tokenId will be randomly picked
   */
  function getBounds()
    internal
    view
    returns (uint256 lowerBound, uint256 upperBound)
  {
    if (totalSupply < 8000) {
      // For 8 batch mints of 1000 tokens including the presale
      lowerBound = (totalSupply / 1000) * 1000;
      upperBound = lowerBound + 1000;
    } else if (totalSupply < 10000) {
      // To get the 200 tokens slots to be distributed by Dutch auctions
      lowerBound = 8000 + ((totalSupply - 8000) / 200) * 200;
      upperBound = lowerBound + 200;
    } else {
      // Set both at zero to mark that we reached the end of the max supply
      lowerBound = 0;
      upperBound = 0;
    }
  }

  /**
   * @dev Set the address of the Piano King Wallet
   */
  function setPianoKingWallet(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWallet = addr;
  }

  /**
   * @dev Set the address of the Piano King Whitelist
   */
  function setWhitelist(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWhitelist = PianoKingWhitelist(addr);
  }

  /**
   * @dev Set the address of the contract authorized to do Dutch Auction
   * of the tokens of this contract
   */
  function setDutchAuction(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingDutchAuction = addr;
  }

  /**
   * @dev Set the address of the contract meant to hold the royalties
   */
  function setFundsContract(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingFunds = addr;
  }

  /**
   * @dev Set the address of the contract meant to request the
   * random number
   */
  function setRNConsumerContract(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingRNConsumer = IPianoKingRNConsumer(addr);
  }

  /**
   * @dev Set the base URI of every token URI
   */
  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  /**
   * @dev Set addresses directly in the list as if they preminted for free
   * like for giveaway.
   */
  function setPreApprovedAddresses(
    address[] memory addrs,
    uint256[] memory amounts
  ) external onlyOwner {
    require(addrs.length <= 10, "Too many addresses");
    require(addrs.length == amounts.length, "Arrays length do not match");
    for (uint256 i = 0; i < addrs.length; i++) {
      address addr = addrs[i];
      require(addr != address(0), "Invalid address");
      uint256 amount = amounts[i];
      require(amount > 0, "Amount too low");
      require(
        amount + preMintAllowance[addr] <= MAX_TOKEN_PER_ADDRESS,
        "Above maximum"
      );
      if (preMintAllowance[addr] == 0) {
        preMintAddresses.push(addr);
      }
      preMintAllowance[addr] = amount;
    }
  }

  /**
   * @dev Retrieve the funds of the sale
   */
  function retrieveFunds() external {
    // Only the Piano King Wallet or the owner can withraw the funds
    require(
      msg.sender == pianoKingWallet || msg.sender == owner(),
      "Not allowed"
    );
    payable(pianoKingWallet).sendValue(address(this).balance);
  }

  // The following functions are overrides required by Solidity.

  /**
   * @dev Override of an OpenZeppelin hook called on before any token transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    // This will prevent anyone from burning a token if he or she tries
    // to send it to the zero address
    require(to != address(0), "Burning not allowed");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Get the URI for a given token
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");
    // Concatenate the baseURI and the tokenId as the tokenId should
    // just be appended at the end to access the token metadata
    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  // View and pure functions

  /**
   * @dev Get the address of the Piano King wallet
   */
  function getPianoKingWallet() external view returns (address) {
    return pianoKingWallet;
  }

  /**
   * @dev Get the addresses that preminted
   */
  function getPremintAddresses() external view returns (address[] memory) {
    return preMintAddresses;
  }

  /**
   * @dev Called with the sale price to determine how much royalty is owed and to whom.
   * @param tokenId - the NFT asset queried for royalty information
   * @param salePrice - the sale price of the NFT asset specified by `tokenId`
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for `salePrice`
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    // The funds should be sent to the funds contract
    receiver = pianoKingFunds;
    // We divide it by 10000 as the royalties can change from
    // 0 to 10000 representing percents with 2 decimals
    royaltyAmount = (salePrice * ROYALTIES) / 10000;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * We customize the ERC721 model of OpenZeppelin to make the variable internal
 * instead of private as we want to access it to reduce fees for batch mints.
 * And since we don't use OpenZeppelin mint functions and they are not part of
 * of the official specification of the ERC721 (EIP-721), we removed them.
 * Same for the burning function as we purposely forbid burning of a token once
 * it has been minted.
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;

  // Mapping owner address to token count
  mapping(address => uint256) internal _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) internal _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    // Implementation in child contract
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender));
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721.ownerOf(tokenId) == from,
      "ERC721: transfer of token that is not own"
    );
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PianoKingWhitelist is Ownable, ReentrancyGuard {
  using Address for address payable;

  // Address => amount of tokens allowed for white listed address
  mapping(address => uint256) private whiteListAmount;
  address[] private whiteListedAddresses;
  // Supply left to be distributed
  uint256 private supplyLeft = 1000;
  uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
  // In wei
  uint256 private constant PRICE_PER_TOKEN = 100000000000000000;
  // Address authorized to withdraw the funds
  address private pianoKingWallet = 0xA263f5e0A44Cb4e22AfB21E957dE825027A1e586;
  // Indicate if the sale is open
  bool private saleOpen = true;

  event AddressWhitelisted(
    address indexed addr,
    uint256 amountOfToken,
    uint256 fundsDeposited
  );

  /**
   * @dev White list an address for a given amount of tokens
   */
  function whiteListSender() external payable nonReentrant {
    // Check that the sale is still open
    require(saleOpen, "Sale not open");
    // We check the value is at least greater or equal to that of
    // one token
    require(msg.value >= PRICE_PER_TOKEN, "Not enough funds");
    // We get the amount of tokens according to the value passed
    // by the sender. Since Solidity only supports integer numbers
    // the division will be an integer whose value is floored
    // (i.e. 15.9 => 15 and not 16)
    uint256 amountOfToken = msg.value / PRICE_PER_TOKEN;
    // We check there is enough supply left
    require(supplyLeft >= amountOfToken, "Not enough tokens left");
    // Check that the amount desired by the sender is below or
    // equal to the maximum per address
    require(
      amountOfToken + whiteListAmount[msg.sender] <= MAX_TOKEN_PER_ADDRESS,
      "Above maximum"
    );
    // If the amount is set to zero then the sender
    // is not yet whitelisted so we add it to the list
    // of whitelisted addresses
    if (whiteListAmount[msg.sender] == 0) {
      whiteListedAddresses.push(msg.sender);
    }
    // Assign the number of token to the sender
    whiteListAmount[msg.sender] += amountOfToken;

    // Remove the assigned tokens from the supply left
    supplyLeft -= amountOfToken;

    // Some events for easy to access info
    emit AddressWhitelisted(msg.sender, amountOfToken, msg.value);
  }

  /**
   * @dev Set the address of the Piano King Wallet
   */
  function setPianoKingWallet(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWallet = addr;
  }

  /**
    @dev Set the status of the sale
    @param open Whether the sale is open
   */
  function setSaleStatus(bool open) external onlyOwner {
    saleOpen = open;
  }

  /**
   * @dev Get the supply left
   */
  function getSupplyLeft() external view returns (uint256) {
    return supplyLeft;
  }

  /**
   * @dev Get the amount of tokens the address has been whitelisted for
   * If the value is equal to 0 then the address is not whitelisted
   * @param adr The address to check
   */
  function getWhitelistAllowance(address adr) public view returns (uint256) {
    return whiteListAmount[adr];
  }

  /**
   * @dev Get the list of all whitelisted addresses
   */
  function getWhitelistedAddresses() public view returns (address[] memory) {
    return whiteListedAddresses;
  }

  /**
   * @dev Retrieve the funds of the sale
   */
  function retrieveFunds() external {
    // Only the Piano King Wallet or the owner can withraw the funds
    require(
      msg.sender == pianoKingWallet || msg.sender == owner(),
      "Not allowed"
    );
    payable(pianoKingWallet).sendValue(address(this).balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPianoKingRNConsumer {
  function getRandomNumbers()
    external
    view
    returns (uint256 _randomSeed, uint256 _randomIncrementor);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";