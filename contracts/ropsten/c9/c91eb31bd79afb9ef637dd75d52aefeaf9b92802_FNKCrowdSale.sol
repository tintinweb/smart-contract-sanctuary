pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// &#39;FunkeyCoin&#39; CROWDSALE contract
//
// Deployed to : 0x06404399e748CD83F25AB163711F9F4D61cfd0e6
// Symbol      : FNK
// Name        : FunkeyCoin
// Total supply: 20,000,000,000 FNK
// Decimals    : 18
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// @Name SafeMath
// @Desc Math operations with safety checks that throw on error
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------
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
        return a / b;
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
// ----------------------------------------------------------------------------
// @title ERC20Basic
// @dev Simpler version of ERC20 interface
// See https://github.com/ethereum/EIPs/issues/179
// ----------------------------------------------------------------------------
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
// ----------------------------------------------------------------------------
// @title ERC20 interface
// @dev See https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool); 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// ----------------------------------------------------------------------------
// @Name Ownable 
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
// ----------------------------------------------------------------------------
// @Name WhiteList
// @desc KYC Completed
// ----------------------------------------------------------------------------
contract WhiteList is Ownable {

    mapping( address => bool ) public whiteList;
    
    event KYCComplete(address indexed CompleteAddress);
    event KYCCancel(address indexed CancelAddress);

    modifier CheckWhiteList { require(whiteList[msg.sender] != true); _; }

    function completeWhiteList(address[] _whiteListAddress) external onlyOwner {
        for (uint16 ui = 0; ui < _whiteListAddress.length; ui++) {
            whiteList[_whiteListAddress[ui]] = true;
            
            emit KYCComplete(_whiteListAddress[ui]);
        }
    }

    function cancelWhiteList(address[] _blackListAddress) external onlyOwner {
        for (uint16 ui = 0; ui < _blackListAddress.length; ui++) {
            whiteList[_blackListAddress[ui]] = false;
            
            emit KYCCancel(_blackListAddress[ui]);
        }
    }
}
// ----------------------------------------------------------------------------
// @Name SalePeriod
// @Desc Funkey CrowdSale Period(Start / End / Round )
// ----------------------------------------------------------------------------
contract SalePeriod is Ownable {
    
    uint256 public startDate;
    uint256[5] public bonusDate;
    uint256 public endDate;
    uint8 public saleRound;
    
    bool public isStarted;
    
    event ICOStart(uint256 indexed Start, uint256 indexed End);

    constructor() public {
        isStarted = false;
    }
    
    modifier isSaleStarted() { require(isStarted); _; }
    modifier isSaleEnded() { require(!isStarted); _; }
    modifier isProgressing() { require(now >= startDate && now <= endDate); _;}
    
    function crowdSaleStart(uint16 _endDate, uint16[5] _roundPeriod) external onlyOwner isSaleStarted {
        isStarted = true;
        startDate = now;
        endDate = now + (_endDate * 1 days);
        
        for(uint8 ui; ui < 5; ui++) {
            bonusDate[ui] = now + (_roundPeriod[ui] * 1 days);
        }
        
        saleRound = 0;
        
        emit ICOStart(startDate, endDate);
    }
    
    function getRoundBonusRate() internal isSaleStarted returns (uint8) { 
        
        uint8 bonusRate;
        
        if (now >= bonusDate[0] && now < bonusDate[1]) {
            saleRound = 0;
            bonusRate = 15;
        } else if (now >= bonusDate[1] && now < bonusDate[2]) {
            saleRound = 1;
            bonusRate = 10;
        } else if (now >= bonusDate[3] && now < bonusDate[4]) {
            saleRound = 2;
            bonusRate = 5;
        } else if (now >= bonusDate[4] && now < endDate) {
            saleRound = 3;
            bonusRate = 1;
        }
        
        return bonusRate;
    }
    
    function _getSaleRound() public view returns (uint8) {
        return saleRound;
    }
    
    // Emergency
    // Destroy
}
// ----------------------------------------------------------------------------
// @Name ContractWallet
// @desc FNK / ETH Deposit & Transfer
// ----------------------------------------------------------------------------
contract ContractWallet is Ownable, SalePeriod {
    // The token being sold
    ERC20 public FunkeyCoin;
    
    // Address where funds are collected
    address public wallet;
    
    constructor() public {
        FunkeyCoin = ERC20(0x06404399e748CD83F25AB163711F9F4D61cfd0e6);
        wallet = msg.sender;
    }
    
    function deliverTokens(uint256 _tokenAmount) internal {
        FunkeyCoin.transfer(msg.sender, _tokenAmount);
    }
    
    function deliverETH() internal {
        wallet.transfer(msg.value);
    }
    
    function _getTokenAmount() external view returns (uint256) {
        return FunkeyCoin.balanceOf(this);
    }
    
    function _getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function endSale() external onlyOwner isSaleEnded {
        FunkeyCoin.transfer(msg.sender, FunkeyCoin.balanceOf(this));
    }
}
// ----------------------------------------------------------------------------
// @Name CalculateBounusRate
// @Desc 
// ----------------------------------------------------------------------------
contract CalculateBounusRate is ContractWallet {
    using SafeMath for uint256;
    
    // How many token units a buyer gets per wei
    uint256 public rate;
    // Amount of wei raised
    uint256 public weiRaised;
    
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    function calculateFNKRate() internal returns (uint256) {
        
        uint256 fnkAmounts;
        uint8 bonusRate = getRoundBonusRate();
        
        fnkAmounts = msg.value * 1000 * bonusRate;
        
        return fnkAmounts;
    }
    
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    /*function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
    
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // update state
        weiRaised = weiRaised.add(weiAmount);
        
        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        
        _updatePurchasingState(_beneficiary, weiAmount);
        
        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }*/
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract FNKCrowdSale is CalculateBounusRate, WhiteList {
 
    event ICOParticipation(address indexed participant, uint256 indexed ethAmounts, uint256 indexed fnkAmounts);
    
    // ------------------------------------------------------------------------
    // 10,000 FNK Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable CheckWhiteList isProgressing {
        
        uint256 tokens;
        tokens = calculateFNKRate();
        
        // Check FNK Balance
        require(tokens <= FunkeyCoin.balanceOf(this));
        
        deliverTokens(tokens);
        deliverETH();
        
        emit ICOParticipation(msg.sender, msg.value, tokens);
    }
}