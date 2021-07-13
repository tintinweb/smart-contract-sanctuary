/**
 *Submitted for verification at Etherscan.io on 2021-07-13
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

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external view returns (address);
}

contract RegisterManager {
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public WETH = uniV2Router02.WETH();
    address public distributionToken;
    address public WHLClubAddress;
    address[] path;
    
    uint public roomFee = 0.01 ether;
    uint public systemFee = 0.05 ether;
    
    address public admin;

    address payable public donationAddress;
    
    mapping(address => bool) public isSystemRegistered;
    mapping(uint => mapping(address => bool)) private _isRoomRegistered;

    
    event SystemRegistered(address registrant);
    event SystemUnregistered(address registrant);
    event RoomRegistered(address registrant, uint room_id);
    event RoomUnregistered(address registrant, uint room_id);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _distributionToken, address _whlclubAddress, address payable _donationAddress) {
        require(_distributionToken != address(0), "Invalid address");
        require(_whlclubAddress != address(0), "Invalid address");
        
        distributionToken = _distributionToken;
        path.push(WETH);
        path.push(_distributionToken);
        
        admin = msg.sender;
        
        WHLClubAddress = _whlclubAddress;
        donationAddress = _donationAddress;
    }
    
    function setDistributionToken(address _token) external onlyAdmin {
        require(_token != address(0), "Invalid address");
        
        distributionToken = _token;
    }
    
    function autoSwapAndDistritue(uint _estimatedAmount) private {
        uint _ethBalance = address(this).balance;
        uint _returnBalance;
        if (_ethBalance >= 2 ether) {
            _returnBalance = uniV2Router02.swapExactETHForTokens{value:1 ether}(_estimatedAmount, path, address(this), type(uint256).max)[1];
            IERC20(distributionToken).transfer(address(0x000000000000000000000000000000000000dEaD), _returnBalance);
        }
    }
    
    function systemRegister(uint _estimatedAmount) external payable {
        require(msg.value == systemFee, "Wrong ETH value!");
        require(!isSystemRegistered[msg.sender], "Already Registered!");
        
        uint256 _amount = msg.value;
        uint256 _donationAmount = _amount / 10;
        
        if (!donationAddress.send(_donationAmount)) {
            donationAddress.transfer(_donationAmount);
        }
        
        autoSwapAndDistritue(_estimatedAmount);
        
        isSystemRegistered[msg.sender] = true;
        emit SystemRegistered(msg.sender);
    }

    function roomRegister(uint roomId, uint _estimatedAmount) external payable {
        require(msg.value == roomFee, "Wrong ETH value!");
        require(!_isRoomRegistered[roomId][msg.sender], "Already Registered!");
        
        uint256 _amount = msg.value;
        uint256 _donationAmount = _amount / 10;
        
        if (!donationAddress.send(_donationAmount)) {
            donationAddress.transfer(_donationAmount);
        }
        
        autoSwapAndDistritue(_estimatedAmount);
        
        _isRoomRegistered[roomId][msg.sender] = true;
        emit RoomRegistered(msg.sender, roomId);
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
    
    function setDonationAddress(address payable _donationAddress) external onlyAdmin {
        require(_donationAddress != address(0), "Invalid address");
        
        donationAddress = _donationAddress;
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
}