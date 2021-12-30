/* 
 This token certifies the personal right of its owner to use
 the literature work «Walking in the Fresh Air»
 (Valery Gorlachev; language of publication – Russian (Cyrillic alphabet)),
 which constitutes the result of intellectual activity (hereinafter – «Book»).
 Receipt of the token means the owner's consent to
 the terms of the agreement (https://fresh-air-walks.ru/nft/legal)
 in accordance with Art. 438 of the Civil Code of the Russian Federation.
 The owner of the token has the right to use the token for personal,
 non-commercial purposes in ways that are explicitly stated
 in the agreement. Any use of the token and/or the Book by any other means
 constitutes copyright infringement and is punishable under applicable law.

 Настоящий токен удостоверяет персональное право его владельца
 на использование произведения литературы «Прогулки на свежем воздухе»
 (Валерий Горлачев; язык издания — русский (кириллица)),
 являющегося результатом интеллектуальной деятельности (далее — «Книга»).
 Получение токена означает присоединение владельца
 к условиям соглашения  (https://fresh-air-walks.ru/nft/legal)
 в порядке ст. 438 Гражданского кодекса Российской Федерации.
 Владелец токена имеет право на использование токена в личных некоммерческих
 целях теми способами, которые прямо указаны в соглашении.
 Любое использование токена и/или Книги иными способами является нарушением
 авторских прав и влечет за собой  ответственность, предусмотренную
 действующим законодательством.
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Address.sol";

contract FreshAirWalksNFT is ERC721, Ownable
{
    using Address for address payable;

    event Action(address indexed customer, uint256 indexed tokenId, string data, uint256 n);
    event Splited(address indexed customer, uint256 indexed tokenId, address indexed receiver, uint256 n);
    event Minted(address indexed customer, uint256 n);
    event PriceChanged(uint256 priceWei);

    uint256                      private _minterCounter;
    string                       private _base;
    mapping (uint256 => uint256) public  _n;
    uint256                      public  _priceWei;

    constructor() ERC721("Fresh Air Walks", "FAW")
    {
        setBaseURI("https://freshairwalks.ru/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }

    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }

    function setPrice(uint256 priceWei) public onlyOwner
    {
        _priceWei = priceWei;
        emit PriceChanged(priceWei);
    }

    function mint(address customer, uint256 n) public onlyOwner returns(uint256)
    {
        return _mymint(customer, n);
    }

    function mintMulti(uint256 count, address customer, uint256 n) public onlyOwner
    {
        for(uint256 i = 0; i < count; ++i)
        {
            _mymint(customer, n);
        }
    }

    function _mymint(address customer, uint256 n) internal returns(uint256)
    {
        _minterCounter += 1;
        _safeMint(customer, _minterCounter);
        _n[_minterCounter] = n;
        emit Minted(customer, n);
        return _minterCounter;
    }

    function action(uint256 tokenId, string memory data, uint256 n) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        if (n > 0)
        {
            if (_n[tokenId] > 0)
            {
                require(_n[tokenId] >= n, "FreshAirWalks: Not enough power in token to do action");
                _n[tokenId] -= n;
                if (_n[tokenId] == 0)
                {
                    _burn(tokenId);
                }
            }
        }
        emit Action(_msgSender(), tokenId, data, n);
    }

    function split(uint256 tokenId, address receiver, uint256 n) public returns(uint256)
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        if (_n[tokenId] > 0)
        {
            require(_n[tokenId] >= n, "FreshAirWalks: Not enough power in source token");
            _n[tokenId] -= n;
            if (_n[tokenId] == 0)
            {
                _burn(tokenId);
            }
        }
        emit Splited(_msgSender(), tokenId, receiver, n);
        return _mymint(receiver, n);
    }

    receive () payable external
    {
        require(_priceWei > 0, "FreshAirWalks: NFT public sale is closed");
        require(msg.value == _priceWei, "FreshAirWalks: Invalid amount of wei");
        _mymint(_msgSender(), 3);
    }

    function withdraw() public onlyOwner
    {
        payable(_msgSender()).sendValue(address(this).balance);
    }
}