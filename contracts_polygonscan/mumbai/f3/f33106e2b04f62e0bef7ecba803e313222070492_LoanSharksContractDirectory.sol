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
    Directory[] v_directory;

    //The directory of Loan Sharks socials (web2)
    Socials[] v_socials;

    constructor(){
        _validator = msg.sender;
    }   

    //Public viewer of v_directory
    function directory() public view returns(Directory[] memory){
        return v_directory;
    }   
    
    //Public viwer of v_socials
    function socials() public view returns(Socials[] memory){
        return v_socials;
    }

    //Change Validator
    function change_validator(address new_validator) public onlyValidator{
        _validator = new_validator;
    }

    //Add an element in the directory array
    function add_directory(string memory name, address contract_address) public onlyValidator{
        v_directory.push(
            Directory(
                name,
                contract_address
            )
        );
    }

    //Add an element in the socials array
    function add_social(string memory name, string memory url) public onlyValidator{
        v_socials.push(
            Socials(
                name,
                url
            )
        );
    }

    // Remove an element in the directory array by index
    function burn_directory(uint index) public onlyValidator{
        require(index < v_directory.length);
        v_directory[index] = v_directory[v_directory.length-1];
        v_directory.pop();
    }
    // Remove an element in the socials array by index
    function burn_social(uint index) public onlyValidator{
        require(index < v_socials.length);
        v_socials[index] = v_socials[v_socials.length-1];
        v_socials.pop();
    }


    //Validator modifier for creating voting sessions
    modifier onlyValidator() {
        require(_validator == msg.sender);
        _;
    }
}