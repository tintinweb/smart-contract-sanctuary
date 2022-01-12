// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MintingPass is ERC1155, Ownable {
    struct MintingPassData {
        uint amount;
        uint minted;
        uint rate;
    }

    MintingPassData[] public mintingPasses;

    address payable public wallet;
    bool public isPaused = true;

    // Contract name
    string public name = "test";
    // Contract symbol
    string public symbol = "test";

    constructor(address payable _wallet, string memory _uri) ERC1155(_uri) {
        require(_wallet != address(0), "MintingPass::constructor: _wallet address is 0");

        wallet = _wallet;

        addMintingPass(300, 0.03 ether);
        addMintingPass(150, 0.06 ether);
    }

    function mint(uint256 passId, uint256 amount) public payable returns (bool) {
        require(!isPaused, "MintingPass::mint: contract is paused");
        require(passId < mintingPasses.length, "MintingPass::mint: mintingPassId does not exist");
        require(msg.value == mintingPasses[passId].rate * amount, "MintingPass::mint: wrong ether amount");

        mintingPasses[passId].minted += amount;
        require(mintingPasses[passId].minted <= mintingPasses[passId].amount, "MintingPass::mint: not enough supply");

        _mint(msg.sender, passId, amount, "");

        wallet.transfer(msg.value);

        return true;
    }

    function _setPause(bool pause) external onlyOwner returns (bool) {
        isPaused = pause;

        return true;
    }

    function _setNewURI(string memory _newUri) external onlyOwner returns (bool) {
        _setURI(_newUri);

        return true;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function _setWallet(address payable _wallet) external onlyOwner returns (bool) {
        wallet = _wallet;

        return true;
    }

    function _setMintingPassData(uint passId, uint amount, uint rate) external onlyOwner returns (bool) {
        mintingPasses[passId].amount = amount;
        mintingPasses[passId].rate = rate;

        return true;
    }

    // rate in wei
    function _addMintingPasses(uint[] calldata amounts, uint[] calldata rates) public onlyOwner returns (bool) {
        require(amounts.length == rates.length, 'MintingPass::addMintingPasses: amounts length must be equal rates length');

        for(uint i = 0; i < amounts.length; i++) {
            addMintingPass(amounts[i], rates[i]);
        }

        return true;
    }

    function addMintingPass(uint amount, uint rate) internal returns (bool) {
        MintingPassData memory pass = MintingPassData({amount: amount, minted: 0, rate: rate});
        mintingPasses.push(pass);

        return true;
    }

    function getAllMintingPasses() public view returns (MintingPassData[] memory) {
        return mintingPasses;
    }

    function getMintingPassesLength() public view returns (uint) {
        return mintingPasses.length;
    }
}