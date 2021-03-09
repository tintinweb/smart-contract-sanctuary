// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./AccessControl.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract GovERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable, AccessControl {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    bool public isOnline;
    bool public canWithdrawalFees;
    DAOInterface public DAO;
    ExchangeInterface public Exchange;
    uint256 public total_voting_power;
    uint256 constant public MAX_VOTES = 10_000_000;
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes32 public constant GOVERANCE = keccak256("GOVERANCE");
    bytes32 public constant EXCHANGE = keccak256("EXCHANGE");
    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;


    
    // Mapping from owner to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    struct Voting {
            
        uint256 id;
        
        bool hasVoted;

    }
    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public delegate_voting_power;
    mapping(uint256 => uint256) public NFT_voting_power;
    mapping(address => bool) public vote_in_progress;
    mapping (address => Voting) private currently_voting;
    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
     
     // @notice An event emitted when voting power has been changed
    event VotingPowerAdded(address indexed voter, uint256 indexed tokenId, uint256 indexed votes);
    event VotingPowerRemoved(address indexed voter, uint256 indexed tokenId,uint256 indexed votes);
    
    
    constructor (string memory name, string memory symbol, string memory baseURI_, address _exchange) public {
        _name = name;
        _symbol = symbol;
        _setBaseURI(baseURI_);
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EXCHANGE, _exchange);
        isOnline = true;
        canWithdrawalFees = false;
        _mint(msg.sender, 5_000_000);
        
    }
    
    modifier isGoverance() {
        require(
            hasRole(GOVERANCE, _msgSender()) ||  hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only permitted addresses can use this function"
        );
        _;
    }
   modifier isExchange() {
        require(
            hasRole(EXCHANGE, _msgSender()),
            "Only permitted addresses can use this function"
        );
        _;
    }
 
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mecanisms to perform token transfer, such as signature-based.
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId, uint256 voting_power) internal virtual {
        _safeMint(to, tokenId, "", voting_power);
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data, uint256 voting_power) internal virtual {
        _mint(to, voting_power);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 voting_power) internal virtual {
        require(isOnline, "The contract is paused, cannot proceed");
        require(to != address(0), "ERC721: mint to the zero address");
        uint256 tokenId = totalSupply().add(1); 
        require(!_exists(tokenId), "ERC721: token already minted");
        if(total_voting_power.add(voting_power) >= MAX_VOTES){
            return;
        }
        if(balanceOf(to) >= 1){
            uint256 current_token = tokenOfOwnerByIndex(to, 0);
            NFT_voting_power[current_token] = NFT_voting_power[current_token].add(voting_power);
            delegate_voting_power[to] = delegate_voting_power[to].add(voting_power);
            total_voting_power = total_voting_power.add(voting_power);
            emit VotingPowerAdded(to, current_token, voting_power);
            return;
        }
        _holderTokens[to].add(tokenId);
        NFT_voting_power[tokenId] = voting_power;
        delegate_voting_power[to] = delegate_voting_power[to].add(voting_power);
        _tokenOwners.set(tokenId, to);
        total_voting_power = total_voting_power.add(voting_power);
        emit VotingPowerAdded(to, tokenId, voting_power);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        //_beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);
        //_tokenOwners.remove(tokenId);
        _tokenOwners.set(tokenId, address(0));
        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!isLocked(from), "NFT votes are being used and cannot be transferred");
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        delegate_voting_power[from] = delegate_voting_power[from].sub(NFT_voting_power[tokenId]);
        delegate_voting_power[to] = delegate_voting_power[to].add(NFT_voting_power[tokenId]);
        emit VotingPowerAdded(to, tokenId, NFT_voting_power[tokenId]);
        emit VotingPowerRemoved(from, tokenId, NFT_voting_power[tokenId]);
    }
    
    
    /**
     * 
     *      GOVERANCE FUNCTIONS
     * 
     * */
      function isLocked(address _account) public returns (bool){
        if(vote_in_progress[_account]){
            if(DAO.state(currently_voting[_account].id) != ProposalState.Active){
                _unlockNFT(_account);
                return false;
            }else{
                return true;
            }
        }else{
            return false;
        }
    }
        
   function _lockNFT(address _voter, uint256 _proposal) isGoverance external returns (bool){
      vote_in_progress[_voter] = true;
      Voting memory newVote = Voting({
            id: _proposal,
            hasVoted: true
        });
      currently_voting[_voter] = newVote;
      return vote_in_progress[_voter];
   } 

    function _unlockNFT(address _voter) internal returns (bool){
         vote_in_progress[_voter] = false;
         return true;
    }

    /**
     * @dev Returns the total votes in circulation
     */
    function totalVotingPower() public view  returns (uint256) {
        return total_voting_power;
    }


    /**
     * @dev Returns an account's total voting power
     */
    function delegateVotingPower(address _address) public view  returns (uint256) {
        return delegate_voting_power[_address];
    }
    
    /**
     * @dev Returns an NFT's total voting power
     */
    function tokenVotingPower(uint256 _tokenId) public view  returns (uint256) {
        return NFT_voting_power[_tokenId];
    }
       /**  Bonding curve
     *
     * */
    function calculateCurve() public view returns (uint256) {
        uint256 p = (
            (total_voting_power.div(200) * 10**18).div(MAX_VOTES.sub(total_voting_power))
        );
        if(p > (1*10**18)){
            return 1* 10**18;
        }
        if(p == 0){
            return 1;
        }
        return p;
    }
    
    function _checkWashTrader(address _account) internal view returns (bool){
        return DAO.getWashTrader(_account);
    }
    
    function _checkApprovedContract(address _contract) internal view returns (bool){
        return DAO.getApprovedContracts(_contract);
    }
    function splitNFT(address _to, uint256 _tokenId, uint256 _split_amount)public returns (bool){
        require(isOnline, "The contract is paused, cannot proceed");
        require(ownerOf(_tokenId) == _msgSender(), "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        require(!isLocked(_msgSender()), "NFT votes are being used and cannot be transferred");
        require(delegate_voting_power[_msgSender()] >= _split_amount, "You don't have enough votes to split");
        require(NFT_voting_power[_tokenId] >= _split_amount, "Your NFT doesn't have that many votes to split");
        uint256 tokenId = totalSupply().add(1); 
        require(!_exists(tokenId), "ERC721: token already minted");
        
        
        NFT_voting_power[tokenId] = _split_amount;    
        NFT_voting_power[_tokenId] = NFT_voting_power[_tokenId].sub(_split_amount);
        _tokenOwners.set(tokenId, _to);
        _holderTokens[_to].add(tokenId);
        delegate_voting_power[_msgSender()] = delegate_voting_power[_msgSender()].sub(_split_amount);
        delegate_voting_power[_to] = delegate_voting_power[_to].add(_split_amount);
        emit VotingPowerAdded(_to, tokenId, NFT_voting_power[tokenId]);
        emit VotingPowerRemoved(_msgSender(), tokenId, NFT_voting_power[tokenId]);
        emit Transfer(address(0), _to, tokenId);
    
       
    }
    
    function buyVotes() public payable returns (bool){
        require(isOnline, "The contract is paused, cannot proceed");
        uint256 p = calculateCurve();
        uint256 amount = msg.value.div(p);
        require(amount >= 1, "Not enough for one vote");
        require(total_voting_power.add(amount) <= MAX_VOTES, "Not enough votes left to be purchased");
        _mint(_msgSender(), amount);
        return true;
        
    }
    
    function earnVotes(uint256 _value, address _seller, address _buyer, address _contract) isExchange external returns (bool){
        uint256 p = calculateCurve();
        uint256 multipler = 50;
        //p = p.add(p.mul(75).div(100));
        if(_checkApprovedContract(_contract)){
            multipler = 100;
        }
        uint256 votes = _value.div(p);
        votes = votes.mul(multipler).div(100);
        if(votes < 2){
              
            return false;
        }
         if(total_voting_power.add(votes) >= MAX_VOTES){
             
             return false;
         }
        require(_buyer != address(0x0) && _seller != address(0x0), "Cannot by the 0x0 address");
        require(_contract != address(0x0), "Cannot be the 0x0 address");
        require(_value >= 0, "Must have sent a value");
        if(_buyer == _seller){
            return false;
        }
        if(_checkWashTrader(_seller) || _checkWashTrader(_buyer)){
              
            return false;
        }
   
        votes = votes.div(2);
        _mint(_seller, votes);
        _mint(_buyer, votes);
        return true;
    }
    
    function setDAOContract(address _DAO) isGoverance public returns (bool){
        DAO = DAOInterface(_DAO);
        _setupRole(GOVERANCE, _DAO);
        return true;
    }
    function setExchangeContract(address _exchange) isGoverance public returns (bool){
        Exchange = ExchangeInterface(_exchange);
        _setupRole(EXCHANGE, _exchange);
        return true;
    }
    function toggleOnline() isGoverance public returns (bool){
        isOnline = !isOnline;
        return isOnline;
    }
      function toggleWithdrawFees() isGoverance public returns (bool){
       canWithdrawalFees = !canWithdrawalFees;
       return canWithdrawalFees;
    }
  function withdraw (uint256 _amount) public returns (bool){
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not authorized");
      require(_amount <= address(this).balance, "Not enough funds to withdrawal");
      msg.sender.transfer(_amount);
      return true;
  }
  
  function withdrawFeesByVoter(uint256 _tokenId) public returns (bool){
      require(canWithdrawalFees, "Withdrawals have not been enabled by the DAO");
      require(isOnline, "The contract is paused, cannot proceed");
      require(balanceOf(msg.sender) >= 1, "You must have atleast 1 NFT to withdrawal");
      require(ownerOf(_tokenId) == msg.sender, "You do not own that token");
      require(delegateVotingPower(msg.sender) >= 1, "You must have atleast 1 vote in order to withdrawal");
      require(tokenVotingPower(_tokenId) >= 1, "Your NFT must hold atleast 1 vote");
      require(total_voting_power.sub(NFT_voting_power[_tokenId]) >= 0, "Cannot go negative for voting power");
      require(address(Exchange).balance > 0, "No fees to withdrawal");
      _withdrawalFees(_tokenId);
      
      
  }
  function _withdrawalFees(uint256 _tokenId) internal returns (bool){
      require(tokenVotingPower(_tokenId) <= delegateVotingPower(msg.sender), "NFT has more votes than owner does");
      uint256 percentageOfVotes = (tokenVotingPower(_tokenId).mul(10_000)).div(total_voting_power);
      require(percentageOfVotes > 0, "Percentage of votes is less than minimum to withdrawal");
      uint256 ExchangeBalance = address(Exchange).balance;
      uint256 withdrawAmount = (ExchangeBalance.mul(percentageOfVotes)).div(10_000);
      require(withdrawAmount > 0, "Cannot withdrawal 0");
      require(withdrawAmount <= ExchangeBalance, "Cannot withdrawal more than the balance of the contract");
        
      delegate_voting_power[msg.sender] = delegate_voting_power[msg.sender].sub(NFT_voting_power[_tokenId]);
      emit VotingPowerRemoved(msg.sender, _tokenId, NFT_voting_power[_tokenId]); 
      total_voting_power = total_voting_power.sub(NFT_voting_power[_tokenId]);
      NFT_voting_power[_tokenId] = 0;
      _burn(_tokenId);
      require(Exchange.WithdrawalDAO(withdrawAmount, msg.sender), "Withdrawal failed");
      return true;
  }
  
}
interface DAOInterface {
    
    function state(uint256 proposalId) external view returns (GovERC721.ProposalState);
    function getWashTrader(address _account) external view returns (bool);
    function getApprovedContracts(address _contract) external view returns (bool);
}
interface ExchangeInterface {
    
    function WithdrawalDAO (uint256 _amount, address payable _account) external returns (bool);
}