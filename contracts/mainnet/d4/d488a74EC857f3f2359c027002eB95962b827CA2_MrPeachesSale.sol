/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

//   ______   ______     ______     ______     __  __     ______     ______    
//  /\  == \ /\  ___\   /\  __ \   /\  ___\   /\ \_\ \   /\  ___\   /\  ___\   
//  \ \  _-/ \ \  __\   \ \  __ \  \ \ \____  \ \  __ \  \ \  __\   \ \___  \  
//   \ \_\    \ \_____\  \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\ 
//    \/_/     \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_____/   \/_____/ 
//                                                                             

//Peaches.Finance
//Docs.Peaches.Finance

//Decentralised Censorship Resistant Stock Tokens on Ethereum.
// :::::::::::::::: ILO :::::::::::::

// Deposit Eth or DAI, Liquidity Generation on Uniswap, Emergency Withdraw


pragma solidity ^0.8.4;


contract MrPeachesSale {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
        
    IERC20 public peaches;
    IERC20 public stableCoin;
    address payable public developer;
    address public oracle;
    
    uint public immutable multiplier;
    uint public immutable privateSaleRate;
    uint public immutable publicSaleRate;
    uint public immutable uniswapRate;
          
    uint public privateSaleSold;
    uint public publicSaleSold;
          
    uint public privateSaleCap;
    uint public publicSaleCap;
          
    uint public publicSaleOpenedAt;
    uint public publicSaleClosedAt;
    uint public liquidityGeneratedAt;
          
    bool public privateSaleClosed = false;
          
    IUniswapV2Router02 public uniswapRouter;
          
    mapping(address => bool) public whiteListed;
    mapping(address => uint256) public tokenBalances;
    mapping(address => uint256) public stableCoinContributed;
          
    event LiquidityGenerated(uint amountA, uint amountB, uint liquidity);
    event PeachesClaimed(address account, uint amount);
    event EmergencyWithdrawn(address account, uint amount);
    event EthDeposited(address account, uint tokens, int price);
    event CoinDeposited(address account, uint tokens);
    event LpRecovered(address account, uint tokens);
    
    constructor(
        uint _privateSaleRate, 
        uint _publicSaleRate, 
        uint _uniswapRate, 
        uint _privateSaleCap, 
        uint _publicSaleCap, 
        uint _multiplier, 
        IERC20 _peaches, 
        IERC20 _stableCoin, 
        address _oracle, 
        address _uniswapRouter
        ) {
        privateSaleRate = _privateSaleRate;
        publicSaleRate = _publicSaleRate;
        uniswapRate = _uniswapRate;
        privateSaleCap = _privateSaleCap;
        publicSaleCap = _publicSaleCap;
        multiplier = _multiplier;
        peaches = _peaches;
        stableCoin = _stableCoin;
        oracle = _oracle;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        developer = payable(msg.sender);
    }

    receive() external payable {
        depositEth();
    }

    function depositEth() public payable {
        
        uint tokens;
        
        require(msg.value > 0);
        
        (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
        
        if (privateSaleClosed == false) {
        
            require(whiteListed[msg.sender], "Not whitelisted");
            
            tokens = msg.value.mul(uint(price)).div(privateSaleRate);
            
            require(tokenBalances[msg.sender].add(tokens) >= 16000000000000000000 && tokenBalances[msg.sender].add(tokens) <= 41670000000000000000000, "Private sale limit");
            
            require(privateSaleSold.add(tokens) <= privateSaleCap, "Cap reached");
            privateSaleSold = privateSaleSold.add(tokens);
            
        } else {
       
            require(publicSaleOpenedAt !=0 && publicSaleClosedAt == 0, "Public sale closed");
            require(block.timestamp >= publicSaleOpenedAt && block.timestamp <= publicSaleOpenedAt.add(21 days), 'Time was reached');
            
            if (block.timestamp <= publicSaleOpenedAt.add(6 hours)) {
                require(whiteListed[msg.sender], "Not whitelisted");  
            }
            
            uint amount = msg.value.mul(uint(price)).div(multiplier);
            
            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = address(stableCoin);
            
            uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value:msg.value}(amount.sub(amount / 25), path, address(this), block.timestamp.add(15 minutes));
            require(amounts[1] > 0);
            
            tokens = amounts[1].mul(multiplier).div(publicSaleRate);
            
            require(tokenBalances[msg.sender].add(tokens) >= 125000000000000000000 && tokenBalances[msg.sender].add(tokens) <= 31250000000000000000000, "Public sale limit");
            
            require(publicSaleSold.add(tokens) <= publicSaleCap, "Cap reached");
            publicSaleSold = publicSaleSold.add(tokens);
            
            stableCoinContributed[msg.sender] = stableCoinContributed[msg.sender].add(amounts[1]);
            
        }
        
        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(tokens);
        emit EthDeposited(msg.sender, tokens, price);
    }
    
    function depositCoin(uint amount) external {
        
        uint tokens;
        
        require(amount > 0); 
        require(amount <= stableCoin.allowance(msg.sender, address(this)), "Allowance not high enough");
        stableCoin.safeTransferFrom(msg.sender, address(this), amount);

        if (privateSaleClosed == false) {
    
            require(whiteListed[msg.sender], "Not whitelisted");
            
            tokens = amount.mul(multiplier).div(privateSaleRate);
            
            require(tokenBalances[msg.sender].add(tokens) >= 16000000000000000000 && tokenBalances[msg.sender].add(tokens) <= 41670000000000000000000, "Private sale limit");
            
            require(privateSaleSold.add(tokens) <= privateSaleCap, "Cap reached");
            privateSaleSold = privateSaleSold.add(tokens);
    
        } else {  
        
            require(publicSaleOpenedAt !=0 && publicSaleClosedAt == 0, "Public sale closed");
            require(block.timestamp >= publicSaleOpenedAt && block.timestamp <= publicSaleOpenedAt.add(21 days), 'Time was reached');
            
            if (block.timestamp <= publicSaleOpenedAt.add(6 hours)) {
                require(whiteListed[msg.sender], "Not whitelisted");  
            }
            
            tokens = amount.mul(multiplier).div(publicSaleRate);
            
            require(tokenBalances[msg.sender].add(tokens) >= 125000000000000000000 && tokenBalances[msg.sender].add(tokens) <= 31250000000000000000000, "Public sale limit");
            
            require(publicSaleSold.add(tokens) <= publicSaleCap, "Cap reached");
            publicSaleSold = publicSaleSold.add(tokens);
            
            stableCoinContributed[msg.sender] = stableCoinContributed[msg.sender].add(amount);
            
        }
        
        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(tokens);
        emit CoinDeposited(msg.sender, tokens);
    } 
    
    function closePrivateSale() external {
    require(msg.sender == developer, "Developer only");
        
        require(privateSaleClosed == false, "Private sale closed");
        
        privateSaleClosed = true;
        publicSaleOpenedAt = block.timestamp;
        
        stableCoin.safeTransfer(developer, stableCoin.balanceOf(address(this)));
        
        (bool success, ) = developer.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    
    function closePublicSale() external {
        
        require(publicSaleOpenedAt !=0, "Private sale open");
        require(publicSaleClosedAt == 0, 'Public sale closed');
        require(block.timestamp > publicSaleOpenedAt.add(21 days) || (publicSaleSold >= publicSaleCap.sub(125000000000000000000) && publicSaleSold <= publicSaleCap), 'Too early');

        publicSaleClosedAt = block.timestamp;
    }
    
    function generateLiquidity() external {
        
        require(publicSaleClosedAt != 0, 'Public sale open');
        require(liquidityGeneratedAt == 0, 'Liquidity generated');
        require(block.timestamp > publicSaleClosedAt.add(30 minutes), 'Too early');
        
        uint stableCoinBalance = stableCoin.balanceOf(address(this));
        require(stableCoinBalance > 0, 'Stablecoin balance is zero');
        stableCoin.safeApprove(address(uniswapRouter), stableCoinBalance);
        uint amountPeaches = stableCoinBalance.mul(multiplier).div(uniswapRate);
        peaches.safeApprove(address(uniswapRouter), amountPeaches);

        (uint amountA, uint amountB, uint liquidity) = uniswapRouter.addLiquidity(
            address(peaches),
            address(stableCoin),
            amountPeaches,
            stableCoinBalance,
            amountPeaches.sub(amountPeaches / 10),
            stableCoinBalance.sub(stableCoinBalance / 10),
            address(this),
            block.timestamp.add(2 hours)
        );

        liquidityGeneratedAt = block.timestamp;
        
        emit LiquidityGenerated(amountA, amountB, liquidity);
    }
    
    function claimPeaches() external {
        
        require(liquidityGeneratedAt != 0, 'Liquidity not generated');
        uint tokens =  tokenBalances[msg.sender];
        require(tokens > 0 , "Nothing to claim");
        
        stableCoinContributed[msg.sender] = 0;
        tokenBalances[msg.sender] = 0;
        
        peaches.safeTransfer(msg.sender, tokens);
        
        emit PeachesClaimed(msg.sender, tokens);
    }
    
    function emergencyWithdrawCoins() external {
        
        require(publicSaleClosedAt != 0, 'Public sale open');
        require(liquidityGeneratedAt == 0, 'Liquidity generated');
        require(block.timestamp > publicSaleClosedAt.add(30 minutes).add(3 days), 'Too early');
        
        uint contributedAmount = stableCoinContributed[msg.sender];
        require(contributedAmount > 0, 'Nothing to withdraw');
        
        tokenBalances[msg.sender] = 0;      
        stableCoinContributed[msg.sender] = 0;
        
        stableCoin.safeTransfer(msg.sender, contributedAmount);
        
        emit EmergencyWithdrawn(msg.sender, contributedAmount);
    }
    
    function recoverPeaches() external {
    require(msg.sender == developer, "Developer only");
        
        require(publicSaleClosedAt != 0, 'Public sale open');
        require(block.timestamp > publicSaleClosedAt.add(30 minutes).add(30 days), 'Too early');
        
        uint sold = privateSaleSold.add(publicSaleSold);
        uint cap = privateSaleCap.add(publicSaleCap);
        
        if (cap > sold) {
            peaches.safeTransfer(developer, cap.sub(sold));
        }
    }
    
    function recoverLpTokens(address _lpToken) external {
    require(msg.sender == developer, "Developer only");
    
        require(liquidityGeneratedAt != 0, 'Liquidity not generated');
        require(block.timestamp >= liquidityGeneratedAt.add(180 days), 'Too early');

        IERC20 lpToken = IERC20(_lpToken);
        uint lpBalance = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(developer, lpBalance);

        emit LpRecovered(developer, lpBalance);
    }
    
    function addPrivateInvestor(address _address, uint _tokens) external {
    require(msg.sender == developer, "Developer only");
    
        require(privateSaleClosed == false, "Private sale closed");
        
        privateSaleSold = privateSaleSold.add(_tokens);
        tokenBalances[_address] = tokenBalances[_address].add(_tokens);
    }
    
    function setWhitelist(address[] memory addrs) external {
    require(msg.sender == developer, "Developer only");
        
        require(publicSaleClosedAt == 0, 'Public sale closed');
        
        for (uint8 i = 0; i < addrs.length; i++){
         whiteListed[addrs[i]] = true;
        }
    }

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.8.0;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;       

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

   
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.8.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity >=0.8.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity >=0.6.2;

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