/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.4.24;

interface IChernobylInu{
    function decimals() external view returns(uint8);
    function balanceOf(address who) external view returns(uint256);
    function transfer(address to, uint tokens) external returns (bool success);

}

contract ChernobylFaucet{
    address owner;
    IChernobylInu chernobyl;
    address public chernobylAddress;
    uint256 public tokensDroped;
    uint256 public tokensAvailable;
    uint256 public tokensPerDrop;
    mapping(address => bool) public hasClaimed;

    event TokensClaimed(address to, uint256 howMany, uint256 kuantosVan, uint256 kuantosQuedan);

    constructor() public {
        owner = msg.sender;
        //chernobylAddress = 0x5d31f4CdF46DA9E1E1fE6C27F792C1E85318631b;
        chernobylAddress = 0xC5A2Ec38cEf021FFC5702278251104B66B7C820C;
        chernobyl = IChernobylInu(chernobylAddress);
        tokensPerDrop = 10000000;
        tokensAvailable = 20000000000;
    }


    function claim() public{
        uint256 realChernobylAmount = tokensPerDrop * (10 ** uint256(chernobyl.decimals()));
        require(
            chernobyl.balanceOf(address(this)) >= realChernobylAmount
            ,"Chernobyl Faucet: There is no left balance for airdrop. Airdrop has been end. Try buying tokens in Pancakeswap"
        );
        require(
            !hasClaimed[msg.sender]
            ,"You already claimed this airdrop"
        );
        require(
            chernobyl.transfer(msg.sender, realChernobylAmount)
            ,"Chernobyl Faucet: Transfer failed :("
        );
        tokensDroped += tokensPerDrop;
        tokensAvailable -= tokensPerDrop;
        hasClaimed[msg.sender]=true;
        emit TokensClaimed(msg.sender, realChernobylAmount, tokensDroped, tokensAvailable);
    }


    function () public payable {
        revert();
    }

}