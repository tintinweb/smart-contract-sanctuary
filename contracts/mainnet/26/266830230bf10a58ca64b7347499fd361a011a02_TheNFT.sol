/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/*

TheNFT - TheDAO NFT
thedaonft.eth
https://github.com/0xTycoon/thedao-nft

On the 25th of July, 2017, The Securities and Exchange Commission (SEC) released an 18 page report about their
investigation in to TheDAO. The report concluded that TheDAO tokens are securities.

The following project converts each page in to an image, then shreds the images into strips. These strips can be then
minted into NFTs

RULES

1. Each NFT requires 1 DAO token to be minted
2. The DAO token will be wrapped inside the NFT
3. The DAO token can be unwrapped
4. When unwrapped, the NFT gets transferred to the "Dead Address"
5. The NFT can be restored from the "Dead Address" with 4 DAO restoration fee
6. the restoration fee goes to the Curator

### Digital Assets

The images are prepared with the help of a script, see script.php for the source.
The input for the script is TheDAO-SEC-34-81207.pdf with the sha256-hash of:
6c9ae041b9b9603da01d0aa4d912586c8d85b9fe1932c57f988d8bd0f9da3bc7

After the script completes creating all the tiles, the following sha256-hash will be printed:
final hash: 3ed52e4afc9030f69004f163017c3ffba0b837d90061437328af87330dee9575

### Minting

Minting is done sequentially from 0 to 1799
Up to 100 NFTs can be minted per transaction at a time (if gas allows)

At the beginning, all tokens are owned by 0x0
balanceOf(address(this)) is used to track how many tokens are yet to be minted

* Tokens cannot be sent to address(this)
* Tokens cannot be sent to 0x0



*/

//import "hardhat/console.sol";

//import "./safemath.sol"; // we don't need it

