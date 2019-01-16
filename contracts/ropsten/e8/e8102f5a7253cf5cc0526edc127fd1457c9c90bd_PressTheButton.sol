pragma solidity ^0.4.25;

contract PressTheButton {
    
    bool public started = false;
    uint public last_click_block;
    address public last_click_address;
    uint public how_many_blocks_to_win;
    
    constructor(uint _how_many_blocks_to_win) public payable {
        how_many_blocks_to_win = _how_many_blocks_to_win;
    }

    function click() public payable {
        require(msg.sender != last_click_address);
        require(msg.value > 0.1 ether);
        
        if(started)
            require(!ended());
        else
            started = true;
            
        last_click_address = msg.sender;
        last_click_block = block.number;
    }
    
    function withdraw() public {
        require(ended());
        msg.sender.transfer(address(this).balance);
    }
    
    function ended() public view returns(bool) {
        return last_click_block < block.number - how_many_blocks_to_win;   
    }
}