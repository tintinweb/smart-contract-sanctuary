// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";

import "./AbstractERC1155Factory.sol";

/*
 * @title ERC1155 token for Pixelvault planets
 *
 * @author Niftydude
 */
contract Planets is AbstractERC1155Factory {
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    mapping(uint256 => mapping(address => uint256)) public passBalanceOf;
    mapping(uint256 => MintPass) public mintPasses;

    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );
    event Purchased(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    struct MintPass {
        uint256 mintPrice;
        uint256 maxSupply;
        uint256 maxPurchaseTx;
        uint256 purchased;
        string ipfsMetadata;
    }

    constructor(
        string memory _name,
        string memory _symbol

    ) ERC1155("ipfs://") {
        name_ = _name;
        symbol_ = _symbol;
    }

    function addMintPass(
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _maxPurchaseTx,
        string memory _ipfsMetadata
    ) public onlyOwner {
        MintPass storage p = mintPasses[counter.current()];
        p.mintPrice = _mintPrice;
        p.maxSupply = _maxSupply;
        p.maxPurchaseTx = _maxPurchaseTx;
        p.ipfsMetadata = _ipfsMetadata;

        counter.increment();
    }

    function editPass(
        uint256 _mintPrice,
        uint256 _maxPurchaseTx,
        uint256 _planetIndex
    ) external onlyOwner {
        require(exists(_planetIndex), "EditPlanet: planet does not exist");

        mintPasses[_planetIndex].mintPrice = _mintPrice;
        mintPasses[_planetIndex].maxPurchaseTx = _maxPurchaseTx;
    }

    function mint(
        uint256 passID,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(exists(passID), "Mint: planet does not exist");
        require(
            totalSupply(passID) + amount <= mintPasses[passID].maxSupply,
            "Mint: Max supply reached"
        );

        _mint(to, passID, amount, "");
    }

    function purchase(uint256 planetID, uint256 amount) external payable {
        require(
            amount <= mintPasses[planetID].maxPurchaseTx,
            "Purchase: Max purchase per tx exceeded"
        );
        require(
            totalSupply(planetID) + amount <= mintPasses[planetID].maxSupply,
            "Purchase: Max total supply reached"
        );
        require(
            msg.value == amount * mintPasses[planetID].mintPrice,
            "Purchase: Incorrect payment"
        );

        mintPasses[planetID].purchased += amount;

        _mint(msg.sender, planetID, amount, "");

        emit Purchased(planetID, msg.sender, amount);
    }

 

    /**
     * @notice return total supply for all existing planets
     */
    function totalSupplyAll() external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](counter.current());

        for (uint256 i; i < counter.current(); i++) {
            result[i] = totalSupply(i);
        }

        return result;
    }

    /**
     * @notice indicates weither any token exist with a given id, or not
     */
    function exists(uint256 id) public view override returns (bool) {
        return mintPasses[id].maxSupply > 0;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the planet id to return metadata for
     */

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(mintPasses[_id].ipfsMetadata);
    }
}