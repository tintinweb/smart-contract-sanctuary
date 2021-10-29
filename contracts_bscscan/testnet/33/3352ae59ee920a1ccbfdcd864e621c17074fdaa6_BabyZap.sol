/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
* BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface InterfaceLP {
    function sync() external;
}
  
interface IDEXRouter {
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

contract BabyZap is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    IDEXRouter public router;
    address public pair;
    InterfaceLP public pairContract;

    string private _name = 'Zapit';
    string private _symbol = 'ZAP';
    uint8 private _decimals = 18;
        
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 1e7 * 1e18;
    uint256 private TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 public _gonsPerFragment;
    
    mapping(address => uint256) public _gonBalances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public blacklist;
    mapping (address => uint256) public _buyInfo;
    mapping(address => bool) public presaleWallet;

    uint256 public _percentForTxLimit = 1;
    uint256 public _percentForWalletLimit = 2;
    uint256 public _percentForBuyRebase = 10;
    
    uint256 public _timeLimitFromLastBuy = 2 minutes;
    uint256 private _lastBurn;
    
    uint public _torchBurnPercent = 1; 
    uint public _torchburnRewardPercent = 1;

    uint public _burnBlockGap = 1200;
    
    uint256 private pairAmount;
    uint256 private callerAmount;
    uint256 private burnReward;

    event Airdrop(address holder, uint256 amount);
    
    bool public _live = false;
    
    constructor () {
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        pairContract = InterfaceLP(pair);

        _lastBurn = block.number;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[_msgSender()] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }

