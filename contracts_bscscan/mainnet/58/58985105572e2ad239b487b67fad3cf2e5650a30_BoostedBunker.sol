// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./ProofToken.sol";
import { HighLevelSystem } from "./HighLevelSystem.sol";

/// @title BoostedBunker
/// @author Andrew FU
contract BoostedBunker is ProofToken {

    struct User {
        uint256 depositPtokenAmount;
        uint256 depositTokenAAmount;
        uint256 depositTokenBAmount;
        uint256 depositTokenValue;
        uint256 depositBlockTimestamp;
    }

    HighLevelSystem.HLSConfig private HLSConfig;
    HighLevelSystem.Position private Position;
    
    using SafeMath for uint256;

    uint256 public total_deposit_limit_a;
    uint256 public total_deposit_limit_b;
    uint256 public deposit_limit_a;
    uint256 public deposit_limit_b;
    uint256 private temp_free_funds_a;
    uint256 private temp_free_funds_b;
    bool public TAG = false;
    address private dofin = address(0);
    address private factory = address(0);
    address[] public rtokens;

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

    function initialize(uint256[2] memory _uints, address[4] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        Position = HighLevelSystem.Position({
            pool_id: _uints[0],
            token_amount: 0,
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            crtoken_amount: 0,
            supply_amount: 0,
            liquidity_a: 0,
            liquidity_b: 0,
            borrowed_token_a_amount: 0,
            borrowed_token_b_amount: 0,
            token: _addrs[0],
            token_a: _addrs[1],
            token_b: _addrs[2],
            lp_token: _addrs[3],
            supply_crtoken: address(0x0000000000000000000000000000000000000000),
            borrowed_crtoken_a: address(0x0000000000000000000000000000000000000000),
            borrowed_crtoken_b: address(0x0000000000000000000000000000000000000000),
            funds_percentage: _uints[1],
            total_depts: 0
        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address[7] memory _config, address[] memory _rtokens, address _dofin, uint256[4] memory _deposit_limit) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        HLSConfig.token_oracle = _config[0];
        HLSConfig.token_a_oracle = _config[1];
        HLSConfig.token_b_oracle = _config[2];
        HLSConfig.cake_oracle = _config[3];
        HLSConfig.router = _config[4];
        HLSConfig.factory = _config[5];
        HLSConfig.masterchef = _config[6];

        rtokens = _rtokens;
        dofin = _dofin;
        deposit_limit_a = _deposit_limit[0];
        deposit_limit_b = _deposit_limit[1];
        total_deposit_limit_a = _deposit_limit[2];
        total_deposit_limit_b = _deposit_limit[3];

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }
    
    function getConfig() external view returns(HighLevelSystem.HLSConfig memory) {
        
        return HLSConfig;
    }

    function getPosition() external view returns(HighLevelSystem.Position memory) {
        
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }
    
    function rebalanceWithoutRepay() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        Position = HighLevelSystem.exitPositionBoosted(HLSConfig, Position);
        Position = HighLevelSystem.enterPositionBoosted(HLSConfig, Position);
        temp_free_funds_a = IBEP20(Position.token_a).balanceOf(address(this));
        temp_free_funds_b = IBEP20(Position.token_b).balanceOf(address(this));
    }
    
    function checkAddNewFunds() external view returns (uint256) {
        uint256 free_funds_a = IBEP20(Position.token_a).balanceOf(address(this));
        uint256 free_funds_b = IBEP20(Position.token_b).balanceOf(address(this));
        if (free_funds_a > temp_free_funds_a || free_funds_b > temp_free_funds_b) {
            if (Position.token_a_amount == 0 && Position.token_b_amount == 0) {
                // Need to enter
                return 1;
            } else {
                // Need to rebalance
                return 2;
            }
        }
        return 0;
    }

    function autoCompound(uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HighLevelSystem.autoCompound(HLSConfig, _amountIn, _path, _wrapType);
        Position.token_amount = IBEP20(Position.token).balanceOf(address(this));
        Position.token_a_amount = IBEP20(Position.token_a).balanceOf(address(this));
        Position.token_b_amount = IBEP20(Position.token_b).balanceOf(address(this));
    }
    
    function enter() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        Position = HighLevelSystem.enterPositionBoosted(HLSConfig, Position);
        temp_free_funds_a = IBEP20(Position.token_a).balanceOf(address(this));
        temp_free_funds_b = IBEP20(Position.token_b).balanceOf(address(this));
    }

    function exit() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        Position = HighLevelSystem.exitPositionBoosted(HLSConfig, Position);
    }

    function getTotalAssets() public view returns (uint256) {
        // Free funds amount
        uint256 tokenAfreeFunds = IBEP20(Position.token_a).balanceOf(address(this));
        uint256 tokenBfreeFunds = IBEP20(Position.token_b).balanceOf(address(this));
        (uint256 token_a_value, uint256 token_b_value) = HighLevelSystem.getChainLinkValues(HLSConfig, tokenAfreeFunds, tokenBfreeFunds);
        // Total Debts amount from PancakeSwap
        uint256 totalDebts = Position.total_depts;
        
        return token_a_value.add(token_b_value).add(totalDebts);
    }

    function getDepositAmountOut(uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256, uint256, uint256, uint256) {
        uint256 totalAssets = getTotalAssets();
        uint256 token_value;
        (_token_a_amount, _token_b_amount, token_value) = HighLevelSystem.getUpdatedAmount(HLSConfig, Position, _token_a_amount, _token_b_amount);
        require(_token_a_amount <= deposit_limit_a.mul(10**IBEP20(Position.token_a).decimals()), "Deposit too much token a!");
        require(_token_b_amount <= deposit_limit_b.mul(10**IBEP20(Position.token_b).decimals()), "Deposit too much token b!");
        (uint256 total_deposit_limit_a_value, uint256 total_deposit_limit_b_value) = HighLevelSystem.getChainLinkValues(HLSConfig, total_deposit_limit_a.mul(10**IBEP20(Position.token_a).decimals()), total_deposit_limit_b.mul(10**IBEP20(Position.token_b).decimals()));
        require(total_deposit_limit_a_value.add(total_deposit_limit_b_value) >= totalAssets.add(token_value), "Deposit get limited");

        uint256 shares;
        if (totalSupply_ > 0) {
            shares = token_value.mul(totalSupply_).div(totalAssets, "Bunker Div error checkpoint 1");
        } else {
            shares = token_value;
        }
        return (_token_a_amount, _token_b_amount, token_value, shares);
    }
    
    function deposit(uint256 _token_a_amount, uint256 _token_b_amount) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        // Calculation of pToken amount need to mint
         uint256 token_value;
         uint256 shares;
        (_token_a_amount, _token_b_amount, token_value, shares) = getDepositAmountOut(_token_a_amount, _token_b_amount);

        // Record user deposit amount
        User memory user = users[msg.sender];
        user.depositPtokenAmount = user.depositPtokenAmount.add(shares);
        user.depositTokenAAmount = user.depositTokenAAmount.add(_token_a_amount);
        user.depositTokenBAmount = user.depositTokenBAmount.add(_token_b_amount);
        user.depositTokenValue = user.depositTokenValue.add(token_value);
        user.depositBlockTimestamp = block.timestamp;
        users[msg.sender] = user;

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IBEP20(Position.token_a).transferFrom(msg.sender, address(this), _token_a_amount);
        IBEP20(Position.token_b).transferFrom(msg.sender, address(this), _token_b_amount);
        
        return true;
    }
    
    function getWithdrawAmount() external view returns (uint256, uint256) {
        uint256 totalAssets = getTotalAssets();
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        if (withdraw_amount > user.depositPtokenAmount) {
            return (0, 0);
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.depositTokenValue.add(10**IBEP20(Position.token).decimals())) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100, "Bunker Div error checkpoint 2");
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return HighLevelSystem.getValeSplit(HLSConfig, user_value);
    }
    
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender);
        require(withdraw_amount > 0, "Proof token amount insufficient");
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_, "Bunker Div error checkpoint 3");
        User memory user = users[msg.sender];
        bool need_rebalance = false;
        require(withdraw_amount <= user.depositPtokenAmount, "Proof token amount incorrect");
        require(block.timestamp > user.depositBlockTimestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        (uint256 value_a, uint256 value_b) = HighLevelSystem.getValeSplit(HLSConfig, value);
        if (value_a > IBEP20(Position.token_a).balanceOf(address(this)) || value_b > IBEP20(Position.token_b).balanceOf(address(this))) {
            Position = HighLevelSystem.exitPositionBoosted(HLSConfig, Position);
            totalAssets = getTotalAssets();
            value = withdraw_amount.mul(totalAssets).div(totalSupply_, "Bunker Div error checkpoint 4");
            need_rebalance = true;
        }
        // Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        // TODO need double check
        if (value > user.depositTokenValue.add(10**IBEP20(Position.token).decimals())) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100, "Bunker Div error checkpoint 5");
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        // Modify user state data
        user.depositPtokenAmount = 0;
        user.depositTokenAAmount = 0;
        user.depositTokenBAmount = 0;
        user.depositTokenValue = 0;
        user.depositBlockTimestamp = 0;
        users[msg.sender] = user;
        (uint256 user_value_a, uint256 user_value_b) = HighLevelSystem.getValeSplit(HLSConfig, user_value);
        (uint256 dofin_value_a, uint256 dofin_value_b) = HighLevelSystem.getValeSplit(HLSConfig, dofin_value);
        // Approve for withdraw
        IBEP20(Position.token_a).approve(address(this), user_value_a);
        IBEP20(Position.token_b).approve(address(this), user_value_b);
        IBEP20(Position.token_a).transferFrom(address(this), msg.sender, user_value_a);
        IBEP20(Position.token_b).transferFrom(address(this), msg.sender, user_value_b);
        if (dofin_value_a > IBEP20(Position.token_a).balanceOf(address(this))) {
            dofin_value_a = IBEP20(Position.token_a).balanceOf(address(this));
            need_rebalance = false;
        }
        if (dofin_value_b > IBEP20(Position.token_b).balanceOf(address(this))) {
            dofin_value_b = IBEP20(Position.token_b).balanceOf(address(this));
            need_rebalance = false;
        }
        // Approve for withdraw
        IBEP20(Position.token_a).approve(address(this), dofin_value_a);
        IBEP20(Position.token_b).approve(address(this), dofin_value_b);
        IBEP20(Position.token_a).transferFrom(address(this), dofin, dofin_value_a);
        IBEP20(Position.token_b).transferFrom(address(this), dofin, dofin_value_b);
        // Enter position again
        if (need_rebalance == true) {
            Position = HighLevelSystem.enterPositionBoosted(HLSConfig, Position);
            temp_free_funds_a = IBEP20(Position.token_a).balanceOf(address(this));
            temp_free_funds_b = IBEP20(Position.token_b).balanceOf(address(this));
        }
        
        return true;
    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        uint256 pTokenBalance = balanceOf(msg.sender);
        User memory user = users[msg.sender];
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.depositPtokenAmount > 0, "Not depositor");

        // Approve for withdraw
        IBEP20(Position.token_a).approve(address(this), user.depositTokenAAmount);
        IBEP20(Position.token_b).approve(address(this), user.depositTokenBAmount);
        IBEP20(Position.token_a).transferFrom(address(this), msg.sender, user.depositTokenAAmount);
        IBEP20(Position.token_b).transferFrom(address(this), msg.sender, user.depositTokenBAmount);
        
        return true;
    }
    
}