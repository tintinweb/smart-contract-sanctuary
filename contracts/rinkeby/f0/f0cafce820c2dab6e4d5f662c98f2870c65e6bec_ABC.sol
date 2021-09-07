// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./base64.sol";
import "./Cards.sol";

//
//                                  -::::::::::::::::-
//                           .::::- -                = -::::
//                       .:::.     =-                =-     .:::.
//                   ::::          .-                =           :::.
//                ::.               -               -                :::
//              : -                 -       11     -.                 .: :
//            :: ::+                -      111    :.                .=:. ::
//          .-     .=         000   -        1   :.         d       :-.     -.
//         -.        -       00 00  -       111 :.      ddddd     ::         .-
//       ::           -       000   -          .:       d ddd  .:.             ::
//     ::              -            -         .:        ddd  ::                  -.
//    -.            H   -           -        .:           .::                     .-
//   -.          H HHH   -          -       .-          ::.        (::::)           .-
//    .::         HHH HH .-         -       ::        ::            :::::         ::
//       ::         H     .:        ...-=-::::-:::. ::            ::  ::)       .::
//         ::.             .:      ::::            ::=:                     ::.
//            ::            :: ::-=                    -.                 ::
//              ::.           . -.                      .-             .::
//                .::         ::                          ::         ::.
//                   ::     .-                              -.     ::
//                     ::. -.                                .- .:.
//
//   Run It Wild + PrimeFlare


contract ABC is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    address x = address(0xEA13b61a446A544404B07B7C8Dbe8D3376417a9F);
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("ABC", "ABC") {}

    uint256 public constant MAX_HAND = 10000;
    uint256 public constant BUY_PRICE = 52000000000000000; // 0.052 ETH

    function claim() public payable returns (uint) {
        require(msg.value >= BUY_PRICE, "Minimum buy in is required to play.");
        require(_tokenIdCounter.current() < MAX_HAND, "All 10,000 hands are dealt.");
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        return _tokenIdCounter.current();
    }

    function getHand(uint256 tokenId) private view returns (uint8[10] memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(Strings.toString(tokenId), x)));
        uint8[52] memory cards = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51];
        uint8[10] memory hand;

        for (uint8 i = 0; i < 5; i++) {
            uint8 index = uint8(rand%(52-i));
            hand[i*2] = cards[index]%13;
            hand[i*2+1] = uint8(cards[index]/13);
            cards[index] = cards[cards.length-1-i];
        }
        return hand;
    }

    function getCardImage(uint8 cardNumber, uint8 suitIndex, uint8 handIndex) private pure returns (bytes memory) {
        string[4] memory suits = ["&#9829;","&#9824;","&#9827;","&#9830;"];
        string[4] memory suitColors = ["ec5300","000","000","ec5300"];
        string memory card;
        string memory suit = suits[suitIndex];
        string memory suitColor = suitColors[suitIndex];

        if (cardNumber == 0) { card = 'A'; }
        else if (cardNumber == 12) { card = 'K'; }
        else if (cardNumber == 11) { card = 'Q'; }
        else if (cardNumber == 10) { card = 'J'; }
        else { card = Strings.toString(cardNumber+1); }

        string memory cardTransform;
        if (handIndex == 1) {
          cardTransform = '<g transform="translate(-135,70) rotate(-50 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
        }
        else if (handIndex == 2) {
          cardTransform = '</text></g><g transform="translate(-75,20) rotate(-25 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
        }
        else if (handIndex == 3) {
          cardTransform = '</text></g><g><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
        }
        else if (handIndex == 4) {
          cardTransform = '</text></g><g transform="translate(75,20) rotate(25 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
        }
        else if (handIndex == 5) {
          cardTransform = '</text></g><g transform="translate(135,70) rotate(50 250 229)"><rect x="200" y="150" height="158" width="100" rx="5" ry="5" class="ace" /><text x="290" y="181" text-anchor="end" style="fill: #C2BD88;">';
        }

        bytes memory cardImage = abi.encodePacked(
          cardTransform,
          card,
          '</text><text x="250" y="227.5" alignment-baseline="middle" text-anchor="middle" class="king">',
          suit,
          '</text><text x="250" y="228" alignment-baseline="middle" text-anchor="middle" style="fill: #', suitColor, '; font-size:1.4em">',
          suit,
          '</text><text x="350" y="297" text-anchor="end" style="fill: #C2BD88;" transform="rotate(180 280 288)">',
          card);

        return cardImage;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        uint8[10] memory hand = getHand(tokenId);

        bytes memory card1Image = getCardImage(hand[0], hand[1], 1);
        bytes memory card2Image = getCardImage(hand[2], hand[3], 2);
        bytes memory card3Image = getCardImage(hand[4], hand[5], 3);
        bytes memory card4Image = getCardImage(hand[6], hand[7], 4);
        bytes memory card5Image = getCardImage(hand[8], hand[9], 5);

        string memory trait = Cards.getTrait(hand);

        bytes memory brandText = abi.encodePacked(
          '</text></g><text x="250" y="83" style="fill: #C2BD88;font-size:0.85em" text-anchor="middle">H01d\'Em</text><text x="250" y="100" style="fill: #C2BD88;font-size:0.5em;font-style:italic" text-anchor="middle">Series 0ne</text><text x="250" y="387" style="fill: #C2BD88;font-size:0.65em;font-style:italic" text-anchor="middle">#',
          Strings.toString(tokenId),
          '</text><text x="100" y="100" style="fill: #C2BD88;"><textPath startOffset="-100%" xlink:href="#pokey" style="font-size:0.6em;">You Can\'t Bluff the Blockchain.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="5.475%" xlink:href="#pokey" style="font-size:0.6em;">You Can\'t Bluff the Blockchain.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="-45%" xlink:href="#pokey" style="font-size:0.6em;">Winners H01d\'Em, Losers F01d\'Em.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath><textPath startOffset="55%" xlink:href="#pokey" style="font-size:0.6em;">Winners H01d\'Em, Losers F01d\'Em.<animate additive="sum" attributeName="startOffset" from="100%" to="0%" begin="0s" dur="25s" repeatCount="indefinite" /></textPath></text></svg>'
          );

        bytes memory handImage = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500" preserveAspectRatio="xMidYMid meet" style="font:300 1.8em sans-serif"><path id="pokey" d="M38,18 h424 a20,20 0 0 1 20,20 v424 a20,20 0 0 1 -20,20 h-424 a20,20 0 0 1 -20,-20 v-424 a20,20 0 0 1 20,-20 z" /><rect width="500" height="500" fill="#034C29" /><style type="text/css"><![CDATA[.ace{stroke:#C2BD88;stroke-width:2.25;fill:#034C29} .king{fill:#C2BD88;font-size:1.5em;stroke:#C2BD88;stroke-width:3}]]></style>',
            card1Image,
            card2Image,
            card3Image,
            card4Image,
            card5Image,
            brandText);

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(handImage))
        );

        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"H01d\'Em S1 Hand #',Strings.toString(tokenId),
                '","external_url":"https://h01dem.com","image":"',image,
                '","description":"H01d\'Em Series 0ne. The first ever H01d\'Em tournament, shuffled and dealt on-chain. 52 card deck. 0ne mint = 0ne shuffle. Five card draw dealt on contract. 10,000 hands. 311,875,200 possibilities. 0ne Champion. May the best hand win.","attributes":[{"trait_type":"Hand","value":"',trait,'"}]}'
            )))));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable owner = payable(msg.sender);
        owner.transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}