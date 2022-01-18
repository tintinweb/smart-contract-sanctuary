// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEscrow {
    enum FundingState {
        PAUSED,
        ACTIVE,
        REFUND
    }

    //Events definitions
    event USDCDeposited(address indexed payee, uint256 indexed amount);
    event USDCWithdrawn(address indexed payee, uint256 indexed amount);
    event Deposited(address indexed payee, uint256 indexed weiAmount);
    event Withdrawn(address indexed payee, uint256 indexed weiAmount);
    event RemovedReservation(address indexed user, uint256 indexed id);

    event UnitPriceChanged(uint256 indexed newPriceETH, uint256 indexed newPriceUSDT);
    event TotalUnitsAvailableChanged(uint256 indexed newAmount);
    event FundingSateChanged(uint8 indexed newState);

    //Functions restricted in access by the Owner
    function setState(FundingState _state) external;    // Set contract state
    function setETHPrice(uint256 amount) external;     // Set ETH price in wei
    function setUSDCPrice(uint256 amount) external;    // Set USDC price with 6 decimals
    function changeRecipient(address newRecipient) external;    // Change recipient address
    function transferOwnership(address newOwner) external;    // Change owner of the contract
    function reset(uint256 ethPrice, uint256 usdcPrice) external;    // Expand total supply and prices

    //Functions restricted in access by the recipient
    function withdrawETH(address payable receiver, uint256 amount) external;    // Withdraw amount of ETH in wei from the contract
    function withdrawUSDC(address receiver, uint256 amount) external;    // Withdraw amount of USDC with 6 decimals from the contract
    function withdrawAll(address payable receiver) external;    // Withdraw everything from the contract

    // Public getters functions to retrieve data
    function totalValue() external view returns (uint256 usdcFunded, uint256 ethFunded); // USDC and ETH deposited in the contract
    function getMyReservedAssets() external view returns(uint256 value); // Number of reserved items of msg.sender

    // Functions called by the user
    function buyWithUSDC(uint256 amount) external; // Reserve an amount with USDC
    function buyWithEther(uint256 amount) external payable; // Reserve an amount with ETH
    function claimBackAllFunds() external; // Claim back everything
}

//Copied from OZ contracts
interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}

