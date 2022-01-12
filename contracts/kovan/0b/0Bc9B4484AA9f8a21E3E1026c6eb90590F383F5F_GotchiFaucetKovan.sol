/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity 0.8.11;

interface IAavegotchiFacet {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);
    function balanceOf(address _owner) external view returns (uint256 balance_);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds, bytes calldata _data) external;
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
    
    function sendMyGotchisToContract(uint256 _amount) public {
        uint32[] memory tempTokenIds = aavegotchiFacet.tokenIdsOfOwner(msg.sender);
        uint256[] memory tokenIds = conversionArray32to256(tempTokenIds, _amount);
        sendBatch(tokenIds);
    }

    function conversionArray32to256(uint32[] memory _array32, uint256 _amount) internal pure returns(uint256[] memory) {
        // uint256[] memory array256;
        uint256 length = _amount;
        if(length > _array32.length) length = _array32.length;
        if(length == 0) length = _array32.length;
        uint256[] memory array256 = new uint256[](length);
        for (uint i = 0 ; i < length ; i++ ) {
            array256[i] = uint256(_array32[i]);
        }
        return array256;
    }

    function sendBatch(uint256[] memory _tokenIds) internal {
        for(uint i = 0; i < _tokenIds.length; i++) {
            aavegotchiFacet.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }
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