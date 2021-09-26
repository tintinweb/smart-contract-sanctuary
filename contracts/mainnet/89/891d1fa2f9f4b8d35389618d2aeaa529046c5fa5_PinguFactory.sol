// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Pingu.sol";

contract PinguFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmYyxvjP46HR96AEmFLt6TEfJoCfia6VdNKtntWuF2vWRx/";

    /*
     * Enforce the existence of only 100 OpenSea creatures.
     */
    uint256 specialEditionCounter;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Chilly Bit Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "CHB";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return 102;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < 102; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));

        Pingu openSeaPingu = Pingu(nftAddress);

        if (_optionId == 0) {
            openSeaPingu.mintTo(_toAddress,_optionId);
        } else if (_optionId == 1) {
            for (
                uint256 i = 0;
                i < 4;
                i++
            ) {
                openSeaPingu.mintTo(_toAddress,_optionId);
            }
        } else if (_optionId > 1) {
            openSeaPingu.mintTo(_toAddress,_optionId);
            specialEditionCounter++;
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= 102)
        {
            return false;
        }

        Pingu openSeaPingu = Pingu(nftAddress);
        uint256 pinguSupply = openSeaPingu.totalSupply();


        uint256 numItemsAllocated = 0;
         if (_optionId == 0) {
            numItemsAllocated = 1;
        } else if (_optionId == 1) {
            numItemsAllocated = 4;
        }

        return (pinguSupply - specialEditionCounter) <= (900 - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId), ".json"));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}