//Copied from OZ contracts
library SafeERC20 {
    
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call reverted");
        if (returnedData.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        require(isContract(address(token)), "Call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        bytes memory returnedData = verifyCallResult(success, returndata, "Call to non-contract");
        if (returnedData.length > 0) {
            require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
        }
    }
}

contract Escrow is IEscrow {
    using SafeERC20 for IERC20;
    
    address public recipient;
    address public owner;
    address public usdc;
    uint8 public state;

    //Fixed prices
    uint256 public usdcPrice; // With 6 decimals
    uint256 public ethPrice; // In wei

    //Total Supply and sold
    uint256 public totalSupply;
    uint256 public sold;
    
    //Number of items reserved by each user
    mapping(address => uint256) public userReservedAssets;
    
    //Track the USDC and ETH deposited by each users
    mapping(address => uint256) public ethDeposited;
    mapping(address => uint256) public usdcDeposited;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier onlyRecipient {
        require(msg.sender == recipient, "Caller is not recipient");
        _;
    }
    
    constructor(
        address _usdc, //USDC address to be used on the oracle
        address _recipient, //Who can withdraw funds from the contract
        uint256 _usdcPrice, //USDC price with 6 decimals, for example 100 USDC = 100000000
        uint256 _ethPrice, //ETH price in wei
        uint256 _totalSupply // Numbner of items to sell
    ) {
        usdc = _usdc;
        owner = msg.sender;
        recipient = _recipient;
        usdcPrice = _usdcPrice;
        ethPrice = _ethPrice;
        totalSupply = _totalSupply;
        state = uint8(FundingState.ACTIVE);
    }
    
    // Owner restricted functions
    // Set state either paused 0, active 1, refund 2
    function setState(FundingState _state) external override onlyOwner {
        state = uint8(_state);
        emit FundingSateChanged(state);
    }

    // Increase total supply and adjust prices
    function reset(uint256 _ethPrice, uint256 _usdcPrice) external override onlyOwner {
        totalSupply += 14500; //Increments from 14500 to 29000, from 29000 to 43500, to 58000
        require(totalSupply <= 58000, "Hitted limit");
        ethPrice = _ethPrice;
        usdcPrice = _usdcPrice;
        emit TotalUnitsAvailableChanged(totalSupply - sold);
        emit UnitPriceChanged(ethPrice, usdcPrice);
    }

    // Set ETH price in wei
    function setETHPrice(uint256 amount) external override onlyOwner {
        ethPrice = amount;
        emit UnitPriceChanged(ethPrice, usdcPrice);
    }

    // Set USDC price with 6 decimals
    function setUSDCPrice(uint256 amount) external override onlyOwner {
        usdcPrice = amount;
        emit UnitPriceChanged(ethPrice, usdcPrice);
    }

    // Change recipient address
    function changeRecipient(address newRecipient) external override onlyOwner {
        recipient = newRecipient;
    }
    
    // Transfer ownership of the contract
    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
    }

    // Withdraw amount of ETH in wei from the contract
    function withdrawETH(address payable receiver, uint256 amount) external override onlyRecipient {
        emit Withdrawn(receiver, amount);
        _sendValue(receiver, amount);
    }
    
    // Withdraw amount of USDC with 6 decimals from the contract
    function withdrawUSDC(address receiver, uint256 amount) external override onlyRecipient {
        emit USDCWithdrawn(receiver, amount);
        IERC20(usdc).safeTransfer(receiver, amount);
    }
    
    // Withdraw everything from the contract
    function withdrawAll(address payable receiver) external override onlyRecipient {
        emit Withdrawn(receiver, address(this).balance);
        emit USDCWithdrawn(receiver, IERC20(usdc).balanceOf(address(this)));
        _sendValue(receiver, address(this).balance);
        IERC20(usdc).safeTransfer(receiver, IERC20(usdc).balanceOf(address(this)));
    }
    
    // Public getters functions to retrieve data
    
    function totalValue() external override view returns (uint256 usdcFunded, uint256 ethFunded) {
        usdcFunded = IERC20(usdc).balanceOf((address(this)));
        ethFunded = address(this).balance;
        return (
            usdcFunded,
            ethFunded
        );
    }
    
    function getMyReservedAssets() external override view returns (uint256 value) {
        value = userReservedAssets[msg.sender];
        return value;
    }

    // User interacting functions

    function buyWithUSDC(uint256 amount) external override {
        _buyWithUSDC(amount);
    }

    function buyWithEther(uint256 amount) external override payable {
        _buyWithEther(amount);
    }
    
    function claimBackAllFunds() external override {
        require(state == uint8(FundingState.REFUND), "System state is not in refund");

        uint256 usdcUserBalance = usdcDeposited[msg.sender];
        uint256 ethUserBalance = ethDeposited[msg.sender];
        uint256 itemsReserved = userReservedAssets[msg.sender];

        require(itemsReserved > 0, "Users has no items reserved");             
        require(usdcUserBalance > 0 || ethUserBalance > 0, "No funds to transfer back");
        require(usdcUserBalance <= IERC20(usdc).balanceOf(address(this)), "Insufficient USDC balance");

        // Delete reservation and give back to the user his funds
        delete usdcDeposited[msg.sender];
        delete ethDeposited[msg.sender];
        delete userReservedAssets[msg.sender];
        sold -= itemsReserved;
        emit RemovedReservation(msg.sender, itemsReserved);
        
        if(usdcUserBalance > 0) IERC20(usdc).safeTransfer(msg.sender, usdcUserBalance);
        if(ethUserBalance > 0) _sendValue(payable(msg.sender), ethUserBalance);
    }

    // internal functions
    
    function _sendValue(address payable receiver, uint256 amount) internal {
        require(address(this).balance >= amount, "Insufficient ETH balance");

        (bool success, ) = receiver.call{value: amount}("");
        require(success, "unable to send value, recipient may have reverted");
    }
    
    function _validateDeposit(uint256 amount) internal view {
        require(state == uint8(FundingState.ACTIVE), "System state is not active");
        require(totalSupply - sold >= amount, "Not enough items to reserve");
    }

    function _buyWithEther(uint256 amount) internal {
        uint256 amountOfETH = amount*ethPrice;

        require(msg.value >= amountOfETH, "Insufficient ETH amount");

        _validateDeposit(amount);

        uint256 leftover;
        if(msg.value > amountOfETH) leftover = msg.value - amountOfETH;

        ethDeposited[msg.sender] += amountOfETH;
        _saveBuy(amount);

        if(leftover > 0) _sendValue(payable(msg.sender), leftover);

        emit Deposited(msg.sender, amountOfETH);
        emit TotalUnitsAvailableChanged(totalSupply - sold);
    }

    function _buyWithUSDC(uint256 amount) internal {
        uint256 amountOfUSDC = amount*usdcPrice;

        require(IERC20(usdc).allowance(msg.sender, address(this)) >= amountOfUSDC, "Not enough allowance");

        _validateDeposit(amount);
                
        usdcDeposited[msg.sender] += amountOfUSDC;
        _saveBuy(amount);

        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amountOfUSDC);

        emit USDCDeposited(msg.sender, amountOfUSDC);
        emit TotalUnitsAvailableChanged(totalSupply - sold);
    }

    function _saveBuy(uint256 amount) internal {
        userReservedAssets[msg.sender] += amount;
        sold += amount;
    }
}