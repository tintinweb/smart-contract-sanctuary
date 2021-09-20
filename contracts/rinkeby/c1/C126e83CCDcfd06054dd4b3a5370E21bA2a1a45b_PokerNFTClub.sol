// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./Cards.sol";
import "./Render.sol";

contract PokerNFTClub is ERC721Enumerable, Ownable {
    constructor() ERC721("ABC", "ABC") {}

    uint16 public constant MAX_HAND = 10000;
    uint256 public constant BUY_PRICE = 0.052 ether;
    uint32 public constant MAX_VARIATION = 311875200;

    uint32[] private handList;
    uint256 private startClaimDate = 1632567600; //September 25, 2021 11:00:00 AM UTC

    function claimTokens(uint256 amount) external payable {
        require( startClaimDate != 0 && startClaimDate <= block.timestamp, "You are too early" );
        require(amount<=10, 'You cannot claim more than 10 tokens in one transaction');
        require( msg.value >= BUY_PRICE * amount, "Not enough Ether to claim the tokens" );
        require(handList.length+amount <= MAX_HAND, "All 10,000 hands are dealt.");
        require(tx.origin == msg.sender, "Can not be called using a contract.");

        for (uint256 i; i < amount; i++) {
                uint32 hand = getHandSeed();
                uint curTokenId = handList.length;
                _safeMint(msg.sender, curTokenId);
                handList.push(hand);
            }
    }

    function getHandSeed() private view returns (uint32) {
        return uint32(uint256(keccak256(abi.encodePacked(block.difficulty, block.coinbase, msg.sender, handList.length, address(this)))) % MAX_VARIATION);
    }

    function setStartClaimDate(uint256 _startClaimDate)
        external
        onlyOwner
    {
        startClaimDate = _startClaimDate;
    }

    function getHand(uint32 handId) private pure returns (uint8[10] memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(Strings.toString(handId))));
        uint8[52] memory cards = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51];
        uint8[10] memory hand;

        for (uint8 i = 0; i < 5; i++) {
            uint8 index = uint8(rand%(52-i));
            hand[i*2] = cards[index]%13;
            hand[i*2+1] = uint8(cards[index]/13);
            cards[index] = cards[cards.length-1-i];
            rand = uint256(keccak256(abi.encodePacked(Strings.toString(rand))));
        }
        return hand;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < handList.length, "Hand not yet claimed.");
        uint8[10] memory hand = getHand(handList[tokenId]);

        bytes memory card1Image = Render.getCardImage(hand[0], hand[1], 1);
        bytes memory card2Image = Render.getCardImage(hand[2], hand[3], 2);
        bytes memory card3Image = Render.getCardImage(hand[4], hand[5], 3);
        bytes memory card4Image = Render.getCardImage(hand[6], hand[7], 4);
        bytes memory card5Image = Render.getCardImage(hand[8], hand[9], 5);

        string memory trait = Cards.getTrait(hand);

        bytes memory brandText = Render.getBrandImage(tokenId);

        bytes memory handImage = abi.encodePacked(
            Render.getHeader(),
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
                '{"name":"Poker NFT Club(TBS) #',Strings.toString(tokenId),
                '","external_url":"https://pokernft.club","image":"',image,
                '","description":"Poker NFT Club(The Beginning Series) is a collection of 10,000 Poker Hands. Digital collectibles living on the Ethereum blockchain. Shuffled and dealt 0n-Chain. 52 Straight Up 5 Card Draw. One Deck of Cards. 311,875,200 potential hands. 10,000 Hands Drawn. One winner one grand prize. \'MAY THE FLOP BE WITH YOU!!\'","attributes":[{"trait_type":"Hand","value":"',trait,'"}]}'
            )))));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable owner = payable(msg.sender);
        owner.transfer(balance);
    }
}