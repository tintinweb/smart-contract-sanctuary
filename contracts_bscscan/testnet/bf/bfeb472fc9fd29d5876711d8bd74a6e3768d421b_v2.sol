/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.0;

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
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

contract ERC1155 is Context, ERC165, IERC1155 {
    using Address for address;

    address public escrowAddress;
    address public admin;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(address _admin, address _escrowAddress) {
        admin = payable(_admin);
        escrowAddress = _escrowAddress;
        EscrowInterface = EscrowInt(escrowAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    EscrowInt public EscrowInterface;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function changeAdmin(address _admin) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        admin = payable(_admin);
        return true;
    }

    function setEscrowAddress(address _escrowAddress) external onlyAdmin {
        escrowAddress = _escrowAddress;
        EscrowInterface = EscrowInt(escrowAddress);
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length);

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

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
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
        require(_msgSender() == escrowAddress, "Only escrow contract");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "Not owner or not approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(_msgSender() == escrowAddress, "Only escrow contract");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155:Caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

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
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

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
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

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
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface EscrowInt {
    function placeOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256 _timeline,
        uint256 _adminPlatformFee
    ) external returns (bool);
}

pragma solidity 0.8.0;

contract v2 is ERC1155 {
    using SafeMath for uint256;

    // address public admin;
    // address public escrowAddress;
    uint256 public maxEditionsPerNFT;
    uint256 public tokenId;

    struct owner {
        address creator;
        uint256 percent1;
        address coCreator;
        uint256 percent2;
    }

    // Escrow public EscrowInterface;

    enum Type {
        Instant,
        Auction,
        secondHandBuy
    }

    mapping(address => bool) public creator;
    mapping(uint256 => owner) private ownerOf;
    mapping(uint256 => string) public tokenURI;

    constructor(address _admin, address _escrowAddress)
        ERC1155(_admin, _escrowAddress)
    {
        //ERC1155()
        // admin = payable(_admin);
        creator[admin] = true;
        // escrowAddress = _escrowAddress;
        // EscrowInterface = Escrow(escrowAddress);
    }

    // modifier onlyAdmin() {
    //     require(msg.sender == admin, "Only admin");
    //     _;
    // }

    function approveCreators(address[] memory _creators) external onlyAdmin {
        for (uint256 i = 0; i < _creators.length; i++) {
            creator[_creators[i]] = true;
        }
    }

    function disableCreators(address[] memory _creators) external onlyAdmin {
        for (uint256 i = 0; i < _creators.length; i++) {
            creator[_creators[i]] = false;
        }
    }

    function TokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI[_tokenId];
    }

    // function setEscrowAddress(address _escrowAddress) external onlyAdmin {
    //     escrowAddress = _escrowAddress;
    //     EscrowInterface = Escrow(escrowAddress);
    // }

    function ownerOfToken(uint256 _tokenId)
        public
        view
        returns (
            address,
            uint256,
            address,
            uint256
        )
    {
        return (
            ownerOf[_tokenId].creator,
            ownerOf[_tokenId].percent1,
            ownerOf[_tokenId].coCreator,
            ownerOf[_tokenId].percent2
        );
    }

    function setMaxEditions(uint256 _number) external onlyAdmin {
        require(_number > 0, "Zero editions per NFT");
        maxEditionsPerNFT = _number;
    }

    function mintToken(
        uint256 _editions,
        string memory _tokenURI,
        address _creator,
        address _coCreator,
        uint256 _creatorPercent,
        uint256 _coCreatorPercent,
        Type _saleType,
        uint256 _timeline,
        uint256 _pricePerNFT,
        uint256 _adminPlatformFee
    ) external returns (bool) {
        require(_editions > 0, "Zero editions");
        require(_pricePerNFT > 0, "Zero price");
        require(_adminPlatformFee < 50, "Admin fee too high"); //Discuss
        require(creator[msg.sender], "Only approved users can mint");

        require(
            _saleType == Type.Instant || _saleType == Type.Auction,
            "Invalid saletype"
        );
        if (_saleType == Type.Instant) {
            require(_timeline == 0, "Invalid time for Buying");
        } else if (_saleType == Type.Auction && msg.sender != admin) {
            require(
                _timeline == 12 || _timeline == 24 || _timeline == 48,
                // _timeline > block.timestamp.add(5 minutes) &&
                //     _timeline <= block.timestamp.add(2 days),
                "Incorrect time"
            );
        }
        if (msg.sender != admin) {
            require(
                _editions <= maxEditionsPerNFT,
                "Editions greater than allowed"
            );
            require(msg.sender == _creator, "Invalid Parameters");
        }
        require(
            _creatorPercent.add(_coCreatorPercent) == 100,
            "Wrong percentages"
        );
        uint256 platFee;
        if (msg.sender == admin) platFee = _adminPlatformFee;

        _mint(escrowAddress, tokenId, _editions, "");
        tokenURI[tokenId] = _tokenURI;
        ownerOf[tokenId] = owner(
            _creator,
            _creatorPercent,
            _coCreator,
            _coCreatorPercent
        );
        EscrowInterface.placeOrder(
            _creator,
            tokenId,
            _editions,
            _pricePerNFT,
            uint256(_saleType),
            _timeline,
            platFee
        );
        tokenId++;
        return true;
    }

    function burn(
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == escrowAddress, "Only escrow");
        _burn(from, _tokenId, amount);
        return true;
    }
}