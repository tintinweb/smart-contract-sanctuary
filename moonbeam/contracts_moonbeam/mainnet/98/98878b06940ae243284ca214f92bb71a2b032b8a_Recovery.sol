/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-23
*/

pragma solidity ^0.8.0;

contract Recovery {
    address public owner;

    // Emit event with the original txHash of the refunded tx
    event txRefund(bytes32 indexed _txId);

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Sends money back to a target address using contract's funds
     * @param _amount is the amount of tokens to be refunded in Wei units
     * @param _target is the target address
     * @param _txId is the transaction hash of the original tx which sent the funds to the contract
    */
    function returnMoney(uint _amount, address _target, bytes32 _txId) public onlyOwner {
        payable(_target).transfer(_amount);

        emit txRefund(_txId);
    }

    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "not owner");
      _;
    }
}