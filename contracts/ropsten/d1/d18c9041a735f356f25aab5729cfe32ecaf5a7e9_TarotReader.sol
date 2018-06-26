pragma solidity ^0.4.24;
contract TarotReader {

  mapping (address => uint8[]) readings;

  address public creator;
  function draw_random_card(uint8 index,uint8[] table) view private returns (uint8)  {
    uint8 random_card=random(77,index);
    for (uint8 i = 0; i < table.length; i++) {
      if(random_card==table[i]){ 
        return draw_random_card(index,table);
      }
    }
    return random_card;
  }
function random(uint8 range,uint count) view private returns (uint8 randomNumber) {
  uint8 _seed = uint8(
    keccak256(
      abi.encodePacked(
        keccak256(
          abi.encodePacked(
            blockhash(block.number),
            _seed)
        ), now + count)
    ));
  return _seed % range;
}
  function spread(uint8 cards) private{
    assert(cards<17);
    uint8[] memory table = new uint8[](cards);
    for (uint8 position = 0; position < cards; position++) {
      table[position]=draw_random_card(position,table);
    }
    readings[msg.sender]=table;
  }
  function career_path() payable  public {
    creator.transfer(msg.value);
    return spread(7);
  }
  function celtic_cross() payable public {
    creator.transfer(msg.value);
    spread(10);
  }
  function past_present_future() payable public {
    creator.transfer(msg.value);
    spread(3);
  }
  function success() payable public {
    creator.transfer(msg.value);
    spread(5);
  }
  function spiritual_guidance() payable public {
    creator.transfer(msg.value);
    spread(8);
  }
  function one_card() payable public {
    creator.transfer(msg.value);
    spread(1);
  }
  function reading() view public returns(uint8[]) {
    return readings[msg.sender];
  }
  
  constructor() public{
    creator = msg.sender;
  }



}