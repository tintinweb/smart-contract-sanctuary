/**
 *Submitted for verification at BscScan.com on 2020-09-14
*/

pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract BatchTransfer {
    mapping(uint256 => bool) public idContract;
    function disperseToken(IERC20 token, uint256 _idContract, address[] memory recipients, uint256[] memory values) external {
        require(!idContract[_idContract], "ID used");
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++){
            total += values[i];
        }    
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 j = 0; j < recipients.length; j++){
            require(token.transfer(recipients[j], values[j]));
        }        
        idContract[_idContract] = true;
    }
}