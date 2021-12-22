// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./NODERewardManagement.sol";
import "./PaymentSplitter.sol";
import "./IERC20.sol";
import "./IJoeFactory.sol";
import "./ERC20.sol";
import "./IJoeRouter02.sol";


pragma solidity ^0.8.0;

contract Thor is ERC20, PaymentSplitter {
    using SafeMath for uint256;

    NODERewardManagement public nodeRewardManager;

    IJoeRouter02 public uniswapV2Router;

    address public uniswapV2Pair;
    address public futurUsePool;
    address public distributionPool;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public futurFee;
    uint256 public totalFees;

    uint256 public cashoutFee;

    uint256 public rwSwap;
    bool public swapping = false;
    bool public swapLiquify = true;
    uint256 public swapTokensAmount;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable Error: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity
    );

    constructor(address[] memory payees, uint256[] memory shares, address[] memory addresses, uint256[] memory balances,
        uint256[] memory fees, uint256 swapAmount,address uniV2Router, address gateway) ERC20("Versus", "$Versus") PaymentSplitter(payees, shares) {
        
        _owner = gateway;
        emit OwnershipTransferred(address(0), _owner);

        futurUsePool = addresses[4];
        distributionPool = addresses[5];

        require(futurUsePool != address(0) && distributionPool != address(0), "F&RAZ");

        require(uniV2Router != address(0), "RZ");
        IJoeRouter02 _uniswapV2Router = IJoeRouter02(uniV2Router);

        address _uniswapV2Pair = IJoeFactory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WAVAX());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        require(fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,"F0");
        futurFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];
        rwSwap = fees[4];

        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);

        require(addresses.length > 0 && balances.length > 0, "ALZ");
        require(addresses.length == balances.length, "ALU");

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], balances[i] * (10**18));
        }
        require(totalSupply() == 20456743e18, "TE20");
        require(swapAmount > 0, "SAI");
        swapTokensAmount = swapAmount * (10**18);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)public onlyOwner
    {
        require(pair != uniswapV2Pair,"PAA");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "AAS");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialETHBalance);
        payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WAVAX();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,0, path, address(this),block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityAVAX{value: ethAmount}(
            address(this),tokenAmount, 0,0,address(0),block.timestamp
        );
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagement(nodeManagement);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RHA");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IJoeRouter02(newAddress);
        address _uniswapV2Pair = IJoeFactory(uniswapV2Router.factory())
        .createPair(address(this), uniswapV2Router.WAVAX());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function blacklistMalicious(address account, bool value)external onlyOwner
    {
        _isBlacklisted[account] = value;
    }


    function _transfer(address from, address to,uint256 amount) internal override {
        require(from != address(0), "TFZ");
        require(to != address(0), "TTZ");
        require(!_isBlacklisted[from] && !_isBlacklisted[to],"Blacklisted address");

        super._transfer(from, to, amount);
    }

    function createNodeWithTokens(string memory name) public {
        require(bytes(name).length > 3 && bytes(name).length < 32, "NSI");
        address sender = _msgSender();
        require(sender != address(0),"CFZ");
        require(!_isBlacklisted[sender], "BA");
        require(sender != futurUsePool && sender != distributionPool,"FRCCN");
        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(balanceOf(sender) >= nodePrice,"BTL");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (swapAmountOk && swapLiquify &&!swapping &&sender != owner() &&!automatedMarketMakerPairs[sender]
        ) {
            swapping = true;
            uint256 futurTokens = contractTokenBalance.mul(futurFee).div(100);
            swapAndSendToFee(futurUsePool, futurTokens);
            uint256 rewardsPoolTokens = contractTokenBalance.mul(rewardsFee).div(100);
            uint256 rewardsTokenstoSwap = rewardsPoolTokens.mul(rwSwap).div(100);
            swapAndSendToFee(distributionPool, rewardsTokenstoSwap);
            super._transfer(address(this), distributionPool, rewardsPoolTokens.sub(rewardsTokenstoSwap));
            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(100);
            swapAndLiquify(swapTokens);
            swapTokensForEth(balanceOf(address(this)));
            swapping = false;
        }
        super._transfer(sender, address(this), nodePrice);
        nodeRewardManager.createNode(sender, name);
    }
    function boostReward(uint amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function getNodeNumberOf(address account) public view returns (uint256) {
        return nodeRewardManager._getNodeNumberOf(account);
    }
    function cashoutReward(uint256 blocktime) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT");
        require(!_isBlacklisted[sender], "CSHTB");
        require(sender != futurUsePool && sender != distributionPool,"CSHTFR");
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(sender,blocktime);
        require(rewardAmount > 0,"CSHTR");

        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {feeAmount = rewardAmount.mul(cashoutFee).div(100);swapAndSendToFee(futurUsePool, feeAmount);}
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutNodeReward(sender, blocktime);
    }

    function cashoutAll() public {
        address sender = _msgSender();
        require(sender != address(0),"MANIACSHTZ");
        require(!_isBlacklisted[sender], "MANIACSHTB");
        require(sender != futurUsePool && sender != distributionPool,"MANIACSHTF");
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(sender);
        require(rewardAmount > 0,"MANIACSHTR");
        if (swapLiquify) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(futurUsePool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(distributionPool, sender, rewardAmount);
        nodeRewardManager._cashoutAllNodesReward(sender);
    }

    

    function getRewardAmountOf(address account) public view onlyOwner returns (uint256)
    {
        return nodeRewardManager._getRewardAmountOf(account);
    }

    function getRewardAmount() public view returns (uint256) {
        require(_msgSender() != address(0), "SZ");
        require(nodeRewardManager._isNodeOwner(_msgSender()),"NNO");
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }

    function changeNodePrice(uint256 newNodePrice) public onlyOwner {
        nodeRewardManager._changeNodePrice(newNodePrice);
    }

    function getNodePrice() public view returns (uint256) {
        return nodeRewardManager.nodePrice();
    }

    function changeRewardPerNode(uint256 newPrice) public onlyOwner {
        nodeRewardManager._changeRewardPerNode(newPrice);
    }

    function getRewardPerNode() public view returns (uint256) {
        return nodeRewardManager.rewardPerNode();
    }

    function changeClaimTime(uint256 newTime) public onlyOwner {
        nodeRewardManager._changeClaimTime(newTime);
    }

    function getClaimTime() public view returns (uint256) {
        return nodeRewardManager.claimTime();
    }

    function changeAutoDistri(bool newMode) public onlyOwner {
        nodeRewardManager._changeAutoDistri(newMode);
    }






function getAutoDistri() public view returns (bool) {
        return nodeRewardManager.autoDistri();
    }

    function changeGasDistri(uint256 newGasDistri) public onlyOwner {
        nodeRewardManager._changeGasDistri(newGasDistri);
    }

    function getGasDistri() public view returns (uint256) {
        return nodeRewardManager.gasForDistribution();
    }

    function getDistriCount() public view returns (uint256) {
        return nodeRewardManager.lastDistributionCount();
    }

    function getNodesNames() public view returns (string memory) {
        require(_msgSender() != address(0), "SCBZ");
        require(nodeRewardManager._isNodeOwner(_msgSender()),"NNO");
        return nodeRewardManager._getNodesNames(_msgSender());
    }

    function getNodesCreatime() public view returns (string memory) {
        require(_msgSender() != address(0), "SCBZ");
        require(nodeRewardManager._isNodeOwner(_msgSender()),"NNO");
        return nodeRewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesRewards() public view returns (string memory) {
        require(_msgSender() != address(0), "SCBZ");
        require(nodeRewardManager._isNodeOwner(_msgSender()),"NNO");
        return nodeRewardManager._getNodesRewardAvailable(_msgSender());
    }

    function getNodesLastClaims() public view returns (string memory) {
        require(_msgSender() != address(0), "SCBZ");
        require(nodeRewardManager._isNodeOwner(_msgSender()),"NNO");
        return nodeRewardManager._getNodesLastClaimTime(_msgSender());
    }

    function distributeRewards() public  onlyOwner returns (uint256, uint256, uint256)
    {
        return nodeRewardManager._distributeRewards();
    }

    function publiDistriRewards() public {
        nodeRewardManager._distributeRewards();
    }

    function getTotalStakedReward() public view returns (uint256) {
        return nodeRewardManager.totalRewardStaked();
    }

    function getTotalCreatedNodes() public view returns (uint256) {
        return nodeRewardManager.totalNodesCreated();
    }
}