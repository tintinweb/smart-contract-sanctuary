/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

pragma solidity ^0.8.0;
interface Pepefactory{
        function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external  ;
}
contract BatchMinter{
    address constant owner = 0x9615c6684686572D77D38d5e25Bc58472560E22C;
    address pepe = 0x7BC2c1B1a0C56Eb34F18f81584A229698D7BEaA1;
    function setPepefactory(address x) external{
        require(msg.sender == owner);
        pepe = x;
    }
    function batchMint(uint start, uint end, address to) external{
        require(msg.sender == owner);
        for (uint i = start; i <= end; i++){
            Pepefactory(pepe).mint(to, i, 1, hex'');
        }
    }
    function kill() external{
        require(owner == msg.sender);
        selfdestruct(payable(owner));
    }
}