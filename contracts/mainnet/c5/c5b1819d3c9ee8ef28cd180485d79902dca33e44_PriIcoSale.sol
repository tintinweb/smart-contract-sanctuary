pragma solidity 0.4.24;
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Token
 * @dev Implemented token interface
 */
contract Token {
    function transferSoldToken(address _contractAddr, address _to, uint256 _value) public returns(bool);
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() public view returns (uint256);
}
contract WhiteList {
	function register(address _address) public;
	function unregister(address _address) public;
	function isRegistered(address _address) public view returns(bool);	
}
/**
 * @title BtradeIcoSale
 * @dev Smart contract for ico sale
 */
contract PriIcoSale {
    using SafeMath for uint256;  // use SafeMath
    
    address public owner;              // BtradeIcoSale creator
    address public beneficiary;        // After ico end, send to address
    uint public fundingEthGoal;        // Goal funding ethereum amount
    uint public raisedEthAmt;          // Funded ethereum amout
    uint public totalSoldTokenCount;   // Sold total token count
    uint public pricePerEther;         // Percentage of token per ethereum
    
    Token public tokenReward;          // ERC20 based token address
	WhiteList public whiteListMge;     // Whitelist manage contract address
	
    bool enableWhiteList = false;      // check whitelist flag
    bool public icoProceeding = false; // Whether ico is in progress
    
    mapping(address => uint256) public funderEthAmt;
    
    event ResistWhiteList(address funder, bool isRegist); // white list resist event
    event UnregisteWhiteList(address funder, bool isRegist); // white list remove event
    event FundTransfer(address backer, uint amount, bool isContribution); // Investment Event
    event StartICO(address owner, bool isStart);
	event CloseICO(address recipient, uint totalAmountRaised); // ico close event
    event ReturnExcessAmount(address funder, uint amount);
    
    /**
     * Constructor function
     * Setup the owner
     */
    function PriIcoSale(address _sendAddress, uint _goalEthers, uint _dividendRate, address _tokenAddress, address _whiteListAddress) public {
        require(_sendAddress != address(0));
        require(_tokenAddress != address(0));
        require(_whiteListAddress != address(0));
        
        owner = msg.sender; // set owner
        beneficiary = _sendAddress; // set beneficiary 
        fundingEthGoal = _goalEthers * 1 ether; // set goal ethereu
        pricePerEther = _dividendRate; // set price per ether
        
        tokenReward = Token(_tokenAddress); // set token address
        
    }
    /**
     * Start ICO crowdsale.
     */
    function startIco() public {
        require(msg.sender == owner);
        require(!icoProceeding);
        icoProceeding = true;
		emit StartICO(msg.sender, true);
    }
    /**
     * Close ICO crowdsale.
     */
    function endIco() public {
        require(msg.sender == owner);
        require(icoProceeding);
        icoProceeding = false;
        emit CloseICO(beneficiary, raisedEthAmt);
    }
    /**
     * Check whiteList.
     */
    function setEnableWhiteList(bool _flag) public {
        require(msg.sender == owner);
        require(enableWhiteList != _flag);
        enableWhiteList = _flag;
    }
    /**
     * Resist White list for to fund
     * @param _funderAddress the address of the funder
     */
    function resistWhiteList(address _funderAddress) public {
        require(msg.sender == owner);
        require(_funderAddress != address(0));		
		require(!whiteListMge.isRegistered(_funderAddress));
		
		whiteListMge.register(_funderAddress);
        emit ResistWhiteList(_funderAddress, true);
    }
    function removeWhiteList(address _funderAddress) public {
        require(msg.sender == owner);
        require(_funderAddress != address(0));
        require(whiteListMge.isRegistered(_funderAddress));
        
        whiteListMge.unregister(_funderAddress);
        emit UnregisteWhiteList(_funderAddress, false);
    }
    /**
     * Fallback function
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        require(icoProceeding);
        require(raisedEthAmt < fundingEthGoal);
        require(msg.value >= 0.1 ether); // Minimum deposit amount
        if (enableWhiteList) {
            require(whiteListMge.isRegistered(msg.sender));
        }
        
        uint amount = msg.value; // Deposit amount
        uint remainToGoal = fundingEthGoal - raisedEthAmt;
        uint returnAmt = 0; // Amount to return when the goal is exceeded
        if (remainToGoal < amount) {
            returnAmt = msg.value.sub(remainToGoal);
            amount = remainToGoal;
        }
        
        // Token quantity calculation and token transfer, if excess amount is exceeded, it is sent to investor
        uint tokenCount = amount.mul(pricePerEther);
        if (tokenReward.transferSoldToken(address(this), msg.sender, tokenCount)) {
            raisedEthAmt = raisedEthAmt.add(amount);
            totalSoldTokenCount = totalSoldTokenCount.add(tokenCount);
            funderEthAmt[msg.sender] = funderEthAmt[msg.sender].add(amount);
            emit FundTransfer(msg.sender, amount, true);
            
            // The amount above the target amount is returned.
            if (returnAmt > 0) {
                msg.sender.transfer(returnAmt);
                icoProceeding = false; // ICO close
                emit ReturnExcessAmount(msg.sender, returnAmt);
            }
        }
    }
    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public {
        require(msg.sender == owner);
        if (raisedEthAmt >= fundingEthGoal){
            safeWithdrawal();
        }
        icoProceeding = false;
    }
    /**
     * Withdraw the funds
     */
    function safeWithdrawal() public {
        require(msg.sender == owner);
        beneficiary.transfer(address(this).balance);
        emit FundTransfer(beneficiary, address(this).balance, false);
    }
}