/**
 *Submitted for verification at Etherscan.io on 2020-05-01
*/

pragma solidity 0.5.16;


contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 interface paxInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
 }




contract tempDist is owned{

    address public paxTokenAddress;

    uint eligibleCount;
    uint totalDividendAmount;

    function setEligibleCount(uint _eligibleCount) onlyOwner public returns(bool)
    {
        eligibleCount = _eligibleCount;
        return true;
    }

    function setTotalDividendAmount(uint _totalDividendAmount) onlyOwner public returns(bool)
    {
        totalDividendAmount = _totalDividendAmount;
        return true;
    }


    function changePAXaddress(address newPAXaddress) onlyOwner public returns(string memory){
        //if owner makes this 0x0 address, then it will halt all the operation of the contract. This also serves as security feature.
        //so owner can halt it in any problematic situation. Owner can then input correct address to make it all come back to normal.
        paxTokenAddress = newPAXaddress;
        return("PAX address updated successfully");
    }

    function payToUser(address _user) onlyOwner public returns(bool)
    {
        uint amount = totalDividendAmount / eligibleCount;
        require(paxInterface(paxTokenAddress).transfer(_user, amount),"token transfer failed");
    }



}