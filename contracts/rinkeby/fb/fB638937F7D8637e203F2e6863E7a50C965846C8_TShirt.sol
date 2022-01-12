// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './TShirtRenderer.sol';
import './Base64.sol';

contract TShirt is ERC721, ERC721Enumerable, Pausable, Ownable, ITShirtRenderer {
  using Address for address payable;
  using Counters for Counters.Counter;

  address public rendererAddress;

  Counters.Counter private _tokenIdCounter;
  uint256 public constant MAX_SUPPLY = 999;

  // tokenId => minted Options
  mapping(uint256 => Options) private tokens;

  constructor() ERC721('T-Shirt Exchange', 'TSHIRT') {}

  function setRendererAddress(address to) public {
    rendererAddress = to;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function getCost(uint256 design) public view override returns (uint256) {
    return ITShirtRenderer(rendererAddress).getCost(design);
  }

  function render(uint256 tokenId, Options memory options) public view override returns (string memory) {
    return ITShirtRenderer(rendererAddress).render(tokenId, options);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'id');
    return render(tokenId, tokens[tokenId]);
  }

  function withdraw(uint256 amount, address to) external onlyOwner {
    require(amount > 0 && amount <= address(this).balance, 'oob');
    payable(to).sendValue(amount);
  }

  function purchase(Options memory options) external payable {
    // supply check
    require(_tokenIdCounter.current() <= MAX_SUPPLY, 'max');

    // validate design
    require(options.background > 0 && options.outline > 0 && options.fill > 0, 'color');
    require(options.background != options.outline, 'mono');

    // price check
    require(msg.value >= getCost(options.design), 'cost');

    // save options and increment tokenId
    _tokenIdCounter.increment();
    tokens[_tokenIdCounter.current()] = options;

    // mint token to sender
    _safeMint(_msgSender(), _tokenIdCounter.current());
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';
import './Base64.sol';

interface ITShirtRenderer {
  struct Options {
    uint256 design;
    uint256 background;
    uint256 outline;
    uint256 fill;
    uint256 color1;
    uint256 color2;
    uint256 color3;
    uint256 color4;
    uint256 color5;
  }

  function getCost(uint256 design) external view returns (uint256);

  function render(uint256 tokenId, Options memory options) external view returns (string memory);
}

contract TShirtRenderer is ITShirtRenderer {
  // private string-building constants
  string private constant PATH_PREFIX = '<path fill-rule="evenodd" clip-rule="evenodd" class="';
  string private constant COLOR_PREFIX = ',{"trait_type":"Color","value":"';

  // matches length of designs array
  uint256 public constant DESIGNS_MAX = 75;

  // cost tiers
  uint256 public constant COST_BASIC = 0.1234 ether;
  uint256 public constant COST_FANCY = 0.345 ether;
  uint256 public constant COST_WHALE = 1 ether;

  // split every 6th char to get array. size = length / 6
  string public constant COLORS =
    '------F1F5F9E2E8F0CBD5E194A3B864748B4755693341551E293BF5F5F4E7E5E4D6D3D1A8A29E78716C57534E44403C292524FEE2E2FECACAFCA5A5F87171EF4444DC2626B91C1C991B1BFFEDD5FED7AAFDBA74FB923CF97316EA580CC2410C9A3412FEF3C7FDE68AFCD34DFBBF24F59E0BD97706B4530992400EFEF9C3FEF08AFDE047FACC15EAB308CA8A04A16207854D0EECFCCBD9F99DBEF264A3E63584CC1665A30D4D7C0F3F6212DCFCE7BBF7D086EFAC4ADE8022C55E16A34A15803D166534D1FAE5A7F3D06EE7B734D39910B981059669047857065F46CCFBF199F6E45EEAD42DD4BF14B8A60D94880F766E115E59CFFAFEA5F3FC67E8F922D3EE06B6D40891B20E7490155E75E0F2FEBAE6FD7DD3FC38BDF80EA5E90284C70369A1075985DBEAFEBFDBFE93C5FD60A5FA3B82F62563EB1D4ED81E40AFE0E7FFC7D2FEA5B4FC818CF86366F14F46E54338CA3730A3EDE9FEDDD6FEC4B5FDA78BFA8B5CF67C3AED6D28D95B21B6F3E8FFE9D5FFD8B4FEC084FCA855F79333EA7E22CE6B21A8FAE8FFF5D0FEF0ABFCE879F9D946EFC026D3A21CAF86198FFCE7F3FBCFE8F9A8D4F472B6EC4899DB2777BE185D9D174DFFE4E6FECDD3FDA4AFFB7185F43F5EE11D48BE123C9F1239';

  string[] public patterns = [
    '', // 0: blank
    '11 8h1v17h-1V8zm-1 1H9v4h1V9zm-3 1h1v5H7v-5zm-2 2h1v1H5v-1zm9-3h-1v16h1V9zm1 1h1v15h-1V10zm3 0h-1v15h1V10zm2-2h-1v17h1V8zm1 0h1v6h-1V8zm3 1h-1v5h1V9zm1 2h1v3h-1v-3z',
    '8 9h6v1H8V9zm0 2v-1H7v1H6v2h1v1h2v-1H8v-1h16v1h-1v1h2v-1h1v-2h-1v-1h-1V9h-6v1h6v1H8zm16 0v1h1v-1h-1zM8 11v1H7v-1h1zm14 2H10v1h12v-1zm-11 2h10v1H11v-1zm10 2H11v1h10v-1zm-10 2h10v1H11v-1zm10 2H11v1h10v-1zm-10 2h10v1H11v-1z',
    '22 8h-2v1h1v1h2V9h-1V8zm-3 2h-1v1h-1v2h1v1h2v-1h1v-2h-1v-1h-1zm4 1h2v1h1v2h-1v1h-1v-1h-1v-1h-1v-1h1v-1zM6 12H5v1h1v-1zm12 3h-1v1h-1v2h1v1h2v-1h1v-2h-1v-1h-1zm-5 1h-1v1h-1v2h1v1h2v-1h1v-2h-1v-1h-1zm8 3h-1v1h-1v2h1v1h1v-4zm-5 1h-1v1h-1v2h1v1h2v-1h1v-2h-1v-1h-1zm-4 1h-1v4h1v-1h1v-2h-1v-1zm6 3h2v1h-2v-1zm-5-13h2v1h1v2h-1v1h-2v-1h-1v-2h1v-1zm-5 0h2v1h1v2h-1v-1H9v1H7v-2h1v-1zm5-3h-3v2h2V9h1V8z',
    '17 14h-2v1h-1v1h-1v2h1v1h1v1h2v-1h1v-1h1v-2h-1v-1h-1v-1zm0 1v1h1v2h-1v1h-2v-1h-1v-2h1v-1h2z',
    '18 11h-4v1h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1h4v1h1v1h1v1h1v-1h-1v-1h-1v-1h-1v-1zm3 8h-1v1h-1v1h-1v1h-4v-1h-1v-1h-1v-1h-1v1h1v1h1v1h1v1h4v-1h1v-1h1v-1h1v-1z',
    '9 9v1H8v1H7v1H6v1h1v-1h1v-1h1v-1h1V9h1V8h-1v1H9zm16 3h1v1h-1v-1zm-1-1h1v1h-1v-1zm-1-1h1v1h-1v-1zm-1-1h1v1h-1V9zm0 0h-1V8h1v1z',
    '12 9h1v1h-1V9zm-1 2v-1h1v1h-1zm-1 1v-1h1v1h-1zm-1 1v-1h1v1H9zm-1 1v-1h1v1H8zm0 0v1H7v-1h1zm11-5h1v1h-1V9zm2 2h-1v-1h1v1zm1 1h-1v-1h1v1zm1 1h-1v-1h1v1zm1 1h-1v-1h1v1zm0 0h1v1h-1v-1zm-3 9h-1v1h-1v1h1v-1h1v-1zm-9 1h1v1h-1v-1zm0 0h-1v-1h1v1z',
    '21 9h-1v1h-1v1h3v-1h-1V9Zm-4 3h-1v1h-1v1h3v-1h-1v-1Zm-4 2h-1v1h-1v1h3v-1h-1v-1Zm6 1h-1v1h-1v1h3v-1h-1v-1Zm-3 3h-1v-1h-1v1h-1v1h3v-1Zm-4 2h-1v1h1v-1Zm-1 4h1v1h-1v-1Zm9-4h-1v-1h-1v1h-1v1h3v-1Zm-4 2h-1v-1h-1v1h-1v1h3v-1Zm5 2h-1v-1h-1v1h-1v1h3v-1Zm0-12v1h-1v1h2v-2h-1Zm5 0h1v1h-3v-1h1v-1h1v1Zm-13-2h1v1h-3v-1h1V9h1v1Zm-5 1h1v1H6v-1h1v-1h1v1Zm-1 4v-2h1v2H7Z',
    '11 16v4h10v-3h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1Z',
    '11 8h-1v1H8v2h17v-1h-1V9h-2V8h-3v1h-1v1h-4V9h-1V8h-2Zm0 11h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v3H11v-4Z',
    '7 10h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h2v1h1v1h-2v1h-1v-1h-3v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1H9v1H8v-1H7v1H6v-1H5v-1h1v-1h1v-1Zm5 12h-1v3h10v-2h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1Z',
    '9 9H8v1H7v1H6v1h1v1h2V9Zm4 0h-1v2h2V9h-1Zm6 4h-1v3h3v-2h-1v-1h-1Zm-7 0h-1v4h2v-4h-1Zm8 7h-2v3h2v-1h1v-2h-1Zm1-11h2v4h-2v-1h-1v-2h1V9ZM11 22h4v2h-1v1h-2v-1h-1v-2Z',
    '15 10h2v2h-1v1h-2v-1h-1v-2h2Zm-2 7h2v3h-3v-1h-1v-2h2Zm2 3h3v4h-3v-4Zm6 2h-2v3h2v-3ZM7 14v1h1v-1h1v-1H7v1Zm16-2h3v2h-1v1h-1v-1h-1v-2Zm-4 2h-2v1h-1v3h3v-4Z',
    '18 9h2v2h-1v1h-2v-1h-1v-1h2V9Zm0 7h2v1h1v2h-1v1h-2v-1h-1v-2h1v-1Zm-4 3h-1v1h-1v2h1v1h2v-1h1v-2h-1v-1h-1Zm3 4h2v1h1v1h-4v-1h1v-1Zm-4-9h2v1h1v2h-1v1h-2v-1h-1v-2h1v-1Zm-2-1v1H9v-1H8v-2h1v-1h2v1h1v2h-1Zm13-4h-1v1h-1v2h1v1h2v-1h1v-1h-1v-1h-1V9Z',
    '13 8h-1v1h1V8zm-1 2h1v1h2v2h-3v-3zm3 4h-1v1h-2v2h3v-3zm-2 4h-1v3h3v-2h-2v-1zm11-7h1v2h-3v-3h1v1h1zm-9 11h-1v1h-2v2h3v-3z',
    '20 8v3h-1v-1h-1V9h1V8h1zM8 10h1v1h1V9H8v1zm10 4v1h-1v-3h3v2h-2zm-1 4h2v1h1v-3h-3v2zm-7-5H9v1H8v1H7v-3h3v1zm8 10h-1v-3h3v2h-2v1zm1 2h1v-1h-3v1h2z',
    '10 8h1v6h-1V8zm3 1h1v16h-1V9zm-5 1H7v5h1v-5zm8 0h1v15h-1V10zm4-2h-1v17h1V8zm2 1h1v4h-1V9zm4 2h-1v3h1v-3z',
    '12 8h-1v17h1V8zm3 2h-1v15h1V10zM8 9h1v5H8V9zm-2 3H5v1h1v-1zm11-2h1v15h-1V10zm4-2h-1v17h1V8zm2 1h1v5h-1V9zm4 3h-1v1h1v-1z',
    '10 8h3v1h-3V8zm16 3H6v1h20v-1zm-15 3h10v1H11v-1zm10 3H11v1h10v-1zm-10 3h10v1H11v-1zm0 3h10v1H11v-1zM22 8h-3v1h3V8zM7 14h1v1H7v-1zm18 0h-1v1h1v-1z',
    '25 10H7v1h18v-1zM6 13h3v1H6v-1zm4 0h12v1H10v-1zm11 3H11v1h10v-1zm-10 3h10v1H11v-1zm0 3h10v1H11v-1zm15-9h-3v1h3v-1z',
    '20 8h2v2h-2V8zm-9 3h2v2h-2v-2zm6 0h2v2h-2v-2zm-1 3h-2v2h2v-2zm-5 3h2v2h-2v-2zm8 0h-2v2h2v-2zm-5 3h2v2h-2v-2zm-1 3h-2v2h2v-2zm4 0h2v2h-2v-2zm4-3h-1v2h1v-2zm-1-6h1v2h-1v-2zm5-3h-2v2h2v-2zM7 11H6v1H5v1h2v-2zm1-2h2v1H8V9z',
    '11 8h2v2h-2V8zm5 3h-2v2h2v-2zm4 0h2v2h-2v-2zm-1 5v-2h-2v2h2zm-8-2h2v2h-2v-2zm5 3h-2v2h2v-2zm-5 3h2v2h-2v-2zm8 2v-2h-2v2h2zm-5 1h2v2h-2v-2zm7 0h-1v2h1v-2zm-1-6h1v2h-1v-2zm-10-6H8v2h2v-2zm8-2h1v1h-1V9zm6 0h-1v1h1V9zm0 5h1v1h-1v-1zm3-2h-1v1h1v-1z',
    '8 15H7v-5h1v5zm3 6h1v-8h-1v8zm6-6h-2v2h2v-2zm4 6v-1h-8v1h8zm0 3v1H11v-1h10zm0-13h-1v8h1v-8zm3-1h1v5h-1v-5zm-13 1v1h8v-1h-8z',
    '22 9h1v4h-1V9zM9 13h1v-2H9v2zm4 0v1h4v-1h-4zm6 0h-1v4h1v-4zm-5 6h-1v-4h1v4zm-8-6H5v-1h1v1zm13 6v-1h-4v1h4zm2 4v-1H11v1h10zm6-11h-1v1h1v-1zm-9-2V9h3v1h-3zM9 9v1h5V9H9z',
    '12 8h-2v1H8v2h1v-1h1V9h3V8h-1zm1 6h1v1h1v1h6v1h-1v1h-1v1h-1v-1h-1v-1h-6v-1h1v-1h1v-1zm5-3h1v-1h1V9h2V8h-3v1h-1v2zm5-1h1v1h1v1h1v1h-5v-1h1v-1h1v-1zM13 22h1v1h1v1h6v1H11v-1h1v-1h1v-1z',
    '14 10h-1v1h-1v1H5v1h2v1h2v-1h8v1h1v1h1v-1h1v-1h7v-1h-2v-1h-1v-1h-1v1h-1v1h-7v-1h-1v-1zm-1 8h1v1h1v1h6v1h-1v1h-1v1h-1v-1h-1v-1h-6v-1h1v-1h1v-1z',
    '22 8h-1v2h-1v1h1v3h-1v1h1v-1h1v-3h1v-1h-1V8zm-8 2h3v1h-1v3h1v1h-1v3h1v1h-1v3h1v1h-1v2h-1v-2h-1v-1h1v-3h-1v-1h1v-3h-1v-1h1v-3h-1v-1zm6 8h1v1h-1v-1zm1 4h-1v1h1v-1zM9 9h1v1h1v1h-1v2H9v-2H8v-1h1V9z',
    '12 8h1v4h1v1h-1v3h1v1h-1v3h1v1h-1v3h1v1h-3v-1h1v-3h-1v-1h1v-3h-1v-1h1v-3h-1v-1h1V9h-1V8h1zm7 1h-1v3h-1v1h1v3h-1v1h1v3h-1v1h1v3h-1v1h3v-1h-1v-3h1v-1h-1v-3h1v-1h-1v-3h1v-1h-1V9zm5 1h1v2h1v1h-1v2h-1v-2h-1v-1h1v-2zM6 11h1v1h1v1H7v1H6v-1H5v-1h1v-1z',
    '11 8h-1v6h1V8zm4 2h-1v15h1V10zm3-1h1v16h-1V9zm5 0h-1v4h1V9zm3 3h1v1h-1v-1zM7 11H6v3h1v-3z',
    '21 8h1v6h-1V8zm-7 1h-1v16h1V9zm4 1h-1v15h1V10zm8 1h-1v3h1v-3zM9 9h1v4H9V9zm-3 3H5v1h1v-1z',
    '8 11h1v2H8v-2zm2 0h2v2h-2v-2zm7 0h-2v2h2v-2zm-6 5h1v2h-1v-2zm4 0h2v2h-2v-2zm-3 5h-1v2h1v-2zm8 0h1v2h-1v-2zm1-5h-1v2h1v-2zm-6 5h2v2h-2v-2zm-1-5h-1v2h1v-2zm4 0h1v2h-1v-2zm4-5h-2v2h2v-2zm3 0h1v1h1v1h-2v-2zm-11 0h-1v2h1v-2zm5 0h-1v2h1v-2zm4 0h1v2h-1v-2zm-9 10h-1v2h1v-2zm4 0h1v2h-1v-2zM6 12H5v1h2v-2H6v1z',
    '14 9v1h-1V9h1zm-6 6v-1H7v1h1zm9-1v1h-2v-1h2zm0 5v1h-2v-1h2zm0 6v-1h-2v1h2zm-3-6v1h-1v-1h1zm0-4v-1h-1v1h1zm5-1v1h-1v-1h1zm0 6v-1h-1v1h1zm-5 4v1h-1v-1h1zm-2-4v-1h-1v1h1zm0-6v1h-1v-1h1zm0 10v1h-1v-1h1zm7 1v-1h-1v1h1zm2-11v1h-1v-1h1zm4 1v-1h-1v1h1zm-6-5V9h-1v1h1zm-7-1v1h-2V9h2zm-3 1V9H8v1h1zm13-1v1h-2V9h2zm2 1V9h-1v1h1zm-3 9v1h-1v-1h1zm0 6v-1h-1v1h1z',
    '25 10H7v1H6v1h20v-1h-1v-1zm-4 4H11v2h10v-2zm-10 4h10v2H11v-2zm10 4H11v2h10v-2zm3-8h1v1h-1v-1zM8 14H7v1h1v-1z',
    '11 8h-1v2h4V9h-3V8zm11 3V9h-4v1h3v1H11v3h9v1h-8v3h7v1h-6v3h5v1h-4v2h1v-1h4v-3h-5v-1h6v-3h-7v-1h8v-3h-9v-1h10v-1z',
    '11 8h-1v1h1v2H9V9H8v1H7v1H6v1H5v1h2v2h1v-1h1v-1h2v2h2v2h-2v2h2v2h-2v2h2v2h2v-2h2v2h2v-2h2v-2h-2v-2h2v-2h-2v-2h2v-2h2v1h1v1h1v-2h2v-1h-1v-1h-1v-1h-1V9h-1v2h-2V9h1V8h-1v1h-2v2h-2v-1h-2v1h-2V9h-2V8zm2 5v2h2v2h-2v2h2v2h-2v2h2v-2h2v2h2v-2h-2v-2h2v-2h-2v-2h2v-2h2v-2h-2v2h-2v-2h-2v2h-2zm0 0h-2v-2h2v2zm2 0v2h2v-2h-2zm2 4h-2v2h2v-2zm6-6v2h2v-2h-2zM9 13H7v-2h2v2z',
    '13 8h-1v1h1V8zm-3 2h1v1h-1v-1zm5 0h-1v1h1v-1zm-3 2h1v1h-1v-1zm2 2h1v1h-1v-1zm3 0h1v1h-1v-1zm3-2h-1v1h1v-1zm-8 4h1v1h-1v-1zm-3-4H8v1h1v-1zm10 4h1v1h-1v-1zm5-4h-1v1h1v-1zm-7-2h1v1h-1v-1zm5 0h-1v1h1v-1zm-3-2h1v1h-1V8zm-1 10h-1v1h1v-1zm1 2h1v1h-1v-1zm-1 2h-1v1h1v-1zm1 2h1v1h-1v-1zm-4-6h-1v1h1v-1zm-3 2h1v1h-1v-1zm2 2h1v1h-1v-1zm-1 2h-1v1h1v-1z',
    '15 13h2v2h-2z',
    '17 13h2v2h-2z',
    '13 13h2v2h-2z',
    '16 15h2v2h-2z',
    '14 15h2v2h-2z',
    '17 11h1v1h-1v-1zm2 1v1h-1v-1h1zm0 0v-1h1v1h-1zm-6 7h1v1h-1v-1zm0 1v1h-1v-1h1zm1 0h1v1h-1v-1zm4-1h-1v1h1v1h1v-1h1v-1h-1v1h-1v-1zm-3-7h-1v-1h-1v1h-1v1h1v-1h1v1h1v-1z',
    '23 10h1v1h-1v-1zm0 2v-1h-1v1h1zm1 0h-1v1h1v1h1v-1h1v-1h-1v-1h-1v1zm0 0v1h1v-1h-1zm-6 3h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h-1v-1h-1v1h-1v-1zM7 13h1v1H7v-1zm0-1v-1h1v1H7zm2 0H8v1h1v-1zm0-1h1v1H9v-1zm0 0H8v-1h1v1zm-2 1H6v1h1v-1zm10 11h1v1h-1v-1zm-1 1h1v1h-1v-1zm-1 0v-1h1v1h-1zm-1 0h1v1h-1v-1zm-1 0v-1h1v1h-1zm-1 0v1h1v-1h-1zm0 0h-1v-1h1v1zm7 0v1h-1v-1h1zm1 0h-1v-1h1v1zm0 0h1v1h-1v-1z',
    '13 8h-1v1h1V8zm-1 7h-1v1h1v1h1v-1h-1v-1zm-1 4h1v1h-1v-1zm1 1h1v1h-1v-1zm0 3h-1v1h1v1h1v-1h-1v-1zm3 0h1v1h-1v-1zm1 1h1v1h-1v-1zm3-1h1v1h-1v-1zm1 1h1v1h-1v-1zm-4-5h-1v1h1v1h1v-1h-1v-1zm3 0h1v1h-1v-1zm1 1h1v1h-1v-1zm-5-5h1v1h-1v-1zm1 1h1v1h-1v-1zm4-1h-1v1h1v1h1v-1h-1v-1zm0-7h1v1h-1V8zM7 11h1v1H7v-1zm1 1h1v1H8v-1zm4-1h-1v1h1v1h1v-1h-1v-1zm7 0h1v1h-1v-1zm1 1h1v1h-1v-1zm4-1h-1v1h1v1h1v-1h-1v-1zm-9 0h1v1h-1v-1zm1 1h1v1h-1v-1z',
    '11 9h-1v1H9v1h1v-1h1V9zm7 0h1v1h-1V9zm0 1v1h-1v-1h1zm-4 3h1v1h-1v-1zm0 1v1h-1v-1h1zm1 3h-1v1h-1v1h1v-1h1v-1zm-1 4h1v1h-1v-1zm0 1v1h-1v-1h1zm5-1h-1v1h-1v1h1v-1h1v-1zm-1-4h1v1h-1v-1zm0 1v1h-1v-1h1zm1-5h-1v1h-1v1h1v-1h1v-1zm-5-3h-1v1h1v-1zm-4 3h1v1h-1v-1zm15 1h-1v1h1v-1zm-2-5h-1v1h-1v1h1v-1h1V9zM7 13H6v1h1v-1z',
    '12 8h1v17h-1V8zm4 2h1v15h-1V10zm5-2h-1v17h1V8zm3 2h1v5h-1v-5zM9 9H8v5h1V9z',
    '11 8h1v17h-1V8zm4 2h1v15h-1V10zm5-2h-1v17h1V8zm3 1h1v5h-1V9zM8 10H7v5h1v-5z',
    '10 9H9v1H7v1h3V9zm12 0h1v1h2v1h-3V9zm-7 1h-1v5h-3v1h4v-6zm2 0h1v5h3v1h-4v-6zm-6 8h4v7h-1v-6h-3v-1zm6 7v-7h4v1h-3v6h-1z',
    '9 9H8v1h1V9zm15 0h-1v1h1V9zM13 9h1v6h-3v-1h2V9zm1 16v-6h-3v1h2v5h1zm5-16h-1v6h3v-1h-2V9zm-1 16v-6h3v1h-2v5h-1zm7-11h-1v1h1v-1zM8 14H7v1h1v-1z',
    '13 8h-1v5h-2v1h3V8zm-7 6h3v-1H6v1zm13-6h1v5h2v1h-3V8zm7 6h-3v-1h3v1zm-7 11v-5h2v1h-1v4h-1zm-7-5h-1v1h1v4h1v-5h-1z',
    '12 8h-2v1h2V8zm8 1V8h-1v1h-1v1h2V9zm-3 2h-1v1h1v-1zm-5 1h2v2h-2v-2zm4 6v-2h2v2h-2zm1 5v2h-2v-2h2zm4-1h-1v1h1v-1zm-10 1h1v2h-1v-2zm12-12h1v1h-1v-1zm-5 3h-1v1h1v-1zM8 13h1v1H8v-1zm7 5h-1v1h1v-1z',
    '22 8h-1v2h2V9h-1V8zM8 10h2v2H8v-2zm13 4h-2v2h2v-2zm-10 4h2v2h-2v-2zm8 6h2v1h-2v-1zm-5-1h-1v1h1v-1zM13 9h1v1h1v1h-2V9zm10 4h1v1h-1v-1zm-7 0h-1v1h1v-1zm-6 0h1v1h-1v-1zm9 6h-2v2h2v-2z',
    '12 10h-1v1h1v-1zm3 5h-2v2h2v-2zm5 2h-1v1h1v-1zm0 2h1v1h-1v-1zm-7 2h-1v1h1v-1zm5 1h1v1h-1v-1zM6 12H5v1h1v1h1v-2H6zm15 0h1v1h-1v-1zm-1-1h-2v2h2v-2zm5 3v-2h2v1h-1v1h-1zm-14 2h1v1h-1v-1zm5 4h-2v2h2v-2z',
    '10 8v1h3V8h-3zm9 1V8h3v1h-3zm-5 5h-1v6h6v-6h-5zm4 1h-4v4h4v-4zM7 15v-5h1v5H7zm17-5v5h1v-5h-1z',
    '10 10h13v3h-1v-2H10v2H9v-3h1zm5 6h2v2h-2v-2zm-4 7v1h10v-1H11z',
    '5 13v-1h1v1H5zm6-1v10h10V12H11zm9 9v-8h-8v8h8zm6-9v1h1v-1h-1z',
    '8 10h2v1h12v-1h2v1h-1v1H9v-1H8v-1zm3 6h10v1H11v-1zm0 5h10v1H11v-1z',
    '25 10h-1v1h-1v1H9v-1H8v-1H7v2h1v1h16v-1h1v-2zm-14 7h10v1H11v-1zm0 5h10v1H11v-1z',
    '8 9h6v1H8V9zm-3 3h1v1H5v-1zm2 2H6v-1h1v1zm0 0h1v1H7v-1zm20-2h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1zm-6 12H11v1h10v-1zm-10-5h10v1H11v-1zm10-5H11v1h10v-1zm3-5h-6v1h6V9z',
    '26 12v1h-1v1h-2v-1h1v-1h1v-1h1v1zm-4-4h-3v1h3V8zM11 23h10v1H11v-1zm0-5h10v1H11v-1zM10 8h3v1h-3V8zm12 5H10v1h12v-1zM7 13H6v-2h1v1h1v1h1v1H7v-1z',
    '7 11H6v2h1v1h2v-3H7zm18 0h1v2h-1v1h-2v-3h2zm-14 3h10v2H11v-2zm10 6H11v2h10v-2z',
    '8 10H7v2h1v1h2v-1H9v-1H8v-1zm16 0h1v2h-1v1h-2v-1h1v-1h1v-1zm-13 6h10v2H11v-2zm10 6H11v2h10v-2z',
    '24 11v1h1v-1h-1zm0 1v1h-1v-1h1zM7 12h1v-1H7v1zm1 0v1h1v-1H8zm5 1v-1h2v1h1v2h-1v2h2v-1h2v1h1v2h-1v1h-2v-1h-2v2h1v2h-1v1h-2v-1h-1v-2h1v-6h-1v-2h1z',
    '26 13h-1v1h-1v-1h1v-1h1v1zM6 13h1v-1H6v1zm1 0v1h1v-1H7zm12-1h-2v1h-1v2h1v1h2v-1h1v-2h-1v-1zm-6 4h2v1h1v2h-1v1h-2v-1h-1v-2h1v-1zm4 4h2v1h1v2h-1v1h-2v-1h-1v-2h1v-1z',
    '23 11h3v1h1v1h-1v1h-1v1h-1v-1h-1v-3zM6 12H5v1h1v1h1v1h1v-1h1v-3H6v1zm5 8h10v5H11v-5z',
    '8 9h2v1h1v2h-1v1H8v-1H7v-2h1V9zm3 6h10v5H11v-5zm13-6h-2v1h-1v2h1v1h2v-1h1v-2h-1V9z',
    '10 9h1v1h1v1h1v1h1v1h1v1h2v-1h1v-1h1v-1h1v-1h1V9h2v2h-1v1h-1v1h-1v1h-1v1h-1v1h-1v1h-2v-1h-1v-1h-1v-1h-1v-1h-1v-1h-1v-1H9V9h1z',
    '11 8h-1v2h1v1h1v1h1v1h1v1h1v1h2v-1h1v-1h1v-1h1v-1h1v-1h1V8h-1v1h-1v1h-1v1h-1v1h-1v1h-2v-1h-1v-1h-1v-1h-1V9h-1V8z',
    '22 8h-3v17h2V14h1v-1h1v1h1v1h1v-1h1v-1h1v-1h-1v-1h-1v-1h-1V9h-2V8z',
    '10 8h3v17h-2V14h-1v-1H9v1H8v1H7v-1H6v-1H5v-1h1v-1h1v-1h1V9h2V8z',
    '21 20v5H11v-5h10z',
    '11 15v5h10v-5H11z',
    '16 11h1v3h-2v-2h1v-1zm-2 6h-3v3h2v-1h1v-2zm4 3h2v1h1v4h-4v-2h1v-3z',
    '9 9H8v1H7v1H6v1h4v-2H9V9zm10 1h2v3h-2v1h-2v-4h2zm-2 5h-3v3h3v-3zm1 8v-4h-3v1h-1v3h4zm-6-11h1v-1h1v3h-2v-2z',
    '10 11h1v2h1v1h1v1h-2v-1h-1v-1H9v-1h1v-1zm7 4h4v3h-1v1h-3v-4zm-3 6h-2v1h-1v3h3v-1h1v-3h-1z',
    '13 9h1v2h-2v2h-1v-3h1V9h1zm-1 7h1v-1h1v2h-2v-1zm9-5V9h3v1h1v3h-3v-1h-1v-1zm-2 12v-1h1v-1h-2v1h-1v2h2v-1z',
    '12 16h8v1h-8v-1z',
    '12 15h8v1h-8v-1z',
    '12 14h8v1h-8v-1z',
    '7 11h1v1H7v-1zm1 1h1v1H8v-1zm4 1h8v1h-8v-1zm13-2h-1v1h-1v1h1v-1h1v-1z',
    '6 12h1v1H6v-1zm1 1h1v1H7v-1zm5-1h8v1h-8v-1zm14 0h-1v1h-1v1h1v-1h1v-1z',
    '10 9H8v1H7v1H6v1H5v1h1v1h1v1h1v-1h1v-1h1v-1h1v-2h-1V9zm12 0h2v1h1v1h1v1h1v1h-1v1h-1v1h-1v-1h-1v-1h-1v-1h-1v-2h1V9z',
    '13 12h1v1h-1v-1zm1 1h1v1h-1v-1zm5-1h-1v1h-1v1h1v-1h1v-1zm-6 5h1v1h-1v-1zm1 0v-1h1v1h-1zm4 0h1v1h-1v-1zm0 0h-1v-1h1v1z',
    '15 11h1v1h-1v-1zm-2 4h-1v1h1v-1zm4 3h-1v1h1v-1zm3-4h-1v1h1v-1z',
    '16 12h1v1h-1v-1zm-2 2h-1v1h1v-1zm5 1h-1v1h1v-1zm-3 2h-1v1h1v-1z',
    '14 13h1v2h-1v-2zm3 0h1v2h-1v-2zm1 4h-4v-1h-1v1h1v1h4v-1zm0 0v-1h1v1h-1z',
    '13 12h3v1h4v1h-1v1h-1v1h-3v-1h-2v-3z',
    '12 14h2v1h-2v-1zm5 2h-1v1h-1v1h2v-2z',
    '14 13h1v1h-1z',
    '14 13h-1v1h-1v1h2v4h-1v1h2v-2h3v1h-1v1h2v-5h1v-1h-1v1h-4v-3h-1v1Z',
    '13 13h1v1h-1z',
    '14 18h1v2h-2v-1h1v-1Zm4 0h1v2h-2v-1h1v-1Z',
    '16 15h-3v2h1v1h2v-3z',
    '13 14h4v4h-1v-1h-1v-1h-1v-1h-1v-1z',
    '14 13h-1v1h2v1h1v1h1v2h1v-5h-4z',
    '17 12h-4v1h3v1h1v1h1v3h1v-4h-1v-1h-1v-1z',
    '18 13h-1v1h1v1h-2v-1h-3v1h-1v2h6v-1h1v-2h1v-1h-1v1h-1v-1Zm-5 2h1v1h-1v-1Z',
    '13 15h1v1h-1z',
    '13 12h1v1h-1v-1Zm2 1h-1v1h1v-1Zm0 0v-1h1v1h-1Z',
    '16 11h-1v1h1v-1zm4 2h-1v1h1v-1zm-4 0h1v1h1v2h1v3h-1v1h-1v1h-3v-1h-1v-3h1v-1h1v-1h1v-2z',
    '15 17h1v2h1v1h-3v-2h1v-1z',
    '14 13h-1v1h1v-1zm1 4h-1v2h4v-4h-2v1h-1v1z',
    '16 18v-2h1v3h-1v2h-1v-1h-1v-1h1v-1h1z',
    '17 13v-1h-2v1h-1v1h-1v1h-1v2h2v1h-1v1h-1v1h1v-1h1v1h1v-1h2v1h1v-1h1v1h1v-1h-1v-1h-1v-1h2v-2h-1v-1h-1v-1h-1zm0 5h1v1h-1v-1zm-2 0v-1h2v1h-2zm0 0h-1v1h1v-1zm3-2v-1h-1v1h1zm-3 0v-1h-1v1h1z',
    '17 12h1v1h1v1h1v4h-1v1h-1v1h-4v-1h-1v-1h-1v-4h1v-1h1v-1h3z',
    '14 14h1v1h-1v-1zm3 0h1v1h-1v-1zm2 2h-1v1h-4v-1h-1v1h1v1h4v-1h1v-1z',
    '13 13h-1v1h1v3h-1v1h3v-1h-1v-4h-1zm-1 7h8v1h-8v-1zm5-7h2v1h-2v-1zm0 4h-1v-3h1v3zm2 0v1h-2v-1h2zm0-1v1h1v-3h-1v2z',
    '19 13h-6v5h1v1h-1v1h2v-2h2v1h-1v1h2v-2h1v-5zm-1 1h-1v1h1v-1zm0 2h-4v1h4v-1zm-4-1v-1h1v1h-1z',
    '16 12h1v2h-1v1h3v1h-1v1h-1v1h-1v1h-1v-2h1v-1h-3v-1h1v-1h1v-1h1v-1z',
    '11 17h10v4H11z',
    '6 13h3v1H8v1H7v-1H6v-1Zm4 0h12v1h-1v3H11v-3h-1v-1Zm16 0h-3v1h1v1h1v-1h1v-1Z',
    '9 9H8v1h1v1h4v1h4v1h4v1h1v-2h-4v-1h-4v-1h-4V9H9Zm2 10h3v1h4v1h3v1h-4v-1h-4v-1h-2v-1Zm13-6h-1v1h3v-1h-2Z',
    '19 9h-1v1h3v1h4v1h1v-1h-1v-1h-3V9h-3Zm-8 7h3v1h4v1h3v1h-4v-1h-4v-1h-2v-1Z',
    '5 12h5v1H5v-1Zm5 1h4v1h4v1h3v1h-4v-1h-4v-1h-3v-1Zm1 9h3v1h4v1h3v1h-4v-1h-4v-1h-2v-1Z',
    '11 9H8v1h2v1h4v1h4v1h5v1h3v-1h-3v-1h-4v-1h-4v-1h-4V9Zm0 9v1h4v1h4v1h2v-1h-1v-1h-4v-1h-4v-1h-1v1Z',
    '7 11H6v1h2v1h4v1h4v1h4v1h1v-2h-4v-1h-4v-1H9v-1H7Zm4 9h3v1h4v1h3v1h-4v-1h-4v-1h-2v-1Z',
    '8 10H7v1h2v1h4v1h4v1h5v-1h-4v-1h-4v-1h-4v-1H8Zm17 4h-1v1h1v-1Zm-14 5h4v1h4v1h2v1h-3v-1h-4v-1h-3v-1Z',
    '15 12h-1v1h3v1h-2v2h1v-1h1v-1h1v-1h-1v-1h-2zm1 5h-1v1h1v-1z',
    '13 12h1v1h-1v-1zm2 2v-1h-1v1h-1v1h1v1h-1v1h1v-1h1v-1h2v1h1v1h1v-1h-1v-1h1v-1h-1v-1h1v-1h-1v1h-1v1h-2zm2 0v1h1v-1h-1zm-2 0h-1v1h1v-1z',
    '16.5 12h1v1h1v1h-4v-1h2v-1zm-2 3h-1v-1h1v1zm3 1h-3v-1h3v1zm0 1v-1h1v1h-1zm-3 1v1h1v-1h2v-1h-4v1h1z',
    '13 12h2v1h-1v3h1v1h-2v-5zm4 4h1v-3h-1v-1h2v5h-2v-1z',
    '19 12h-6v1h-1v6h1v1h1v-1h1v1h2v-1h1v1h1v-1h1v-6h-1v-1zm-1 2v2h-1v-2h1zm-3 2h-1v-2h1v2z',
    '13 14h4v1h1v1h-2v2h2v-1h1v-1h1v2h-1v1h-1v1h-5v-1h-1v-4h1v-1z',
    '13 12h6v1h-6v-1zm6 1h1v2h-2v-1h1v-1zm-6 2h1v1h2v1h-3v-2zm0 2v1h-1v-1h1zm2 1h-1v1h-1v1h1v-1h2v1h1v-1h1v-1h-1v1h-1v-1h-1z',
    '17 14h1v1h-1z',
    '12 12h4v1h1v1h1v3h1v2h1v1h-2v-2h-1v2h-3v-1h1v-2h-1v-1h1v-1h-3v-1h2v-1h-2v-1zm2 5v1h-1v-1h1z',
    '15 13h1v1h-1v-1z',
    '16 14h3v1h-3v-1z',
    '13 13h1v1h1v1h-1v1h-1v1h3v-5h-3v1z',
    '17 12v5h-3v-1h1v-1h1v-1h-1v-1h-1v-1h3z',
    '17 12v1h1v3h-1v1h-2v-1h1v-1h1v-1h-1v-1h-1v-1h2z',
    '16 12h1v1h-1v-1zm2 2h-1v-1h1v1zm0 1v-1h1v1h-1zm-1 1h1v-1h-1v1zm0 0v1h-1v-1h1z',
    '14.5 13v1h1v-1h-1Zm3 3v-1h-1v1h1Z',
    '17.5 14v-1h-1v1h1Zm-3 1v1h1v-1h-1Z',
    '15.5 14h1v1h-1z',
    '14.5 14h-1v1h1v-1Zm4 0h-1v1h1v-1Z',
    '16.5 12h-1v1h1v-1Zm0 4h-1v1h1v-1Z',
    '14 16h4v1h-4z',
    '13 15h6v1h-6z',
    '12 14h8v1h-8z',
    '14 13h4v1h-4z',
    '15 12h2v1h-2z',
    '14 12h4v1h1v4h-1v1h-4v-1h-1v-4h1v-1z',
    '17 12h-1v2h1v-2z"/><path fill-opacity=".25" d="M13 13h1v2h1v1h4v1h-1v1h-4v-1h-1v-4zm2 0h1v1h-1v-1z',
    '17 12h-4v5h4v1h3v-1h-1v-1h-1v-1h1v-1h1v-1h-3v-1z"/><path fill-opacity=".2" d="M17 13h3v1h-1v1h-1v1h1v1h1v1h-3v-5z',
    '12 12h1v8h-1z',
    '13 13h5v1h2v2h-1v-1h-1v1h1v1h-2v1h1v1h-5v-1h1v-1h-1v-4z"/><path fill-opacity=".2" d="M13 16h1v1h-1v-1zm4 1h-3v1h3v-1zm0 0v-1h1v1h-1z',
    '15.5 12h-2v1h-1v2h1v1h1v1h1v1h1v-1h1v-1h1v-1h1v-2h-1v-1h-2v1h-1v-1z"/><g fill="#fff"><path fill-opacity=".6" d="M13.5 13h1v1h-1z"/><path fill-opacity=".3" d="M15.5 13h-1v1h-1v1h1v-1h1v-1z"/></g><path fill-opacity=".2" d="M19.5 14h-1v1h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1h1v-1z"/><path fill-opacity=".1" d="M19.5 13h-1v1h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1h1v-1z',
    '13 12h2v2h1v1h-1v1h1v2h-1v-1h-1v-1h-1v-1h-1v-2h1v-1zm3 4v-1h1v-1h-1v-1h1v-1h2v1h1v2h-1v1h-1v1h-1v-1h-1z"/><g fill="#fff"><path fill-opacity=".6" d="M13 13h1v1h-1z"/><path fill-opacity=".3" d="M15 13h-1v1h-1v1h1v-1h1v-1z"/></g><path d="M20 13h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1zm-4 3h-1v1h1v-1z" fill-opacity=".1"/><path fill-opacity=".2" d="M20 14h-1v1h-1v1h-1v1h1v-1h1v-1h1v-1zm-4 3h-1v1h1v-1z',
    '14 16h-1v-3h6v3h-1v1h-1v2h1v1h-4v-1h1v-2h-1v-1z"/><path fill-opacity=".2" d="M16 18h-1v1h2v-1h-1z',
    '15 16h-1v-3h4v3h-1v1h-2v-1z"/><path fill="#fff" fill-opacity=".4" d="M15 15h1v-2h-1v2z',
    '19 12h-6v1h-1v6h1v1h6v-1h1v-6h-1v-1z"/><path fill="#fff" d="M17 13h-2v1h-1v1h-1v2h1v1h1v1h2v-1h1v-1h1v-2h-1v-1h-1v-1z',
    '16 15h-1v2h2v-2h-1z',
    '14 13h4v4h-4z',
    '15 14v2h2v-2h-2z"/><path fill="#fff" fill-opacity=".3" d="M16 14h-1v1h1v1h1v-1h-1v-1z',
    '17 12h-2v2h-2v2h2v2h2v-2h2v-2h-2v-2zm-1 2h1v2h-2v-2h1z"/><path fill-opacity=".2" d="M16 12h-1v1h1v-1zm3 2h-1v1h1v-1zm-6 1h1v1h-1v-1zm4 2h-1v1h1v-1z',
    '13 16h6v1h-6z',
    '16 15h2v1h-2z',
    '13 14h6v1h-6z',
    '18 12h-4v1h-1v1h6v-1h-1v-1zm-5 5h6v1h-6v-1z"/><path fill-opacity=".1" d="M14 14h-1v3h1v-3zm5 0h-1v3h1v-3z"/><path fill="#fff" fill-opacity=".2" d="M16 12h1v1h-1v-1zm1 1v1h1v-1h-1zm-3 0h1v1h-1v-1z',
    '"/><path d="M10 9V8h3v1h1v1h4V9h1V8h3v1h2v1h1v1h1v1h1v1h-1v1h-1v1h-1v-1h-1v-1h-1v1h-1v11H11V14h-1v-1H9v1H8v1H7v-1H6v-1H5v-1h1v-1h1v-1h1V9h2Z" fill="url(#gd1)"/><defs><linearGradient id="gd1" gradientTransform="rotate(45 0.5 0.5)"><stop class="g1"/><stop offset="100%" class="g2"/></linearGradient></defs><g x="'
  ];

  // fill empty spaces with 0
  uint256[5][] public designs = [
    [0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0],
    [2, 0, 0, 0, 0],
    [3, 0, 0, 0, 0],
    [4, 5, 6, 7, 0],
    [8, 0, 0, 0, 0],
    [9, 10, 11, 0, 0],
    [12, 13, 14, 0, 0],
    [15, 16, 0, 0, 0],
    [17, 18, 0, 0, 0],
    [19, 20, 0, 0, 0],
    [21, 22, 0, 0, 0],
    [23, 24, 0, 0, 0],
    [25, 26, 0, 0, 0],
    [27, 28, 0, 0, 0],
    [29, 30, 0, 0, 0],
    [31, 32, 0, 0, 0],
    [33, 0, 0, 0, 0],
    [34, 0, 0, 0, 0],
    [35, 0, 0, 0, 0],
    [36, 0, 0, 0, 0],
    [37, 38, 39, 40, 41],
    [42, 43, 0, 0, 0],
    [44, 45, 0, 0, 0],
    [46, 47, 30, 0, 0],
    [48, 49, 50, 0, 0],
    [51, 52, 53, 0, 0],
    [54, 55, 56, 0, 0],
    [57, 58, 59, 60, 0],
    [61, 62, 0, 0, 0],
    [63, 64, 0, 0, 0],
    [65, 66, 0, 0, 0],
    [67, 68, 0, 0, 0],
    [69, 70, 0, 0, 0],
    [71, 72, 0, 0, 0],
    [67, 0, 0, 0, 0],
    [73, 74, 75, 76, 0],
    [77, 78, 79, 80, 81],
    [82, 0, 0, 0, 0],
    [83, 84, 85, 0, 0],
    [86, 0, 0, 0, 0],
    [87, 88, 89, 0, 0],
    [90, 91, 92, 0, 0],
    [93, 94, 95, 96, 0],
    [97, 98, 99, 0, 0],
    [100, 101, 102, 103, 0],
    [143, 144, 0, 0, 0],
    [145, 146, 0, 0, 0],
    [147, 0, 0, 0, 0],
    [148, 0, 0, 0, 0],
    [149, 0, 0, 0, 0],
    [104, 0, 0, 0, 0],
    [105, 106, 0, 0, 0],
    [107, 0, 0, 0, 0],
    [108, 0, 0, 0, 0],
    [109, 0, 0, 0, 0],
    [71, 110, 111, 0, 0],
    [112, 113, 114, 0, 0],
    [115, 116, 117, 0, 0],
    [118, 0, 0, 0, 0],
    [119, 0, 0, 0, 0],
    [120, 0, 0, 0, 0],
    [121, 0, 0, 0, 0],
    [122, 0, 0, 0, 0],
    [123, 124, 125, 0, 0],
    [126, 127, 0, 0, 0],
    [150, 151, 0, 0, 0],
    [152, 153, 0, 0, 0],
    [154, 155, 156, 0, 0],
    [128, 0, 0, 0, 0],
    [157, 139, 158, 159, 160],
    [129, 130, 131, 132, 0],
    [133, 134, 135, 136, 137],
    [138, 139, 140, 141, 142],
    [161, 0, 0, 0, 0]
  ];

  // index matches designs array above, see purchase method for logic
  bool[] public fancy = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false // whale
  ];

  constructor() {}

  // extract 0-6 substring at spot within mega palette string
  function getColor(uint256 spot) private pure returns (string memory) {
    if (spot == 0) return '';
    bytes memory strBytes = bytes(COLORS);
    bytes memory result = new bytes(6);
    for (uint256 i = (spot * 6); i < ((spot + 1) * 6); i++) result[i - (spot * 6)] = strBytes[i];
    return string(result);
  }

  function getStyles(Options memory options) private pure returns (string memory) {
    // prettier-ignore
    return string(abi.encodePacked(
      '.c1{fill:#', getColor(options.color1), '}',
      '.c2{fill:#', getColor(options.color2), '}',
      '.c3{fill:#', getColor(options.color3), '}',
      '.c4{fill:#', getColor(options.color4), '}',
      '.c5{fill:#', getColor(options.color5), '}',
      '.g1{stop-color:#', getColor(options.fill), '}',
      '.g2{stop-color:#', getColor(options.color1), '}'
    ));
  }

  function getDesign(Options memory options) private view returns (string memory) {
    // prettier-ignore
    return string(abi.encodePacked(
      PATH_PREFIX, 'c1" d="M', patterns[designs[options.design][0]], '"/>',
      PATH_PREFIX, 'c2" d="M', patterns[designs[options.design][1]], '"/>',
      PATH_PREFIX, 'c3" d="M', patterns[designs[options.design][2]], '"/>',
      PATH_PREFIX, 'c4" d="M', patterns[designs[options.design][3]], '"/>',
      PATH_PREFIX, 'c5" d="M', patterns[designs[options.design][4]], '"/>'
    ));
  }

  function getColorAttributes(Options memory options) private pure returns (string memory) {
    // prettier-ignore
    return string(abi.encodePacked(
      COLOR_PREFIX, getColor(options.fill), '"}',
      COLOR_PREFIX, getColor(options.color1), '"}',
      COLOR_PREFIX, getColor(options.color2), '"}',
      COLOR_PREFIX, getColor(options.color3), '"}',
      COLOR_PREFIX, getColor(options.color4), '"}',
      COLOR_PREFIX, getColor(options.color5), '"}'
    ));
  }

  function getCost(uint256 design) external view override returns (uint256 cost) {
    cost = COST_BASIC;
    if (design == DESIGNS_MAX) cost = COST_WHALE;
    else if (fancy[design]) cost = COST_FANCY;
  }

  function render(uint256 tokenId, Options memory options) external view override returns (string memory) {
    // prettier-ignore
    string memory art = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 0 3200 3200">',
          '<style>',
            getStyles(options),
          '</style>',
          '<g transform="scale(100)">',
            '<path fill="#', getColor(options.background), '" d="M0 0h32v32H0z"/>',
            '<path fill="#', getColor(options.outline), '" d="M13 7h-3v1H8v1H7v1H6v1H5v1H4v1h1v1h1v1h1v1h1v-1h1v-1h1v11h1v1h10v-1h1V14h1v1h1v1h1v-1h1v-1h1v-1h1v-1h-1v-1h-1v-1h-1V9h-1V8h-2V7h-3v1h-1v1h-4V8h-1V7Z"/>',
            '<path fill="#', getColor(options.fill), '" d="M10 8v1H8v1H7v1H6v1H5v1h1v1h1v1h1v-1h1v-1h1v1h1v11h10V14h1v-1h1v1h1v1h1v-1h1v-1h1v-1h-1v-1h-1v-1h-1V9h-2V8h-3v1h-1v1h-4V9h-1V8h-3Z"/>',
            getDesign(options),
          '</g>',
        '</svg>'
      )
    );

    // prettier-ignore
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{',
              '"name": "T-Shirt #', Strings.toString(tokenId), '",',
              '"external_url": "https://tshirt.exchange/shirt/', Strings.toString(tokenId), '",',
              '"description": "On-chain user generated t-shirts.",',
              '"attributes": [',
                '{"trait_type":"Design","value":"No. ', Strings.toString(options.design + 1), '"}',
                ',{"trait_type":"Background","value":"', getColor(options.background), '"}',
                ',{"trait_type":"Outline","value":"', getColor(options.outline), '"}',
                getColorAttributes(options),
              '],',
              '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(art)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }
}

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity 0.8.9;

library Base64 {
  bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}