/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


interface tokenInterface
{
    function mintToken(address target, uint256 mintedAmount) external returns(bool);
}


//*********************************************************************************//
//-----------------  INTERFACE FOR FETCHING REAL TIME PRICE  ----------------------//
//*********************************************************************************//

interface oracleInterface
{
    function fetchPriceFromOracle() external returns(bool);
}


//*********************************************************************************//
//----------------------   OGS MAIN ICO CODE STARTS HERE  -------------------------//
//*********************************************************************************//


contract test_ICO
{
    uint public priceOfOneToken; // Current price of one token

    address payable public projectAdmin; // Address of project leader

    address public _tokenAddress; // Address of OGS token

    address payable newProjectAdmin; // To change projectAdmin in case of private key of current admin compormised.


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    //This generates a public event when someone buys OGS Token

    event buyShareEv(address buyer,uint paidAmount,uint tokenReceived, uint timeOfEvent);

    // This notifies when projectAdmin withdraws fund for particular milestone,it also indicates a particular milestone started now
    event withdrawFundEv(uint amountWithdrawn, uint mileStoneIndex, uint timeOfEvent);  

    // This is indicator for when a particular milestone finished
    event mileStoneFinishedEv(uint mileStoneIndex, uint timeOfEvent);     






    //Data structure of milestones and its status
    struct mileStone
    {
        bytes32 discriptionHash; // sha256 hash value of 'discription text' of milestone available on official website
        uint daysRequired; // Expected required time for particular milestone
        uint fundValue; // Required fund to finish a particular milestone
        uint startedOn; // When milestone started
        uint finishedOn; // When milestone finished
    }


    mileStone[] public mileStones; // Indexed record of all milestones

    address public oracleContractAddress; // Address of Oracle contract to fetch real time price from exchange will be deployed in future

    // This code block will run only once while deployment
    constructor() { 
        projectAdmin = payable(msg.sender);
    }  

    // Those functions which are marked as 'onlyProjectAdmin' ,  public/investor can not call.
    modifier onlyProjectAdmin()
    {
        require(msg.sender == projectAdmin);
        _;
    }

    // To set contract address for fetching real time market price
    function setOracleContractAddress(address _oracleContractAddress) public onlyProjectAdmin returns(bool)
    {
        oracleContractAddress = _oracleContractAddress;
        return true;
    }

    // To set contract address for fetching real time market price
    function set_tokenAddress(address __tokenAddress) public onlyProjectAdmin returns(bool)
    {
        _tokenAddress = __tokenAddress;
        return true;
    }

    // To set contract address for fetching real time market price
    function changeProjectAdmin(address payable _newProjectAdmin) public onlyProjectAdmin returns(bool)
    {
        newProjectAdmin = _newProjectAdmin;
        return true;
    }

    function confirmProjectAdminChange() public returns(bool)
    {
        require(msg.sender == newProjectAdmin, "Invalid Caller");
        projectAdmin = newProjectAdmin;
        newProjectAdmin = payable(address(0));
        return true;
    }

    // To define milestones.
    // new milestones can be defined anytime in future.
    // Once mile stone defined can not be altered later, so be extra careful before entering values
    function _defineMileStone(bytes32 _discriptionHash, uint _daysRequired,uint _fundValue) public onlyProjectAdmin returns(bool)
    {
        mileStone memory temp;
        temp.discriptionHash = _discriptionHash;
        temp.daysRequired = _daysRequired;  
        temp.fundValue = _fundValue;
        mileStones.push(temp);
        return true;
    }

    // for public to buy new token, when someone buys token will be minted on fly, so total supply will increase accordingly
    // initial supply of OGS token is 0 will increase total supply on each buying, there is no max supply, in another words
    // max supply is limited by public action of buying token, if public stopped buying new token then that will be max supply
    // so total supply and max supply will always be equal
    function buyShare() public payable returns(bool)
    {
        if(oracleContractAddress != address(0)) require(oracleInterface(oracleContractAddress).fetchPriceFromOracle(), "price update fail");
        require(msg.value >= priceOfOneToken, "less than one token not allowed" );
        uint tokenAmount = msg.value / priceOfOneToken;
        require(tokenInterface(_tokenAddress).mintToken(msg.sender, tokenAmount), "token purchase fail");
        emit buyShareEv(msg.sender, msg.value, tokenAmount, block.timestamp);
        return true;
    }


    // To start a particular milestone index projectAdmin will withdraw funds to operate production 
    // Time of withdraw will be market as starting time of given milestone
    function withdrawFund(uint _mileStoneIndex) public onlyProjectAdmin returns(bool)
    {   
        require(_mileStoneIndex < mileStones.length, "Invalid mile stone index");
         mileStone memory tempThis = mileStones[_mileStoneIndex];

        if(_mileStoneIndex > 0)
        {
            mileStone memory temp = mileStones[_mileStoneIndex -1];
            require(temp.finishedOn > 0 , "previous mile stone pending");
        }
        require(tempThis.fundValue <= address(this).balance, "not enough balance");
        mileStones[_mileStoneIndex].startedOn = block.timestamp;
        projectAdmin.transfer(tempThis.fundValue);
        emit withdrawFundEv(tempThis.fundValue,_mileStoneIndex, block.timestamp);
        return true;
    }

    // When a milestone will finish projectAdmin will call this function to indicate and to be
    // eligible to withdraw fund for next milestone
    function mileStoneFinished(uint _mileStoneIndex) public onlyProjectAdmin returns(bool)
    {
        mileStone memory temp = mileStones[_mileStoneIndex];
        require(temp.startedOn > 0 && temp.finishedOn == 0 , "wrong/inactive mileStone");
        mileStones[_mileStoneIndex].finishedOn = block.timestamp;
        emit mileStoneFinishedEv(_mileStoneIndex, block.timestamp);
        return true;
    }

    // This function will be used to update current price of token until price fetching from oracle not implemented
    // Price fetching from oracle will be started after listing OGS token to exchanges.
    function updatePrice(uint _priceOfOneToken) public onlyProjectAdmin returns(bool)
    {
        priceOfOneToken = _priceOfOneToken;
        return true;
    }


}