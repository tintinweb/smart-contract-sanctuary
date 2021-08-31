/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

/**
 * OpenZepplin contracts contained within are licensed under an MIT License.
 * 
 * The MIT License (MIT)
 * 
 * Copyright (c) 2016-2021 zOS Global Limited
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * SPDX-License-Identifier: MIT
 */

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/ReentrancyGuard.sol
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/introspection/IERC165.sol
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/introspection/ERC165.sol
pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721.sol
pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Context.sol
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Address.sol
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/extensions/IERC721Metadata.sol
pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/token/ERC721/IERC721Receiver.sol
pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name = "Igor - EtherCats.io";

    // Token symbol
    string private _symbol =  "IGOR";
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "ipfs://QmY2RtPNfCYyJJW8CtbNWLs3GGSaUus5vG38g4kRZ5Ci7k";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not owned");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    
    function snipe(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

//Igor's Manifest is an EtherCats production. Igor was illustrated and animated by Nadia Khuzina. The principle concept was developed by Woody Deck. The contract was written by Woody Deck and Edvard Gzraryan. Special thanks to Vitalik Buterin for his inspiration in challenging economic dogma.
contract IgorsManifest is ERC721, ReentrancyGuard {
    address public contractOwner;
    uint256 public snipeStep;
    uint256 public snipePrice;
    bool public snipeable;
    uint256 public blockTimerStartTime;
    string igorsHash;
    
    event Snipe(address indexed owner, uint256 price, uint256 step, uint256 blockTimestamp);
    event ExtendLeasehold(uint256 blockTimestamp);
    event DecreaseSnipeStep(uint256 price, uint256 step, uint256 blockTimestamp);

    constructor() {
        contractOwner = msg.sender;
        _safeMint(msg.sender, 1, ""); //Igor is minted as token ID number 1, and the contractOwner owns it initially.
        snipeStep = 0;
        snipePrice = snipePriceTable(snipeStep);
        snipeable = true;
        blockTimerStartTime = block.timestamp;
        igorsHash = "QmSGsx5Cs1zLxmMX8YjvGx1x1vYn47jzuFKy13yhM4S61q";
    }

    //This is a lookup table to determine the cost to snipe Igor from someone.
    function snipePriceTable(uint256 _snipeStep) internal pure returns(uint256 _snipePrice) {
        if (_snipeStep == 0) return 0.1 * 10 ** 18;
        else if (_snipeStep == 1) return 0.15 * 10 ** 18;
        else if (_snipeStep == 2) return 0.21 * 10 ** 18;
        else if (_snipeStep == 3) return 0.28 * 10 ** 18;
        else if (_snipeStep == 4) return 0.36 * 10 ** 18;
        else if (_snipeStep == 5) return 0.45 * 10 ** 18;
        else if (_snipeStep == 6) return 0.55 * 10 ** 18;
        else if (_snipeStep == 7) return 0.66 * 10 ** 18;
        else if (_snipeStep == 8) return 0.78 * 10 ** 18;
        else if (_snipeStep == 9) return 1 * 10 ** 18;
        else if (_snipeStep == 10) return 1.5 * 10 ** 18;
        else if (_snipeStep == 11) return 2.2 * 10 ** 18;
        else if (_snipeStep == 12) return 3 * 10 ** 18;
        else if (_snipeStep == 13) return 4 * 10 ** 18;
        else if (_snipeStep == 14) return 6 * 10 ** 18;
        else if (_snipeStep == 15) return 8.5 * 10 ** 18;
        else if (_snipeStep == 16) return 12 * 10 ** 18;
        else if (_snipeStep == 17) return 17 * 10 ** 18;
        else if (_snipeStep == 18) return 25 * 10 ** 18;
        else if (_snipeStep == 19) return 35 * 10 ** 18;
        else if (_snipeStep == 20) return 47 * 10 ** 18;
        else if (_snipeStep == 21) return 60 * 10 ** 18;
        else if (_snipeStep == 22) return 75 * 10 ** 18;
        else if (_snipeStep == 23) return 92 * 10 ** 18;
        else if (_snipeStep == 24) return 110 * 10 ** 18;
        else if (_snipeStep == 25) return 130 * 10 ** 18;
        else if (_snipeStep == 26) return 160 * 10 ** 18;
        else if (_snipeStep == 27) return 200 * 10 ** 18;
        else if (_snipeStep == 28) return 250 * 10 ** 18;
        else if (_snipeStep == 29) return 310 * 10 ** 18;
        else if (_snipeStep == 30) return 380 * 10 ** 18;
        else if (_snipeStep == 31) return 460 * 10 ** 18;
        else if (_snipeStep == 32) return 550 * 10 ** 18;
        else if (_snipeStep == 33) return 650 * 10 ** 18;
        else if (_snipeStep == 34) return 760 * 10 ** 18;
    }

    modifier onlyIgorOwner() {
        require(msg.sender == ownerOf(1), "Sender is not the owner of Igor.");
        _;
    }

    function snipeIgor() external payable nonReentrant {
        require(msg.sender != ownerOf(1), "You cannot snipe Igor from the address that already owns him.");
        require(msg.value == snipePrice, "The amount sent did not match the current snipePrice.");
        require(snipeable == true, "Sniping is permanently disabled. Igor is owned as a freehold now.");    
        address tokenOwner = ownerOf(1);
        //If the snipeStep is 0, then all proceeds go to the owner.
        if (snipeStep == 0) {
            snipeStep++;
            snipePrice = snipePriceTable(snipeStep);
            snipe(tokenOwner, msg.sender, 1);
            (bool sent,) = payable(tokenOwner).call{ value: msg.value }("");
            require(sent, "Failed to send Ether.");
        } else {
            //Else is all cases after Step 0.
             uint256 etherCatsRoyalty = (msg.value - snipePriceTable(snipeStep - 1)) * 25 / 100;
             uint256 payment = msg.value - etherCatsRoyalty;
            if (snipeStep < 34) {
                snipeStep++;
                snipePrice = snipePriceTable(snipeStep);
            }
            //Automatically stop sniping if Igor is sniped on Step 33.
            if (snipeStep == 34) {
                snipeable = false;
            }
            snipe(tokenOwner, msg.sender, 1);
            (bool paymentSent,) = payable(tokenOwner).call{ value: payment }("");
            require(paymentSent, "Failed to send Ether.");
            
            (bool royaltySent,) = payable(contractOwner).call{ value: etherCatsRoyalty }("");
            require(royaltySent, "Failed to send Ether.");
        }
        
        blockTimerStartTime = block.timestamp;
        emit Snipe(msg.sender, snipePrice, snipeStep, blockTimerStartTime);
    }

    //This option disables sniping permanently. It will behave like a normal ERC721 after this function is triggered. It can only be called by Igor's owner. 
    function permanentlyStopSniping() external payable onlyIgorOwner {
        require(snipeStep <= 20, "Igor can only be bought out on snipe steps before Step 21.");
        require(msg.value == 141 * 10 ** 18, "The amount sent did not match the freehold option amount.");
        require(snipeable == true, "Cannot disable sniping twice. Igor is already not snipeable.");
        snipeable = false;
        (bool sent,) = payable(contractOwner).call{ value: msg.value }("");
        require(sent, "Failed to send Ether.");
    }
    
    //To prevent people from reducing the snipe step, you must pay 1/1000th (0.1%) tax to the creator every two weeks. Activating this function early or multiple times does not result in time accumulating. It will always reset the countdown clock back to 1209600 seconds (two weeks).
    function extendLeasehold() external payable onlyIgorOwner {
        require(snipeStep >= 1, "You cannot extend the leasehold timer when it is step zero.");
        require(msg.value == snipePriceTable(snipeStep-1) / 1000, "The price to extend is 1/1000th of the current value, or the snipe step minus 1");
        require(snipeable == true, "Cannot extend. Igor is not snipeable anymore, sorry.");
        blockTimerStartTime = block.timestamp;
        (bool sent,) = payable(contractOwner).call{ value: msg.value }("");
        require(sent, "Failed to send Ether.");
        
        emit ExtendLeasehold(blockTimerStartTime);
    }

    //If the owner after 1209600 seconds (two weeks) has not paid the extension tax, then anyone can reduce the snipeStep by 1.
    function decreaseSnipeStep() external {
        require(block.timestamp - blockTimerStartTime > 1209600, "You cannot reduce the snipe step until after the lease is up.");
        require(snipeStep >= 1, "You cannot reduce the snipe step when it is at zero.");
        require(snipeStep < 34, "You cannot reduce the snipe step once it reaches step 34.");
        require(snipeable == true, "Igor is not snipeable anymore, sorry.");
        snipeStep--;
        snipePrice = snipePriceTable(snipeStep);
        blockTimerStartTime = block.timestamp;
        
        emit DecreaseSnipeStep(snipePrice, snipeStep, blockTimerStartTime);
    }
    
    //This function is for site owners to vet that Igor is only shown by the Ethereum address that owns him. This is conceptual, and only facilitates the possibility of restricting PFP NFTs from being displayed by accounts that do not own the NFT. It is up to a site to implement such a process on its own. It is not mandated by the terms of this contract. Reputable sites concerned about security will never store or even ask you to create a password. Reputable sites will require Web3 authentication for logins. Adding PFP avatar restrictions is trivial after adopting Web3 for authentication.
    function pfpOwner() external view returns (address igorsOwner, string memory igorsIPFSHash){
        return (ownerOf(1), igorsHash);
    }

    //There's only one Igor. Some frontends may look for this optional ERC721 implementation.
    function totalSupply() public pure returns (uint256) {
        return 1;
    }
}