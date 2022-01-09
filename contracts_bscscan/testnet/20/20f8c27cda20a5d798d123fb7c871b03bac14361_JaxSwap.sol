// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ref/PancakeRouter.sol";
import "./lib/Initializable.sol";
import "./JaxLibrary.sol";
import "./JaxOwnable.sol";

interface IJaxSwap {
  event Set_Jax_Admin(address jax_admin);
  event Set_Token_Addresses(address wjxn, address wjax, address vrp, address jusd);
  event Swap_Wjxn_Wjax(uint amount);
  event Swap_Wjax_Wjxn(uint amount);
  event Swap_WJXN_VRP(address account, uint wjxn_amount, uint vrp_amount);
  event Swap_WJAX_JUSD(address account, uint amountIn, uint amountOut);
  event Swap_VRP_WJXN(address account, uint vrp_amount, uint wjxn_amount);
  event Swap_JUSD_WJAX(address account, uint amountIn, uint amountOut);
  event Swap_JToken_JUSD(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_JUSD_JToken(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_JToken_BUSD(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_BUSD_JToken(address jtoken, address account, uint amountIn, uint amountOut);
}

interface IJaxAdmin {

  struct JToken{
    uint jusd_ratio;
    uint markup_fee;
    address markup_fee_wallet;
    string name;
  }

  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function system_status () external view returns (uint);

  function priceImpactLimit() external view returns (uint);

  function show_reserves() external view returns(uint, uint, uint);
  function get_wjxn_wjax_ratio(uint withdrawal_amount) external view returns (uint);
  function wjax_usd_ratio() external view returns (uint);
  function get_wjxn_vrp_ratio() external view returns (uint);
  function get_vrp_wjxn_ratio() external view returns (uint);
  function use_wjax_usd_dex_pair() external view returns (uint);
  function wjxn_usd_ratio() external view returns (uint);
  function use_wjxn_usd_dex_pair() external view returns (uint);
  function wjxn_wjax_collateralization_ratio() external view returns (uint);
  function wjax_collateralization_ratio() external view returns (uint);
  function get_wjax_jusd_ratio() external view returns (uint);
  function freeze_vrp_wjxn_swap() external view returns (uint);
  function jtokens(address jtoken_address) external view returns (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, string memory name);
  
  function wjax_jusd_markup_fee() external view returns (uint);
  function wjax_jusd_markup_fee_wallet() external view returns (address);
  function blacklist(address _user) external view returns (bool);
}

contract JaxSwap is IJaxSwap, Initializable, JaxOwnable {
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  using JaxLibrary for JaxSwap;

  IJaxAdmin public jaxAdmin;
  IPancakeRouter01 router;

  IERC20 public wjxn;
  IERC20 public busd;
  IERC20 public wjax;
  IERC20 public vrp; 
  IERC20 public jusd;

  mapping (address => uint) public wjxn_wjax_ratios;

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Not_Admin"); //Only Admin can perform this operation.
    _;
  }

  modifier onlyGovernor() {
    require(jaxAdmin.userIsGovernor(msg.sender), "Not_Governor"); //Only Governor can perform this operation.
    _;
  }

  modifier onlyAjaxPrime() {
    require(jaxAdmin.userIsAjaxPrime(msg.sender), "Not_AjaxPrime"); //Only AjaxPrime can perform this operation.
    _;
  }

  modifier isActive() {
      require(jaxAdmin.system_status() == 2, "Swap_Paused"); //Swap has been paused by Admin.
      _;
  }

  modifier notContract() {
    uint256 size;
    address addr = msg.sender;
    assembly {
        size := extcodesize(addr)
    }
    require((size == 0) && (msg.sender == tx.origin),
          "Contract_Call_Not_Allowed"); //Only non-contract/eoa can perform this operation
    _;
  }

  function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
    jaxAdmin = IJaxAdmin(newJaxAdmin);
    jaxAdmin.system_status();
    emit Set_Jax_Admin(newJaxAdmin);
  }

  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) external {
    require(msg.sender == address(jaxAdmin), "Only JaxAdmin Contract");
    busd = IERC20(_busd);
    busd.approve(address(router), type(uint).max);
    wjxn = IERC20(_wjxn);
    wjax = IERC20(_wjax);
    vrp = IERC20(_vrp);
    jusd = IERC20(_jusd);
    wjxn.approve(address(router), type(uint).max);
    wjax.approve(address(router), type(uint).max);
    emit Set_Token_Addresses(_wjxn, _wjax, _vrp, _jusd);
  }

