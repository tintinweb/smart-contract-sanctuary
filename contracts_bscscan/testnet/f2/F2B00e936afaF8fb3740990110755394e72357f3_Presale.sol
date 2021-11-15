// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;





abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IERC20 {
 
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256); 
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
           
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

  
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
 abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Presale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

	/* the maximum amount of tokens to be sold   totalSupply * 0.45 * 1800/5800        */ 
	uint256 constant maxGoal = 140000 * (10**9) * 10**9;     //the goal bnb is 2200
	/* how much has been raised by crowdale (in ETH) */
	uint256 public amountRaised;
	/* how much has been raised by crowdale (in PartyDoge) */
	uint256 public amountRaisedPartyDoge;

	/* the start & end date of the crowdsale */
	uint256 public start;
	uint256 public deadline1;
	uint256 public endOfICO;
	uint256 public deadline2;
	uint256 public deadline3;



	/* there are different prices in different time intervals  decimal 10**9 */ 
	uint256 constant price = 63 * 10**9  ;  //63.63

	/* the address of the token contract */
	IERC20 private tokenReward;
	
	/* the balances (in ETH) of all investors */
	mapping(address => uint256) public balanceOf;
	/* the balances (in PartyDoge) of all investors */
	mapping(address => uint256) public balanceOfPartyDoge;


	/* indicates if the crowdsale has been closed already */
	bool public presaleClosed = false;
	/* notifying transfers and the success of the crowdsale*/
	event GoalReached(address beneficiary, uint256 amountRaised);
	event FundTransfer(address backer, uint256 amount, bool isContribution, uint256 amountRaised);

    /*  initialization, set the token address */
    constructor(IERC20 _token, uint256 _start, uint256 _dead1, uint256 _dead2, uint256 _dead3, uint256 _end ) {
        tokenReward = _token;
		start = _start;
		deadline1 = _dead1;
		deadline2 = _dead2;
		deadline3 = _dead3;
		endOfICO = _end;
	
		
	
    }

    /* invest by sending ether to the contract. */
    receive () external payable {
		if(msg.sender != owner()) //do not trigger investment if the multisig wallet is returning the funds
        	invest();
		else revert();
    }

	function checkFunds(address addr) external view returns (uint256) {
		return balanceOf[addr];
	}

	function checkPartyDogeFunds(address addr) external view returns (uint256) {
		return balanceOfPartyDoge[addr];
	}

	function getBNBBalance() external view returns (uint256) {
		return address(this).balance;
	}

    /* make an investment
    *  only callable if the crowdsale started and hasn't been closed already and the maxGoal wasn't reached yet.
    *  the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
    *  the sent value is directly forwarded to a safe multisig wallet.
    *  this method allows to purchase tokens in behalf of another address.*/
    function invest() public payable {
    	uint256 amount = msg.value;
		require(presaleClosed == false && block.timestamp >= start && block.timestamp < deadline3, "Presale is closed");
		require(msg.value >= 1 * 10**17, "Fund is less than 0.1 BNB");

		balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
		require(balanceOf[msg.sender] <= 5 * 10**18, "Fund is more than 5 BNB");
		uint256 partyDogePrice = getPresalePrice();
		amountRaised = amountRaised.add(amount);

		balanceOfPartyDoge[msg.sender] = balanceOfPartyDoge[msg.sender].add(amount.mul(partyDogePrice).div(1e9));
		amountRaisedPartyDoge = amountRaisedPartyDoge.add(amount.mul(partyDogePrice).div(1e9));

		if (amountRaisedPartyDoge >= maxGoal) {
			presaleClosed = true;
			emit GoalReached(msg.sender, amountRaised);
		}
		
        emit FundTransfer(msg.sender, amount, true, amountRaised);
    }

    modifier afterClosed() {
        require(block.timestamp >= endOfICO, "Distribution is off.");
        _;
    }

	function getPresalePrice() public view returns (uint256){
		if(block.timestamp > start && block.timestamp < deadline1 )
			return price.mul(4).div(3);   // 25% discount for first step
		if(block.timestamp > deadline1 && block.timestamp < deadline2 )
			return price.mul(5).div(4);   // 20% discount for first step
		if(block.timestamp > deadline1 && block.timestamp < deadline2 )
			return price.mul(20).div(17);   // 15% discount for first step
		return price;
	}
	function getPartyDoge() external afterClosed nonReentrant {
		require(balanceOfPartyDoge[msg.sender] > 0, "Zero BNB contributed.");
		uint256 amount = balanceOfPartyDoge[msg.sender];
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance >= amount, "Contract has less fund.");
		balanceOfPartyDoge[msg.sender] = 0;
		tokenReward.transfer(msg.sender, amount);
	}

	function withdrawETH() external onlyOwner afterClosed {
		uint256 balance = this.getBNBBalance();
		require(balance > 0, "Balance is zero.");
		address payable payableOwner = payable(owner());
		payableOwner.transfer(balance);
	}

	function withdrawPartyDoge() external onlyOwner afterClosed{
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance > 0, "Balance is zero.");
		tokenReward.transfer(owner(), balance);
	}
}

