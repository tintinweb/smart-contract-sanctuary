/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File lib/utils/ERC165/interfaces/IERC165.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {

    function supportsInterface(
        bytes4 interfaceId_
    ) external view returns (bool);

}


// File lib/utils/ERC165/ERC165.sol

pragma solidity ^0.8.0;

// [INTERFACES]
contract ERC165 is IERC165 {

    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return interfaceId_ == type(IERC165).interfaceId;
    }

}


// File lib/tokens/ERC721/interfaces/IERC721.sol

pragma solidity ^0.8.0;

interface IERC721 {

    function balanceOf(address owner_) external view returns (uint256); //

    function ownerOf(uint256 tokenId_) external view returns (address); //

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) external;

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    function approve(address to_, uint256 tokenId_) external;

    function setApprovalForAll(address operator_, bool approved_) external;

    function getApproved(uint256 tokenId_) external view returns (address);

    function isApprovedForAll(address owner_, address operator_) external view returns (bool);

    event Transfer(
        address indexed from_,
        address indexed to_,
        uint256 indexed tokenId_
    );

    event Approval(
        address indexed owner_,
        address indexed approved_,
        uint256 indexed tokenId_
    );

    event ApprovalForAll(
        address indexed owner_,
        address indexed operator_,
        bool indexed approved_
    );

}


// File lib/tokens/ERC721/interfaces/IERC721Receiver.sol

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator_,
        address from_,
        uint tokenId_,
        bytes calldata data
    ) external returns (bytes4);

}


// File lib/utils/Address.sol

