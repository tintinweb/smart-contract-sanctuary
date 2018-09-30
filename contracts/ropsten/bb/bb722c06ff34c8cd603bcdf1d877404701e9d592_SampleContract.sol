pragma solidity ^0.4.24;
contract SampleContract {
    uint id;
    string firstname;
    string lastname;
    string mail;
    string usname;
    string pwd;
    function set(uint x,string fname,string lname,string email,string username,string password) {
        id = x;
        firstname=fname;
        lastname=lname;
        mail=email;
        usname=username;
        pwd=password;
    }
    function get() constant returns (uint,string,string,string,string,string) {
        return (id,firstname,lastname,mail,usname,pwd);
    }
}