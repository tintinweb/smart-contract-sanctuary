//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface cETH {

    // define functions of COMPOUND we'll be using

    function mint() external payable; // to deposit to compound
    function redeem(uint redeemTokens) external returns (uint); // to withdraw from compound

    //following 2 functions to determine how much you'll be able to withdraw
    function exchangeRateStored() external view returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}


contract SmartBankAccount {
    uint totalContractBalance = 0;

    address public COMPOUND_CETH_ADDRESS;
    cETH ceth;

    function setCEth(address _cEthAddress) public {
        COMPOUND_CETH_ADDRESS = _cEthAddress;
        ceth = cETH(_cEthAddress);
    }

    function getContractBalance() public view returns (uint){
        return totalContractBalance;
    }

    mapping(address => uint) public balances;
    mapping(address => uint) depositTimestamps;

    function addBalance() public payable {
//        balances[msg.sender] = msg.value;
//        totalContractBalance = totalContractBalance + msg.value;
//        depositTimestamps[msg.sender] = block.timestamp;

        uint priorCEth = getBalance(address(this));
        // send ethers to mint()
        ceth.mint{value : msg.value}();
        uint laterCEth = getBalance(address(this));
        balances[msg.sender] = laterCEth - priorCEth;
        totalContractBalance = laterCEth;
        depositTimestamps[msg.sender] = block.timestamp;
    }

    function getBalance(address userAddress) public view returns (uint256) {
        return ceth.balanceOf(userAddress) * ceth.exchangeRateStored() / 1e18;
    }

    function withdraw() public payable {

        //CAN YOU OPTIMIZE THIS FUNCTION TO HAVE FEWER LINES OF CODE?

//        address payable withdrawTo = payable(msg.sender);
//        uint amountToTransfer = getBalance(msg.sender);
//        withdrawTo.transfer(amountToTransfer);
//        totalContractBalance = totalContractBalance - amountToTransfer;
//        balances[msg.sender] = 0;

        uint priorBalance = address(this).balance;
        ceth.redeem(balances[msg.sender]);
        uint laterBalance = address(this).balance;
        payable(msg.sender).transfer(laterBalance - priorBalance);
    }

    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }


}