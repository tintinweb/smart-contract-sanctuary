/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); owner = newOwner;}
}

contract Destructible is Ownable {}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {}
contract CoinRateMintableStandard {
    uint256 public coinRateRewards;
    uint256 public onlyStrongHolder;
    function mintingCoinRate() public returns (bool);
    event CoinRateMinting(address indexed _address, uint _coinRateMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Besta is ERC20, CoinRateMintableStandard, Ownable {
    using SafeMath for uint256;

    string public name = "Besta";
    string public symbol = "BESTA";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function Reep() public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 400000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= onlyStrongHolder) return mintingCoinRate();
        if(msg.sender == _to && balances[msg.sender] < onlyStrongHolder) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }
    
    function burn(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Transfer(account, address(0), _value);
    }

    function mint(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        totalInitialSupply = totalInitialSupply.add(_value);
        emit Transfer(address(0), msg.sender, _value);
    }
    
    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

    uint256 public coinRateRewards = 30000000 * (10**decimals);
    uint256 public coinRateStartTime; //CoinAge Minting start time
    
    uint256 public coinRate = 10;
    uint256 public eraInterval = 180;

    uint256 public onlyStrongHolder = 300 * (10**decimals); //Minimum coins/tokens hold in wallet to trigger minting
    
    modifier StrongHolderMinter() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= onlyStrongHolder);
        _;
    }

    function mintingCoinRate() StrongHolderMinter public returns (bool) {
        require(balances[msg.sender] >= onlyStrongHolder);
        
        if(balances[msg.sender] < onlyStrongHolder) revert();
        
        uint coinRateMinting = getCoinRateMinting();
        
        if(coinRateMinting <= 0) return false;
        
        assert(coinRateMinting <= coinRateRewards);
        assert(coinRateRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinRateMinting);
        coinRateRewards = coinRateRewards.sub(coinRateMinting);
        balances[msg.sender] = balances[msg.sender].add(coinRateMinting);

        emit CoinRateMinting(msg.sender, coinRateMinting);
        emit Transfer(address(0), msg.sender, coinRateMinting);
        return true;
    }

    function getCoinRateMinting() internal view returns (uint) {
        require((now >= coinRateStartTime) && (coinRateStartTime > 0));
        uint blockRate = totalSupply.div(coinRateRewards);
        uint rewardRate = blockRate.mul(eraInterval);
        uint coinRateMinting = rewardRate.mul(coinRate);
        return coinRateMinting;
    }
    
    function CoinRateMintingStart() public onlyOwner {
        require(msg.sender == owner && coinRateStartTime == 0);
        coinRateStartTime = now;
    }
    
    function setCoinRateRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        coinRateRewards = coinRateRewards.add(value);
    }
    
    function setCoinRate(uint256 _coinRate) public onlyOwner {
       coinRate = _coinRate;
    }
    
    function setOnlyStrongHolder(uint256 _onlyStrongHolder) public onlyOwner {
        onlyStrongHolder = _onlyStrongHolder;
    }
    
    
    function setEraInterval(uint256 _eraInterval) public onlyOwner {
        eraInterval = _eraInterval;
    }
    
//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------

    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    
    bool public closed;
    
    uint public presaleSupply = 400000 * (10**decimals);
    uint public bonusPurchase = 200000 * (10**decimals);
    uint public startDate;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() public payable {
        require((now >= startDate && now.sub(startDate) <= 120 days));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        if(purchasedAmount > presaleSupply) revert();
        
        uint purchasedAmount; {
        
        if (now.sub(startDate) <= 15 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                purchasedAmount = msg.value * 100;
            }
        }
        
        uint bonusAmount; {
            
            if (now.sub(startDate) <= 15 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                bonusAmount = purchasedAmount.div(4);
            }
        }
        
        owner.transfer(msg.value);
        
        totalSupply = totalInitialSupply.add(purchasedAmount + bonusAmount);
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount + bonusAmount);
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function setPresaleSupply(uint256 value) public onlyOwner {
        presaleSupply = presaleSupply.add(value);
    }
    
    function setBonusPurchase(uint256 value) public onlyOwner {
        bonusPurchase = bonusPurchase.add(value);
    }
}