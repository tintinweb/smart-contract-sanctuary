// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract PyMon is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_TOKENS = 11111;
    uint256 public GIVEAWAY_AMOUNT = 15;
    uint256 public MAX_MINTABLE_PER_TX = 12;
    uint256 public PRICE_PER_TOKEN = 0.025 ether;

    string public beginning_uri = "https://pymonfiles.blob.core.windows.net/metadata/";
    string public ending_uri = ".json";

    bool public minting_allowed = false;

    address payable public main_owner = payable(0x9408c666a65F2867A3ef3060766077462f84C717);
    address payable public second_owner = payable(0x8614287f6f69548e5Dc1FcAD91504A4Fe9A7EAbc);
    address payable public third_owner = payable(0x2dF0ab8b36081d9bFEB27F7e73F8Cf04834b7d28);

    constructor() ERC721 ("PyMons", "PYMON") {
        // First 15 PyMons will be given away
        for (uint8 i = 0; i < GIVEAWAY_AMOUNT; ++i) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function calculateMintingPrice(uint256 _quantity) view public returns(uint256) {
        require(_quantity > 0, "Quantity must be greater than 0.");
        require(_quantity <= MAX_MINTABLE_PER_TX, "Too many tokens queried for minting.");

        return _quantity * PRICE_PER_TOKEN;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(beginning_uri, (tokenId + 1).toString(), ending_uri));
    }

    function mintToken(uint256 _num_to_mint) public payable {
        require(minting_allowed, "Minting has not begun yet!");
        require(msg.value >= calculateMintingPrice(_num_to_mint), "Did not send enough ETH to mint.");
        require(totalSupply() + _num_to_mint <= MAX_TOKENS, "Not enough NFTs left to mint.");

        for (uint8 quantity = 0; quantity < _num_to_mint; ++quantity) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function withdraw() public onlyOwner {
        main_owner.transfer(56 * address(this).balance / 100);
        second_owner.transfer(24 * address(this).balance / 44);
        third_owner.transfer(address(this).balance);
    }

    function toggleMinting() external onlyOwner {
        minting_allowed = !minting_allowed;
    }

    function setBeginningURI(string memory _new_uri) external onlyOwner {
        beginning_uri = _new_uri;
    }

    function setEndingURI(string memory _new_uri) external onlyOwner {
        ending_uri = _new_uri;
    }

    function setMainOwner(address _address) external onlyOwner {
        main_owner = payable(_address);
    }

    function setSecondOwner(address _address) external onlyOwner {
        second_owner = payable(_address);
    }

    function setThirdOwner(address _address) external onlyOwner {
        third_owner = payable(_address);
    }
}