/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**
 * SWAP
 */

// SPDX-License-Identifier: MIT

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!
pragma solidity 0.6.12;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Router01 {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
    external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(address token,uint256 amountTokenDesired,uint256 amountTokenMin,uint256 amountETHMin,address to,uint256 deadline)
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline)
    external returns (uint amountA, uint amountB);

    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline)
    external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline,bool approveMax, uint8 v, bytes32 r, bytes32 s)
    external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s)
    external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);
}

contract TIKI_SWAP {

    bool public saleActive;
    // IERC20 _fTikToken;
    // IERC20 _newTikToken;
    IUniswapV2Router01 rout;

    address public _fTikToken;
    address public _newTikToken;

    address public owner;
    mapping(address => bool) whitelist;
    mapping(address => bool) adminAddress;

    uint256 public exchangedTokens;
    uint256 public price;

    event details(address token, address to, uint256 amountRecieved);
    event Whitelist(address indexed userAddress, bool Status);
    event bnbExchange(address userAddress, address, uint256);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"TIKI TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }

    constructor( address _V1, address _V2, uint256 _priceToSwap) public {
        owner =  _msgSender();
        saleActive = true;
        _fTikToken = _V1;
        _newTikToken = _V2;
        price = _priceToSwap;
        rout = IUniswapV2Router01(0x10ED43C718714eb63d5aA57B78B54704E256024E); // LIVE PC v2
        adminAddress[msg.sender] = true;
        whitelist[msg.sender] = true;
        saleActive = true;
        emit Whitelist(msg.sender, true);
    }

    // Change the token price
    // Note: Set the price respectively considering the decimals of busd
    // Example: If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).

    modifier onlyAdmin() {
        require(adminAddress[msg.sender]);
        _;
    }

    function updateWhitelist(address _account) onlyAdmin external {
        whitelist[_account] = true;
    }

    function exchangeTik(uint256 _tokenAmount) public {

        if (whitelist[msg.sender] = true) {
            require(saleActive == true, "TIKI: SALE HAS ENDED.");
            require(_tokenAmount >= 0, "TIKI: BUY ATLEAST 1 TOKEN.");

            require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");
            require(IERC20(_newTikToken).transfer(_msgSender(), _tokenAmount), "TIKI: CONTRACT DOES NOT HAVE ENOUGH TOKENS.");

            exchangedTokens += _tokenAmount;
        } else {
            require(saleActive == true, "TIKI: SALE HAS ENDED.");
            require(_tokenAmount >= 0, "TIKI: BUY ATLEAST 1 TOKEN.");

            uint256 cost = _tokenAmount * price;

            require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");
            require(IERC20(_newTikToken).transfer(_msgSender(), cost), "TIKI: CONTRACT DOES NOT HAVE ENOUGH TOKENS.");
        }

        emit details(_newTikToken, _msgSender(), _tokenAmount);
    }

    function exchangeV1ToBNB( uint256 _tokenAmount) public onlyOwner {
        require(IERC20(_fTikToken).transferFrom(_msgSender(), address(this), _tokenAmount), "TIKI: TRANSFER OF FAILED!");

        payable(_msgSender()).transfer(_tokenAmount);
        address(this).balance - _tokenAmount;
        emit bnbExchange(_msgSender(), address(this), _tokenAmount);
    }

    function ret() public payable {
        
    }

    function ball() public view returns(uint256) {
        return (address(this).balance);
    }

    function balTik() public view returns(uint256 _TikToken) {
        _TikToken = IERC20(_fTikToken).balanceOf(address(this));
        return _TikToken;
    }

    function addLiquidity()  onlyOwner public returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        uint256 contractBalanceFtoken = IERC20(_fTikToken).balanceOf(address(this));
        uint256 contractBalanceNtoken = IERC20(_newTikToken).balanceOf(address(this));

        IERC20(_fTikToken).approve(address(rout), contractBalanceFtoken);
        IERC20(_newTikToken).approve(address(rout), contractBalanceNtoken);

        require(contractBalanceNtoken >= contractBalanceFtoken, "you are trying to reduce the current market price");

        // function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
        rout.addLiquidity(_newTikToken,_fTikToken,contractBalanceNtoken,contractBalanceFtoken,0,0, _newTikToken,block.timestamp + 10 minutes);

        return (amountToken,amountETH,liquidity);
    }

    function addLiquidityETH(uint256 _amount)  onlyOwner public returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        uint256 contractBalanceFtoken = IERC20(_fTikToken).balanceOf(address(this));
        uint256 contractBalanceNtoken = IERC20(_newTikToken).balanceOf(address(this));

        IERC20(_fTikToken).approve(address(rout), contractBalanceFtoken);
        IERC20(_newTikToken).approve(address(rout), contractBalanceNtoken);

        require(contractBalanceNtoken >= contractBalanceFtoken, "you are trying to reduce the current market price");

        // function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadlin)
        // {value:totalContributions.div(2)}(address(token),TOKENS_FOR_LP,1,1,address(this),block.timestamp + 10 minutes);
        rout.addLiquidityETH{value:_amount}(address(_newTikToken),contractBalanceNtoken,1,1,address(this),block.timestamp + 10 minutes);

        return (amountToken,amountETH,liquidity);
    }

    function changeRouterContract(address _newRout) onlyOwner public {
        rout = IUniswapV2Router01(_newRout);
    }

    // End the sale, don't allow any purchases anymore and send remaining rgp to the owner
    function disableSale() external onlyOwner{

        // End the sale
        saleActive = false;

        // Send unsold tokens and remaining busd to the owner. Only ends the sale when both calls are successful
        IERC20(_newTikToken).transfer(owner, IERC20(_newTikToken).balanceOf(address(this)));
    }

    function setPriceForUnWhitelistedAddress(uint256 _priceToSwap) public onlyOwner{
        price = _priceToSwap;
    }

    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress[_adminAddress]=true;
    }

    function removeAdmin(address _adminAddress) public onlyOwner {
        delete(adminAddress[_adminAddress]);
    }

    // Start the sale again - can be called anytime again
    function enableSale() external onlyOwner{

        // Enable the sale
        saleActive = true;

        // Check if the contract has any tokens to sell or cancel the enable
        require(IERC20(_newTikToken).balanceOf(address(this)) >= 1, "TIKI: CONTRACT DOES NOT HAVE TOKENS TO SELL.");
    }

    // Withdraw (accidentally) to the contract sent eth
    function withdrawBNB() external payable onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Withdraw (accidentally) to the contract sent ERC20 tokens
    function withdrawNewTiki(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));

        IERC20(_token).transfer(owner, _tokenBalance);
    }
}