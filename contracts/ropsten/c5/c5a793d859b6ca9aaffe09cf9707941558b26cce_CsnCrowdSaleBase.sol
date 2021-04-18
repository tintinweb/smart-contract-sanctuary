pragma solidity ^0.6.0;
import './CsnCrowdConfigurableSale.sol';
import './SafeMath.sol';
import './Maps.sol';
// SPDX-License-Identifier: UNLICENSED

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CsnCrowdSaleBase is CsnCrowdConfigurableSale {
    using SafeMath for uint256;
    using Maps for Maps.Map;
    // The token being sold
    IERC20 public token;
    mapping(address => uint256) public participations;
    Maps.Map public participants;

    event Finalized();

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */ 
    event BuyTokens(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event ClaimBack(address indexed purchaser, uint256 amount);

    constructor() public { // wallet which has the ICO tokens
    }

    function setWallet(address payable _wallet) public onlyAdmin  {
        wallet = _wallet;
    }

    receive () external payable {
        if(msg.sender != wallet && msg.sender != address(0x0) && !isCanceled) {
            buyTokens(msg.value);
        }
    }

    function buyTokens(uint256 _weiAmount) private {
        require(validPurchase(), "Requirements to buy are not met");
        uint256 rate = getRate();
        // calculate token amount to be created
        uint256 gas = 0;
        uint256 amountIncl = 0;
        uint256 amount = 0;
        uint256 tokens = 0;
        uint256 newBalance = 0;
       
        participations[msg.sender] = participations[msg.sender].safeAdd(_weiAmount);
        if(participants.containsAddress(msg.sender))
        {
            gas = tx.gasprice * 83000;
            amountIncl = _weiAmount.safeAdd(gas);
            amount = amountIncl.safeMul(rate);
            tokens = amount.safeDiv(1000000000000000000);
            Maps.Participant memory existingParticipant = participants.getByAddress(msg.sender);
            newBalance = tokens.safeAdd(existingParticipant.Tokens);
        }
        else {
            gas = tx.gasprice * 280000;
            amountIncl = _weiAmount.safeAdd(gas);
            amount = amountIncl.safeMul(rate);
            tokens = amount.safeDiv(1000000000000000000);
            newBalance = tokens;
        } 
        participants.insertOrUpdate(Maps.Participant(msg.sender, participations[msg.sender], newBalance, block.timestamp));

        //forward funds to wallet
        forwardFunds();

         // update state
        weiRaised = weiRaised.safeAdd(_weiAmount);
         //purchase tokens and transfer to buyer
        token.transferFrom(wallet, msg.sender, tokens);
         //Token purchase event
        emit BuyTokens(msg.sender, msg.sender, _weiAmount, tokens);
    }

    function GetNumberOfParticipants() public view  returns (uint) {
        return participants.count;
    }

    function GetMaxIndex() public view  returns (uint) {
        return participants.lastIndex;
    }

    function GetParticipant(uint index) public view  returns (address Address, uint256 Participation, uint256 Tokens, uint256 Timestamp ) {
        Maps.Participant memory participant = participants.get(index);
        Address = participant.Address;
        Participation = participant.Participation;
        Tokens = participant.Tokens;
        Timestamp = participant.Timestamp;
    }
    
    function Contains(address _address) public view returns (bool) {
        return participants.contains(Maps.Participant(_address, 0, 0, block.timestamp));
    }
    
    function Destroy() private returns (bool) {
        participants.destroy();
    }

    function buyTokens() public payable {
        require(msg.sender != address(0x0), "Can't by from null");
        buyTokens(msg.value);
    }

    //send tokens to the given address used for investors with other conditions, only contract admin can call this
    function transferTokensManual(address beneficiary, uint256 amount) public onlyAdmin {
        require(beneficiary != address(0x0), "address can't be null");
        require(amount > 0, "amount should greater than 0");

        //transfer tokens
        token.transferFrom(wallet, beneficiary, amount);

        //Token purchase event
        emit BuyTokens(wallet, beneficiary, 0, amount);

    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // should be called after crowdsale ends or to emergency stop the sale
    function finalize() public onlyAdmin {
        require(!isFinalized, "Is already finalised");
        emit Finalized();
        isFinalized = true;
    }

    // @return true if the transaction can buy tokens
    // check for valid time period, min amount and within cap
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = startDate <= block.timestamp && endDate >= block.timestamp;
        bool nonZeroPurchase = msg.value != 0;
        bool minAmount = msg.value >= minimumParticipationAmount;
        bool withinCap = weiRaised.safeAdd(msg.value) <= cap;

        return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withinCap;
    }

    // @return true if the goal is reached
    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

    function minimumCapReached() public view returns (bool) {
        return weiRaised >= minimumToRaise;
    }

    function claimBack() public {
        require(isCanceled, "The presale is not canceled, claiming back is not possible");
        require(participations[msg.sender] > 0, "The sender didn't participate to the presale");
        uint256 participation = participations[msg.sender];
        participations[msg.sender] = 0;
        msg.sender.transfer(participation);
        emit ClaimBack(msg.sender, participation);
    }

    function cancelSaleIfCapNotReached() public onlyAdmin {
        require(weiRaised < minimumToRaise, "The amount raised must not exceed the minimum cap");
        require(!isCanceled, "The presale must not be canceled");
        require(endDate > block.timestamp, "The presale must not have ended");
        isCanceled = true;
    }
}