/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity ^0.8.0;

contract Faucet {
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Buoy AddressIndex: Not called by owner');
        _;
    }
    
    receive() external payable {}
    fallback() external payable {}
    
    address owner;
    address buoy;
    mapping(address => uint) accTrack;

    IERC20 Buoy;

    constructor(address b) {
        owner = msg.sender;
        buoy = b;
        Buoy = IERC20(b);
    }

    function setBuoy(address b) onlyOwner public {
        buoy = b;
        Buoy = IERC20(b);
    }

    function setOwner(address x) onlyOwner public {
        owner = x;
    }
    
    function drain() onlyOwner public {
        uint amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function redeemFaucet() public {
        require(block.timestamp > accTrack[msg.sender], "Too soon since last claim");
        accTrack[msg.sender] = block.timestamp + 1 days;
        Buoy.transfer(msg.sender, 100*(10**18));
        payable(msg.sender).transfer(1*(10**17));
    }

}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}