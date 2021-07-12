// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./GasReward.sol";

interface Target {
    function getAirdrop(address _refer) external returns (bool success);
    function getAirdrop2(address _refer) external returns (bool success);
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

    function getAirdrop(address contractAddr) public {
        Target(contractAddr).getAirdrop(owner);
        Target(contractAddr).getAirdrop2(owner);
    }

}

contract UniqueWorker {
    address public owner = msg.sender;

    function execute(Target target, IERC20 erc20) public {
        target.getAirdrop(owner);
        target.getAirdrop2(owner);

        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(owner, balance);
    }
}

contract Claim is ERC20, GasReward {
    address public pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public wBNBAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint public claimCount = 256;
    address public claimAddress = address(0);
    uint256 public claimReward = 0;
    bool public claimUnique = false;

    address public bankAddress = msg.sender;

    uint256 public tokenPrice = 50000000000000;

    Worker public worker = new Worker();

    UniqueWorker[] public uworkers;
    mapping(address => uint) uworkersIndex;

    function buy() public payable returns (uint256 count) {
        require(tokenPrice != 0, "Claim: buy function is disabled");
        require(msg.value >= tokenPrice, "Claim: value can't zero");
        count = (msg.value / tokenPrice) * (10 ** decimals());
        _mint(msg.sender, count);
        collectEth();
    }

    function getAirdropWithBuy(uint256 count, address contractAddr, bool swap) public payable {
        buy();
        getAirdrop(count, contractAddr, swap);
    }

    function getAirdropWithBuy2(uint256 count, address contractAddr, bool swap) public payable {
        buy();
        getAirdrop2(count, contractAddr, swap);
    }

    function getAirdropUniqueWithBuy(uint256 count, address contractAddr, bool swap) public payable {
        buy();
        getAirdropUnique(count, contractAddr, swap);
    }

    function getAirdrop(uint256 count, address contractAddr, bool swap) public {
        _payAirdrop(msg.sender, count);
        _execute(count, contractAddr);
        _withdrawAirdrop(contractAddr, swap);
    }
    function getAirdrop2(uint256 count, address contractAddr, bool swap) public {
        _payAirdrop(msg.sender, count);
        _execute(count, contractAddr);
        _withdrawAirdrop(contractAddr, swap);
    }
    function execute(uint count, address contractAddr) public onlyOwner {
        _execute(count, contractAddr);
    }

    function getAirdropUnique(uint256 count, address contractAddr, bool swap) public {
        _payAirdrop(msg.sender, count);
        _executeUnique(count, contractAddr);
        _withdrawAirdrop(contractAddr, swap);
    }

    function collect(address contractAddr) public {
        worker.collect(contractAddr);
        IERC20(contractAddr).transfer(bankAddress, IERC20(contractAddr).balanceOf(address(this)));
    }

    function collectEth() public {
        worker.collectEth();
        payable(bankAddress).transfer(address(this).balance);
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(balanceOf(newOwner) != 0);
        owner = newOwner;
    }

    function setBankAddress(address newBankAddress) public onlyOwner {
        require(newBankAddress != address(0));
        bankAddress = newBankAddress;
    }

    function setTokenPrice(uint256 newTokenPrice) public onlyOwner {
        tokenPrice = newTokenPrice;
    }

    function setPancakeRouter(address newPancakeRouter) public onlyOwner {
        pancakeRouter = newPancakeRouter;
    }

    function setWBNB(address newWBNB) public onlyOwner {
        wBNBAddr = newWBNB;
    }

    function setClaim(uint count, address contractAddr, uint256 reward, bool uniqueCall) public onlyOwner {
        claimCount = count;
        claimAddress = contractAddr;
        claimReward = reward;
        claimUnique = uniqueCall;
    }

    function claim() public {
        require(claimAddress != address(0));
        if(claimUnique) {
            _executeUnique(claimCount, claimAddress);
        } else {
            _execute(claimCount, claimAddress);
        }
        uint256 balance = IERC20(claimAddress).balanceOf(address(this));
        _swap(claimAddress, balance, bankAddress);
        _mint(msg.sender, claimReward);
    }

    function _withdrawAirdrop(address contractAddr, bool swap) private {
        IERC20 erc20 = IERC20(contractAddr);
        uint256 amount = erc20.balanceOf(address(this));
        if(swap) {
            _swap(contractAddr, amount, msg.sender);
        } else {
            erc20.transfer(msg.sender, amount);
        }
        collectEth();
    }

    function _createNewUniqueWorker() private returns (uint) {
        uworkers.push(new UniqueWorker());
        return uworkers.length - 1;
    }

    function getUniqueWorkersCount() public view returns (uint) {
        return uworkers.length;
    }

    function getUniqueWorkersIndexAt(address addr) public view returns (uint) {
        return uworkersIndex[addr];
    }

    function getUniqueWorkerIndex(address addr) public returns (uint index) {
        if(uworkers.length <= uworkersIndex[addr]) {
            _createNewUniqueWorker();
        }

        index = uworkersIndex[addr];
        uworkersIndex[addr] += 1;
    }

    function _execute(uint256 count, address contractAddr) private {
        gasRewardStart();
        Target target = Target(contractAddr);
        IERC20 erc20 = IERC20(contractAddr);
        address workerAddr = address(worker);

        uint j = 0;

        // fix referal reward
        if(erc20.balanceOf(workerAddr) == 0) { 
            worker.getAirdrop(contractAddr);

            // the one tick was executed
            j++;
        }

        for(; j < count; j++) {
            target.getAirdrop(workerAddr);
        }
                for(; j < count; j++) {
            target.getAirdrop2(workerAddr);
        }
        worker.collect(contractAddr);
        uint gasUsed = gasRewardEnd();
        _gasReward(msg.sender, gasUsed);
    }

    function _executeUnique(uint256 count, address contractAddr) private {
        gasRewardStart();
        Target target = Target(contractAddr);
        IERC20 erc20 = IERC20(contractAddr);

        for(uint i = 0; i < count; i++) {
            uint index = getUniqueWorkerIndex(contractAddr);
            uworkers[index].execute(target, erc20);
        }

        uint gasUsed = gasRewardEnd();
        _gasReward(msg.sender, gasUsed);
    }

    function _gasReward(address sender, uint gasUsed) private {
        uint count = (((gasUsed * tx.gasprice) / tokenPrice) * (10 ** decimals())) / 10;
        _mint(sender, count);
    }

    function _swap(address contractAddr, uint256 amount, address to) private {
        address[] memory path = new address[](2);
        path[0] = contractAddr;
        path[1] = wBNBAddr;
        IERC20(contractAddr).approve(pancakeRouter, amount);
        ISWAP(pancakeRouter).swapExactTokensForETH(amount, 1, path, to, 99999999999999999);
    }

    function _payAirdrop(address sender, uint count) private {
        uint256 amount = _calcAmountFromCount(count);
        if(sender != owner) {
            _burn(msg.sender, amount);
        }
    }

    function _calcAmountFromCount(uint count) private view returns (uint) {
        return count * (10 ** decimals());
    }

    receive() external payable {}
}