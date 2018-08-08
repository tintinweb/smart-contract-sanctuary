pragma solidity ^0.4.18;

//Contract By Yoav Taieb. <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="750c1a14035b1c1a06111003351218141c195b161a18">[email&#160;protected]</a>

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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

interface LikaToken {
    function setLock(bool _newLockState) external returns (bool success);
    function mint(address _for, uint256 _amount) external returns (bool success);
    function demint(address _for, uint256 _amount) external returns (bool success);
    function decimals() view external returns (uint8 decDigits);
    function totalSupply() view external returns (uint256 supply);
    function balanceOf(address _owner) view external returns (uint256 balance);
}

contract LikaCrowdsale {
    using SafeMath for uint256;
    //global definisions
    enum ICOStateEnum {NotStarted, Started, Refunded, Successful}

    address public owner = msg.sender;

    LikaToken public managedTokenLedger;

    string public name = "Lika";
    string public symbol = "LIK";

    bool public halted = false;

    uint256 public minTokensToBuy = 100;

    uint256 public ICOcontributors = 0;

    uint256 public ICOstart = 1526947200; //17 May 1018 00:00:00 GMT
    uint256 public ICOend = 1529884800; // 17 June 2018 00:00:00 GMT
    uint256 public Hardcap = 2000 ether;
    uint256 public ICOcollected = 0;
    uint256 public Softcap = 200 ether;
    uint256 public ICOtokensSold = 0;
    uint256 public TakedFunds = 0;

    uint256 public bonusState = 0;

    ICOStateEnum public ICOstate = ICOStateEnum.NotStarted;

    uint8 public decimals = 18;
    uint256 public DECIMAL_MULTIPLIER = 10**uint256(decimals);

    uint256 public ICOprice = uint256(12 ether).div(100000);
    uint256[4] public ICOamountBonusLimits = [5 ether, 20 ether, 50 ether, 200 ether];
    uint256[4] public ICOamountBonusMultipierInPercent = [103, 105, 107, 110]; // count bonus
    uint256[5] public ICOweekBonus = [152, 117, 110, 105, 102]; // time bonus

    mapping(address => uint256) public weiForRefundICO;

    mapping(address => uint256) public weiToRecoverICO;

    mapping(address => uint256) public balancesForICO;

    event Purchased(address indexed _from, uint256 _value);

    function advanceState() public returns (bool success) {
        transitionState();
        return true;
    }

    function transitionState() internal {

      if (now >= ICOstart) {
            if (ICOstate == ICOStateEnum.NotStarted) {
                ICOstate = ICOStateEnum.Started;
            }
            if (Hardcap > 0 && ICOcollected >= Hardcap) {
                ICOstate = ICOStateEnum.Successful;
            }
        } if (now >= ICOend) {
            if (ICOstate == ICOStateEnum.Started) {
                if (ICOcollected >= Softcap) {
                    ICOstate = ICOStateEnum.Successful;
                } else {
                    ICOstate = ICOStateEnum.Refunded;
                }
             }
         }
     }

    modifier stateTransition() {
        transitionState();
        _;
        transitionState();
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

    // Ownership

    event OwnershipTransferred(address indexed viousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return managedTokenLedger.balanceOf(_owner);
    }

    function totalSupply() view public returns (uint256 balance) {
        return managedTokenLedger.totalSupply();
    }


    constructor(address _newLedgerAddress) public {
        require(_newLedgerAddress != address(0));
        managedTokenLedger = LikaToken(_newLedgerAddress);
    }

    function setNameAndTicker(string _name, string _symbol) onlyOwner public returns (bool success) {
        require(bytes(_name).length > 1);
        require(bytes(_symbol).length > 1);
        name = _name;
        symbol = _symbol;
        return true;
    }

    function setBonusState(uint256 _newState) onlyOwner public returns (bool success){
       bonusState = _newState;
       return true;
    }


    function setLedger(address _newLedgerAddress) onlyOwner public returns (bool success) {
        require(_newLedgerAddress != address(0));
        managedTokenLedger = LikaToken(_newLedgerAddress);
        return true;
    }


    function () public payable stateTransition notHalted {
        require(msg.value > 0);
        require(ICOstate == ICOStateEnum.Started);
        assert(ICOBuy());
    }

    function finalize() stateTransition public returns (bool success) {
        require(ICOstate == ICOStateEnum.Successful);
        owner.transfer(ICOcollected - TakedFunds);
        return true;
    }

    function setHalt(bool _halt) onlyOwner public returns (bool success) {
        halted = _halt;
        return true;
    }

    function calculateAmountBoughtICO(uint256 _weisSentScaled, uint256 _amountBonusMultiplier)
        view internal returns (uint256 _tokensToBuyScaled, uint256 _weisLeftScaled) {
        uint256 value = _weisSentScaled;
        uint256 totalPurchased = 0;

      totalPurchased = value.div(ICOprice);
	    uint256 weekbonus = getWeekBonus(totalPurchased).sub(totalPurchased);
	    uint256 forThisRate = totalPurchased.mul(_amountBonusMultiplier).div(100).sub(totalPurchased);
	    value = _weisSentScaled.sub(totalPurchased.mul(ICOprice));
      totalPurchased = totalPurchased.add(forThisRate).add(weekbonus);

      return (totalPurchased, value);
    }

    function getBonusMultipierInPercents(uint256 _sentAmount) public view returns (uint256 _multi) {
        uint256 bonusMultiplier = 100;
        for (uint8 i = 0; i < ICOamountBonusLimits.length; i++) {
            if (_sentAmount < ICOamountBonusLimits[i]) {
                break;
            } else {
                bonusMultiplier = ICOamountBonusMultipierInPercent[i];
            }
        }
        return bonusMultiplier;
    }

    function getWeekBonus(uint256 amountTokens) internal view returns(uint256 count) {
        uint256 countCoints = 0;
        uint256 bonusMultiplier = 100;

        //You can check the current Bonus State on www.LikaCoin.io

        if (bonusState == 0) {
           countCoints = amountTokens.mul(ICOweekBonus[0]);
        } else if (bonusState == 1) {
           countCoints = amountTokens.mul(ICOweekBonus[1] );
        } else if (bonusState == 2) {
          countCoints = amountTokens.mul(ICOweekBonus[2] );
        } else if (bonusState == 3) {
          countCoints = amountTokens.mul(ICOweekBonus[3] );
        }else {
          countCoints = amountTokens.mul(ICOweekBonus[3] );
        }

        return countCoints.div(bonusMultiplier);
    }

    function ICOBuy() internal notHalted returns (bool success) {
        uint256 weisSentScaled = msg.value.mul(DECIMAL_MULTIPLIER);
        address _for = msg.sender;
        uint256 amountBonus = getBonusMultipierInPercents(msg.value);
        uint256 tokensBought;
        uint256 fundsLeftScaled;
        (tokensBought, fundsLeftScaled) = calculateAmountBoughtICO(weisSentScaled, amountBonus);
        if (tokensBought < minTokensToBuy.mul(DECIMAL_MULTIPLIER)) {
            revert();
        }
        uint256 fundsLeft = fundsLeftScaled.div(DECIMAL_MULTIPLIER);
        uint256 totalSpent = msg.value.sub(fundsLeft);
        if (balanceOf(_for) == 0) {
            ICOcontributors = ICOcontributors + 1;
        }
        managedTokenLedger.mint(_for, tokensBought);
        balancesForICO[_for] = balancesForICO[_for].add(tokensBought);
        weiForRefundICO[_for] = weiForRefundICO[_for].add(totalSpent);
        weiToRecoverICO[_for] = weiToRecoverICO[_for].add(fundsLeft);
        emit Purchased(_for, tokensBought);
        ICOcollected = ICOcollected.add(totalSpent);
        ICOtokensSold = ICOtokensSold.add(tokensBought);
        return true;
   }

    function recoverLeftoversICO() stateTransition notHalted public returns (bool success) {
        require(ICOstate != ICOStateEnum.NotStarted);
        uint256 value = weiToRecoverICO[msg.sender];
        delete weiToRecoverICO[msg.sender];
        msg.sender.transfer(value);
        return true;
    }

    function refundICO(address refundAdress) stateTransition notHalted onlyOwner public returns (bool success) {
        require(ICOstate == ICOStateEnum.Refunded);
        uint256 value = weiForRefundICO[refundAdress];
        delete weiForRefundICO[refundAdress];
        uint256 tokenValue = balancesForICO[refundAdress];
        delete balancesForICO[refundAdress];
        managedTokenLedger.demint(refundAdress, tokenValue);
        refundAdress.transfer(value);
        return true;
    }

    function withdrawFunds() onlyOwner public returns (bool success) {
        require(Softcap <= ICOcollected);
        owner.transfer(ICOcollected - TakedFunds);
        TakedFunds = ICOcollected;
        return true;
    }

    function setSoftCap(uint256 _newSoftCap) onlyOwner public returns (bool success) {
       Softcap = _newSoftCap;
       return true;
    }

    function setHardCap(uint256 _newHardCap) onlyOwner public returns (bool success) {
       Hardcap = _newHardCap;
       return true;
    }

    function setEndDate(uint256 _newEndDate) onlyOwner public returns (bool success) {
          ICOend = _newEndDate;
          return true;
    }


    function manualSendTokens(address rAddress, uint256 amount) onlyOwner public returns (bool success) {
        managedTokenLedger.mint(rAddress, amount);
        balancesForICO[rAddress] = balancesForICO[rAddress].add(amount);
        emit Purchased(rAddress, amount);
        ICOtokensSold = ICOtokensSold.add(amount);
        return true;
    }

}