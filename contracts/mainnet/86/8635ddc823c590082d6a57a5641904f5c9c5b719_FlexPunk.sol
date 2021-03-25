/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.5.0;

interface ICryptoPunkLike {
    function punkIndexToAddress(uint256) external view returns (address);
}

contract FlexPunk {
    address public owner = 0xA1Ed76f128084e70C683eB86b1A61FeFdc49268F;  
    bool public paused = false;
    struct ActiveFlex {
        address flexer;
        uint256 flexAmount;
        uint256 id;
        uint256 time;
    }
  
    ActiveFlex public flex;
    event NewFlex(address indexed _flexer, uint256 _id, uint256 _value);
    event RevokeFlex(address indexed _address, uint256 _id, uint256 _days);

    constructor(address _flexer, uint256 _flexAmount, uint256 _id, uint256 _time) public{
        flex.flexer = _flexer;
        flex.flexAmount = _flexAmount;
        flex.id = _id;
        flex.time = _time;
        
    }

       modifier onlyDegenData {
        require(
            msg.sender == 0xA1Ed76f128084e70C683eB86b1A61FeFdc49268F,
            "Excuse me, This doesn't belong to you"
        );
        _;
    }

    modifier isPaused {
        require(
            paused == false,
            "sorry we have pause things for now. Too much Flexing is going on."
        );
        _;
    }

 
    
    function flexPunk(uint256 _id) public payable {
        require(msg.value > .1 ether, "Minimu Flex is .1 ETH.");
        require(ICryptoPunkLike(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).punkIndexToAddress(
                _id
            ) == msg.sender,
            "Sender has to be the owner of the Punk"
        );
        require(
            msg.value > flex.flexAmount,
            "You Gotta Flex more than the Current Flex"
        );
        require(
            block.timestamp > flex.time,
            "You gotta Wait your turn to flex"
        );
        flex.flexAmount = msg.value;
        flex.flexer = msg.sender;
        flex.id = _id;
        flex.time = block.timestamp + 1 days;
        emit NewFlex(msg.sender, _id, msg.value);
        
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyDegenData {
        msg.sender.transfer(address(this).balance);
    }
    
    function revokeFlex(uint256 _id) public isPaused {
         require(ICryptoPunkLike(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).punkIndexToAddress(
                _id
            ) == msg.sender,
            "Sender has to be the owner of the Punk"
        );
        emit RevokeFlex(msg.sender, _id, block.timestamp);
    }
}