pragma solidity ^0.4.0;
contract SplitIncomes {
    mapping(address => uint256) withdrawn;
    mapping(address => bool) inShares;
    uint256 totalWithdrawn;
    uint256 SharesCount;

    constructor(address[] addresses) public {
        SharesCount = addresses.length;

        for (uint i = 0; i < SharesCount; i++) {
            inShares[addresses[i]] = true;
        }
    }

    function () public payable {}

    function balance() public view returns (uint256) {
        if (!inShares[msg.sender]) {
            return 0;
        }

        return (address(this).balance + totalWithdrawn) / SharesCount - withdrawn[msg.sender];
    }

    function withdraw() public {
        require(inShares[msg.sender]);
        uint256 available = balance();
        if (available > 0) {
            withdrawn[msg.sender] += available;
            totalWithdrawn += available;
            msg.sender.transfer(available);
        }
    }
}