// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract DYTToken is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    mapping(address => bool) public blacklistedAddr;
    mapping(address => bool) public whitelistAddr;
    
    uint256 public sellFee = 5;
    uint256 public buyFee =2;
    uint256 maxAmount =  50 * 10**3 * 10**18;

    //Bot Protection
    bool public botProtectEnabled;
    uint256 public maxFastestBuyersBlacklist = 10;
    uint256 public fastestBuyers =1;
    //MKT
    address public mktAddr = 0xeC0c24FE2Ed12165eD649A9A9C5B988C85111716;
    uint256 public swapTokensAtAmount = 10 * 10**3 * 10**18;
    
     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    constructor() public ERC20("DYT TOKEN", "DYT") {
        //mainnet
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
             .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        //whitelist address
        //whitelistAddr[address(_uniswapV2Router)] = true;
        whitelistAddr[owner()] =true;
        whitelistAddr[mktAddr] = true;
        whitelistAddr[address(this)] = true;
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(mktAddr, true);
        excludeFromFees(address(this), true);
        //enable Botprotect
        botProtectEnabled = true;
        _mint(owner(), 30000000 * (10**18));
    }

    receive() external payable {
        require(whitelistAddr[msg.sender] , 'Whitelisted address');
  	}

    function setFee(uint256 _sellFee, uint256 _buyFee) public onlyOwner{
        require(1<= _sellFee && _sellFee <=15, "SellFee range from 1 to 15");
        require(1<= _buyFee && _buyFee <=15, "BuyFee range from 1 to 15");
        sellFee = _sellFee;
        buyFee = _buyFee;
    } 

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }
    function setMaxFastestBuyersBlacklist(uint256 _maxFastestBuyersBlacklist) external onlyOwner{
        maxFastestBuyersBlacklist = _maxFastestBuyersBlacklist;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already excluded");
        _isExcludedFromFees[account] = excluded;

    }
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function blacklistMultipleAddrs(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            blacklistedAddr[accounts[i]] = excluded;
        }
    }

    function setMktAddress(address  _wallet) external onlyOwner{
        require(_wallet != address(0), "Invalid Address");
        mktAddr = _wallet;
    }

    
    function blacklistAddress(address account, bool value) external onlyOwner{
        require(account != address(this), "Cannot blacklist contract address");
        require(account != uniswapV2Pair, "Cannot blacklist Pair address");
        blacklistedAddr[account] = value;
    }

    function whitelistAddress(address account, bool value) external onlyOwner{
        whitelistAddr[account] = value;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //Bot Protect
        require(amount >0 , "amount = 0");
        if (amount > maxAmount){
            require(whitelistAddr[from],"maxAmount");
        }
        require(!blacklistedAddr[from], "Blacklist sender");
        require(!blacklistedAddr[to], "Blacklist receiver");

        if(botProtectEnabled ){
            if (fastestBuyers <= maxFastestBuyersBlacklist) {
                if (from == uniswapV2Pair && !whitelistAddr[to]){ 
                    blacklistedAddr[to] = true; 
                    fastestBuyers ++;
                }   
                else if (to == uniswapV2Pair && !whitelistAddr[from]){
                    blacklistedAddr[from] = true; 
                    fastestBuyers ++;
                }
            }
        }

        uint256 transferFee = to == uniswapV2Pair
            ? sellFee
            : (from == uniswapV2Pair ? buyFee : 0);

        if (
            transferFee > 0 &&
            from != address(this) &&
            to != address(this) 
        ) {
            uint256 _fee = amount.mul(transferFee).div(100);
            super._transfer(from, address(this), _fee); 
            amount = amount.sub(_fee);
        }

        super._transfer(from, to, amount);
        
    }
    
    function setMaxAmount(uint256 _maxAmount) external onlyOwner{
        maxAmount = _maxAmount;
    }

    function setBotProtectEnabled(bool _botProtectEnabled) external onlyOwner{
        botProtectEnabled = _botProtectEnabled;
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner{
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function swapForMkt() public nonReentrant {
        uint256 _contractBalance = balanceOf(address(this));
        require(_contractBalance >= swapTokensAtAmount, "contractBalance < swapTokensAtAmount");
        swapTokensForEth(swapTokensAtAmount);
        
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
            mktAddr,
            block.timestamp
        );
    }

}