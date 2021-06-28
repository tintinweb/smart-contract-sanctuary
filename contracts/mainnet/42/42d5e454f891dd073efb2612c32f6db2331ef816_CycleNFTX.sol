/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: GPL-3.0

/**
Public good from https://twitter.com/0xfoobar

Cycle through NFTX pools until you find the ID you want

See https://github.com/NFTX-project/x-contracts-private/blob/4650f3cae4c2d776ca45effba65513c9e6ec4b6b/contracts/NFTX.sol

*/

pragma solidity ^0.8.0;


interface NFTXv7 {
    function requestMint(uint256 vaultId, uint256[] memory nftIds) external payable;

    // Burns a Meebit, gives you MEEBIT; see https://etherscan.io/tx/0x8d443e00c0a7b702b105cb1fbc4cafbd424a5cee756965007877a164203ee359
    function mint(uint256 vaultId, uint256[] memory nftIds, uint256 d2Amount) external payable;

    // Burns PUNK-BASIC, gives you a WPUNK; see https://etherscan.io/tx/0x7b30eabbcdad9a6827029ba6ffb8196fa1921f9960214b3ccc463b764b4a72ea
    function redeem(uint256 vaultId, uint256 amount) external;


}

interface xStore {
    function xTokenAddress(uint256 vaultId) external view returns (address);
    function nftAddress(uint256 vaultId) external view returns (address);
}

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 amount) external payable;
    function approve(address _spender, uint256 amount) external;
}

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function ownerOf(uint256 _tokenId) external view returns (address);
    function approve(address _spender, uint256 _tokenId) external;
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}


contract CycleNFTX is ERC721TokenReceiver {

    address owner;
    NFTXv7 nftx = NFTXv7(0xAf93fCce0548D3124A5fC3045adAf1ddE4e8Bf7e);
    xStore store = xStore(0xBe54738723cea167a76ad5421b50cAa49692E7B7);
    uint256 currentTokenId;
    uint256[] desiredIds;

    constructor() {
        // owner = _owner;
    }

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Not owner");
    //     _;
    // }

    /**
     * Precondition: have PUNK-BASIC tokens in your wallet and approve contract for transfer
     * This will revert with out-of-gas unless the proper token is found, so no need to return tokens to user
     * Uses 3.15M gas to do 10 iterations
     * Uses 332k gas to do 1 iteration
     */
    function cycle(uint256 vaultId, uint256[] memory _desiredIds, uint256 maxIterations, bool acceptAny) public {
        address xToken = store.xTokenAddress(vaultId); // PUNK-BASIC
        address nftAddress = store.nftAddress(vaultId); // WPUNKS
        uint256[] memory currentTokenIds = new uint256[](1);
        desiredIds = _desiredIds;
        IERC20(xToken).transferFrom(msg.sender, address(this), 1 ether);
        uint iterations = 0;
        while(true) {
            IERC20(xToken).approve(address(nftx), 1 ether);
            nftx.redeem(vaultId, 1);
            if(acceptAny || isDesired(currentTokenId)) {
                IERC721(nftAddress).transferFrom(address(this), msg.sender, currentTokenId);
                return;
            }
            iterations += 1;
            if(iterations >= maxIterations) {
                require(false, "Hit maximum iterations");
            }
            currentTokenIds[0] = currentTokenId;
            IERC721(nftAddress).approve(address(nftx), currentTokenId);
            nftx.mint(vaultId, currentTokenIds, 1);
        }
    }

    function isDesired(uint256 _tokenId) internal view returns (bool) {
        for(uint i = 0; i < desiredIds.length; i++) {
            if(_tokenId == desiredIds[i]) {
                return true;
            }
        }
        return false;
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) public override returns (bytes4) {
        currentTokenId = _tokenId;
        // TODO: hardcode this hash
        return 0x150b7a02; //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}