  function swap_wjxn_wjax(uint amount) external onlyGovernor {
    address[] memory path = new address[](2);
    path[0] = address(wjxn);
    path[1] = address(wjax);
    JaxLibrary.swapWithPriceImpactLimit(address(router), amount, jaxAdmin.priceImpactLimit(), path, address(this));
    
    (uint wjax_lsc_ratio, ,) = jaxAdmin.show_reserves();
    
    require(wjax_lsc_ratio/1e10 <= jaxAdmin.wjax_collateralization_ratio() * 110 / 100, "Unable to swap as collateral is fine"); //Unable to withdraw as collateral is fine.
    emit Swap_Wjxn_Wjax(amount);
  }

  function swap_wjax_wjxn(uint amount) external onlyGovernor {
    // require(validate_wjax_withdrawal(_amount) == true, "validate_wjax_withdrawal failed");

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(wjxn);
    JaxLibrary.swapWithPriceImpactLimit(address(router), amount, jaxAdmin.priceImpactLimit(), path, address(this));
    
    (uint wjax_lsc_ratio, ,) = jaxAdmin.show_reserves();
    
    require(wjax_lsc_ratio/1e10 >= jaxAdmin.wjax_collateralization_ratio(), "Low Reserves");

    emit Swap_Wjax_Wjxn(amount);
  }

  function swap_wjxn_vrp(uint amountIn) external isActive returns (uint) {
    require(amountIn > 0, "Zero AmountIn"); //WJXN amount must not be zero.
    require(!jaxAdmin.blacklist(msg.sender), "blacklisted");
    require(wjxn.balanceOf(msg.sender) >= amountIn, "Insufficient WJXN");

    // Set wjxn_wjax_ratio of sender 
    uint wjxn_wjax_ratio_now = jaxAdmin.get_wjxn_wjax_ratio(0);
    uint wjxn_wjax_ratio_old = wjxn_wjax_ratios[msg.sender];
    if(wjxn_wjax_ratio_old < wjxn_wjax_ratio_now)
        wjxn_wjax_ratios[msg.sender] = wjxn_wjax_ratio_now;

    uint vrp_to_be_minted = amountIn * jaxAdmin.get_wjxn_vrp_ratio();
    wjxn.transferFrom(msg.sender, address(this), amountIn);
    vrp.mint(msg.sender, vrp_to_be_minted);
    emit Swap_WJXN_VRP(msg.sender, amountIn, vrp_to_be_minted);
    return vrp_to_be_minted;
  }

  function swap_vrp_wjxn(uint amountIn) external isActive returns (uint) {
    require(jaxAdmin.freeze_vrp_wjxn_swap() == 0, "Freeze VRP-WJXN Swap"); //VRP-WJXN exchange is not allowed now.
    require(!jaxAdmin.blacklist(msg.sender), "blacklisted");
    require(amountIn > 0, "Zero AmountIn");
    require(vrp.balanceOf(msg.sender) >= amountIn, "Insufficient VRP");
    require(wjxn.balanceOf(address(this))> 0, "No Reserves.");
    uint wjxn_to_be_withdrawn = amountIn * jaxAdmin.get_vrp_wjxn_ratio() / (10 ** (18 * 2));
    require(wjxn_to_be_withdrawn >= 1, "Min Amount for withdrawal is 1 WJXN."); 
    require(wjxn.balanceOf(address(this))>= wjxn_to_be_withdrawn, "Insufficient WJXN");

    // check wjxn_wjax_ratio of sender 
    uint wjxn_wjax_ratio_now = jaxAdmin.get_wjxn_wjax_ratio(wjxn_to_be_withdrawn);

    require(wjxn_wjax_ratio_now >= jaxAdmin.wjxn_wjax_collateralization_ratio(), "Low Reserves"); //Unable to withdraw as reserves are low.
    // require(wjxn_wjax_ratios[msg.sender] >= wjxn_wjax_ratio_now, "Unable to withdraw as reserves are low.");

    vrp.burnFrom(msg.sender, amountIn);
    wjxn.transfer(msg.sender, wjxn_to_be_withdrawn);
    emit Swap_VRP_WJXN(msg.sender, amountIn, wjxn_to_be_withdrawn);
    return wjxn_to_be_withdrawn;
  }

