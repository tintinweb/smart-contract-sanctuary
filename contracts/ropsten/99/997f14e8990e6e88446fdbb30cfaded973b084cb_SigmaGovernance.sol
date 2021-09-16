/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

  
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
      

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC659 {
    function totalSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function activeSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function burnedSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function redeemedSupply(  uint256 class, uint256 nonce) external  view  returns (uint256);
    function getNonceCreated(uint256 class) external view returns (uint256[] memory);
    function balanceOf(address account, uint256 class, uint256 nonce) external view returns (uint256);
    function getBondSymbol(uint256 class) view external returns (string memory);
    function getBondInfo(uint256 class, uint256 nonce) external view returns (string memory BondSymbol, uint256 timestamp, uint256 info2, uint256 info3, uint256 info4, uint256 info5,uint256 info6);
    function bondIsRedeemable(uint256 class, uint256 nonce) external view returns (bool);
    
 
    function issueBond(address _to, uint256  class, uint256 _amount) external returns(bool);
    function redeemBond(address _from, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function transferBond(address _from, address _to, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    function burnBond(address _from, uint256[] calldata class, uint256[] calldata nonce, uint256[] calldata _amount) external returns(bool);
    
    event eventIssueBond(address _operator, address _to, uint256 class, uint256 nonce, uint256 _amount); 
    event eventRedeemBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventBurnBond(address _operator, address _from, uint256 class, uint256 nonce, uint256 _amount);
    event eventTransferBond(address _operator, address _from, address _to, uint256 class, uint256 nonce, uint256 _amount);
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface ISigmoidExchange{
    function isActive(bool _contract_is_active) external returns (bool);
    function maxiumuSupply() external view returns (uint256);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setBondContract(address bond_address) external returns (bool);
    function setTokenContract(uint256 token_class, address token_address) external returns (bool);

}

interface ISigmoidTokens {
    function isActive(bool _contract_is_active) external returns (bool);
    function maxiumuSupply() external view returns (uint256);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function bankTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

interface ISigmoidBonds{
    function isActive(bool _contract_is_active) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setExchangeContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setTokenContract(uint256 class, address contract_address) external returns (bool);
    function createBondClass(uint256 class, string calldata bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch)external returns (bool);
}

interface ISigmoidBank{
    function isActive(bool _contract_is_active) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setBondContract(address bond_address) external returns (bool);
    function setTokenContract(uint256 token_class, address token_address) external returns (bool);
   
    function addStablecoinToList(address contract_address) external returns (bool);
    function checkIntheList(address contract_address) view external returns (bool);
    function migratorLP(address _to, address tokenA, address tokenB) external returns (bool);

    
    function powerX(uint256 power_root, uint256 num,uint256 num_decimals)  pure external returns (uint256);
    function logX(uint256 log_root,uint256 log_decimals, uint256 num)  pure external returns (uint256);
    
    function getBondExchangeRateSASHtoUSD(uint256 amount_SASH_out) view external returns (uint256);
    function getBondExchangeRateUSDtoSASH(uint256 amount_USD_in) view external returns (uint256);
    function getBondExchangeRatSGMtoSASH(uint256 amount_SGM_out) view external returns (uint256);
    function getBondExchangeRateSASHtoSGM(uint256 amount_SASH_in) view external returns (uint256);
    
    function buySASHBondWithUSD(address contract_address, address _to, uint256 amount_USD_in) external returns (bool);
    function buySGMBondWithSASH(address _to, uint256 amount_SASH_in) external returns (bool);
    function buyVoteBondWithSGM(address _from, address _to, uint256 amount_SGM_in) external returns (bool);
    
   function redeemBond(address _to, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount, address first_referral, address second_referral) external returns (bool);
}

interface ISigmoidGovernance{
    function isActive(bool _contract_is_active) external returns (bool);
    function getClassInfo(uint256 poposal_class) external view returns(uint256 timelock, uint256 minimum_approval, uint256 minimum_vote, uint256 need_architect_veto, uint256 maximum_execution_time, uint256 minimum_execution_interval);
    function getProposalInfo(uint256 poposal_class, uint256 proposal_nonce) external view returns(uint256 timestamp, uint256 total_vote, uint256 approve_vote, uint256 architect_veto, uint256 execution_left, uint256 execution_interval);
    
    function vote(uint256 poposal_class, uint256 proposal_nonce, bool approval, uint256 _amount) external returns(bool);
    function veto(uint256 poposal_class, uint256 proposal_nonce, bool approval) external  returns(bool);
    function createProposal(uint256 poposal_class, address proposal_address, uint256 proposal_execution_nonce, uint256 proposal_execution_interval) external returns(bool);
    function revokeProposal(uint256 poposal_class, uint256 proposal_nonce, uint256 revoke_poposal_class, uint256 revoke_proposal_nonce) external returns(bool);
    function checkProposal(uint256 poposal_class, uint256 proposal_nonce) external view returns(bool);
    
    function firstTimeSetContract(address SASH_address,address SGM_address, address bank_address, address bond_address, address exchange_address) external returns(bool);
    function InitializeSigmoid() external returns(bool);
    function pauseAll(bool _contract_is_active) external returns(bool);
   
    function updateGovernanceContract(uint256 poposal_class, uint256 proposal_nonce, address new_governance_address) external returns(bool);
    function updateExchangeContract(uint256 poposal_class, uint256 proposal_nonce, address new_exchange_address) external returns(bool);
    function updateBankContract(uint256 poposal_class, uint256 proposal_nonce, address new_bank_address) external returns(bool);
    function updateBondContract(uint256 poposal_class, uint256 proposal_nonce, address new_bond_address) external returns(bool);
    function updateTokenContract(uint256 poposal_class, uint256 proposal_nonce, uint256 new_token_class, address new_token_address) external returns(bool);
    function createBondClass(uint256 poposal_class, uint256 proposal_nonce, uint256 bond_class, string calldata bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch) external returns (bool);
   
    function migratorLP(uint256 poposal_class, uint256 proposal_nonce, address _to, address tokenA, address tokenB) external returns(bool);
    function transferTokenFromGovernance(uint256 poposal_class, uint256 proposal_nonce, address _token, address _to, uint256 _amount) external returns(bool);
    function claimFundForProposal(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_amount,  uint256 SGM_amount) external returns(bool);
    function mintAllocationToken(address _to, uint256 SASH_amount, uint256 SGM_amount) external returns(bool);
    function changeTeamAllocation(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_ppm, uint256 SGM_ppm) external returns(bool);
    function changeCommunityFundSize(uint256 poposal_class, uint256 proposal_nonce, uint256 new_SGM_budget_ppm, uint256 new_SASH_budget_ppm) external returns(bool);
    
    function changeReferralPolicy(uint256 poposal_class, uint256 proposal_nonce, uint256 new_1st_referral_reward_ppm, uint256 new_1st_referral_POS_reward_ppm, uint256 new_2nd_referral_reward_ppm, uint256 new_2nd_referral_POS_reward_ppm, uint256 new_first_referral_POS_Threshold_ppm, uint256 new_second_referral_POS_Threshold_ppm) external returns(bool);
    function claimReferralReward(address first_referral, address second_referral, uint256 SASH_total_amount) external returns(bool);
    function getReferralPolicy(uint256 index) external view returns(uint256);
}

contract SigmaGovernance is ISigmoidGovernance{
    address public dev_address;
    address public CSO_address;
    address public SASH_contract;
    address public SGM_contract;
    address public governance_contract;
    address public exchange_contract;
    address public bank_contract;
    address public bond_contract;
    address public airdrop_contract;
    bool public initialized;
    bool public contract_is_active;
    
    uint256 SASH_proposal_claimed;
    uint256 SGM_proposal_claimed;
    
    uint256 SASH_budget_ppm = 1e5;
    uint256 SGM_budget_ppm = 1e5;
    
    uint256 SASH_allocation_distributed_ppm;
    uint256 SGM_allocation_distributed_ppm;
    
    mapping (address => uint256[2]) allocation_ppm;
    mapping (address => uint256[2]) allocation_minted;
    
    uint256 SASH_total_allocation_distributed;
    uint256 SGM_total_allocation_distributed;
    
    uint256 first_referral_reward_ppm = 5e3;
    uint256 first_referral_POS_reward_ppm = 1e4;
    uint256 second_referral_reward_ppm = 1e4;
    uint256 second_referral_POS_reward_ppm = 2e4;
    
    uint256 first_referral_POS_Threshold_ppm = 2e2;
    uint256 second_referral_POS_Threshold_ppm = 1e1;
    
    mapping (uint256 => mapping(uint256=>uint256[6])) public _proposalVoting;
    mapping (uint256 => mapping(uint256=>address)) public _proposalAddress;
    mapping (uint256 => uint256[6]) public _proposalClassInfo;
    //roposal class, proposal nonce, [0proposal timelock, 1total vote, 2appove vote, 3Architect Veto(0 no vote,
    //1 aprove, 2 vote veto), proposal can be exacuted, proposal execution interval]
    
    mapping (uint256 => uint256)public _proposalNonce;
    
    constructor() public{
        _proposalClassInfo[0][0] = 15*24*60*60;//timelock
        _proposalClassInfo[0][1] = 50;//minimum approval percentage needed
        _proposalClassInfo[0][3] = 1;//need arechitect approval
        _proposalClassInfo[0][4] = 1;//maximum excution time
        
        _proposalClassInfo[1][0] = 10*24*60*60;//timelock
        _proposalClassInfo[1][1] = 50;//minimum approval percentage needed
        _proposalClassInfo[1][3] = 1;//need arechitect approval
        _proposalClassInfo[1][4] = 1;//maximum excution time
        
        _proposalClassInfo[2][0] = 5*24*60*60;//timelock
        _proposalClassInfo[2][1] = 50;//minimum approval percentage needed
        _proposalClassInfo[2][3] = 1;//need arechitect approval
        _proposalClassInfo[2][4] = 120;//maximum excution time
        
        
        dev_address=msg.sender;
        CSO_address=msg.sender;   
      
    }
    
    function isActive(bool _contract_is_active) public override returns (bool){
         contract_is_active = _contract_is_active;
         return(contract_is_active);
     }
         
        
    function _mintReferralReward(address _to, uint256 SASH_amount) private returns(bool){
        require(SASH_proposal_claimed + SASH_amount <= (IERC20(SASH_contract).totalSupply()-SASH_total_allocation_distributed) / 1e6 * (SASH_budget_ppm - SASH_allocation_distributed_ppm));
        ISigmoidTokens(SASH_contract).mint(_to, SASH_amount);
        SASH_total_allocation_distributed += SASH_amount;
        
        return(true);

    }

    function getClassInfo(uint256 poposal_class) public view override returns(uint256 timelock, uint256 minimum_approval, uint256 minimum_vote, uint256 need_architect_veto, uint256 maximum_execution_time, uint256 minimum_execution_interval){
        timelock=_proposalClassInfo[poposal_class][0];
        minimum_approval=_proposalClassInfo[poposal_class][1];
        minimum_vote=_proposalClassInfo[poposal_class][2];
        need_architect_veto=_proposalClassInfo[poposal_class][3];
        maximum_execution_time=_proposalClassInfo[poposal_class][4];
        minimum_execution_interval=_proposalClassInfo[poposal_class][5];

    }
    
    
    function getProposalInfo(uint256 poposal_class, uint256 proposal_nonce) public view override returns(uint256 timestamp, uint256 total_vote, uint256 approve_vote, uint256 architect_veto, uint256 execution_left, uint256 execution_interval){
        timestamp=_proposalVoting[poposal_class][proposal_nonce][0];
        total_vote=_proposalVoting[poposal_class][proposal_nonce][1];
        approve_vote=_proposalVoting[poposal_class][proposal_nonce][2];
        architect_veto=_proposalVoting[poposal_class][proposal_nonce][3];  //0=no vote, 1=approval, 2=veto
        execution_left=_proposalVoting[poposal_class][proposal_nonce][4];
        execution_interval=_proposalVoting[poposal_class][proposal_nonce][5];
        
    }
    
    function vote(uint256 poposal_class, uint256 proposal_nonce, bool approval, uint256 _amount) public override returns(bool){
        require( ISigmoidBank(bank_contract).buyVoteBondWithSGM(msg.sender, msg.sender, _amount));
        require( _proposalVoting[poposal_class][proposal_nonce][0] + _proposalClassInfo[poposal_class][0] > now);
        if (approval == true){
            _proposalVoting[poposal_class][proposal_nonce][1]+=_amount;
            _proposalVoting[poposal_class][proposal_nonce][2]+=_amount;
        }
        else {
            _proposalVoting[poposal_class][proposal_nonce][1]+=_amount;
        }
        return(true);
          
    }
    
    function veto(uint256 poposal_class, uint256 proposal_nonce, bool approval) public override returns(bool){
        require( _proposalVoting[poposal_class][proposal_nonce][0] + _proposalClassInfo[poposal_class][0] > now);
          require(msg.sender == dev_address,"msg.sender is not dev_address");
        if (approval == true){
            _proposalVoting[poposal_class][proposal_nonce][3] = 1;
        }
        
        if (approval == false){
            _proposalVoting[poposal_class][proposal_nonce][3] = 2;
        }
        return(true);
          
    }
     
    function createProposal(uint256 poposal_class, address proposal_address, uint256 proposal_execution_nonce, uint256 proposal_execution_interval) public override returns(bool){
        require(initialized == true);
        _proposalNonce[poposal_class]+=1;
        _proposalVoting[poposal_class][_proposalNonce[poposal_class]][0] = now;
        _proposalAddress[poposal_class][_proposalNonce[poposal_class]] = proposal_address;
        _proposalVoting[poposal_class][_proposalNonce[poposal_class]][4] = proposal_execution_nonce;
        _proposalVoting[poposal_class][_proposalNonce[poposal_class]][5] = proposal_execution_interval;
        return(true);
          
    }
    
    function revokeProposal(uint256 poposal_class, uint256 proposal_nonce, uint256 revoke_poposal_class, uint256 revoke_proposal_nonce) public override returns(bool){
        require(initialized == true);
        require(poposal_class <= revoke_poposal_class);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        _proposalVoting[revoke_poposal_class][revoke_proposal_nonce][4] = 0;
        return(true);
          
    }
    
    function checkProposal(uint256 poposal_class, uint256 proposal_nonce) public view override returns(bool){
        require( _proposalVoting[poposal_class][proposal_nonce][0] + _proposalClassInfo[poposal_class][0] < now , "Wait");
        uint256 aproval_vote_percentage = _proposalVoting[poposal_class][proposal_nonce][2]*100/_proposalVoting[poposal_class][proposal_nonce][2];
        require(aproval_vote_percentage >= _proposalClassInfo[poposal_class][1], "Vote");
        
        require(_proposalVoting[poposal_class][proposal_nonce][3] <= _proposalClassInfo[poposal_class][3], "Arechitect");
        return(true);

    }
    
    function firstTimeSetContract(address SASH_address,address SGM_address, address bank_address, address bond_address, address exchange_address) public override returns(bool){
        require(initialized == false);
        require(msg.sender == dev_address);
        SASH_contract = SASH_address;
        SGM_contract = SGM_address;
        bank_contract = bank_address;
        bond_contract = bond_address;
        exchange_contract = exchange_address;
        return(true);
    }
    
    function InitializeSigmoid() public override returns(bool){
        require(msg.sender == dev_address || msg.sender == dev_address);
        require(initialized == false);
        require(SASH_contract != address(0));
        require(SGM_contract != address(0));
        require(bank_contract != address(0));
        require(bond_contract != address(0));
        require(exchange_contract != address(0));
        
        ISigmoidBonds(bond_contract).setExchangeContract(exchange_contract);    
        
        ISigmoidBonds(bond_contract).setBankContract(bank_contract);
        ISigmoidTokens(SASH_contract).setBankContract(bank_contract);
        ISigmoidTokens(SGM_contract).setBankContract(bank_contract);
   
        ISigmoidBank(bank_contract).setBondContract(bond_contract);
        
        ISigmoidBonds(bond_contract).isActive(true);
        ISigmoidBank(bank_contract).isActive(true);
        ISigmoidTokens(SASH_contract).isActive(true);
        ISigmoidTokens(SGM_contract).isActive(true);
        
        initialized = true;
        return(true);
      
    } 
    
    function pauseAll(bool _contract_is_active) public override returns(bool){
        require(msg.sender == CSO_address);
        require(initialized == true);
        ISigmoidBonds(bond_contract).isActive(_contract_is_active);
        ISigmoidBank(bank_contract).isActive(_contract_is_active);
        ISigmoidTokens(SASH_contract).isActive(_contract_is_active);
        ISigmoidTokens(SGM_contract).isActive(_contract_is_active);
        
    }
    
    function updateGovernanceContract(uint256 poposal_class, uint256 proposal_nonce, address new_governance_address) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        isActive(false);
        ISigmoidBank(bank_contract).setGovernanceContract(new_governance_address);
        ISigmoidBonds(bond_contract).setGovernanceContract(new_governance_address);
        ISigmoidTokens(SASH_contract).setGovernanceContract(new_governance_address);
        ISigmoidTokens(SGM_contract).setGovernanceContract(new_governance_address);        
        ISigmoidGovernance(new_governance_address).isActive(true);
        return(true);
  
    }
    
    function updateExchangeContract(uint256 poposal_class, uint256 proposal_nonce, address new_exchange_address) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
                
        ISigmoidExchange(exchange_contract).isActive(false);
        exchange_contract=new_exchange_address;

        ISigmoidBonds(exchange_contract).setExchangeContract(new_exchange_address);
        
        ISigmoidExchange(exchange_contract).isActive(true);
        return(true);
  
    }
    
    function updateBankContract(uint256 poposal_class, uint256 proposal_nonce, address new_bank_address) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        
        ISigmoidBank(bank_contract).isActive(false);
        bank_contract=new_bank_address;
        ISigmoidBank(bank_contract).setBankContract(new_bank_address);
        ISigmoidBonds(bond_contract).setBankContract(new_bank_address);
        ISigmoidTokens(SASH_contract).setBankContract(new_bank_address);
        ISigmoidTokens(SGM_contract).setBankContract(new_bank_address);
        ISigmoidBank(bank_contract).isActive(true);
        return(true);
        
    }

    function updateBondContract(uint256 poposal_class, uint256 proposal_nonce, address new_bond_address) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        ISigmoidBonds(bond_contract).isActive(false);
        bond_contract=new_bond_address;        
        ISigmoidBank(bank_contract).setBondContract(new_bond_address);
        ISigmoidBonds(bond_contract).isActive(true);
        
        return(true);
  
    }
    

    function updateTokenContract(uint256 poposal_class, uint256 proposal_nonce, uint256 new_token_class, address new_token_address) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        if (new_token_class == 0){
            ISigmoidTokens(SASH_contract).isActive(false);
            SASH_contract=new_token_address;  
            ISigmoidTokens(SASH_contract).isActive(true);
        }
        
        if (new_token_class == 1){
            ISigmoidTokens(SGM_contract).isActive(false);
            SGM_contract=new_token_address;  
            ISigmoidTokens(SGM_contract).isActive(true);
        }
        
        ISigmoidBank(bank_contract).setTokenContract(new_token_class, new_token_address);
        ISigmoidBonds(bond_contract).setTokenContract(new_token_class, new_token_address);
        
        return(true);
        
    }
    
    function createBondClass(uint256 poposal_class, uint256 proposal_nonce, uint256 bond_class, string memory bond_symbol, uint256 Fibonacci_number, uint256 Fibonacci_epoch) public override returns (bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class, proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        ISigmoidBonds(bond_contract).createBondClass(bond_class, bond_symbol, Fibonacci_number, Fibonacci_epoch);
        return(true);
        
    }
  
    function migratorLP(uint256 poposal_class, uint256 proposal_nonce, address _to, address tokenA, address tokenB) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        require(ISigmoidBank(bank_contract).migratorLP(_to, tokenA, tokenB));
        
        return(true);
    }  
    
    function transferTokenFromGovernance(uint256 poposal_class, uint256 proposal_nonce, address _token, address _to, uint256 _amount) public override returns(bool){
        require(poposal_class <= 2);
        require(checkProposal( poposal_class, proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        require(IERC20(_token).transfer(_to, _amount));
        
        return(true);
        
    }
    
    function claimFundForProposal(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_amount,  uint256 SGM_amount) public override returns(bool){
        require(poposal_class <= 2);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        require(SASH_proposal_claimed + SASH_amount <=(IERC20(SASH_contract).totalSupply()-SASH_total_allocation_distributed)/ 1e6 * (SASH_budget_ppm - SASH_allocation_distributed_ppm));
        ISigmoidTokens(SASH_contract).mint(_to, SASH_amount);
        allocation_minted[_to][0] += SASH_amount;
        SASH_total_allocation_distributed += SASH_amount;
        
        require(SGM_proposal_claimed + SGM_amount <= (IERC20(SGM_contract).totalSupply()-SGM_total_allocation_distributed)/ 1e6 * (SGM_budget_ppm - SGM_allocation_distributed_ppm));
        ISigmoidTokens(SGM_contract).mint(_to, SGM_amount);
        SGM_total_allocation_distributed += SGM_amount;
        
        return(true);

    }
    

    function mintAllocationToken(address _to, uint256 SASH_amount, uint256 SGM_amount) public override returns(bool){
         
        require(allocation_minted[_to][0] + SASH_amount <= (IERC20(SASH_contract).totalSupply()-SASH_total_allocation_distributed)/ 1e6 * (allocation_ppm[_to][0]));
        ISigmoidTokens(SASH_contract).mint(_to, SASH_amount);
        allocation_minted[_to][0] += SASH_amount;
        SASH_total_allocation_distributed += SASH_amount;
        
        require(allocation_minted[_to][1] + SGM_amount <= (IERC20(SGM_contract).totalSupply()-SGM_total_allocation_distributed) / 1e6 * (allocation_ppm[_to][0]));
        ISigmoidTokens(SGM_contract).mint(_to, SGM_amount);
        allocation_minted[_to][1] += SGM_amount;
        SGM_total_allocation_distributed += SGM_amount;

        return(true);

    }
    

    function changeTeamAllocation(uint256 poposal_class, uint256 proposal_nonce, address _to, uint256 SASH_ppm, uint256 SGM_ppm) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        uint256 total_referral_ppm = first_referral_reward_ppm + first_referral_POS_reward_ppm + second_referral_reward_ppm + second_referral_POS_reward_ppm;
        
        require(SASH_allocation_distributed_ppm - allocation_ppm[_to][0] + SASH_ppm <= SASH_budget_ppm - total_referral_ppm);
        allocation_ppm[_to][0] = SASH_ppm;
        SASH_allocation_distributed_ppm=SASH_allocation_distributed_ppm - allocation_ppm[_to][0] + SASH_ppm;
        
        require(SGM_allocation_distributed_ppm  - allocation_ppm[_to][1] + SGM_ppm <= SGM_budget_ppm);
        allocation_ppm[_to][1] = SGM_ppm;
        SGM_allocation_distributed_ppm = SGM_allocation_distributed_ppm - allocation_ppm[_to][1] + SGM_ppm;
        
        return(true);
    
    }
    
    function changeCommunityFundSize(uint256 poposal_class, uint256 proposal_nonce, uint256 new_SGM_budget_ppm, uint256 new_SASH_budget_ppm) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        SASH_budget_ppm = new_SASH_budget_ppm;
        SGM_budget_ppm = new_SGM_budget_ppm;
        
        return(true);
    
    }
    
    function changeReferralPolicy(uint256 poposal_class, uint256 proposal_nonce, uint256 new_1st_referral_reward_ppm, uint256 new_1st_referral_POS_reward_ppm, uint256 new_2nd_referral_reward_ppm, uint256 new_2nd_referral_POS_reward_ppm, uint256 new_first_referral_POS_Threshold_ppm, uint256 new_second_referral_POS_Threshold_ppm) public override returns(bool){
        require(poposal_class <= 1);
        require(checkProposal( poposal_class,  proposal_nonce) == true);
        require(_proposalAddress[poposal_class][_proposalNonce[poposal_class]] == msg.sender);
        _proposalVoting[poposal_class][proposal_nonce][4] -= 1;
        
        first_referral_reward_ppm = new_1st_referral_reward_ppm;
        first_referral_POS_reward_ppm = new_1st_referral_POS_reward_ppm;
        
        second_referral_reward_ppm = new_2nd_referral_reward_ppm;
        second_referral_POS_reward_ppm = new_2nd_referral_POS_reward_ppm;
        
        first_referral_POS_Threshold_ppm = new_first_referral_POS_Threshold_ppm;
        second_referral_POS_Threshold_ppm = new_second_referral_POS_Threshold_ppm;
        return(true);
    
    }
    
    function claimReferralReward(address first_referral, address second_referral, uint256 SASH_total_amount) public override returns(bool){
        require(msg.sender == bank_contract);
        uint256 first_referral_SGM_needed = (IERC20(SASH_contract).totalSupply()-SASH_total_allocation_distributed) /1e6 * first_referral_POS_Threshold_ppm;
        uint256 second_referral_SGM_needed = (IERC20(SASH_contract).totalSupply()-SASH_total_allocation_distributed) /1e6 * second_referral_POS_Threshold_ppm;
        uint256 first_referral_reward_size = SASH_total_amount / 1e6 * first_referral_reward_ppm;
        uint256 first_referral_POS_reward_size = SASH_total_amount / 1e6 * first_referral_POS_reward_ppm / 1e6 * ( IERC20(SGM_contract).balanceOf(first_referral) * 1e5 / first_referral_SGM_needed);
        uint256 second_referral_reward_size = SASH_total_amount / 1e6 * second_referral_reward_ppm;
        uint256 second_referral_POS_reward_size = SASH_total_amount / 1e6 * second_referral_POS_reward_ppm / 1e6 * ( IERC20(SGM_contract).balanceOf(second_referral) * 1e5 / second_referral_SGM_needed);
        
        
        if(first_referral_POS_reward_size > SASH_total_amount / 1e6 * first_referral_POS_reward_ppm){
            first_referral_POS_reward_size = SASH_total_amount / 1e6 * first_referral_POS_reward_ppm;  
       
        } 
        
        if(second_referral_POS_reward_size > SASH_total_amount / 1e6 * second_referral_POS_reward_ppm){
            second_referral_POS_reward_size =  SASH_total_amount / 1e6 * second_referral_POS_reward_ppm;  
       
        } 
        
        if(IERC20(SGM_contract).balanceOf(first_referral) > first_referral_SGM_needed){
            _mintReferralReward(first_referral, first_referral_reward_size+first_referral_POS_reward_size);
        
        }
        
        if(IERC20(SGM_contract).balanceOf(second_referral) > second_referral_SGM_needed){
            _mintReferralReward(second_referral, second_referral_reward_size + second_referral_POS_reward_size);
        
        }
        
        return(true);
    }
    
    function getReferralPolicy(uint256 index) public view override returns(uint256){
        if(index == 0){
            return(first_referral_reward_ppm);
        }
        
        if(index == 1){
            return(first_referral_POS_reward_ppm);
        }
        
        if(index == 2){
            return(second_referral_reward_ppm);
        }
        
        if(index == 3){
            return(second_referral_POS_reward_ppm);
        }
        
        if(index == 4){
            return(first_referral_POS_Threshold_ppm);
        }
        
        if(index == 5){
            return(second_referral_POS_Threshold_ppm);
        }
    }
}