/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// contracts/GhostSoftwareCDROM.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

contract Ownable {
    address public owner;
    address private nextOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");
        nextOwner = nextOwner_;
    }

    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;
        owner = msg.sender;
        emit OwnershipTransferred(owner, msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }
}


contract Reentrancy {
    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;
    uint256 internal reentrancyStatus;

    modifier nonReentrant() {
        require(reentrancyStatus != REENTRANCY_ENTERED, "Reentrant call");
        reentrancyStatus = REENTRANCY_ENTERED;
        _;
        reentrancyStatus = REENTRANCY_NOT_ENTERED;
    }
}

contract ChadeauChristmas is IERC721, IERC165, IERC721Metadata, Ownable, Reentrancy {

    string public override name;
    string public override symbol;
    string public baseURI;
    string private _unrevealed;
    string public rootURI;
    uint256 public immutable allocation;
    uint256 public immutable quantity;
    uint256 public immutable price;
    address public immutable operator;
    uint256 private nextTokenId;
    uint256 private allocationsTransferred = 0;
    bool public revealed = false;
    mapping (uint256 => bool) internal _burned;
    mapping (uint256 => string) internal _tokenUris;

    event GiftClaimed(
        uint256 indexed tokenId,
        uint256 amountPaid,
        address buyer,
        address receiver
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );

    constructor(
        uint256 allocation_,
        uint256 quantity_,
        address owner_,
        address operator_
    ) Ownable(owner_) {
        name = "Chadeau Christmas";
        symbol = "GIFT";
        baseURI = "https://arweave.net/";
        _unrevealed = "_isL0YCWpP_Vh_v8SWlgsFyHi-v5Q4jVNZyzwmx-Tco";
        allocation = allocation_;
        nextTokenId = allocation_;
        quantity = quantity_;
        price = 0.05 ether;
        operator = operator_;
    }

    function purchase(address recipient)
        external
        payable
        returns (uint256 tokenId)
    {
        require(msg.value >= price, "Insufficient funds sent");
        tokenId = nextTokenId;
        nextTokenId++;
        require(tokenId < quantity, "This token is sold out");
        _mint(recipient, tokenId);
        emit GiftClaimed(tokenId, msg.value, msg.sender, recipient);
        return tokenId;
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == operator) {
            return _balances[owner_] + allocation - allocationsTransferred;
        }
        require(owner_ != address(0), "ERC721: balance query for the zero address");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {

        if (
            _owners[tokenId] == address(0) &&
            tokenId < allocation &&
            !_burned[tokenId]
        ) {
            return operator;
        }

        address _owner = _owners[tokenId];

        require(
            _owner != address(0),
            "ERC721: owner query for nonexistent token"
        );

        return _owner;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId <= quantity);
        string memory uri;
        if (!revealed) {
            uri = string(abi.encodePacked(baseURI, _unrevealed));
        } else {
            uri = string(abi.encodePacked(baseURI, rootURI, _toString(tokenId)));
        }
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Chadeau Christmas Gift #',
                                    _toString(tokenId),
                                    '","description": "From: Santa, To: You",',
                                    '"image": "',
                                        uri, '"}'
                                )
                            )
                        )
                    )
                )
            ));
    }

    function setTokenURI(uint index, string memory hash) public onlyOwner {
        _tokenUris[index] = hash;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, rootURI, "contract"));
    }

    function changeRootURI(string memory rootURI_) public onlyOwner {
        rootURI = rootURI_;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
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


    function _exists(uint256 tokenId) internal view returns (bool) {
        if (tokenId < allocation && !_burned[tokenId]) {
            return true;
        }

        return _owners[tokenId] != address(0);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);
        _approve(address(0), tokenId);
        if (_balances[owner_] > 0) {
            _balances[owner_] -= 1;
        }
        delete _owners[tokenId];
        _burned[tokenId] = true;
        emit Transfer(owner_, address(0), tokenId);
        if (tokenId < allocation) {}
    }

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address approver, bool approved)
        public
        virtual
        override
    {
        require(approver != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][approver] = approved;
        emit ApprovalForAll(msg.sender, approver, approved);
    }

    function isApprovedForAll(address owner, address operator_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator_];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

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

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(
            to != address(0),
            "ERC721: transfer to the zero address (use burn instead)"
        );

        _approve(address(0), tokenId);

        if (_balances[from] > 0) {
            _balances[from] -= 1;
        }

        _owners[tokenId] = to;

        if (from == operator && tokenId < allocation) {
            allocationsTransferred += 1;
            _balances[to] += 1;
        } else if (to == operator && tokenId < allocation) {
            allocationsTransferred -= 1;
        } else {
            _balances[to] += 1;
        }

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}