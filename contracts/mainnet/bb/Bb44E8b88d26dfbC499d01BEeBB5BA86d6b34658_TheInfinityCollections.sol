// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./BYOTInterface.sol";
import "./ReEntrancyGuard.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract TheInfinityCollections is Context, ERC165, IERC721, Ownable, ReentrancyGuard {

      constructor(BYOTInterface _byot) {
        byot = _byot;
    }

    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;

    BYOTInterface byot;

    

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    mapping(address => uint256) public mapOfClaimed;


    uint256 minted = 0;


    uint CHANGE_PRICE = .1 ether;
    uint CHANGE_PRICE_DELTA = .025 ether;
    mapping(uint256 => string) public tokenURIs; // ids to tokenURIs

  
    ///////////////////////////////

    /// EVENTS  ///

    /////////////////////////////
    event NewSlot(uint256 id,address buyer,string tokenURI);
    event UpdatedSlot(uint256 id,address buyer,string tokenURI);
    event UpdatedBaseURI(string baseURI);

    
   modifier enoughToChange() {
            require(msg.value >= CHANGE_PRICE , "Fee Entered To Change is Not Enough");
    _;
  }


    // only owner can withdraw money deposited in the contract
      function withdraw() external onlyOwner returns(bool){
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
        return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual  returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }


    //  only the owner can set the baseURI for tokenURI
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner() returns(string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        tokenURIs[tokenId] = _tokenURI;
        emit UpdatedBaseURI(tokenURIs[tokenId]);
    }

      //  internal function to set on mint or change
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal returns(string memory){
        tokenURIs[tokenId] = _tokenURI;
    }


    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = TheInfinityCollections.ownerOf(tokenId);
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = TheInfinityCollections.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
        require(TheInfinityCollections.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(TheInfinityCollections.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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



    /* 
        Slots are created based on array indexes 
        _descriptionArr[0], _imgUrlArr[0], _sizeArr[0] maps to one slot
        _descriptionArr[1], _imgUrlArr[1], _sizeArr[1] maps to another slot... and so on
        Check if enough ether to mint all slots. Arrays must be same length. Can't mint more than 20 at time
    */
    /// @dev create slot(s) in one of the houses 
     /// @param _URIs- array containing all of the img urls of slots to mint
    function createSlot(string[] memory _URIs) public nonReentrant  {
        require(byot.getMintCredits(msg.sender) - mapOfClaimed[msg.sender]  > 0, "No more pieces left to claim at this moment");
        require(_URIs.length <= byot.getMintCredits(msg.sender) - mapOfClaimed[msg.sender] && _URIs.length <= 20 , "Trying to mint too much");
         for(uint256 i = 0; i < _URIs.length; i++){
             string memory _uri = _URIs[i];
             require(bytes(_uri).length != 0, "Null Token URI");
             _createSlot(_uri);
        }
    }

     /// initializes a slot in the Infinity Collections
    /// @dev check if more slots can minted, 
    /// @param _uri - the data associated with the slot
    function _createSlot(string memory _uri) internal {
        _safeMint(msg.sender, minted);
        _setTokenURI(minted, _uri);
        emit NewSlot(minted,msg.sender,_uri);
        minted = minted.add(1);
        mapOfClaimed[msg.sender] = mapOfClaimed[msg.sender] + 1;
    }


  


    /// change information associated with a slot
    function changeSlotInfo(uint256 id, string memory _uri) public payable nonReentrant enoughToChange(){
        _changeSlotInfo(id, _uri);
    }

    /// @dev -- makes sure that person hasn't edited slot more than twice
    /// @param id -- associated with slot
    /// @param _uri -- slot's new uri
    function _changeSlotInfo(uint256 id, string memory _uri) internal{
        require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
        address owner = TheInfinityCollections.ownerOf(id);
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved to make changes"
        );
        require(bytes(_uri).length != 0);
        _setTokenURI(id, _uri);
        CHANGE_PRICE = CHANGE_PRICE + CHANGE_PRICE_DELTA;
        emit UpdatedSlot(id,msg.sender, _uri);
    }


      /// @dev -- get the slots that have been mitned so far. this makes it easy to access the slots while minting is taking place
    /// @return arrays and each index in an array represents a given slot. [0],[0],[0].. will represent the fields of a given slot
  function getSlots() public view returns(address[] memory,uint256[] memory,string[] memory) {
        address[] memory _addresses = new address[] (minted);
        uint256[] memory _idArr = new uint256[] (minted);
        string[] memory _tokenURIArr = new string[] (minted);
        for(uint256 i = 0; i < minted; i++){
            _addresses[i] = _owners[i];
            _idArr[i] = i;
            _tokenURIArr[i] = tokenURI(i);
        }
        return (_addresses,_idArr,_tokenURIArr);
    }

    // get a slot by id. will return it's field and tokenURI
    function getSlot(uint _id) public view returns(string memory){
        require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");
        return (tokenURI(_id));
    }


    function getChangePrice() external view returns(uint) {
        return CHANGE_PRICE;
    }

    function setBYOT(BYOTInterface _byot) external onlyOwner() {
        byot = _byot;
    }

    function setChangePrice(uint256 newPrice) public onlyOwner {
        CHANGE_PRICE = newPrice;
    }

    function setDeltaPrice(uint256 newPrice) public onlyOwner {
        CHANGE_PRICE_DELTA = newPrice;
    }



 
}