// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ProofToken.sol";
import { HLS_boosted } from "./HLS_boosted.sol";

/// @title Polygon BoostedBunker
/// @dev Normalized Value means "in USDC value".
/// @dev Normalized Decimal / Normalized Amount means "decimals == 18".
/// @dev deNormalized Amount means "decimals == token.decimals()".
contract BoostedBunker is ProofToken {


// -------------------------------------------------- public variables ---------------------------------------------------

    struct User {
        uint256 Proof_Token_Amount;
        uint256 Token_A_Amount;
        uint256 Token_B_Amount;
        uint256 Lp_Equiv_Amount;
        uint256 Block_Timestamp;
    }

    HLS_boosted.HLSConfig private HLSConfig;
    HLS_boosted.Position private Position;

    using SafeMath for uint256;

    uint256 public total_deposit_limit_a; // upper bound of tokenA amount in this bunker, ex: 500000 USDC.
    uint256 public total_deposit_limit_b; // upper bound of tokenB amount in this bunker, ex: 500000 DAI.
    uint256 public deposit_limit_a; // upper bound of tokenA for single depositing , ex: 100 USDC. 
    uint256 public deposit_limit_b; // upper bound of tokenB for single depositing , ex: 100 DAI.
    uint256 private temp_free_fund_a;// updated after each enterposition/exitposition used to check need rebalance or not
    uint256 private temp_free_fund_b;
    bool public TAG = false;
    bool public singleFarm = true;
    bool public PositionStatus = false;

    address private dofin = address(0) ;
    address private factory = address(0);
    mapping (address => User) private users;
    event Received(address, uint);


// --------------------------------------------------- config things -----------------------------------------------------
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

    function initialize(uint256 _funds_percentage, address[3] memory _addrs, string memory _name, string memory _symbol, uint8 _decimals) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        Position = HLS_boosted.Position({
            token_a_amount: 0,
            token_b_amount: 0,
            lp_token_amount: 0,
            liquidity_a: 0,
            liquidity_b: 0,
            token_a: _addrs[0],
            token_b: _addrs[1],
            lp_token: _addrs[2],
            funds_percentage: _funds_percentage,
            total_debts: 0
        });
        initializeToken(_name, _symbol, _decimals);
        factory = msg.sender;
    }
    
    function setConfig(address[3] memory _config, address _dofin, uint256[4] memory _deposit_limit, bool _singleFarm) external {
        if (dofin!=address(0) && factory!=address(0)) {
            require(checkCaller() == true, "Only factory or dofin can call this function");
        }
        HLSConfig.router = _config[0];
        HLSConfig.staking_reward = _config[1];
        HLSConfig.dQuick_addr = _config[2];

        dofin = _dofin;
        deposit_limit_a = _deposit_limit[0];
        deposit_limit_b = _deposit_limit[1];
        total_deposit_limit_a = _deposit_limit[2];
        total_deposit_limit_b = _deposit_limit[3];
        singleFarm = _singleFarm ;

        // Set Tag
        setTag(true);
    }

    function setTag(bool _tag) public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        TAG = _tag;
    }

