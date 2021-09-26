/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Only owner');
        _;
    }
}

contract AirDrop is Ownable {
    address public factory;
    address public token;

    uint public quantity;
    uint public balance;
    uint public tranche;
    uint public counter;

    mapping(address => uint) public pickers;
    
    constructor(address factory_, address owner_, address token_, uint quantity_, uint tranche_)  {
        require(tranche_ < quantity_, 'LIQS AirDrop: Tranche cannot be smaller thas quantity');
        factory = factory_;
        owner = owner_;
        token = token_;
        quantity = quantity_;
        tranche = tranche_;
    }

    function deposit() external onlyOwner {
        require(balance == 0, 'LIQS AirDrop: Deposit arleady has been made');
        balance = quantity;
        IERC20(token).transferFrom(msg.sender, address(this), quantity);
    }

    function pick() external {
        require(pickers[msg.sender] != 1, 'LIQS AirDrop: Sender arleady picked');
        require(balance % tranche == 0 , 'LIQS AirDrop: Balance modulo tranche must be 0');
        require(tranche < balance, 'LIQS AirDrop: Insuficient contract balance');
        pickers[msg.sender] = 1;
        counter += 1;
        balance -= tranche;
        IERC20(token).transfer(msg.sender, tranche);
    }
}

contract AirDropFactory {
    uint public airDropsLength = 0;
    mapping(address => address) public getAirDrop;
    address[] public allAirDrops;
    mapping(address => address[]) public userAirDrops;

    function addAirDrop(address owner, address token, uint quantity, uint tranche) external {
        AirDrop airDrop = new AirDrop(address(this), owner, token, quantity, tranche);
        address airDropAddress = address(airDrop);
        userAirDrops[msg.sender].push(airDropAddress);
        allAirDrops[airDropsLength] = airDropAddress;
        getAirDrop[token] = airDropAddress;
        airDropsLength += 1;
    }
}


contract Router is Ownable {
    uint public balance;
    
    uint public refferalTax;
    mapping(address => uint) private _refferalBalances;
    
    AirDropFactory public airDropFactory;
    uint airDropPrice = 1;

    modifier costs(uint price) {
        require(msg.value >= price, 'Wrong price');
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        airDropFactory = new AirDropFactory();

        refferalTax = 25; //do usuniecia
        airDropPrice = 1; // do usunieca
    }
    
    function _collectPayment(uint value, address refferal) private {
        _refferalBalances[refferal] += value * refferalTax / 100;
        balance += value * (100 - refferalTax) / 100;
    }
    
    function addAirDrop(address token, uint quantity, uint tranche, address refferal) external payable costs(airDropPrice) {
        _collectPayment(msg.value, refferal);
        airDropFactory.addAirDrop(msg.sender, token, quantity, tranche);
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(balance);
        balance = 0;
    }
    
    function refferalWithdraw() external {
        require(_refferalBalances[msg.sender] > 0, 'No funds');
        payable(msg.sender).transfer(_refferalBalances[msg.sender]);
        _refferalBalances[msg.sender] = 0;
    }
    
    function setRefferalTax(uint newTax) external {
        require(newTax >= 0 && newTax <= 100, 'Invalid value');
        refferalTax = newTax;
    }
    
    function setAirCropPrice(uint newPrice) external {
        airDropPrice = newPrice;
    }
    
    function refferalBalance(address refferal) external view returns(uint) {
        return _refferalBalances[refferal];
    }
}