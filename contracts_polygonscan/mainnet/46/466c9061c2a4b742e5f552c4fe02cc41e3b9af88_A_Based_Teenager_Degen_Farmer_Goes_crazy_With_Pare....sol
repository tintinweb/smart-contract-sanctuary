/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

// SPDX-License-Identifier: MIT-0
// so if you happen to stumble across this contract, its coded by a teenage polygon layer-2 ponzi-loving degenerate yield farmer who sucks at solidity, but wants to learn :D
/*
    |--\     /---\    |---\    |----   |----\        |----\    /---\     /----       
    |   |   |     |   |    |   |       |     |       |     |  |     |   |            
    |--<    |     |   |---/    |----   |     |       |____/   |     |   |  ---\      
    |   |   |     |   |   \    |       |     |       |        |     |   |      |     
    |__/     \___/    |    |   |____   |____/        |         \___/     \____/      
    |----\    /---\     /----       
    |     |  |     |   |            
    |____/   |     |   |  ---\      
    |        |     |   |      |     
    |         \___/     \____/      
    |----\    /---\     /----       
    |     |  |     |   |            
    |____/   |     |   |  ---\      
    |        |     |   |      |     
    |         \___/     \____/    
    |----\    /---\     /----       
    |     |  |     |   |            
    |____/   |     |   |  ---\      
    |        |     |   |      |     
    |         \___/     \____/    
*/
// My dad turned off the wifi cuz of parental controls
// But I want to learn more solidity >:(
// I'm earning more than my teachers with yield degening
// I'm scared my GFI rewards will dump in price when I wake up
// All I want is a simple compounder
// I need wifi to deploy this contract
// hiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii anyone see this comment hiiiii eeeeeee

// Harvesting $GFI rewards > trigonometry homework WHYWHYWHY its 12 am and I did nothing whinecry cry pepe
// 4chan /biz/   >   English Presentation
// I am gonna rope reeeee eee ee ee  ee eee.. e e cope
// Do comments cost more gas when deploying this contract
// LET ME DEPLOY MY CONTRACT DAD I WANT TO COMPOUND MY GRAVITY TOKENS
// I HATE PARENTAL CONTROLS
// pls help someone plsssssssssss im done with this contract helppp wwwweee eee.
// slowly going crazy, the only thing I can do is write comments or play offline Minecraft
// AT LEAST LET ME DO SOMETHING PRODUCTIVE LIKE..... READ SOLIDITY DOCS >:((((((((((((((()))))))))))))))
// WHYWHYWYHYWHYWHWYHWYHWYH I want to watch Youtube or Crunchyroll until 6 am plssssssssssssssssssssssssssssssss
// Massive AoT and USDC Maxi :LMAO:
// Discord frens i want to talk to you I hate offline im too addicted im to degenerate pepega pepeplease pepegeg cryga

pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IGFIRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IGFIFarmV2 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function emergencyWithdraw() external;
}

contract A_Based_Teenager_Degen_Farmer_Goes_crazy_With_Parental_controls_no_wifi_to_learn_solidity_not_Pog_Poggers_CRYGA_Slowly_Going_Crazy {
    
    address public owner;
    IERC20 public GLP = IERC20(0x42286296C3edE3f6a0ec4e687939b017408Cf321);
    IERC20 public GFI = IERC20(0x874e178A2f3f3F9d34db862453Cd756E7eAb0381);
    IERC20 public USDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IGFIRouter public GFIRouter = IGFIRouter(0x57dE98135e8287F163c59cA4fF45f1341b680248);
    IGFIFarmV2 public GFIFarm = IGFIFarmV2(0xe3bC11531D78Ce351Db9D2f0eC270B863FaC1C07);
    
    uint constant TWENTY_MINUTES = 1200;

    constructor() {
        owner = msg.sender;
        GLP.approve(address(GFIFarm), 2**256 - 1);
        GFI.approve(address(GFIRouter), 2**256 - 1);
        USDC.approve(address(GFIRouter), 2**256 - 1);
        USDT.approve(address(GFIRouter), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "GFICompounder: caller is not the owner");
        _;
    }

    function depositGLP() public onlyOwner {
        require(GLP.balanceOf(address(this)) != 0, "GFICompounder: No GLP tokens to stake");
        GFIFarm.deposit(GLP.balanceOf(address(this)));
    }

    function emergencyWithdrawFromGFarm() public onlyOwner {
        GFIFarm.emergencyWithdraw();
        GLP.transfer(owner, GLP.balanceOf(address(this)));
    }

    function claimReward() public onlyOwner {
        GFIFarm.withdraw(0);
    }

    function claimRewardToOwner() public onlyOwner {
        GFIFarm.withdraw(0);
        GFI.transfer(owner, GFI.balanceOf(address(this)));
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function compound() public onlyOwner {
        GFIFarm.withdraw(0);

        if (address(GFI) != address(USDC)) {
            uint256 remainingHarvested = GFI.balanceOf(address(this));
            if (remainingHarvested > 0) {
                _swapForUSDC();
            }
        }

        uint256 _balanceA = USDC.balanceOf(address(this));
        if (_balanceA > 0) {
            _swapHalfUSDCForUSDT();
        }

        uint256 aBalance = USDC.balanceOf(address(this));
        uint256 bBalance = USDT.balanceOf(address(this));
        
        if (aBalance > 0 && bBalance > 0) {
            GFIRouter.addLiquidity(
                address(USDC), address(USDT),
                aBalance, bBalance,
                0, 0,
                address(this),
                block.timestamp + TWENTY_MINUTES
            );
        }

        GFIFarm.deposit(GLP.balanceOf(address(this)));
        /*
            GFIFarm.withdraw(0);
            swapForUSDC();
            swapHalfUSDCforUSDT();
            addUSDCUSDTLPs();
        */
    }

    function addUSDCUSDTLPs() public onlyOwner {
        GFIRouter.addLiquidity(
            address(USDC),
            address(USDT),
            USDC.balanceOf(address(this)),
            USDT.balanceOf(address(this)),
            0,
            0,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function _swapForUSDC() public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(GFI);
        path[1] = address(USDC);

        GFIRouter.swapExactTokensForTokens(
            (GFI.balanceOf(address(this))),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function _swapHalfUSDCForUSDT() public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(USDT);

        GFIRouter.swapExactTokensForTokens(
            (USDC.balanceOf(address(this))/2),
            0,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "GFICompounder: external call failed");
        return result;
    }
}