// -------------------------------------------------- getters & check ----------------------------------------------------

    function checkAddNewFunds() public view returns (uint256) {
        uint256 free_fund_a = IERC20(Position.token_a).balanceOf(address(this));
        uint256 free_fund_b = IERC20(Position.token_b).balanceOf(address(this));

        if (free_fund_a > temp_free_fund_a || free_fund_b > temp_free_fund_b) {
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

    function getConfig() external view returns(HLS_boosted.HLSConfig memory) {
        
        return HLSConfig;
    }

    function getPosition() external view returns(HLS_boosted.Position memory) {
     
        return Position;
    }

    function getUser(address _account) external view returns (User memory) {
        
        return users[_account];
    }

    function getWithdrawAmount() external view returns (uint256 withdraw_a_amount, uint256 withdraw_b_amount) {
        uint256 totalAssets = getTotalAssets();
        uint256 withdraw_amount = balanceOf(msg.sender);
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        if (withdraw_amount > user.Proof_Token_Amount) {
            return (0, 0);
        }
        uint256 dofin_value;
        uint256 user_value;
        if (value > user.Lp_Equiv_Amount.add(10**IERC20(Position.lp_token).decimals())) {
            dofin_value = (value.sub(user.Lp_Equiv_Amount)).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }
        
        return HLS_boosted.getLpTokenAmountIn(Position.lp_token, user_value);

    }

    function getTotalAssets() public view returns (uint256) {

        uint256 tokenAfreeFunds = IERC20(Position.token_a).balanceOf(address(this));
        uint256 tokenBfreeFunds = IERC20(Position.token_b).balanceOf(address(this));
        uint256 lp_token_amount = HLS_boosted.getLpTokenAmountOut(Position.lp_token, tokenAfreeFunds, tokenBfreeFunds);

        // Total Debts amount from Quickswap
        uint256 totalDebts = HLS_boosted.getTotalDebtsBoosted(Position);
        
        return lp_token_amount.add(totalDebts);
    }

    function getDepositAmountOut(uint256 _token_a_amount, uint256 _token_b_amount) public view returns (uint256, uint256, uint256, uint256) {

        uint256 totalAssets = getTotalAssets();
        uint256 lp_token_amount;

        (_token_a_amount, _token_b_amount, lp_token_amount) = HLS_boosted.getUpdatedAmount(HLSConfig, Position, _token_a_amount, _token_b_amount);
        
        require(_token_a_amount <= deposit_limit_a.mul(10**IERC20(Position.token_a).decimals()), "Deposit too much token a!");
        require(_token_b_amount <= deposit_limit_b.mul(10**IERC20(Position.token_b).decimals()), "Deposit too much token b!");

        uint256 total_deposit_limit_lp = HLS_boosted.getLpTokenAmountOut(Position.lp_token, total_deposit_limit_a.mul(10**IERC20(Position.token_a).decimals()), total_deposit_limit_b.mul(10**IERC20(Position.token_b).decimals()));

        require(total_deposit_limit_lp >= totalAssets.add(lp_token_amount), "Deposit get limited");

        uint256 shares;
        if (totalSupply_ > 0) {
            shares = lp_token_amount.mul(totalSupply_).div(totalAssets);
        } else {
            shares = lp_token_amount;
        }
        return (_token_a_amount, _token_b_amount, lp_token_amount, shares);

    }

    function getFreeFunds(bool _getAll, bool _getNormalized) public view returns (uint256,uint256,uint256,uint256){
        
        ( uint256 a_free_fund , uint256 b_free_fund ) = HLS_boosted.getFreeFunds(Position.token_a, Position.token_b, Position.funds_percentage, _getAll, _getNormalized);
        
        return (a_free_fund, b_free_fund, temp_free_fund_a, temp_free_fund_b) ;
    }


// ------------------------------------------------ manipulative functions -----------------------------------------------
    function rebalanceWithoutRepay() public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _rebalanceWithoutRepay();
    }

    function _rebalanceWithoutRepay() public {
        require(TAG == true, 'TAG ERROR.');
        require(PositionStatus == true, 'POSITIONSTATUS ERROR');
        _exit();
        _enter();
    }

    function _exit() private {
        require(TAG == true, 'TAG ERROR.');
        Position = HLS_boosted.exitPositionBoosted(HLSConfig, Position, singleFarm);
        PositionStatus = false;
    }

    function _enter() private {
        require(TAG == true, 'TAG ERROR.');
        Position = HLS_boosted.enterPositionBoosted(HLSConfig, Position, singleFarm);
        temp_free_fund_a = IERC20(Position.token_a).balanceOf(address(this));
        temp_free_fund_b = IERC20(Position.token_b).balanceOf(address(this));
        PositionStatus = true;
    }
    
    function enter() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _enter();
    }

    function exit() external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        _exit();
    } 
    
    function autoCompound(uint256 _amountIn, address[] calldata _path, uint256 _wrapType) external {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HLS_boosted.autoCompound(HLSConfig.router, _amountIn, _path, _wrapType);
        Position.token_a_amount = IERC20(Position.token_a).balanceOf(address(this));
        Position.token_b_amount = IERC20(Position.token_b).balanceOf(address(this));
        Position.total_debts = HLS_boosted.getTotalDebtsBoosted(Position);
    }

    function claimReward() public {
        require(checkCaller() == true, "Only factory or dofin can call this function");
        require(TAG == true, 'TAG ERROR.');
        HLS_boosted.claimReward(HLSConfig.staking_reward, HLSConfig.dQuick_addr, singleFarm);
    }

    /** @dev User's deposit function
        @param _token_a_amount : deNormalized amount
        @param _token_b_amount : deNormalized amount
     */
    function deposit(uint256 _token_a_amount, uint256 _token_b_amount) external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        // Calculation of pToken amount need to mint
         uint256 lp_token_amount;
         uint256 shares;
        (_token_a_amount, _token_b_amount, lp_token_amount, shares) = getDepositAmountOut(_token_a_amount, _token_b_amount);

        // Record user deposit amount
        User memory user = users[msg.sender];
        user.Proof_Token_Amount = user.Proof_Token_Amount.add(shares);  //Norm
        user.Token_A_Amount = user.Token_A_Amount.add(_token_a_amount); //deNorm
        user.Token_B_Amount = user.Token_B_Amount.add(_token_b_amount); //deNorm
        user.Lp_Equiv_Amount = user.Lp_Equiv_Amount.add(lp_token_amount);// pair lp decimal==18
        user.Block_Timestamp = block.timestamp;
        users[msg.sender] = user;

        // Mint pToken and transfer Token to cashbox
        mint(msg.sender, shares);
        IERC20(Position.token_a).transferFrom(msg.sender, address(this), _token_a_amount);
        IERC20(Position.token_b).transferFrom(msg.sender, address(this), _token_b_amount);
        
        uint256 newFunds = checkAddNewFunds();
        if (newFunds == 1) {
            _enter();
        } else if (newFunds == 2) {
            _rebalanceWithoutRepay();
        }

        return true;

    }
    
    /// @dev User's withdraw function. For now, only allow user to withdraw all.
    function withdraw() external returns (bool) {
        require(TAG == true, 'TAG ERROR.');
        uint256 withdraw_amount = balanceOf(msg.sender);
        require(withdraw_amount > 0, "Proof token amount insufficient");
        uint256 totalAssets = getTotalAssets();
        uint256 value = withdraw_amount.mul(totalAssets).div(totalSupply_);
        User memory user = users[msg.sender];
        bool need_rebalance = false;
        require(withdraw_amount <= user.Proof_Token_Amount, "Proof token amount incorrect");
        require(block.timestamp > user.Block_Timestamp, "Deposit and withdraw in same block");
        // If no enough amount of free funds can transfer will trigger exit position
        (uint256 value_a, uint256 value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, value);

        if ( value_a > IERC20(Position.token_a).balanceOf(address(this)) || value_b > IERC20(Position.token_b).balanceOf(address(this)) ) {
            Position = HLS_boosted.exitPositionBoosted(HLSConfig, Position, singleFarm);
            totalAssets = getTotalAssets();
            value = withdraw_amount.mul(totalAssets).div(totalSupply_);
            need_rebalance = true;
        }
        // Will charge 20% fees
        burn(msg.sender, withdraw_amount);
        uint256 dofin_value;
        uint256 user_value;

        if (value > user.Lp_Equiv_Amount.add(10**IERC20(Position.lp_token).decimals())) {
            dofin_value = (value.sub(user.Lp_Equiv_Amount)).mul(20).div(100);
            user_value = value.sub(dofin_value);
        } else {
            user_value = value;
        }

        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Token_A_Amount = 0;
        user.Token_B_Amount = 0;
        user.Lp_Equiv_Amount = 0;
        user.Block_Timestamp = 0;
        users[msg.sender] = user;

        (uint256 user_value_a, uint256 user_value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, user_value);
        (uint256 dofin_value_a, uint256 dofin_value_b) = HLS_boosted.getLpTokenAmountIn(Position.lp_token, dofin_value);

        // Approve for withdraw
        IERC20(Position.token_a).approve(address(this), user_value_a);
        IERC20(Position.token_b).approve(address(this), user_value_b); 
        IERC20(Position.token_a).transferFrom(address(this), msg.sender, user_value_a);
        IERC20(Position.token_b).transferFrom(address(this), msg.sender, user_value_b);

        if (dofin_value_a > IERC20(Position.token_a).balanceOf(address(this))) {
            dofin_value_a = IERC20(Position.token_a).balanceOf(address(this));
            need_rebalance = false;
        }

        if (dofin_value_b > IERC20(Position.token_b).balanceOf(address(this))) {
            dofin_value_b = IERC20(Position.token_b).balanceOf(address(this));
            need_rebalance = false;
        }
        
        // Approve for withdraw
        IERC20(Position.token_a).approve(address(this), dofin_value_a);
        IERC20(Position.token_b).approve(address(this), dofin_value_b);
        IERC20(Position.token_a).transferFrom(address(this), dofin, dofin_value_a);
        IERC20(Position.token_b).transferFrom(address(this), dofin, dofin_value_b);


        // Enter position again
        if (need_rebalance == true) {
            Position = HLS_boosted.enterPositionBoosted(HLSConfig, Position, singleFarm);
            temp_free_fund_a = IERC20(Position.token_a).balanceOf(address(this));
            temp_free_fund_b = IERC20(Position.token_b).balanceOf(address(this));
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
        IERC20(Position.token_a).approve(address(this), user.Token_A_Amount);
        IERC20(Position.token_b).approve(address(this), user.Token_B_Amount); 
        IERC20(Position.token_a).transferFrom(address(this), msg.sender, user.Token_A_Amount);
        IERC20(Position.token_b).transferFrom(address(this), msg.sender, user.Token_B_Amount); 
        
        // Modify user state data
        user.Proof_Token_Amount = 0;
        user.Token_A_Amount = 0;
        user.Token_B_Amount = 0;
        user.Lp_Equiv_Amount = 0;
        user.Block_Timestamp = 0;
        users[msg.sender] = user;
        
        return true;
    }
    


// -------------------------------------------------- ending of bunker ---------------------------------------------------

    // function getHLSStakedTokenAmount()public view returns(uint256, uint256){
    //     (uint256 token_a_amt, uint256 token_b_amt) = HLS_boosted.getStakedTokenAmount(Position);
    //     return (token_a_amt, token_b_amt) ;
    // }
    
    // function getHLSTotalDebtsBoosted() public view returns(uint256){
    //     uint256 totalDebts = HLS_boosted.getTotalDebtsBoosted(Position);
    //     return totalDebts ;
    // }

    // function getHLSUpdatedAmount(uint256 _token_a_amount,uint256 _token_b_amount) public view returns(uint256, uint256, uint256){
    //     (uint256 _token_a_amount,uint256 _token_b_amount,uint256 token_total_value) = HLS_boosted.getUpdatedAmount(HLSConfig, Position, _token_a_amount, _token_b_amount);

    //     return (_token_a_amount, _token_b_amount, token_total_value);
    // }


}