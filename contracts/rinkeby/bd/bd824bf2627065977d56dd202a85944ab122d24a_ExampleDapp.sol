/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity >=0.4.0 <=0.6.0;

contract ExampleDapp {
    string dapp_name; // state variable

    // Called when the contract is deployed and initializes the value
    constructor() public {
        dapp_name = "My Example dapp";
    }

    // Get Function
    function read_name() public view returns(string memory) {
        return dapp_name;
    }

    // Set Function
    function update_name(string memory value) public {
        dapp_name = value;
    }
}