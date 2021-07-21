/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

pragma solidity 0.5.1;

contract myContract {
    mapping(address => uint256) public balances;
    address payable wallet;
    
    event Purchase(address indexed _buyer , uint256 _amount);
    constructor(address payable _wallet) public {
        wallet = _wallet;
    }
    
    function() external payable {
        buyToken();
    }
    
    function buyToken() public payable{
        // buy a buyToken
        balances[msg.sender] += 1;
        //send ether to wallet
        wallet.transfer(msg.value);
        emit Purchase(msg.sender,1);
        
    }

}