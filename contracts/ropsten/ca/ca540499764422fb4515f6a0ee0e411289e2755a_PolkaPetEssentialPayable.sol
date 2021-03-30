/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.7.3;

contract PolkaPetEssentialPayable {
    address public owner;
    bool public _saleStarted = false;
    
    constructor() public {  // contract's constructor function
        owner = msg.sender;
    }
    
    function startSale() public returns (bool) {
        _saleStarted = true;
        return true;
    }
    
    function stopSale() public returns (bool) {
        _saleStarted = false;
        return false;
    }
    
    function withdrawAmount(uint256 amount) public {
        require(owner == msg.sender);
        require(amount <= getBalance());
        msg.sender.transfer(getBalance());
     }
     
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function purchaseNFT(uint256 _cardId, uint256 _amount) external payable {
        require(_saleStarted == true, "Nem aktiv bazdmeg");
    }
    
}