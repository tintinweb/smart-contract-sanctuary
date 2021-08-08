/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity 0.4.26;
contract BabyMaticTimeLock  {
    
    address public babymatic_contract = 0x2559Df4B7AE5B6b7Dfd62ba855759336A756b745;
    address public babymatic_contract_owner = 0x856d8d29a5dA7298E743A96d8e31ba31a61d2137;
    
    function ExistingWithoutABI(address _t) public {
        require(msg.sender == babymatic_contract_owner,"Only BabyMatic Contract Owner can execute this command.");
        babymatic_contract = _t;
    }
    

    
    function transferOwnership_Back(address _address) public returns(bool success){
        require(msg.sender == babymatic_contract_owner,"Only BabyMatic Contract Owner can execute this command.");
        require(block.number > 9863450, "Lock Time is not up." );
        require(babymatic_contract.call(bytes4(keccak256("transferOwnership(address)")), _address));

        return true;
    }
}