  function swap_wjax_jusd(uint amountIn) external isActive{
    // Calculate fee
    uint fee_amount = amountIn * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
		require(wjax.balanceOf(msg.sender) >= amountIn, "Insufficient fund");
    // pay fee
    wjax.transferFrom(msg.sender, jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    wjax.transferFrom(msg.sender, address(this), amountIn - fee_amount);

    uint jusd_amount = (amountIn - fee_amount) * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e18;

    jusd.mint(msg.sender, jusd_amount);
		emit Swap_WJAX_JUSD(msg.sender, amountIn, jusd_amount);
	}

  function swap_jusd_wjax(uint jusd_amount) external isActive returns (uint) {
		require(jusd.balanceOf(msg.sender) >= jusd_amount, "Insufficient jusd");
    uint fee_amount = jusd_amount * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (jusd_amount - fee_amount) * 1e18 * (10 ** wjax.decimals()) / jaxAdmin.get_wjax_jusd_ratio() / (10 ** jusd.decimals());
		require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient reserves");
    jusd.burnFrom(msg.sender, jusd_amount);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    wjax.transfer(msg.sender, wjax_amount);

		emit Swap_JUSD_WJAX(msg.sender, jusd_amount, wjax_amount);
    return wjax_amount;
	}

  function swap_jusd_jtoken(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    uint ratio = jusd_ratio;
    require(ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint256 jtoken_amount = amountIn * ratio / 1e8;
    // Calculate Fee on receiver side
    uint256 jtoken_markup_fee = jtoken_amount * markup_fee / 1e8;
    require(jusd.balanceOf(msg.sender) >= amountIn, "Insufficient JUSD");
    jusd.burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    uint amountOut = jtoken_amount-jtoken_markup_fee;
    IERC20(jtoken).mint(markup_fee_wallet, jtoken_markup_fee);
    IERC20(jtoken).mint(msg.sender, amountOut);
    emit Swap_JUSD_JToken(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
  }

  function swap_jtoken_jusd(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    uint ratio = jusd_ratio;
    require(ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint jusd_amountOut = amountIn * 1e8 / ratio;
    uint jusd_markup_fee = jusd_amountOut * markup_fee / 1e8;
    require(IERC20(jtoken).balanceOf(msg.sender) >= amountIn, "Insufficient JTOKEN");
    IERC20(jtoken).burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    uint amountOut = jusd_amountOut - jusd_markup_fee;
    jusd.mint(markup_fee_wallet, jusd_markup_fee);
    jusd.mint(msg.sender, amountOut);
    emit Swap_JToken_JUSD(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
  }

  function swap_jtoken_busd(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    require(jusd_ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint jusd_amountOut = amountIn * 1e8 / jusd_ratio;
    uint jusd_markup_fee = jusd_amountOut * markup_fee / 1e8;
    require(IERC20(jtoken).balanceOf(msg.sender) >= amountIn, "Insufficient Jtoken");
    IERC20(jtoken).burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    // uint jusd_amount = jusd_amountOut-jusd_markup_fee;
    jusd.mint(markup_fee_wallet, jusd_markup_fee);
    // jusd.mint(msg.sender, amountOut);

       
    uint fee_amount = (jusd_amountOut - jusd_markup_fee) * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (jusd_amountOut - jusd_markup_fee - fee_amount) * (10 ** wjax.decimals()) * 1e18 / (10 ** jusd.decimals()) / jaxAdmin.get_wjax_jusd_ratio();
		require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient reserves");
    // jusd.burnFrom(msg.sender, jusd_amount);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    // wjax.transfer(msg.sender, wjax_amount);

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(busd);

    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), wjax_amount, jaxAdmin.priceImpactLimit(), path, msg.sender);
    
		emit Swap_JToken_BUSD(jtoken, msg.sender, amountIn, amounts[1]);
    return amounts[1];
  }

  function swap_busd_jtoken(address jtoken, uint amountIn) external isActive returns(uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    require(jusd_ratio > 0, "Invalid JUSD-Ratio");
    require(busd.balanceOf(msg.sender)>=amountIn, "Insufficient BUSD");
    busd.transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(busd);
    path[1] = address(wjax);
    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amountIn, jaxAdmin.priceImpactLimit(), path, address(this));
    // Calculate fee
    uint wjax_fee = amounts[1] * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
    // pay fee
    uint wjax_amountOut = amounts[1] - wjax_fee;
    wjax.transfer(jaxAdmin.wjax_jusd_markup_fee_wallet(), wjax_fee);
    // wjax.transferFrom(msg.sender, address(this), wjax_amountOut);

    uint jusd_amount = wjax_amountOut * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e18;

    // jusd.mint(msg.sender, jusd_amount);

    uint jtoken_amount = jusd_amount * jusd_ratio / 1e8;
    // Calculate Fee on receiver side
    uint jtoken_markup_fee = jtoken_amount * markup_fee / 1e8;
    // jusd.burnFrom(msg.sender, jusd_amount);
    // The recipient has to pay fee. 
    uint amountOut = jtoken_amount-jtoken_markup_fee;
    IERC20(jtoken).mint(markup_fee_wallet, jtoken_markup_fee);
    IERC20(jtoken).mint(msg.sender, amountOut);

		emit Swap_BUSD_JToken(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
	}

  function swap_jusd_busd(uint amountIn) external isActive returns (uint) {
    uint fee_amount = amountIn * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (amountIn - fee_amount) * 1e18 * (10 ** wjax.decimals()) / jaxAdmin.get_wjax_jusd_ratio() / (10 ** jusd.decimals());
    
    require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient WJAX fund");
    require(jusd.balanceOf(msg.sender) >= amountIn, "Insufficient JUSD");

    jusd.burnFrom(msg.sender, amountIn);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    // wjax.transfer(msg.sender, wjax_amount);

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(busd);

    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), wjax_amount, jaxAdmin.priceImpactLimit(), path, msg.sender);
    return amounts[1];
  } 
  
  function swap_busd_jusd(uint amountIn) external isActive{
		require(busd.balanceOf(msg.sender) >= amountIn, "Insufficient Busd fund");
    busd.transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(busd);
    path[1] = address(wjax);
    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amountIn, jaxAdmin.priceImpactLimit(), path, address(this));
    // Calculate fee
    uint wjax_fee = amounts[1] * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
    // pay fee
    wjax.transfer(jaxAdmin.wjax_jusd_markup_fee_wallet(), wjax_fee);
    // wjax.transferFrom(msg.sender, address(this), amounts[1] - wjax_fee);

    uint jusd_amount = (amounts[1] - wjax_fee) * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e18;

    jusd.mint(msg.sender, jusd_amount);
		emit Swap_WJAX_JUSD(msg.sender, amountIn, jusd_amount);
	}

  function initialize(address _jaxAdmin, address pancakeRouter) external initializer {

    // wjax_jusd_markup_fee_wallet = msg.sender;

    router = IPancakeRouter01(pancakeRouter);
    jaxAdmin = IJaxAdmin(_jaxAdmin);

    owner = msg.sender;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}
}

/**
 *Submitted for verification at BscScan.com on 2021-04-23
*/
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

// File: @uniswap\lib\contracts\libraries\TransferHelper.sol

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

// File: contracts\interfaces\IPancakeRouter01.sol

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts\interfaces\IPancakeRouter02.sol

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts\interfaces\IPancakeFactory.sol

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\libraries\SafeMath.sol

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, 'ds-math-div-zero');
        z = x / y;
    }
}

