/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity =0.8.0;

interface IDogeTalk {
    function author() external view returns (address);
    function replyingTo() external view returns (address);
    function content() external view returns (string memory);
    function receivedTips() external view returns (uint256);
    function claimTips() external;
}

contract DogeTalk is IDogeTalk {
    address payable private _author;
    address payable private _replyingTo;
    string private _content;
    
    constructor(address payable replyingTo_, string memory content_) payable {
        _author = payable(msg.sender);
        _replyingTo = replyingTo_;
        _content = content_;
        
        // Send tip when replying.
        _replyingTo.transfer(msg.value);
    }

    function author() public view override returns (address) {
        return _author;
    }
    
    function replyingTo() public view override returns (address) {
        return _replyingTo;
    }

    function content() public view override returns (string memory) {
        return _content;
    }

    function receivedTips() public view override returns (uint256) {
        return address(this).balance;
    }
    
    function claimTips() public override {
        _author.transfer(address(this).balance);
    }
    
    receive() external payable { }
}