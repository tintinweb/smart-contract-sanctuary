/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface cETH {
    // define functions of compound we will use here
    function mint() external payable; // to deposit compound
    function redeem(uint redeemTokens) external returns (uint); // to withdraw from compound

    // following two function to determine how much you will withdraw
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance); 
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address sender) external view returns (uint256);

    function transfer(address receipent, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address receipent, uint256 amount) external returns (bool);

}


contract SmartBankAccount {
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);
    uint totalContractBalance = 0;
    
    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;

    function getContractBalance() public view returns(uint) {
        return totalContractBalance;
    }
    
    function addBalance() public payable {
        uint256 cEthOfContractBeforeMinting = ceth.balanceOf(address(this)); //this refers to the current contract

        // send ethers to mint()
        ceth.mint{value: msg.value}();
        uint256 cEthOfContractAfterMinting = ceth.balanceOf(address(this)); // updated balance after minting

        uint cEthOfUser = cEthOfContractAfterMinting - cEthOfContractBeforeMinting; // the difference is the amount that has been created by the mint() function
        balances[msg.sender] = cEthOfUser;
    }

    function addBalanceERC20(address erc20TokenSmartContractAddress) public {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);

        // how many erc20tokens has the user (msg.sender) approved this contract to use?
        uint256 approvedAmount = erc20.allowance(msg.sender, address(this));
        erc20.transferFrom(msg.sender, address(this), approvedAmount);
    }

    function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns (uint256) {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }
    

    function getBalance(address userAddress) public view returns(uint256) {
        // uint principal = balances[userAddress];
        // uint timeElapsed = block.timestamp - depositTimestamps[userAddress]; //seconds
        // return principal + uint(principal * (7 * timeElapsed / (100 * 365 * 24 * 60 * 60))) + 1; //simple interest of 0.07%  per year

        return balances[userAddress] * ceth.exchangeRateStored() / 1e18;
    }
    
    function getCethBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress];
    }
    
    function getExchangeRate() public view returns(uint256){
        return ceth.exchangeRateStored();
    }

    function withdraw() public payable {
        ceth.redeem(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
    
    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }
    
    // function withdraw() public payable {
    //     address payable withdrawTo = payable(msg.sender);
    //     uint amountToTransfer = getBalance(msg.sender);
    //     withdrawTo.transfer(amountToTransfer);

    //     totalContractBalance = totalContractBalance - amountToTransfer;
    //     balances[msg.sender] = 0;
    //     ceth.redeem(getBalance(msg.sender));
    // }    
}