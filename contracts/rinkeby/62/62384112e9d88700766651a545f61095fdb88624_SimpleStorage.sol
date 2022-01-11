/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage{
address favoriteAddress = 0xE095940927762921813927a54ECfb451A233bF85;
uint256 public Value = 0;
bool public Mycheck = false;
struct Member{
    uint256 walletID;
    string name;
}
Member[] public _member;
mapping (uint256=>string) public WaletToName;

function AddMemebr(uint256 _wallet, string memory _name) public {
        _member.push(Member(_wallet, _name));
        WaletToName[_wallet] = _name;
}

function ChangeValue(uint256 _newValue) public {
    if (_newValue > 121){
Value = _newValue;
}
}

function GetValue() public view returns (uint256) {
return Value;

}

function ShowMyWalletName(uint _wallet) public returns(string memory){
    Mycheck = false;
    string memory a = WaletToName[_wallet] ;
    if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked("ann"))) {
  Mycheck = true;
}
    return a; //ShowMyWalletAddrs(my_account);
}


function ShowMyWalletAddrs() public view returns (uint){
    address my_account = msg.sender;
    uint my_ether_balance = my_account.balance;
    return my_ether_balance; //ShowMyWalletAddrs(my_account);
}

}