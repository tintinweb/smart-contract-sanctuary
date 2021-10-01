/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// File: PoolCleaner.sol

// Be name Khoda

// Bime Abolfazl



pragma solidity ^0.8.0;



/*



Before calling any method:

1. Transfer all LP tokens to the contract (UniDD, UniDE, UniDU, UniDUniDeusUsdc, UniDeaEth)

2. Add Minter and Burner role of Dea and Deus tokens to the contract



*/





interface IERC20 {





    function totalSupply() external view returns (uint256);



    function balanceOf(address account) external view returns (uint256);



    function allowance(address owner, address spender) external view returns (uint256);





    function transfer(address recipient, uint256 amount) external returns (bool);



    function approve(address spender, uint256 amount) external returns (bool);



    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



	function mint(address to, uint256 amount) external;

	

    function burn(address from, uint256 amount) external;



    event Transfer(address indexed from, address indexed to, uint256 value);



    event Approval(address indexed owner, address indexed spender, uint256 value);



}



interface IUniswapV2Router {

    function removeLiquidity(

        address tokenA,

        address tokenB,

        uint liquidity,

        uint amountAMin,

        uint amountBMin,

        address to,

        uint deadline

    ) external returns (uint amountA, uint amountB);

    

    function swapExactTokensForTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external returns (uint[] memory amounts);

}





contract PoolCleaner {

    

    IUniswapV2Router public router;

    IERC20 public uniDD;

    IERC20 public uniDE;

    IERC20 public uniDU;

    IERC20 public uniDeaEth;

    IERC20 public uniDeusUsdc;

    IERC20 public dea;

    IERC20 public deus;

    IERC20 public eth;

    IERC20 public usdc;

    address public balancerPoolAddress;

    address public account;

    address public deployer;

   

    constructor(

        IUniswapV2Router _router,

        address _balancerPoolAddress,

        IERC20 _uniDD,

        IERC20 _uniDE,

        IERC20 _uniDU,

        IERC20 _uniDeaEth,

        IERC20 _uniDeusUsdc

        ) {

        

        router = _router;

        balancerPoolAddress = _balancerPoolAddress;

        uniDD = _uniDD;

        uniDE = _uniDE;

        uniDU = _uniDU;

        uniDeaEth = _uniDeaEth;

        uniDeusUsdc = _uniDeusUsdc;

        

        deployer  = msg.sender;

        

        uniDD.approve(address(router), type(uint).max);

        uniDE.approve(address(router), type(uint).max);

        uniDU.approve(address(router), type(uint).max);

        uniDeaEth.approve(address(router), type(uint).max);

        uniDeusUsdc.approve(address(router), type(uint).max);



    }

    

    function init(

        IERC20 _dea,

        IERC20 _deus,

        IERC20 _eth,

        IERC20 _usdc,

        address _account

        

        ) public {



        require(msg.sender == deployer, "Only deployer can call this method");

       

        dea = _dea;

        deus = _deus;

        eth = _eth;

        usdc = _usdc;

        account = _account;

    }

    

    

    function removeLiquidity(uint deadline) private {

        address contractAddress = address(this);

        uint balance = uniDD.balanceOf(contractAddress);

        if(balance != 0) {

            router.removeLiquidity(address(dea), address(deus), balance, 0, 0, contractAddress, deadline);

        }



        balance = uniDE.balanceOf(contractAddress);

        if(balance != 0) {

            router.removeLiquidity(address(deus), address(eth), balance, 0, 0, contractAddress, deadline);

        }



        balance = uniDU.balanceOf(contractAddress);

        if(balance != 0) {

            router.removeLiquidity(address(dea), address(usdc), balance, 0, 0, contractAddress, deadline);

        }

        

        balance = uniDeaEth.balanceOf(contractAddress);

        if(balance != 0) {

            router.removeLiquidity(address(dea), address(eth), balance, 0, 0, contractAddress, deadline);

        }

        

        balance = uniDeusUsdc.balanceOf(contractAddress);

        if(balance != 0) {

            router.removeLiquidity(address(deus), address(usdc), balance, 0, 0, contractAddress, deadline);

        }

    }

    

    function mintTokens() private {

        uint deaMintAmount = dea.balanceOf(address(uniDD)) + dea.balanceOf(address(uniDU)) + 2 * 10 ** 30;

        uint deusMintAmount = deus.balanceOf(address(uniDD)) + deus.balanceOf(address(uniDE)) + 2 * 10 ** 30;

         

        dea.mint(address(this), deaMintAmount);

        deus.mint(address(this), deusMintAmount);

    }

    

    function swapTokens(uint deadline) private {

        

        dea.approve(address(router), 2 * 10 ** 30);

        deus.approve(address(router), 2 * 10 ** 30);



        

        address[] memory path = new address[](2);

        

        // Dea - usdc

        

        path[0] = address(dea);

        path[1] = address(usdc);

        router.swapExactTokensForTokens(

            10 ** 30,

            0,

            path,

            address(this),

            deadline

        );

        

        // Deus - Eth



        path[0] = address(deus);

        path[1] = address(eth);

        router.swapExactTokensForTokens(

            10 ** 30,

            0,

            path,

            address(this),

            deadline

        );

        

        // Dea - Eth

        

        path[0] = address(dea);

        path[1] = address(eth);

        router.swapExactTokensForTokens(

            10 ** 30,

            0,

            path,

            address(this),

            deadline

        );

        

        // Deus - Usdc



        path[0] = address(deus);

        path[1] = address(usdc);

        router.swapExactTokensForTokens(

            10 ** 30,

            0,

            path,

            address(this),

            deadline

        );

    }

    

    function burnTokens() private {

        dea.burn(address(uniDD), dea.balanceOf(address(uniDD)));

        deus.burn(address(uniDD), deus.balanceOf(address(uniDD)));



        dea.burn(address(uniDU), dea.balanceOf(address(uniDU)));



        deus.burn(address(uniDE), deus.balanceOf(address(uniDE)));

        

        dea.burn(address(uniDeaEth), dea.balanceOf(address(uniDeaEth)));



        deus.burn(address(uniDeusUsdc), deus.balanceOf(address(uniDeusUsdc)));



    }

    

    function clearBalancerPool() private {

        uint balance = dea.balanceOf(balancerPoolAddress);

        dea.burn(balancerPoolAddress, balance);

        dea.mint(address(this), balance);

    }

    

    function transferTokens() private {

        dea.transfer(account, dea.balanceOf(address(this)));

        deus.transfer(account, deus.balanceOf(address(this)));

        usdc.transfer(account, usdc.balanceOf(address(this)));

        eth.transfer(account, eth.balanceOf(address(this)));

    }

    

    function cleanPools(uint deadline) public {

        

        require(msg.sender == deployer, "Only deployer can call this method");

        

        // Remove liquidity using pool tokens

        

        removeLiquidity(deadline);

        

        // Mint requiring dea & deus amount

        

        mintTokens(); // tested: needs roles

        

        // Swap tokens to extract remaining amounts

        

        swapTokens(deadline);

        

        // Burn remainings in pools

        

        burnTokens();

        

        // Clear balancer pool

        

        clearBalancerPool();

        

        // Transfre everything to account 

        

        transferTokens();

    }

    

    function withdrawERC20(address tokenAddress, address to, uint amount) public {



        require(msg.sender == deployer, "Only deployer can call this method");

        

        IERC20(tokenAddress).transfer(to, amount);

    }

    

    

}



//Dar panah khoda