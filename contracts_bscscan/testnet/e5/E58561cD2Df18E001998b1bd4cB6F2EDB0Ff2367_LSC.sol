/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

abstract contract Context {
    constructor ()  { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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



//**********************************************************************************************
//******************************  Contract code starts here!  **********************************
//**********************************************************************************************

contract LSC is Context, IBEP20, Ownable {
    using SafeMath for uint256;

	// Standard Mappings for IBEP20 Contract
    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;

	// Pancake Bullshit
    address public pancakeswapV2Pair;
    IPancakeRouter02 _pancakeswapV2Router;
	
	// Metadata
	uint256 public _totalSupply;
	uint8 _decimals;
	string internal _name;
	string internal _symbol;

	//Wallet Addresses Public
    address public _lottoWallet;
    address public _marketWallet;
    address public _solidityWallet;
    address public _liquidityAddress;
    address public _gameWinner;
    
    
    //flags and functionality
    
    bool feesActive;
    bool inSwapAndLiquify;
    
    uint256 gameTimer;
    uint256 timerExpires;
    
    //Lottery Game Variables
    address[] playerStack;
    mapping(address => uint256) playerStackIndex;
    
    uint256 public prize;
    uint256 internal _ticketPrice;    
    uint256 internal _maxTickets;
    
    uint256 public _pancakeSwapSellFee = 19;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    

	constructor () {
		_decimals = 9;
        _name = "Lottoescape";
        _symbol = "LSC";
        
        //Set Game Variables
        prize = 10 * 10 ** uint256(9 + _decimals);
        _ticketPrice = 100000 * 10 ** uint256(_decimals);
        _maxTickets = 500000;
        gameTimer = 300 seconds;
        
        
        feesActive = true;
        
        //Transfer funds to Owner address
        // _mint(_msgSender(), 10**uint256(_decimals + 15)); //set the starting value as a 15 digit amount
        _balances[_msgSender()] = 10**uint256(_decimals + 15);
        // emit Transfer(address(0), msg.sender, _totalSupply);
        _liquidityAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        _pancakeswapV2Router = IPancakeRouter02(_liquidityAddress);

    	// Create a Pancake pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
            
        //remove or change these after testing 
        //setMarketWallet(0xB8D16214aD6Cb0E4967c3aeFCc8Bc5f74D386B0a);
        //setLottoWallet(0xB8D16214aD6Cb0E4967c3aeFCc8Bc5f74D386B0a);
        
    }
    
    //*****************************************************************************
    //************************  Lotto Game Function calls  ************************
    //*****************************************************************************
    
    function startLotto() public onlyOwner {
        // Public access to the private function initiateGame()
        initiateGame();
    }
    
    
    function endGameEarly() public onlyOwner{
        timerExpires = block.timestamp;
        checkTimer();
    }
    
    function initiateGame() private {
        //Set a timer and start the game
        timerExpires = gameTimer + block.timestamp;
    }
    
    function checkTimer() internal {
        //if timer expired
        if (timerExpires <= block.timestamp){
            //payout winners and start a new game
            address winner = drawWinner();
            _transfer(_lottoWallet, winner, prize);
            // payWinner();
        }
        
        //Reset timer and start a new match
        initiateGame();
    }
    
    
    function drawWinner() internal returns (address winner) {
        require(playerStack.length > 0, "drawWinner: No ticket holders to pick from");
        //get necessary information before continuing
        //total number of virtual valid tickets in the system
        uint256 totaltickets = sumTickets();
        //draw a random number to be processed
        //this number is from 0 to the total number of tickets issued
        uint256 winningValue = getRandomNumber(totaltickets);
        
        uint256 ticketsPerPlayer;
        //Step through all of the eligible accounts to determine who wins
        for (uint256 i; i < playerStack.length; i++) {
            //fetch next ticket holder
            ticketsPerPlayer = getTickets(playerStack[i]);
            
            if (ticketsPerPlayer == winningValue) {
                //player wins
                _gameWinner = playerStack[i];
                return playerStack[i];
            }
            
        }
    }
    
    function sumTickets() private returns (uint256) {
        uint256 totalTickets;
        uint256 val;
        for (uint256 i; i < playerStack.length; i++) {
            val = getTickets(playerStack[i]);
            totalTickets += val;
            if (val == 0) {
                //player has been nuked, rerun this value
                i--;
            }
        }
        
        return totalTickets;
    }
    
    function getTickets(address player) private returns (uint256) {
        //Return the number of entries for address player
        if (_balances[player] == 0) {
            //kick player from the stack and return 0
            removePlayer(playerStackIndex[player]);
            return 0;
        } else {
            //Return ticket result for player
            uint256 tickets = _balances[player].div(_ticketPrice);
            if (tickets > _maxTickets) {
                tickets = _maxTickets;
            }
            return tickets;
        }
    }
    
    function addTokenHolder(address checkholder) private {
        //Currently this is only called by _transfer before the address recieves tokens
        //it will need to be updated if called elsewhere
        if (checkholder != owner() &&  //checking the blacklist
            checkholder != _lottoWallet &&
            checkholder != _marketWallet &&
            checkholder != _solidityWallet &&
            checkholder != _liquidityAddress
            ) {
            if (_balances[checkholder] == 0) {
                playerStack.push(checkholder);
            }
        }
    }
    
    function removePlayer(uint256 index) private {
        //The easiest way to eject a player from the stack, order is not important
        if ((index + 1) < playerStack.length){
            playerStack[index] = playerStack[(playerStack.length - 1)];
            playerStack.pop;
        } else {
            playerStack.pop;
        }
    }
    
    
    
    function setRouterAddress(address payable newRouter) public onlyOwner() {
        //assign to state variable
        _liquidityAddress = newRouter;
        
        //construct new swap pair
        _pancakeswapV2Router = IPancakeRouter02(_liquidityAddress);
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
    }
	
	function transferLSCgame2(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        //_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
	
	function pancakeswapV2Router() public view returns (IPancakeRouter02) {
		return _pancakeswapV2Router;
	}
	
	function getRandomNumber(uint maxValue) private view returns(uint256) {
        uint256 randomSpawn = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, maxValue)));
        return randomSpawn % maxValue;
    }
    
    receive() external payable {}
    
    //*****************************************************************************
    //***************************  Setters and Getters  ***************************
    //*****************************************************************************    
    
    function activateFees() public onlyOwner {
        feesActive = true;
    }

    function deactivateFees() public onlyOwner {
        feesActive = false;
    }
    
    function setGameTimer(uint256 newTimer) public onlyOwner {
        gameTimer = newTimer;
    }
    
    //*****************************************************************************
    //*********************  Contract IBEP20 Function calls  **********************
    //*****************************************************************************

    
    function setMarketWallet(address newWallet) public onlyOwner {
        //require(_balances[_marketWallet] == 0, "There are still funds in the current Market Wallet");
        _balances[_marketWallet] = 0;
        _marketWallet = newWallet; 
        _transfer(_msgSender(), _marketWallet, 10*10**uint256(12 + _decimals));
    }
    
    function setLottoWallet(address newWallet) public onlyOwner {
        //require(_balances[_lottoWallet] == 0, "There are still funds in the current Market Wallet");
        _balances[_lottoWallet] = 0;
        _lottoWallet = newWallet; 
        _transfer(_msgSender(), _lottoWallet, 20*10**uint256(12 + _decimals));    
    }
    
    function swapAndLiquify(uint256 amount) public lockTheSwap{
        // Record the initialBalance of the token wallet
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);
        
        uint256 initialBalance = address(this).balance;

        // swap tokens and add BNB to contract wallet
        swapTokensForBNB(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // Determine how much BNB was added to the wallet
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Send the other half of the tokens plus BNB to liquidity
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function swapTokensForBNB(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH();

        //always approve the transfer before doing it
        _approve(address(this), address(_pancakeswapV2Router), amount);
        
        // make the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    //adds the liquidity as part of SwapAndLiquify
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // add the liquidity
        _pancakeswapV2Router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    
    function setPancakeswapSellFee(uint256 amount) external onlyOwner {
        require(amount <= 19, "Pancakeswap FEE too much");
        _pancakeSwapSellFee = amount;
    }
    
    //This function is always run before taxable transfers call to _transfer()
    function payoutFees(address sender, address recipient, uint256 amount) internal {
        uint distributeAmount = (amount * 2).div(100);
        uint liquidityAmount = (amount * 2).div(100);
        uint lotteryAmount = (amount * 2).div(100);
        uint marketAmount = amount.div(100);
        
        if(_pancakeSwapSellFee > 0 && recipient == pancakeswapV2Pair){
            distributeAmount += amount * _pancakeSwapSellFee / 100;
        }
        
        //Transfer fees to respective accounts
        //first the easy ones, tokens to direct accounts
        
        if(_marketWallet != address(0)){
            _balances[_marketWallet] += marketAmount;
        }
        // _transfer(sender, _marketWallet, marketAmount);
        if(_lottoWallet != address(0)){
            _balances[_lottoWallet] += lotteryAmount;
        }
        
        // Now handle liquidity swap
		if(sender != pancakeswapV2Pair && !inSwapAndLiquify && sender != _msgSender()) {
			_balances[address(this)] = _balances[address(this)].add(liquidityAmount);
			swapAndLiquify(liquidityAmount);
        }
        // Distribute to tokenHolders
        if (playerStack.length > 0) {
            uint256 disamount = distributeAmount.div(playerStack.length);
            for (uint256 i = 0; i < playerStack.length; i++){
                
		        _balances[playerStack[i]] = _balances[playerStack[i]].add(disamount);
            }
        }
    }
	
	
	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");
	    
	    if(sender == pancakeswapV2Pair && amount > 0){
	        addTokenHolder(recipient);
	    }
	    
	    uint256 transferFee = 0;
	    if(feesActive && (sender == pancakeswapV2Pair || recipient == pancakeswapV2Pair)){
	        uint256 pancakeSellFee = 0;
	        
	        if(_pancakeSwapSellFee > 0 && recipient == pancakeswapV2Pair){
	            pancakeSellFee = _pancakeSwapSellFee;
	        }
	        
	        payoutFees(sender, recipient, amount);
		    transferFee = amount * 7 + pancakeSellFee / 100;
	    }
		
		_balances[sender] -= amount;
		_balances[recipient] += amount - transferFee;
		
		emit Transfer(sender, recipient, amount);
	}
	

    //*****************************************************************************
    //*********************  Standard IBEP20 Function calls  **********************
    //*****************************************************************************

	function getOwner() external view returns (address) {
		return owner();
	}

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function totalSupply() override external view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address account) override external view returns (uint256) {
		return _balances[account];
	}
	
	function transfer(address recipient, uint256 amount) override external returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
	    
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
		return true;
	}
	
	function allowance(address owner, address spender) override external view returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) override external returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}
	
	function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
		return true;
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}
	
}