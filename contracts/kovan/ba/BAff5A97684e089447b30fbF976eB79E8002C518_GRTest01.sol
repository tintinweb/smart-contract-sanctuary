/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Following contracts and interfaces are flattened imports of ChainLink, ERC20 and UniV2Router
// These are required to verify the contract
// GorillaRug contract code starts on line 364

contract VRFRequestIDBase {

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

abstract contract VRFConsumerBase is VRFRequestIDBase {

  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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


contract GRTest01 is Context, IERC20, VRFConsumerBase {

    // Variables for contract lifecycle and transaction fees
    mapping (uint256 => uint) private _epochTimestamp;
    mapping (uint16 => uint16) private _epochTax;
    mapping (uint16 => uint16) private _epochBurn;
    uint16 private _epoch;
    uint16 private _flatBuyFee = 5;
    bool private _liquifying;
    
    uint256 private _start = 1639500900; // Contract starts

    // Variables for selecting winners
    address[] private winnersPool;
    address[] private winners;
    bool private winnersSelected = false;
    
    // Variables required for Chainlink to work
    bytes32 private _keyHash;
    uint256 private _fee;
    
    // Variables for tokens to work
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => uint256) private _lastBuyTransactionBlock;
    mapping (address => uint256) private _lastSellTransactionBlock;

    uint256 private constant _totalSupply = 10 * 10**6 * 10**18; // Ten million total supply

    // Token info
    string private _name = "GRTest01";
    string private _symbol = "GRT01";
    uint8 private _decimals = 18;

    // Wallet addresses
    address payable private _devWallet = payable(0x5e608Ed6782D5d0Ea8547647e55e11793F303A4B);
    address private _lpWallet = 0x6D1A2c4979939133D705899954aA33527d533209;
    address payable private _buyBackWallet = payable(0x90B10B9D3228351c6D072b3596D78cEd0C4dc80c);
    address private _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Canonical address for Uniswap Router02
    address private _pairAd = address(0); // Pair address

    IUniswapV2Router02 private UniV2Router;

    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee) VRFConsumerBase(vrfCoordinator, link) {
        _epoch = 0;
        // Contract lifecicle timestamps
        _epochTimestamp[0] = _start;
        _epochTimestamp[1] = _start + 10 minutes;
        _epochTimestamp[2] = _start + 20 minutes;
        _epochTimestamp[3] = _start + 30 minutes;
        _epochTimestamp[4] = _start + 40 minutes;
        _epochTimestamp[5] = _start + 55 minutes;
        // Taxation values
        _epochTax[0] = 5;
        _epochTax[1] = 4;
        _epochTax[2] = 3;
        _epochTax[3] = 2;
        _epochTax[4] = 0;
        // Buyback values
        _epochBurn[0] = 20;
        _epochBurn[1] = 16;
        _epochBurn[2] = 12;
        _epochBurn[3] = 8;
        _epochBurn[4] = 20;
        // Requred data to create a pool
        _balances[_lpWallet] = _totalSupply;
        UniV2Router = IUniswapV2Router02(_uniRouter);
        // Required data to use Chainlink
        _keyHash = keyHash;
        _fee = fee;
    }

    modifier noRecursion {
        _liquifying = true;
        _;
        _liquifying = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // Prevent transaction from being sandwiched
    // Does not allow both buy and sell from one address during the same block
    function isSandwich(address sender, address recipient, address pair) private returns (bool) {
        // Buy logic
        if (sender == pair) {
            if (block.number == _lastSellTransactionBlock[recipient])
                return true;
            _lastBuyTransactionBlock[recipient] = block.number;
        // Sell logic
        } else if (recipient == pair) {
            if (block.number == _lastBuyTransactionBlock[sender])
                return true;
            _lastSellTransactionBlock[sender] = block.number;
        }
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        // Check to be sure epoch is set correctly
        _checkEpoch();

        // One-time set pair address during addLiquidity, since that should be the first use of this function
        if (_pairAd == address(0) && sender != address(0)) {
            _pairAd = recipient;
        }
        
        // Ensure we're within the contract lifecycle limits and the transaction is not a sandwich pair,
        // unless it's the LP or the Uni router (for add/removeLiquidity)
        if (sender != _lpWallet && recipient != _lpWallet && recipient != _uniRouter && sender != address(this))
        {
            require(!isSandwich(sender, recipient, _pairAd));
            require (block.timestamp >= _epochTimestamp[0] && block.timestamp <= _epochTimestamp[5], "No trades at this time");
            // Token limit of 350000 for the first 15 minutes
            require (amount <= (_totalSupply * 35 / 1000) || block.timestamp >= _epochTimestamp[0] + 15 minutes);
        }
        

        // The usual ERC20 checks
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "Transfer = 0");
        
        // Set defaults for fallback
        uint256 amountRemaining = amount;
        uint256 taxes = 0;
        uint256 buyBack = 0;

        // Logic for buys
        if (sender == _pairAd && recipient != _lpWallet && recipient != _uniRouter && recipient != _buyBackWallet)
        {
            taxes = amount * _flatBuyFee / 100;
            amountRemaining = amount - taxes;
            
            // If it is the last epoch and the amount bought is more than 10000, the buyer is added to pottential winners' list
            if (block.timestamp > _epochTimestamp[4] && block.timestamp <= _epochTimestamp[5] && amount >= 10**4 * 10**18) {
                winnersPool.push(recipient);
            }
            
            // Nothing is liquified at this point to make transaction cheaper for the buyer
        }
        
        // Logic for sells
        if (recipient == _pairAd && sender != _lpWallet && sender != address(this))
        {
            taxes = amount * _epochTax[_epoch] / 100;
            amountRemaining = amount - taxes;

            buyBack = amount * _epochBurn[_epoch] / 100;
            amountRemaining = amountRemaining - buyBack;
        }
        
        _balances[address(this)] += buyBack;        
        _balances[address(this)] += taxes;
        if (_balances[address(this)] > 100 * 10**18 && !_liquifying && recipient == _pairAd){
            if (_balances[address(this)] >= buyBack) {
                uint256 _taxAmount = _balances[address(this)] - buyBack;
                if (_taxAmount > amount * 10 / 100) _taxAmount = amount * 10 / 100;
                uint256 _liquidateAmount = buyBack + _taxAmount;
                // Calculate, which percent of the liquidate amount the buyback takes
                uint256 _buyBackPercent = buyBack * 100 / _liquidateAmount;
                // Liquidate and transfer buyback and tax money to corresponding accounts
                // Done as a single operation to prevent additional transaction costs on extra swaps and transfers
                liquidateTokensWithTaxes(_liquidateAmount, _buyBackWallet, _buyBackPercent, _devWallet);
            }
        }

        _balances[recipient] += amountRemaining;
        _balances[sender] -= amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _checkEpoch() private {
        if (_epoch == 0 && block.timestamp >= _epochTimestamp[1]) _epoch = 1;
        if (_epoch == 1 && block.timestamp >= _epochTimestamp[2]) _epoch = 2;
        if (_epoch == 2 && block.timestamp >= _epochTimestamp[3]) _epoch = 3;
        if (_epoch == 3 && block.timestamp >= _epochTimestamp[4]) _epoch = 4;
        if (_epoch == 4 && block.timestamp >= _epochTimestamp[5]) _epoch = 5;
    }

    function currentEpoch() public view returns (uint16){
        return _epoch;
    }

    function pairAddr() public view returns (address){
        return _pairAd;
    }

    function sendETH(uint256 amount, address payable _to) private {
        (bool sent,) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Liqudate for a single address
    function liquidateTokens(uint256 amount, address payable recipient) private noRecursion {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        if (address(this).balance > 0) sendETH(address(this).balance, recipient);
    }
    
    // Liquidate percent of the amount for an address and send reminder to tax address
    function liquidateTokensWithTaxes(uint256 amount, address payable recipient, uint256 percent, address payable taxRecipient) private noRecursion {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        uint256 buyBackAmount = address(this).balance * percent / 100;

        if (address(this).balance > 0) sendETH(buyBackAmount, recipient);
        if (address(this).balance > 0) sendETH(address(this).balance, taxRecipient);
    }

    function emergencyWithdrawETH() external {
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        (bool sent,) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    
    function withdrawRemaining() external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _devWallet, "Unauthorized");
        liquidateTokens(_balances[address(this)], _devWallet);
    }
    
    // Generates a list of winners. Can be called only once
    function getWinners() external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        require (!winnersSelected, "Already selected"); // Prevent a second call of the function
        if (winnersPool.length <= 3) {
            winners = winnersPool; // If less than 10 winners in winnersPool - all are winners
        } else {
            require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK - fill contract with faucet");
            requestRandomness(_keyHash, _fee); // Generate a random number
        }
        winnersSelected = true;
    }
    
    // Generates a list of winners. Can be called only if getWinners was not successful
    // The purpose of this function is to retry the randomness request, if the original
    // one failed due to wrong amount of LINK
    function emergencyGetWinners(uint256 overrideFee) external {
        require (block.timestamp > _epochTimestamp[5], "The game is still in progress"); // Prevent from being called until the game is finished
        require (_msgSender() == _buyBackWallet || _msgSender() == _devWallet, "Unauthorized");
        require (winners.length == 0, "Already selected"); // Don't allow to call if the original succeeded
        if (winnersPool.length <= 3) {
            winners = winnersPool; // If less than 10 winners in winnersPool - all are winners
        } else {
            require(LINK.balanceOf(address(this)) >= overrideFee, "Not enough LINK - fill contract with faucet");
            requestRandomness(_keyHash, overrideFee); // Generate a random number
        }
        winnersSelected = true;
    }
    
    function showWinners() view public returns(address[] memory) {
        return winners;
    }
    
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        uint256 randomNumber = randomness;
        for (uint8 i = 0; i < 3; i++) {
            if (i != 0) {
                // Generate a random number based on the previous winner's address
                // Divide by 2 to prevent possible overflow and add more randomness
                randomNumber = randomNumber / 2 + uint256(uint160(winners[i - 1])) / 2;
            }
            uint16 randomIndex = uint16(randomNumber % winnersPool.length);
            rememberWinner(randomIndex);
        }
    }
    
    function rememberWinner(uint256 index) private {
        // Add the winner
        address winner = winnersPool[index];
        winners.push(winner);
        // Remove from winnersPool to ensure that this enrty won't be selected twice
        winnersPool[index] = winnersPool[winnersPool.length - 1];
        winnersPool.pop();
    }

    receive() external payable {}

    fallback() external payable {}
}