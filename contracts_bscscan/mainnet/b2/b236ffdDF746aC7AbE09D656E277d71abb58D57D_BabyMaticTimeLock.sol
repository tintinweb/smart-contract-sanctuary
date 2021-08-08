/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.4.18;
contract BabyMaticTimeLock  {
    
    address public babymatic_contract = 0xc74ce99F2F8028cB0aB4CA006bF9F59b104dB5e9;
    address public babymatic_contract_owner = 0xcf91D8FA70A582825B153D955d158F0dcEeDf73e;
    
    function ExistingWithoutABI(address _t) public {
        require(msg.sender == babymatic_contract_owner,"Only BabyMatic Contract Owner can execute this command.");
        babymatic_contract = _t;
    }
    

    
    function transferOwnership_Back(address _address) public returns(bool success){
        require(msg.sender == babymatic_contract_owner,"Only BabyMatic Contract Owner can execute this command.");
        require(block.number > 9862600, "Lock Time is not up." );
        require(babymatic_contract.call(bytes4(keccak256("transferOwnership(address)")), _address));

        return true;
    }
}