// contracts/XChain.sol
// SPDX-License-Identifier: GPL-3.0

//  * This is the ERC1155 for XChain.Tech 
//  * Owners NFTs are the NFT ID 0.
//  * Future needs will use IDs 1, 2, 3, and so on.
//  * More info at https://xchain.tech and via email at [email protected]
//  * To contact the XChain Tech Foundation: [email protected]

pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./IERC1155.sol";

contract XChain is ERC1155 {

    constructor() ERC1155("https://xchain.tech/NFT/{id}/XChain.json") {}

    string public name = "XChain Tech";

    mapping (address => uint) public addressLockedUntilTimestamp;
    mapping (address => bool) public addressUnlocked;
    mapping (uint256 => uint256) private _totalSupply;

    function contractURI() public pure returns (string memory) {
        return "https://xchain.tech/NFT/XChain.json";
    }

    function uri(uint256 _tokenId) override public pure returns(string memory) {
        return string(abi.encodePacked("https://xchain.tech/NFT/", uint2str(_tokenId), "/XChain.json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155) { 
        require(addressLockedUntilTimestamp[from] < block.timestamp || addressUnlocked[from], "XChain: Address timelocked, cannot transfer NFTs");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, "0x00");
        if (from == address(0)) {for (uint256 i = 0; i < ids.length; ++i) {_totalSupply[ids[i]] += amounts[i];}}
        if (to == address(0)) {for (uint256 i = 0; i < ids.length; ++i) {_totalSupply[ids[i]] -= amounts[i];}}
        data = data;
    }

    function unlockAddress(address operator) public {
        require(_msgSender() == 0x8b8E1624814975aD4D52BFFA7c38C05101675bB7, "XChain: Only the foundation can unlock an address.");
        addressUnlocked[operator] = true;
    }

    function mint(address to, uint256 id, uint256 amount, uint lockedUntilTimestamp) public virtual {
        require(_msgSender() == 0x8b8E1624814975aD4D52BFFA7c38C05101675bB7 || isApprovedForAll(0x8b8E1624814975aD4D52BFFA7c38C05101675bB7, _msgSender()), "XChain: Only approved accounts can mint new tokens.");
        addressLockedUntilTimestamp[to] = lockedUntilTimestamp;
        _mint(to, id, amount, "0x00");
    }

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return XChain.totalSupply(id) > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

}