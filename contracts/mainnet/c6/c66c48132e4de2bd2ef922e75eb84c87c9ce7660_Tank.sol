pragma solidity ^0.4.24;


contract owned {
    constructor() public { owner = msg.sender; }

    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
}


contract Tank is owned {

    function () payable public {}

    function withdrawEther(address toAddress, uint256 amount) public onlyOwner {
        toAddress.transfer(amount);
    }

    function withdrawToken(address token, address toAddress, uint256 amount) public onlyOwner {
        ERC20(token).transfer(toAddress, amount);
    }

    function withdrawInBatch(address[] tokenList, address[] toAddressList, uint256[] amountList) public onlyOwner {
        require(tokenList.length == toAddressList.length);
        require(toAddressList.length == amountList.length);

        for (uint i = 0; i < toAddressList.length; i++) {
            if (tokenList[i] == 0) {
                this.withdrawEther(toAddressList[i], amountList[i]);
            } else {
                this.withdrawToken(tokenList[i], toAddressList[i], amountList[i]);
            }
        }
    }

    function withdrawEtherInBatch(address[] toAddressList, uint256[] amountList) public onlyOwner {
        require(toAddressList.length == amountList.length);

        for (uint i = 0; i < toAddressList.length; i++) {
            this.withdrawEther(toAddressList[i], amountList[i]);
        }
    }
}