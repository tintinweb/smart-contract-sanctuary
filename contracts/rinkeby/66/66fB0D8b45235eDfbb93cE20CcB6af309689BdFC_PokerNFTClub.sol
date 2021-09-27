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
    constructor() ERC721("Poker NFT Club - TBS", "PNC") {}

    uint16 public constant MAX_HAND = 10000;
    uint256 public constant BUY_PRICE = 0.052 ether;
    uint32 public constant MAX_VARIATION = 311875200;

    uint32[] private handList;
    uint256 private startClaimDate = 1632913200; //September 29, 2021 11:00:00 AM UTC
    struct Traits {
            string[10] A_NAME;
            string[10] B_NAME;
            string[10] C_NAME;
            string[10] D_NAME;
        }
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

    function getHand(uint32 handId) private pure returns (uint8[14] memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(Strings.toString(handId))));
        uint8[52] memory cards = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51];
        uint8[14] memory hand;

        for (uint8 i = 0; i < 5; i++) {
            uint8 index = uint8(rand%(52-i));
            hand[i*2] = cards[index]%13;
            hand[i*2+1] = uint8(cards[index]/13);
            cards[index] = cards[cards.length-1-i];
            if(i<4){
               hand[10+i] = uint8(index%10);
            }
            rand = uint256(keccak256(abi.encodePacked(Strings.toString(rand))));
        }
        return hand;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId < handList.length, "Hand not yet claimed.");
        uint8[14] memory hand = getHand(handList[tokenId]);

        bytes memory card1Image = Render.getCardImage(hand[0], hand[1], 1);
        bytes memory card2Image = Render.getCardImage(hand[2], hand[3], 2);
        bytes memory card3Image = Render.getCardImage(hand[4], hand[5], 3);
        bytes memory card4Image = Render.getCardImage(hand[6], hand[7], 4);
        bytes memory card5Image = Render.getCardImage(hand[8], hand[9], 5);

        Traits memory traits = Traits(["SKULL","ADI SHAKTI","STAR AND CRESCENT","PEACE","CROSS OF LORRAINE","YIN YANG","WHEEL OF DHARMA","EARTH","NEPTUNE","MERCURY"],["CHESS KING","CHESS QUEEN","CHESS ROOK","CHESS BISHOP","CHESS KNIGHT","CHESS PAWN","EIGHTH NOTE","BEAMED EIGHTH NOTES","EAST SYRIAC CROSS","UNIVERSAL RECYCLING"],["CROSSED SWORDS","HAMMER AND PICK","FLOWER","GEAR","ATOM","FLEUR-DE-LIS","STAR","COFFIN","SCISSORS","PENCIL"],["DIAMOND","FLORAL HEART","HEAVY SPARKLE","SNOWFLAKE","AIRPLANE","VICTORY HAND","BASEBALL","HOT SPRINGS","SMILING FACE","FROWNING FACE"]);
       
        string memory trait = Cards.getTrait(hand);

        bytes memory brandText = Render.getBrandImage(tokenId,hand);

        bytes memory handImage = abi.encodePacked(
            Render.getHeader(),
            card1Image,
            card2Image,
            card3Image,
            card4Image,
            card5Image,
            brandText);
        bytes memory traitsarray=abi.encodePacked('[{"trait_type":"Hand","value":"',trait,'"},{"trait_type":"The Blind","value":"',traits.A_NAME[hand[10]],'"},{"trait_type":"Late Position","value":"',traits.B_NAME[hand[11]],'"},{"trait_type":"Middle Position","value":"',traits.C_NAME[hand[12]],'"},{"trait_type":"Early Position","value":"',traits.D_NAME[hand[13]],'"}]');
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(handImage))
        );
    
        return string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"Poker NFT Club(TBS) #',Strings.toString(tokenId),
                '","external_url":"https://pokernft.club","image":"',image,
                '","description":"Poker NFT Club(The Beginning Series) is a collection of 10K Poker Hands. Digital collectibles living on the Ethereum blockchain generated randomly on chain from 50 possible traits. All hands are exclusive and provide access to membership, but some are rarer than others. \'MAY THE FLOP BE WITH YOU!!\'","attributes":',traitsarray,'}'
            )))));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable owner = payable(msg.sender);
        owner.transfer(balance);
    }

    mapping(address => bool) private winners;
    
    /**
     * Sets the winners of giveaway for free mint
     */
    function addGiveAwayWinners(address[] memory _winners)
        external
        onlyOwner
    {
        
        for (uint256 i; i < _winners.length; i++) {
            winners[_winners[i]] = true;
        }
    }
    
    /**
     * free mint for the winners of giveaway
     */
    function claimTokenWinner() external  {
        require( startClaimDate != 0 && startClaimDate <= block.timestamp, "You are too early" );
        require(handList.length < MAX_HAND, "All 10,000 hands are dealt.");
        require(tx.origin == msg.sender, "Can not be called using a contract.");
        require(winners[msg.sender]==true,"You are not winner or claimed already");

        uint32 hand = getHandSeed();
        uint curTokenId = handList.length;
        _safeMint(msg.sender, curTokenId);
        handList.push(hand);
        winners[msg.sender]=false;
        
    }

    /**
     * 50 reserve for rewards, giveaway and team. 
     */
    function reserve() external onlyOwner returns (uint) {
        require(handList.length < 50, "Can only claim first 50");

        uint32 hand = getHandSeed();
        uint curTokenId;

        for(uint16 i = 0; i < 50; i++){
          curTokenId = handList.length;
          _safeMint(msg.sender, curTokenId);
          hand = getHandSeed();
          handList.push(hand);
        }

        return curTokenId;
    }


}