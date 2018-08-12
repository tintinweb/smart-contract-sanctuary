pragma solidity ^0.4.24;

contract DMIBLog {
    event MIBLog(bytes4 indexed sig, address indexed sender, uint _value) anonymous;

    modifier mlog {
        emit MIBLog(msg.sig, msg.sender, msg.value);
        _;
    }
}

contract Ownable {
    address public owner;

    event OwnerLog(address indexed previousOwner, address indexed newOwner, bytes4 sig);

    constructor() public { 
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));
        emit OwnerLog(owner, newOwner, msg.sig);
        owner = newOwner;
    }
}

contract MIBStop is Ownable, DMIBLog {

    bool public stopped;

    modifier stoppable {
        require (!stopped);
        _;
    }
    function stop() onlyOwner mlog public {
        stopped = true;
    }
    function start() onlyOwner mlog public {
        stopped = false;
    }
}

library SafeMath {
    
    /**
     * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
    
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
        )
    internal
    {
        require(token.transferFrom(from, to, value));
    }
}


contract MIBTokenSale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    ERC20 mibtokenaddress;
    
    uint8 private nowvestingType = 0;
    uint256 private minimum_wei = 1e18;         // 1eth
    
    uint256 private totalWeiEther;
    
    uint8 k;
    
    mapping(uint8 => uint) assignTokensperType ;
    mapping(uint8 => uint) remainTokensperType ;
    mapping(uint8 => uint) nowTokensperEth;
    mapping(uint8 => uint) distributionTimes;

    uint8 public iDistribution;
    uint8 public iICO;

    modifier canDistribute() {
        require(iICO == 1);
        require(iDistribution > 1);
        _;
    }
    

    enum InvestTypes { Angels, Pre_sales, Ico, Offices, Teams, Advisors, Stocks, MAX_InvestTypes }
    
    event TokenPurchase(address indexed _sender, address indexed _to, uint256 _value1, uint _value2, uint _value3);  
    event MibTokenSend(address indexed _sender, address indexed _to, uint256 _value1, uint _value2, uint _value3);  
    event MibSetLog(address indexed _sender, uint256 _value1, uint _value2, uint _value3);  

    //vesting, sep, rate, start date, end date, start distribution date
    constructor(
            ERC20 _mibtokenaddress,
            uint [] vesting,
            uint8 [] sep,
            uint [] rate
        ) public {
        
            mibtokenaddress = ERC20(_mibtokenaddress);
    
            //proceed only ico
            nowvestingType = uint8(InvestTypes.Ico);
    
            for(k=0; k<uint8(InvestTypes.MAX_InvestTypes); k++)
            {
                remainTokensperType[k] = remainTokensperType[k].add(vesting[k] * 1e18);
                assignTokensperType[k] = assignTokensperType[k].add(vesting[k] * 1e18);
                nowTokensperEth[k] = rate[k];
                distributionTimes[k] = sep[k];
            }     
    
            totalWeiEther = 0;
        
    }  
    
    function setVestingRate(uint256 _icorate) onlyOwner public {

        nowTokensperEth[uint8(InvestTypes.Ico)] = _icorate;
        
        emit MibSetLog(msg.sender, 0, 0, _icorate);
    }

    function setVestingType(uint8 _type) onlyOwner public {
        require(_type < uint8(InvestTypes.MAX_InvestTypes));
        nowvestingType = _type;
        //proceed only ico
        nowvestingType = uint8(InvestTypes.Ico);
        
        emit MibSetLog(msg.sender, 0, 0, nowvestingType);
        
    }
    
    function startICO() onlyOwner public {
        require(iDistribution < 1);
        require(iICO < 1);
        iICO = 2;
    }

    function stopICO() onlyOwner public {
        require(iDistribution <= 1);
        iICO = 1;
    }
    
    function distributionStart() onlyOwner public {
        require(iICO == 1);
        iDistribution = 2;
    }

    function getDistributionStatus() onlyOwner public view returns(uint8) {
        return iDistribution;
    }
    
    function getNowVestingType() public view returns (uint8) {
        return nowvestingType;
    }
    
    function getassignTokensperType(uint8 _type) public view returns (uint) {
        return assignTokensperType[_type];
    }
    
    function getremainTokensperType(uint8 _type) public view returns (uint) {
        return remainTokensperType[_type];
    }

    function getTotalWEIEther() onlyOwner public view returns (uint256) { 
        return totalWeiEther; 
    }

    function () external payable {
        
        buyTokens(msg.sender, nowvestingType);
    }
    
    function buyTokens(address _to, uint8 _type) public payable {
        uint256 tokens;
        
        require(iICO > 1);

        require(_type < uint8(InvestTypes.MAX_InvestTypes));
        
        tokens = _preValidatePurchase(_to, _type, msg.value);

        processPurchase(_to, _type, tokens);
        remainTokensperType[_type] = remainTokensperType[_type].sub(tokens);
        
        mibtokenaddress.safeTransfer(_to, tokens);
        
    }
    
    function _preValidatePurchase(
        address _to,
        uint8 _type,
        uint256 _weiAmount
        )
    internal 
    view
    returns (uint256)
    {
        uint256 tokens;
        uint256 tmpTokens;
        
        require(_to != address(0));
        require(_weiAmount >= minimum_wei);

        tokens = nowTokensperEth[nowvestingType].mul(msg.value);
        
        tmpTokens = tokens.mul(20).div(100);
        tokens = tokens.add(tmpTokens);
        
        require(tokens > 0);
        
        require(tokens <= remainTokensperType[_type]);
        
        return tokens;
    }
  
    
    function processPurchase(address _to, uint8 _type, uint256 _tokens) internal {

        _forwardFunds();
        totalWeiEther += msg.value;

        emit TokenPurchase(owner, _to, _type, msg.value, _tokens);
    }

    function ownerSendTokens(address _to, uint8 _type, uint256 _weitokens) 
        public 
        canDistribute
        onlyOwner
        payable
        returns (uint256)
    {
        uint256 remaintokens;
        
        remaintokens = remainTokensperType[_type];
        
        require(remaintokens >= _weitokens);
        require(_type < uint8(InvestTypes.MAX_InvestTypes));
        
        mibtokenaddress.safeTransfer(_to, _weitokens);
        remainTokensperType[_type] = remainTokensperType[_type].sub(_weitokens);
        
        emit MibTokenSend(msg.sender, _to, _type, _weitokens, remainTokensperType[_type]);
        return (remainTokensperType[_type]);
        
    }
    
    function _forwardFunds() internal  {
        owner.transfer(msg.value);
    }

}