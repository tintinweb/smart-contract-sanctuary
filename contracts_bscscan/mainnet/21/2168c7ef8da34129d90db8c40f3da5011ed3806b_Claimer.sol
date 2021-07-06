// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ITarget.sol";
import "./IERC20.sol";
import "./ISWAP.sol";
import "./Worker.sol";


contract Claimer {
    address public owner = msg.sender;
    address public bank = msg.sender;

    address public constant pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant wBNBAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    Worker private _worker = new Worker();
    uint256 private gasStart;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier gasWrite {
        gasStart = gasleft();
        _;
    }

    function execute(address addr, uint count) public gasWrite {

        ITarget target = ITarget(addr);
        IERC20 erc20 = IERC20(addr);
        address workerAddr = address(_worker);

        uint j = 0;

        // fix referal reward
        if(erc20.balanceOf(workerAddr) == 0) { 
            _worker.getAirdrop(address(this));

            // the one tick was executed
            j++;
        }

        for(; j < count; j++) {
            target.getAirdrop(workerAddr);
        }
        _worker.collect(addr);

        _withdraw(addr);
    }

    function _withdraw(address addr) private {
        IERC20 erc20 = IERC20(addr);
        uint256 amount = erc20.balanceOf(address(this));
        _swap(addr, amount, address(this));

        uint gasUsed = gasStart - gasleft();
        uint etherUsed = (gasUsed * tx.gasprice) + (0.005 ether);

        require(etherUsed < address(this).balance, "CANCEL");

        payable(bank).transfer(address(this).balance);
    }

    function swap(address contractAddr, uint256 amount, address to) public onlyOwner gasWrite {
        _swap(contractAddr, amount, to);
    }

    function withdraw(address addr) public onlyOwner gasWrite {
        _withdraw(addr);
    }

    function _swap(address contractAddr, uint256 amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        IERC20(contractAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForETH(amount, 1, path, to, 99999999999999999);
    }

    fallback() external payable {}
    receive() external payable {}
}