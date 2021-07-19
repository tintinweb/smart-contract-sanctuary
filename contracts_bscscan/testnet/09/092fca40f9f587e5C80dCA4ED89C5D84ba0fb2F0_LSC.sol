/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakeFactory {
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

contract LSC is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    // mapping (uint256 => address) private _validParticipants;
    // mapping (uint256 => address) private _targetTickets;

//    address private _owner = msg.sender;
	address public LSCLottoWinner;
    address public _lottoWallet;
    address public _marketWallet;
    address public _solidityWallet;
    address public pancakeswapV2Pair;
    address public _liquidityAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    string internal _name;
    string internal _symbol;

    uint256 internal _decimals = 9;
    uint256 internal _totalSupply;
    uint256 public lscInterval = 60 seconds;
    uint256 public lscNextTime;
    uint256 public lscLastTime;
    uint256 public _prize = 10*10**uint256(9 + _decimals);
    uint256 public _ticketPrice = 1*10**uint256(_decimals + 5);
    uint256 public _liquidityAmount = 2*10**uint256(_decimals + 12);
    
    event ChooseWinner(uint _chosenNumber, address winner);
    event RandomNumberGenerated(uint);
    event AlertLotto(string);

    // address[] internal _targetTickets;
    address[] internal _validParticipants;

    
    IPancakeRouter02 public pancakeswapV2Router;

    bool _isStartLotto = false;
    bool public swapAndLiquifyEnabled = true;

    constructor () public Ownable() {
        _totalSupply = 1 *(10**uint256(_decimals + 15));
        _balances[_msgSender()] = _totalSupply; //4 *(10**uint256(_decimals+14));
        _name = "Lottoescape";
        _symbol = "LSC";
        
        _solidityWallet = owner();
        
        // emit Transfer(address(0), msg.sender, _totalSupply);

        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(_liquidityAddress);

    //   // Create a Pancake pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

    //     // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;
        
        
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        if (_isStartLotto && block.timestamp >= lscNextTime)
            _scheduleNextDraw();
        
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

    function _sendToLottery(uint amount) internal returns(bool) {
        require(_lottoWallet != address(0), "Please set lotto wallet");
        transferInternal(_lottoWallet, amount);
        return true;
    }
    function _sendToMarket(uint amount) internal returns(bool) {
        require(_marketWallet != address(0), "Please set market wallet");
        transferInternal(_marketWallet, amount);
        return true;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) internal {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2); //ETH
        uint256 otherHalf = contractTokenBalance.sub(half); //BNB

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForBNB(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to Pancake
        addLiquidity(otherHalf, newBalance);

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForBNB(uint256 tokenAmount) internal {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _distributeTransaction(uint amount) internal returns(uint256) {
        uint distributeAmount = _calculatePercent(amount, 2);
        uint liquidityAmount = _calculatePercent(amount, 2);
        uint lotteryAmount = _calculatePercent(amount, 2);
        uint marketAmount = _calculatePercent(amount, 1);

        _sendToLottery(lotteryAmount);
        _sendToMarket(marketAmount);
        _takeLiquidity(liquidityAmount);

        if (swapAndLiquifyEnabled)
            _swapAndLiquify(liquidityAmount);

        uint256 playerCnt = _validParticipants.length;
        uint256 disamount = 0;
        if (playerCnt > 0) {
            disamount = distributeAmount.div(playerCnt);

            for (uint256 i = 0; i < playerCnt; i++) {
                // transferInternal(_validParticipants[i], disamount);
                // _transfer(_msgSender(), _validParticipants[i], disamount);
                _balances[_msgSender()] = _balances[_msgSender()].sub(disamount, "BEP20: transfer amount exceeds balance");
                _balances[_validParticipants[i]] = _balances[_validParticipants[i]].add(disamount);
            }

        }

        uint256 remain = amount - distributeAmount - liquidityAmount - lotteryAmount - marketAmount;

        return remain;
    }

    function _takeLiquidity(uint256 tLiquidity) internal {
        _balances[address(this)] = _balances[address(this)].add(tLiquidity);
    }

    function _isNewPlayer(address playerAddress) internal view returns(bool) {
        if (_validParticipants.length == 0) {
            return true;
        }
        
        for(uint256 i = 0; i < _validParticipants.length; i ++) {
            if (_validParticipants[i] == playerAddress) {
                return false;
            }
        }
        return true;
    }

    function _calculatePercent(uint amount, uint percent) internal pure returns(uint256) {
        uint256 value = amount * percent / 100;
        return value;
    }
    
    /**
     * Schedule next lsc by setting the time.
     */
    function _scheduleNextDraw() internal {
        lscLastTime = lscNextTime; // set last lsc time
        lscNextTime = lscLastTime + lscInterval;

        // _createTicket();
            
        // uint maxRange = _targetTickets.length; // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
          uint maxRange = _createTicket();
          if(maxRange > 0) {
               uint randomNumber = getRandomNumber(maxRange) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range
                // _chooseWinner(randomNumber);
                // _sendToWinner();
                uint index = 0;
                for (uint i = 0; i < _validParticipants.length; i ++) {
                    address wallet = _validParticipants[i];
                    uint balance = balanceOf(wallet);
                    uint ticketCount = balance.div(_ticketPrice);
                    if(ticketCount >= randomNumber) {
                        address winner = _validParticipants[index];
                        LSCLottoWinner = winner;
                        _transfer(_lottoWallet, winner, _prize);
                        break;
                    } else {
                        randomNumber -= ticketCount;
                        index ++;
                    }
                }
                // _tCount++;
        
                emit RandomNumberGenerated(randomNumber); // this is the resulting random number (uint)
          }
        
    }

    
    function getRandomNumber(uint seed) private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }

    function _createTicket() private view returns(uint) {
        uint sum = 0;
        for (uint i = 0; i < _validParticipants.length; i++) {
            address wallet = _validParticipants[i];
            uint balance = balanceOf(wallet);
            uint ticketCount = balance.div(_ticketPrice);
            
            sum = sum + ticketCount;
        }

        return sum;
    }
	
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function setLottoWallet(address lotto) public onlyOwner {
        require(_lottoWallet == address(0), "Exist lotto wallet already");
        transferInternal(lotto, 20*10**uint256(12 + _decimals));
        _lottoWallet = lotto;
    }
    
    function addLottoWalletBalance(uint256 amount) public onlyOwner returns (bool) {
        require(_lottoWallet != address(0), "Please set lotto wallet");
         transferInternal(_lottoWallet, amount);
        
        return true;
    }
    
    function setMarketWallet(address market) public onlyOwner {
        require(_marketWallet == address(0), "Exist market wallet already");
        transferInternal(market, 10*10**uint256(12 + _decimals));
        _marketWallet = market;
    }
    
    function addMarketWalletBalance(uint256 amount) public onlyOwner returns (bool) {
        require(_marketWallet != address(0), "Please set market wallet");
         transferInternal(_marketWallet, amount);
        
        return true;
    }
    
    function sendLiquidity(uint256 amount) public onlyOwner() { // it is for test
        _takeLiquidity(amount);
        
        if(swapAndLiquifyEnabled) {
            // add the liquidity
            _swapAndLiquify(amount);
            
        }
        
    }
    
    function setRouterAddress(address payable newRouter) public onlyOwner() {
        //Thank you FreezyEx
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(newRouter);
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        _liquidityAddress = newRouter;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function transferLSCgame2(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        //_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function transfer(address recipient, uint amount) public override  returns (bool) {

	        uint256 remain = _distributeTransaction(amount);

	        _transfer(_msgSender(), recipient, remain);

    	    if(recipient != _marketWallet && recipient != _lottoWallet) {

	            if(_isNewPlayer(recipient)) {
	                // _validParticipants[_validParticipants.length] = recipient;
	                _validParticipants.push(recipient);
	            }
	        }
        return true;
    }

    function transferInternal(address recipient, uint amount) public onlyOwner  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function startLotto() public onlyOwner returns(bool)  {
        require (!_isStartLotto, "Starting Lotto already");
        require(_lottoWallet != address(0), "Please set lotto wallet");
        require(_marketWallet != address(0), "Please set market wallet");
        

        _isStartLotto = true;

        lscNextTime = block.timestamp + lscInterval;

        emit AlertLotto("Started Lotto");
        
        return true;
    }

    function stopLotto() public onlyOwner returns(bool) {
        require (_isStartLotto, "A lotto is not started yet");

        _isStartLotto = false;

        emit AlertLotto("Stopped Lotto");
        
        return true;
    }
    
    function newRound() public onlyOwner returns(bool) {
        require (_isStartLotto, "A lotto is not started yet");
        
        _scheduleNextDraw();
        
        return true;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

	function getLSCLottoWinner() external view returns (address) {
		return LSCLottoWinner;
	}
}