/**
 *Submitted for verification at Etherscan.io on 2021-04-05
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

interface IWHLClub {
    function distribute(uint256 _amount) external;
}

contract RegisterManager {
    IUniswapV2Router02 constant uniV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public WETH = uniV2Router02.WETH();
    address public distributionToken;
    address public WHLClubAddress;
    address[] path;
    
    uint public roomFee = 0.01 ether;
    uint public systemFee = 0.05 ether;
    
    uint public daiPrimeFee = 50000 * 10 ** 18;
    uint public daiApexFee = 250000 * 10 ** 18;
    
    uint public totalDaiBalance;
    address public admin;
    IERC20 public token0;
    
    address public daiPrimeFeeAddress;
    address public daiApexFeeAddress;
    
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

    constructor(address _daiToken, address _distributionToken, address _whlclubAddress, address _daiPrimeFeeAddress, address _daiApexFeeAddress) {
        require(_distributionToken != address(0), "Invalid address");
        require(_daiToken != address(0), "Invalid address");
        require(_whlclubAddress != address(0), "Invalid address");
        require(_daiPrimeFeeAddress != address(0), "Invalid address");
        require(_daiApexFeeAddress != address(0), "Invalid address");
        
        distributionToken = _distributionToken;
        path.push(WETH);
        path.push(_distributionToken);
        
        token0 = IERC20(_daiToken);
        admin = msg.sender;
        
        WHLClubAddress = _whlclubAddress;
        daiPrimeFeeAddress = _daiPrimeFeeAddress;
        daiApexFeeAddress = _daiApexFeeAddress;
    }

    function setToken0(address _token) external onlyAdmin {
        require(_token != address(0), "Invalid address");
        
        token0 = IERC20(_token);
    }
    
    function setDistributionToken(address _token) external onlyAdmin {
        require(_token != address(0), "Invalid address");
        
        distributionToken = _token;
    }
    
    function autoSwapAndDistritue(uint _estimatedAmount) private {
        uint _ethBalance = address(this).balance;
        uint _returnBalance;
        if (_ethBalance >= 10 ether) {
            _returnBalance = uniV2Router02.swapExactETHForTokens{value:9 ether}(_estimatedAmount, path, address(this), type(uint256).max)[1];
        }
        IERC20(distributionToken).approve(WHLClubAddress, _returnBalance);
        IWHLClub(WHLClubAddress).distribute(_returnBalance);
    }
    
    function systemRegister(uint _estimatedAmount) external payable {
        require(msg.value == systemFee, "Wrong ETH value!");
        require(!isSystemRegistered[msg.sender], "Already Registered!");
        
        autoSwapAndDistritue(_estimatedAmount);
        
        isSystemRegistered[msg.sender] = true;
        emit SystemRegistered(msg.sender);
    }

    function roomRegister(uint roomId, uint _estimatedAmount) external payable {
        require(msg.value == roomFee, "Wrong ETH value!");
        require(!_isRoomRegistered[roomId][msg.sender], "Already Registered!");
        
        autoSwapAndDistritue(_estimatedAmount);
        
        _isRoomRegistered[roomId][msg.sender] = true;
        emit RoomRegistered(msg.sender, roomId);
    }

    function systemPrimeRegister() external {
        require(!isPrimeRegistered[msg.sender], "Already Registered!");
        require(token0.balanceOf(msg.sender) >= daiPrimeFee, "dai is not enough!");
        require(token0.allowance(msg.sender, address(this)) >= daiPrimeFee, "dai is not approved!");

        token0.transferFrom(msg.sender, daiPrimeFeeAddress, daiPrimeFee);
        totalDaiBalance = totalDaiBalance + daiPrimeFee;
        
        isPrimeRegistered[msg.sender] = true;
        emit SystemPrimeRegistered(msg.sender, daiPrimeFee);
    }
    
    function systemApexRegister() external {
        require(!isApexRegistered[msg.sender], "Already Registered!");
        
        uint limitAmount = isPrimeRegistered[msg.sender] ? daiApexFee - daiPrimeFee : daiApexFee;
        
        require(token0.balanceOf(msg.sender) >= limitAmount, "dai is not enough!");
        require(token0.allowance(msg.sender, address(this)) >= limitAmount, "dai is not approved!");

        token0.transferFrom(msg.sender, daiApexFeeAddress, limitAmount);
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

    function setDaiPrimeFeeAddress(address _daiPrimeFeeAddress) external onlyAdmin {
        require(_daiPrimeFeeAddress != address(0), "Invalid address");
        
        daiPrimeFeeAddress = _daiPrimeFeeAddress;
    }
    
    function setDaiApexFeeAddress(address _daiApexFeeAddress) external onlyAdmin {
        require(_daiApexFeeAddress != address(0), "Invalid address");
        
        daiApexFeeAddress = _daiApexFeeAddress;
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
}