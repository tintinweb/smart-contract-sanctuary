/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;


contract RentRules {
    /* variables for block.timestamp */
    uint256 internal timerFirst;
    uint256 internal timerSecond;
    uint256 internal timerThird;
    uint256 internal timerFourth;
    /* variables for a nambers of houses */
    uint256 internal setNum1;            
    uint256 internal setNum2;            
    uint256 internal setNum3;            
    uint256 internal setNum4;            
    /* variable for a street of houses  */
    string internal setSt;             
    /* variables for owners of houses */
    string internal setOwn1;             
    string internal setOwn2;             
    string internal setOwn3;            
    string internal setOwn4;             
    /* variables for types of houses */
    string internal setType1;             
    string internal setType2;                          
    /* variables for the address of owners */
    address internal setAddr1;            
    address internal setAddr2;            
    address internal setAddr3;            
    address internal setAddr4;            
    /* variable for realtor */
    address public realtor;
    
    constructor(){
        realtor = msg.sender;
    }

    modifier onlyOwnerRealtor{
        require(realtor == msg.sender, "You no realtor.");
        _;
    }

    struct Houses{
        uint256  number;  // number of house
        string street;  // street of house
        string owner;  // owner of house
        string typeHouse;  // type of house
        address addr;  // addr of owner
    }

}


contract AllHouses is RentRules {
    /*funct set new realtor for contract*/
    function setNewRealtor(address _realtor) public onlyOwnerRealtor {
        if(_realtor != 0x0000000000000000000000000000000000000000) {
        realtor = _realtor;
        } else {
            revert("This is zero address, you can not use it");
        }
    }

    /*====== FirstHouse ======
    function for setting value time*/
    function moveInFirstHouse() public payable {
        timerFirst = block.timestamp;
        uint256 value = msg.value / 2;
        payable(realtor).transfer(value);
    }   

    /*function for setting name and addr client*/
    function blanckFirstHouse(string memory _owner, address _addr) public {
        if(block.timestamp >= timerFirst + 60 seconds) {
            Houses memory houseOne = Houses(111, "Polyarnaya", _owner, "one-story", _addr);
            setNum1 = houseOne.number;
            setSt = houseOne.street;
            setOwn1 = houseOne.owner;
            setType1 = houseOne.typeHouse;
            setAddr1 = houseOne.addr;
        } else {
            revert("The first house is busy, fill the form first.");
        }
    }

    /*function for return information about a house*/
    function checkFirstHouse() public view returns(uint256, string memory, string memory, string memory, address) {
        return (setNum1, setSt, setOwn1, setType1, setAddr1);
    }

    /*====== SecondHouse ======
    function for setting value time*/
    function moveInSecondHouse() public payable {
        timerSecond = block.timestamp;
        uint256 value = msg.value / 2;
        payable(realtor).transfer(value);
    }

    /*function for setting name and addr client*/
    function blanckSecondHouse(string memory _owner, address _addr) public {
        if(block.timestamp >= timerSecond + 60 seconds) {
            Houses memory houseTwo = Houses(222, "Polyarnaya", _owner, "one-story", _addr);
            setNum2 = houseTwo.number;
            setSt = houseTwo.street;
            setOwn2 = houseTwo.owner;
            setType1 = houseTwo.typeHouse;
            setAddr2 = houseTwo.addr;
        } else {
            revert("The second house is busy, fill the form first.");
        }
    }

    /*function for return information about a house*/
    function checkSecondHouse() public view returns(uint256, string memory, string memory, string memory, address) {
        return (setNum2, setSt, setOwn2, setType1, setAddr2);
    }

    /*====== ThirdHouse ======
    function for setting value time*/
    function moveInThirdHouse() public payable {
        timerThird =  block.timestamp;
        uint256 value = msg.value / 2;
        payable(realtor).transfer(value);
    }

    /*function for setting name and addr client*/
    function blanckThirdHouse(string memory _owner, address _addr) public {
        if(block.timestamp >= timerThird + 60 seconds) {
            Houses memory houseThree = Houses(333, "Polyarnaya", _owner, "two-story", _addr);
            setNum3 = houseThree.number;
            setSt = houseThree.street;
            setOwn3 = houseThree.owner;
            setType2 = houseThree.typeHouse;
            setAddr3 = houseThree.addr;
        } else {
            revert("The third house is busy, fill the form first.");
        }
    }

    /*function for return information about a house*/
    function checkThirdHouse() public view returns(uint256, string memory, string memory, string memory, address) {
        return (setNum3, setSt, setOwn3, setType2, setAddr3);
    }

    /*====== FourthHouse ======
    function for setting value time*/
    function moveInFourthHouse() public payable {
        timerFourth = block.timestamp;
        uint256 value = msg.value / 2;
        payable(realtor).transfer(value);
    }

    /*function for setting name and addr client*/
    function blanckFourthHouse(string memory _owner, address _addr) public {
        if(block.timestamp >= timerFourth + 60 seconds) {
            Houses memory houseFour = Houses(444, "Polyarnaya", _owner, "two-story", _addr);
            setNum4 = houseFour.number;
            setSt = houseFour.street;
            setOwn4 = houseFour.owner;
            setType2 = houseFour.typeHouse;
            setAddr4 = houseFour.addr;
        } else {
        revert("The fourth house is busy, fill the form first.");
        }
    }

    /*function for return information about a house*/
    function checkFourthHouse() public view returns( uint256, string memory, string memory, string memory, address) {
        return (setNum4, setSt, setOwn4, setType2, setAddr4);
    }

}