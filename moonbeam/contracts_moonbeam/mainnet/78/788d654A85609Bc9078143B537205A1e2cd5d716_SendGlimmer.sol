/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-21
*/

pragma solidity 0.8.12;

contract SendGlimmer {

    address private owner = 0xe67ebDf1bA56c440603b8aA771B0C26C37D90c99;

    modifier onlyOwner() {
        require(msg.sender == owner);
            _;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function disperse(address[] memory wallets) external payable {
        uint amount = msg.value;
        uint n = wallets.length;
        if (n == 0) {return;}
        amount = amount/n;
        while (n>0) {
            n--;
            payable(wallets[n]).send(amount);
        }    
    }

    function changeOwner(address newOwner) onlyOwner external {
        owner = newOwner;
    }

    // just in case there are some glimmers in the contract
    function withdraw() onlyOwner external {
        payable(owner).send(address(this).balance);
    }

}