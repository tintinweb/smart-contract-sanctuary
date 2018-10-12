pragma solidity ^0.4.25;
// https://www.youtube.com/channel/UCfCIlNwVtwcEn_Qscyhld_g/featured?view_as=subscriber
contract NOTBAD {
    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    function () external payable
{
        if (invested[msg.sender] != 0) {
            uint256 amount = invested[msg.sender] * (address(this).balance / (invested[msg.sender] * 100 )) / 100 * (block.number - atBlock[msg.sender]) / 6100;
            msg.sender.transfer(amount);
        }
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}