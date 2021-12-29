/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract LoanSharksContractDirectory{
    //Naming struct for directory
    struct Directory{
        string name;
        address contract_address;
    }

    //Naming struct for socials
    struct Socials{
        string name;
        string url;
    }

    //Validator modifies directory
    address _validator;

    //The directory of Loan Sharks contracts (web3)
    Directory[] public directory;

    //The directory of Loan Sharks socials (web2)
    Socials[] public socials;

    constructor(){
        _validator = msg.sender;
    }   

    //Change Validator
    function change_validator(address new_validator) public onlyValidator{
        _validator = new_validator;
    }

    //Add an element in the directory array
    function add_directory(string memory name, address contract_address) public onlyValidator{
        directory.push(
            Directory(
                name,
                contract_address
            )
        );
    }

    //Add an element in the socials array
    function add_social(string memory name, string memory url) public onlyValidator{
        socials.push(
            Socials(
                name,
                url
            )
        );
    }

    // Remove an element in the directory array by index
    function burn_directory(uint index) public onlyValidator{
        require(index < directory.length);
        directory[index] = directory[directory.length-1];
        directory.pop();
    }
    // Remove an element in the socials array by index
    function burn_social(uint index) public onlyValidator{
        require(index < socials.length);
        socials[index] = socials[socials.length-1];
        socials.pop();
    }


    //Validator modifier for creating voting sessions
    modifier onlyValidator() {
        require(_validator == msg.sender);
        _;
    }
}