// File: contracts\interfaces\IPancakePair.sol

interface IPancakePair {
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

// File: contracts\libraries\PancakeLibrary.sol



library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(uint160(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         factory,
        //         keccak256(abi.encodePacked(token0, token1)),
        //         hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
        //     )))));
        pair = IPancakeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts\interfaces\IERC20.sol

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\interfaces\IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\PancakeRouter.sol







contract PancakeRouter is IPancakeRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPancakePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(to);
        (address token0,) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPancakePair(PancakeLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return PancakeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return PancakeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return PancakeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PancakeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PancakeLibrary.getAmountsIn(factory, amountOut, path);
    }
}



/**
 *Submitted for verification at BscScan.com on 2020-09-03
*/

contract WETH {
    string public name     = "Wrapped BNB";
    string public symbol   = "WBNB";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return balanceOf[address(this)];
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

import "./ref/PancakeRouter.sol";

library JaxLibrary {

  function swapWithPriceImpactLimit(address router, uint amountIn, uint limit, address[] memory path, address to) internal returns(uint[] memory) {
    IPancakeRouter01 pancakeRouter = IPancakeRouter01(router);
    
    IPancakePair pair = IPancakePair(IPancakeFactory(pancakeRouter.factory()).getPair(path[0], path[1]));
    (uint res0, uint res1, ) = pair.getReserves();
    uint reserveIn;
    uint reserveOut;
    if(pair.token0() == path[0]) {
      reserveIn = res0;
      reserveOut = res1;
    } else {
      reserveIn = res1;
      reserveOut = res0;
    }
    uint amountOut = pancakeRouter.getAmountOut(amountIn, reserveIn, reserveOut);
    require((reserveOut * 1e18 / reserveIn) * (1e8 - limit) / 1e8 <= amountOut * 1e18 / amountIn, "Price Impact too high");
    return pancakeRouter.swapExactTokensForTokens(amountIn, 0, path, to, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract JaxOwnable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
      require(owner == msg.sender, "JaxOwnable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Internal function without access restriction.
  */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}