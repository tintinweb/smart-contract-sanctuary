pragma solidity ^0.4.21;


contract Owner {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owner(address _owner) public {
        owner = _owner;
    }

    function changeOwner(address _newOwnerAddr) public onlyOwner {
        require(_newOwnerAddr != address(0));
        owner = _newOwnerAddr;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Extradecoin is Owner {
    using SafeMath for uint256;

    string public constant name = "EXTRADECOIN";
    string public constant symbol = "ETE";
    uint public constant decimals = 18;
    uint256 constant public totalSupply = 250000000 * 10 ** 18; // 250 mil tokens will be supplied
  
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    address public adminAddress;
    address public walletAddress;
    address public founderAddress;
    address public advisorAddress;
    
    mapping(address => uint256) public totalInvestedAmountOf;

    uint constant lockPeriod1 = 3 years; // 1st locked period for tokens allocation of founder and team
    uint constant lockPeriod2 = 1 years; // 2nd locked period for tokens allocation of founder and team
    uint constant lockPeriod3 = 90 days; // 3nd locked period for tokens allocation of advisor and ICO partners
   
    uint constant NOT_SALE = 0; // Not in sales
    uint constant IN_ICO = 1; // In ICO
    uint constant END_SALE = 2; // End sales

    uint256 public constant salesAllocation = 125000000 * 10 ** 18; // 125 mil tokens allocated for sales
    uint256 public constant founderAllocation = 37500000 * 10 ** 18; // 37.5 mil tokens allocated for founders
    uint256 public constant advisorAllocation = 25000000 * 10 ** 18; // 25 mil tokens allocated for allocated for ICO partners and bonus fund
    uint256 public constant reservedAllocation = 62500000 * 10 ** 18; // 62.5 mil tokens allocated for reserved, bounty campaigns, ICO partners, and bonus fund
    uint256 public constant minInvestedCap = 6000 * 10 ** 18; // 2500 ether for softcap 
    uint256 public constant minInvestedAmount = 0.1 * 10 ** 18; // 0.1 ether for mininum ether contribution per transaction
    
    uint saleState;
    uint256 totalInvestedAmount;
    uint public icoStartTime;
    uint public icoEndTime;
    bool public inActive;
    bool public isSelling;
    bool public isTransferable;
    uint public founderAllocatedTime = 1;
    uint public advisorAllocatedTime = 1;
    uint256 public icoStandardPrice;
    
    uint256 public totalRemainingTokensForSales; // Total tokens remaining for sales
    uint256 public totalAdvisor; // Total tokens allocated for advisor
    uint256 public totalReservedTokenAllocation; // Total tokens allocated for reserved

    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC20 standard event
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20 standard event

    event StartICO(uint state); // Start ICO sales
    event EndICO(uint state); // End ICO sales
    
    event SetICOPrice(uint256 price); // Set ICO standard price
    
    event IssueTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint state); // Issue tokens to investor
    event AllocateTokensForFounder(address founderAddress, uint256 founderAllocatedTime, uint256 tokenAmount); // Allocate tokens to founders&#39; address
    event AllocateTokensForAdvisor(address advisorAddress, uint256 advisorAllocatedTime, uint256 tokenAmount); // Allocate tokens to advisor address
    event AllocateReservedTokens(address reservedAddress, uint256 tokenAmount); // Allocate reserved tokens
    event AllocateSalesTokens(address salesAllocation, uint256 tokenAmount); // Allocate sales tokens


    modifier isActive() {
        require(inActive == false);
        _;
    }

    modifier isInSale() {
        require(isSelling == true);
        _;
    }

    modifier transferable() {
        require(isTransferable == true);
        _;
    }

    modifier onlyOwnerOrAdminOrPortal() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    function Extradecoin(address _walletAddr, address _adminAddr) public Owner(msg.sender) {
        require(_walletAddr != address(0));
        require(_adminAddr != address(0));
		
        walletAddress = _walletAddr;
        adminAddress = _adminAddr;
        inActive = true;
        totalInvestedAmount = 0;
        totalRemainingTokensForSales = salesAllocation;
        totalAdvisor = advisorAllocation;
        totalReservedTokenAllocation = reservedAllocation;
    }
    
    // Fallback function for token purchasing  
    function () external payable isActive isInSale {
        uint state = getCurrentState();
        require(state == IN_ICO);
        require(msg.value >= minInvestedAmount);
        
        if (state == IN_ICO) {
            return issueTokensForICO(state);
        }
        revert();
    }

    // ERC20 standard function
    function transfer(address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ERC20 standard function
    function transferFrom(address _from, address _to, uint256 _value) external transferable returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // ERC20 standard function
    function approve(address _spender, uint256 _value) external transferable returns (bool) {
        require(_spender != address(0));
        require(_value > 0);
		
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    // Start ICO
    function startICO() external isActive onlyOwnerOrAdmin returns (bool) {
        saleState = IN_ICO;
        icoStartTime = now;
        isSelling = true;
        emit StartICO(saleState);
        return true;
    }

    // End ICO
    function endICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(icoEndTime == 0);
        saleState = END_SALE;
        isSelling = false;
        icoEndTime = now;
        emit EndICO(saleState);
        return true;
    }
    
    // Set ICO price including ICO standard price, ICO 1st round price, ICO 2nd round price
    function setICOPrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        icoStandardPrice = _tokenPerEther;
        emit SetICOPrice(icoStandardPrice);
        
        return true;
    }

    // Activate token sale function
    function activate() external onlyOwner {
        inActive = false;
    }

    // Deacivate token sale function
    function deActivate() external onlyOwner {
        inActive = true;
    }

    // Enable transfer feature of tokens
    function enableTokenTransfer() external isActive onlyOwner {
        isTransferable = true;
    }

    // Modify wallet
    function changeWallet(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(walletAddress != _newAddress);
        walletAddress = _newAddress;
    }

    // Modify admin
    function changeAdminAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(adminAddress != _newAddress);
        adminAddress = _newAddress;
    }
  
    // Modify founder address to receive founder tokens allocation
    function changeFounderAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(founderAddress != _newAddress);
        founderAddress = _newAddress;
    }

    // Modify team address to receive team tokens allocation
    function changeTeamAddress(address _newAddress) external onlyOwnerOrAdmin {
        require(_newAddress != address(0));
        require(advisorAddress != _newAddress);
        advisorAddress = _newAddress;
    }

    // Allocate tokens for founder vested gradually for 4 year
    function allocateTokensForFounder() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(founderAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            require(now >= icoEndTime + lockPeriod1);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (founderAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod2);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 3;
            return;
        }
        revert();
    }
    

    // Allocate tokens for advisor and angel investors vested gradually for 1 year
    function allocateTokensForAdvisor() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(advisorAddress != address(0));
        uint256 amount;
        if (advisorAllocatedTime == 1) {
            amount = advisorAllocation * 50/100;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForFounder(advisorAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (advisorAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod2);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 3;
            return;
        }
        if (advisorAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 4;
            return;
        }
        if (advisorAllocatedTime == 4) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 5;
            return;
        }
        if (advisorAllocatedTime == 5) {
            require(now >= icoEndTime + lockPeriod3);
            amount = advisorAllocation * 125/1000;
            balances[advisorAddress] = balances[advisorAddress].add(amount);
            emit AllocateTokensForAdvisor(advisorAddress, advisorAllocatedTime, amount);
            advisorAllocatedTime = 6;
            return;
        }
        revert();
    }
    
    // Allocate reserved tokens
    function allocateReservedTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalReservedTokenAllocation = totalReservedTokenAllocation.sub(_amount);
        emit AllocateReservedTokens(_addr, _amount);
    }

   // Allocate sales tokens
    function allocateSalesTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalRemainingTokensForSales = totalRemainingTokensForSales.sub(_amount);
        emit AllocateSalesTokens(_addr, _amount);
    }
    // ERC20 standard function
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     // Issue tokens to normal investors through ICO rounds
    function issueTokensForICO(uint _state) private {
        uint256 price = icoStandardPrice;
        issueTokens(price, _state);
    }
    
    // Issue tokens to investors and transfer ether to wallet
    function issueTokens(uint256 _price, uint _state) private {
        require(walletAddress != address(0));
		
        uint tokenAmount = msg.value.mul(_price).mul(10**18).div(1 ether);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        walletAddress.transfer(msg.value);
        emit IssueTokens(msg.sender, msg.value, tokenAmount, _state);
    }

    // ERC20 standard function
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
    
     // Get current sales state
    function getCurrentState() public view returns(uint256) {
        return saleState;
    }
    // Get softcap reaching status
    function isSoftCapReached() public view returns (bool) {
        return totalInvestedAmount >= minInvestedCap;
    }
}