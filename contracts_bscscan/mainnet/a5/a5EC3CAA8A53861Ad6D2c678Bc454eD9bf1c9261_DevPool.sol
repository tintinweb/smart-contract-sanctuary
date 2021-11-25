/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT


// Current Version of solidity
pragma solidity ^0.8.2;

// Spooder Interface
interface SpooderToken {
    //mapping(address => uint) public balances;
    //mapping(address => mapping(address => uint)) public allowance;
    function allowance() external view returns (uint);
    function totalSupply() external view returns (uint);
    // function name() public pure returns (string);
    // function symbol() public pure returns (string);
    function decimals() external view returns (uint);
    function devWallet1() external view returns (address);
    function devWallet2() external view returns (address);
    function lpWallet() external view returns (address);
    function taxWallet() external view returns (address);
    // event Transfer(address indexed from, address indexed to, uint value);
    // event Approval(address indexed owner, address indexed spender, uint value);
    function balanceOf(address) external returns(uint);
    function transfer(address, uint) external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
    function approve(address, uint) external returns (bool);
}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}
// Pancakeswap Interface
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

// Main Contract
contract DevPool {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 100000000 * (10 ** 18);
    string public name = "Development Pool";
    string public symbol = "POOL-DEV";
    uint public decimals = 18;
    uint public totalWebbed = 0;
    // Tax Wallet
    address public taxWallet = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    // Web Wallet
    address public webWallet = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    // SPOOD Contract address
    address public contractSPOOD = 0x8A34a903ad540BbD6bBb91d37fCc6b57E68FEC54;
    address public contractWEB;
    // WBNB Contract address
    address public contractWBNB = 0xB33662186c4FCFAFc2E4Ca9A8F08a4840200ad5d;
        
    address[] public usersWebbed;
    address public user;
    uint public userReward;
    uint public rewardVectorLength = 0;
    uint initialBalance;
    
    uint256 public minWebSPOOD = 100000 * (10 ** 18);
    uint256 public minWebBNB = 0.05 * (10 ** 18);
    uint public liquidityAmount;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    event Web(address indexed from, uint value);
    event UnWeb(address indexed to, uint value);
    event UpdateRewards(uint value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 tokensIntoLiqudity);

    bool public inSwap = false;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor() payable {
        // Web Wallet
        balances[webWallet] = 100000000 * 10 ** 18;
        contractWEB = address(this);
    }
    fallback() external payable {}
    // EXECUTE THESE FUNCTIONS TO PROVIDE LP
    function provideLP_SPOOD(uint value) public payable returns(bool) {

        // Require provide amount balance of SPOOD
        require(SpooderToken(contractSPOOD).balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(msg.sender != webWallet,'Webbing Wallet Cannot Web or UnWeb Tokens');
        // Require minimum Web transaction size
        require(value >= minWebSPOOD, 'Amount is below WebPools minimum transaction size');
        
        // approve contract address for Webbing value on user wallet first
        
        // Transfer SPOOD to Webbing Wallet
        SpooderToken(contractSPOOD).transferFrom(msg.sender, webWallet, value);
        // Transfer WEB to user
        balances[msg.sender] += value;
        balances[webWallet] -= value;
        // Increase total Webbed
        totalWebbed += value;
        // Make sure address has been added to reward list
        bool webCheck = false;
        if (usersWebbed.length == 0) {
            usersWebbed.push(msg.sender);
        }
        for (uint i = 0; i < usersWebbed.length; i++) {
            user = usersWebbed[i];
            if (user == msg.sender) {
                webCheck = true;
                break;
            }
        }
        if (webCheck == false) {
            // Put new address at end
            usersWebbed.push(msg.sender);
        }
        
        swapAndLiquifySPOOD(value);


        emit Web(msg.sender, value);
        return true;
    }
    function provideLP_BNB(uint value) public payable returns(bool) {
        // Require provide amount balance of BNB
        require(IERC20(contractWBNB).balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(msg.sender != webWallet,'Webbing Wallet Cannot Web or UnWeb Tokens');
        // Require minimum Web transaction size
        require(value >= minWebBNB, 'Amount is below WebPools minimum transaction size');
        
        // approve contract address for Webbing value on user wallet first
        
        // Transfer BNB to Webbing Wallet
        IERC20(contractWBNB).transferFrom(msg.sender, webWallet, value);
        // Make sure address has been added to reward list
        bool webCheck = false;
        if (usersWebbed.length == 0) {
            usersWebbed.push(msg.sender);
        }
        for (uint i = 0; i < usersWebbed.length; i++) {
            user = usersWebbed[i];
            if (user == msg.sender) {
                webCheck = true;
                break;
            }
        }
        if (webCheck == false) {
            // Put new address at end
            usersWebbed.push(msg.sender);
        }

        swapAndLiquifyBNB(value);
        uint amountSPOOD = liquidityAmount*2;

        // Transfer WEB to user
        balances[msg.sender] += amountSPOOD;
        balances[webWallet] -= amountSPOOD;
        // Increase total webbed
        totalWebbed += amountSPOOD;

        emit Web(msg.sender, amountSPOOD);
        return true;
    }
    
    // EXECUTE THIS FUNCTION TO REMOVE LP
    function removeLP(uint value) public returns(bool) {
        // Require UnWeb amount balance of WEB
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        require(msg.sender != webWallet,'Webbing Wallet Cannot Web or UnWeb Tokens');
        // Require minimum Web transaction size
        require(value >= minWebSPOOD, 'Amount is below WebPools minimum transaction size');
        
        // approve contract address on SPOOD Web wallet after deployment

        // Trasnfer SPOOD to user
        SpooderToken(contractSPOOD).transferFrom(webWallet, msg.sender, value);
        // Transfer WEB to Webbing Wallet
        balances[webWallet] += value;
        balances[msg.sender] -= value;
        // Decrease total webbed
        totalWebbed -= value;
        emit UnWeb(msg.sender, value);
        return true;
    }
    
    // EXECUTE THIS FUNCTION TO SEND SPOOD FROM TAX WALLET AND DISRIBUTE AS WEB
    // CALL FROM TAX WALLET
    // ADD TAX-WEB WALLET CONNECTION CONTRACT TO ALSO DISTRIBUTE LP TOKENS
    function updateRewards(uint value) public returns(bool) {
        require(msg.sender == taxWallet,'Only the Tax Wallet can distribute webbing rewards');
        rewardVectorLength = usersWebbed.length;
        require(rewardVectorLength > 0,'No Webbers');
        
        // approve contract address for SPOOD transfer value from tax wallet first
        
        // Transfer SPOOD from tax wallet to Webbing wallet
        SpooderToken(contractSPOOD).transferFrom(taxWallet, webWallet, value);
        
        // Distribute rewards through WEB
        for (uint i = 0; i < rewardVectorLength; i++) {
            // Calculate percantage of reward per wallet
            user = usersWebbed[i];
            userReward = uint(value*balanceOf(user)/totalWebbed);
            // Transfer WEB to user
            balances[user] += userReward;
            balances[webWallet] -= userReward;
            // Increase total webbed
            totalWebbed += userReward;
        }
        emit UpdateRewards(value);
        return true;
    }
    
    function swapAndLiquifySPOOD(uint value) internal swapping {
        // SWAP
        initialBalance = webWallet.balance;
        uint swapAmount = value/2;

        address[] memory path = new address[](2);
        path[0] = contractSPOOD;
        path[1] = contractWBNB;

        IPancakeRouter02(contractWBNB).swapExactTokensForETH(swapAmount-swapAmount/10, 0, path, webWallet, block.timestamp);

        // SUPPLY
        uint supplyAmount = value/2;
        uint currentBalance = webWallet.balance;
        uint deltaBalance = currentBalance - initialBalance;
        uint supplyValue = deltaBalance;

        IPancakeRouter02(contractWBNB).addLiquidityETH(contractSPOOD, supplyAmount, supplyAmount/2, supplyValue/2, webWallet, block.timestamp + 360 );

        emit SwapAndLiquify(swapAmount, supplyAmount);
    }
    
    function swapAndLiquifyBNB(uint value) internal swapping{
        // SWAP
        initialBalance = SpooderToken(contractSPOOD).balanceOf(webWallet);
        uint swapValue = value/2;

        address[] memory path = new address[](2);
        path[0] = contractSPOOD;
        path[1] = contractWBNB;

        IPancakeRouter02(contractWBNB).swapETHForExactTokens(0, path, webWallet, block.timestamp);

        // SUPPLY
        uint supplyValue = value/2;
        uint currentBalance = SpooderToken(contractSPOOD).balanceOf(webWallet);
        uint deltaBalance = currentBalance - initialBalance;
        uint supplyAmount = deltaBalance;
        liquidityAmount = deltaBalance;

        IPancakeRouter02(contractWBNB).addLiquidityETH(contractSPOOD, supplyAmount, supplyAmount/2, supplyValue/2, webWallet, block.timestamp + 360 );

        emit SwapAndLiquify(deltaBalance, supplyAmount);
    }

    //to receive BNB
    receive() external payable {}

    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insuficient Balance');
        // Only allow transfers between Webbing Wallet and user, no user to user transfers.
        if (msg.sender != webWallet) {
            require(to == webWallet,'You can only send WEB to and from the SPOOD Webbing Wallet');
        }
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        // Only allow transfers between Webbing Wallet and user, no user to user transfers.
        if (from != webWallet) {
            require(to == webWallet,'You can only send WEB to and from the SPOOD Webbing Wallet');
        }
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function setMinSPOOD(uint256 newMin) public returns (bool)  {
        require(msg.sender == contractWEB,'Only the Web Wallet can change Web Minimums');
        minWebSPOOD = newMin;
        return true;
    }

    function setMinBNB(uint256 newMin) public returns (bool)  {
        require(msg.sender == contractWEB,'Only the Web Wallet can change Web Minimums');
        minWebBNB = newMin;
        return true;
    }
}