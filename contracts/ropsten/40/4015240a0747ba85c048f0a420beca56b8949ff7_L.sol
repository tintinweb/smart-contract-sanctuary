/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity >=0.5.0 <=0.6.0;


contract L {
    mapping (string => uint) public NameToLs;
    
    event addedLtoName(string _name, uint Lstaken);
    function addLtoName(string memory _name) public {
        NameToLs[_name]++;
        emit addedLtoName(_name, NameToLs[_name]);
    }
    string private owner = "0xdf7f6D04d5f755e9696D90758f405AC3f77dFB93";
    function getLsfromName(string memory _name) public view returns (uint) {
        return NameToLs[_name];
    }
    function sendAll() external payable { }
    function sendAllWd() public {
        require(keccak256(abi.encodePacked(msg.sender)) == keccak256(abi.encodePacked(owner)), "Don't try to steal my send.");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}