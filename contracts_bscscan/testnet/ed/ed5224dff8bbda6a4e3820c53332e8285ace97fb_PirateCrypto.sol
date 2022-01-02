// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

// bot protect check sender recerver before transfer
// abstract contract BPContract{
//     function protect( address sender, address receiver, uint256 amount ) external virtual;
// }

contract PirateCrypto is ERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    uint256 public sellFee = 1;
    uint256 public buyFee =0;
    uint256 public maxAmount =  200 * 10**3 * 10**18;

    address public mktAddr = 0x1Ce63ebcCCce1dc60ee726EA3Ec8e9b4ccF86653;
    uint256 public swapTokensAtAmount = 10 * 10**3 * 10**18;
     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isWhitelist;
    //Bot Protect
    //BPContract public BP;
    bool public bpEnabled;
    bool public BPDisabledForever = false;

    constructor() ERC20("PIRATES CRYPTO", "PKC") {
        //testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        //mainnet
    	//IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
             .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        setWhitelistAddr(address(this), true);
        setWhitelistAddr(owner(), true);
        setWhitelistAddr(mktAddr, true);

        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {}

    function setFee(uint256 _sellFee, uint256 _buyFee) public onlyOwner{
        require(0<= _sellFee && _sellFee <=10, "SellFee <= 10");
        require(0<= _buyFee && _buyFee <=10, "BuyFee <= 10");
        sellFee = _sellFee;
        buyFee = _buyFee;
    } 


    function setMktAddress(address  _wallet) external onlyOwner{
        require(_wallet != address(0), "Invalid Address");
        mktAddr = _wallet;
    }

    function setWhitelistAddr(address account, bool value) public onlyOwner{
        _isWhitelist[account] = value;
    }

    function isWhitelistAddr(address account) public view returns(bool) {
        return _isWhitelist[account];
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        //Bot Protect
        // if (bpEnabled && !BPDisabledForever){
        //     BP.protect(from, to, amount);
        // }

        require(amount >0 , "amount = 0");
        if (amount > maxAmount && to == uniswapV2Pair && !isWhitelistAddr(from)){
            revert("MaxAmount");
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
        require(_maxAmount > 200 * 10**3 * 10**18, "maxAmount too small");
        maxAmount = _maxAmount;
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner{
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function swapForMkt() public nonReentrant onlyOwner {
        uint256 _contractBalance = balanceOf(address(this));
        require(_contractBalance >= swapTokensAtAmount, "contractBalance < swapTokensAtAmount");
        swapTokensForEth(swapTokensAtAmount);
        
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            mktAddr,
            block.timestamp
        ){}
        catch{}
    }
    //Bot Protect Func
    // function setBPAddrss(address _bp) external onlyOwner {
    //     require(address(BP)== address(0), "Can only be initialized once");
    //     BP = BPContract(_bp);
    // }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }

    function setBotProtectionDisableForever() external onlyOwner{
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }

}