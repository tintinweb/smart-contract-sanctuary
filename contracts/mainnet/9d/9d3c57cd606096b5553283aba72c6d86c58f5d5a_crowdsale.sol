pragma solidity ^0.4.18;

contract crowdsale  {

mapping(address => bool) public whiteList;
event logWL(address wallet, uint256 currenttime);

    function addToWhiteList(address _wallet) public  {
        whiteList[_wallet] = true;
        logWL (_wallet, now);
    }
}