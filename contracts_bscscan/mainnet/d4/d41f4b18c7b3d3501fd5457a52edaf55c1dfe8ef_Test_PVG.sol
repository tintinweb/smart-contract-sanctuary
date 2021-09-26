// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.12;
import "./ReentrancyGuard.sol";
import "./BEP20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./BPContract.sol";

contract Test_PVG is BEP20, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    bool public bpEnabled;
    uint256 public maxSupply =  20000000000000000000000000;
    uint256 public minSweep =   200000000000000000000;
    uint256 public buyOperationFee = 1;
    uint256 public buyRewardFee = 2;
    uint256 public Fee = 1;
    uint256 public sellRewardFee = 2;
    BPContract public BP;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public poolRewardAddress;
    address public poolAirdropAddress;


    mapping(address => bool) private _excludeFromFee;
    bool isSwapping = false;
    constructor(string memory _name, string memory _symbol, address _poolRewardAddress) BEP20(_name, _symbol) {
        _mint(_msgSender(), maxSupply);
        poolRewardAddress = _poolRewardAddress;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    function setBpAddress(address _bp) external onlyOwner {
        require(address(BP) == address(0), "Error!");
        BP = BPContract(_bp);
    }
    function setBpEnabled(bool _enabled) external onlyOwner {
        require(address(BP) != address(0), "Error!");
        bpEnabled = _enabled;
    }

    function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {
        if (bpEnabled) {
            BP.protect(sender, recipient, amount);
        }
        if(amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }
        if(
            sender != owner() && recipient != owner()
            && sender != address(this) && recipient != address(this)
            && _excludeFromFee[sender] != true && _excludeFromFee[recipient] != true
            && sender != poolRewardAddress && recipient != poolRewardAddress
            && isSwapping == false
            &&(recipient == uniswapV2Pair || sender == uniswapV2Pair)
        ){
            isSwapping = true;
            uint256 _rewardFee;
            uint256 _operationFee;
            if(recipient == uniswapV2Pair){
                _rewardFee = amount.mul(sellRewardFee).div(100);
                _operationFee = amount.mul(Fee).div(100);
            } else {
                _rewardFee = amount.mul(buyRewardFee).div(100);
                _operationFee = amount.mul(buyOperationFee).div(100);
            }
            if(_rewardFee > 0 && _operationFee > 0){
                amount = amount.sub(_rewardFee.add(_operationFee));
                super._transfer(sender, poolRewardAddress, _rewardFee);
                super._transfer(sender, address(this), _operationFee);
            }
            if(recipient == uniswapV2Pair)
                sweepTokenForOperation();
            isSwapping = false;
        }
        super._transfer(sender, recipient, amount);
    }
    function setBuyFee(uint256 operationFee, uint256 rewardFee) external onlyOwner {
        buyOperationFee = operationFee;
        buyRewardFee = rewardFee;
    }
    function setFee(uint256 operationFee, uint256 rewardFee) external onlyOwner {
        Fee = operationFee;
        sellRewardFee = rewardFee;
    }
    function setMinSweep(uint256 _minSweep) external onlyOwner {
        minSweep = _minSweep;
    }
    function sweepTokenForOperation()  public nonReentrant {
        uint256 contractTokenBalance = balanceOf(address(this));
        if( contractTokenBalance >= minSweep)
            swapTokensForEth(contractTokenBalance);
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            owner(), 
            block.timestamp
        );
    }
    function addExcludeFromFee( address[] memory users) external onlyOwner {
        if(users.length == 1) {
        _excludeFromFee[users[0]] = true;
        } else {
            for(uint256 i = 0; i<users.length; i++) {
                _excludeFromFee[users[i]] = true;
            }
        }
    }
    function removeExcludeFromFee( address[] memory users) external onlyOwner {
        if(users.length == 1) {
        _excludeFromFee[users[0]] = false;
        } else {
            for(uint256 i = 0; i<users.length; i++) {
                _excludeFromFee[users[i]] = false;
            }
        }
    }
    function setPoolRewardAddress(address _poolRewardAddress) external onlyOwner{
        poolRewardAddress = _poolRewardAddress;
    }
    function setPoolAirdropAddress(address _poolAirdropAddress) external onlyOwner{
        poolAirdropAddress = _poolAirdropAddress;
    }
    
    receive() external payable {
    }
}