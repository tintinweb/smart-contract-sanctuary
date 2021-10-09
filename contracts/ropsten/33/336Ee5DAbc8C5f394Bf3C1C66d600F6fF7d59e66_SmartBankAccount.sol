/**
 *Submitted for verification at Etherscan.io on 2021-10-08
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
 * @title SmartBankAccount
 * @dev Store & Widthdraw money, using Compound under the hood
 */
contract SmartBankAccount {
    uint totalContractBalance = 0;
    // Ropsten TestNet cETH address
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    function getContractBalance() public view returns(uint) {
        return totalContractBalance;
    }
    
    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;
    
    receive() external payable{}
    /**
    * @dev Deposit Ether
    */
    function addBalance() public payable {
        _mint(msg.value);
    }
    
    /**
    * @dev Retrieves the amount of stored Ether
    */
    function getBalance(address userAddress) public view returns(uint) {
        // Get amount of cETH and calculate received ETH based on the exchange rate
        return balances[userAddress]*ceth.exchangeRateStored()/1e18;
        
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
    * @dev Withdraws all the Ether
    */
    function withdraw() public payable {
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
        address payable transferTo = payable(msg.sender); // get payable to transfer towards
        
        uint256 cEthWithdrawn = _withdrawCEther(amountRequested);

        totalContractBalance -= cEthWithdrawn;
        balances[msg.sender] -= cEthWithdrawn;
        transferTo.transfer(amountRequested);
        
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