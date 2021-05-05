/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity =0.8.0;

interface IBarker {
    function collectTips() external;
    event Bark(address author, address barkingToWhom, string content, uint256 tip);
    event TipReceived(address thisBark, address tipper, uint256 amount);
    event TipsCollected(address author, address collector, uint256 amount);
}

contract Barker is IBarker {
    address payable public author;
    address payable public barkingToWhom;
    string public content;
    
    constructor(address payable barkingToWhom_, string memory content_) payable {
        author = payable(msg.sender);
        barkingToWhom = barkingToWhom_;
        content = content_;
        barkingToWhom.transfer(msg.value);
        emit Bark(author, barkingToWhom, content, msg.value);
    }

    receive() external payable {
        emit TipReceived(address(this), msg.sender, msg.value);
    }

    function collectTips() public override {
        uint256 amount = address(this).balance;
        author.transfer(amount);
        emit TipsCollected(author, msg.sender, amount);
    }
}