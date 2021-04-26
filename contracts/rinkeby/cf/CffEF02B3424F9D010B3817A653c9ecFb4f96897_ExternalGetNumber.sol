/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.17;

interface GteNumberInterface{
    function getNum() view external returns(uint);
    function changeNumber(uint _newNum) external;
}

contract ExternalGetNumber{
    address public manager;
    GteNumberInterface getNumber;

    function ExternalGetNumber() public{
        manager = msg.sender; 

    }

    modifier restrictedAccess(){
        require(msg.sender == manager);
        _;        
    }

    function setInternalContractAddress(address _contract) external restrictedAccess{
        getNumber = GteNumberInterface(_contract);
    }
    
    function chnageGuessingNumber(uint _num) external restrictedAccess{
        getNumber.changeNumber(_num);
    }
    
    function checkMyGuess(uint _num) external payable returns(bool){
        require(msg.value > 0.01 ether);
        if(_num == getNumber.getNum()){
            msg.sender.transfer(address(this).balance);
            //transfer money
        }
        
        return (_num == getNumber.getNum());
    }
}