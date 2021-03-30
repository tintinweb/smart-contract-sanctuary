/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract RegisterManager {

    uint public roomFee = 0.01 ether;
    uint public systemFee = 0.05 ether;
    
    uint public daiPrimeFee = 50000 * 10 ** 18;
    uint public daiApexFee = 250000 * 10 ** 18;
    
    uint public totalDaiBalance;
    address public admin;
    IERC20 public token0;
    
    mapping(address => bool) public isSystemRegistered;
    mapping(uint => mapping(address => bool)) private _isRoomRegistered;

    mapping(address => bool) public isPrimeRegistered;
    mapping(address => bool) public isApexRegistered;
    
    event SystemRegistered(address registrant);
    event SystemUnregistered(address registrant);
    event RoomRegistered(address registrant, uint room_id);
    event RoomUnregistered(address registrant, uint room_id);
    event SystemPrimeRegistered(address registrant, uint amount);
    event SystemApexRegistered(address registrant, uint amount);
    event SystemApexUpdated(address registrant, uint amount);
    event SystemPrimeUnregistered(address registrant);
    event SystemApexUnregistered(address registrant);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Invalid address");
        
        token0 = IERC20(_token);
        admin = msg.sender;
    }

    function setToken0(address _token) external onlyAdmin {
        require(_token != address(0), "Invalid address");
        
        token0 = IERC20(_token);
    }
    
    function systemRegister() external payable {
        require(msg.value == systemFee, "Wrong ETH value!");
        require(!isSystemRegistered[msg.sender], "Already Registered!");
        isSystemRegistered[msg.sender] = true;
        emit SystemRegistered(msg.sender);
    }

    function roomRegister(uint roomId) external payable {
        require(msg.value == roomFee, "Wrong ETH value!");
        require(!_isRoomRegistered[roomId][msg.sender], "Already Registered!");
        _isRoomRegistered[roomId][msg.sender] = true;
        emit RoomRegistered(msg.sender, roomId);
    }

    function systemPrimeRegister() external {
        require(!isPrimeRegistered[msg.sender], "Already Registered!");
        require(token0.balanceOf(msg.sender) >= daiPrimeFee, "dai is not enough!");
        require(token0.allowance(msg.sender, address(this)) >= daiPrimeFee, "dai is not approved!");
        
        token0.transferFrom(msg.sender, address(this), daiPrimeFee);
        totalDaiBalance = totalDaiBalance + daiPrimeFee;
        
        isPrimeRegistered[msg.sender] = true;
        emit SystemPrimeRegistered(msg.sender, daiPrimeFee);
    }
    
    function systemApexRegister() external {
        require(!isApexRegistered[msg.sender], "Already Registered!");
        
        uint limitAmount = isPrimeRegistered[msg.sender] ? daiApexFee - daiPrimeFee : daiApexFee;
        
        require(token0.balanceOf(msg.sender) >= limitAmount, "dai is not enough!");
        require(token0.allowance(msg.sender, address(this)) >= limitAmount, "dai is not approved!");
        
        token0.transferFrom(msg.sender, address(this), limitAmount);
        totalDaiBalance = totalDaiBalance + limitAmount;
        
        if (!isPrimeRegistered[msg.sender]) {
            isPrimeRegistered[msg.sender] = true;
            isApexRegistered[msg.sender] = true;
            emit SystemApexRegistered(msg.sender, limitAmount);
        } else {
            isApexRegistered[msg.sender] = true;
            emit SystemApexUpdated(msg.sender, limitAmount);
        }
            
    }
    
    function isRoomRegistered(uint roomId, address registrant) external view returns(bool) {
        return _isRoomRegistered[roomId][registrant];
    }

    function setSystemFee(uint _systemFee) external onlyAdmin {
        systemFee = _systemFee;
    }

    function setRoomFee(uint _roomFee) external onlyAdmin {
        roomFee = _roomFee;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        
        admin = _newAdmin;
    }

    function setPrimeFee(uint _primeFee) external onlyAdmin {
        daiPrimeFee = _primeFee;
    }
    
    function setApexFee(uint _apexFee) external onlyAdmin {
        daiApexFee = _apexFee;
    }
    
    function roomUnregister(uint roomId, address registrant) external onlyAdmin {
        // require(!isSystemRegistered[registrant], "Unexist registrant!");
        require(_isRoomRegistered[roomId][registrant], "Unexist registrant in the room!");
        _isRoomRegistered[roomId][registrant] = false;
        emit RoomUnregistered(registrant, roomId);
    }

    function systemUnregister(address registrant) external onlyAdmin {
        require(isSystemRegistered[registrant], "Unexist registrant!");
        isSystemRegistered[registrant] = false;
        emit SystemUnregistered(registrant);
    }

    function systemPrimeUnregister(address registrant) external onlyAdmin {
        require(isPrimeRegistered[registrant], "Unexist registrant!");
        isPrimeRegistered[registrant] = false;
        emit SystemPrimeUnregistered(registrant);
    }
    
    function systemApexUnregister(address registrant) external onlyAdmin {
        require(isApexRegistered[registrant], "Unexist registrant!");
        isApexRegistered[registrant] = false;
        emit SystemApexUnregistered(registrant);
    }
    
    function withdraw() external onlyAdmin {
        uint _balance = address(this).balance;
        require(_balance > 0, "Insufficient balance");
        if (!payable(msg.sender).send(_balance)) {
            payable(msg.sender).transfer(_balance);
        }
    }
    
    function withdrawToken() external onlyAdmin {
        uint _tokenBalance = token0.balanceOf(address(this));
        require(_tokenBalance > 0, "Insufficient balance");
        token0.transfer(msg.sender, _tokenBalance);
        totalDaiBalance = 0;
    }
}