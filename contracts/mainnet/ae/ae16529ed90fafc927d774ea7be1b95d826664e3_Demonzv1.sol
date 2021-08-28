// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract Demonzv1 is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_TOKENS = 10000;
    uint256 public MAX_MINTABLE_PER_TX = 20;
    uint256 public MAX_PER_WALLET = 50;

    uint256 public minting_price = 0.06 ether;
    string public beginning_uri = "https://blbstrgacct.blob.core.windows.net/metadata/";
    string public ending_uri = ".json";

    mapping (address => uint16) public burn_count;
    bool public minting_allowed = false;

    mapping (address => uint8) public presale_allocation;

    constructor() ERC721 ("CryptoDemonz", "DEMONZv1") {
        presale_allocation[0x02B06E44aEa658d9F113A22Cee32b924B45D5bb0] = 10;
        presale_allocation[0xb1776C152080228214c2E84e39A93311fF3c03C1] = 20;
        presale_allocation[0x0Edc2C64D952E75241590aC5Fb10077395F93DF6] = 30;
        presale_allocation[0x1de70e8fBBFB0Ca0c75234c499b5Db74BAE0D66B] = 8;
        presale_allocation[0x28a9CA0b1bF4bB2d04430A256B35B60DD9fCFc22] = 10;
        presale_allocation[0xFD861f7C8A59Ff456D6f5949c313FF02eB07B686] = 30;
        presale_allocation[0x8464da2C737DfE5B55c0D4BE69Fa7E84eB2249BE] = 20;
        presale_allocation[0x31be8e4756eA0Aa3660C973e882460873970c0da] = 20;
        presale_allocation[0xaC03FCc8fF62B3a3427ea2657CB4b78436C9Bc5F] = 3;
        presale_allocation[0x37b3fAe959F171767E34e33eAF7eE6e7Be2842C3] = 20;
        presale_allocation[0xe8300fBFE3F0E6182cb797A1f9B4e6BB65961aA8] = 5;
        presale_allocation[0x11483a4Fa80708ee902375259fA3B75f89177Fa7] = 6;
        presale_allocation[0xa1BbD8D39eD536DEa030A32F3F6C5916C845A800] = 20;
        presale_allocation[0xC0A564ae0BfBFB5c0d2027559669a785916387a6] = 1;
        presale_allocation[0x6f79ef162babd7DF4527832603185dA5F26b947a] = 1;
        presale_allocation[0xA011A2379E884826ec192bd7f46b2aFa6C356Dc1] = 5;
        presale_allocation[0x2d253a1e93DDf47d84150f2f34A08D507d416A62] = 5;
        presale_allocation[0xc04B7d464c724c8D4d5FE6067938cEDAb82afa12] = 10;
        presale_allocation[0x09242cf44047b58ff0Fbfe8428Ab39f2faAdfF7E] = 20;
        presale_allocation[0x75A08F634704c0060180C3a8E00F2b5991f2E5c9] = 20;
        presale_allocation[0x145c584F2F022997a9d0e5FcB4346042229525E1] = 3;
        presale_allocation[0x30965b30bbBD150d634Ca46D5c9b38B2fb9c2f53] = 10;
        presale_allocation[0xca1B8F95046506fdF2560880b2beB2950CC9aED6] = 20;
        presale_allocation[0xB9f41e10dF1e82Af748505A78bB127246Cea9860] = 20;
        presale_allocation[0x0A9Cb981760b88965BE3acA083cF3cA756EaFb77] = 30;
        presale_allocation[0x0eE0ee6C665EE946b2BF296f5f9219883Ad9DB29] = 20;
        presale_allocation[0x0416B4E5A120b61E6B459dd36DFE5589521AF870] = 10;
        presale_allocation[0x5967993F6315F01bc19561DF2b08e26e38Fb0d5e] = 20;
        presale_allocation[0x0c04187bB588Fe4a76C2060583575baBD5D99B3b] = 10;
        presale_allocation[0xe0C484C905da1488700270f8398419d8B84915B5] = 10;
        presale_allocation[0xF71EcE292584ac18730FD351F08FFaDe12398b82] = 20;
        presale_allocation[0xd2AEb39449b5E25258cceB24f5dd67d8110172D2] = 2;
        presale_allocation[0x93DaEDCa59f895d0c3F3978cd64d9CB981913C33] = 1;
        presale_allocation[0x44dc73292fB745d92EF1906dc362e03f2670Be70] = 6;
        presale_allocation[0xC3847b0324809af87bbc07E5a8E92a6fF8A7D202] = 6;
        presale_allocation[0x9408c666a65F2867A3ef3060766077462f84C717] = 20;
        presale_allocation[0x614621D47DCA95E365f152FEf71071F3B9370771] = 4;
        presale_allocation[0x4B424674eA391E5Ee53925DBAbD73027D06699A9] = 40;
        presale_allocation[0x19b927168996F0179FB1B57E8D27778e532f958A] = 15;
        presale_allocation[0xc04B7d464c724c8D4d5FE6067938cEDAb82afa12] = 10;
        presale_allocation[0x6978339e7549cE63952A625C5D5E8aE67c034f92] = 3;
        presale_allocation[0x70Cbc550D8187824EA1A6F94952C0Fa9B844f8fC] = 3;
        presale_allocation[0x5013C667440a7E6925A11389AdDc1B2a71552CaD] = 10;
        presale_allocation[0x5967993F6315F01bc19561DF2b08e26e38Fb0d5e] = 20;
        presale_allocation[0x8fA469EE658e4Dc604251D1D7C23ED71DAC5aB9D] = 10;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(beginning_uri, tokenId.toString(), ending_uri));
    }

    function preMint(uint256 _num_to_mint) external {
        require(totalSupply() + _num_to_mint <= MAX_TOKENS, "Not enough NFTs left to mint");
        require(presale_allocation[msg.sender] >= _num_to_mint, "Cannot premint that many tokens");

        for (uint256 i = 0; i < _num_to_mint; ++i) {
            _safeMint(msg.sender, totalSupply());
            --presale_allocation[msg.sender];
        }
    }

    function mintToken(uint256 _num_to_mint) external payable {
        require(minting_allowed, "Minting has not begun yet");
        require(msg.value == _num_to_mint * minting_price, "Incorrect amount of ETH sent");
        require(_num_to_mint <= MAX_MINTABLE_PER_TX, "Too many tokens queried for minting");
        require(totalSupply() + _num_to_mint <= MAX_TOKENS, "Not enough NFTs left to mint");
        require(balanceOf(msg.sender) + _num_to_mint <= MAX_PER_WALLET, "Exceeds wallet max allowed balance");

        for (uint256 i = 0; i < _num_to_mint; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function burnToken(uint256 _token_id) external {
        require(ownerOf(_token_id) == msg.sender, "Sender is not owner");
        _burn(_token_id);
        ++burn_count[msg.sender];
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function toggleMinting() external onlyOwner {
        minting_allowed = !minting_allowed;
    }

    function setMintingPrice(uint256 _new_minting_price) external onlyOwner {
        minting_price = _new_minting_price;
    }

    function mintForGiveaway(uint256 _num_to_mint) external onlyOwner {
        require(totalSupply() < 90, "Cannot mint anymore for giveaways");

        for (uint i = 0; i < _num_to_mint; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setBeginningURI(string memory _new_uri) external onlyOwner {
        beginning_uri = _new_uri;
    }

    function setEndingURI(string memory _new_uri) external onlyOwner {
        ending_uri = _new_uri;
    }

}