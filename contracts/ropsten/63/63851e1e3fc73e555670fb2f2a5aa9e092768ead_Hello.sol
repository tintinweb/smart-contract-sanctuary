pragma solidity ^0.4.25;

contract Hello{
    string private message;
    string private issuer;
    string private company;
    string private product;
    //bytes32 private model_no;
    uint private date_issue;

    constructor(string msg, string iss, string comp, string pro) public {
        message = msg;
        issuer = iss;
        company = comp;
        product = pro;
        date_issue = now;
    }

    function setMsg(string x) public {
        message = x;
    }

    function getMsg() public view returns (string) {
        return message;
    }

    function getIssuer() public view returns (string){
        return issuer;
    }

    function getCompany() public view returns (string){
        return company;
    }

    function getProduct() public view returns (string){
        return product;
    }

    function getDate() public view returns (uint256){
        return date_issue;
    }
}

contract DateTime {
    function getYear(uint timestamp) public returns (uint16);
    function getMonth(uint timestamp) public returns (uint8);
    function getDay(uint timestamp) public returns (uint8);
}