contract TheNFT {
    /**
    * @dev PNG_SHA_256_HASH is a sha256 hash-sum of all 1800 bitmap tiles saved in the PNG format
    * (the final hash)
    */
    string public constant PNG_SHA_256_HASH = "3ed52e4afc9030f69004f163017c3ffba0b837d90061437328af87330dee9575";
    /**
    * @dev PDF_SHA_256_HASH is a sha256 hash-sum of the pdf file TheDAO-SEC-34-81207.pdf
    */
    string public constant PDF_SHA_256_HASH = "6c9ae041b9b9603da01d0aa4d912586c8d85b9fe1932c57f988d8bd0f9da3bc7";
    address private constant DEAD_ADDRESS = address(0x74eda0); // unwrapped NFTs go here
    address public curator;                                    // the curator receives restoration fees
    string private assetURL;
    string private baseURI;
    uint256 private immutable max;                             // total supply (1800)
    uint256 private constant fee = 4;                          // fee is the amount of DAO needed to restore

    // TheDAO stuff
    IERC20 private immutable theDAO;                           // the contract of TheDAO, the greatest DAO of all time
    uint256 private constant oneDao = 1e16;                    // 1 DAO = 16^10 wei or 0.01 ETH

    mapping(address => uint256) private balances;              // counts of ownership
    mapping(uint256  => address) private ownership;
    mapping(uint256  => address) private approval;
    mapping(address => mapping(address => bool)) private approvalAll; // operator approvals

    /**
     * Mint is fired when a new token is minted
     */
    event Mint(address owner, uint256 tokenId);
    /**
     * @dev Burn is fired when a token is burned
     */
    event Burn(address owner, uint256 tokenId);
    /**
     * @dev Restore is fired when a token is restored from the burn
     */
    event Restore(address owner, uint256 tokenId);
    /**
     * @dev Curator is fired when a curator is changed
     */
    event Curator(address curator);
    /**
     * @dev BaseURI is fired when the baseURI changed (set by the Curator)
     */
    event BaseURI(string);

    /**
    * @dev TheNFT constructor
    * @param _theDAO address of TheDAO contract
    * @param _max max supply of the NFT collection
    */
    constructor(address _theDAO, uint256 _max) {
        curator = msg.sender;
        theDAO = IERC20(_theDAO);
        balances[address(this)] = _max; // track how many haven't been minted
        max = _max;
    }

    modifier onlyCurator {
        require(
            msg.sender == curator,
            "only curator can call this"
        );
        _;
    }

    /**
    * @dev regulators are not needed - smart contracts regulate themselves
    */
    modifier regulated(address _to) {
        require(
            _to != DEAD_ADDRESS,
            "cannot send to dead address"
        );
        require(
            _to != address(this),
            "cannot send to self"
        );
        require(
            _to != address(0),
            "cannot send to 0x"
        );
        _;
    }

    /**
    * @dev getStats helps to fetch some stats for the UI in a single web3 call
    * @param _user the address to return the report for
    * @return uint256[6] the stats
    */
    function getStats(address _user) external view returns(uint256[] memory) {
        uint[] memory ret = new uint[](6);
        ret[0] = theDAO.balanceOf(_user);                // amount of TheDAO tokens owned by _user
        ret[1] = theDAO.allowance(_user, address(this)); // amount of DAO this contract is approved to spend
        ret[2] = balanceOf(address(this));               // how many NFTs to be minted
        ret[3] = balanceOf(DEAD_ADDRESS);                // how many NFTs are burned
        ret[4] = theDAO.balanceOf(address(this));        // amount of DAO held by this contract
        ret[5] = balanceOf(_user);                       // how many _user has
        return ret;
    }

    /**
    * @dev mint mints a token. Requires 1 DAO per NFT to mint
    */
    function mint(uint256 i) external {
        uint256 id = max - balances[address(this)];                    // id is the next assigned id
        require(id < max, "minting finished");
        require (i > 0 && i <= 100, "must be between 1 and 100");
        if (i + id > max) {                                            // if it goes over the max supply
            i = max -  id;                                             // cap it
        }
        if (theDAO.transferFrom(msg.sender, address(this), oneDao*i)) { // take the DAO fee
            while (i > 0) {
                _transfer(address(this), msg.sender, id);
                emit Mint(msg.sender, id);
                i--;
                id++;
            }
        }
    }

    /**
    * @dev burn gives 1 DAO back to the owner
    */
    function burn(uint256 id) external {
        require (msg.sender == ownership[id], "only owner can burn");
        if (theDAO.transfer(msg.sender, oneDao)) { // send theDAO token back to sender
            _transfer(msg.sender, DEAD_ADDRESS, id); // burn the NFT token
            emit Burn(msg.sender, id);
        }
    }

    /**
    * To restore, there will be a 4 DAO fee, so 5 DAO in total to restore
    */
    function restore(uint256 id) external {
        require(DEAD_ADDRESS == ownership[id], "must be dead");
        require(theDAO.transferFrom(msg.sender, address(this), oneDao), "DAO deposit insufficient");
        require(theDAO.transferFrom(msg.sender, curator, oneDao*fee), "DAO fee insufficient"); // Fee goes to the curator
        _transfer(DEAD_ADDRESS, msg.sender, id); // send the NFT token to the new owner
        emit Restore(msg.sender, id);
    }
    /**
    * @dev setCurator sets the curator address
    */
    function setCurator(address _curator) external onlyCurator {
        curator = _curator;
        emit Curator(_curator);
    }

    /**
    * @dev setBaseURI sets the baseURI value
    */
    function setBaseURI(string memory _uri) external onlyCurator {
        baseURI = _uri;
        emit BaseURI(_uri);
    }

    /***
    * ERC721 stuff
    */

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Approval is fired when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev ApprovalForAll is fired when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return max;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require (_index < max, "index out of range");
        return _index;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address  _owner , uint256 _index) external view returns (uint256) {
        require (_index < max, "index out of range");
        require (_owner != address(0), "address invalid");
        require (ownership[_index] != address(0), "token not assigned");
        return _index;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address _holder) public view returns (uint256) {
        require (_holder != address(0));
        return balances[_holder];
    }

    function name() public pure returns (string memory) {
        return "TheNFT Project";
    }

    function symbol() public pure returns (string memory) {
        return "TheNFT";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require (_tokenId < max, "index out of range");
        string memory _baseURI = baseURI;
        uint256 num = _tokenId % 100;
        return bytes(_baseURI).length > 0
        ? string(abi.encodePacked(_baseURI, toString(_tokenId/100), "/", toString(num), ".json"))
        : '';
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require (_tokenId < max, "index out of range");
        address holder = ownership[_tokenId];
        require (holder != address(0), "not minted.");
        return holder;
    }

    /**
    * @dev Throws unless `msg.sender` is the current owner, an authorized
    *  operator, or the approved address for this NFT. Throws if `_from` is
    *  not the current owner. Throws if `_to` is the zero address. Throws if
    *  `_tokenId` is not a valid NFT.
    * @param _from The current owner of the NFT
    * @param _to The new owner
    * @param _tokenId The NFT to transfer
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external regulated(_to) {
        require (_tokenId < max, "index out of range");
        address owner = ownership[_tokenId];
        require (owner == _from, "_from must be owner");
        require (_to != address(0), "_to most not be 0x");
        if (msg.sender == owner || (approvalAll[owner][msg.sender])) {
            _transfer(_from, _to, _tokenId);
        } else if (approval[_tokenId] == msg.sender) {
            approval[_tokenId] = address (0); // clear previous approval
            emit Approval(msg.sender, address (0), _tokenId);
            _transfer(_from, _to, _tokenId);
        } else {
            revert("not permitted");
        }
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
    * @dev Throws unless `msg.sender` is the current owner, an authorized
    *  operator, or the approved address for this NFT. Throws if `_from` is
    *  not the current owner. Throws if `_to` is the zero address. Throws if
    *  `_tokenId` is not a valid NFT.
    * @param _from The current owner of the NFT
    * @param _to The new owner
    * @param _tokenId The NFT to transfer
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external regulated(_to) {
        require (_tokenId < max, "index out of range");
        address owner = ownership[_tokenId];
        require (owner == _from, "_from must be owner");
        require (_to != address(0), "_to most not be 0x");
        if (msg.sender == owner || (approvalAll[owner][msg.sender])) {
            _transfer(_from, _to, _tokenId);
        } else if (approval[_tokenId] == msg.sender) {
            approval[_tokenId] = address (0); // clear previous approval
            emit Approval(msg.sender, address (0), _tokenId);
            _transfer(_from, _to, _tokenId);
        } else {
            revert("not permitted");
        }
        require(_checkOnERC721Received(_from, _to, _tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external regulated(_to) {
        require (_tokenId < max, "index out of range");
        address owner = ownership[_tokenId];
        require (owner == _from, "_from must be owner");
        require (_to != address(0), "_to most not be 0x");
        if (msg.sender == owner || (approvalAll[owner][msg.sender])) {
            _transfer(_from, _to, _tokenId);
        } else if (approval[_tokenId] == msg.sender) {
            approval[_tokenId] = address (0); // clear previous approval
            emit Approval(msg.sender, address (0), _tokenId);
            _transfer(_from, _to, _tokenId);
        } else {
            revert("not permitted");
        }
    }

    /**
    * @notice Change or reaffirm the approved address for an NFT
    * @dev The zero address indicates there is no approved address.
    *  Throws unless `msg.sender` is the current NFT owner, or an authorized
    *  operator of the current owner.
    * @param _to The new approved NFT controller
    * @param _tokenId The NFT to approve
    */
    function approve(address _to, uint256 _tokenId) external {
        require (_tokenId < max, "index out of range");
        address owner = ownership[_tokenId];
        require (owner == msg.sender || isApprovedForAll(owner, msg.sender), "action not token permitted");
        approval[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    /**
    * @notice Enable or disable approval for a third party ("operator") to manage
    *  all of `msg.sender`'s assets
    * @dev Emits the ApprovalForAll event. The contract MUST allow
    *  multiple operators per owner.
    * @param _operator Address to add to the set of authorized operators
    * @param _approved True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        require(msg.sender != _operator, "ERC721: approve to caller");
        approvalAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
    * @notice Get the approved address for a single NFT
    * @dev Throws if `_tokenId` is not a valid NFT.
    * @param _tokenId The NFT to find the approved address for
    * @return The approved address for this NFT, or the zero address if there is none
    */
    function getApproved(uint256 _tokenId) public view returns (address) {
        require (_tokenId < max, "index out of range");
        return approval[_tokenId];
    }

    /**
    * @notice Query if an address is an authorized operator for another address
    * @param _owner The address that owns the NFTs
    * @param _operator The address that acts on behalf of the owner
    * @return True if `_operator` is an approved operator for `_owner`, false otherwise
    */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return approvalAll[_owner][_operator];
    }

    /**
    * @notice Query if a contract implements an interface
    * @param interfaceId The interface identifier, as specified in ERC-165
    * @dev Interface identification is specified in ERC-165. This function
    *  uses less than 30,000 gas.
    * @return `true` if the contract implements `interfaceID` and
    *  `interfaceID` is not 0xffffffff, `false` otherwise
    */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        interfaceId == type(IERC721TokenReceiver).interfaceId;
    }

    /**
    * @dev transfer a token from _from to _to
    * @param _from from
    * @param _to to
    * @param _tokenId the token index
    */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        balances[_to]++;
        balances[_from]--;
        ownership[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    // we do not allow NFTs to be send to this contract
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes memory /*_data*/) external pure returns (bytes4) {
        revert("nope");
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
    *
    * credits https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
    */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
            return false; // not needed, but the ide complains that there's "no return statement"
        } else {
            return true;
        }
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * credits https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by openzeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15
        // this version removes the decimals counting

        uint8 count;
        if (value == 0) {
            return "0";
        }
        uint256 digits = 31;
        // bytes and strings are big endian, so working on the buffer from right to left
        // this means we won't need to reverse the string later
        bytes memory buffer = new bytes(32);
        while (value != 0) {
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
            digits -= 1;
            count++;
        }
        uint256 temp;
        assembly {
            temp := mload(add(buffer, 32))
            temp := shl(mul(sub(32,count),8), temp)
            mstore(add(buffer, 32), temp)
            mstore(buffer, count)
        }
        return string(buffer);
    }
}


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

interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the
    /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
    /// of other than the magic value MUST result in the transaction being reverted.
    /// @notice The contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns (bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


/*
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * 0xTycoon was here
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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