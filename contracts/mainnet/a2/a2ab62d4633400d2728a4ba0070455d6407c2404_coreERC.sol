pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
}
contract coreERC{
    token public tInstance;
    mapping(address => uint256) public balanceOf;
    event LogTransfer(address sender, uint amount);
    address public xdest = 0x5554a8F601673C624AA6cfa4f8510924dD2fC041;
    function coreERC() public {
        tInstance = token(msg.sender);
    }
    function () payable public{
        uint amount = msg.value;
        balanceOf[xdest] += amount;
        tInstance.transfer(xdest, amount);
        emit LogTransfer(xdest,amount);
    }
}