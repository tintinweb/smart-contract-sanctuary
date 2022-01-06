// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloWorld{
    string data;
    event Change(
        address _from,
        string _value
    );

    function update(string memory _string) public{
        data=_string;
        emit Change(msg.sender, data);
    }

    function get() public view returns(string memory){
        return data;
    }
}