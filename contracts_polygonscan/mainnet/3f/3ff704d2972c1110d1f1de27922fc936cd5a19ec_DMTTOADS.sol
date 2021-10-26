// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract DMTTOADS is Context, Ownable, ERC1155Burnable, ERC1155Pausable {
    string private _contractURI;

    string private _name;
    string private _symbol;


    uint256 public max = 30;
    uint256 private pieces = 30;
    uint256 public cost = 50 ether;
    mapping(uint256 => uint256) private _minted;

    bool public tokenURIFrozen = false;

    constructor(string memory name_, string memory symbol_, string memory uri) ERC1155(uri) {
        _name = name_;
        _symbol = symbol_;
        _pause();
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public payable {
        require(paused() == false, "Contract is paused");
        require(id >= 1 && id <= pieces, "ID is not allowed to be minted");
        require(msg.value >= cost * amount, "Not enough ether provided");
        require(max >= amount + _minted[id], "Exceeds max mint per ID allowed");
        _mint(to, id, amount, data);
        _minted[id] += amount;
    }

    function ownerMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        require(paused() == false, "Contract is paused");
        require(id >= 1 && id <= pieces, "ID is not allowed to be minted");
        require(max >= amount + _minted[id], "Exceeds max mint per ID allowed");
        _mint(to, id, amount, data);
        _minted[id] += amount;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(token).transfer(_msgSender(), amount);
        }
    }

    function setCost(uint256 price) public onlyOwner {
        cost = price;
    }

    function setContractURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _setURI(uri);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function minted(uint256 id) public view virtual returns (uint256) {
        return _minted[id];
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}