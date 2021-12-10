/*
 *                                                     __----~~~~~~~~~~~------___
 *                                    .  .   ~~//====......          __--~ ~~
 *                    -.            \_|//     |||\\  ~~~~~~::::... /~
 *                 ___-==_       _-~o~  \/    |||  \\            _/~~-
 *         __---~~~.==~||\=_    -_--~/_-~|-   |\\   \\        _/~
 *     _-~~     .=~    |  \\-_    '-~7  /-   /  ||    \      /
 *   .~       .~       |   \\ -_    /  /-   /   ||      \   /
 *  /  ____  /         |     \\ ~-_/  /|- _/   .||       \ /
 *  |~~    ~~|--~~~~--_ \     ~==-/   | \~--===~~        .\
 *           '         ~-|      /|    |-~\~~       __--~~
 *                       |-~~-_/ |    |   ~\_   _-~            /\
 *                            /  \     \__   \/~                \__
 *                        _--~ _/ | .-~~____--~-/                  ~~==.
 *                       ((->/~   '.|||' -_|    ~~-/ ,              . _||
 *                                  -_     ~\      ~~---l__i__i__i--~~_/
 *                                  _-~-__   ~)  \--______________--~~
 *                                //.-~~~-~_--~- |-------~~~~~~~~
 *                                       //.-~~~--\
 *                       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;



import "./Uniswap.sol";
import "./SuperERC20.sol";


abstract contract BPContract{
function protect( address sender, address receiver, uint256 amount ) external virtual;
}

contract Token is SuperERC20 {
    using SafeMath for uint256;

    // uint256 public maxSupply = 1000 * 10**6 * 10**18;
    uint256 public maxSupply = 1000000000 * 10**18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public antiBotEnabled;
    uint256 public antiBotDuration = 10 minutes;
    uint256 public antiBotTime;
    uint256 public antiBotAmount;

    address WBNB = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    constructor()
        SuperERC20('TMonsterBattleCoin', "TMBC") 
    {
        _mint(_msgSender(), maxSupply);
        
        // test
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        
        // prd
        // PancakeSwap
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(WBNB, address(this));

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        
        excludeFromFees(address(this), true);
        excludeFromFees(_msgSender(), true);

    }
    
    
    //Anti bots
    mapping(address => bool) bots;

    // function setBlacklists(address _bots) external onlyOwner {
    //     require(!bots[_bots]);
    //     bots[_bots] = true;
    // }
    
    function antiBot(uint256 amount) external onlyOwner {
        require(amount > 0, "not accept 0 value");
        require(!antiBotEnabled);

        antiBotAmount = amount;
        antiBotTime = block.timestamp.add(antiBotDuration);
        antiBotEnabled = true;
    }
    
    mapping (address => bool) private _isExcludedFromFees;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
     function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    bool public useFee;

    function setUseFee(bool value)public onlyOwner{
        require(useFee != value, "Use fee The current status is this");
        useFee = value;
    }

    bool public useSweepTokenForBosses;

    function setUseSweepTokenForBosses(bool value)public onlyOwner{
        useSweepTokenForBosses = value;
    }

    BPContract public BP;
    bool public bpEnabled;
    bool public BPDisabledForever = false;

    function setBPAddrss(address _bp) external onlyOwner { 
        require(address(BP)== address(0), "Can only be initialized once"); 
        BP = BPContract(_bp);
    }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled; 
    }
    function setBotProtectionDisableForever() external onlyOwner{
        require(BPDisabledForever == false);
        BPDisabledForever = true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (bpEnabled && !BPDisabledForever){
            BP.protect(sender, recipient, amount);
        }

        if (
            antiBotTime > block.timestamp &&
            amount > antiBotAmount &&
            bots[sender]
        ) {
            revert("Anti Bot");
        }
        
        if (useSweepTokenForBosses && recipient == uniswapV2Pair){
            _sweepTokenForBosses();
        }
        
        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellFeeRate : buyFeeRate;
            // : (sender == uniswapV2Pair ? buyFeeRate : 0);

        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this) &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient] &&
            useFee
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, address(this), _fee); // Transfer fee to this token, We had to do it for the longevity of the project!
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function _sweepTokenForBosses() internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForBosses) {
            swapTokensForEth(tokenForBosses);
        }
    }
    
    function sweepTokenForBosses() public onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForBosses) {
            swapTokensForEth(tokenForBosses);
        }
    }

    // receive eth from uniswap swap
    // receive() external payable {}
    
    function OwnerSafeWithdrawalEth(uint256 amount) public onlyOwner{
        if (amount == 0){
            address(uint160(owner())).transfer(address(this).balance);
            return;
        }
        address(uint160(owner())).transfer(amount);
    }

    function OwnerSafeWithdrawalToken(address token_address, uint256 amount) public onlyOwner{
        IERC20 token_t = IERC20(token_address);
        if (amount == 0){
            token_t.transfer(owner(), token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner(), amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            addressForBosses, // The contract
            block.timestamp
        );

        // make the swap
        // try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        //     tokenAmount,
        //     0, // accept any amount of ETH
        //     path,
        //     addressForBosses, // The contract
        //     block.timestamp
        // ){

        // }catch{

        // }
    }

    function setAddressForBosses(address _addressForBosses) external onlyOwner {
        require(_addressForBosses != address(0), "0x is not accepted here");

        addressForBosses = _addressForBosses;
    }
    
    
}