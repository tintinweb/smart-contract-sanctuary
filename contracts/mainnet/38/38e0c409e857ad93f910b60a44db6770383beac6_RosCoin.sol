pragma solidity >= 0.4.24 < 0.6.0;


/**
 * @title ROS Coin
 */

/**
 * @title ERC20 Standard Interface
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title RosCoin implementation
 */
contract RosCoin is IERC20 {
    string public name = "Ros Coin";
    string public symbol = "ROS";
    uint8 public decimals = 18;
    
    uint256 pvsaleAmount;
    uint256 salesAmount;
    uint256 rewardAmount;
    uint256 companyAmount;
    uint256 rndAmount;
    
    uint256[] allowance;
    

    uint256 _totalSupply;
    mapping(address => uint256) balances;

    // Addresses
    address public owner;
    address public pvsale;
    address public sales;
    address public reward;
    address public company;
    address public rnd;
    
    address public marker;
    address public locker;
    
    IERC20 private _locker;
    IERC20 private _marker;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner = msg.sender;

        pvsale  = 0xbf98f2BA89cC717459EB666538f4e9Ba6f8d134D;
        sales   = 0xC97F0A011A2dbf5c9E32d0C25A9ee8d9A1F368E4;
        reward  = 0x58755Aac033CA336bE9F40B4d609DBA2339c1bCb;
        company = 0x97697db45109138b06eFF5D5AF857bDfb11c95A6;
        rnd     = 0x1f7b494E6aE6a3D9FBFfc4da76F7B7fBF6aa24d5;
        
        marker  = 0xE3791E6fCFFDFBfEE077e44F6DbD77881c2759F4;
        locker  = 0x628162AFe4E62418bDD36c35Beb2E1710a2E6212;

        pvsaleAmount   = toWei( 300000000);
        salesAmount    = toWei( 100000000);
        rewardAmount   = toWei( 150000000);
        companyAmount  = toWei( 250000000);
        rndAmount      = toWei( 200000000);
        _totalSupply   = toWei(1000000000);  //1,000,000,000
        
        _locker = IERC20(locker);
        _marker = IERC20(marker);

        require(_totalSupply == pvsaleAmount + salesAmount + rewardAmount + companyAmount + rndAmount );
        
        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, balances[owner]);
        
        transfer(pvsale, pvsaleAmount);
        transfer(sales, salesAmount);
        transfer(reward, rewardAmount);
        transfer(company, companyAmount);
        transfer(rnd, rndAmount);

        require(balances[owner] == 0);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(msg.sender != to);
        require(to != owner);
        require(value > 0);

        uint256 lockerBalance = _locker.balanceOf(msg.sender);
        uint256 markerBalance = _marker.balanceOf(msg.sender);

        if (lockerBalance > 0) {
            require(now > 1607558400);
        }

        if (markerBalance > 0) {
            require(balances[msg.sender] >= markerBalance + value);
        }

        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );    // prevent overflow



        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burnCoins(uint256 value) public {
        require(balances[msg.sender] >= value);
        require(_totalSupply >= value);
        
        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }

    function toWei(uint256 value) private view returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}