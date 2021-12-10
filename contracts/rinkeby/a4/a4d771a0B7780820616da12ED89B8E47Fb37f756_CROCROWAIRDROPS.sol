// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract CROCROWAIRDROPS is Context, Ownable, ERC1155Burnable{

    string private _name;
    string private _symbol;

    bool public tokenURIFrozen = false;

    constructor(string memory name_, string memory symbol_, string memory uri) ERC1155(uri) {
        _name = name_;
        _symbol = symbol_;
    }

    function airdrop(
        address[] memory accounts,
        uint256 id,
        bytes memory data
    ) public onlyOwner {
        uint256 count = accounts.length;
        for (uint256 i = 0; i < count; i++){
            _mint(accounts[i], id, 1, data);
        }
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            payable(_msgSender()).transfer(amount);
        } else {
            IERC20(token).transfer(_msgSender(), amount);
        }
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _setURI(uri);
    }


    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
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
    ) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}