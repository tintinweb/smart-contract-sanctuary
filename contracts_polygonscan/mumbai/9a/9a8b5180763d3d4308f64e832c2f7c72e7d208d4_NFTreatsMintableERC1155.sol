// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ChildMintableERC1155.sol";

contract NFTreatsMintableERC1155 is ChildMintableERC1155  {
    mapping(uint => string) public locator;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    constructor() public ChildMintableERC1155("https://ipfs.io/ipfs/",0x49dab4Ed81a8CFec9816C2Bf885a3e034d8a207B) {}


    function uri(uint256 _id) public view override returns (string memory){

        return string(
            abi.encodePacked(locator[_id])
        );
    }

    function mapIdToLocator(uint _tokenId, string memory locale) internal {
        locator[_tokenId] = locale;
    }

    function unMapIdToLocator(uint _tokenId) internal {
        locator[_tokenId] = '';
    }

    // Creates `amount` tokens of token type `id`, and assigns them to `account`
    // The modifier `onlyMetaTxOrRole(DEFAULT_ADMIN_ROLE)` only allow when this function is called 
    // in {executeMetaTransaction} or the account that make call that have role `DEFAULT_ADMIN_ROLE`
    function mintToCaller(address account,
        uint256 amount,
        bytes memory data,
        string memory tokenURI)
    public onlyMetaTxOrRole(DEFAULT_ADMIN_ROLE) returns (uint256) {

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(account, id, amount, data);
        mapIdToLocator(id, tokenURI);

        return id;

    }

    // Destroys `amount` tokens of token type `id` from account with address `_msgSender()`
    // The `_msgSender()` is address of account that make call to {executeMetaTransaction}
    // The modifier `onlyMetaTx` only allow when this function is called in {executeMetaTransaction} 
    function burnToCaller(
        uint256 id,
        uint256 amount)
    public onlyMetaTx returns (uint256) {

        _burn(_msgSender(), id, amount);
        unMapIdToLocator(id);

        return id;

    }
}