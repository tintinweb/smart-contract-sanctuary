// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    using SafeMath for uint256;
    
    enum Rarity{SCRAP, NORMAL, RARE, EPIC, LEGENDARY, MYTHIC}
    enum Elements{ AIR, WATER , FIRE, EARTH }
    enum NftTypes{ CHARACTER, CREATURE , WEAPON, ITEM, ARMOR, STRUCTURE }
    
    // Save Devs Addrs
    struct  Developpers {
        mapping( address => uint  )  addressRols;
        address[]   devAddress;
    }
    
    struct Multiplies{
        int16 human;
        int16 creatures; 
        int16 structure;
    }
    
    struct  Features{
        int16 stamine;
        int16 attackpower;
        int16 agility;
        int16 criticalchance;
        int16 defence;
    }
    
    struct  Definition{
        Rarity rarity;
        Elements element;
        NftTypes nftType;
        Features features;
    }
    
    // Mapping ID to Attributes
    mapping(uint256 => Definition ) public _nftAttributes;
    
    // Multipliers by rarity
    mapping( Rarity => Multiplies ) public _multipliesByRarity ;
        
    // banned nft
    mapping(uint256 => bool )private  _NftIDIsBanned ;

    // banned account
    mapping(address => bool )public  _bannedAddress ;
    
    // team control address
    Developpers _admins;
    
    //incrementative ID
    uint256 private _NFTIds;
    
    // total amount
    uint256 _totalSupply;
    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    
    // Token symbol
    string private _customUri= "https://nftfinder.alteredbattleground.com/";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    
    // Mapping from owner to all Tokens ID
    mapping(address => uint256[]  ) private _balanceOfTokensIds;
    


    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
        @dev only devOwner
     */
    modifier onlyOwner()  {
        // require(_devsOwners[msg.sender] <= 2 && _devsOwners[msg.sender] > 0, "you shall not pass" );
        require( getDevRole(msg.sender) <= 2 && getDevRole(msg.sender) > 0, "you shall not pass" );
        _;
    }

    /**
        @dev any devs
     */
    modifier anyDev()  {
        require( getDevRole(msg.sender) <= 3  && getDevRole(msg.sender) > 0, "you shall not pass" );
        _;
    }
    
    
    /**
       * @dev See {IERC20-totalSupply}.
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor( ) {
        _name = "Alter NFT";
        _symbol = "AlterNft";
        
        
        _admins.addressRols[ _msgSender() ] = 1 ;
        _admins.devAddress.push( _msgSender() );
        
        Initializes();
    }


    /*
     @dev Instancialize initial states of NFTs
    */
    function Initializes() private {
        _multipliesByRarity[Rarity.SCRAP]       = Multiplies(90,40,10);
        _multipliesByRarity[Rarity.NORMAL]      = Multiplies(100,70,20);
        _multipliesByRarity[Rarity.RARE]        = Multiplies(110,100,30);
        _multipliesByRarity[Rarity.EPIC]        = Multiplies(120,150,50);
        _multipliesByRarity[Rarity.LEGENDARY]   = Multiplies(130,200,100);
        _multipliesByRarity[Rarity.MYTHIC]      = Multiplies(150,400,200);
    }
    
    /*
    @dev List all dev address 
    */
    function getDevList() public view  returns( address  [] memory   ){
        
        return  _admins.devAddress;
    }
    
    /*
    @dev get Dev Rol
    */
    function getDevRole(address dev)public view returns( uint ){
        return _admins.addressRols[dev] ;
    }
    
    
    /*
    @dev set Dev
    */
    function setDev(address dev, uint rol ) onlyOwner public payable  {
        if( getDevRole(dev)  <= uint(0)  ){
            _admins.devAddress.push( dev );
        }
        _admins.addressRols[ dev ] = rol ;
    }
    
    /*
    
    */
    /*
    @dev delete Dev
    */
    function delDev(address dev ) onlyOwner public payable  {
        for(uint i=0;i <  _admins.devAddress.length; i++){
            
            if( _admins.devAddress[i] == dev  ){
                delete  _admins.devAddress[i];
            }
        }
        delete _admins.addressRols[ dev ] ;
    }
    
    
    
     /*
     @dev set new Multiplies value
    */
    function setRarityMultiplier(Rarity _newRarity,Multiplies memory _multiplies ) onlyOwner public payable {
        _multipliesByRarity[_newRarity] = _multiplies;
    }

    /*
        @dev Define _customUri NFT finder
    */
    function _setURI(string memory newUri) public  onlyOwner payable {
        _customUri = newUri;
    }

    /*
    * @dev Set a custom NFT with attr
        PARAMS:( address , [Rarity,element,nftType,[stamine,attackpower,agility,criticalchance,defence]]  )
    */
    function customMintNFT(address addr, Definition memory _definition) public payable anyDev returns (uint256) {
        _NFTIds = _NFTIds.add(1);
        uint256 newNFTId = _NFTIds;

        _mint(addr, newNFTId);
        
        _nftAttributes[newNFTId] = _definition;

        return newNFTId;
    }
    
    /*
    * @dev Set a custom NFT with attr
        PARAMS:( address , [Rarity,element,nftType,[stamine,attackpower,agility,criticalchance,defence]]  )
        -> [  ["1","1","1",["100","100","100","100","100"]] ]  <-
    */
    function customMintNFT(address payable[] memory addrs, Definition[] memory _definitions) public payable onlyOwner  /* returns ( uint256[] memory ids  ) */ {
        require( addrs.length == _definitions.length ,"Incorrect List length " );
        for(uint256 i=0; i< addrs.length; i++ )
        {
            customMintNFT( addrs[i], _definitions[i] )  ;
        }
    }
    
    
    /*
    @dev bann NFT ID
    */
    function bannMultiNft(uint256  []  memory  IDs, bool[] memory  bannUmbann) public   onlyOwner payable {
        require( IDs.length == bannUmbann.length , "length is not the same" );
        
        for(uint256 i=0;i<IDs.length; i++ )
        {
            bannNft(  IDs[i] ,  bannUmbann[i] );
            //   bannNft( IDs[i] , bannUmbann[i] );
        }
    }
    

    /*
        @dev Bann Specific NFT
    */
    function bannNft(uint256  NFTID, bool  bannUmbann) public   anyDev payable {
        require( _NFTIds >= NFTID, "NewId Is Wrong");
        
        _NftIDIsBanned[ NFTID] =  bannUmbann ;
        
    }
    
    
    /*
        @dev Bann All account NFT
    */
    function bannAccountNft(address account ) public   onlyOwner payable {
        
        uint256[] memory listOfNft = getTokensOfAddress(account);
        bool[] storage  bannUBannList  ;
        
        for( uint256 i=0; i < listOfNft.length ;i++   )
        {
            // bannUBannList[i] = true;
            bannUBannList.push ( true );
        }
        
        bannMultiNft(listOfNft, bannUBannList  );
        setBannedAddress( account,  true );
    }


    /*
        @dev set banned Address
    */
    function setBannedAddress(address owner, bool bannUnbann )public onlyOwner payable {
        _bannedAddress[owner] = bannUnbann ;
    }
    
    
    /*
    @dev cehck is ntf is banned
    */
    function isBanned(uint256 _NFTId) public view returns(bool result){
        if( _NftIDIsBanned[_NFTId] ){
            result= true;
        }
        else{
            result= false;
        }
    }
    
    
     
    /*
    @dev Gett all tokens of address
    */
    function getTokensOfAddress(address owner) public view returns(uint256[] memory balance  ) {
        // require ( _balanceOfTokensIds[owner].length >0  );
        return _balanceOfTokensIds[owner];
    }
    
    /*
     *   @dev add Token ID to the owner list
    */
    function setBalanceOfTokensIds(address currentOwner , uint256 nftId) internal {
        
        // if(currentOwner != address(0)){
            _balanceOfTokensIds[currentOwner].push(nftId) ;
        // }
    }
    
    
    function removeBalanceOfTokenIds(address owner, uint256 nftId) internal {
        if(owner != address(0)){
            
            uint lengList = _balanceOfTokensIds[owner].length;
            
            for(uint i=0; i < lengList ; i++  )
            {
                if( _balanceOfTokensIds[owner][i] == nftId )
                {
                    delete _balanceOfTokensIds[owner][i] ;
                }
            }
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
    ) internal virtual {
        
        require( _bannedAddress[from] == false ,"Banned origin account");
        require( _bannedAddress[to]   == false ,"Banned destination account");
        require( isBanned(tokenId) ==false ,"Banned Token");
                
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    /*
    * @dev See atributes of nft, all feacture are here
    */
    // function tokenFeatures(uint256 tokenId)public view return( mapping(uint256 => Definition ) ){
    //     require(_exists(tokenId), "Nonexistent token");
    //     require(_attributes[tokenId] , "Nonexistent attributes");
        
    //     return 
    // }
    

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _customUri;
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
        address owner = ERC721.ownerOf(tokenId);
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
        
        setBalanceOfTokensIds( to,  tokenId );
        
        _totalSupply++;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        
        removeBalanceOfTokenIds( owner , tokenId);
        _totalSupply--;

        emit Transfer(owner, address(0), tokenId);
    }
    
    
    function burn(uint256 tokenId) onlyOwner public payable {
        _burn(tokenId);
        
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        setBalanceOfTokensIds( to,  tokenId );
        removeBalanceOfTokenIds(from, tokenId);
        
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

   
}