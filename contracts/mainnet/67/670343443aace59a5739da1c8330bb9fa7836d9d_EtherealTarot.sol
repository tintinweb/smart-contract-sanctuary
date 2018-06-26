pragma solidity ^ 0.4 .23;
//Ethereal Tarot Reader http://tarot.etherealbazaar.com/
contract EtherealTarot {

  mapping(address => uint8[]) readings;
  mapping(address => uint8[]) orientations;
  uint8[78] cards;
  uint8 deckSize = 78;
  address public creator;

  constructor() public {
    creator = msg.sender;
    for (uint8 card = 0; card < deckSize; card++) {
      cards[card] = card;
    }
  }
    
  function draw(uint8 index, uint8 count) public {
    // put the drawn card at the end of the array
    // so the next random draw cannot contain
    // a card thats already been drawn
    uint8 drawnCard = cards[index];
    uint8 tableIndex = deckSize - count - 1;
    cards[index] = cards[tableIndex];
    cards[tableIndex] = drawnCard;
  }

  function draw_random_card(uint8 count) private returns(uint8) {
    uint8 random_card = random(deckSize - count, count);
    draw(random_card, count);
    return random_card;
  }

  function random(uint8 range, uint8 count) view private returns(uint8) {
    uint8 _seed = uint8(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              blockhash(block.number),
              _seed)
          ), now + count)
      )
    );
    return _seed % (range);
  }

  function spread(uint8 requested) private {
    // cards in the current spread
    uint8[] memory table = new uint8[](requested);
    //card orientation 0 is front 1 is reversed
    uint8[] memory oriented = new uint8[](requested);

    //Draw the whole spread
    for (uint8 position = 0; position < requested; position++) {
      table[position] = draw_random_card(position);
      oriented[position] = random(2, position);
    }
    orientations[msg.sender] = oriented;
    readings[msg.sender] = table;
  }


  function orientation() view public returns(uint8[]) {
    return orientations[msg.sender];
  }

  function reading() view public returns(uint8[]) {
    return readings[msg.sender];
  }

  // Tarot by donation + gas costs
  function withdraw() public {
    require(msg.sender == creator);
    creator.transfer(address(this).balance);
  }
    
  function shiva() public{
    require(msg.sender == creator);
    selfdestruct(creator);
  }

  // 6 Different Spreads available
  function career_path() payable public {
    spread(7);
  }

  function celtic_cross() payable public {
    spread(10);
  }

  function past_present_future() payable public {
    spread(3);
  }

  function success() payable public {
    spread(5);
  }

  function spiritual_guidance() payable public {
    spread(8);
  }

  function one_card() payable public {
    spread(1);
  }
  function two_card() payable public {
    spread(2);
  }

  function seventeen() payable public {
    spread(17);
  }
  
}