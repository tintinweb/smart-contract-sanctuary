pragma solidity ^0.4.21;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface GACR {
    function transfer(address to, uint256 value) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
    function totalSupply() external view returns (uint256);
    function setTeamAddress(address _teamFund) external;
    function transferOwnership(address newOwner) external;
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // ICO stage
    enum CrowdsaleStage { PreICO, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.PreICO; // By default it&#39;s Pre Sale

    // Token distribution
    uint256 public constant maxTokens           = 50000000*1e18;    // max of GACR tokens
    uint256 public constant tokensForSale       = 28500000*1e18;    // 57%
    uint256 public constant tokensForBounty     = 1500000*1e18;     // 3%
    uint256 public constant tokensForAdvisors   = 3000000*1e18;     // 6%
    uint256 public constant tokensForTeam       = 9000000*1e18;     // 18%
    uint256 public tokensForEcosystem           = 8000000*1e18;     // 16%

    // Start & End time of Crowdsale
    uint256 startTime   = 1522494000;   // 2018-03-31T11:00:00
    uint256 endTime     = 1539169200;   // 2018-10-10T11:00:00

    // The token being sold
    GACR public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Limit for total contributions
    uint256 public cap;

    // KYC for ICO
    mapping(address => bool) public whitelist;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @dev Event for whitelist update
     * @param purchaser who add to whitelist
     * @param status of purchased for whitelist
     */
    event WhitelistUpdate(address indexed purchaser, bool status);

    /**
     * @dev Event for crowdsale finalize
     */
    event Finalized();

    /**
     * @param _cap ether cap for Crowdsale
     * @param _rate Number of token units a buyer gets per wei
     * @param _wallet Address where collected funds will be forwarded to
     */
    constructor(uint256 _cap, uint256 _rate, address _wallet, address _token) public {
        require(_cap > 0);
        require(_rate > 0);
        require(_wallet != address(0));

        cap = _cap;
        rate = _rate;
        wallet = _wallet;
        token = GACR(_token);
    }

    /**
     * @dev Check that sale is on
     */
    modifier saleIsOn() {
        require(now > startTime && now < endTime);
        _;
    }

    //note: only for test
    //function setNowTime(uint value) public onlyOwner {
    //    require(value != 0);
    //    _nowTime = value;
    //}

    /**
     * @dev Buy tokens
     */
    function buyTokens(address _beneficiary) saleIsOn public payable {
        uint256 _weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= cap);

        require(stage==CrowdsaleStage.PreICO ||
               (stage==CrowdsaleStage.ICO && isWhitelisted(_beneficiary)));

        // calculate token amount to be created
        uint256 _tokenAmount = _weiAmount.mul(rate);

        // bonus calculation
        uint256 bonusTokens = 0;
        if (stage == CrowdsaleStage.PreICO) {
            if (_tokenAmount >= 50e18 && _tokenAmount < 3000e18) {
                bonusTokens = _tokenAmount.mul(23).div(100);
            } else if (_tokenAmount >= 3000e18 && _tokenAmount < 15000e18) {
                bonusTokens = _tokenAmount.mul(27).div(100);
            } else if (_tokenAmount >= 15000e18 && _tokenAmount < 30000e18) {
                bonusTokens = _tokenAmount.mul(30).div(100);
            } else if (_tokenAmount >= 30000e18) {
                bonusTokens = _tokenAmount.mul(35).div(100);
            }
        } else if (stage == CrowdsaleStage.ICO) {
            uint256 _nowTime = now;

            if (_nowTime >= 1531486800 && _nowTime < 1532696400) {
                bonusTokens = _tokenAmount.mul(18).div(100);
            } else if (_nowTime >= 1532696400 && _nowTime < 1533906000) {
                bonusTokens = _tokenAmount.mul(15).div(100);
            } else if (_nowTime >= 1533906000 && _nowTime < 1535115600) {
                bonusTokens = _tokenAmount.mul(12).div(100);
            } else if (_nowTime >= 1535115600 && _nowTime < 1536325200) {
                bonusTokens = _tokenAmount.mul(9).div(100);
            } else if (_nowTime >= 1536325200 && _nowTime < 1537534800) {
                bonusTokens = _tokenAmount.mul(6).div(100);
            } else if (_nowTime >= 1537534800 && _nowTime < endTime) {
                bonusTokens = _tokenAmount.mul(3).div(100);
            }
        }
        _tokenAmount += bonusTokens;

        // check limit for sale
        require(tokensForSale >= (token.totalSupply() + _tokenAmount));

        // update state
        weiRaised = weiRaised.add(_weiAmount);
        token.mint(_beneficiary, _tokenAmount);

        emit TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokenAmount);

        wallet.transfer(_weiAmount);
    }

    /**
     * @dev Payable function
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Change Crowdsale Stage.
     * Options: PreICO, ICO
     */
    function setCrowdsaleStage(uint value) public onlyOwner {

        CrowdsaleStage _stage;

        if (uint256(CrowdsaleStage.PreICO) == value) {
            _stage = CrowdsaleStage.PreICO;
        } else if (uint256(CrowdsaleStage.ICO) == value) {
            _stage = CrowdsaleStage.ICO;
        }

        stage = _stage;
    }

    /**
     * @dev Set new rate (protection from strong volatility)
     */
    function setNewRate(uint _newRate) public onlyOwner {
        require(_newRate > 0);
        rate = _newRate;
    }

    /**
     * @dev Set hard cap (protection from strong volatility)
     */
    function setHardCap(uint256 _newCap) public onlyOwner {
        require(_newCap > 0);
        cap = _newCap;
    }

    /**
     * @dev Set new wallet
     */
    function changeWallet(address _newWallet) public onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

    /**
     * @dev Add/Remove to whitelist array of addresses based on boolean status
     */
    function updateWhitelist(address[] addresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address contributorAddress = addresses[i];
            whitelist[contributorAddress] = status;
            emit WhitelistUpdate(contributorAddress, status);
        }
    }

    /**
     * @dev Check that address is exist in whitelist
     */
    function isWhitelisted(address contributor) public constant returns (bool) {
        return whitelist[contributor];
    }

    /**
     * @dev Function to mint tokens
     */
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        return token.mint(_to, _amount);
    }

    /**
     * @dev Return ownership to previous owner
     */
    function returnOwnership() onlyOwner public returns (bool) {
        token.transferOwnership(owner);
    }

    /**
     * @dev Finish Crowdsale
     */
    function finish(address _bountyFund, address _advisorsFund, address _ecosystemFund, address _teamFund) public onlyOwner {
        require(_bountyFund != address(0));
        require(_advisorsFund != address(0));
        require(_ecosystemFund != address(0));
        require(_teamFund != address(0));

        emit Finalized();

        // unsold tokens to ecosystem (perhaps further they will be burnt)
        uint256 unsoldTokens = tokensForSale - token.totalSupply();
        if (unsoldTokens > 0) {
            tokensForEcosystem = tokensForEcosystem + unsoldTokens;
        }

        // distribute
        token.mint(_bountyFund,tokensForBounty);
        token.mint(_advisorsFund,tokensForAdvisors);
        token.mint(_ecosystemFund,tokensForEcosystem);
        token.mint(_teamFund,tokensForTeam);

        // finish
        token.finishMinting();

        // freeze team tokens
        token.setTeamAddress(_teamFund);
    }
}