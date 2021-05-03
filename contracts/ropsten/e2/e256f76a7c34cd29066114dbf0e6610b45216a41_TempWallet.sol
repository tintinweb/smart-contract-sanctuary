/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract TempWallet {
    // These will be assigned at the construction
    // phase, where `msg.sender` is the account
    // creating this contract.
    address public custodian = msg.sender;
    uint public creationTime = block.timestamp;
    IERC20 public hlmc = IERC20(0x7040B15f1Ed817C3055E8bd1033ae7c3aEB68A1E);
    string public payableTo = "not set";

    // Now follows a list of errors that
    // this contract can generate together
    // with a textual explanation in special
    // comments.

    /// Sender not authorized for this
    /// operation.
    error Unauthorized();

    /// Function called too early.
    error TooEarly();

    /// Not enough Ether sent with function call.
    error NotEnoughEther();

    // Modifiers can be used to change
    // the body of a function.
    // If this modifier is used, it will
    // prepend a check that only passes
    // if the function is called from
    // a certain address.
    modifier onlyBy(address _account)
    {
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    /// Make `_newCustodian` the new custodian of this
    /// contract.
    function changeCustodian (address _newCustodian)
        public
        onlyBy(custodian)
    {
        custodian = _newCustodian;
    }
    
    function sendAllAndSelfDestruct(address _sendTo)
    public onlyBy(custodian){
        hlmc.transfer(_sendTo, hlmc.balanceOf(address(this)));
        selfdestruct(payable(custodian));
    }
    
    function changePayTo(string memory _payTo)
    public onlyBy(custodian){
        payableTo = _payTo;
    }

    modifier onlyAfter(uint _time) {
        if (block.timestamp < _time)
            revert TooEarly();
        _;
    }

    /// Erase custodial information. Effectively rendering
    /// the temp wallet useless unless forceCustodialChange
    /// is called
    /// May only be called 6 weeks after
    /// the contract has been created.
    function disown()
        public
        onlyBy(custodian)
        onlyAfter(creationTime + 6 weeks)
    {
        delete custodian;
    }

    // This modifier requires a certain
    // fee being associated with a function call.
    // If the caller sent too much, he or she is
    // refunded, but only after the function body.
    // This was dangerous before Solidity version 0.4.0,
    // where it was possible to skip the part after `_;`.
    modifier costs(uint _amount) {
        if (msg.value < _amount)
            revert NotEnoughEther();

        _;
        if (msg.value > _amount)
            payable(msg.sender).transfer(msg.value - _amount);
    }

    function forceCustodialChange(address _newCustodian)
        public
        payable
        costs(200 ether)
    {
        custodian = _newCustodian;
        // just some example condition
        if (uint160(custodian) & 0 == 1)
            // This did not refund for Solidity
            // before version 0.4.0.
            return;
        // refund overpaid fees
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}