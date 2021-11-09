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
    HighLevelSystem.Position private position;
    
    using SafeMath for uint256;
    uint256 constant private MAX_INT_EXPONENTIATION = 2**256 - 1;

    uint256 private total_deposit_limit_a;
    uint256 private total_deposit_limit_b;
    uint256 private deposit_limit_a;
    uint256 private deposit_limit_b;
    uint256 private temp_free_funds_a;
    uint256 private temp_free_funds_b;
    bool public TAG = false;
    address private dofin = address(0);
    address private factory = address(0);

    mapping (address => User) private users;

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
        position = HighLevelSystem.Position({
            pool_id: _uints[0],
            token_amount: 0,
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            crtoken_amount: 0,
            supply_crtoken_amount: 0,
            token: _addrs[0],
            token_a: _addrs[1],
            token_b: _addrs[2],
            lp_token: _addrs[3],
            supply_crtoken: address(0x0000000000000000000000000000000000000000),
            borrowed_crtoken_a: address(0x0000000000000000000000000000000000000000),
            borrowed_crtoken_b: address(0x0000000000000000000000000000000000000000),
            supply_funds_percentage: _uints[1],
            total_depts: 0
        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address[8] memory _config, address _dofin, uint256[4] memory _deposit_limit) external {
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
        HLSConfig.CAKE = _config[7];

        dofin = _dofin;
        deposit_limit_a = _deposit_limit[0];
        deposit_limit_b = _deposit_limit[1];
        total_deposit_limit_a = _deposit_limit[2];
        total_deposit_limit_b = _deposit_limit[3];

        // Approve for PancakeSwap addliquidity
        IBEP20(position.token_a).approve(HLSConfig.router, MAX_INT_EXPONENTIATION);
        IBEP20(position.token_b).approve(HLSConfig.router, MAX_INT_EXPONENTIATION);
        // Approve for PancakeSwap stake
        IBEP20(position.lp_token).approve(HLSConfig.masterchef, MAX_INT_EXPONENTIATION);

        // Approve for PancakeSwap removeliquidity
        IBEP20(position.lp_token).approve(HLSConfig.router, MAX_INT_EXPONENTIATION);
        // Approve for withdraw
        IBEP20(position.token_a).approve(address(this), MAX_INT_EXPONENTIATION);
        IBEP20(position.token_b).approve(address(this), MAX_INT_EXPONENTIATION);

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }
    
    function getPosition() external view returns(HighLevelSystem.Position memory) {
        
        return position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }
    
    function rebalanceWithoutRepay() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.exitPositionBoosted(HLSConfig, position);
        position = HighLevelSystem.enterPositionBoosted(HLSConfig, position);
        temp_free_funds_a = IBEP20(position.token_a).balanceOf(address(this));
        temp_free_funds_b = IBEP20(position.token_b).balanceOf(address(this));
    }
    
    function checkAddNewFunds() external view returns (uint256) {
        uint256 free_funds_a = IBEP20(position.token_a).balanceOf(address(this));
        uint256 free_funds_b = IBEP20(position.token_b).balanceOf(address(this));
        if (free_funds_a > temp_free_funds_a || free_funds_b > free_funds_b) {
            if (position.token_a_amount == 0 && position.token_b_amount == 0) {
                // Need to enter
                return 1;
            } else {
                // Need to rebalance
                return 2;
            }
        }
        return 0;
    }

    function autoCompound(address[] calldata _token_a_path, address[] calldata _token_b_path) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HighLevelSystem.autoCompoundBoosted(HLSConfig, _token_a_path, _token_b_path);
    }
    
    function enter() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.enterPositionBoosted(HLSConfig, position);
        temp_free_funds_a = IBEP20(position.token_a).balanceOf(address(this));
        temp_free_funds_b = IBEP20(position.token_b).balanceOf(address(this));
    }

    function exit() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        position = HighLevelSystem.exitPositionBoosted(HLSConfig, position);
    }

    function getTotalAssets() public view returns (uint256) {
        // Free funds amount
        uint256 tokenAfreeFunds = IBEP20(position.token_a).balanceOf(address(this));
        uint256 tokenBfreeFunds = IBEP20(position.token_b).balanceOf(address(this));
        (uint256 token_a_value, uint256 token_b_value) = HighLevelSystem.getChainLinkValues(HLSConfig, tokenAfreeFunds, tokenBfreeFunds);
        // Total Debts amount from PancakeSwap
        uint256 totalDebts = HighLevelSystem.getTotalDebtsBoosted(HLSConfig, position);
        
        return token_a_value.add(token_b_value).add(totalDebts);
    }

    function getDepositAmountOut(uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256, uint256, uint256, uint256) {
        (uint256 token_a_value, uint256 token_b_value) = HighLevelSystem.getChainLinkValues(HLSConfig, IBEP20(position.token_a).balanceOf(address(this)), IBEP20(position.token_b).balanceOf(address(this)));
        uint256 totalAssets = token_a_value.add(token_b_value).add(position.total_depts);
        uint256 token_value;
        (_token_a_amount, _token_b_amount, token_value) = HighLevelSystem.getUpdatedAmount(HLSConfig, position, _token_a_amount, _token_b_amount);
        require(_token_a_amount <= deposit_limit_a.mul(10**IBEP20(position.token_a).decimals()), "Deposit too much token a!");
        require(_token_a_amount <= deposit_limit_b.mul(10**IBEP20(position.token_b).decimals()), "Deposit too much token b!");
        require(_token_a_amount > 0, "Deposit token a amount must bigger than 0.");
        require(_token_b_amount > 0, "Deposit token b amount must bigger than 0.");
        uint256 total_deposit_limit = total_deposit_limit_a.mul(10**IBEP20(position.token_a).decimals()).add(total_deposit_limit_b.mul(10**IBEP20(position.token_b).decimals()));
        require(total_deposit_limit >= totalAssets.add(_token_a_amount).add(_token_b_amount), "Deposit get limited");

        uint256 shares;
        if (totalSupply_ > 0) {
            shares = token_value.mul(totalSupply_).div(totalAssets);
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
        user.depositBlockTimestamp = block.timestamp;
        users[msg.sender] = user;

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IBEP20(position.token_a).transferFrom(msg.sender, address(this), _token_a_amount);
        IBEP20(position.token_b).transferFrom(msg.sender, address(this), _token_b_amount);
        
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
        if (value > user.depositTokenValue) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return HighLevelSystem.getValeSplit(HLSConfig, user_value);
    }
    
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        bool need_rebalance = false;
        require(withdraw_amount <= user.depositPtokenAmount, "Proof token amount incorrect");
        require(block.timestamp > user.depositBlockTimestamp, "Deposit and withdraw in same block");
        
        // If no enough amount of free funds can transfer will trigger exit position
        (uint256 value_a, uint256 value_b) = HighLevelSystem.getValeSplit(HLSConfig, value);
        if (value_a > IBEP20(position.token_a).balanceOf(address(this)).add(10**IBEP20(position.token_a).decimals()) || value_b > IBEP20(position.token_b).balanceOf(address(this)).add(10**IBEP20(position.token_b).decimals())) {
            HighLevelSystem.exitPositionBoosted(HLSConfig, position);
            totalAssets = IBEP20(position.token_a).balanceOf(address(this)).add(IBEP20(position.token_b).balanceOf(address(this)));
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
            need_rebalance = true;
        }

        // Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.depositTokenValue) {
            dofin_value = value.sub(user.depositTokenValue).mul(20).div(100);
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
        IBEP20(position.token_a).transferFrom(address(this), msg.sender, user_value_a);
        IBEP20(position.token_b).transferFrom(address(this), msg.sender, user_value_b);
        if (dofin_value_a > IBEP20(position.token_a).balanceOf(address(this))) {
            dofin_value_a = IBEP20(position.token_a).balanceOf(address(this));
            need_rebalance = false;
        }
        if (dofin_value_b > IBEP20(position.token_b).balanceOf(address(this))) {
            dofin_value_b = IBEP20(position.token_b).balanceOf(address(this));
            need_rebalance = false;
        }
        IBEP20(position.token_a).transferFrom(address(this), dofin, dofin_value_a);
        IBEP20(position.token_b).transferFrom(address(this), dofin, dofin_value_b);
        
        // Enter position again
        if (need_rebalance == true) {
            HighLevelSystem.enterPositionBoosted(HLSConfig, position);
            temp_free_funds_a = IBEP20(position.token_a).balanceOf(address(this));
            temp_free_funds_b = IBEP20(position.token_b).balanceOf(address(this));
        }
        
        return true;
    }

    function emergencyWithdrawal() external returns (bool) {
        require(TAG == false, 'NOT EMERGENCY');
        uint256 pTokenBalance = balanceOf(msg.sender);
        User memory user = users[msg.sender];
        require(pTokenBalance > 0,  "Incorrect quantity of Proof Token");
        require(user.depositPtokenAmount > 0, "Not depositor");

        IBEP20(position.token_a).transferFrom(address(this), msg.sender, user.depositTokenAAmount);
        IBEP20(position.token_b).transferFrom(address(this), msg.sender, user.depositTokenBAmount);
        
        return true;
    }
    
}