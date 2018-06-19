pragma solidity ^0.4.18;

	library SafeMath {
	    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
	        if (a == 0) {
	            return 0;
	        }
	        uint256 c = a * b;
	        assert(c / a == b);
	        return c;
	    }

	    function div(uint256 a, uint256 b) internal pure returns (uint256) {
	        // assert(b > 0); // Solidity automatically throws when dividing by 0
	        uint256 c = a / b;
	        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
	        return c;
	    }

	    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
	        assert(b <= a);
	        return a - b;
	    }

	    function add(uint256 a, uint256 b) internal pure returns (uint256) {
	        uint256 c = a + b;
	        assert(c >= a);
	        return c;
	    }
	}

	library SafeBonus {
	    using SafeMath for uint256;

	    function addBonus(uint256 value, uint256 percentages) internal pure returns (uint256) {
	        return value.add(value.mul(percentages).div(100));
	    }
	}

	contract Ownable {
	    address public owner;


	    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	    /**
	     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
	     * account.
	     */
	    function Ownable() public {
	        owner = msg.sender;
	    }


	    /**
	     * @dev Throws if called by any account other than the owner.
	     */
	    modifier onlyOwner() {
	        require(msg.sender == owner);
	        _;
	    }


	    /**
	     * @dev Allows the current owner to transfer control of the contract to a newOwner.
	     * @param newOwner The address to transfer ownership to.
	     */
	    function transferOwnership(address newOwner) public onlyOwner {
	        require(newOwner != address(0));
	        OwnershipTransferred(owner, newOwner);
	        owner = newOwner;
	    }
	}

	interface token {
	    function transfer(address receiver, uint amount) public;
	}

	contract VesaStage2PreICO is Ownable {
	    using SafeMath for uint256;
	    using SafeBonus for uint256;

	    address public beneficiary;
	    uint8 public durationInDays = 31;
	    uint public fundingGoal = 100 ether;
	    uint public fundingGoalHardCap = 10000 ether;
	    uint public amountRaised;
	    uint public start;
	    uint public deadline;
	    uint public bonusPrice = 164285714300000; // 0.0001642857143 ETH
	    uint public bonusPriceDeltaPerHour = 3571428573000; // 0.000003571428573 ETH
	    uint public bonusPeriodDurationInHours = 10;
	    uint public price = 200000000000000; // 0.0002 ETH
	    uint public minSum = 200000000000000000; // 0.2 ETH
	    token public tokenReward;
	    mapping(address => uint256) public balanceOf;
	    bool public fundingGoalReached = false;
	    bool public crowdsaleClosed = false;
	    bool public allowRefund = false;

	    event GoalReached(address recipient, uint totalAmountRaised);
	    event FundTransfer(address backer, uint amount, bool isContribution);
	    event BeneficiaryChanged(address indexed previousBeneficiary, address indexed newBeneficiary);

	    /**
	     * Constructor function
	     *
	     * Setup the owner
	     */
	    function VesaStage2PreICO() public {
	        beneficiary = 0x2bF8AeE3845af10f2bbEBbCF53EBd887c5021d14;
	        start = 1522155600;
	        deadline = start + durationInDays * 1 days;
	        tokenReward = token(0xb1c74c1D82824428e484072069041deD079eD921);
	    }

	    modifier afterDeadline() {
	        if (now >= deadline) 
	            _;
	    }

	    function getPrice() public view returns (uint) {
	        require(!crowdsaleClosed);
	        if ( now >= (start + bonusPeriodDurationInHours.mul(1 hours))) {
	            return price;
	        } else {
	            uint hoursLeft = now.sub(start).div(1 hours);
	            return bonusPrice.add(bonusPriceDeltaPerHour.mul(hoursLeft));
	        }
	    }

	    function getBonus(uint amount) public view returns (uint) {
	        require(!crowdsaleClosed);

	        if (amount < 2857142857000000000) {return 0;}                                        // < 2.857142857
	        if (amount >= 2857142857000000000 && amount < 7142857143000000000) {return 35;}      // 2.857142857-7,142857143 ETH
	        if (amount >= 7142857143000000000 && amount < 14285714290000000000) {return 42;}     // 7,142857143-14,28571429 ETH
	        if (amount >= 14285714290000000000 && amount < 25000000000000000000) {return 47;}    // 14,28571429-25 ETH
	        if (amount >= 25000000000000000000 && amount < 85000000000000000000) {return 55;}    // 25-85 ETH
	        if (amount >= 85000000000000000000 && amount < 285000000000000000000) {return 65;}   // 85-285 ETH
	        if (amount >= 285000000000000000000) {return 75;}                                    // >285 ETH
	    }

	    /**
	     * Fallback function
	     *
	     * The function without name is the default function that is called whenever anyone sends funds to a contract
	     */
	    function () public payable {
	        require(!crowdsaleClosed);
	        require(now > start);
	        require(msg.value > minSum);
	        uint amount = msg.value;
	        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
	        amountRaised = amountRaised.add(amount);

	        uint currentPrice = getPrice();
	        uint currentBonus = getBonus(amount);

	        uint tokensToTransfer = amount.mul(10 ** 18).div(currentPrice);
	        uint tokensToTransferWithBonuses = tokensToTransfer.addBonus(currentBonus);

	        tokenReward.transfer(msg.sender, tokensToTransferWithBonuses);
	        FundTransfer(msg.sender, amount, true);
	    }

	    /**
	     * Check if goal was reached
	     *
	     * Checks if the goal or time limit has been reached and ends the campaign
	     */
	    function checkGoalReached() public afterDeadline {
	        if (amountRaised >= fundingGoal){
	            fundingGoalReached = true;
	            GoalReached(beneficiary, amountRaised);
	        }
	        crowdsaleClosed = true;
	    }

	    /**
	     * Withdraw the funds
	     *
	     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
	     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
	     * the amount they contributed.
	     */
	    function safeWithdrawal() public afterDeadline {
	        if (allowRefund) {
	            uint amount = balanceOf[msg.sender];
	            balanceOf[msg.sender] = 0;
	            if (amount > 0) {
	                if (msg.sender.send(amount)) {
	                    FundTransfer(msg.sender, amount, false);
	                } else {
	                    balanceOf[msg.sender] = amount;
	                }
	            }
	        }

	        if (beneficiary == msg.sender) {
	            if (beneficiary.send(amountRaised)) {
	                FundTransfer(beneficiary, amountRaised, false);
	                crowdsaleClosed = true;
	            } else {
	                //If we fail to send the funds to beneficiary, unlock funders balance
	                fundingGoalReached = false;
	            }
	        }
	    }

	    function tokensWithdrawal(address receiver, uint amount) public onlyOwner {
	        tokenReward.transfer(receiver, amount);
	    }

	    function initializeRefund() public afterDeadline onlyOwner {
	    	allowRefund = true;
	    }

	    function changeBeneficiary(address newBeneficiary) public onlyOwner {
	        require(newBeneficiary != address(0));
	        BeneficiaryChanged(beneficiary, newBeneficiary);
	        beneficiary = newBeneficiary;
	    }

	}