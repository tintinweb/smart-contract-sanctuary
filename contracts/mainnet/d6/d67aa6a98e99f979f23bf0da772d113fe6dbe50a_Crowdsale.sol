pragma solidity ^0.4.21;

interface token {
    function transfer(address receiver, uint amount)external;
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
	uint public allAmountRaised;
    uint public deadline;
    uint public price;
	uint public limitTransfer;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
	bool public crowdsalePaused = false;

    event FundTransfer(address backer, uint amount, bool isContribution);
    
    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }
	
	/**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint durationInMinutes,
        uint etherCostOfEachToken,
		uint limitAfterSendToBeneficiary,
        address addressOfTokenUsedAsReward
    )public {
        beneficiary = ifSuccessfulSendTo;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
		limitTransfer = limitAfterSendToBeneficiary;
    }
	
	/**
     * changeDeadline function
     *
     * Setup the new deadline
     */
    function changeDeadline(uint durationInMinutes) public onlyOwner 
	{
		crowdsaleClosed = false;
        deadline = now + durationInMinutes * 1 minutes;
    }
	
	/**
     * changePrice function
     *
     * Setup the new price
     */
    function changePrice(uint _price) public onlyOwner 
	{
        price = _price;
    }
	
	/**
     * Pause Crowdsale
     *
     */
    function pauseCrowdsale()public onlyOwner 
	{
        crowdsaleClosed = true;
		crowdsalePaused = true;
    }
	
	/**
     * Run Crowdsale
     *
     */
    function runCrowdsale()public onlyOwner 
	{
		require(now <= deadline);
        crowdsaleClosed = false;
		crowdsalePaused = false;
    }

    /**
     * Send To Beneficiary
     *
     * Transfer to Beneficiary
     */
    function sendToBeneficiary()public onlyOwner 
	{
        if (beneficiary.send(amountRaised)) 
		{
			amountRaised = 0;
			emit FundTransfer(beneficiary, amountRaised, false);
		}
    }
	
	/**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable 
	{
        require(!crowdsaleClosed);
		require(now <= deadline);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised    += amount;
		allAmountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true);
		
		if (amountRaised >= limitTransfer)
		{
			if (beneficiary.send(amountRaised)) 
			{
                amountRaised = 0;
				emit FundTransfer(beneficiary, amountRaised, false);
            }
		}
    }
}