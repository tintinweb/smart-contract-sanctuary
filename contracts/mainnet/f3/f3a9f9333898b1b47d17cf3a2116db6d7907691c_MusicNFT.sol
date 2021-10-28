// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC1155.sol";
import "./Ownable.sol";

contract MusicNFT is ERC1155, Ownable {
    using StringUtils for uint256;

    string private baseURI;

    constructor(string memory baseURI_, uint256[] memory ids_, uint256[] memory amounts_) ERC1155(baseURI_){
        baseURI = baseURI_;

        require(ids_.length == amounts_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            _mint(_msgSender(), ids_[i], amounts_[i], bytes("0x0"));
        }
    }

    function name() external pure returns (string memory) {
        return "Mayao NFT";
    }

    function symbol() external pure returns (string memory) {
        return "MYN";
    }

    // transfer on demand
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        uint256 balance = balanceOf(from, id);
        // mint when not enough and from is owner
        if (balance < amount && from == owner()) {
            _mint(from, id, amount - balance, data);
        }
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _amount, bytes memory _data) public onlyOwner {
        require(_to.length == _amount.length);
        //        if (allTokensIndex[_id] == 0) {
        //            // not exist
        //            allTokensIndex[_id] = allTokens.length + 1;
        //            allTokens.push(_id);
        //            emit URI(tokenURI(_id), _id);
        //        }

        for (uint256 i = 0; i < _to.length; ++i) {
            address to = _to[i];
            uint256 amount = _amount[i];

            _mint(to, _id, amount, _data);
        }
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toHexString(32), ".json"));
    }

    // set baseURI
    function setURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    // get baseURI
    function getURI() view public returns (string memory){
        return baseURI;
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        super._burn(account, id, amount);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        super._burnBatch(account, ids, amounts);
    }

}

library StringUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        //        buffer[0] = "0";
        //        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}