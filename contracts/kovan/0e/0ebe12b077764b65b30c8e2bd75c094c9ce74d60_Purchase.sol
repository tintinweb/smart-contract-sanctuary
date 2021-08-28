/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity 0.6.12;

interface IERC721 {
    function mint(address _to, uint256 _projectId, address _by) external;
}

contract Purchase{
    address  address_;
    constructor(address _address) public{
        address_=_address;
    }
    function purchase(uint256 _projectId)  external {
        address to = msg.sender;
        address _by = address(0x00);
        IERC721(address_).mint(to,_projectId,_by);
    }
}