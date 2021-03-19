/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.5.0;

interface IHashmaskLike {
    function ownerOf(uint256) external view returns (address);
}

contract FlexHashmask {
    address public owner = 0xA1Ed76f128084e70C683eB86b1A61FeFdc49268F;

    struct ActiveFlex {
        address flexer;
        uint256 flexAmount;
        uint256 id;
        uint256 time;
    }

    bool public paused = false;

    ActiveFlex public flex;

    event NewFlex(address indexed _flexer, uint256 _id, uint256 _value);

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

    function flexHashmask(uint256 _id) public payable isPaused {
        require(msg.value > .1 ether, "Minimum Flex is > .1 ETH.");
        require(
            IHashmaskLike(0xC2C747E0F7004F9E8817Db2ca4997657a7746928).ownerOf(
                _id
            ) == msg.sender,
            "Sender has to be the owner of the Hashmask"
        );
        require(
            msg.value > flex.flexAmount,
            "You Gotta Flex more than the Current Flex."
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

    function pause(bool _bool) public onlyDegenData {
        paused = _bool;
    }
}