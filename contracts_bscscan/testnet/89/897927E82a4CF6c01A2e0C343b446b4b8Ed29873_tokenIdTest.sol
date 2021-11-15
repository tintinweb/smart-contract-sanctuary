pragma solidity ^0.6.0;
import "./ItokenId.sol";

contract tokenIdTest {
    address private tokenId;
    constructor (address _tokenId) public {
        tokenId = _tokenId;
    }

    function usetokenId() external returns (uint256){
        return ItokenId(tokenId).getTokenId();
    }
}

pragma solidity ^0.6.0;

interface ItokenId{
    function getTokenId() external returns (uint256);
}

