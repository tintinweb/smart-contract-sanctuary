/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-03-21
*/

pragma solidity 0.8.12;

contract SendGlimmer {

    address private owner = 0x23648C3f4187680A290a2461a82fa96A1c8B606A;

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