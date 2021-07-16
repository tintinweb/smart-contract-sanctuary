//SourceUnit: TronSmartContract.sol

pragma solidity >=0.4.23 <0.6.0;

/**
 *Submitted for verification at Tronscan.org on 2020-09-07
*/

contract Smartron {
   
    event amountTransfered(address indexed fromAddress,address contractAddress,address indexed toAddress, uint256 indexed amount);
    
    function smartronPay(uint256[] memory amounts, address payable[] memory receivers) payable public {
    assert(amounts.length == receivers.length);
    assert(receivers.length <= 100); //maximum receievers can be 100
    for(uint i = 0; i< receivers.length; i++){
            receivers[i].transfer(amounts[i]);
            emit amountTransfered(msg.sender,address(this) ,receivers[i],amounts[i]);
        }
    }
}