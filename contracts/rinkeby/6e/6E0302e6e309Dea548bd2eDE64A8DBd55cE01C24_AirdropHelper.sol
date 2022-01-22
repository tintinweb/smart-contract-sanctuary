contract AirdropHelper {

    function airdropFrom(IERC721 erc721, uint[] calldata tokenIds, address[] calldata tos) external {
        require(tokenIds.length == tos.length, "ERR");
        for (uint i = 0; i < tos.length; i++) {
            erc721.transferFrom(msg.sender, tos[i], tokenIds[i]);
        }
    }

}

interface IERC721 {

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}