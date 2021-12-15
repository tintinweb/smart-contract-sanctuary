// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ProofToken.sol";
import { HLS_fixed } from "./HLS_fixed.sol";

import "./CErc20Delegator.sol";
import "./ComptrollerInterface.sol";

/// @title Polygon FixedBunker
contract FixedBunker is ProofToken {

    struct User {
        uint256 Proof_Token_Amount;
        uint256 Deposited_Token_Amount;
        uint256 Deposit_Block_Timestamp;
    }

    HLS_fixed.Position private Position;
    
    using SafeMath for uint256;

    uint256 public total_deposit_limit;
    uint256 public deposit_limit;
    uint256 private temp_free_funds;
    bool public TAG = false;
    bool public PositionStatus = false;	
    address private dofin = address(0);
    address private factory = address(0);

    mapping (address => User) private users;
    event Received(address, uint);

    function sendFees() external payable {
        
        emit Received(msg.sender, msg.value);
    }

    function feesBack() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        uint256 contract_balance = payable(address(this)).balance;
        payable(address(msg.sender)).transfer(contract_balance);
    }

    function checkCaller() public view returns (bool) {
        if (msg.sender == factory || msg.sender == dofin) {
            return true;
        }
        return false;
    }

    function initialize(address _depositing_token_addr, address _supply_crtoken_addr, uint256 _funds_percentage, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        Position = HLS_fixed.Position({
            token_amount: 0,
            crtoken_amount: 0,
            supply_amount: 0,

            token: _depositing_token_addr,
            supply_crtoken: _supply_crtoken_addr,
            funds_percentage: _funds_percentage,

            total_debts: 0

        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address _dofin, uint256[2] memory _deposit_limit) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }

        dofin = _dofin;
        deposit_limit = _deposit_limit[0];
        total_deposit_limit = _deposit_limit[1];

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }

    function getPosition() external view returns(HLS_fixed.Position memory) {
        
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }
    
    function rebalance() external  {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _rebalance();
    }

    function _rebalance() private  {
        require(TAG == true, 'TAG ERROR');
        require(PositionStatus == true, 'POSITIONSTATUS ERROR');
        _exit();
        _enter();
    }
    
    function checkAddNewFunds() public view returns (uint256) {
        uint256 free_funds = IERC20(Position.token).balanceOf(address(this));
        if (free_funds > temp_free_funds) {
            if (PositionStatus == false) {
                // Need to enter
                return 1;
            } else {
                // Need to rebalance
                return 2;
            }
        }
        return 0;
    }
    
    function enter() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _enter();
    }

    function _enter() private {
        require(TAG == true, 'TAG ERROR.');
        Position = HLS_fixed.enterPositionFixed(Position);
        temp_free_funds = IERC20(Position.token).balanceOf(address(this));
        PositionStatus = true;
    }

    function exit() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _exit();
    }

    function _exit() private {
        require(TAG == true, 'TAG ERROR.');
        Position = HLS_fixed.exitPositionFixed(Position);
        PositionStatus = false;
    }

    function getTotalAssets() public view returns (uint256) {
        // Free funds amount
        uint256 freeFunds = IERC20(Position.token).balanceOf(address(this));
        // Total Debts amount from Cream
        uint256 totalDebts = Position.total_debts;
        
        return freeFunds.add(totalDebts);
    }

    function getDepositAmountOut(uint256 _deposit_amount) public view returns (uint256) {
        require(_deposit_amount <= deposit_limit.mul(10**IERC20(Position.token).decimals()), "Deposit too much");
        require(_deposit_amount > 0, "Deposit amount must bigger than 0");
        uint256 totalAssets = getTotalAssets();
        require(total_deposit_limit.mul(10**IERC20(Position.token).decimals()) >= totalAssets.add(_deposit_amount), "Deposit get limited");
        uint256 shares;
        if (totalSupply_ > 0) {
            shares = _deposit_amount.mul(totalSupply_).div(totalAssets, "Bunker Div error checkpoint 1");
        } else {
            shares = _deposit_amount;
        }
        return shares;
    }
    
    function deposit(uint256 _deposit_amount) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        // Calculation of pToken amount need to mint
        uint256 shares = getDepositAmountOut(_deposit_amount);
        
        // Record user deposit amount
        User memory user = users[msg.sender];
        user.Proof_Token_Amount = user.Proof_Token_Amount.add(shares);
        user.Deposited_Token_Amount = user.Deposited_Token_Amount.add(_deposit_amount);
        user.Deposit_Block_Timestamp = block.timestamp;
        users[msg.sender] = user;

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IERC20(Position.token).transferFrom(msg.sender, address(this), _deposit_amount);

        uint256 newFunds = checkAddNewFunds();	
        if (newFunds == 1) {	
            _enter();	
        } else if (newFunds == 2) {	
            _rebalance();	
        }	
        
        return true;
    }
    
    function getWithdrawAmount() external view returns (uint256) {
        uint256 totalAssets = getTotalAssets();
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        if (withdraw_amount > user.Proof_Token_Amount) {
            return 0;
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.Deposited_Token_Amount) {
            dofin_value = value.sub(user.Deposited_Token_Amount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return user_value;
    }
    
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender);
        require(withdraw_amount > 0, "Proof token amount insufficient");
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        bool need_rebalance = false;
        require(withdraw_amount <= user.Proof_Token_Amount, "Proof token amount incorrect");
        require(block.timestamp > user.Deposit_Block_Timestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        if (value > IERC20(Position.token).balanceOf(address(this))) {
            Position = HLS_fixed.exitPositionFixed(Position);
            totalAssets = IERC20(Position.token).balanceOf(address(this));
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
            need_rebalance = true;
        }
        // Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        // TODO need double check
        if (value > user.Deposited_Token_Amount.add(10**IERC20(Position.token).decimals())) {
            dofin_value = value.sub(user.Deposited_Token_Amount).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposit_Block_Timestamp = 0;
        users[msg.sender] = user;
        // Approve for withdraw
        IERC20(Position.token).approve(address(this), user_value);
        IERC20(Position.token).transferFrom(address(this), msg.sender, user_value);
        if (dofin_value > IERC20(Position.token).balanceOf(address(this))) {
            dofin_value = IERC20(Position.token).balanceOf(address(this));
            need_rebalance = false;
        }
        // Approve for withdraw
        IERC20(Position.token).approve(address(this), dofin_value);
        IERC20(Position.token).transferFrom(address(this), dofin, dofin_value);

        // Enter position again
        if (need_rebalance == true) {
            Position = HLS_fixed.enterPositionFixed(Position);
            temp_free_funds = IERC20(Position.token).balanceOf(address(this));
        }
        
        return true;
    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        uint256 pTokenBalance = balanceOf(msg.sender);
        User memory user = users[msg.sender];
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.Proof_Token_Amount > 0, "Not depositor");

        // Approve for withdraw
        IERC20(Position.token).approve(address(this), user.Deposited_Token_Amount);
        IERC20(Position.token).transferFrom(address(this), msg.sender, user.Deposited_Token_Amount);
        
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Deposited_Token_Amount = 0;
        user.Deposit_Block_Timestamp = 0;
        users[msg.sender] = user;
        
        return true;
    }


}