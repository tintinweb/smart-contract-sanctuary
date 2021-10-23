// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155MetadataURI is IERC1155 {
    function uri() external view returns (string memory);
}

library String {
    /**
     * @dev Converts a `uint256` to a `string`.
     * via OraclizeAPI - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function fromUint(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    function fromAddress(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0F))];
        }
        return string(str);
    }
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri = "https://api.bundles.finance/api/token/";

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri() public view virtual override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _uri,
                    String.fromAddress(address(this)),
                    "/",
                    String.fromUint(tokenId)
                )
            );
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
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

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        uint256 accountBalance = _balances[id][account];
        require(
            accountBalance >= amount,
            "ERC1155: burn amount exceeds balance"
        );
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(
                accountBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
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
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract AHFactory is ERC1155, ERC1155Holder {
    
    using SafeMath for uint256;

    struct StructNFT {                                                          // Bundle
        string name;
        string desc;
        string link;
        uint256 copies;
        uint256 fee;
        uint256 basePrice;
        string metadata;
        address creator; // whether by Admin or Artist
        address currentOwner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    mapping(uint256 => uint256) public mintedNFT;
    mapping(uint256 => StructNFT) mappingNFT;

    mapping(address => uint256[]) ownedNFT;                 // NFT ids owned by a user

    uint256 public nextNFTIndex;
    uint256[] public indexNFT;
    

    // Create NFT by admin
    // function setNFT(uint8 _copies, uint256 _basePrice, uint256 _fee, bool _isSelf, string memory _metadata) public {
    function setNFT(string memory _name, string memory _desc, string memory _link, uint256 _copies, uint256 _fee, uint256 _basePrice, string memory _metadata) public {
        StructNFT storage instanceNFT = mappingNFT[nextNFTIndex];

        instanceNFT.name = _name;
        instanceNFT.desc = _desc;
        instanceNFT.link = _link;
        instanceNFT.copies = _copies;
        instanceNFT.fee = _fee;
        instanceNFT.basePrice = _basePrice;
        instanceNFT.metadata = _metadata;
        instanceNFT.creator = msg.sender;
        instanceNFT.currentOwner = msg.sender;

        indexNFT.push(nextNFTIndex);
        nextNFTIndex += 1;        
    }

    function getNFT(uint256 _index)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256, uint256, uint256, 
            // string memory, 
            address 
        )
    {
        require(_index < nextNFTIndex, "NFT does not exists");
        return (
            mappingNFT[_index].name,
            mappingNFT[_index].desc,
            mappingNFT[_index].link,
            mappingNFT[_index].copies,
            mappingNFT[_index].fee,
            mappingNFT[_index].basePrice,
            // mappingNFT[_index].metadata,
            mappingNFT[_index].creator
        );
    }

    function getCreator(uint256 _tokenId) public view returns(address){
        return mappingNFT[_tokenId].creator;
    }

    function getFee(uint256 _tokenId) public view returns(uint256){
        return mappingNFT[_tokenId].fee;
    }

    function getNFTCount() external view returns (uint256) {
        return indexNFT.length;
    }

    function purchaseNFT(uint256 _index, uint8 _quantity) payable public {
       
        require(_index < nextNFTIndex, "NFT does not exists");
        require(
            mintedNFT[_index] < mappingNFT[_index].copies &&
                mintedNFT[_index].add(_quantity) <= mappingNFT[_index].copies,
            " NFT: Exceeding Copies Limit"
        );
        require(msg.sender.balance >= mappingNFT[_index].basePrice * _quantity);                          // Check BALANCE

        mappingNFT[_index].creator.call{value:msg.value};
                
        super._mint(msg.sender, _index , _quantity,"");     
        mappingNFT[_index].currentOwner = msg.sender;
        ownedNFT[msg.sender].push(_index);
        
    }

    //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> RESALE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    struct StructAuction {
        uint auctionEndTime;
        address highestBidder;
        uint highestBid;
        mapping(address => uint) pendingReturns;
        uint256 startPrice;
        bool finished;
        mapping(address => uint256) myCurrendBid;
    }

    struct ReSale {
        uint256 id;                                         // Sale Id 
        uint256 price;
        uint256 quantity;
        bool privateSale;
        uint256 timestamp;
    }

    uint256 public nextSaleId;
    uint256[] public saleId;

    uint256 public feePercent = 50; 
    address public feeCollector;

    mapping (uint256 => ReSale) sale; 
    
    mapping (address => mapping (uint256 => StructAuction)) mappingAuction;
    mapping (address => string[]) public mappingAuctionData; // returns => tokenId, price, quantity, timestamp 
    // mapping (address => string[]) public mappingAuctionDetails; // returns => tokenId, price, quantity, timestamp 
    // mapping (uint256 => address[]) public _mappingBidCreators;  // store bidCreators for tokenId
    // mapping (address => mapping (uint256 => bool)) public _mappingCheckBidExists;  // returns true or false if exists

   
    mapping (address => mapping(uint256 => ReSale[])) public saleHistory;
    mapping (address => string[]) public mappingSalesHistory; // returns => tokenId, price, quantity, timestamp 


    function setFeeCollector(address _feeCollector) public onlyOwner {
      feeCollector = _feeCollector;
    }

    //------------| Currently set to 5% |---------------
    function setPlatformFee(uint256 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }
    
    function findFeePercent(uint256 _feePercent, uint256 amount) internal pure returns (uint256) {
        return amount.mul(_feePercent).div(1000);
    }

    function setSalesHistory(string memory tokenId, string memory price, string memory quantity, string memory timestamp, string memory types, address _newOwner) public {
        string memory sample = string(abi.encodePacked(tokenId,"|", price, "|", quantity, "|", timestamp, "|", types));
        mappingSalesHistory[_newOwner].push(sample);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

                
                
    //  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DIRECT SALE >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


    // ** On setting the price, NFT will be transferred to this contract.
    function setSellingPriceForNFT(uint256 _index, uint256 _quantity, uint256 _priceInWeiForm, bool _isprivateSale) public {

        require(feeCollector != address(0), "Fee collector is not set");
        require(_index < nextNFTIndex, "This NFT does not exists");

        ReSale memory instance;

        instance.id = nextSaleId;
        instance.price = _priceInWeiForm;
        instance.quantity = _quantity;
        instance.privateSale = _isprivateSale;
        instance.timestamp = block.timestamp;

        sale[nextSaleId] = instance;
        saleHistory[msg.sender][nextSaleId].push(instance);
        
        //  mappingForNFTPrice[msg.sender][_id] = _priceInWeiForm;
        //  mappingForNFTQuantity[msg.sender][_id] = _quantity;
        //  mappingQuantitySold[msg.sender][_id] += _quantity; // count NFT   
        //  mappingClaim[msg.sender][_id][true] = _quantity; 
        
        safeTransferFrom(msg.sender, address(this), _index , _quantity, "");                   // transfer NFT from seller to contract address
        
        saleId.push(nextSaleId);
        nextSaleId += 1;
    }

    function getSellingNFTPrice(uint256 _id) public view returns (uint256){
        return sale[_id].price;
    }

    function reSaleNFT (uint256 _index, uint256 _saleId, uint256 _quantity, address _seller) public payable {
        
        require( msg.value > sale[_saleId].price * sale[_saleId].quantity, "Less than net ETH amount sent");
        require(_index < nextNFTIndex, "This NFT does not exists");
        require( _quantity == sale[_saleId].quantity, "");

        uint256 sellerEth = sale[_saleId].price * _quantity;

        payable(_seller).transfer(sellerEth);

        super.safeTransferFrom(address(this), msg.sender, _index, _quantity, "");

        setSalesHistory(uint2str(_index), uint2str(msg.value), uint2str(_quantity), uint2str(block.timestamp), "sale", msg.sender);

    }



    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> AUCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


    function setAuctionData(string memory tokenId, string memory price, string memory duration, string memory timestamp, address _user) public {
        string memory dataString = string(abi.encodePacked(tokenId,"|", price, "|", duration, "|", timestamp));
        mappingAuctionData[_user].push(dataString);
    }

    /** 
        => Every auction start , 1 NFT will be transferred to contract |---
        => Finished value must be false to start the auction
    */
    function startAuction(uint256 _duration, uint256 _tokenId, uint256 _startPrice) public {      
        
        require(!mappingAuction[msg.sender][_tokenId].finished, "Current session is running"); // must be false
        require(feeCollector != address(0), "Fee collector is not set");
        require(balanceOf(msg.sender, _tokenId) > 0, "You do not possess this NFT");
        // require(recordBidCreator(_tokenId) == true, "Bid creator not recorded");
        
        mappingAuction[msg.sender][_tokenId].auctionEndTime = block.timestamp.add(_duration);
        mappingAuction[msg.sender][_tokenId].startPrice = _startPrice;
        mappingAuction[msg.sender][_tokenId].finished = true;

        safeTransferFrom(msg.sender, address(this), _tokenId , 1, ""); 
        // mappingQuantityAuctioned[msg.sender][_tokenId] += 1;           // count NFT

        setAuctionData(uint2str(_tokenId), uint2str(_startPrice), uint2str(mappingAuction[msg.sender][_tokenId].auctionEndTime), uint2str(block.timestamp), msg.sender);
        mappingAuction[msg.sender][_tokenId].highestBidder = msg.sender; // If no one bid, NFT is not lost

    }

    /**  
       => Next bid amount > current + msg.value
       => Withdrawable amount (pendingReturns)
       => My Bid Current : withdrawable + msg.value

    */  
    function bid(address _seller, uint256 _tokenId) public payable {
        
        require(mappingAuction[_seller][_tokenId].finished, "This auction has not been started yet!.");
        require(block.timestamp <= mappingAuction[_seller][_tokenId].auctionEndTime, "Invalid seller or auction already finished.");
        
        uint256 discarded = mappingAuction[_seller][_tokenId].pendingReturns[msg.sender]; 

        require(discarded.add(msg.value) > mappingAuction[_seller][_tokenId].startPrice, "Bid must be higher than start price");
        require(discarded.add(msg.value) > mappingAuction[_seller][_tokenId].highestBid, "There already is a higher bid.");
       
        if (mappingAuction[_seller][_tokenId].highestBid != 0) {
            
            address highestBDR = mappingAuction[_seller][_tokenId].highestBidder;  // Record payment for discarded bidder
            mappingAuction[_seller][_tokenId].pendingReturns[highestBDR] = mappingAuction[_seller][_tokenId].highestBid;
        }

        // my curent bid | Reset this ** | Once auction finalised
        mappingAuction[_seller][_tokenId].myCurrendBid[msg.sender] = discarded.add(msg.value);

        mappingAuction[_seller][_tokenId].highestBidder = msg.sender;
        // Highest bid = previous bid + current fund 
        mappingAuction[_seller][_tokenId].highestBid = discarded.add(msg.value);
            
        // store tokenID and seller as => string
        // ** then reset it once auction finalized

        // setAuctionDetails(uint2str(_tokenId), toString(_seller));

        // emit HighestBidIncreased(msg.sender, discarded.add(msg.value));
            
    }


    // Discarded bidder can withdraw their fund. 
    function withdraw(address _seller, uint256 _tokenId) public {
        require(block.timestamp >= mappingAuction[_seller][_tokenId].auctionEndTime, "Can withdraw once auction finished.");
        uint amount = mappingAuction[_seller][_tokenId].pendingReturns[msg.sender];
        require(amount > 0, " You bid history is not available");
        mappingAuction[_seller][_tokenId].pendingReturns[msg.sender] = 0; //____| Reset Amount |_____
        payable(msg.sender).transfer(amount);

        mappingAuction[_seller][_tokenId].myCurrendBid[msg.sender] = 0 ; // Reset my current bid if fund was withdrawn
                
    }

    function finalizeAuction(address _seller, uint256 _tokenId) public {
        require(block.timestamp >= mappingAuction[_seller][_tokenId].auctionEndTime, "Auction not yet started or finished.");
        require(mappingAuction[_seller][_tokenId].finished, "Auction already finished!.");
       
        mappingAuction[_seller][_tokenId].finished = false;
        address winner = mappingAuction[_seller][_tokenId].highestBidder;            
        safeTransferFrom(address(this), winner, _tokenId , 1, ""); // transfer from contract
        uint256 bidAmount = mappingAuction[_seller][_tokenId].highestBid;
        // mappingQuantityAuctioned[_seller][_tokenId] -= 1; // Remove count once Auction is finished
       
        //----| Royality to NFT creator |---------------
        payable(getCreator(_tokenId)).transfer(findFeePercent(getFee(_tokenId), bidAmount)); 
        payable(feeCollector).transfer(findFeePercent(feePercent, bidAmount)); // 5 %
        payable(_seller).transfer(bidAmount.sub(findFeePercent(feePercent, bidAmount)).sub(findFeePercent(getFee(_tokenId), bidAmount))); // 95%

        // removeBidCreator(_tokenId, find(_seller, _mappingBidCreators[_tokenId]), _seller); // remove the bid Creator
    
        
        setSalesHistory(uint2str(_tokenId), uint2str(bidAmount), "1", uint2str(block.timestamp), "auction", winner); 
        
        mappingAuction[_seller][_tokenId].myCurrendBid[winner] = 0 ;

        // emit AuctionFinalized(winner, mappingAuction[_seller][_tokenId].highestBid);
    }

}