pragma solidity ^0.8.0;
library Address {
function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File lib/tokens/ERC721/ERC721.sol

pragma solidity ^0.8.0;

// [CONTRACTS]
// [INTERFACES]
// [LIBRARIES]
contract ERC721 is ERC165, IERC721 {

    using Address for address;

    // Mapping  :   (uint256 tokenId) to (address owner)
    mapping(uint256 => address) internal _owners;
    // Mapping  :   (address owner) to (uint256 tokenId)
    mapping(address => uint256) internal _balances;
    // Mapping  :   (uint256 tokenId) to (address approvedAddress)
    mapping(uint256 => address) internal _tokenApprovals;
    // Mapping  :   (address owner) to (mapping(address operator) to (bool approved))
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // [CONSTRUCTOR]
    constructor () {}

    // [EXTERNAL FUNCTIONS]

    // Origin=[IERC721]
    // Takes    :   [ the balance owners address as (address owner_) ]
    // Returns  :   [ the balance of {owner_} as (uint256) ]
    function balanceOf(address owner_) public view virtual override returns (uint256)  {
        require(owner_ != address(0), "ERC721: balance query for the zero address");
        return _balances[owner_];
    }

    // Origin=[IERC721]
    // Takes    :   [ queried token ID as (uint256 tokenId_) ]
    // Returns  :   [ the owner of {tokenId_} as (address owner) ]
    function ownerOf(uint256 tokenId_) public view virtual override returns (address) {
        address owner = _owners[tokenId_];
        require(owner != address(0), "ERC721: owner query for nonexistant token");
        return owner;
    }

    // Origin=[IERC721]
    // Takes    :   [ the address of the owner of the token as (address from_) ]
    //          :   [ the address of the reciever of the token as (address to_) ]
    //          :   [ the ID of the token being transfered as (tokenId_) ]
    //          :   [ additional data without a specific format as (bytes memory data_) ]
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    // Origin=[IERC721]
    // Takes    :   [ the address of the owner of the token as (address from_) ]
    //          :   [ the address of the reciever of the token as (address to_) ]
    //          :   [ the ID of the token being transfered as (tokenId_) ]
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // Origin=[IERC721]
    // Takes    :   [ the address of the owner of the token as (address from_) ]
    //          :   [ the address of the reciever of the token as (address to_) ]
    //          :   [ the ID of the token being transfered as (tokenId_) ]
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
        _transfer(from_, to_, tokenId_);
    }

    // Origin=[IERC721]
    // Takes    :   [ the address to be approved as (address to_) ]
    //              [ the tokenId as (uint256 tokenId_) ]
    function approve(address to_, uint256 tokenId_) external virtual override  {
        address owner = ERC721.ownerOf(tokenId_);
        require(to_ != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to_, tokenId_);
    }

    // Origin=[IERC721]
    // Takes    :   [ the operator address to approve by msg.sender as (address operator_) ]
    //              [ the approved state for {operator_} as (bool approved_)]
    // Emits    :   [ ApprovalForAll(owner_, operator_, approved_) ]
    function setApprovalForAll(address operator_, bool approved_) external virtual override {
        require(operator_ != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    // Origin=[IERC721]
    // Takes    :   [ the queried tokens ID as (tokenId_) ]
    // Returns  :   [ the address the token is approved to as (address approvedAddress) ]
    function getApproved(uint256 tokenId_) public virtual view override returns (address) {
        require(_exists(tokenId_), "ERC721: approved query for nonexistant token");
        return _tokenApprovals[tokenId_];
    }

    // Origin=[IERC721]
    // Takes    :   [ the owner as (address owner_) ]
    //              [ the operator as (address operator_) ]
    // Returns  :   [ if the {operator_} is approved by {owner_} ]
    function isApprovedForAll(address owner_, address operator_) public virtual view override returns (bool) {
        return _operatorApprovals[owner_][operator_];
    }

    // Origin=[IERC165]
    // Takes    :   [ the interfaceId as (bytes4 interfaceId_) ]
    // Returns  :   [ if the interface is supported as (bool) ]
    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId_ == type(IERC721).interfaceId ||
            // interfaceId_ == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    // [INTERNAL FUNCTIONS]

    // Takes    :   [ the address of the attempting spender as (address spender_) ]
    //          :   [ the token ID that {spender_} is attempting to spend as (uint256 tokenId_)]
    // Returns  :   [ if the {spender_} is allowed to spend the token with ID {tokenId_} ]
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId_);
        return (spender_ == owner || spender_ == getApproved(tokenId_) || isApprovedForAll(owner, spender_));
    }

    // Takes    :   [ the owners address as (address from_) ]
    //              [ the receivers address as (address to_) ]
    //              [ the ID of the token being transfered ]
    // Emits    :   [ Transfer(from_, to_, tokenId_) ]
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(ERC721.ownerOf(tokenId_) == from_, "ERC721: transfer of token that is not own");
        require(to_ != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId_);
        _balances[from_]    -= 1;
        _balances[to_]      += 1;
        _owners[tokenId_]   = to_;
        emit Transfer(from_, to_, tokenId_);
    }

    // Takes    :   [ the address of the owner of the token as (address from_) ]
    //          :   [ the address of the reciever of the token as (address to_) ]
    //          :   [ the ID of the token being transfered as (tokenId_) ]
    //          :   [ additional data without a specific format as (bytes memory data_) ]
    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transfer(from_, to_, tokenId_);
        require(_checkOnERC721Received(from_, to_, tokenId_, data_), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // Takes    :   [ the address being approved for the token as (address approved_) ]
    //              [ the tokens ID as (uint256 tokenId_) ]
    // Emits    :   [ Approval(owner_, approved_, tokenId_) ]
    function _approve(address approved_, uint256 tokenId_) internal virtual {
        _tokenApprovals[tokenId_] = approved_;
        emit Approval(ERC721.ownerOf(tokenId_), approved_, tokenId_);
    }

    // Takes    :   [ the token ID being checked as (uint256 tokenId_) ]
    // Returns  :   [ if the token exists with ID {tokenId_} as (bool) ]
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _owners[tokenId_] != address(0);
    }

    // Takes    :   [ the previous owner of the token as (address from_) ]
    //          :   [ the address receiving the tokens as (address to_) ]
    //          :   [ the tokens ID as (uint256 tokenId_) ]
    //          :   [ additional data without a specific format as (bytes memory data_) ]
    // Returns  :   [ if {to_} implements the ERC721Receiver contract as (bool) ]
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal returns (bool) {
        if (to_.isContract()) {
            try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 retval) {
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


// File lib/tokens/ERC721/extensions/ERC721Mintable.sol

pragma solidity ^0.8.0;

// [CONTRACTS]
abstract contract ERC721Mintable is ERC721 {

    // [EXTERNAL FUNCTIONS]
    //TODO: WIP
    function mint() external payable returns (bool) {

    }

    // [INTERNAL FUNCTIONS]

    //TODO: WIP
    function _safeMint(address to_, uint256 tokenId_) internal virtual {
        _safeMint(to_, tokenId_, "");
    }

    //TODO: WIP
    function _safeMint(
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _mint(to_, tokenId_);
        require(
            _checkOnERC721Received(address(0), to_, tokenId_, data_),
            "ERC721Mintable: transfert to non ERC721Receiver implementer"
        );
    }

    //TODO: WIP
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0), "ERC721Mintable: mint to zero address");
        require(!_exists(tokenId_), "ERC721Mintable: token already minted");
        _balances[to_] += 1;
        _owners[tokenId_] = to_;
        emit Transfer(address(0), to_, tokenId_);
    }

}


// File contracts/TestContract.sol

pragma solidity ^0.8.0;

// [CONTRACTS]
contract TestContract is ERC721, ERC721Mintable {

    constructor() ERC721() {
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
        _safeMint(msg.sender, 2);
    }


}