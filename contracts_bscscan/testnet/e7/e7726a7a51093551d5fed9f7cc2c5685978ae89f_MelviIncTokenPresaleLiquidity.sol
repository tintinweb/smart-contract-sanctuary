/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface MelviToken {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMelviIncPresaleLiquidity {
    function routerLiquidity() external view returns (address);
    function addressContract() external view returns (address);
    function priceToken() external view returns (uint256);
    
    
    function setRouterLiquidity(address) external;
    function setAddressContract(address) external;
    function setPriceToken(uint256) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Router {
  function addLiquidity(
       address tokenA,
       address tokenB,
       uint amountADesired,
       uint amountBDesired,
       uint amountAMin,
       uint amountBMin,
       address to,
       uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity) {}
  
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {}
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {}
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH) {}
}

contract MelviIncTokenPresaleLiquidity {
    address owner;
    uint256 tokensForSale = 7000000 ether; // Amount of tokens available for sale
    
    address public routerLiquidity;
    address public addressContract;
    uint256 public priceToken;
    
    event Sold(address buyer, uint256 amount);
    
    constructor() public {
        owner = msg.sender;
        
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b);
        
        return c;
    }
    
    function buy(uint256 _amountTokens) public payable {
        MelviToken MelviTokenContract  = MelviToken(IMelviIncPresaleLiquidity(owner).addressContract()); // Token address
        uint256 price = IMelviIncPresaleLiquidity(owner).priceToken(); // Token price per BNB
        
        require(msg.value == mul(price, _amountTokens), "MelviIncTokenPresaleLiquidity: invalid price");
        uint256 scaledAmount = mul(_amountTokens, uint256(10) ** MelviTokenContract.decimals());
        require(tokensForSale >= scaledAmount, "MelviIncTokenPresaleLiquidity: amount for sale not available");
        require(MelviTokenContract.balanceOf(address(this)) >= scaledAmount, "MelviIncTokenPresaleLiquidity: amount not available");
        
        tokensForSale -= _amountTokens;
        require(MelviTokenContract.transfer(msg.sender, scaledAmount));
        emit Sold(msg.sender, _amountTokens);
    }
    
    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB) public {
        Router router  = Router(IMelviIncPresaleLiquidity(owner).routerLiquidity()); // Router address
        router.addLiquidity(
           address(tokenA),
           address(tokenB),
           amountA,
           amountB,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function addLiquidityETH(address token, uint amountA) public {
        Router router  = Router(IMelviIncPresaleLiquidity(owner).routerLiquidity()); // Router address
        router.addLiquidityETH(
           address(token),
           amountA,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function removeLiquidity(address tokenA, address tokenB, uint liquidity) public {
        Router router  = Router(IMelviIncPresaleLiquidity(owner).routerLiquidity()); // Router address
        
        router.removeLiquidity(
           address(tokenA),
           address(tokenB),
           liquidity,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function removeLiquidityETH(address token, uint liquidity) public {
        Router router  = Router(IMelviIncPresaleLiquidity(owner).routerLiquidity()); // Router address
        
        router.removeLiquidityETH(
           address(token),
           liquidity,
           0,
           0,
           address(this),
           block.timestamp
        );
    }
    
    function setRouterLiquidity(address _routerLiquidity) external {
        require(msg.sender == owner, 'MelviIncTokenPresaleLiquidity: FORBIDDEN');
        routerLiquidity = _routerLiquidity;
    }
    
    function setAddressContract(address _addressContract) external {
        require(msg.sender == owner, 'MelviIncTokenPresaleLiquidity: FORBIDDEN');
        addressContract = _addressContract;
    }
    
    function setPriceToken(uint256 _priceToken) external {
        require(msg.sender == owner, 'MelviIncTokenPresaleLiquidity: FORBIDDEN');
        priceToken = _priceToken;
    }
}