/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI,IERC1155Receiver {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    mapping (uint256 => bool) private _stakeStatus;
    
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }
    
    function getStakeStatus(uint256 id) public view returns(bool) {
        return _stakeStatus[id];
    } 
    
    function setStakeStatus(uint256 id, bool status) internal {
        _stakeStatus[id] = status;
    }
    
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        public view virtual override
        returns(bytes4)
    {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        public view virtual override
        returns(bytes4)
    {
        return 0xbc197c81;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }


    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
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
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
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
        require(getStakeStatus(id) == false, "token has been staked");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function _saleTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(getStakeStatus(id) == false, "token has been staked");
        
        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

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
            require(getStakeStatus(id) == false, "token has been staked");
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
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

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(getStakeStatus(id) == false, "token has been staked");
        
        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

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
            uint256 id = ids[i];
            require(getStakeStatus(id) == false, "token has been staked");
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
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
        internal
        virtual
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
}
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

contract testAccessControl{
    
    address payable public ceoAddress;
    address payable public cfoAddress;
    address payable public cooAddress;
    address payable public eventAddress;
    mapping(address => bool) public partnerAddress;
    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    
     modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    
    modifier onlyPartner(){
        require(partnerAddress[msg.sender] == true);
        _;
    }
    
    function setPartnerAddress(address partener,bool isPartener) external onlyCEO{
        partnerAddress[partener] = isPartener;
    }
    
    function setCEO(address payable _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }
    
    function setCFO(address payable _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    function setCOO(address payable _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }
    
        
    function setEventAddress(address payable _addr) external onlyCEO {
        require(_addr != address(0));

        eventAddress = _addr;
    }
}

contract testBase is testAccessControl,ERC1155{
    using SafeMath for uint;
    
    string public constant name = "testNFT";
    string public constant symbol = "test";
    
    struct Game{
        address manager;
        string  name;
        uint256  gameId;
        uint16  version;
    }
    
    struct ItemAttr{
        uint16  name;
        uint16  gameId;
        uint16  itemType;
        bool    canRaiseBirth;
        uint256 star;
        uint256 genes;
        uint256 strength;
        uint256 intelligence;
        uint256 agility;
        uint256 health;
        uint256 originalCombat;
    }
    
    struct Auction {
        // tokenId
        uint256 tokenId;
        // Current owner of NFT
        address payable seller;
        
        uint16 amount;
        
        uint16 balanceAmount;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        // Duration (in seconds) of auction
        uint64 duration;
        // Time when auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
        bool isOver;
    }
    

    mapping (uint256 => Game)   public games;
    
    mapping (uint256 => ItemAttr) private tokenIdToItemAttr;
    
    mapping (uint256 => Auction) public saleIdToAuction;

    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _gameIds;
    
    mapping (uint256 => address) public creators;
    
    mapping (uint256 => uint256) public tokenSupply;
    
    mapping (uint256 => address) public copyrightPerson;
    
    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;
    
    uint dnaDigits = 64;
    uint dnaModulus = 10 ** dnaDigits;

    uint256 public levelUpAmount = 100000000000000000;
    uint256 public upgradeStarAmount = 200000000000000000;
    uint256 public giveBirthAmount = 100000000000000000;
    IERC20 public PAY_TOKEN = IERC20(0x55d398326f99059fF775485246999027B3197955);
    bool public allowNFTFlag = false;
    bool public modifyFlag = false;
    
    event AuctionCreated(uint256 saleId,uint256 tokenId, uint16 amount,uint16 balance,uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 saleId, uint256 amount,uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 saleId);

    constructor() ERC1155("https://test.com/api/item/{id}.json"){
        ceoAddress = payable(_msgSender());
        cfoAddress = payable(_msgSender());
        cooAddress = payable(_msgSender());
        eventAddress = payable(_msgSender());
    }
    
    function setAllowNFTFlag(bool _nftFlag) external onlyCEO{
        allowNFTFlag = _nftFlag;
    }
    
    function setPayToken(IERC20 token) external onlyCEO {
        PAY_TOKEN = token;
    }
    
    function setLevelUpFee(uint256 _fee) external onlyCEO {
        levelUpAmount = _fee;    
    }
    
    function setUpagradeFee(uint256 _fee) external onlyCEO {
        upgradeStarAmount = _fee;    
    }
    
    function setBirthFee(uint256 _fee) external onlyCEO {
        giveBirthAmount = _fee;    
    }
    
    function setUrl(string memory newuri) public onlyCEO{
        _setURI(newuri);
    }
    
    function _generateRandomDna(uint256 _itemType) private view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_itemType,block.timestamp,block.number)));
        return rand % dnaModulus;
    }
    
    function _checkName(string memory str1, string memory str2) private pure returns(bool){
        return (keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2)));
    }
    
    function setStake(uint256 id, bool status) external onlyPartner{
        setStakeStatus(id, status);
    }
    
    function newGame(string memory gameName,uint16 version) public onlyPartner{
        uint256 newId = uint16(_gameIds.current());
        for(uint16 i = 0;i < newId; i++){
            Game memory beforGame = games[i];
            if(beforGame.manager == _msgSender() && _checkName(beforGame.name,gameName) == true){
                require(beforGame.version != version,"Base: The game version already exists");
            }else{
               require(_checkName(beforGame.name,gameName) == false,"Base: The game name already exists"); 
            } 
        }
        Game memory game = Game(_msgSender(),gameName,newId,version);
        games[newId] = game;
        _gameIds.increment();
    }
    
    function createHeroNFT(address account,
    uint16 itemName,uint16 gameId,bytes memory data)public virtual onlyPartner(){
        Game memory game = games[gameId];
        if (allowNFTFlag == false) {
            require(game.manager == _msgSender(),"Base: msgsender not manager!");
        }
        
        uint256 newItemId = _tokenIds.current();
        _mint(account,newItemId,1,data);
        tokenSupply[newItemId] = 1;
        uint256 genes = _generateRandomDna(1);
        uint256 strength = genes.mod(100);
        uint256 intelligence = (genes.mod(10000)).div(100);
        uint256 agility = (genes.mod(1000000)).div(10000);
        uint256 originalCombat = strength.add(intelligence).add(agility);
        
        if (originalCombat >= 250 && game.manager!=_msgSender()) {
            genes = _generateRandomDna(strength);
            strength = genes.mod(100);
            intelligence = (genes.mod(10000)).div(100);
            agility = (genes.mod(1000000)).div(10000);
            originalCombat = strength.add(intelligence).add(agility);
        }
        
        uint256 health = 100 + (strength.mul(85) + agility.mul(5) + intelligence.mul(10)).div(100);
        ItemAttr memory attr = 
            ItemAttr(itemName,gameId,1,true,1,genes,strength,intelligence,agility,health, originalCombat);
        setStakeStatus(newItemId, false);
        tokenIdToItemAttr[newItemId] = attr;
        creators[newItemId] = _msgSender();
        _tokenIds.increment();
    }
    
    function createEquipmentNFT(address account,
    uint16 itemName,uint16 gameId,bytes memory data)public virtual onlyPartner(){
        Game memory game = games[gameId];
        if (allowNFTFlag == false) {
            require(game.manager == _msgSender(),"Base: msgsender not manager!");
        }
        
        uint256 newItemId = _tokenIds.current();
        _mint(account,newItemId,1,data);
        tokenSupply[newItemId] = 1;
        uint256 genes = _generateRandomDna(2);
        uint256 strength = genes.mod(10);
        uint256 intelligence = genes.mod(100).div(10);
        uint256 agility = genes.mod(1000).div(100);
        uint256 originalCombat = strength.add(intelligence).add(agility);
        uint256 health = 15 + (strength.mul(90) + agility.mul(5) + intelligence.mul(5)).div(100);
        ItemAttr memory attr = 
            ItemAttr(itemName,gameId,2,false,1,genes,strength,intelligence,agility,health,originalCombat);
        tokenIdToItemAttr[newItemId] = attr;
        setStakeStatus(newItemId, false);
        creators[newItemId] = _msgSender();
        _tokenIds.increment();
    }
    
    function isSuccessfulAction(uint256 tokenId, uint256 factor) internal view returns(bool) {
        uint256 left = _generateRandomDna(tokenId) % factor;
        if (factor - left > 1) {
            return true;
        }
        return false;
    }
    
    function getRarity(uint256 _tokenId) public view returns(uint256) {
        ItemAttr storage token = tokenIdToItemAttr[_tokenId];
        if (token.originalCombat >= 270) {
            return 1;
        } else if (token.originalCombat >= 240) {
            return 2;
        } else if (token.originalCombat >= 170) {
            return 3;
        } else {
            return 4;
        }
    }
    
    function levelUpItem(uint256 _tokenId1, uint256 _tokenId2) public returns(uint256 _rand,uint256 _genes){
        ItemAttr storage token1 = tokenIdToItemAttr[_tokenId1];
        ItemAttr storage token2 = tokenIdToItemAttr[_tokenId2];
        require(token1.star == 1 && token2.star == 1, "Cards should be all level 1");
        require(balanceOf(_msgSender(),_tokenId1) == 1 && balanceOf(msg.sender,_tokenId2) == 1,"You must have this item");
        require(getStakeStatus(_tokenId1) == false && getStakeStatus(_tokenId2) == false, "one of token is staked");
        require(token1.itemType == 1 && token1.itemType == token2.itemType,"Must be of the same type");
        if (msg.sender != ceoAddress) {
            require(PAY_TOKEN.transferFrom(msg.sender, address(this), levelUpAmount), "you need pay fee to upgrade");
        }
        
        if (!isSuccessfulAction(_tokenId1, 3)) return(9, token1.genes);
        
        uint256 newGenes = 0;
        uint256 randTime = block.timestamp % 2;
        uint256 divNum = 1 * 10 ** 62;
        uint256 tokenGenes1 = token1.genes;
        uint256 tokenGenes2 = token2.genes;
        for(uint i = 0;i < 32; i++){
            uint256 genes1 = tokenGenes1 / divNum;
            uint256 genes2 = tokenGenes2 / divNum;
            uint256 newNum = 0;
            if((randTime == genes1 % 2) || (randTime == genes2 % 2)){   //level up success
                newNum = genes1 > genes2 ? genes1:genes2;
            }else{                  //level up fail
                newNum = genes1 > genes2 ? genes2:genes1;
            }
            tokenGenes1 = tokenGenes1 - genes1 * divNum;
            tokenGenes2 = tokenGenes2 - genes2 * divNum;
            newGenes *= 100;
            newGenes += newNum;
            divNum /= 100;
        }
        _burn(_msgSender(),_tokenId1,1);
        _burn(_msgSender(),_tokenId2,1);
        
        uint256 newItemId = _tokenIds.current();
        _mint(_msgSender(),newItemId,1,"0x03");
        tokenSupply[newItemId] = 1;
        ItemAttr storage attr = tokenIdToItemAttr[_tokenId1];
        
        uint256 strength = newGenes.mod(100);
        uint256 intelligence = (newGenes.mod(10000)).div(100);
        uint256 agility = (newGenes.mod(1000000)).div(10000);
        uint256 health = 100 + (strength.mul(85) + agility.mul(5) + intelligence.mul(10)).div(100);
        uint256 originalCombat = strength.add(intelligence).add(agility);
        tokenIdToItemAttr[newItemId] = 
            ItemAttr(attr.name,attr.gameId,attr.itemType,(token1.canRaiseBirth && token2.canRaiseBirth),
            1,newGenes,strength,intelligence,agility,health,originalCombat);
        setStakeStatus(newItemId, false);
        creators[newItemId] = _msgSender();
        _tokenIds.increment();
        
        return (randTime,newGenes);
    }
    
    function upgradeStar(uint256 _tokenId1, uint256 _tokenId2, uint16 choice) public returns(bool){
        ItemAttr storage token1 = tokenIdToItemAttr[_tokenId1];
        ItemAttr storage token2 = tokenIdToItemAttr[_tokenId2];
        if (token1.star != 1 || token2.star != 1) {
            require(token1.star > 0 && token2.star > 0 && token1.star - token2.star == 1, "should be 1 star difference between card1 and card2");
        }
        require(balanceOf(_msgSender(),_tokenId1) == 1 && balanceOf(msg.sender,_tokenId2) == 1,"You must have this item");
        require(getStakeStatus(_tokenId1) == false && getStakeStatus(_tokenId2) == false, "one of token is staked");
        require(token1.itemType == 1 && token1.itemType == token2.itemType,"Must be of the same type");
        if (msg.sender != ceoAddress) {
            require(PAY_TOKEN.transferFrom(msg.sender, address(this), upgradeStarAmount), "you need pay fee to upgrade");
        }
        
        uint256 tokenRarity = getRarity(_tokenId2);
        uint256 factor = 2;
        if (tokenRarity == 1) {
            factor = 20;
        } else if (tokenRarity == 2) {
            factor = 8;
        } else if (tokenRarity == 3) {
            factor = 3;
        }
        
        if (!isSuccessfulAction(_tokenId1, factor)) return false;
        
        uint256 tempAttrPoints = 0;
        if (token1.star == 1) {
            tempAttrPoints = 20;
            token1.health += 30;
        } else if (token1.star == 2) {
            tempAttrPoints = 30;
            token1.health += 60;
        } else if (token1.star == 3) {
            tempAttrPoints = 45;
            token1.health += 90;
        } else if (token1.star == 4) {
            tempAttrPoints = 65;
            token1.health += 150;
        } else if (token1.star == 5) {
            tempAttrPoints = 90;
            token1.health += 210;
        } else if (token1.star > 5) {
            tempAttrPoints = 90 + token1.star * 2;
            token1.health += 210 + token1.star * 5;
        }
        
        token1.star += 1;
        if (choice == 1) {
            token1.strength += tempAttrPoints;
            token1.health += tempAttrPoints.mul(85).div(100); 
        } else if (choice == 2) {
            token1.intelligence += tempAttrPoints;
            token1.health += tempAttrPoints.mul(5).div(100); 
        } else if (choice == 3) {
            token1.agility += tempAttrPoints;
            token1.health += tempAttrPoints.mul(10).div(100); 
        }
        
        _burn(_msgSender(),_tokenId2,1);
        return true;
    }
    
    
    function giveBirth(uint256 _tokenId, bytes memory data) public {
        ItemAttr storage token = tokenIdToItemAttr[_tokenId];
        require(balanceOf(_msgSender(),_tokenId) == 1,"You must have this item");
        require(getStakeStatus(_tokenId) == false, "token is staked");
        require(token.itemType == 1 && token.canRaiseBirth == true, "can not give birth");
        require(PAY_TOKEN.transferFrom(_msgSender(), address(this), giveBirthAmount), "you need pay fee to upgrade");
        
        uint256 newItemId = _tokenIds.current();
        _mint(_msgSender(),newItemId,1,data);
        tokenSupply[newItemId] = 1;
        
        uint256 genes = _generateRandomDna(1);
        uint256 strength = genes.mod(100);
        uint256 intelligence = (genes.mod(10000)).div(100);
        uint256 agility = (genes.mod(1000000)).div(10000);
        uint256 originalCombat = strength.add(intelligence).add(agility);
        
        if (originalCombat >= 250) {
            genes = _generateRandomDna(strength);
            strength = genes.mod(100);
            intelligence = (genes.mod(10000)).div(100);
            agility = (genes.mod(1000000)).div(10000);
            originalCombat = strength.add(intelligence).add(agility);
        }
        uint256 health = 100 + (strength.mul(85) + agility.mul(5) + intelligence.mul(10)).div(100);
        ItemAttr memory attr = 
            ItemAttr(token.name,token.gameId,1,false,1,genes,strength,intelligence,agility,health, originalCombat);
        tokenIdToItemAttr[newItemId] = attr;
        setStakeStatus(newItemId, false);
        creators[newItemId] = _msgSender();
        _tokenIds.increment();
        token.canRaiseBirth = false;
    }
    
    function setModifyFlag(bool flag) external onlyCEO {
        modifyFlag = flag;    
    }
    
    function modifyItemAttr(uint256 tokenId, uint256 strength, uint256 intelligence, uint256 agility) public onlyPartner {
        if (modifyFlag == false) {
            require(ceoAddress == _msgSender(),"Base: msgsender not manager!");
        }
        
        ItemAttr storage attr = tokenIdToItemAttr[tokenId];
        attr.strength = strength;
        attr.intelligence = intelligence;
        attr.agility = agility;
        attr.health = 100 + (strength.mul(85) + agility.mul(5) + intelligence.mul(10)).div(100);
        if (attr.star == 1) {
            attr.originalCombat = strength.add(intelligence).add(agility);
        }
    }
    
    function getTokenIdInfo(uint256 _tokenId) public view returns(
        uint16 _name,
        uint16 _gameId,
        uint16 _itemType,
        bool _canRaiseBirth,
        uint256 _star,
        uint256 _genes,
        uint256 _strength,
        uint256 _intelligence,
        uint256 _agility,
        uint256 _health,
        uint256 _originalCombat,
        uint256 _currentCombat
        ){
        ItemAttr storage itemAttr = tokenIdToItemAttr[_tokenId];
        return (
            itemAttr.name,
            itemAttr.gameId,
            itemAttr.itemType,
            itemAttr.canRaiseBirth,
            itemAttr.star,
            itemAttr.genes,
            itemAttr.strength,
            itemAttr.intelligence,
            itemAttr.agility,
            itemAttr.health,
            itemAttr.originalCombat,
            itemAttr.strength+itemAttr.intelligence+itemAttr.agility
            );
    }

    function getCreators(uint256 id) public view returns (address) {
        return creators[id];
    }
    
    function getUserItems(address user) public view returns(uint256[] memory ,uint256[] memory)
    {
        uint256 currentId = _tokenIds.current();
        uint256 count = 0;
        for(uint256 i = 0; i < currentId; i++){
            if(balanceOf(address(user),i)> 0){
                count++;
            }
        }
        uint256[] memory itemIds = new uint256[](count);
        uint256[] memory itemCount = new uint256[](count);
        uint256 index = 0;
        for(uint256 i = 0; i < currentId; i++){
            uint256 amount = balanceOf(address(user),i);
            if(amount > 0){
                itemIds[index] = i;
                itemCount[index] = amount;
                index++;
            }
        }
        return (itemIds,itemCount);
    }
    
    function setCut(uint256 _cut)public onlyCEO{
        ownerCut = _cut;
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId,uint256 amount,bytes calldata data) internal {
        // it will throw if transfer fails
        
        safeTransferFrom(_owner, address(this), _tokenId,amount,data);
    }
    

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId,uint256 amount,bytes calldata data) internal {
        // it will throw if transfer fails
        _saleTransfer(address(this), _receiver, _tokenId,amount,data);
    }

    /// @dev Adds an auction to the list of open auctions. Also fires the
    ///  AuctionCreated event.
    /// @param _tokenId The ID of the token to be put on auction.
    /// @param _auction Auction to add.
    function _addAuction(uint256 _saleId,uint256 _tokenId, Auction memory _auction) internal {
        // Require that all auctions have a duration of
        // at least one minute. (Keeps our math from getting hairy!)
        require(_auction.duration >= 1 minutes);

        saleIdToAuction[_saleId] = _auction;

        AuctionCreated(
            uint256(_saleId),
            uint256(_tokenId),
            uint16(_auction.amount),
            uint16(_auction.balanceAmount),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

    /// @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _saleId, uint256 tokenId,address _seller,uint16 balance,bytes calldata data) internal {
        _removeAuction(_saleId);
        _transfer(_seller, tokenId,balance,data);
        AuctionCancelled(_saleId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _saleId, uint256 _bidAmount,uint16 count)internal returns (uint256)
    {
        // Get a reference to the auction struct
        Auction storage auction = saleIdToAuction[_saleId];

        // Explicitly check that this auction is currently live.
        // (Because of how Ethereum mappings work, we can't just count
        // on the lookup above failing. An invalid _tokenId will just
        // return an auction object that is all zeros.)
        require(_isOnAuction(auction) && auction.isOver == false,"is on auction");
        
        require(auction.balanceAmount >= count,"understock");
        
        // Check that the bid is greater than or equal to the current price
        uint256 price = _currentPrice(auction) * count;
        require(_bidAmount >= price,"bidAmount must >= price");

        // Grab a reference to the seller before the auction struct
        // gets deleted.
        address payable seller = auction.seller;

        // The bid is good! Remove the auction before sending the fees
        // to the sender so we can't have a reentrancy attack.
        
        auction.balanceAmount = auction.balanceAmount - count;
        if(auction.balanceAmount <= 0){
            auction.isOver = true;
        }

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the auctioneer's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can't go negative.)
            uint256 auctioneerCut = _computeCut(price);
            uint256 buyBackCut = auctioneerCut / 4;
            uint256 cfoCut = auctioneerCut - buyBackCut;
            uint256 sellerProceeds = price - auctioneerCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it's an
            // accident, they can call cancelAuction(). )
            cfoAddress.transfer(cfoCut);
            eventAddress.transfer(buyBackCut);
            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        
        payable(msg.sender).transfer(bidExcess);
        

        // Tell the world!
        AuctionSuccessful(_saleId, count,price, msg.sender);

        return price;
    }

    /// @dev Removes an auction from the list of open auctions.
    /// @param _saleId - ID of NFT on auction.
    function _removeAuction(uint256 _saleId) internal {
        delete saleIdToAuction[_saleId];
    }

    /// @dev Returns true if the NFT is on auction.
    /// @param _auction - Auction to check.
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns current price of an NFT on auction. Broken into two
    ///  functions (this one, that computes the duration from the auction
    ///  structure, and the other that does the price computation) so we
    ///  can easily test that the price computation works correctly.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

        // A bit of insurance against negative values (or wraparound).
        // Probably not necessary (since Ethereum guarnatees that the
        // now variable doesn't ever go backwards).
        if (block.timestamp > _auction.startedAt) {
            secondsPassed = block.timestamp - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return _endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    /// @dev Computes owner's cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the ClockAuction constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }
}


contract testNFT is testBase {
    
    using Counters for Counters.Counter;
    Counters.Counter public _saleIds;
    
    constructor(){
        ownerCut = 800;
    }

    function withdrawBalance() external onlyCFO{
        cfoAddress.transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token) external onlyCFO {
        token.transfer(cfoAddress, token.balanceOf(address(this)));
    }
    
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint16 amount,
        bytes calldata data
    )
        public
    {
        require(balanceOf(msg.sender,_tokenId) >= amount);
        require(getStakeStatus(_tokenId) == false, "Item is staked");
        _escrow(msg.sender, _tokenId,amount,data);
        uint256 saleId = _saleIds.current();
        Auction memory auction = Auction(
            _tokenId,
            payable(_msgSender()),
            uint16(amount),
            uint16(amount),
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(block.timestamp),
            false
        );
        _addAuction(saleId,_tokenId, auction);
        _saleIds.increment();
    }

    /// @dev Bids on an open auction, completing the auction and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _saleId - ID of token to bid on.
    function bid(uint256 _saleId,uint16 amount,bytes calldata data)public payable
    {
        // _bid will throw if the bid or funds transfer fails
        require(amount > 0);
        Auction storage auction = saleIdToAuction[_saleId];
        uint256 _tokenId = auction.tokenId;
        _bid(_saleId, msg.value,amount);
        _transfer(msg.sender, _tokenId,amount,data);
        _removeAuction(_saleId);
    }
    
    function cancelAuction(uint256 _saleId,bytes calldata data)public
    {
        Auction storage auction = saleIdToAuction[_saleId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        uint256 tokenId = auction.tokenId;
        require(msg.sender == seller);
        _cancelAuction(_saleId, tokenId,seller,auction.balanceAmount,data);
    }
    
    function clearAuction(uint64 _beforTime,uint64 _afterTime,bool delOwner)public onlyCEO{
        uint256 saleId = _saleIds.current();
        for(uint256 i = 0;i < saleId;i++){
            Auction storage auction = saleIdToAuction[i];
            if(delOwner == false && auction.seller == ceoAddress){
                continue;
            }
            if(auction.startedAt > _beforTime && auction.startedAt < _afterTime){
                _removeAuction(i);
            }
        }
    }

    function getCurrentPrice(uint256 _saleId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = saleIdToAuction[_saleId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
    
    function getBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
}