// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./ERC1155Helpers.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
 
contract ERC1155 is Context,ERC165,ERC1155Holder, IERC1155, IERC1155MetadataURI,Owned {
    using SafeMath for uint256;
    using Address for address;
    using Strings for string;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;
    mapping (uint256 => uint256) private tokenSupply;

    
    //set as 6 because 6 NFTs are minted till token ID=6 in constrcuctor
    uint256 private _currentTokenID = 6;

    IERC20 public YouTokenAddress;
    IERC20 public JustTokenAddress;
    IERC20 public WinTokenAddress;
    


    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
    
    struct BurnTokens{
        uint256 youTokens;
        uint256 justTokens;
        uint256 winTokens;
    }
    
    // mapping id=>[YOU,JUST,WIN]
    mapping (uint256 =>BurnTokens) private _burnRequiredToMint;


    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_, address _youTokenAddress, address _justTokenAddress, address _winTokenAddress, address owner ) public Owned(owner){
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
        
         YouTokenAddress = IERC20(_youTokenAddress);
         JustTokenAddress = IERC20(_justTokenAddress);
         WinTokenAddress = IERC20(_winTokenAddress);
         
        //mint NFTs
         _mint(address(this), 1, 50, "" );
        _burnRequiredToMint[1]=BurnTokens(0, 3 ether,1 ether);
         tokenSupply[1] = 50;

         _mint(address(this), 2, 20, "" );
        _burnRequiredToMint[2]=BurnTokens(6 ether,3 ether, 1 ether);
         tokenSupply[2] = 20;

         _mint(address(this), 3, 50, "" );
        _burnRequiredToMint[3]=BurnTokens(0, 3 ether,1 ether);
         tokenSupply[3] = 50;
 
        _mint(address(this), 4, 20, "" );
        _burnRequiredToMint[4]=BurnTokens(6 ether,3 ether, 1 ether);
         tokenSupply[4] = 20;
 
        _mint(address(this), 5, 20, "" );
        _burnRequiredToMint[5]=BurnTokens(6 ether,3 ether, 1 ether);
         tokenSupply[5] = 20;
 
        _mint(address(this), 6, 50, "" );
        _burnRequiredToMint[6]=BurnTokens(0 ether,3 ether, 1 ether);
         tokenSupply[6] = 50;
 
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
     
      /**
   * @dev Returns an URI for a given token ID
   */
  function uri(uint256 _tokenId) external view override returns (string memory) {
    return Strings.strConcat(
        _uri,
        Strings.uint2str(_tokenId)
    );
  }
  
    // function uri(uint256) external view override returns (string memory) {
    //     return _uri;
    // }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    
    
  /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _to which account NFT to be minted
    * @param _initialSupply amount to supply the first owner
    * @param _Uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    
    * @return The newly created token ID
    */
  function create(
    address _to,
    uint256 _initialSupply,
    string calldata _Uri,
    bytes calldata _data
  ) external onlyOwner returns (uint256) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();

    if (bytes(_Uri).length > 0) {
      emit URI(_Uri, _id);
    }
    
    _mint(_to, _id, _initialSupply, _data);
    tokenSupply[_id] = _initialSupply;

    return _id;
  }
  
    
    /**
    * @dev Creates a new token type and assigns _initialSupply to an address
    * NOTE: remove onlyOwner if you want third parties to create new tokens on your contract (which may change your IDs)
    * @param _initialSupply amount to supply the first owner
    * @param _Uri Optional URI for this token type
    * @param _data Data to pass if receiver is contract
    * @param  youTokensToBurn YOU tokens to be burned
    * @param  justTokensToBurn JUST tokens to be burned
    * @param  winTokensToBurn WIN tokens to be burned

    * @return The newly created token ID
    */
  function createToFarm(
    uint256 _initialSupply,
    string calldata _Uri,
    bytes calldata _data,
    uint256 youTokensToBurn, 
    uint256 justTokensToBurn, 
    uint256 winTokensToBurn
  ) external onlyOwner returns (uint256) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();

    if (bytes(_Uri).length > 0) {
      emit URI(_Uri, _id);
    }
    
    _mint(address(this), _id, _initialSupply, _data);
    _burnRequiredToMint[_id]=BurnTokens(youTokensToBurn, justTokensToBurn, winTokensToBurn);
    tokenSupply[_id] = _initialSupply;

    return _id;
  }
  

  /**
    * @dev Mints some amount of tokens to an address
    * @param _id          Token ID to mint
    * @param _quantity    Amount of tokens to mint
    * @param _data        Data to pass if receiver is contract
    */
  function mint(
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) external onlyOwner {
    _mint(address(this), _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id].add(_quantity);
  }
    

 /**
    * @dev burns YOU JUST WIN and transfers NFT to sender
    * @param _id id of token which sender wants to receive in exchange of burning reqd YOU, JUST & WIN
    */
    function burnNReceiveNFT(uint256 _id) external returns (bool){
        
        uint balanceYOU = YouTokenAddress.balanceOf(msg.sender);
        uint balanceJUST = JustTokenAddress.balanceOf(msg.sender);
        uint balanceWIN = WinTokenAddress.balanceOf(msg.sender);
        
        uint reqdYOU=_burnRequiredToMint[_id].youTokens;
        uint reqdJUST=_burnRequiredToMint[_id].justTokens;
        uint reqdWIN=_burnRequiredToMint[_id].winTokens;
        
        require(balanceYOU >= reqdYOU, "YOU balance is lesser than required burn");
        require(balanceJUST >= reqdJUST, "JUST balance is lesser than required burn");
        require(balanceWIN >= reqdWIN, "WIN balance is lesser than required burn");
        
        YouTokenAddress.burnToFarm(msg.sender, reqdYOU);
        JustTokenAddress.burnToFarm(msg.sender, reqdJUST);
        WinTokenAddress.burnToFarm(msg.sender, reqdWIN);
        
        
        address operator = _msgSender();
        address from=address(this);
        
        // safe transfer
        _beforeTokenTransfer(operator, from, msg.sender, _asSingletonArray(_id), _asSingletonArray(1),"minted for burn of you,just,win");

        _balances[_id][from] = _balances[_id][from].sub(1, "ERC1155: insufficient balance for transfer");
        _balances[_id][msg.sender] = _balances[_id][msg.sender].add(1);

        emit TransferSingle(operator, from, msg.sender, _id, 1);

        _doSafeTransferAcceptanceCheck(operator, from, msg.sender, _id, 1, "");
    
        return true;
    }

    
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);

    }


    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    
    /**
     * to fetch how much YOU JUST WIN need to be burnt to mint particular NFT
     */
    function getTokensToBurnForNFT(uint256 id) public view returns (uint256[3] memory) {
        return [_burnRequiredToMint[id].youTokens,_burnRequiredToMint[id].justTokens,_burnRequiredToMint[id].winTokens];
    }
    
    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    
    

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
     
     
     function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }


     
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );
        
         tokenSupply[id] = tokenSupply[id].sub( amount);


        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
            
             tokenSupply[ids[i]]=tokenSupply[ids[i]].sub( amounts[i]);

        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

  /**
    * @dev increments the value of _currentTokenID
    */
   function _incrementTokenTypeId() private  {
     _currentTokenID++;
   }
   
   
  /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }
  
  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setURI(_newBaseMetadataURI);
  }


}