/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity 0.6.5;

contract AlohaDataChild {
    address alohaNFT;

    event Data(address indexed from, bytes bytes_data);
    event DataDecoded(address indexed from, uint256 id, uint256 image, uint256 background);

    constructor() public {
    }

    function setData(uint256 tokenId) public {
        bytes memory bytes_data = abi.encode(tokenId, 2, 3);

        emit Data(msg.sender, bytes_data);

        (uint256 id, uint256 image, uint256 background) = abi.decode(bytes_data, (uint256, uint256, uint256));
        
        emit DataDecoded(msg.sender, id, image, background);
    }
}