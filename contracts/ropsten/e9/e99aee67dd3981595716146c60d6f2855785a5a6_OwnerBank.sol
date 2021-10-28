/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity 0.8.2;

contract OwnerBank {
    /** @dev store the actual numbers of deposit */
    uint private depositCount;
    /** @dev store the timestamp of the first deposit */
    uint private timestampFirst;
    /** @notice store the address of contract owner */
    address public owner;
    /** @dev history of deposit, indexing a depositID to the amount of this deposit
             depositCount is used as depositID in 'receive()' */
    mapping (uint => uint) private fundHistory;

    /** @notice verify if the sender address is the owner of contract */
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner of contract");
        _;
    }

    /** @notice construct the contract with an owner */
    constructor(address _owner) {
        require(_owner != address(0), "Owner can't be address 0");
        owner = _owner;
    }

    /** @notice send an 'amount' of contract funds on the owner address
        @param amount the amount in wei */
    function withdrawFunds(uint amount) public onlyOwner(){
        require (amount > 0);
        require (address(this).balance >= amount, "not enough liquidity in bank");
        require ((block.timestamp - timestampFirst) / 60 / 60 / 24 >= 90, "You need to wait 3 months since first deposit");
        
        payable(owner).transfer(amount);
        
        emit onWithdraw(amount, block.timestamp);
    }

    /** @notice receive ethers and add an history of this deposit in 'fundHistory' */
    receive() external payable {
        depositCount++;
        if(depositCount == 1){
            //to be able to calculate time since first deposit
            timestampFirst = block.timestamp;
        }

        fundHistory[depositCount] = msg.value;
        emit onDeposit(msg.value, block.timestamp);
    }

    event onWithdraw(uint amount, uint timestamp);
    event onDeposit(uint amount, uint timestamp);
}