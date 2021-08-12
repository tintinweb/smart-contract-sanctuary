/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

//SPDX-License-Identifier: Diemlibre Ware

/** 
 * This code/file/software is owned by Diemlibre and Diemlibre only.
 * All rights belong to Diemlibre.
 * Only Diemlibre authorizes the use of this code.
 * 
**/

pragma solidity 0.8.4;

/**
 * ERC Interface for Diemlibre Token.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DiemlibreFaucet {
    
    struct State {
        bool isInit;
        address self;
        address owner;
        address holder;
        uint256 faucetAmount; // In smallest unit WEI
        uint256 maxPageBuffer;
    }
    
    IERC20 DLB;
    address[] savedAddresses;
    mapping(address => bool) sentAddresses;
    State currentState;
    
    constructor(address _tokenAddress, address _holderAddress) {
        require(_tokenAddress != address(0), "Error! Invalid Token Address.");
        require(_holderAddress != address(0), "Error! Invalid Holder Address.");
        require(_tokenAddress != _holderAddress, "Token Address and Spender Address cann't be the same.");
        
        currentState = State({
            isInit: false,
            self: address(0),
            owner: msg.sender,
            holder: _holderAddress,
            faucetAmount: 2000000000000000000000,
            maxPageBuffer: 1000
        });
        
        DLB = IERC20(_tokenAddress);
    }
    
    function _withdrawETHToOwner(uint256 _amount) private returns(bool) {
         payable(currentState.owner).transfer(_amount);
         
         return true;
    }
    
    function getCurrentState() external view returns(State memory) {
        
        return currentState;
    }
    
    /**
     * Method: faucet
     * Des: To send a speicific amout of $DLB to addresses and you pay for gas.
     **/
    function diemlibreFaucet(address _faucetAddress) external returns(bool) {
        require(sentAddresses[_faucetAddress] == false, "Error 501: Address has already been fauced with DLB.");
        require(currentState.isInit, "Error 500: Contract Not Initialized or Contract Turned Off.");
        
        uint256 tokenAllowance = DLB.allowance(currentState.holder, currentState.self);
        
        require(currentState.faucetAmount > 0 && currentState.faucetAmount <= tokenAllowance, "Error 502: Insufficient Liquidity");
        require(DLB.transferFrom(currentState.holder, _faucetAddress, currentState.faucetAmount), "Error 503: Oops... Could not complete Transaction. Please try again later.");
        sentAddresses[_faucetAddress] = true;
        savedAddresses.push(_faucetAddress);
        return true;
    }
    
        
    // Owner Functions
    
    function init(address _selfAddress) external returns(bool) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        
        currentState.self = _selfAddress;
        currentState.isInit = true;
        return true;
    }
    
    function power(bool _state) external returns(State memory) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        
        currentState.isInit = _state;
        return currentState;
    }
    
    function getSavedAddressesLength() external view returns(uint256) {
         require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
         
         return savedAddresses.length;
    }
    
    function getSavedAddresses(uint256 _page) external view returns(address[] memory) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        require(_page >= 1, "Error 400: Invalid Page Number.");
        
        uint256 i;
        uint256 j = 0;
        address[] memory res;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 tempUpperLimit = _page * currentState.maxPageBuffer;
        
        if(savedAddresses.length < tempUpperLimit) {
            if(savedAddresses.length < currentState.maxPageBuffer) lowerLimit = 0;
            else lowerLimit = (_page - 1) * currentState.maxPageBuffer;
            
            upperLimit = savedAddresses.length;
            
            // If an unvailable page is requested lowerLimit will be greater than upperLimit
            if(lowerLimit > upperLimit) return res;
            
            // If lowerLimit == 0, then you should requesting for only page 1
            if(lowerLimit == 0 && _page > 1) return res;
        } else {
            lowerLimit = (_page - 1) * currentState.maxPageBuffer;
            upperLimit = tempUpperLimit;
        }
        
        uint256 resLength = upperLimit - lowerLimit;
        res = new address[](resLength);

        for(i = lowerLimit; i < upperLimit; i++) {
            res[j] = savedAddresses[i];
            j++;
        }
        
        return res;
    }
    
    function setHolderAddress(address _newHolder) external returns(State memory) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        
        currentState.holder = _newHolder;
        return currentState;
    }
    
    function setFaucetAmount(uint256 _faucetAmount) external returns(State memory) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        
        currentState.faucetAmount = _faucetAmount;
        return currentState;
    }
    
    function setMaxPageBuffer(uint256 _maxPageBuffer) external returns(State memory) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        
        currentState.maxPageBuffer = _maxPageBuffer;
        return currentState;
    }
    
    function withdrawETHToOwner(uint256 _amount) external returns(bool) {
        require(msg.sender == currentState.owner, "Error 401: Unauthorized Access.");
        require(_amount > 0, "Error 400: Invalid Amount! Amount must be greater than 0.");
        
        return _withdrawETHToOwner(_amount);
    }
}