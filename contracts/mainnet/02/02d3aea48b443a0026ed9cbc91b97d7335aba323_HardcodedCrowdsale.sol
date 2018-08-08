pragma solidity ^0.4.17;

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

interface ManagedToken{
    function setLock(bool _newLockState) public returns (bool success);
    function mint(address _for, uint256 _amount) public returns (bool success);
    function demint(address _for, uint256 _amount) public returns (bool success);
    function decimals() constant public returns (uint8 decDigits);
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
}
  
contract HardcodedCrowdsale {
    using SafeMath for uint256;

    //global definisions

    enum ICOStateEnum {NotStarted, Started, Refunded, Successful}


    address public owner = msg.sender;
    ManagedToken public managedTokenLedger;

    string public name = "MDBlockchainPreICO";
    string public symbol = "MDB";

    bool public unlocked = false;
    bool public halted = false;

    uint256 public totalSupply = 0;
    
    uint256 public minTokensToBuy = 1000;
    
    uint256 public preICOcontributors = 0;
    uint256 public ICOcontributors = 0;

    uint256 public preICOstart;
    uint256 public preICOend;
    uint256 public preICOgoal;
    uint256 public preICOcollected = 0;
    uint256 public preICOcap = 0 ether;
    uint256 public preICOtokensSold = 0;
    ICOStateEnum public preICOstate = ICOStateEnum.NotStarted;
    
    uint8 public decimals = 18;
    uint256 public DECIMAL_MULTIPLIER = 10**uint256(decimals);

    uint256[3] public preICOrates = [uint(1 ether).div(1600), uint(1 ether).div(1400), uint(1 ether).div(1200)];
    uint256[3] public preICOcoinsLeft = [7000000*DECIMAL_MULTIPLIER, 14000000*DECIMAL_MULTIPLIER, 21000000*DECIMAL_MULTIPLIER];
    uint256 public totalPreICOavailible = 42000000*DECIMAL_MULTIPLIER;

    mapping(address => uint256) public weiForRefundPreICO;

    mapping(address => uint256) public weiToRecoverPreICO;

    mapping(address => uint256) public balancesForPreICO;

    event Purchased(address indexed _from, uint256 _value);

    function advanceState() public returns (bool success) {
        transitionState();
        return true;
    }

    function transitionState() internal {
        if (now >= preICOstart) {
            if (preICOstate == ICOStateEnum.NotStarted) {
                preICOstate = ICOStateEnum.Started;
            }
            if (preICOcap > 0 && preICOcollected >= preICOcap) {
                preICOstate = ICOStateEnum.Successful;
            }
            if (preICOtokensSold == totalPreICOavailible) {
                preICOstate = ICOStateEnum.Successful;
            }
        } if (now >= preICOend) {
            if (preICOstate == ICOStateEnum.Started) {
                if (preICOcollected >= preICOgoal) {
                    preICOstate = ICOStateEnum.Successful;
                } else {
                    preICOstate = ICOStateEnum.Refunded;
                }
            }
        } 
    }

    modifier stateTransition() {
        transitionState();
        _;
        transitionState();
    }

    modifier requirePreICOState(ICOStateEnum _state) {
        require(preICOstate == _state);
        _;
    }

    modifier notHalted() {
        require(!halted);
        _;
    }

    // Ownership

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));      
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return managedTokenLedger.balanceOf(_owner);
    }


    function HardcodedCrowdsale (uint _preICOstart, uint _preICOend, uint _preICOgoal, uint _preICOcap, address _newLedgerAddress) public {
        require(_preICOstart > now);
        require(_preICOend > _preICOstart);
        require(_preICOgoal > 0);
        require(_newLedgerAddress != address(0));
        preICOstart = _preICOstart;
        preICOend = _preICOend;
        preICOgoal = _preICOgoal;
        preICOcap = _preICOcap;
        managedTokenLedger = ManagedToken(_newLedgerAddress);
        decimals = managedTokenLedger.decimals();
        DECIMAL_MULTIPLIER = 10**uint256(decimals);
    }

    function setNameAndTicker(string _name, string _symbol) onlyOwner public returns (bool success) {
        require(bytes(_name).length > 1);
        require(bytes(_symbol).length > 1);
        name = _name;
        symbol = _symbol;
        return true;
    }

    function setLedger (address _newLedgerAddress) onlyOwner public returns (bool success) {
        require(_newLedgerAddress != address(0));
        managedTokenLedger = ManagedToken(_newLedgerAddress);
        decimals = managedTokenLedger.decimals();
        DECIMAL_MULTIPLIER = 10**uint256(decimals);
        return true;
    }

    function () payable stateTransition notHalted public {
        if (preICOstate == ICOStateEnum.Started) {
            assert(preICOBuy());
        } else {
            revert();
        }
    }

    function transferPreICOCollected() onlyOwner stateTransition public returns (bool success) {
        require(preICOstate == ICOStateEnum.Successful);
        owner.transfer(preICOcollected);
        return true;
    }

    function setHalt(bool _halt) onlyOwner public returns (bool success) {
        halted = _halt;
        return true;
    }

    function calculateAmountBoughtPreICO(uint256 _weisSentScaled) internal returns (uint256 _tokensToBuyScaled, uint256 _weisLeftScaled) {
        uint256 value = _weisSentScaled;
        uint256 totalPurchased = 0;
        for (uint8 i = 0; i < preICOrates.length; i++) {
            if (preICOcoinsLeft[i] == 0) {
                continue;
            }
            uint256 rate = preICOrates[i];
            uint256 forThisRate = value.div(rate);
            if (forThisRate == 0) {
                break;
            }
            if (forThisRate > preICOcoinsLeft[i]) {
                forThisRate = preICOcoinsLeft[i];
                preICOcoinsLeft[i] = 0;
            } else {
                preICOcoinsLeft[i] = preICOcoinsLeft[i].sub(forThisRate);
            }
            uint256 consumed = forThisRate.mul(rate);
            value = value.sub(consumed);
            totalPurchased = totalPurchased.add(forThisRate);
        }
        return (totalPurchased, value);
    }

    function preICOBuy() internal notHalted returns (bool success) {
        uint256 weisSentScaled = msg.value.mul(DECIMAL_MULTIPLIER);
        address _for = msg.sender;
        var (tokensBought, fundsLeftScaled) = calculateAmountBoughtPreICO(weisSentScaled);
        if (tokensBought < minTokensToBuy.mul(DECIMAL_MULTIPLIER)) {
            revert();
        }
        uint256 fundsLeft = fundsLeftScaled.div(DECIMAL_MULTIPLIER);
        uint256 totalSpent = msg.value.sub(fundsLeft);
        if (balanceOf(_for) == 0) {
            preICOcontributors = preICOcontributors + 1;
        }
        managedTokenLedger.mint(_for, tokensBought);
        balancesForPreICO[_for] = balancesForPreICO[_for].add(tokensBought);
        weiForRefundPreICO[_for] = weiForRefundPreICO[_for].add(totalSpent);
        weiToRecoverPreICO[_for] = weiToRecoverPreICO[_for].add(fundsLeft);
        Purchased(_for, tokensBought);
        preICOcollected = preICOcollected.add(totalSpent);
        totalSupply = totalSupply.add(tokensBought);
        preICOtokensSold = preICOtokensSold.add(tokensBought);
        return true;
    }

    function recoverLeftoversPreICO() stateTransition notHalted public returns (bool success) {
        require(preICOstate != ICOStateEnum.NotStarted);
        uint256 value = weiToRecoverPreICO[msg.sender];
        delete weiToRecoverPreICO[msg.sender];
        msg.sender.transfer(value);
        return true;
    }

    function refundPreICO() stateTransition requirePreICOState(ICOStateEnum.Refunded) notHalted 
        public returns (bool success) {
            uint256 value = weiForRefundPreICO[msg.sender];
            delete weiForRefundPreICO[msg.sender];
            uint256 tokenValue = balancesForPreICO[msg.sender];
            delete balancesForPreICO[msg.sender];
            managedTokenLedger.demint(msg.sender, tokenValue);
            msg.sender.transfer(value);
            return true;
    }

    function cleanup() onlyOwner public {
        selfdestruct(owner);
    }

}