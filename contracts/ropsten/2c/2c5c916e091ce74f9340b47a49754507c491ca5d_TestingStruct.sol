/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.8.10;
//SPDX-License-Identifier: UNLICENSED

contract TestingStruct
{
    struct Test
    {
        bool exists;
    }

    struct Test2
    {
        uint256 num;
    }

    uint256 payoutBlockTime = 0;
    uint256 payoutEndBlockTime = 0;
    uint256 previousPayoutBlockTime;

    address[] approvedTokens;

    string output = "";

    mapping (address => bool) dividendExempt;

    mapping (address => mapping (address => Test2)) mapTest;

    Test test2;

    struct payoutToken{ //Defines the properties for payout token options on a per-token basis
        uint256 tokenID; //A numerical ID to identify the payout token
        string tokenTicker; // The ticker of the payout token
        address tokenAddress; //The contract address of the payout token
        uint256 rewardsToBePaid; //This is a placeholder when adding up token amount that counts towards rewards paid.  This represents ONLY the native token.
        uint256 totalDistributed; //The total quantity of the token paid out across the lifetime of all holders
        uint256 holdersSelectingThis; //Returns the # of holders who have selected this payout option
        bool enabled; //Allows the owner to enable/disable a payout token
    }

    mapping(address => payoutToken) payoutTokenList;

    constructor()
    {
        //test1.exists = true;
        addPayoutToken(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB, "WETH");
        addPayoutToken(0xb54f16fB19478766A268F172C9480f8da1a7c9C3, "TIME");
        addPayoutToken(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70, "DAI");
        addPayoutToken(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664, "USDC");
        addPayoutToken(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7, "AVAX");

        mapTest[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB][0xb54f16fB19478766A268F172C9480f8da1a7c9C3].num = 25;
    }

function getPayoutBlockTimestamp() public view returns (uint256)
{
    return payoutBlockTime;
}

function getPayoutEndBlockTimestamp() public view returns (uint256)
{
    return payoutEndBlockTime;
}

function getBlockTimestamp() public view returns (uint256)
{
    return block.timestamp;
}

function setPayoutEndBlockTime(uint256 _seconds) public{
    payoutEndBlockTime = block.timestamp + (_seconds * 1 seconds);
}

function updatePayoutBlockTimestamp() public
{
    if(block.timestamp >= payoutBlockTime + 10 seconds){
        payoutBlockTime = block.timestamp;
    }
}

function getMapTest() public view returns (uint256)
{
    return mapTest[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB][0xb54f16fB19478766A268F172C9480f8da1a7c9C3].num;
}

function setMapTest(uint256 _num) public
{
    mapTest[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB][0xb54f16fB19478766A268F172C9480f8da1a7c9C3].num = _num;
}

function checkTest() public view returns (bool)
{
    if(test2.exists == true)
    {return true;}
    else
    {return false;}
}

function changeTest() public
{
    if(test2.exists == true)
    {
        test2.exists = false;
    }
    else
    {
        test2.exists = true;
    }
}

function getETHBal() public view returns (uint256)
{
    return address(msg.sender).balance;
}

function getBlock() public view returns (uint256)
{
    return block.number;
}

function getExempt(address _address) public view returns (bool)
{
    return dividendExempt[_address];
}

function changeExempt(address _holder, bool exempt) public
{
    dividendExempt[_holder] = exempt;
}

function getArrayElement(uint index) public view returns (address)
{
    return approvedTokens[index];
}

function addPayoutToken(address _address, string memory _ticker) public {
        approvedTokens.push(_address);
        payoutTokenList[_address].tokenID = approvedTokens.length;
        payoutTokenList[_address].tokenTicker = _ticker;
        payoutTokenList[_address].tokenAddress = _address;
        payoutTokenList[_address].rewardsToBePaid = 0;
        payoutTokenList[_address].totalDistributed = 0;
        payoutTokenList[_address].holdersSelectingThis = 0;
        payoutTokenList[_address].enabled = true;
    }

    function disablePayoutToken(address _address) public {
        payoutTokenList[_address].enabled = false;
    }

    function enablePayoutToken(address _address) public {
        payoutTokenList[_address].enabled = true;
    }

    function listTokenProperties(address _address) public view returns (uint256, string memory, address, uint256, uint256, uint256, bool){
        return (payoutTokenList[_address].tokenID, payoutTokenList[_address].tokenTicker, payoutTokenList[_address].tokenAddress,
        payoutTokenList[_address].rewardsToBePaid, payoutTokenList[_address].totalDistributed, payoutTokenList[_address].holdersSelectingThis,
        payoutTokenList[_address].enabled);
    }

    function swapUSDC(uint256 amount) public {

    }

}