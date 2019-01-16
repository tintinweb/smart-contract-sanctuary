pragma solidity ^0.4.18;
contract naga_boom  {
    
    address dc=0xa5c73a8364032de753ae96afc7b10c53b2c45d50;
    
    function settte(uint256 _amount,address _to) public returns(bool success){
        require(dc.call(bytes4(keccak256("transfer(address, uint256)")),_to,_amount));
        return true;
    }
}