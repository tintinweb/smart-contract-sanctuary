/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity ^0.5.0;


contract owned {
    address public owner;
    address public auditor;

    constructor() public {
        owner = msg.sender;
        auditor = 0x241A280362b4ED2CE8627314FeFa75247fDC286B;
    }

    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == auditor);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract cashier is owned {
    
    string public name;
    bool public online = true;
    address public bucks;
    address public blcks;
    uint256 public period;
    address public mainWallet = msg.sender;
    uint256 public APY = 14;

    struct deposits{
        uint256 amount;
        bool payed;
        uint256 date;
    }

    mapping (address => deposits[]) public investments;

    event SwapToUSDT(address indexed beneficiary, uint256 value);
    
    event SwapToBLACKT(address indexed beneficiary, uint256 value);
 
    event IsOnline(bool status);

    
    constructor(
        string memory Name,
        address initialBucks,
        address initialBlcks,
        uint256 initialPeriod
    ) public {           
        name = Name;                                   
        bucks = initialBucks;
        blcks = initialBlcks;
        period = initialPeriod;
    }

    
    function USDtoBLACKT( uint256 value) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        require(online);
        uint256 d0 = 10**uint256(b0.decimals());
        uint256 d1 = 10**uint256(b1.decimals());
        uint256 vald = value*d0/d1;
        require(b1.allowance(msg.sender,address(this)) >= value);
        require(b0.allowance(mainWallet,address(this)) >= vald);
        b1.transferFrom(msg.sender,mainWallet,value);
        b0.transferFrom(mainWallet,msg.sender,vald);
        emit SwapToBLACKT(msg.sender,value);
        return true;
    }

    function BLACKTtoUSD(uint256 value) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        require(online);
        uint256 d0 = 10**uint256(b0.decimals());
        uint256 d1 = 10**uint256(b1.decimals());
        uint256 vald = value*d1/d0;
        require(b0.allowance(msg.sender,address(this)) >= value);
        require(b1.allowance(mainWallet,address(this)) >= vald);
        b0.transferFrom(msg.sender,mainWallet,value);
        b1.transferFrom(mainWallet,msg.sender,vald);
        emit SwapToUSDT(msg.sender,value);
        
        return true;
    }

    function AutoInvestUSD(uint256 investment) public returns (bool success) {
        BLACKT b0 = BLACKT(blcks);
        IERC20 b1 = IERC20(bucks);
        uint256 d0 = 10**uint256(b0.decimals());
        uint256 d1 = 10**uint256(b1.decimals());
        uint256 vald = investment*d0/d1;
        require(online);
        require(b1.allowance(msg.sender,address(this)) >= investment);
        require(b0.allowance(mainWallet,address(this)) >= vald);
        b1.transferFrom(msg.sender,mainWallet,investment);
        b0.lockLiquidity(msg.sender, vald);   
        investments[msg.sender].push(deposits(vald,false,now));
        return true;
    }

    function AutoUnlock() public returns (bool success) {
        require(online);
        BLACKT b = BLACKT(blcks);
        for (uint256 j=0; j < investments[msg.sender].length; j++){
            if (now-investments[msg.sender][j].date>period && !investments[msg.sender][j].payed) {
                if (b.unlockLiquidity(msg.sender, investments[msg.sender][j].amount)) {
                    b.transferFrom(mainWallet,msg.sender,investments[msg.sender][j].amount*APY/100);
                    investments[msg.sender][j].payed = true;
                }
            }
        }
        return true;
    }

    function zChangeAPY(uint256 newAPY) onlyOwner public returns (bool success) {
        APY = newAPY;
        return true;
    }

    function zChangePeriod(uint256 newPeriod) onlyOwner public returns (bool success) {
        period = newPeriod;
        return true;
    }

    function zChangeBucks(address newBucks) onlyOwner public returns (bool success) {
        bucks = newBucks;
        return true;
    }

    function zChangeBlcks(address newBlcks) onlyOwner public returns (bool success) {
        blcks = newBlcks;
        return true;
    }

    function zChangeOnlineState(bool state) onlyOwner public returns (bool success) {
        online = state;
        return true;
    }

    function zChangeMainWallet(address newWallet) onlyOwner public returns (bool success) {
        mainWallet = newWallet;
        return true;
    }
}

interface BLACKT {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function lockedBalance(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function lockLiquidity(address _beneficiary, uint256 _value) external returns (bool);
    function unlockLiquidity(address _beneficiary, uint _value) external returns (bool);
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external returns (bool);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external returns (bool);
}