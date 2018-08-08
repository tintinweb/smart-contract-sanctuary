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


contract GreenX is Owner {
    using SafeMath for uint256;

    string public constant name = "GREENX";
    string public constant symbol = "GEX";
    uint public constant decimals = 18;
    uint256 constant public totalSupply = 375000000 * 10 ** 18; // 375 mil tokens will be supplied
  
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    address public portalAddress;
    address public adminAddress;
    address public walletAddress;
    address public founderAddress;
    address public teamAddress;

    mapping(address => bool) public privateList;
    mapping(address => bool) public whiteList;
    mapping(address => uint256) public totalInvestedAmountOf;

    uint constant lockPeriod1 = 180 days; // 1st locked period for tokens allocation of founder and team
    uint constant lockPeriod2 = 1 years; // 2nd locked period for tokens allocation of founder and team
    uint constant lockPeriod3 = 2 years; // locked period for remaining sale tokens after ending ICO
    uint constant NOT_SALE = 0; // Not in sales
    uint constant IN_PRIVATE_SALE = 1; // In private sales
    uint constant IN_PRESALE = 2; // In presales
    uint constant END_PRESALE = 3; // End presales
    uint constant IN_1ST_ICO = 4; // In ICO 1st round
    uint constant IN_2ND_ICO = 5; // In ICO 2nd round
    uint constant IN_3RD_ICO = 6; // In ICO 3rd round
    uint constant END_SALE = 7; // End sales

    uint256 public constant salesAllocation = 187500000 * 10 ** 18; // 187.5 mil tokens allocated for sales
    uint256 public constant bonusAllocation = 37500000 * 10 ** 18; // 37.5 mil tokens allocated for token sale bonuses
    uint256 public constant reservedAllocation = 90000000 * 10 ** 18; // 90 mil tokens allocated for reserved, bounty campaigns, ICO partners, and bonus fund
    uint256 public constant founderAllocation = 37500000 * 10 ** 18; // 37.5 mil tokens allocated for founders
    uint256 public constant teamAllocation = 22500000 * 10 ** 18; // 22.5 mil tokens allocated for team
    uint256 public constant minInvestedCap = 2500 * 10 ** 18; // 2500 ether for softcap 
    uint256 public constant minInvestedAmount = 0.1 * 10 ** 18; // 0.1 ether for mininum ether contribution per transaction
    
    uint saleState;
    uint256 totalInvestedAmount;
    uint public icoStartTime;
    uint public icoEndTime;
    bool public inActive;
    bool public isSelling;
    bool public isTransferable;
    uint public founderAllocatedTime = 1;
    uint public teamAllocatedTime = 1;
    uint256 public privateSalePrice;
    uint256 public preSalePrice;
    uint256 public icoStandardPrice;
    uint256 public ico1stPrice;
    uint256 public ico2ndPrice;
    uint256 public totalRemainingTokensForSales; // Total tokens remaining for sales
    uint256 public totalReservedAndBonusTokenAllocation; // Total tokens allocated for reserved and bonuses
    uint256 public totalLoadedRefund; // Total ether will be loaded to contract for refund
    uint256 public totalRefundedAmount; // Total ether refunded to investors

    event Approval(address indexed owner, address indexed spender, uint256 value); // ERC20 standard event
    event Transfer(address indexed from, address indexed to, uint256 value); // ERC20 standard event

    event ModifyWhiteList(address investorAddress, bool isWhiteListed);  // Add or remove investor&#39;s address to or from white list
    event ModifyPrivateList(address investorAddress, bool isPrivateListed);  // Add or remove investor&#39;s address to or from private list
    event StartPrivateSales(uint state); // Start private sales
    event StartPresales(uint state); // Start presales
    event EndPresales(uint state); // End presales
    event StartICO(uint state); // Start ICO sales
    event EndICO(uint state); // End ICO sales
    
    event SetPrivateSalePrice(uint256 price); // Set private sale price
    event SetPreSalePrice(uint256 price); // Set presale price
    event SetICOPrice(uint256 price); // Set ICO standard price
    
    event IssueTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint state); // Issue tokens to investor
    event RevokeTokens(address investorAddress, uint256 amount, uint256 tokenAmount, uint256 txFee); // Revoke tokens after ending ICO for incompleted KYC investors
    event AllocateTokensForFounder(address founderAddress, uint256 founderAllocatedTime, uint256 tokenAmount); // Allocate tokens to founders&#39; address
    event AllocateTokensForTeam(address teamAddress, uint256 teamAllocatedTime, uint256 tokenAmount); // Allocate tokens to team&#39;s address
    event AllocateReservedTokens(address reservedAddress, uint256 tokenAmount); // Allocate reserved tokens
    event Refund(address investorAddress, uint256 etherRefundedAmount, uint256 tokensRevokedAmount); // Refund ether and revoke tokens for investors

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
        require(msg.sender == owner || msg.sender == adminAddress || msg.sender == portalAddress);
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == adminAddress);
        _;
    }

    function GreenX(address _walletAddr, address _adminAddr, address _portalAddr) public Owner(msg.sender) {
        require(_walletAddr != address(0));
        require(_adminAddr != address(0));
        require(_portalAddr != address(0));
		
        walletAddress = _walletAddr;
        adminAddress = _adminAddr;
        portalAddress = _portalAddr;
        inActive = true;
        totalInvestedAmount = 0;
        totalRemainingTokensForSales = salesAllocation;
        totalReservedAndBonusTokenAllocation = reservedAllocation + bonusAllocation;
    }

    // Fallback function for token purchasing  
    function () external payable isActive isInSale {
        uint state = getCurrentState();
        require(state >= IN_PRIVATE_SALE && state < END_SALE);
        require(msg.value >= minInvestedAmount);

        bool isPrivate = privateList[msg.sender];
        if (isPrivate == true) {
            return issueTokensForPrivateInvestor(state);
        }
        if (state == IN_PRESALE) {
            return issueTokensForPresale(state);
        }
        if (IN_1ST_ICO <= state && state <= IN_3RD_ICO) {
            return issueTokensForICO(state);
        }
        revert();
    }

    // Load ether amount to contract for refunding or revoking
    function loadFund() external payable {
        require(msg.value > 0);
		
        totalLoadedRefund = totalLoadedRefund.add(msg.value);
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

    // Modify white list
    function modifyWhiteList(address[] _investorAddrs, bool _isWhiteListed) external isActive onlyOwnerOrAdminOrPortal returns(bool) {
        for (uint256 i = 0; i < _investorAddrs.length; i++) {
            whiteList[_investorAddrs[i]] = _isWhiteListed;
            emit ModifyWhiteList(_investorAddrs[i], _isWhiteListed);
        }
        return true;
    }

    // Modify private list
    function modifyPrivateList(address[] _investorAddrs, bool _isPrivateListed) external isActive onlyOwnerOrAdminOrPortal returns(bool) {
        for (uint256 i = 0; i < _investorAddrs.length; i++) {
            privateList[_investorAddrs[i]] = _isPrivateListed;
            emit ModifyPrivateList(_investorAddrs[i], _isPrivateListed);
        }
        return true;
    }

    // Start private sales
    function startPrivateSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == NOT_SALE);
        require(privateSalePrice > 0);
		
        saleState = IN_PRIVATE_SALE;
        isSelling = true;
        emit StartPrivateSales(saleState);
        return true;
    }

    // Start presales
    function startPreSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState < IN_PRESALE);
        require(preSalePrice > 0);
		
        saleState = IN_PRESALE;
        isSelling = true;
        emit StartPresales(saleState);
        return true;
    }

    // End presales
    function endPreSales() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == IN_PRESALE);
		
        saleState = END_PRESALE;
        isSelling = false;
        emit EndPresales(saleState);
        return true;
    }

    // Start ICO
    function startICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(saleState == END_PRESALE);
        require(icoStandardPrice > 0);
		
        saleState = IN_1ST_ICO;
        icoStartTime = now;
        isSelling = true;
        emit StartICO(saleState);
        return true;
    }

    // End ICO
    function endICO() external isActive onlyOwnerOrAdmin returns (bool) {
        require(getCurrentState() == IN_3RD_ICO);
        require(icoEndTime == 0);
		
        saleState = END_SALE;
        isSelling = false;
        icoEndTime = now;
        emit EndICO(saleState);
        return true;
    }

    // Set private sales price
    function setPrivateSalePrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        privateSalePrice = _tokenPerEther;
        emit SetPrivateSalePrice(privateSalePrice);
        return true;
    }

    // Set presales price
    function setPreSalePrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        preSalePrice = _tokenPerEther;
        emit SetPreSalePrice(preSalePrice);
        return true;
    }

    // Set ICO price including ICO standard price, ICO 1st round price, ICO 2nd round price
    function setICOPrice(uint256 _tokenPerEther) external onlyOwnerOrAdmin returns(bool) {
        require(_tokenPerEther > 0);
		
        icoStandardPrice = _tokenPerEther;
        ico1stPrice = _tokenPerEther + _tokenPerEther * 20 / 100;
        ico2ndPrice = _tokenPerEther + _tokenPerEther * 10 / 100;
        emit SetICOPrice(icoStandardPrice);
        return true;
    }

    // Revoke tokens from incompleted KYC investors&#39; addresses
    function revokeTokens(address _noneKycAddr, uint256 _transactionFee) external onlyOwnerOrAdmin {
        require(_noneKycAddr != address(0));
        uint256 investedAmount = totalInvestedAmountOf[_noneKycAddr];
        uint256 totalRemainingRefund = totalLoadedRefund.sub(totalRefundedAmount);
        require(whiteList[_noneKycAddr] == false && privateList[_noneKycAddr] == false);
        require(investedAmount > 0);
        require(totalRemainingRefund >= investedAmount);
        require(saleState == END_SALE);
		
        uint256 refundAmount = investedAmount.sub(_transactionFee);
        uint tokenRevoked = balances[_noneKycAddr];
        totalInvestedAmountOf[_noneKycAddr] = 0;
        balances[_noneKycAddr] = 0;
        totalRemainingTokensForSales = totalRemainingTokensForSales.add(tokenRevoked);
        totalRefundedAmount = totalRefundedAmount.add(refundAmount);
        _noneKycAddr.transfer(refundAmount);
        emit RevokeTokens(_noneKycAddr, refundAmount, tokenRevoked, _transactionFee);
    }    

    // Investors can claim ether refund if total raised fund doesn&#39;t reach our softcap
    function refund() external {
        uint256 refundedAmount = totalInvestedAmountOf[msg.sender];
        uint256 totalRemainingRefund = totalLoadedRefund.sub(totalRefundedAmount);
        uint256 tokenRevoked = balances[msg.sender];
        require(saleState == END_SALE);
        require(!isSoftCapReached());
        require(totalRemainingRefund >= refundedAmount && refundedAmount > 0);
		
        totalInvestedAmountOf[msg.sender] = 0;
        balances[msg.sender] = 0;
        totalRemainingTokensForSales = totalRemainingTokensForSales.add(tokenRevoked);
        totalRefundedAmount = totalRefundedAmount.add(refundedAmount);
        msg.sender.transfer(refundedAmount);
        emit Refund(msg.sender, refundedAmount, tokenRevoked);
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

    // Modify portal
    function changePortalAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0));
        require(portalAddress != _newAddress);
        portalAddress = _newAddress;
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
        require(teamAddress != _newAddress);
        teamAddress = _newAddress;
    }

    // Allocate tokens for founder vested gradually for 1 year
    function allocateTokensForFounder() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(founderAddress != address(0));
        uint256 amount;
        if (founderAllocatedTime == 1) {
            amount = founderAllocation * 20/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 2;
            return;
        }
        if (founderAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod1);
            amount = founderAllocation * 30/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 3;
            return;
        }
        if (founderAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod2);
            amount = founderAllocation * 50/100;
            balances[founderAddress] = balances[founderAddress].add(amount);
            emit AllocateTokensForFounder(founderAddress, founderAllocatedTime, amount);
            founderAllocatedTime = 4;
            return;
        }
        revert();
    }

    // Allocate tokens for team vested gradually for 1 year
    function allocateTokensForTeam() external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(teamAddress != address(0));
        uint256 amount;
        if (teamAllocatedTime == 1) {
            amount = teamAllocation * 20/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 2;
            return;
        }
        if (teamAllocatedTime == 2) {
            require(now >= icoEndTime + lockPeriod1);
            amount = teamAllocation * 30/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 3;
            return;
        }
        if (teamAllocatedTime == 3) {
            require(now >= icoEndTime + lockPeriod2);
            amount = teamAllocation * 50/100;
            balances[teamAddress] = balances[teamAddress].add(amount);
            emit AllocateTokensForTeam(teamAddress, teamAllocatedTime, amount);
            teamAllocatedTime = 4;
            return;
        }
        revert();
    }

    // Remaining tokens for sales will be locked by contract in 2 years
    function allocateRemainingTokens(address _addr) external isActive onlyOwnerOrAdmin {
        require(_addr != address(0));
        require(saleState == END_SALE);
        require(totalRemainingTokensForSales > 0);
        require(now >= icoEndTime + lockPeriod3);
        balances[_addr] = balances[_addr].add(totalRemainingTokensForSales);
        totalRemainingTokensForSales = 0;
    }

    // Allocate reserved tokens
    function allocateReservedTokens(address _addr, uint _amount) external isActive onlyOwnerOrAdmin {
        require(saleState == END_SALE);
        require(_amount > 0);
        require(_addr != address(0));
		
        balances[_addr] = balances[_addr].add(_amount);
        totalReservedAndBonusTokenAllocation = totalReservedAndBonusTokenAllocation.sub(_amount);
        emit AllocateReservedTokens(_addr, _amount);
    }

    // ERC20 standard function
    function allowance(address _owner, address _spender) external constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    // ERC20 standard function
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Get current sales state
    function getCurrentState() public view returns(uint256) {
        if (saleState == IN_1ST_ICO) {
            if (now > icoStartTime + 30 days) {
                return IN_3RD_ICO;
            }
            if (now > icoStartTime + 15 days) {
                return IN_2ND_ICO;
            }
            return IN_1ST_ICO;
        }
        return saleState;
    }

    // Get softcap reaching status
    function isSoftCapReached() public view returns (bool) {
        return totalInvestedAmount >= minInvestedCap;
    }

    // Issue tokens to private investors
    function issueTokensForPrivateInvestor(uint _state) private {
        uint256 price = privateSalePrice;
        issueTokens(price, _state);
    }

    // Issue tokens to normal investors in presales
    function issueTokensForPresale(uint _state) private {
        uint256 price = preSalePrice;
        issueTokens(price, _state);
    }

    // Issue tokens to normal investors through ICO rounds
    function issueTokensForICO(uint _state) private {
        uint256 price = icoStandardPrice;
        if (_state == IN_1ST_ICO) {
            price = ico1stPrice;
        } else if (_state == IN_2ND_ICO) {
            price = ico2ndPrice;
        }
        issueTokens(price, _state);
    }

    // Issue tokens to investors and transfer ether to wallet
    function issueTokens(uint256 _price, uint _state) private {
        require(walletAddress != address(0));
		
        uint tokenAmount = msg.value.mul(_price).mul(10**18).div(1 ether);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        totalInvestedAmountOf[msg.sender] = totalInvestedAmountOf[msg.sender].add(msg.value);
        totalRemainingTokensForSales = totalRemainingTokensForSales.sub(tokenAmount);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        walletAddress.transfer(msg.value);
        emit IssueTokens(msg.sender, msg.value, tokenAmount, _state);
    }
}