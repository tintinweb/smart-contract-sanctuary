/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// File: contracts/interface/farm/IFarmPool.sol

pragma solidity ^0.5.16;

interface IFarmPool {
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

// File: contracts/interface/farm/IFarmVault.sol

pragma solidity ^0.5.16;

interface IFarmVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);
    function underlying() external view returns (address);
    function underlyingUnit() external view returns(uint256);
    function deposit(uint256 amountWei) external;
    function withdraw(uint256 numberOfShares) external;
    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

}

// File: contracts/interface/gof/IController.sol

pragma solidity ^0.5.16;

interface IController {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
}

// File: contracts/interface/gof/GOFStrategy.sol

pragma solidity ^0.5.16;

interface GOFStrategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
}

// File: contracts/interface/uniswap/IUniswapRouter.sol

pragma solidity ^0.5.16;

interface IUniswapRouter {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

// File: contracts/V2/StrategyFarm.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;






interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function name() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract StrategyFarm is GOFStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    address public want ;
    address constant public output = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    address constant public unirouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 
    address constant public gof = address(0x488E0369f9BC5C40C002eA7c1fe4fd01A198801c);

    address public farmVault;
    address public farmPool;

    
    uint public burnfee = 400;
    uint public fee = 100;
    uint public foundationfee = 400;
    uint public callfee = 100;
    uint public max = 1000;

    uint public reservesRate = 100;
    uint constant public cashMax = 1000;

    uint public withdrawalFee = 0;
    uint constant public withdrawalMax = 10000;
    
    address public governance;
    address public strategyDev;
    address public controller;
    address public foundationAddress = 0x1250E38187Ff89d05f99F3fa0E324241bbE2120C;
    address public burnAddress;

    string public getName;

    address[] public swap2GOFRouting;
    address[] public swap2TokenRouting;
    
    struct StrategyBalance {
        uint256 lpAmount;
        uint256 pricePerFullShare;
    }

    StrategyBalance public balancePrior;
    uint public reserves = 0;
    bool public splitGof = true;

    event UpdateBalance(uint256 _oldReserves, uint256 _newReserves, StrategyBalance _oldBalance, StrategyBalance _newBalance);
    event ClaimReserves(uint256 _amount);
    
    constructor(
        address _controller, 
        address _want,
        address _farmVault,
        address _farmPool,
        address _burnAddress
        ) public {
        governance = msg.sender;
        strategyDev = tx.origin;
        controller = _controller;
        burnAddress = _burnAddress;

        want = _want;
        farmVault = _farmVault;
        farmPool = _farmPool;

        getName = string(abi.encodePacked("golff:Strategy:", IERC20(want).name()));

        balancePrior = currentStrategyBalance();

        swap2TokenRouting = [output,weth,want];
        swap2GOFRouting = [want,weth,gof];
        doApprove();
        
    }

    function doApprove () public{
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, uint(-1));

