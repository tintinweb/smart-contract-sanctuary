/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
/**
 * @title cETH Token
 * @dev Utilities for CompoundETH
 */
interface cETH {
    //@dev functions from Compound that are going to be used
    function mint() external payable; // to deposit to Compound
    function redeem(uint redeemTokens) external returns (uint); // Redeem ETH from Compound
    function redeemUnderlying(uint redeemAmount) external returns (uint); // Redeem specified Amount
    // These 2 determine the amount you're able to withdraw
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
}
/**
 * @title ERC20 Compliant Tokens
 * @dev ERC20 interface for interacting with various tokens
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
/**
 * @title Uniswap Router
 * @dev Allows converting tokens 
 */
interface UniswapRouter {
    function WETH() external pure returns (address);
    
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    )  external  payable  returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        view
        external
        returns (uint[] memory amounts);

}

/**
 * @title SmartBankAccount
 * @dev Store & Widthdraw money, using Compound under the hood
 */
contract SmartBankAccount {
    uint totalContractBalance = 0;
    // Ropsten TestNet cETH address
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    // Ropsten Uniswap Router address
    address UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);
    
    function getContractBalance() public view returns(uint) {
        return totalContractBalance;
    }
    
    mapping(address => uint) balances;
    mapping(address => uint) ethBalances; // Eth Balance
    mapping(address => uint) erc20Balances; // ERC20 Balance
    receive() external payable{}
    /**
    * @dev Deposit Ether
    */
    function addBalance() public payable {
        _mint(msg.value);
    }
    /**
    * @dev Deposit ERC20 compliant tokens
     */
    function addBalanceERC20(address erc20TokenSmartContractAddress) public {
        
        uint ethAfterSwap = _swapTokensForEth(erc20TokenSmartContractAddress);

        _mint(ethAfterSwap);
    }
    /**
    * @dev Mints an specific amount of cEth
    */
    function _mint(uint amountEther) internal {
        
        uint256 cEthBeforeMint = ceth.balanceOf(address(this));
        
        // send ethers to mint()
        ceth.mint{value: amountEther}();
        
        uint256 cEthAfterMint = ceth.balanceOf(address(this));
        
        uint cEthUser = cEthAfterMint - cEthBeforeMint;
        balances[msg.sender] += cEthUser;
        totalContractBalance +=cEthUser;
    }
    function getExchangeRate() public view returns(uint256){
        return ceth.exchangeRateStored();
    }
    /**
    *@dev Swap ERC20 Tokens to ETH
     */
    function _swapTokensForEth(address erc20TokenSmartContractAddress) internal returns(uint256) {
        // Get approved amount of ERC20 tokens for Uniswap
        uint256 approvedAmountOfERC20Tokens = _approveApprovedTokensToUniswap(erc20TokenSmartContractAddress);
        
        // Minimum amount to get from swapping
        uint amountETHMin = 0; 
        address to = address(this);
        // time of execution
        uint deadline = block.timestamp + (24 * 60 * 60);
        
        address[] memory path = new address[](2); // Route used when swapping
        path[0] = erc20TokenSmartContractAddress; // Convert from ERC20
        path[1] = uniswap.WETH(); // To ETH
        
        uint contractEthBalance = address(this).balance;
        // swap to ETH using the route declared earlier
        ethBalances[msg.sender] = uniswap.swapExactTokensForETH(approvedAmountOfERC20Tokens, amountETHMin, path, to, deadline)[1];
        uint ethAfterSwap = address(this).balance - contractEthBalance; // Amount of ETH received
        
        return ethAfterSwap;
    }
    /**
    *@dev Approve the swap of ERC20 tokens
     */
    function _approveApprovedTokensToUniswap(address erc20TokenSmartContractAddress) internal returns(uint256) {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        
        // Get allowed amount
        uint approvedAmountOfERC20Tokens = erc20.allowance(msg.sender, address(this));
        
        // Transfer ERC20 to Contract
        erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);
        
        // Approve the amount of tokens to Uniswap router       
        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens);
        
        return approvedAmountOfERC20Tokens;
    }
    /**
    * @dev Retrieves the amount of stored Ether
    */
    function getBalance(address userAddress) public view returns(uint) {
        // Get amount of cETH and calculate received ETH based on the exchange rate
        return balances[userAddress]*ceth.exchangeRateStored()/1e18;
        
    }
    /**
    * @dev get cETH Balance 
    */
    function getCethBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress];
    }
    /**
    * @dev get Deposited/Withdrawn ETH amount
    */
    function getEthBalance(address userAddress) public view returns(uint256) {
        return ethBalances[userAddress];
    }
    /**
    * @dev get Deposited/Withdrawn ERC20 tokens amount
    */
    function getERC20Balance(address userAddress) public view returns(uint256) {
        return erc20Balances[userAddress];
    }
    /**
    * @dev Get Allowed amount of ERC20 Tokens to be spent
    */
    function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns(uint){
        
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }
    /**
    * @dev Withdraws all the Ether
    */
    function withdrawMax() public payable {
        address payable transferTo = payable(msg.sender); // get payable to transfer towards
        ceth.redeem(balances[msg.sender]); // Redeem that cETH
        uint256 amountToWithdraw = getBalance(msg.sender); // Avalaible amount of $ that can be Withdrawn
        totalContractBalance -= balances[msg.sender];
        balances[msg.sender] = 0;
        transferTo.transfer(amountToWithdraw);
    }
    /**
    * @dev Withdraw a specific amount of Ether
    */
    function withdrawAmount(uint amountRequested) public payable {
        require(amountRequested <= getBalance(msg.sender), "Your balance is smaller than the requested amount");
        address payable transferTo = payable(msg.sender); // get payable to transfer to sender's address
        
        uint256 cEthWithdrawn = _withdrawCEther(amountRequested);

        totalContractBalance -= cEthWithdrawn;
        balances[msg.sender] -= cEthWithdrawn;
        transferTo.transfer(amountRequested);
        
    }
    function withdrawERC20Max(address erc20TokenSmartContractAddress) public {
        
        ceth.redeem(balances[msg.sender]);
        uint256 amountEthToSwap = getBalance(msg.sender);
        totalContractBalance -= balances[msg.sender];
        balances[msg.sender] = 0;
        
        uint256 erc20TokenAmount = _swapEthForTokens(erc20TokenSmartContractAddress, amountEthToSwap);
        
        erc20Balances[msg.sender] = erc20TokenAmount;
    }
    /**
    * @dev Swap Eth for specific ERC20 tokens
    */
    function _swapEthForTokens(address erc20TokenSmartContractAddress, uint256 amountEthToSwap) internal returns(uint256) {
        // Similar process to swapTokensForETH, but reversed (ETH in,ERC20 out)
        uint amountOutMin = 0; 
        address to = address(msg.sender);
        uint deadline = block.timestamp + (24 * 60 * 60);
        
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = erc20TokenSmartContractAddress;
        
        // Uniswap also sends the ERC20 Token
        uint256 erc20TokenAmount = uniswap.swapExactETHForTokens{value: amountEthToSwap}(amountOutMin, path, to, deadline)[1];
        
        return erc20TokenAmount;
    }
    /**
    * @dev Withdraw a specific amount as a chosen token
    */
    function withdrawERC20(address erc20TokenSmartContractAddress, uint256 amountToWithdrawInToken) public {
        
        uint256 amountOfEthToWithdraw = _getEthAmountForERC20Token(erc20TokenSmartContractAddress, amountToWithdrawInToken);
        
        require(amountOfEthToWithdraw <= getBalance(msg.sender), "You don't have enough balance!");
        
        uint256 cEthWithdrawn =  _withdrawCEther(amountOfEthToWithdraw);
        
        
        totalContractBalance -= cEthWithdrawn;
        balances[msg.sender] -= cEthWithdrawn;
        
        uint256 erc20TokenAmount = _swapEthForTokens(erc20TokenSmartContractAddress, amountOfEthToWithdraw);
        
        erc20Balances[msg.sender] = erc20TokenAmount;
    }
    /**
    * @dev get amount to withdraw for ERC20 Token
    */
    function _getEthAmountForERC20Token(address erc20TokenSmartContractAddress, uint256 amountToWithdrawInToken) internal view returns(uint256) {
        
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = erc20TokenSmartContractAddress;
        
        
        uint256 amountOfEthToWithdraw = uniswap.getAmountsIn(amountToWithdrawInToken, path)[0];
        return amountOfEthToWithdraw;
    }
    /**
    * @dev Redeems cETH for withdraw
    * @return Withdrawn cETH
    */
    function _withdrawCEther(uint256 _amountOfEth) internal returns (uint256) {
        uint256 cEthContractBefore = ceth.balanceOf(address(this));
        ceth.redeemUnderlying(_amountOfEth);
        uint256 cEthContractAfter = ceth.balanceOf(address(this));

        uint256 cEthWithdrawn = cEthContractBefore - cEthContractAfter;

        return cEthWithdrawn;
    }
}