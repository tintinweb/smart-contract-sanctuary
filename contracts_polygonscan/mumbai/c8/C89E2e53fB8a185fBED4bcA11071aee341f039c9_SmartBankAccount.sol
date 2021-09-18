/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

pragma solidity >=0.7.0 <0.9.0;

interface cETH {

    // deposit and redeem
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    
    function exchangeRateStored() external view returns (uint);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract SmartBankAccount {
    
    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);    
    
    uint totalContractBalance = 0;

    function getContractBalance() public view returns(uint){
        return totalContractBalance;
    }
    
    mapping(address => uint) balances;
    mapping(address => uint) depositTimestamps;
    
    function addBalance() public payable {
        uint256 cEthofContractBeforeMinting = ceth.balanceOf(address(this));
        
        ceth.mint{value: msg.value}();
        
        uint256 cEthofContactAfterMinting = ceth.balanceOf(address(this));
        uint256 cEthofUser = cEthofContactAfterMinting - cEthofContractBeforeMinting;
        balances[msg.sender] = cEthofUser;
    }
    
    function getBalance(address userAddress) public view returns(uint256) {
        return ceth.balanceOf(userAddress) * ceth.exchangeRateStored() / 1e18;
    }
    
    function withdraw() public payable {
        address payable withdrawTo = payable(msg.sender);
        balances[msg.sender] = 0;
        uint amountToRedeem = balances[msg.sender] * ceth.exchangeRateStored() / 1e18;
        withdrawTo.transfer(ceth.redeem(amountToRedeem));
    }
    
}