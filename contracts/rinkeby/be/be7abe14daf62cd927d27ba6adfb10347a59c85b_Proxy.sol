/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.
contract Proxy {

    address delegate =0x9c4526ABfB99c570208D540397FAcA892186C92e;
    address owner = msg.sender;

    function upgradeDelegate(address newDelegateAddress) public {
        require(msg.sender == owner);
        delegate = newDelegateAddress;
    }

    function() external payable {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}