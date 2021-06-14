/**
 *Submitted for verification at Etherscan.io on 2021-06-14
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
library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC659 {
    function totalSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function activeSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function burnedSupply( uint256 class, uint256 nonce) external view returns (uint256);
    function redeemedSupply(  uint256 class, uint256 nonce) external  view  returns (uint256);
    
    function batchActiveSupply( uint256 class ) external view returns (uint256);
    function batchBurnedSupply( uint256 class ) external view returns (uint256);
    function batchRedeemedSupply( uint256 class ) external view returns (uint256);
    function batchTotalSupply( uint256 class ) external view returns (uint256);

    function getNonceCreated(uint256 class) external view returns (uint256[] memory);
    function getClassCreated() external view returns (uint256[] memory);
    
    function balanceOf(address account, uint256 class, uint256 nonce) external view returns (uint256);
    function batchBalanceOf(address account, uint256 class) external view returns(uint256[] memory);
    
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

interface ISigmoidTokens {

    function isActive(bool _contract_is_active) external returns (bool);
    function setPhase(uint256 phase) external returns (bool);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function maximumSupply() external view returns (uint256);
    function AirdropedSupply() external  view returns (uint256);
    function lockedBalance(address account) external view returns (uint256);
    function checkLockedBalance(address account, uint256 amount) external view returns (bool);
    
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setExchangeContract(address exchange_addres) external returns (bool);
    
    function setAirdropedSupply(uint256 total_airdroped_supply) external returns (bool);
    
    function mint(address _to, uint256 _amount) external returns (bool);
    function mintAllocation(address _to, uint256 _amount) external returns (bool);
    function mintAirdrop(address _to, uint256 _amount) external returns (bool);
    
    function bankTransfer(address _from, address _to, uint256 _amount) external returns (bool);
}

interface ISigmoidGovernance{
    function getClassInfo(uint256 poposal_class) external view returns(uint256 timelock, uint256 minimum_approval, uint256 minimum_vote, uint256 need_architect_veto, uint256 maximum_execution_time, uint256 minimum_execution_interval);
    function getProposalInfo(uint256 poposal_class, uint256 proposal_nonce) external view returns(uint256 timestamp, uint256 total_vote, uint256 approve_vote, uint256 architect_veto, uint256 execution_left, uint256 execution_interval);
    
    function vote(uint256 poposal_class, uint256 proposal_nonce, bool approval, uint256 _amount) external returns(bool);
    function createProposal(uint256 poposal_class, address proposal_address, uint256 proposal_execution_nonce, uint256 proposal_execution_interval) external returns(bool);
    function revokeProposal(uint256 poposal_class, uint256 proposal_nonce, uint256 revoke_poposal_class, uint256 revoke_proposal_nonce) external returns(bool);
    function checkProposal(uint256 poposal_class, uint256 proposal_nonce) external view returns(bool);
    
    function firstTimeSetContract(address SASH_address,address SGM_address, address bank_address,address bond_address) external returns(bool);
    function InitializeSigmoid() external returns(bool);
    function pauseAll() external returns(bool);
    
    function updateGovernanceContract(uint256 poposal_class, uint256 proposal_nonce, address new_governance_address) external returns(bool);
    function updateExchangeContract(uint256 poposal_class, uint256 proposal_nonce, address new_exchange_address) external returns(bool);
    function updateBankContract(uint256 poposal_class, uint256 proposal_nonce, address new_bank_address) external returns(bool);
    function updateBondContract(uint256 poposal_class, uint256 proposal_nonce, address new_bond_address) external returns(bool);
    function updateTokenContract(uint256 poposal_class, uint256 proposal_nonce, uint256 new_token_class, address new_token_address) external returns(bool);
    
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

interface ISigmoidBank{
    function isActive(bool _contract_is_active) external returns (bool);
    function setPhase(uint256 phase) external returns (bool);
    function setGovernanceContract(address governance_address) external returns (bool);
    function setBankContract(address bank_address) external returns (bool);
    function setBondContract(address bond_address) external returns (bool);
    function setTokenContract(uint256 token_class, address token_address) external returns (bool);
   
    function addStablecoinToList(address contract_address) external returns (bool);
    function checkIntheList(address contract_address) view external returns (bool);
    function migratorLP(address _to, address tokenA, address tokenB) external returns (bool);

    
    function powerX(uint256 power_root, uint256 num,uint256 num_decimals)  pure external returns (uint256);
    function logX(uint256 log_root,uint256 log_decimals, uint256 num)  pure external returns (uint256);
    
    function getBondExchangeRateTokentoSASH(uint256 amount_in, address[] calldata path) view external returns (uint256);
    function getBondExchangeRateETHtoSASH(uint256 amount_in, address[] calldata path) view external returns (uint256);
    function getBondExchangeRateSASHtoUSD(uint256 amount_SASH_out) view external returns (uint256);
    function getBondExchangeRateUSDtoSASH(uint256 amount_USD_in) view external returns (uint256);
    function getBondExchangeRatSGMtoSASH(uint256 amount_SGM_out) view external returns (uint256);
    function getBondExchangeRateSASHtoSGM(uint256 amount_SASH_in) view external returns (uint256);
    
    function buySASHBondWithETH(address _to, uint amountOutMin, address[] calldata path) external payable  returns (uint[] memory amounts);
    function buySASHBondWithToken(address contract_address, address _to, uint amountIn, uint amountOutMin, address[] calldata path) external returns (uint[] memory amounts);
   
    function buyWhitelistSASHBondWithUSD(bytes32[] calldata proof, address contract_address, uint256 index, address _to, uint256 amount, uint256 amount_USD_in) external returns (bool);
    function buySASHBondWithUSD(address contract_address, address _to, uint256 amount_USD_in) external returns (bool);
    function buySGMBondWithSASH(address _to, uint256 amount_SASH_in) external returns (bool);
    function buyVoteBondWithSGM(address _from, address _to, uint256 amount_SGM_in) external returns (bool);
    
   function redeemBond(address _to, uint256 class, uint256[] calldata nonce, uint256[] calldata _amount, address first_referral, address second_referral) external returns (bool);
}

contract swap {
   
    // functions to convert any tokens to usd automatically

    address public WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public SwapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public SwapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }
    
    
   function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(SwapFactoryAddress, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(SwapFactoryAddress, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn*9975;
        uint numerator = amountInWithFee*reserveOut;
        uint denominator = reserveIn*10000+amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    function getAmountsOut( uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            address pair_address= IUniswapV2Factory(SwapFactoryAddress).getPair(path[i],path[i+1]);
            
            (uint reserveIn, uint reserveOut,) = IUniswapV2Pair(pair_address).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
    
}
    
contract SigmoidBank is ISigmoidBank,swap{
    address public dev_address;     
    uint public phase_now;
    bytes32 public merkleRoot;
    mapping (address=>bool) public whitelistClaimed;
    bool public merkleRoot_set;
    
    // the address of other Sigmoid protocol contracts
    address public SASH_contract;
    address public SGM_contract;
    address public governance_contract;
    address public bank_contract;
    address public bond_contract;
    
    bool public contract_is_active;

    mapping (uint256 => address) public token_contract;
    address[] public USD_token_list;

   
    constructor() public {
        
        }
    
    //check if the contract is paused
    function isActive(bool _contract_is_active) public override returns (bool){
         contract_is_active = _contract_is_active;
         return(contract_is_active);
    }
    
    //set the phase of the contract, used only during first launch
    function setPhase(uint256 phase) public override returns (bool){
        require(merkleRoot_set==true);
        require( phase== phase_now+1);
        require(msg.sender == governance_contract);
        phase_now +=1;
        return(true);
    }

    //set the merkle proof of whitelist, used only during first launch
    function setMerkleRoot(bytes32 root) public  returns (bool){
        require(msg.sender == dev_address);
        require(phase_now ==0);
        merkleRoot_set = true;
        merkleRoot=root;
        return true;
    }
    
    // merkle proof verifier, used only during first launch
    function merkleVerify(bytes32[] memory proof, bytes32 root, bytes32 leaf) private pure returns (bool) {
        bytes32 computedHash = leaf;
    
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
    
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
    
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
  
    //update governance contract, can only be called from old governance contract
    function setGovernanceContract(address governance_address) public override returns (bool) {
        require(msg.sender==governance_contract);
        governance_contract = governance_address;
        return(true);
    }
    
    //update bank contract, can only be called from governance contract
    function setBankContract(address bank_address) public override returns (bool) {
        require(msg.sender==governance_contract);
        bank_contract = bank_address;
        return(true);
    }
    
    //update bond contract, can only be called from governance contract
    function setBondContract(address bond_address)public override returns (bool) {
        require(msg.sender==governance_contract, "ERC659: operator unauthorized");
        bond_contract=bond_address;
        return (true);
    }   
      
    //update SASH or SGM erc20 token contract, can only be called from governance contract
    function setTokenContract(uint256 class, address contract_address) public override returns (bool) {
        require(msg.sender==governance_contract);
        
        if (class == 0){
            SASH_contract=contract_address;  
        }
        
        if (class == 1){
            SGM_contract=contract_address;  
        }
        
        token_contract[class] = contract_address;
        return(true);
    }
        
    //check if a token is recognised as stable coin by the contract
    function checkIntheList(address contract_address) view public override returns (bool){
        for (uint i=0; i<USD_token_list.length; i++) {
        if(USD_token_list[i]==contract_address){
            return(true);
            }
        }
        return(false);
    }
    
    //recognise new stable stable coin
    function addStablecoinToList(address contract_address) public override returns (bool) {
        require(msg.sender == governance_contract);
        require(checkIntheList(contract_address) == false);
        USD_token_list.push(contract_address);
        if(IUniswapV2Factory(SwapFactoryAddress).getPair(contract_address,token_contract[0])==address(0)){  
            IUniswapV2Factory(SwapFactoryAddress).createPair(contract_address,token_contract[0]);
        }
        
        return(true);
    }
    
    //LP migration
    function migratorLP(address _to, address tokenA, address tokenB) public override returns (bool){
         require(msg.sender == governance_contract);
         address pair_addrss = IUniswapV2Factory(SwapFactoryAddress).getPair(tokenA, tokenB);
         IUniswapV2Pair(pair_addrss).transfer(_to, IUniswapV2Pair(pair_addrss).balanceOf(address(this)));
         return(true);
    }
    
    //pure mathematical function, power of
    function powerX(uint256 power_root, uint256 num,uint256 num_decimals) pure public override returns (uint256) {
        return(num**power_root*1e3/((10**num_decimals)**power_root));
            }
    
    //pure mathematical function, log of
    function logX(uint256 log_root,uint256 log_decimals, uint256 num)  pure public override returns (uint256) {
        for (uint i=1; i<224; i++) {
            if(num/(log_root**i/((10**log_decimals)**i))<1){
            return(i-1);
            }
        }
    }

    //get the projected exchange rate of a token to SASH
    function getBondExchangeRateTokentoSASH(uint256 amount_in, address[] memory path) view public override returns (uint){
        require(path.length == 3);
        uint256[] memory amounts= getAmountsOut (amount_in, path);
        
        uint256 amount_USD_in = amounts[amounts.length-1];
        require (amount_USD_in >= 1e18, "Amount must be higher than 1 USD.");
        uint256 supply_multiplier = IERC20(token_contract[0]).totalSupply()/1e24;
        uint256 supply_multiplier_power = logX(16,1,supply_multiplier);
        return(amount_USD_in*1e3/powerX(supply_multiplier_power,11,1));
    }
   
    //get the projected exchange rate of a ETH(BNB) to SASH
    function getBondExchangeRateETHtoSASH(uint256 amount_in, address[] memory path) view public override returns (uint){
        require(path[0] == WETH, 'INVALID_PATH');
        require(path.length == 2);
        uint256[] memory amounts = getAmountsOut (amount_in, path);
        
        uint256 amount_USD_in = amounts[amounts.length-1];
        require (amount_USD_in >= 1e18, "Amount must be higher than 1 USD.");
        uint256 supply_multiplier = IERC20(token_contract[0]).totalSupply()/1e24;
        uint256 supply_multiplier_power = logX(16,1,supply_multiplier);
        return(amount_USD_in*1e3/powerX(supply_multiplier_power,11,1));
    }
    
    //get the projected exchange rate of SASH to USD
    function getBondExchangeRateSASHtoUSD(uint256 amount_SASH_out) view public override returns (uint256){
        uint256 supply_multiplier=IERC20(token_contract[0]).totalSupply()/1e24;
        uint256 supply_multiplier_power= logX(16,1,supply_multiplier);
        return(powerX(supply_multiplier_power,11,1)*amount_SASH_out/1e3);
    }
    
    //get the projected exchange rate of USD to SASH
    function getBondExchangeRateUSDtoSASH(uint256 amount_USD_in) view public override returns (uint256){
        require(amount_USD_in>=1e18, "Amount must be higher than 1 USD.");
        uint256 supply_multiplier=IERC20(token_contract[0]).totalSupply()/1e24;
        uint256 supply_multiplier_power= logX(16,1,supply_multiplier);
        return(amount_USD_in*1e3/powerX(supply_multiplier_power,11,1));
    }
    
    //get the projected exchange rate of SGM to SASH
    function getBondExchangeRatSGMtoSASH(uint256 amount_SGM_out) view public override returns (uint256){
        uint256 maximum_supply_SGM = ISigmoidTokens(SGM_contract).maximumSupply();
        uint256 supply_multiplier = IERC20(SGM_contract).totalSupply()*1e6/maximum_supply_SGM;
        uint256 supply_multiplier_rate = 1000 + supply_multiplier**2/1e6;
        return(amount_SGM_out*supply_multiplier_rate);       
    }
    
    //get the projected exchange rate of SASH to SGM
    function getBondExchangeRateSASHtoSGM(uint256 amount_SASH_in) view public override returns (uint256){
        require(amount_SASH_in>=1e18, "Amount must be higher than 1 SASHH.");
        uint256 maximum_supply_SGM = ISigmoidTokens(SGM_contract).maximumSupply();
        uint256 supply_multiplier=IERC20(SGM_contract).totalSupply()*1e6/maximum_supply_SGM;
        uint256 supply_multiplier_rate= 1000+supply_multiplier**2/1e6;
  
        return(amount_SASH_in/supply_multiplier_rate);          
    }
    
    //whitelisted address buy SASH bond with USD during the phase 1
    function buyWhitelistSASHBondWithUSD(bytes32[] memory proof, address contract_address, uint256 index, address _to, uint256 amount, uint256 amount_USD_in) public override returns (bool){
        require(contract_is_active == true);
        require(phase_now == 1);
        bytes32 node = keccak256(abi.encodePacked(index, _to, amount));
        assert(merkleVerify(proof,merkleRoot,node)==true);
        require(amount_USD_in<=amount*1e18);
        require(whitelistClaimed[_to]==false);
        require(checkIntheList(contract_address)==true, "Token does not exist in the list.");
        require(amount_USD_in>=1e18, "Amount must be higher than 1 USD.");
        uint256 amount_bond_out = getBondExchangeRateUSDtoSASH(amount_USD_in);
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(contract_address,SASH_contract);
        require(IERC20(contract_address).transferFrom(msg.sender, pair_addrss, amount_USD_in),'Not enough USD for the deposit.');
        require(ISigmoidTokens(SASH_contract).mint(pair_addrss,amount_bond_out));
        IUniswapV2Pair(pair_addrss).sync;
        IUniswapV2Pair(pair_addrss).mint(address(this));
        IERC659(bond_contract).issueBond(_to, 0, amount_bond_out*2);
        
        whitelistClaimed[_to]=true;
        return(true);
    }
    
    //buy SASH bond with ETH 
    function buySASHBondWithETH(address _to, uint amountOutMin, address[] memory path) public payable override returns (uint[] memory amounts){
  
        require(path[0] == WETH, 'INVALID_PATH');
        require(path[1] == 0xDBC941fEc34e8965EbC4A25452ae7519d6BDfc4e, 'INVALID_PATH');
        require(path.length == 2, 'INVALID_PATH');
        amounts = getAmountsOut( msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        address pair_address= IUniswapV2Factory(SwapFactoryAddress).getPair(path[0],path[1]);
        assert(IWETH(WETH).transfer(pair_address, amounts[0]));
        _swap(amounts, path, _to);
  
    }
    
    //buy SASH bond with token
    function buySASHBondWithToken(address contract_address, address _to, uint amountIn, uint amountOutMin, address[] memory path) public override returns (uint[] memory amounts){
        require(path[0] != WETH, 'INVALID_PATH');
        require(path[1] == WETH, 'INVALID_PATH');
        require(path[2] == USD_token_list[0], 'INVALID_PATH');
        amounts = getAmountsOut( amountIn, path);
        require(path.length==3);
        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');

        address pair_address= IUniswapV2Factory(SwapFactoryAddress).getPair(path[0],path[1]);
        require(IERC20(contract_address).transferFrom(msg.sender, pair_address, amountIn));
        _swap(amounts, path, address(this));
        
        
        pair_address= IUniswapV2Factory(SwapFactoryAddress).getPair(path[0],path[1]);
        assert(IWETH(WETH).transfer(pair_address, amounts[1]));
        _swap(amounts, path, address(this));
        
        uint256 amount_USD_in = amounts[amounts.length-1];
        require(amount_USD_in >= 1e18, "Amount must be higher than 1 USD.");
        uint256 amount_bond_out = getBondExchangeRateUSDtoSASH(amount_USD_in);
        
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(USD_token_list[0],SASH_contract);
        require(IERC20(USD_token_list[0]).transferFrom(msg.sender, pair_addrss, amount_USD_in),'Not enough USD for the deposit.');
        
        require(ISigmoidTokens(SASH_contract).mint(pair_addrss,amount_bond_out));
        IUniswapV2Pair(pair_addrss).sync;
        IUniswapV2Pair(pair_addrss).mint(address(this));
        IERC659(bond_contract).issueBond(_to, 0, amount_bond_out*2);
    }
    
    //buy SASH bond with USD
    function buySASHBondWithUSD(address contract_address, address _to, uint256 amount_USD_in) public override returns (bool){
        require(contract_is_active == true);
        require(phase_now >= 1);
        
        if(phase_now == 1){ 
            require(amount_USD_in >= 48e21);
        }
        
        require(checkIntheList(contract_address)==true, "Token does not exist in the list.");
        require(amount_USD_in>=1e18, "Amount must be higher than 1 USD.");
        uint256 amount_bond_out = getBondExchangeRateUSDtoSASH(amount_USD_in);
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(contract_address,SASH_contract);
        require(IERC20(contract_address).transferFrom(msg.sender, pair_addrss, amount_USD_in),'Not enough USD for the deposit.');
        require(ISigmoidTokens(SASH_contract).mint(pair_addrss,amount_bond_out));
        IUniswapV2Pair(pair_addrss).sync;
        IUniswapV2Pair(pair_addrss).mint(address(this));
        IERC659(bond_contract).issueBond(_to, 0, amount_bond_out*2);
        return(true);
    }
    
    //buy SGM bond with SASH
    function buySGMBondWithSASH(address _to, uint256 amount_SASH_in) public override returns (bool){
        require(contract_is_active == true);
        require(phase_now >= 1);
        require(amount_SASH_in>=1e18, "Amount must be higher than 1 USD.");
        uint256 amount_bond_out = getBondExchangeRateSASHtoSGM(amount_SASH_in);
        uint256 maximum_supply_SGM = ISigmoidTokens(SGM_contract).maximumSupply();
        require(amount_bond_out+IERC20(SGM_contract).totalSupply()<=maximum_supply_SGM, "Cant mint more SGM.");
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(SGM_contract,SASH_contract);
        require(IERC20(token_contract[0]).transferFrom(msg.sender, pair_addrss, amount_SASH_in),'Not enough SASH for the deposit.');
        require(ISigmoidTokens(SGM_contract).mint(pair_addrss,amount_bond_out));
        IUniswapV2Pair(pair_addrss).sync;
        IUniswapV2Pair(pair_addrss).mint(address(this));
        IERC659(bond_contract).issueBond(_to, 1, amount_bond_out*2);
        return(true);
    }
    
    //deposit SGM to vote for a proposal
    function buyVoteBondWithSGM(address _from, address _to, uint256 amount_SGM_in) public override returns (bool){
        require(contract_is_active == true);
        require(phase_now >= 2);
        require(_from == msg.sender || msg.sender == governance_contract);

        uint256 amount_bond_out = getBondExchangeRatSGMtoSASH(amount_SGM_in);
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(SGM_contract,SASH_contract);
        
        address Bigest_LP_address;
        address current_LP_address;
        uint256 Bigest_LP_size;
        uint256 current_LP_size;
        for (uint i=0; i<USD_token_list.length; i++){
            
            current_LP_address = IUniswapV2Factory(SwapFactoryAddress).getPair(USD_token_list[i],SASH_contract);
            current_LP_size = IERC20(USD_token_list[i]).balanceOf(current_LP_address);
            if (Bigest_LP_size < current_LP_size){
                Bigest_LP_size = current_LP_size;
                Bigest_LP_address = current_LP_address;
            }
        }
        
        require(ISigmoidTokens(SASH_contract).bankTransfer(Bigest_LP_address, pair_addrss, amount_bond_out),'Not enough SGM for the deposit.');
        IUniswapV2Pair(Bigest_LP_address).sync;
        require(IERC20(SGM_contract).transferFrom(_from, pair_addrss, amount_SGM_in),'Not enough SGM for the deposit.');
        require(ISigmoidTokens(SASH_contract).mint(pair_addrss,amount_bond_out));
        IUniswapV2Pair(pair_addrss).sync;
        IUniswapV2Pair(pair_addrss).mint(address(this));
        IERC659(bond_contract).issueBond(_to, 2, amount_SGM_in);
        IERC659(bond_contract).issueBond(_to, 3, amount_bond_out);
        return(true);
    }
        
    // redeem bond     
    function redeemBond(address _to, uint256 class, uint256[] memory nonce, uint256[] memory _amount, address first_referral, address second_referral) public override returns (bool){
        require(contract_is_active == true);
        assert( IERC659(bond_contract).redeemBond(msg.sender, class, nonce, _amount));
        uint256 amount_token_mint;
        uint256 amount_SASH_transfer;
        uint256 amount_SGM_transfer;
        
        for (uint i=0; i<_amount.length; i++){
            if(class!=2 && class!=3){
                amount_token_mint+=_amount[i];
            }
            
            if(class==2){
                amount_SGM_transfer += _amount[i];
           
            }
        
            if(class==3){
                amount_SASH_transfer += _amount[i];
           
            }
            
        }
      
        if(amount_token_mint > 0){
              
            ISigmoidTokens(token_contract[class]).mint(_to,amount_token_mint);
            ISigmoidGovernance(governance_contract).claimReferralReward(first_referral, second_referral, amount_token_mint);
       
        }
        
        address pair_addrss=IUniswapV2Factory(SwapFactoryAddress).getPair(SGM_contract,SASH_contract);
        
        if(amount_SGM_transfer > 0){
            
           require(ISigmoidTokens(SGM_contract).bankTransfer(pair_addrss, _to, amount_SGM_transfer));
       
        }
        
        if(amount_SASH_transfer > 0){
            
            require(ISigmoidTokens(SASH_contract).bankTransfer(pair_addrss, _to, amount_SASH_transfer));
       
        }
 
    }
 
    
}