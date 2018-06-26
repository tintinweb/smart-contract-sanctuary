pragma solidity ^ 0.4 .23;
contract EtherealTarot {

    struct reading { // Struct
        uint count;
        uint8[] cards;
        bool[] reversed;
    }

  mapping(address => reading) readings;

  uint8[78] cards;
  uint8 deckSize = 78;
  address public creator;

  constructor() public {
    creator = msg.sender;
    for (uint8 card = 0; card < deckSize; card++) {
      cards[card] = card;
    }
  }
    
  function draw(uint8 index, uint8 count) private {
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
  function random_bool(uint8 count) view private returns(bool){
      return 0==random(2,count);
  }

  function spread(uint8 requested) private {
    // cards in the current spread
    uint8[] memory table = new uint8[](requested);
    //card orientation 0 is front 1 is reversed
    bool[] memory oriented = new bool[](requested);

    //Draw the whole spread
    for (uint8 position = 0; position < requested; position++) {
      table[position] = draw_random_card(position);
      oriented[position] = random_bool(position);
    }
    readings[msg.sender]=reading(requested,table,oriented);
  }


  function reading_card_reversed_at(uint8 index) view public returns(bool) {
    require(index<readings[msg.sender].count);
    return readings[msg.sender].reversed[index];
  }
  function reading_length() view public returns(uint) {
    return readings[msg.sender].count;
  }
  function has_reading() view public returns(bool) {
    return readings[msg.sender].count!=0;
  }
    
  function reading_card_at(uint8 index) view public returns(uint8) {
    require(index<readings[msg.sender].count);
    return readings[msg.sender].cards[index];
  }
  function reading_cards() view public returns(uint8[]) {
    return readings[msg.sender].cards;
  }

  // Tarot by donation + gas costs
  function withdraw() public {
    require(msg.sender == creator);
    creator.transfer(address(this).balance);
  }
    
  // for updating to better contracts ~,~
  function shiva() public{
    require(msg.sender == creator);
    selfdestruct(creator);
  }

  // 8 Different Spreads available
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

  function single_card() payable public {
    spread(1);
  }
  function two_card() payable public {
    spread(2);
  }

  function seventeen() payable public {
    spread(17);
  }
  
}