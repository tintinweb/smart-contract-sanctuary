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