    function balanceOf(address account) public view override returns (uint256) {
        if(account == pair)
            return pairAmount;
        return _gonBalances[account].div(_gonsPerFragment);
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
    
    function rebasePlus(uint256 _amount) private {
        _totalSupply = _totalSupply.add(_amount.mul(_percentForBuyRebase).div(100));
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function torchBurner() private {
        uint256 burnAmount = pairAmount.mul(_torchBurnPercent).div(100);
        pairAmount = pairAmount.sub(burnAmount);
        _totalSupply = _totalSupply.sub(burnAmount);
        callerAmount = balanceOf(_msgSender());
        burnReward = burnAmount.mul(_torchburnRewardPercent).div(100);
        uint256 gonValue = burnReward.mul(_gonsPerFragment);
        _gonBalances[_msgSender()] = _gonBalances[_msgSender()].add(gonValue);
        emit Transfer(address(0), _msgSender(), burnReward);
        // callerAmount = callerAmount.add(burnReward);
        _totalSupply = _totalSupply.add(burnReward);
        TOTAL_GONS = _gonsPerFragment.mul(_totalSupply);
        pairContract.sync();
    }

    function blacklistBurn(uint256 _amount) private {      
        _totalSupply = _totalSupply.sub(_amount);
        TOTAL_GONS = _gonsPerFragment.mul(_totalSupply);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (from != owner() && to != owner() && !presaleWallet[from] && !presaleWallet[to]) {
            // if transfer is not from/to the owner or presale wallet
            uint256 txLimitAmount = _totalSupply.mul(_percentForTxLimit).div(100);
            require(amount <= txLimitAmount, "Amount exceeds the max tx limit.");
            
            if(from != pair) {
                // if the transfer is not from liqudity (sell tx).
                require(!blacklist[from] && !blacklist[to], 'Your wallet has been blacklisted for attempting to snipe before launch');
                require(_buyInfo[from] == 0 || _buyInfo[from].add(_timeLimitFromLastBuy) < block.timestamp, "Your wallet is on cooldown, try again shortly");
                
                if(to == address(router) || to == pair) {
                    // If the transfer is sell tx sending tokens to liqudity
                    _buyInfo[from] = block.timestamp;                    
                    _tokenTransfer(from, to, amount);
                }
                    
                else // Direct wallet transfers
                     _tokenTransfer(from, to, amount);

            }            
            else {
                // If the transfer is from liqudity (buy tx)
                uint256 walletMax = _totalSupply.mul(_percentForWalletLimit).div(100);
                require(balanceOf(to) <= walletMax, 'Current balance exceeds the maximum');                
                require(_buyInfo[to] == 0 || _buyInfo[to].add(_timeLimitFromLastBuy) < block.timestamp, "Your wallet is on cooldown, try again shortly");
                                
                if(!_live) {
                    // Launched but not live yet
                    blacklist[to] = true;
                    _buyInfo[to] = 0;
                    _tokenTransfer(from, to, amount);
                    _gonBalances[to] = 0;               
                    blacklistBurn(amount);
                }
                else {
                    // Launched and live
                    _buyInfo[to] = block.timestamp;
                    _tokenTransfer(from, to, amount);
                    rebasePlus(amount);
                }
            }
        } else {
            // Safe transfers between owner and dxsale wallets, don't apply special rules
            _tokenTransfer(from, to, amount);
        }
    }

    function _tokenTransfer(address from, address to, uint256 amount) internal {
        if(to == pair)
            pairAmount = pairAmount.add(amount);
        else if(from == pair)
            pairAmount = pairAmount.sub(amount);
    
        uint256 gonTotalValue = amount.mul(_gonsPerFragment);
        uint256 gonValue = amount.mul(_gonsPerFragment);
        
        _gonBalances[from] = _gonBalances[from].sub(gonTotalValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        
        emit Transfer(from, to, amount);
    }
    
    function updateLive() public onlyOwner {
        if(!_live) {
            _live = true;
        }
    }
    
    function removeFromBlacklist(address account) public onlyOwner {
        blacklist[account] = false;
    }
    
    function updatePercentForTxLimit(uint256 percentForTxLimit) public onlyOwner {
        require(percentForTxLimit >= 1, 'Max tx limit should be greater than 1%');
        _percentForTxLimit = percentForTxLimit;
    }

    function updatePercentForWalletLimit(uint256 percentForWalletLimit) public onlyOwner {
        require(percentForWalletLimit >= 1, 'Max wallet limit should be greater than 1%');
        _percentForWalletLimit = percentForWalletLimit;
    }

    function updateBuyRebase(uint256 percentForBuyRebase) public onlyOwner {
        _percentForBuyRebase = percentForBuyRebase;
    }

    function updateCooldownLimit(uint256 timeLimitFromLastBuy) public onlyOwner {
        require(timeLimitFromLastBuy <= 5 minutes, "Cannot set higher than 5 minutes");
        _timeLimitFromLastBuy = timeLimitFromLastBuy;
    }

    function setPresaleWallet(address account, bool enabled) public onlyOwner {
        presaleWallet[account] = enabled;
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function TORCH() public {
        require(pair != address(0), "The pair is zero address");
        require(_lastBurn.add(_burnBlockGap) <= block.number, "You can not call this function before until next Burn Block");
        torchBurner();
        _lastBurn = block.number;
    }

    function getLastBurn() public view returns(uint256) {
        return _lastBurn;
    }

    function getNextBurn() public view returns(uint256) {
        if(_lastBurn.add(_burnBlockGap) > block.number) {
            uint256 nextBurn = _lastBurn.add(_burnBlockGap).sub(block.number);
            return nextBurn;
        } else {
            return uint256(0);
        }
    }

    function updateTorchBurnPercent(uint256 torchBurnPercent) public onlyOwner {
        require(torchBurnPercent <= 20 , "Cannot set higher than 20%");
        _torchBurnPercent = torchBurnPercent;
    }

    function updateTorchBurnRewardPercent(uint256 torchburnRewardPercent) public onlyOwner {
        require(torchburnRewardPercent <= 20 , "Cannot set higher than 20%");
        _torchburnRewardPercent = torchburnRewardPercent;
    }

    function updateBurnBlockGap(uint256 burnBlockGap) public onlyOwner {        
        _burnBlockGap = burnBlockGap;
    }

    /*
    @dev sends tokens to multiple addresses, from sender wallet
    @param _contributors address[] array with addresses
    @param _balances uint256[] array with balances
    */
    function multiSend(address[] memory _contributors, uint[] memory _balances) public {
        require(
            _contributors.length == _balances.length,
            "Contributors and balances must be same size"
        );
        // Max 200 sends in bulk, uint8 in loop limited to 255
        require(
            _contributors.length <= 200,
            "Contributor list length must be <= 200"
        );
        uint256 sumOfBalances = 0;
        for (uint8 i = 0; i < _balances.length; i++) {
            sumOfBalances = sumOfBalances.add(_balances[i]);
        }
        require(
            balanceOf(msg.sender) >= sumOfBalances,
            "Account balance must be >= sum of balances. "
        );
        require(
            allowance(msg.sender, address(this)) >= sumOfBalances,
            "Contract allowance must be >= sum of balances. "
        );
        address contributor;
        uint256 origBalance;
        for (uint8 j; j < _contributors.length; j++) {
            contributor = _contributors[j];
            require(
                contributor != address(0) &&
                    contributor != 0x000000000000000000000000000000000000dEaD,
                "Cannot airdrop to a dead address"
            );
            origBalance = balanceOf(contributor);
            this.transferFrom(msg.sender, contributor, _balances[j]);
            require(
                balanceOf(contributor) == origBalance + _balances[j],
                "Contributor must recieve full balance of airdrop"
            );
            emit Airdrop(contributor, _balances[j]);
        }
    }
}