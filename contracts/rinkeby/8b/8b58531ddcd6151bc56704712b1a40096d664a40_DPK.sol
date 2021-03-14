/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity 0.5.8;
contract DPK
{
uint clientsCount = 0;
mapping(string => Client) pending;
mapping(string => Client) clients;
mapping(uint => string) clientsIndex;
string pkmKey;
address public owner = 0x4CC4fAaC995A7FfebEAB56F384bdAD797D56F655;

struct Client{
string identity;
string publicKey;
address clientAddress;
}
function addClient(string memory _identity, string memory _publicKey, string memory _token) public
returns (bool success) {
pending[_token] = Client(_identity, _publicKey, msg.sender);
return true;
}
function approveClient(string memory _token) public returns (bool success){
if(msg.sender == owner){
clients[_token] = Client(pending[_token].identity,
pending[_token].publicKey, pending[_token].clientAddress);
clientsIndex[clientsCount] = _token;
clientsCount++;
return true;
}
return false;
}
function getClient(string memory _identity) view public returns (string memory publicKey) {
for( uint i = clientsCount; i >= 0; i--){
if(sha256(abi.encode(clients[clientsIndex[i]].identity)) == sha256(abi.encode(_identity)))
return clients[clientsIndex[i]].publicKey;
}
return "";
}
function storePKMKey(string memory puk) public returns (bool success){
if(msg.sender == owner){
pkmKey = puk;
return true;
}
}
function getPKMKey() view public returns (string memory) {
return pkmKey;
}
}