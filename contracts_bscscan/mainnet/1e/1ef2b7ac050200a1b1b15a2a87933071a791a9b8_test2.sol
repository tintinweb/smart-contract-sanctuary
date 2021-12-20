/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
pragma solidity ^0.6.12;

library AddrArrayLib {
    using AddrArrayLib for Addresses;
    struct Addresses {
        address[] _items;
        mapping(address => int) map;
    }

    function removeAll(Addresses storage self) internal {
        delete self._items;
    }

    function pushAddress(Addresses storage self, address element, bool allowDup) internal {
        if (allowDup) {
            self._items.push(element);
            self.map[element] = 2;
        } else if (!exists(self, element)) {
            self._items.push(element);
            self.map[element] = 2;
        }
    }

    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        if (!exists(self, element)) {
            return true;
        }
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                self.map[element] = 1;
                return true;
            }
        }
        return false;
    }

    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }

    function exists(Addresses storage self, address element) internal view returns (bool) {
        return self.map[element] == 2;
    }

    function getAllAddresses(Addresses storage self) internal view returns (address[] memory) {
        return self._items;
    }
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
        uint deadline
    ) external;
}

contract test2 is IERC20, Context, Ownable { //name contract file name #0
    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) public _isExcluded;
    mapping(address => bool) public whitelist;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal =     100_000_00 * 10 ** 6 * 10 ** 9;//#1
    uint256 public _maxTxAmount =     500_000 * 10 ** 6 * 10 ** 9;//max tx ammount #2
    uint256 public _maxWalletAmount = 2_000_000 * 10 ** 6 * 10 ** 9;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "fml11fjhf "; //name ca #3
    string private _symbol = "fml1uyet8u1";
    uint8 public immutable decimals = 9;

    address public RewardsAddressBuy =  0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //set wallets #4
    address public GiveawayWalletAddressBuy = 0x8E8E3BF264e2Dad590119c8549FA67e99584dfcB;
    address public marketingFundWalletAddressBuy = 0x84ce44794FF34FC09D06255643B9Fb58fCC6a81c;
    address public Team1WalletAddressBuy = 0xD79C335264Fd1A90e8C5496799e096b851E6FD81;

    address public RewardsAddressSell = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public GiveawayWalletAddressSell = 0x8E8E3BF264e2Dad590119c8549FA67e99584dfcB;
    address public marketingFundWalletAddressSell = 0x84ce44794FF34FC09D06255643B9Fb58fCC6a81c;
    address public Team1WalletAddressSell = 0xD79C335264Fd1A90e8C5496799e096b851E6FD81;

    address RewardsAddress;
    address GiveawayWalletAddress;
    address marketingFundWalletAddress;
    address Team1WalletAddress;

    uint256 public _liquidityFeeBuy     = 20; //2% set taxes buy #5
    uint256 public _RewardsFeeBuy       = 40; //4%
    uint256 public _marketingFundFeeBuy = 30; //3%
    uint256 public _GiveawayFeeBuy      = 20; //2%
    uint256 public _Team1FeeBuy         = 10; //1%

    uint256 public _liquidityFeeSell    = 30; //3% set taxes sell #6
    uint256 public _RewardsFeeSell      = 70; //7%
    uint256 public _marketingFundFeeSell= 70; //7%
    uint256 public _GiveawayFeeSell     = 50; //5%
    uint256 public _Team1FeeSell        = 20; //2%

    uint256  _liquidityFee = 0; //0%
    uint256  _GiveawayFee = 0; //0%
    uint256  _marketingFundFee = 0; //0%
    uint256  _Team1Fee = 0; //0%
    uint256  _RewardsFee = 0; //0%

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 public _creationTime = now;

    uint256 private numTokensSellToAddToLiquidity = 500_000 * 10 ** 6 * 10 ** 9;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;


    address public pendingMinter;
    uint public delayMinter;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        _rOwned[owner()] = _rTotal;

        // we whitelist treasure and owner to allow pool management
        whitelist[owner()] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromFee[RewardsAddressBuy] = true;
        _isExcludedFromFee[GiveawayWalletAddressBuy] = true;
        _isExcludedFromFee[marketingFundWalletAddressBuy] = true;
        _isExcludedFromFee[Team1WalletAddressBuy] = true;

        _isExcludedFromFee[RewardsAddressSell] = true;
        _isExcludedFromFee[GiveawayWalletAddressSell] = true;
        _isExcludedFromFee[marketingFundWalletAddressSell] = true;
        _isExcludedFromFee[Team1WalletAddressSell] = true;

        emit Transfer(address(0), msg.sender, _tTotal);

    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function approveAndCall(address spender, uint256 value, bytes calldata data) external  returns (bool) {
        // _approve(msg.sender, spender, value);
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }
    function transferAndCall(address to, uint value, bytes calldata data) external  returns (bool) {
        require(to != address(0) || to != address(this));
        _transfer(msg.sender, to, value);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (rInfo memory rr,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rTotal = _rTotal.sub(rr.rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (rInfo memory rr,) = _getValues(tAmount);
            return rr.rAmount;
        } else {
            (rInfo memory rr,) = _getValues(tAmount);
            return rr.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tt.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    // whitelist to add liquidity
    function setWhitelist(address account, bool _status) public onlyOwner {
        whitelist[account] = _status;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setGiveawayFeePercent(uint256 GiveawayFee) external onlyOwner() {
        _GiveawayFee = GiveawayFee;
    }

    function setMarketingFundFeePercent(uint256 marketingFundFee) external onlyOwner() {
        _marketingFundFee = marketingFundFee;
    }

    function setTeam1FeePercent(uint256 Team1Fee) external onlyOwner() {
        _Team1Fee = Team1Fee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10 ** 2);
    }

    function setMaxWalletPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxWalletAmount = _tTotal.mul(maxTxPercent).div(10 ** 2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    bool transferDebug = true;
    function setTransferDebug(bool _enabled) public onlyOwner {
        transferDebug = _enabled;
    }

    bool public buyTradingEnabled = true;
    bool public sellTradingEnabled = true;
    function setBuyTradingEnabled(bool _enabled) public onlyOwner {
        buyTradingEnabled = _enabled;
    }
    function setSellTradingEnabled(bool _enabled) public onlyOwner {
        sellTradingEnabled = _enabled;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    event feeTransfer(address indexed from, address indexed to, uint256 value);

    function _reflectFee(rInfo memory rr, tInfo memory tt) private {
        _rTotal = _rTotal.sub(rr.rLiquidity);
        _tFeeTotal = _tFeeTotal.add(tt.tGiveawayFee)
        .add(tt.tMarketingFundFee).add(tt.tTeam1Fee).add(tt.tRewardsFee);

        _rOwned[RewardsAddress] = _rOwned[RewardsAddress].add(rr.rRewardsFee);
        _rOwned[GiveawayWalletAddress] = _rOwned[GiveawayWalletAddress].add(rr.rGiveawayFee);
        _rOwned[marketingFundWalletAddress] = _rOwned[marketingFundWalletAddress].add(rr.rMarketingFundFee);
        _rOwned[Team1WalletAddress] = _rOwned[Team1WalletAddress].add(rr.rTeam1Fee);

        if (transferDebug && tt.tRewardsFee > 0)
            emit feeTransfer(msg.sender, RewardsAddress, tt.tRewardsFee);

        if (transferDebug && tt.tGiveawayFee > 0)
            emit feeTransfer(msg.sender, GiveawayWalletAddress, tt.tGiveawayFee);

        if (transferDebug && tt.tMarketingFundFee > 0)
            emit feeTransfer(msg.sender, marketingFundWalletAddress, tt.tMarketingFundFee);

        if (transferDebug && tt.tTeam1Fee > 0)
            emit feeTransfer(msg.sender, Team1WalletAddress, tt.tTeam1Fee);


    }

    struct tInfo {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tGiveawayFee;
        uint256 tMarketingFundFee;
        uint256 tTeam1Fee;
        uint256 tRewardsFee;
    }

    struct rInfo {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rGiveawayFee;
        uint256 rMarketingFundFee;
        uint256 rTeam1Fee;
        uint256 rLiquidity;
        uint256 rRewardsFee;
    }

    function _getValues(uint256 tAmount) private view returns (rInfo memory rr, tInfo memory tt) {
        tt = _getTValues(tAmount);
        rr = _getRValues(tAmount, tt.tLiquidity, tt.tGiveawayFee, tt.tMarketingFundFee,
            tt.tTeam1Fee, tt.tRewardsFee, tt.tLiquidity, _getRate());
        return (rr, tt);
    }

    function _getTValues(uint256 tAmount) private view returns (tInfo memory tt) {
        tt.tGiveawayFee = calculateGiveawayFee(tAmount);
        tt.tMarketingFundFee = calculateMarketingFundFee(tAmount);
        tt.tTeam1Fee = calculateTeam1Fee(tAmount);
        tt.tRewardsFee = calculateRewardsFee(tAmount);
        tt.tLiquidity = calculateLiquidityFee(tAmount);
        uint totalFee = tt.tLiquidity.add(tt.tGiveawayFee);
        totalFee = totalFee.add(tt.tMarketingFundFee).add(tt.tTeam1Fee);
        totalFee = totalFee.add(tt.tRewardsFee);
        tt.tTransferAmount = tAmount.sub(totalFee);
        return tt;
    }

    function _getRValues(uint256 tAmount, uint256 tLiquidityFee, uint256 tGiveawayFee,
        uint256 tMarketingFundFee, uint256 tTeam1Fee, uint256 rRewardsFee, uint256 tLiquidity,
        uint256 currentRate) private pure returns (rInfo memory rr) {
        rr.rAmount = tAmount.mul(currentRate);
        rr.rGiveawayFee = tGiveawayFee.mul(currentRate);
        rr.rMarketingFundFee = tMarketingFundFee.mul(currentRate);
        rr.rTeam1Fee = tTeam1Fee.mul(currentRate);
        rr.rLiquidity = tLiquidity.mul(currentRate);
        rr.rRewardsFee = rRewardsFee.mul(currentRate);
        uint totalFee = rr.rGiveawayFee.add(rr.rMarketingFundFee);
        totalFee = totalFee.add(rr.rTeam1Fee).add(rr.rLiquidity).add(rr.rRewardsFee);
        rr.rTransferAmount = rr.rAmount.sub(totalFee);
        return rr;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(1000);
    }

    function calculateGiveawayFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_GiveawayFee).div(1000);
    }

    function calculateMarketingFundFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFundFee).div(1000);
    }

    function calculateTeam1Fee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_Team1Fee).div(1000);
    }

    function calculateRewardsFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_RewardsFee).div(1000);
    }

    function removeAllFee() private {
        _liquidityFee = 0;
        _GiveawayFee = 0;
        _marketingFundFee = 0;
        _Team1Fee = 0;
        _liquidityFee = 0;
        _RewardsFee = 0;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    uint256 public day1 = 1 days;
    uint256 public day1Pct = 30;
    uint256 public day2 = 2 days;
    uint256 public day2Pct = 60;
    uint256 public day3 = 3 days;
    uint256 public day3Pct = 90;

    function setDay1(uint256 _v) external onlyOwner{
        day1 = _v;
    }
    function setDay2(uint256 _v) external onlyOwner{
        day2 = _v;
    }
    function setDay3(uint256 _v) external onlyOwner{
        day3 = _v;
    }

    function setDay1Pct(uint256 _v) external onlyOwner{
        day1Pct = _v;
    }
    function setDay2Pct(uint256 _v) external onlyOwner{
        day2Pct = _v;
    }
    function setDay3Pct(uint256 _v) external onlyOwner{
        day3Pct = _v;
    }

    function _antiAbuse(address from, address to, uint256 amount, bool isBuy, bool isSell) private view {

        if (from == owner() || to == owner())
        //  if owner we just return or we can't add liquidity
            return;

        if (whitelist[from] || whitelist[to])
        //  if owner we just return or we can't add liquidity
            return;

        if( isBuy ){
            require( balanceOf(to).add(amount)  <= _maxWalletAmount, "exceeds the max balance");
            return;
        }

        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");

        uint256 lastCreationTime;
        uint256 allowedAmount;

        (, uint256 tSupply) = _getCurrentSupply();
        uint256 lastUserBalance = balanceOf(to) + (amount * (100 - getTotalFees()) / 100);

        // bot \ whales prevention
        if (now <= (_creationTime.add(day1))) {
            lastCreationTime = _creationTime.add(day1);
            allowedAmount = tSupply.div(10000).mul(day1Pct);
            require(lastUserBalance < allowedAmount, "tx-exc-d1");
        } else if (now <= (_creationTime.add(day2))) {
            lastCreationTime = _creationTime.add(day2);
            allowedAmount = tSupply.div(10000).mul(day2Pct);
            require(lastUserBalance < allowedAmount, "tx-exc-d2");
        } else if (now <= (_creationTime.add(day3))) {
            lastCreationTime = _creationTime.add(day3);
            allowedAmount = tSupply.div(10000).mul(day3Pct);
            require(lastUserBalance < allowedAmount, "tx-exc-d3");
        }
    }

    event WhiteListTransfer(address from, address to, uint256 amount);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        bool isContractTransfer=(from==address(this) || to==address(this));
        bool isExcluded = (_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        bool isLiquidityTransfer = ((from == uniswapV2Pair && to == address(uniswapV2Router))
        || (to == uniswapV2Pair && from == address(uniswapV2Router)));

        bool isBuy=from==uniswapV2Pair|| from == address(uniswapV2Router);
        bool isSell=to==uniswapV2Pair|| to == address(uniswapV2Router);

        uint8 orderType;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (isContractTransfer || isExcluded || isLiquidityTransfer) {
            takeFee = false;
        }else{
            if( isBuy ){
                orderType = 1;
                require(buyTradingEnabled, "!buyTradingEnabled");
            }
            if( isSell ){
                orderType = 2;
                require(sellTradingEnabled, "!sellTradingEnabled");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        // whitelist to allow treasure to add liquidity:
        if (whitelist[from] || whitelist[to] || ! takeFee ) {
            emit WhiteListTransfer(from, to, amount);
        } else {
            _antiAbuse(from, to, amount, isBuy, isSell);
        }

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }



        //transfer amount, it will take tax, liquidity fee
        _tokenTransfer(from, to, amount, takeFee, orderType);

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function onTransferSetupFees(bool takeFee, uint8 orderType) private {
        if (!takeFee) {
            removeAllFee();
        }else{
            if( orderType == 1 ){
                _GiveawayFee = _GiveawayFeeBuy;
                _marketingFundFee = _marketingFundFeeBuy;
                _Team1Fee = _Team1FeeBuy;
                _liquidityFee = _liquidityFeeBuy;
                _RewardsFee = _RewardsFeeBuy;

                RewardsAddress = RewardsAddressBuy;
                GiveawayWalletAddress = GiveawayWalletAddressBuy;
                marketingFundWalletAddress = marketingFundWalletAddressBuy;
                Team1WalletAddress = Team1WalletAddressBuy;

            }else if( orderType == 2 ){
                _GiveawayFee = _GiveawayFeeSell;
                _marketingFundFee = _marketingFundFeeSell;
                _Team1Fee = _Team1FeeSell;
                _liquidityFee = _liquidityFeeSell;
                _RewardsFee = _RewardsFeeSell;

                RewardsAddress = RewardsAddressSell;
                GiveawayWalletAddress = GiveawayWalletAddressSell;
                marketingFundWalletAddress = marketingFundWalletAddressSell;
                Team1WalletAddress = Team1WalletAddressSell;

            }else{
                removeAllFee();
            }

        }
    }
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,
        bool takeFee, uint8 orderType) private {
        onTransferSetupFees(takeFee, orderType);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        removeAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);

        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tt.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (rInfo memory rr, tInfo memory tt) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rr.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rr.rTransferAmount);
        _takeLiquidity(tt.tLiquidity);
        _reflectFee(rr, tt);
        emit Transfer(sender, recipient, tt.tTransferAmount);
    }

    function getTime() public view returns (uint256){
        return block.timestamp;
    }

    function getTotalFees() internal view returns (uint256) {
        return _GiveawayFee + _liquidityFee + _Team1Fee + _marketingFundFee;
    }

}