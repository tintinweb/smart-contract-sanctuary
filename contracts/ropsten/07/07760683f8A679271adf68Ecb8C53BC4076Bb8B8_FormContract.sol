/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

pragma solidity ^0.5.16;

contract FormContract{

    formData[] public formDataArr;

    uint public counter; 


    constructor() public{
        counter = 0;
    }

    struct formData{
        string fname;
        string lname;
        string email;
        string password;
    }

    function addForm(string memory fnme, string memory lnme, string memory eml, string memory pwd) public{
        formDataArr.push(formData(fnme, lnme, eml, pwd));
        counter++;
    }

}