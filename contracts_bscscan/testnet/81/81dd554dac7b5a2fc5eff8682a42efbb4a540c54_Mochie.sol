// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Mochie is ERC20, Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private inSwapAndLiquify;

    bool public swapAndLiquifyEnabled = true;

    uint256 public maxTxAmount = 5 * 10**5 * (10**18);//0.5% of supply;
    uint256 public maxWalletAmount = 10**6 * (10**18);//1% of supply

    uint256 public swapTokensAtAmount = 2 * 10**5 * (10**18); //0.2% of supply
    
    struct feeRatesStruct {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
    }

    feeRatesStruct public feeRates = feeRatesStruct(
     {buy: 5,    
      sell: 9,
      transfer: 5
    });

    address payable public  marketingWallet;


    // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private _isExcludedFromMaxTx;

    mapping (address => bool) private _isExcludedFromMaxWallet;
    
    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxTx(address indexed account, bool isExcluded);
    event ExcludeFromMaxWallet(address indexed account, bool isExcluded);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event ExcludeMultipleAccountsFromMaxTx(address[] accounts, bool isExcluded);
    event ExcludeMultipleAccountsFromMaxWallet(address[] accounts, bool isExcluded);
    event ExcludeMultipleAccountsFromAll(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapTokensAtAmountUpdated(uint256 amount);
    event MaxTxAmountUpdated(uint256 amount);
    event MaxWalletAmountUpdated(uint256 amount);


    event SwapAndLiquify(
        uint256 tokensIntoLiqudity,
        uint256 bnbReceived
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("Mochie", "MOC") {

        marketingWallet = payable(0x9f5c0B3691C07018d1daE9131f8E0813E21F39Ce);

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        excludeFromMaxWallet(_uniswapV2Pair, true);

        excludeFromAll(owner(), true);
        excludeFromAll(marketingWallet, true);
        excludeFromAll(address(this), true);

        _mint(owner(), 10**8 * (10**18));
    }

    receive() external payable {

  	}

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_isExcludedFromMaxTx[from] || _isExcludedFromMaxTx[to] || amount<= maxTxAmount, "Cannot transfer more than maxTxAmount");


        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

    	uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= swapTokensAtAmount;
       
        if(
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] && 
            swapAndLiquifyEnabled
        ) {
            swapTokensForEth(swapTokensAtAmount);
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            uint256 appliedFee;
            
            if(automatedMarketMakerPairs[from])
            {
                appliedFee = feeRates.buy;
            }
            else if(automatedMarketMakerPairs[to])
            {
                appliedFee = feeRates.sell;
            }
            else
            {
            appliedFee = feeRates.transfer;
            }

        	uint256 fees = (amount*appliedFee)/100;
        	amount -= fees;
            super._transfer(from, address(this), fees);
        }
        require(_isExcludedFromMaxWallet[to] || balanceOf(to)+amount<= maxWalletAmount, "Cannot transfer more than maxWalletAmount");
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap{
  
        // generate the uniswap pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if(allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
          _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            marketingWallet,
            block.timestamp
        );
        
    }

    function rescueBNBFromContract() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //setters

    function setMarketingWallet(address payable _address) external onlyOwner{
        marketingWallet = _address;
        _isExcludedFromFees[marketingWallet] = true;
    }

    function setFees(uint256 buy, uint256 sell, uint256 transfer) external onlyOwner{
        feeRates.buy = buy;
        feeRates.sell = sell;
        feeRates.transfer = transfer;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        maxTxAmount = amount;
        emit MaxTxAmountUpdated(amount);
    }

    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        maxWalletAmount = amount;
        emit MaxWalletAmountUpdated(amount);
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
        emit SwapTokensAtAmountUpdated(amount);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Mochie: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Mochie: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Mochie: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "_isExcludedFromFees  already set to that value");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

     function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxTx[account] != excluded, "_isExcludedFromMaxTx  already set to that value");
        _isExcludedFromMaxTx[account] = excluded;

        emit ExcludeFromMaxTx(account, excluded);
    }

    function excludeMultipleAccountsFromMaxTx(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromMaxTx[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromMaxTx(accounts, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWallet[account] != excluded, "_isExcludedFromMaxWallet already set to that value");
        _isExcludedFromMaxWallet[account] = excluded;

        emit ExcludeFromMaxWallet(account, excluded);
    }

    function excludeMultipleAccountsFromMaxWallet(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromMaxWallet[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromMaxWallet(accounts, excluded);
    }

    function excludeFromAll(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "_isExcludedFromFees  already set to that value");
        require(_isExcludedFromMaxTx[account] != excluded, "_isExcludedFromMaxTx  already set to that value");
        require(_isExcludedFromMaxWallet[account] != excluded, "_isExcludedFromMaxWallet already set to that value");
        _isExcludedFromMaxWallet[account] = excluded;
        _isExcludedFromFees[account] = excluded;
        _isExcludedFromMaxTx[account] = excluded;

        emit ExcludeFromFees(account, excluded);
        emit ExcludeFromMaxTx(account, excluded);
        emit ExcludeFromMaxWallet(account, excluded);
    }

    function excludeMultipleAccountsFromAll(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromMaxWallet[accounts[i]] = excluded;
            _isExcludedFromFees[accounts[i]] = excluded;
            _isExcludedFromMaxTx[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromAll(accounts, excluded);
    }
    
}