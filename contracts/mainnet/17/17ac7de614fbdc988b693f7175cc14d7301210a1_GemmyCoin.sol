pragma solidity ^0.4.24;
// Made By Yoondae - ydwinha@gmail.com - https://blog.naver.com/ydwinha

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;  
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}


contract OwnerHelper
{
    address public owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    constructor() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }

}

contract ERC20Interface
{
    event Transfer( address indexed _from, address indexed _to, uint _value);
    event Approval( address indexed _owner, address indexed _spender, uint _value);
    
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
    function transfer( address _to, uint _value) public returns (bool _success);
    function approve( address _spender, uint _value ) public returns (bool _success);
    function allowance( address _owner, address _spender ) public view returns (uint _allowance);
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success);
}

contract GemmyCoin is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    address public wallet;

    uint public totalSupply;
    
    uint constant public saleSupply         =  3500000000 * E18;
    uint constant public rewardPoolSupply   =  2200000000 * E18;
    uint constant public foundationSupply   =   500000000 * E18;
    uint constant public gemmyMusicSupply   =  1200000000 * E18;
    uint constant public advisorSupply      =   700000000 * E18;
    uint constant public mktSupply          =  1600000000 * E18;
    uint constant public etcSupply          =   300000000 * E18;
    uint constant public maxSupply          = 10000000000 * E18;
    
    uint public coinIssuedSale = 0;
    uint public coinIssuedRewardPool = 0;
    uint public coinIssuedFoundation = 0;
    uint public coinIssuedGemmyMusic = 0;
    uint public coinIssuedAdvisor = 0;
    uint public coinIssuedMkt = 0;
    uint public coinIssuedEtc = 0;
    uint public coinIssuedTotal = 0;
    uint public coinIssuedBurn = 0;
    
    uint public saleEtherReceived = 0;

    uint constant private E18 = 1000000000000000000;
    
    uint public firstPreSaleDate1 = 1529247600;        // 2018-06-18 00:00:00 
    uint public firstPreSaleEndDate1 = 1530198000;     // 2018-06-29 00:00:00 
    
    uint public firstPreSaleDate2 = 1530457200;       // 2018-07-02 00:00:00 
    uint public firstPreSaleEndDate2 = 1532617200;    // 2018-07-27 00:00:00 
    
    uint public secondPreSaleDate = 1532876400;      // 2018-07-30 00:00:00 
    uint public secondPreSaleEndDate = 1534431600;   // 2018-08-17 00:00:00 
    
    uint public thirdPreSaleDate = 1534690800;     // 2018-08-20 00:00:00 
    uint public thirdPreSaleEndDate = 1536246000;  // 2018-09-07 00:00:00 

    uint public mainSaleDate = 1536505200;    // 2018-09-10 00:00:00 
    uint public mainSaleEndDate = 1540911600; // 2018-10-31 00:00:00 
    
    bool public totalCoinLock;
    uint public gemmyMusicLockTime;
    
    uint public advisorFirstLockTime;
    uint public advisorSecondLockTime;
    
    mapping (address => uint) internal balances;
    mapping (address => mapping ( address => uint )) internal approvals;

    mapping (address => bool) internal personalLocks;
    mapping (address => bool) internal gemmyMusicLocks;
    
    mapping (address => uint) internal advisorFirstLockBalances;
    mapping (address => uint) internal advisorSecondLockBalances;
    
    mapping (address => uint) internal  icoEtherContributeds;
    
    event CoinIssuedSale(address indexed _who, uint _coins, uint _balances, uint _ether, uint _saleTime);
    event RemoveTotalCoinLock();
    event SetAdvisorLockTime(uint _first, uint _second);
    event RemovePersonalLock(address _who);
    event RemoveGemmyMusicLock(address _who);
    event RemoveAdvisorFirstLock(address _who);
    event RemoveAdvisorSecondLock(address _who);
    event WithdrawRewardPool(address _who, uint _value);
    event WithdrawFoundation(address _who, uint _value);
    event WithdrawGemmyMusic(address _who, uint _value);
    event WithdrawAdvisor(address _who, uint _value);
    event WithdrawMkt(address _who, uint _value);
    event WithdrawEtc(address _who, uint _value);
    event ChangeWallet(address _who);
    event BurnCoin(uint _value);
    event RefundCoin(address _who, uint _value);

    constructor() public
    {
        name = "GemmyMusicCoin";
        decimals = 18;
        symbol = "GMC";
        totalSupply = 0;
        
        owner = msg.sender;
        wallet = msg.sender;
        
        require(maxSupply == saleSupply + rewardPoolSupply + foundationSupply + gemmyMusicSupply + advisorSupply + mktSupply + etcSupply);
        
        totalCoinLock = true;
        gemmyMusicLockTime = firstPreSaleDate1 + (365 * 24 * 60 * 60);
        advisorFirstLockTime = gemmyMusicLockTime;   // if tokenUnLock == timeChange
        advisorSecondLockTime = gemmyMusicLockTime;  // if tokenUnLock == timeChange
    }

    function atNow() public view returns (uint)
    {
        return now;
    }
    
    function () payable public
    {
        require(saleSupply > coinIssuedSale);
        buyCoin();
    }
    
    function buyCoin() private
    {
        uint ethPerCoin = 0;
        uint saleTime = 0; // 1 : firstPreSale1, 2 : firstPreSale2, 3 : secondPreSale, 4 : thirdPreSale, 5 : mainSale
        uint coinBonus = 0;
        
        uint minEth = 0.1 ether;
        uint maxEth = 100000 ether;
        
        uint nowTime = atNow();
        
        if( nowTime >= firstPreSaleDate1 && nowTime < firstPreSaleEndDate1 )
        {
            ethPerCoin = 50000;
            saleTime = 1;
            coinBonus = 20;
        }
        else if( nowTime >= firstPreSaleDate2 && nowTime < firstPreSaleEndDate2 )
        {
            ethPerCoin = 50000;
            saleTime = 2;
            coinBonus = 20;
        }
        else if( nowTime >= secondPreSaleDate && nowTime < secondPreSaleEndDate )
        {
            ethPerCoin = 26000;
            saleTime = 3;
            coinBonus = 15;
        }
        else if( nowTime >= thirdPreSaleDate && nowTime < thirdPreSaleEndDate )
        {
            ethPerCoin = 18000;
            saleTime = 4;
            coinBonus = 10;
        }
        else if( nowTime >= mainSaleDate && nowTime < mainSaleEndDate )
        {
            ethPerCoin = 12000;
            saleTime = 5;
            coinBonus = 0;
        }
        
        require(saleTime >= 1 && saleTime <= 5);
        require(msg.value >= minEth && icoEtherContributeds[msg.sender].add(msg.value) <= maxEth);

        uint coins = ethPerCoin.mul(msg.value);
        coins = coins.mul(100 + coinBonus) / 100;
        
        require(saleSupply >= coinIssuedSale.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedSale = coinIssuedSale.add(coins);
        saleEtherReceived = saleEtherReceived.add(msg.value);

        balances[msg.sender] = balances[msg.sender].add(coins);
        icoEtherContributeds[msg.sender] = icoEtherContributeds[msg.sender].add(msg.value);
        personalLocks[msg.sender] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit CoinIssuedSale(msg.sender, coins, balances[msg.sender], msg.value, saleTime);

        wallet.transfer(address(this).balance);
    }
    
    function isTransferLock(address _from, address _to) constant private returns (bool _success)
    {
        _success = false;

        if(totalCoinLock == true)
        {
            _success = true;
        }
        
        if(personalLocks[_from] == true || personalLocks[_to] == true)
        {
            _success = true;
        }
        
        if(gemmyMusicLocks[_from] == true || gemmyMusicLocks[_to] == true)
        {
            _success = true;
        }
        
        return _success;
    }
    
    function isPersonalLock(address _who) constant public returns (bool)
    {
        return personalLocks[_who];
    }
    
    function removeTotalCoinLock() onlyOwner public
    {
        require(totalCoinLock == true);
        
        uint nowTime = atNow();
        advisorFirstLockTime = nowTime + (2 * 30 * 24 * 60 * 60);
        advisorSecondLockTime = nowTime + (4 * 30 * 24 * 60 * 60);
    
        totalCoinLock = false;
        
        emit RemoveTotalCoinLock();
        emit SetAdvisorLockTime(advisorFirstLockTime, advisorSecondLockTime);
    }
    
    function removePersonalLock(address _who) onlyOwner public
    {
        require(personalLocks[_who] == true);
        
        personalLocks[_who] = false;
        
        emit RemovePersonalLock(_who);
    }
    
    function removePersonalLockMultiple(address[] _addresses) onlyOwner public
    {
        for(uint i = 0; i < _addresses.length; i++)
        {
        
            require(personalLocks[_addresses[i]] == true);
        
            personalLocks[_addresses[i]] = false;
        
            emit RemovePersonalLock(_addresses[i]);
        }
    }
    
    function removeGemmyMusicLock(address _who) onlyOwner public
    {
        require(atNow() > gemmyMusicLockTime);
        require(gemmyMusicLocks[_who] == true);
        
        gemmyMusicLocks[_who] = false;
        
        emit RemoveGemmyMusicLock(_who);
    }
    
    function removeFirstAdvisorLock(address _who) onlyOwner public
    {
        require(atNow() > advisorFirstLockTime);
        require(advisorFirstLockBalances[_who] > 0);
        
        balances[_who] = balances[_who].add(advisorFirstLockBalances[_who]);
        advisorFirstLockBalances[_who] = 0;
        
        emit RemoveAdvisorFirstLock(_who);
    }
    
    function removeSecondAdvisorLock(address _who) onlyOwner public
    {
        require(atNow() > advisorSecondLockTime);
        require(advisorSecondLockBalances[_who] > 0);
        
        balances[_who] = balances[_who].add(advisorSecondLockBalances[_who]);
        advisorSecondLockBalances[_who] = 0;
        
        emit RemoveAdvisorSecondLock(_who);
    }
    
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) public view returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(balances[msg.sender] >= _value);
        require(isTransferLock(msg.sender, _to) == false);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferMultiple(address[] _addresses, uint[] _values) onlyOwner public returns (bool) 
    {
        require(_addresses.length == _values.length);
        
        uint value = 0;
        
        for(uint i = 0; i < _addresses.length; i++)
        {
            value = _values[i] * E18;
            require(balances[msg.sender] >= value);
            require(isTransferLock(msg.sender, _addresses[i]) == false);
            
            balances[msg.sender] = balances[msg.sender].sub(value);
            balances[_addresses[i]] = balances[_addresses[i]].add(value);
            
            emit Transfer(msg.sender, _addresses[i], value);
        }
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(balances[msg.sender] >= _value);
        require(isTransferLock(msg.sender, _spender) == false);
        
        approvals[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint) 
    {
        return approvals[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) 
    {
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);
        require(isTransferLock(msg.sender, _to) == false);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function withdrawRewardPool(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(rewardPoolSupply >= coinIssuedRewardPool.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedRewardPool = coinIssuedRewardPool.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins);
        personalLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawRewardPool(_who, coins);
    }
    
    function withdrawFoundation(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(foundationSupply >= coinIssuedFoundation.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedFoundation = coinIssuedFoundation.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins);
        personalLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawFoundation(_who, coins);
    }
    
    function withdrawGemmyMusic(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(gemmyMusicSupply >= coinIssuedGemmyMusic.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedGemmyMusic = coinIssuedGemmyMusic.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins);
        gemmyMusicLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawGemmyMusic(_who, coins);
    }
    
    function withdrawAdvisor(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(advisorSupply >= coinIssuedAdvisor.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedAdvisor = coinIssuedAdvisor.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins * 20 / 100);
        advisorFirstLockBalances[_who] = advisorFirstLockBalances[_who].add(coins * 40 / 100);
        advisorSecondLockBalances[_who] = advisorSecondLockBalances[_who].add(coins * 40 / 100);
        personalLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawAdvisor(_who, coins);
    }
    
    function withdrawMkt(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(mktSupply >= coinIssuedMkt.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedMkt = coinIssuedMkt.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins);
        personalLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawMkt(_who, coins);
    }
    
    function withdrawEtc(address _who, uint _value) onlyOwner public
    {
        uint coins = _value * E18;
        
        require(etcSupply >= coinIssuedEtc.add(coins));

        totalSupply = totalSupply.add(coins);
        coinIssuedEtc = coinIssuedEtc.add(coins);
        coinIssuedTotal = coinIssuedTotal.add(coins);

        balances[_who] = balances[_who].add(coins);
        personalLocks[_who] = true;

        emit Transfer(0x0, msg.sender, coins);
        emit WithdrawEtc(_who, coins);
    }
    
    function burnCoin() onlyOwner public
    {
        require(atNow() > mainSaleEndDate);
        require(saleSupply - coinIssuedSale > 0);

        uint coins = saleSupply - coinIssuedSale;
        
        balances[0x0] = balances[0x0].add(coins);
        coinIssuedSale = coinIssuedSale.add(coins);
        coinIssuedBurn = coinIssuedBurn.add(coins);

        emit BurnCoin(coins);
    }
    
    function changeWallet(address _who) onlyOwner public
    {
        require(_who != address(0x0));
        require(_who != wallet);
        
        wallet = _who;
        
        emit ChangeWallet(_who);
    }
    
    function refundCoin(address _who) onlyOwner public
    {
        require(totalCoinLock == true);
        
        uint coins = balances[_who];
        
        balances[_who] = balances[_who].sub(coins);
        balances[wallet] = balances[wallet].add(coins);

        emit RefundCoin(_who, coins);
    }
}