        IERC20(want).safeApprove(unirouter, 0);
        IERC20(want).safeApprove(unirouter, uint(-1));
    }
    
    modifier onlyGovernance() {
        require(msg.sender == governance, "Golff:!governance");
        _;
    }
    
    function updateReserves() internal {
        uint _oldReserves = reserves;
        StrategyBalance memory _oldBalance = balancePrior;

        StrategyBalance memory current = currentStrategyBalance();
        reserves = reserves.add(calcReserve(current.pricePerFullShare));
        balancePrior = current;
        
        emit UpdateBalance(_oldReserves, reserves, _oldBalance, balancePrior);
    }

    function calcReserve(uint pricePerFullShare) internal view returns(uint) {
        return balancePrior.lpAmount.mul(pricePerFullShare.sub(balancePrior.pricePerFullShare)).div(IFarmVault(farmVault).underlyingUnit());
    }

    function lpTokens() internal view returns (uint256) {
        return IERC20(farmVault).balanceOf(address(this)).add(IFarmPool(farmPool).balanceOf(address(this)));
    }

    function currentStrategyBalance() internal view returns (StrategyBalance memory bal) {
        bal = StrategyBalance({
            lpAmount: lpTokens(),
            pricePerFullShare: IFarmVault(farmVault).getPricePerFullShare()
        });
    }

    function claimReserves(uint _r) public checkStrategist {
        require(_r <= reserves, "Strategy:INSUFFICIENT_UNCLAIM");
        reserves = reserves.sub(_r);
        uint _balance = IERC20(want).balanceOf(address(this));

        if (_balance < _r) {
            _r = _withdrawSome(_r.sub(_balance));
            _r = _r.add(_balance);
            updateReserves();
        }
        
        dosplit(_r);

        emit ClaimReserves(_r);
    }

    function claimReservesAll() external checkStrategist {
        claimReserves(reserves);
    }

    function deposit() public {
        doDeposit();
        updateReserves();
    }

    function doDeposit() internal {
        uint _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(farmVault, 0);
            IERC20(want).safeApprove(farmVault, _want);
            IFarmVault(farmVault).deposit(_want);
        }
        
        _depositMine();
    }

    function _depositMine() internal {
        uint _balance = IERC20(farmVault).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(farmVault).safeApprove(farmPool, 0);
            IERC20(farmVault).safeApprove(farmPool, _balance);
            IFarmPool(farmPool).stake(_balance);
        }
    }
    
    // Controller only function for creating additional rewards from dust
    function withdraw(address _asset) external {
        require(msg.sender == controller, "Golff:!controller");
        require(want != _asset, "Golff:want");
        require(gof != _asset, "Golff:gof");
        require(output != _asset, "Golff:output");
        require(farmVault != _asset, "Golff:farmVault");
        
        uint256 balance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).safeTransfer(controller, balance);
    }
    
    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint _amount) external {
        require(msg.sender == controller || msg.sender == governance, "Golff:!controller");
        if ( _amount > 0) {
            uint _balance = IERC20(want).balanceOf(address(this));
            if (_balance < _amount) {
                _amount = _withdrawSome(_amount.sub(_balance));
                _amount = _amount.add(_balance);
            }

            updateReserves();
            
            uint _fee = 0;
            if (withdrawalFee>0){
                _fee = _amount.mul(withdrawalFee).div(withdrawalMax);        
                IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
            }
            
            address _vault = IController(controller).vaults(address(want));
            require(_vault != address(0), "Golff:!vault"); // additional protection so we don't burn the funds
            IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
        }
    }

    function _withdrawSome(uint256 _amount) internal returns (uint) {
        uint256 _share = _amount.mul(IFarmVault(farmVault).underlyingUnit()).div(IFarmVault(farmVault).getPricePerFullShare());
        uint _balance = IERC20(farmVault).balanceOf(address(this));
        if (_balance < _share) {
            IFarmPool(farmPool).withdraw(_share.sub(_balance));
            _balance = IERC20(farmVault).balanceOf(address(this));
        }

        if (_share > _balance) {
            _share = _balance;
        }

        uint256 _wantBal = IERC20(want).balanceOf(address(this));
        IFarmVault(farmVault).withdraw(_share);
        _wantBal = IERC20(want).balanceOf(address(this)).sub(_wantBal);
        return _wantBal;
    }
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller || msg.sender == governance,"Golff:!governance");
        _withdrawAll();

        updateReserves();
        
        balance = IERC20(want).balanceOf(address(this));
        
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "Golff:!vault"); // additional protection so we don't burn the funds
        if (balance > reserves) {
            IERC20(want).safeTransfer(_vault, balance.sub(reserves));
        }
    }
    
    function _withdrawAll() internal {
        uint256 _poolBal = IFarmPool(farmPool).balanceOf(address(this));
        if (_poolBal > 0) {
            IFarmPool(farmPool).exit();
        }

        uint _balance = IERC20(farmVault).balanceOf(address(this));
        if (_balance > 0) {
            IFarmVault(farmVault).withdraw(_balance);
        }
    }

    modifier checkStrategist(){
        require(msg.sender == strategyDev || msg.sender == governance,"Golff:!strategyDev");
        _;
    }
    
    function harvest() external checkStrategist {
        uint _before = IERC20(want).balanceOf(address(this));
        IFarmPool(farmPool).getReward();
        doswap();
        uint _a = IERC20(want).balanceOf(address(this)).sub(_before);
        uint _sb = _a.mul(reservesRate).div(cashMax);
        dosplit(_sb);
        doDeposit();
        updateReserves();
    }

    function doswap() internal {
        uint256 _balance = IERC20(output).balanceOf(address(this));
        if(_balance > 0 && output != want){
            IUniswapRouter(unirouter).swapExactTokensForTokens(_balance, 0, swap2TokenRouting, address(this), now.add(1800));
        }

    }

    function dosplit(uint _b) internal{
        if (_b > 0) {
            if (splitGof) {
                IUniswapRouter(unirouter).swapExactTokensForTokens(_b, 0, swap2GOFRouting, address(this), now.add(1800));
                _b = IERC20(gof).balanceOf(address(this));
                split(IERC20(gof), _b);
            } else {
                split(IERC20(want), _b);
            }
        }
    }

    function split(IERC20 token, uint b) internal{
        if (b > 0) {
            uint _fee = b.mul(fee).div(max);
            uint _foundationfee = b.mul(foundationfee).div(max);
            uint _burnfee = b.mul(burnfee).div(max); 
            uint _callfee = b.sub(_burnfee).sub(_foundationfee).sub(_fee);
            if (_fee > 0){
                token.safeTransfer(IController(controller).rewards(), _fee); 
            }
            if (_callfee > 0) {
                token.safeTransfer(msg.sender, _callfee); 
            }
            if (_foundationfee > 0) {
                token.safeTransfer(foundationAddress, _foundationfee); 
            }
            if (_burnfee >0){
                token.safeTransfer(burnAddress, _burnfee);
            }
        }
    }
    
    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint) {
        return lpTokens().mul(IFarmVault(farmVault).getPricePerFullShare()).div(IFarmVault(farmVault).underlyingUnit());
    }
    
    function balanceAll() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfPool());
    }

    function balanceOf() external view returns (uint) {
        uint _all = balanceAll();
        uint _cReserve = reserves.add(calcReserve(IFarmVault(farmVault).getPricePerFullShare()));
        if (_all < _cReserve) {
            return 0;
        } else {
            return _all.sub(_cReserve);
        }
    }
    
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }
    
    function setController(address _controller) external onlyGovernance {
        controller = _controller;
    }

    function setFees(uint256 _fee, uint256 _callfee, uint256 _burnfee, uint256 _foundationfee) external onlyGovernance{

        fee = _fee;
        callfee = _callfee;
        burnfee = _burnfee;
        foundationfee = _foundationfee;

        max = fee.add(callfee).add(burnfee).add(foundationfee);
    }

    function setReservesRate(uint256 _reservesRate) external onlyGovernance {
        require(_reservesRate < cashMax, "reservesRate >= 1000");
        reservesRate = _reservesRate;
    }

    function setFoundationAddress(address _foundationAddress) external onlyGovernance{
        foundationAddress = _foundationAddress;
    }

    function setWithdrawalFee(uint _withdrawalFee) external onlyGovernance {
        require(_withdrawalFee <=100,"fee > 1%"); //max:1%
        withdrawalFee = _withdrawalFee;
    }

    function setBurnAddress(address _burnAddress) external onlyGovernance {
        burnAddress = _burnAddress;
    }

    function setStrategyDev(address _strategyDev) external onlyGovernance {
        strategyDev = _strategyDev;
    }

    function setSwap2GOF(address[] calldata _path) external onlyGovernance{
        swap2GOFRouting = _path;
    }
    function setSwap2Token(address[] calldata _path) external onlyGovernance{
        swap2TokenRouting = _path;
    }

    function emergencyWithdrawPool() external onlyGovernance {
        IFarmPool(farmPool).withdraw(IFarmPool(farmPool).balanceOf(address(this)));
    }

    function donateReserves(uint256 _amount) external onlyGovernance {
        require(_amount <= reserves, "Strategy:Insufficient reserves");
        reserves = reserves.sub(_amount);
    }
}