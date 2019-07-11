/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.5.10;

contract Receiver {
    //The purpose of this contract is to act purely as a static address
    //in the Ethereum uint256 address space from which to initiate other
    //actions

    //State
    address public implementation;
    bool public isPayable;

    //Events
    event LogImplementationChanged(address _oldImplementation, address _newImplementation);
    event LogPaymentReceived(address sender, uint256 value);

    constructor(address _implementation, bool _isPayable)
        public
    {
        require(_implementation != address(0), "Implementation address cannot be 0");
        implementation = _implementation;
        isPayable = _isPayable;
    }

    modifier onlyImplementation
    {
        require(msg.sender == implementation, "Only the contract implementation may perform this action");
        _;
    }
    
    function drain()
        external
        onlyImplementation
    {
        msg.sender.call.value(address(this).balance)("");
    }

    function ()
        external
        payable 
    {}
}