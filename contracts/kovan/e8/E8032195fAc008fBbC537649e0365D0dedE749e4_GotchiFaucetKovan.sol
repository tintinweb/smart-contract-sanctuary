/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity 0.8.11;

interface IAavegotchiFacet {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
    function balanceOf(address _owner) external view returns (uint256 balance_);
}

contract GotchiFaucetKovan {

    // Contract addresses
    address public diamond;

    // Interfaces to Aavegotchi contract - approval
    IAavegotchiFacet private immutable aavegotchiFacet;

    constructor(address _diamond) {
        diamond = _diamond; 
        aavegotchiFacet = IAavegotchiFacet(diamond); // is immutable
    }

    function getGotchi() public {
        require(numGotchisLeftInContract() > 0, "No gotchis left in the Faucet");
        uint32[] memory tokenIds = getAvailableGotchiInContract();
        aavegotchiFacet.safeTransferFrom(address(this), msg.sender, tokenIds[0]);
    }

    function getAvailableGotchiInContract() public view returns(uint32[] memory) {
        return aavegotchiFacet.tokenIdsOfOwner(address(this));
    }

    function numGotchisLeftInContract() public view returns(uint256) {
        return aavegotchiFacet.balanceOf(address(this));
    }

    function onERC721Received(
        address, /* _operator */
        address, /*  _from */
        uint256, /*  _tokenId */
        bytes calldata /* _data */
    ) external pure  returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}