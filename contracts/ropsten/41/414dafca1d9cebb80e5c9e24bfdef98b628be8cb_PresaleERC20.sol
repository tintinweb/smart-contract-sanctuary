// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./MicroToken.sol";

/**
 * @title Digitalax Genesis NFT
 * @dev To facilitate the genesis sale for the Digitialax platform
 */
contract PresaleERC20 is Ownable {
    using SafeMath for uint256;

    // @notice event emitted upon construction of this contract, used to bootstrap external indexers
    event PresaleERC20ContractDeployed();

    BaseToken public baseToken;

    // @notice all funds will be sent to this address pon purchase of a Genesis NFT
    address payable public paymentRecipient;

    // @notice start date for them the Genesis sale is open to the public, before this data no purchases can be made
    uint256 public presalePhase1StartTimestamp;

    // @notice end date for them the Genesis sale is closed, no more purchased can be made after this point
    uint256 public presalePhase1EndTimestamp;

    // @notice start date for them the Genesis sale is open to the public, before this data no purchases can be made
    uint256 public presalePhase2StartTimestamp;

    // @notice end date for them the Genesis sale is closed, no more purchased can be made after this point
    uint256 public presalePhase2EndTimestamp;

    // @notice start date for them the Genesis sale is open to the public, before this data no purchases can be made
    uint256 public publicSaleStartTimestamp;

    // @notice end date for them the Genesis sale is closed, no more purchased can be made after this point
    uint256 public publicSaleEndTimestamp;
    
    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public minimumDepositEthAmount = 0.5 ether;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public maximumDepositEthAmount = 50 ether;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public constant softCapTokenPerEth = 5000;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public constant softCapEthAmount = 20 ether;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public constant hardCapTokenPerEth = 2500;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public constant hardCapEthAmount = 100 ether;

    // @notice the minimum amount a buyer can contribute in a single go
    uint256 public tokenPerEth;

    // @notice the maximum accumulative amount a user can contribute to the genesis sale
    uint256 public totalDepositedEthBalance;

    uint256 public totalPresaleTokenBalance;
    
    uint256 public tokenDecimal;

    bool public isLeftTokenBurned;

    // @notice accumulative => contribution total
    mapping(address => uint256) public deposits;

    // @notice the maximum accumulative amount a user can contribute to the genesis sale
    mapping (uint256=> address) public depositor;

    // @notice the maximum accumulative amount a user can contribute to the genesis sale
    uint256 private _depositorCount = 0;

    uint256 public _tokenAmountForPresalePhase1;

    uint256 public _tokenAmountForPresalePhase2;

    uint256 public _tokenAmountForPublicSale;

    uint256 public _tokenPresaleTotal;    

    uint256 public tokenSoldTotal;    

    constructor(
        BaseToken _baseToken,
        address payable _paymentRecipient,
        uint256 _presalePhase1StartTimestamp,
        uint256 _presalePhase2StartTimestamp,
        uint256 _publicsaleStartTimestamp
    ) public {
        baseToken = _baseToken;
        paymentRecipient = _paymentRecipient;
        presalePhase1StartTimestamp = _presalePhase1StartTimestamp;
        presalePhase1EndTimestamp = presalePhase1StartTimestamp + 24 * 30 days;
        
        presalePhase2StartTimestamp = _presalePhase2StartTimestamp;
        presalePhase2EndTimestamp = presalePhase2StartTimestamp + 24 * 30 days;
        
        publicSaleStartTimestamp = _publicsaleStartTimestamp;
        publicSaleEndTimestamp = _publicsaleStartTimestamp + 24 * 30 days;

        tokenDecimal = baseToken.decimals();
        _tokenAmountForPresalePhase1 = baseToken.totalSupply().mul(5).div(100);
        _tokenAmountForPresalePhase2 = baseToken.totalSupply().mul(15).div(100);
        _tokenAmountForPublicSale = baseToken.totalSupply().mul(15).div(100);
        _tokenPresaleTotal = _tokenAmountForPresalePhase1.add(_tokenAmountForPresalePhase2).add(_tokenAmountForPublicSale);
        tokenPerEth = softCapTokenPerEth;
        emit PresaleERC20ContractDeployed();
    }

 
    function deposit() public payable {
        require(_getNow() >= presalePhase1StartTimestamp && _getNow() <= publicSaleEndTimestamp, "No Tokens are available outside of the presale window");
        require(tokenSoldTotal <= _tokenPresaleTotal, "No Tokens are available outside of the presale window");
        require(totalDepositedEthBalance < hardCapEthAmount , "HardCap Ether Amount limited");

        if (tokenSoldTotal > _tokenAmountForPresalePhase1 && tokenSoldTotal <= _tokenAmountForPresalePhase2){
            tokenPerEth = tokenPerEth.div(2);
        }
        else if ( tokenSoldTotal > _tokenAmountForPresalePhase2 && tokenSoldTotal <= _tokenAmountForPublicSale){
            tokenPerEth = tokenPerEth.div(4);
        }

        uint256 _depositAmount = msg.value;
        deposits[msg.sender] = deposits[msg.sender].add(_depositAmount);

        require(deposits[msg.sender] >= minimumDepositEthAmount && deposits[msg.sender] <= maximumDepositEthAmount, "User deposit amount is less than minimum deposit amount or mucher than maximum deposit amount");
        
        totalDepositedEthBalance = totalDepositedEthBalance.add(_depositAmount);
        uint256 rewardTokenCount = _depositAmount.div(1 ether).mul(10 ** tokenDecimal).mul(tokenPerEth);

        require(rewardTokenCount <= baseToken.allowance(getOwner(), address(this)), "Revert : not enough token is approved");
        require(rewardTokenCount <= baseToken.balanceOf(getOwner()), "Revert : out of token");
        
        baseToken.transferFrom(getOwner(), msg.sender, rewardTokenCount);
        tokenSoldTotal = tokenSoldTotal.add(rewardTokenCount);
        depositor[_depositorCount] = msg.sender;
        _depositorCount++;


        tokenPerEth = softCapTokenPerEth;
    }

    function getOwner() public view returns (address) {
        return baseToken.owner();
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    
    function getWalletDepositAmount(address user) public view returns (uint256) {
        return deposits[user];
    }

    function hasPreslaeEnded() public view returns (bool) {
        if (_getNow() >= publicSaleEndTimestamp || totalDepositedEthBalance >= hardCapEthAmount)
            return true;
        return false;
    }

    function releaseFunds() external onlyOwner {
        // require(now >= publicSaleEndTimestamp || totalDepositedEthBalance == hardCapEthAmount, "presale is active");
        paymentRecipient.transfer(address(this).balance);
    }

    function burnLeftTokens() public {
        require(_getNow() > publicSaleEndTimestamp , "Presale Not Finished");
        require(!isLeftTokenBurned, "Left Token of Presale already burned");
        uint256 totalSupply = baseToken.totalSupply();
        uint256 leftBalance = totalSupply.mul(80).div(100) - tokenSoldTotal;
        baseToken.burnFrom(getOwner(), leftBalance);
        isLeftTokenBurned = true;
    }
    // Internal

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}