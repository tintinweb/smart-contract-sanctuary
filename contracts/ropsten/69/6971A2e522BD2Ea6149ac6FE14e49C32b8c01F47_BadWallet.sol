/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BadWallet{
    address private owner;
    //event Log(uint gas);

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    function Unprotected()
    public
    {
        owner = msg.sender;
    }
    
    function destroy(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }
    
    function changeOwner (address _newOwner)
    public
    {
        owner = _newOwner;
    }

    function changeOwner_fixed(address _newOwner)
    public
    onlyowner
    {
        owner = _newOwner;
    }

    fallback() external payable {
        // emit Log(gasleft());
        }
    receive() external payable {
            // React to receiving ether
        }
}