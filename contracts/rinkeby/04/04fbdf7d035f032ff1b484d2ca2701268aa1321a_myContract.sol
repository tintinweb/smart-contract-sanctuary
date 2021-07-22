/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity >=0.5.1;

contract myContract {
    mapping(address => uint256) public balances;
    address payable wallet;
    
    function buyToken(address payable _wallet) public payable {
        wallet = _wallet;
        // buy a buyToken
        balances[msg.sender] += 1;
        //send ether to wallet
        _wallet.transfer(3 ether);
    }
    
    function balanceOfSender() public view returns(uint){
        return address(msg.sender).balance;
    }
    
    function balanceOfRecipient() public view returns(uint){
        return address(wallet).balance;
    }

}