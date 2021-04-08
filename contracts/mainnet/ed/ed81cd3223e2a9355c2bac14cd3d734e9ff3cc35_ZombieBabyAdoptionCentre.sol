/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface NFT {
    function mint(address to, uint id, uint amount, bytes memory data) external;
    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;
}

contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed from, address indexed to);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initOwned() internal {
        require(!initialised, "Already initialised");
        owner = msg.sender;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// BokkyPooBah's ZombieBabyAdoptionCentre
//
// Send 0 value or < fee tx to this contract to receive a single random NFT
// Send >= fee tx to this contract to receive a set of NFTs
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------
contract ZombieBabyAdoptionCentre is Owned {

    NFT public nft;
    uint public paused;
    uint public fee;
    uint[] _ids;

    event FeeUpdated(uint[] ids);
    event IdsUpdated(uint[] ids);
    event PausedToggled(bool paused);
    event RefundedETH(uint amount);

    constructor(NFT _nft, uint _fee, uint[] memory __ids) {
        initOwned();
        fee = _fee;
        nft = _nft;
        _setIds(__ids);
    }

    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function _setIds(uint[] memory __ids) internal {
        _ids = __ids;
        emit IdsUpdated(__ids);
    }

    function setIds(uint[] memory __ids) public onlyOwner {
        _setIds(__ids);
    }

    function ids() public view returns (uint[] memory __ids) {
        return _ids;
    }

    function togglePaused() public onlyOwner {
        paused = 1 - paused;
        emit PausedToggled(paused == 1);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        require(paused == 0, "Paused");

        // Mint a random NFT
        if (msg.value < fee) {
            uint randomIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % _ids.length;
            nft.mint(msg.sender, _ids[randomIndex], 1, "");

        // Mint set
        } else {
            uint[] memory amounts = new uint[](_ids.length);
            for (uint i = 0; i < _ids.length; i++) {
                amounts[i] = 1;
            }
            nft.mintBatch(msg.sender, _ids, amounts, "");
            uint refund = msg.value - fee;
            if (refund > 0) {
                payable(msg.sender).transfer(refund);
                emit RefundedETH(refund);
            }
        }
    }
}