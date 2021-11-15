// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

import "./DEIPool.sol";

contract Pool_USDC is DEIPool {
    address public USDC_address;
    constructor(
        address _dei_contract_address,
        address _deus_contract_address,
        address _collateral_address,
        address _trusty_address,
        address _admin_address,
        uint256 _pool_ceiling,
        address _library
    ) 
    DEIPool(_dei_contract_address, _deus_contract_address, _collateral_address, _trusty_address, _admin_address, _pool_ceiling, _library)
    public {
        require(_collateral_address != address(0), "Zero address detected");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        USDC_address = _collateral_address;
    }
}

//Dar panah khoda

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;
// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= DEIPool =============================
// ====================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Vahid Gh: https://github.com/vahid-dev
// SAYaghoubnejad: https://github.com/SAYaghoubnejad

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../../Uniswap/TransferHelper.sol";
import "../../DEUS/IDEUS.sol";
import "../../DEI/IDEI.sol";
import "../../ERC20/ERC20.sol";
import "../../Governance/AccessControl.sol";
import "./DEIPoolLibrary.sol";

contract DEIPool is AccessControl {

    struct RecollateralizeDEI {
		uint256 collateral_amount;
		uint256 pool_collateral_price;
		uint256[] collateral_price;
		uint256 deus_current_price;
		uint256 expireBlock;
		bytes[] sigs;
    }

	/* ========== STATE VARIABLES ========== */

	ERC20 private collateral_token;
	address private collateral_address;

	address private dei_contract_address;
	address private deus_contract_address;

	uint256 public minting_fee;
	uint256 public redemption_fee;
	uint256 public buyback_fee;
	uint256 public recollat_fee;

	mapping(address => uint256) public redeemDEUSBalances;
	mapping(address => uint256) public redeemCollateralBalances;
	uint256 public unclaimedPoolCollateral;
	uint256 public unclaimedPoolDEUS;
	mapping(address => uint256) public lastRedeemed;

	// Constants for various precisions
	uint256 private constant PRICE_PRECISION = 1e6;
	uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
	uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

	// Number of decimals needed to get to 18
	uint256 private immutable missing_decimals;

	// Pool_ceiling is the total units of collateral that a pool contract can hold
	uint256 public pool_ceiling = 0;

	// Stores price of the collateral, if price is paused
	uint256 public pausedPrice = 0;

	// Bonus rate on DEUS minted during recollateralizeDEI(); 6 decimals of precision, set to 0.75% on genesis
	uint256 public bonus_rate = 7500;

	// Number of blocks to wait before being able to collectRedemption()
	uint256 public redemption_delay = 2;

	// Minting/Redeeming fees goes to daoWallet
	uint256 public daoShare = 0;

	DEIPoolLibrary poolLibrary;

	// AccessControl Roles
	bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
	bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
	bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
	bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	bytes32 public constant DAO_SHARE_COLLECTOR = keccak256("DAO_SHARE_COLLECTOR");
	bytes32 public constant PARAMETER_SETTER_ROLE = keccak256("PARAMETER_SETTER_ROLE");

	// AccessControl state variables
	bool public mintPaused = false;
	bool public redeemPaused = false;
	bool public recollateralizePaused = false;
	bool public buyBackPaused = false;

	/* ========== MODIFIERS ========== */

	modifier onlyByTrusty() {
		require(
			hasRole(TRUSTY_ROLE, msg.sender),
			"POOL::you are not trusty"
		);
		_;
	}

	modifier notRedeemPaused() {
		require(redeemPaused == false, "POOL::Redeeming is paused");
		_;
	}

	modifier notMintPaused() {
		require(mintPaused == false, "POOL::Minting is paused");
		_;
	}

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_contract_address,
		address _deus_contract_address,
		address _collateral_address,
		address _trusty_address,
		address _admin_address,
		uint256 _pool_ceiling,
		address _library
	) {
		require(
			(_dei_contract_address != address(0)) &&
				(_deus_contract_address != address(0)) &&
				(_collateral_address != address(0)) &&
				(_trusty_address != address(0)) &&
				(_admin_address != address(0)) &&
				(_library != address(0)),
			"POOL::Zero address detected"
		);
		poolLibrary = DEIPoolLibrary(_library);
		dei_contract_address = _dei_contract_address;
		deus_contract_address = _deus_contract_address;
		collateral_address = _collateral_address;
		collateral_token = ERC20(_collateral_address);
		pool_ceiling = _pool_ceiling;
		missing_decimals = uint256(18) - collateral_token.decimals();

		_setupRole(DEFAULT_ADMIN_ROLE, _admin_address);
		_setupRole(MINT_PAUSER, _trusty_address);
		_setupRole(REDEEM_PAUSER, _trusty_address);
		_setupRole(RECOLLATERALIZE_PAUSER, _trusty_address);
		_setupRole(BUYBACK_PAUSER, _trusty_address);
        _setupRole(TRUSTY_ROLE, _trusty_address);
        _setupRole(TRUSTY_ROLE, _trusty_address);
        _setupRole(PARAMETER_SETTER_ROLE, _trusty_address);
	}

	/* ========== VIEWS ========== */

	// Returns dollar value of collateral held in this DEI pool
	function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
		return ((collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral) * (10**missing_decimals) * collat_usd_price) / (PRICE_PRECISION);
	}

	// Returns the value of excess collateral held in this DEI pool, compared to what is needed to maintain the global collateral ratio
	function availableExcessCollatDV(uint256[] memory collat_usd_price) public view returns (uint256) {
		uint256 total_supply = IDEIStablecoin(dei_contract_address).totalSupply();
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		uint256 global_collat_value = IDEIStablecoin(dei_contract_address).globalCollateralValue(collat_usd_price);

		if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION)
			global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
		uint256 required_collat_dollar_value_d18 = (total_supply * global_collateral_ratio) / (COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 DEI with $1 of collateral at current collat ratio
		if (global_collat_value > required_collat_dollar_value_d18)
			return global_collat_value - required_collat_dollar_value_d18;
		else return 0;
	}

	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

	/* ========== PUBLIC FUNCTIONS ========== */

	// We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency
	function mint1t1DEI(uint256 collateral_amount, uint256 collateral_price, uint256 expireBlock, bytes[] calldata sigs)
		external
		notMintPaused
		returns (uint256 dei_amount_d18)
	{

		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() >= COLLATERAL_RATIO_MAX,
			"Collateral ratio must be >= 1"
		);
		require(
			collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral +  collateral_amount <= pool_ceiling,
			"[Pool's Closed]: Ceiling reached"
		);

		require(expireBlock >= block.number, "POOL::mint1t1DEI: signature is expired");
        bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mint1t1DEI: invalid signatures");

		uint256 collateral_amount_d18 = collateral_amount * (10**missing_decimals);
		dei_amount_d18 = poolLibrary.calcMint1t1DEI(
			collateral_price,
			collateral_amount_d18
		); //1 DEI for each $1 worth of collateral

		dei_amount_d18 = (dei_amount_d18 * (uint256(1e6) - minting_fee)) / 1e6; //remove precision at the end

		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_amount
		);

		daoShare += dei_amount_d18 *  minting_fee / 1e6;
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, dei_amount_d18);
	}

	// 0% collateral-backed
	function mintAlgorithmicDEI(
		uint256 deus_amount_d18,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notMintPaused returns (uint256 dei_amount_d18) {
		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() == 0,
			"Collateral ratio must be 0"
		);
		require(expireBlock >= block.number, "POOL::mintAlgorithmicDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mintAlgorithmicDEI: invalid signatures");

		dei_amount_d18 = poolLibrary.calcMintAlgorithmicDEI(
			deus_current_price, // X DEUS / 1 USD
			deus_amount_d18
		);

		dei_amount_d18 = (dei_amount_d18 * (uint256(1e6) - (minting_fee))) / (1e6);
		daoShare += dei_amount_d18 *  minting_fee / 1e6;

		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, deus_amount_d18);
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, dei_amount_d18);
	}

	// Will fail if fully collateralized or fully algorithmic
	// > 0% and < 100% collateral-backed
	function mintFractionalDEI(
		uint256 collateral_amount,
		uint256 deus_amount,
		uint256 collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notMintPaused returns (uint256 mint_amount) {
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		require(
			global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0,
			"Collateral ratio needs to be between .000001 and .999999"
		);
		require(
			collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral + collateral_amount <= pool_ceiling,
			"Pool ceiling reached, no more DEI can be minted with this collateral"
		);

		require(expireBlock >= block.number, "POOL::mintFractionalDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::mintFractionalDEI: invalid signatures");

		DEIPoolLibrary.MintFD_Params memory input_params;

		// Blocking is just for solving stack depth problem
		{
			uint256 collateral_amount_d18 = collateral_amount * (10**missing_decimals);
			input_params = DEIPoolLibrary.MintFD_Params(
											deus_current_price,
											collateral_price,
											collateral_amount_d18,
											global_collateral_ratio
										);
		}						

		uint256 deus_needed;
		(mint_amount, deus_needed) = poolLibrary.calcMintFractionalDEI(input_params);
		require(deus_needed <= deus_amount, "Not enough DEUS inputted");
		
		mint_amount = (mint_amount * (uint256(1e6) - minting_fee)) / (1e6);

		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, deus_needed);
		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_amount
		);

		daoShare += mint_amount *  minting_fee / 1e6;
		IDEIStablecoin(dei_contract_address).pool_mint(msg.sender, mint_amount);
	}

	// Redeem collateral. 100% collateral-backed
	function redeem1t1DEI(uint256 DEI_amount, uint256 collateral_price, uint256 expireBlock, bytes[] calldata sigs)
		external
		notRedeemPaused
	{
		require(
			IDEIStablecoin(dei_contract_address).global_collateral_ratio() == COLLATERAL_RATIO_MAX,
			"Collateral ratio must be == 1"
		);

		require(expireBlock >= block.number, "POOL::mintAlgorithmicDEI: signature is expired.");
        bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeem1t1DEI: invalid signatures");

		// Need to adjust for decimals of collateral
		uint256 DEI_amount_precision = DEI_amount / (10**missing_decimals);
		uint256 collateral_needed = poolLibrary.calcRedeem1t1DEI(
			collateral_price,
			DEI_amount_precision
		);

		collateral_needed = (collateral_needed * (uint256(1e6) - redemption_fee)) / (1e6);
		require(
			collateral_needed <= collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral,
			"Not enough collateral in pool"
		);

		redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateral_needed;
		unclaimedPoolCollateral = unclaimedPoolCollateral + collateral_needed;
		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
	}

	// Will fail if fully collateralized or algorithmic
	// Redeem DEI for collateral and DEUS. > 0% and < 100% collateral-backed
	function redeemFractionalDEI(
		uint256 DEI_amount,
		uint256 collateral_price, 
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notRedeemPaused {
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		require(
			global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0,
			"POOL::redeemFractionalDEI: Collateral ratio needs to be between .000001 and .999999"
		);

		require(expireBlock >= block.number, "DEI::redeemFractionalDEI: signature is expired");
		bytes32 sighash = keccak256(abi.encodePacked(collateral_address, collateral_price, deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeemFractionalDEI: invalid signatures");

		// Blocking is just for solving stack depth problem
		uint256 deus_amount;
		uint256 collateral_amount;
		{
			uint256 col_price_usd = collateral_price;

			uint256 DEI_amount_post_fee = (DEI_amount * (uint256(1e6) - redemption_fee)) / (PRICE_PRECISION);

			uint256 deus_dollar_value_d18 = DEI_amount_post_fee - ((DEI_amount_post_fee * global_collateral_ratio) / (PRICE_PRECISION));
			deus_amount = deus_dollar_value_d18 * (PRICE_PRECISION) / (deus_current_price);

			// Need to adjust for decimals of collateral
			uint256 DEI_amount_precision = DEI_amount_post_fee / (10**missing_decimals);
			uint256 collateral_dollar_value = (DEI_amount_precision * global_collateral_ratio) / PRICE_PRECISION;
			collateral_amount = (collateral_dollar_value * PRICE_PRECISION) / (col_price_usd);
		}
		require(
			collateral_amount <= collateral_token.balanceOf(address(this)) - unclaimedPoolCollateral,
			"Not enough collateral in pool"
		);

		redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender] + collateral_amount;
		unclaimedPoolCollateral = unclaimedPoolCollateral + collateral_amount;

		redeemDEUSBalances[msg.sender] = redeemDEUSBalances[msg.sender] + deus_amount;
		unclaimedPoolDEUS = unclaimedPoolDEUS + deus_amount;

		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
		IDEUSToken(deus_contract_address).pool_mint(address(this), deus_amount);
	}

	// Redeem DEI for DEUS. 0% collateral-backed
	function redeemAlgorithmicDEI(
		uint256 DEI_amount,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external notRedeemPaused {
		require(IDEIStablecoin(dei_contract_address).global_collateral_ratio() == 0, "POOL::redeemAlgorithmicDEI: Collateral ratio must be 0");

		require(expireBlock >= block.number, "DEI::redeemAlgorithmicDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(deus_contract_address, deus_current_price, expireBlock, getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::redeemAlgorithmicDEI: invalid signatures");

		uint256 deus_dollar_value_d18 = DEI_amount;

		deus_dollar_value_d18 = (deus_dollar_value_d18 * (uint256(1e6) - redemption_fee)) / 1e6; //apply fees

		uint256 deus_amount = (deus_dollar_value_d18 * (PRICE_PRECISION)) / deus_current_price;

		redeemDEUSBalances[msg.sender] = redeemDEUSBalances[msg.sender] + deus_amount;
		unclaimedPoolDEUS = unclaimedPoolDEUS + deus_amount;

		lastRedeemed[msg.sender] = block.number;

		daoShare += DEI_amount * redemption_fee / 1e6;
		// Move all external functions to the end
		IDEIStablecoin(dei_contract_address).pool_burn_from(msg.sender, DEI_amount);
		IDEUSToken(deus_contract_address).pool_mint(address(this), deus_amount);
	}

	// After a redemption happens, transfer the newly minted DEUS and owed collateral from this pool
	// contract to the user. Redemption is split into two functions to prevent flash loans from being able
	// to take out DEI/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
	function collectRedemption() external {
		require(
			(lastRedeemed[msg.sender] + redemption_delay) <= block.number,
			"POOL::collectRedemption: Must wait for redemption_delay blocks before collecting redemption"
		);
		bool sendDEUS = false;
		bool sendCollateral = false;
		uint256 DEUSAmount = 0;
		uint256 CollateralAmount = 0;

		// Use Checks-Effects-Interactions pattern
		if (redeemDEUSBalances[msg.sender] > 0) {
			DEUSAmount = redeemDEUSBalances[msg.sender];
			redeemDEUSBalances[msg.sender] = 0;
			unclaimedPoolDEUS = unclaimedPoolDEUS - DEUSAmount;

			sendDEUS = true;
		}

		if (redeemCollateralBalances[msg.sender] > 0) {
			CollateralAmount = redeemCollateralBalances[msg.sender];
			redeemCollateralBalances[msg.sender] = 0;
			unclaimedPoolCollateral = unclaimedPoolCollateral - CollateralAmount;
			sendCollateral = true;
		}

		if (sendDEUS) {
			TransferHelper.safeTransfer(address(deus_contract_address), msg.sender, DEUSAmount);
		}
		if (sendCollateral) {
			TransferHelper.safeTransfer(
				address(collateral_token),
				msg.sender,
				CollateralAmount
			);
		}
	}

	// When the protocol is recollateralizing, we need to give a discount of DEUS to hit the new CR target
	// Thus, if the target collateral ratio is higher than the actual value of collateral, minters get DEUS for adding collateral
	// This function simply rewards anyone that sends collateral to a pool with the same amount of DEUS + the bonus rate
	// Anyone can call this function to recollateralize the protocol and take the extra DEUS value from the bonus rate as an arb opportunity
	function recollateralizeDEI(RecollateralizeDEI memory inputs) external {
		require(recollateralizePaused == false, "POOL::recollateralizeDEI: Recollateralize is paused");

		require(inputs.expireBlock >= block.number, "POOL::recollateralizeDEI: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(
                                        collateral_address, 
                                        inputs.collateral_price,
                                        deus_contract_address, 
                                        inputs.deus_current_price, 
                                        inputs.expireBlock,
										getChainID()
                                    ));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, inputs.sigs), "POOL::recollateralizeDEI: invalid signatures");

		uint256 collateral_amount_d18 = inputs.collateral_amount * (10**missing_decimals);

		uint256 dei_total_supply = IDEIStablecoin(dei_contract_address).totalSupply();
		uint256 global_collateral_ratio = IDEIStablecoin(dei_contract_address).global_collateral_ratio();
		uint256 global_collat_value = IDEIStablecoin(dei_contract_address).globalCollateralValue(inputs.collateral_price);

		(uint256 collateral_units, uint256 amount_to_recollat) = poolLibrary.calcRecollateralizeDEIInner(
																				collateral_amount_d18,
																				inputs.collateral_price[inputs.collateral_price.length - 1], // pool collateral price exist in last index
																				global_collat_value,
																				dei_total_supply,
																				global_collateral_ratio
																			);

		uint256 collateral_units_precision = collateral_units / (10**missing_decimals);

		uint256 deus_paid_back = (amount_to_recollat * (uint256(1e6) + bonus_rate - recollat_fee)) / inputs.deus_current_price;

		TransferHelper.safeTransferFrom(
			address(collateral_token),
			msg.sender,
			address(this),
			collateral_units_precision
		);
		IDEUSToken(deus_contract_address).pool_mint(msg.sender, deus_paid_back);
	}

	// Function can be called by an DEUS holder to have the protocol buy back DEUS with excess collateral value from a desired collateral pool
	// This can also happen if the collateral ratio > 1
	function buyBackDEUS(
		uint256 DEUS_amount,
		uint256[] memory collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external {
		require(buyBackPaused == false, "POOL::buyBackDEUS: Buyback is paused");
		require(expireBlock >= block.number, "DEI::buyBackDEUS: signature is expired.");
		bytes32 sighash = keccak256(abi.encodePacked(
										collateral_address,
										collateral_price,
										deus_contract_address,
										deus_current_price,
										expireBlock,
										getChainID()));
		require(IDEIStablecoin(dei_contract_address).verify_price(sighash, sigs), "POOL::buyBackDEUS: invalid signatures");

		DEIPoolLibrary.BuybackDEUS_Params memory input_params = DEIPoolLibrary.BuybackDEUS_Params(
													availableExcessCollatDV(collateral_price),
													deus_current_price,
													collateral_price[collateral_price.length - 1], // pool collateral price exist in last index
													DEUS_amount
												);

		uint256 collateral_equivalent_d18 = (poolLibrary.calcBuyBackDEUS(input_params) * (uint256(1e6) - buyback_fee)) / (1e6);
		uint256 collateral_precision = collateral_equivalent_d18 / (10**missing_decimals);

		// Give the sender their desired collateral and burn the DEUS
		IDEUSToken(deus_contract_address).pool_burn_from(msg.sender, DEUS_amount);
		TransferHelper.safeTransfer(
			address(collateral_token),
			msg.sender,
			collateral_precision
		);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function collectDaoShare(uint256 amount, address to) external {
		require(hasRole(DAO_SHARE_COLLECTOR, msg.sender));
		require(amount <= daoShare, "amount<=daoShare");
		IDEIStablecoin(dei_contract_address).pool_mint(to, amount);
		daoShare -= amount;

		emit daoShareCollected(amount, to);
	}

	function emergencyWithdrawERC20(address token, uint amount, address to) external onlyByTrusty {
		IERC20(token).transfer(to, amount);
	}

	function toggleMinting() external {
		require(hasRole(MINT_PAUSER, msg.sender));
		mintPaused = !mintPaused;

		emit MintingToggled(mintPaused);
	}

	function toggleRedeeming() external {
		require(hasRole(REDEEM_PAUSER, msg.sender));
		redeemPaused = !redeemPaused;

		emit RedeemingToggled(redeemPaused);
	}

	function toggleRecollateralize() external {
		require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
		recollateralizePaused = !recollateralizePaused;

		emit RecollateralizeToggled(recollateralizePaused);
	}

	function toggleBuyBack() external {
		require(hasRole(BUYBACK_PAUSER, msg.sender));
		buyBackPaused = !buyBackPaused;

		emit BuybackToggled(buyBackPaused);
	}

	// Combined into one function due to 24KiB contract memory limit
	function setPoolParameters(
		uint256 new_ceiling,
		uint256 new_bonus_rate,
		uint256 new_redemption_delay,
		uint256 new_mint_fee,
		uint256 new_redeem_fee,
		uint256 new_buyback_fee,
		uint256 new_recollat_fee
	) external {
		require(hasRole(PARAMETER_SETTER_ROLE, msg.sender), "POOL: Caller is not PARAMETER_SETTER_ROLE");
		pool_ceiling = new_ceiling;
		bonus_rate = new_bonus_rate;
		redemption_delay = new_redemption_delay;
		minting_fee = new_mint_fee;
		redemption_fee = new_redeem_fee;
		buyback_fee = new_buyback_fee;
		recollat_fee = new_recollat_fee;

		emit PoolParametersSet(
			new_ceiling,
			new_bonus_rate,
			new_redemption_delay,
			new_mint_fee,
			new_redeem_fee,
			new_buyback_fee,
			new_recollat_fee
		);
	}

	/* ========== EVENTS ========== */

	event PoolParametersSet(
		uint256 new_ceiling,
		uint256 new_bonus_rate,
		uint256 new_redemption_delay,
		uint256 new_mint_fee,
		uint256 new_redeem_fee,
		uint256 new_buyback_fee,
		uint256 new_recollat_fee
	);
	event daoShareCollected(uint256 daoShare, address to);
	event MintingToggled(bool toggled);
	event RedeemingToggled(bool toggled);
	event RecollateralizeToggled(bool toggled);
	event BuybackToggled(bool toggled);
}

//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

interface IDEUSToken {
    function setDEIAddress(address dei_contract_address) external;
    function mint(address to, uint256 amount) external;

    // This function is what other dei pools will call to mint new DEUS (similar to the DEI mint)
    function pool_mint(address m_address, uint256 m_amount) external;

    // This function is what other dei pools will call to burn DEUS
    function pool_burn_from(address b_address, uint256 b_amount) external;

    function toggleVotes() external;

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96);

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}

//Dar panah khoda

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

interface IDEIStablecoin {

    function totalSupply() external view returns (uint256);

    function global_collateral_ratio() external view returns (uint256);
	
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);

	function dei_info(uint256 eth_usd_price, uint256 eth_collat_price)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);

	function refreshCollateralRatio(uint256 dei_price_cur, uint256 expireBlock, bytes[] calldata sigs) external;

	function pool_burn_from(address b_address, uint256 b_amount) external;

	function pool_mint(address m_address, uint256 m_amount) external;

	function addPool(address pool_address) external;

	function removePool(address pool_address) external;

	function setDEIStep(uint256 _new_step) external;

	function setPriceTarget(uint256 _new_price_target) external;

	function setRefreshCooldown(uint256 _new_cooldown) external;

	function setDEUSAddress(address _deus_address) external;

	function setPriceBand(uint256 _price_band) external;
	
    function toggleCollateralRatio() external;
}

//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

import "../Utils/EnumerableSet.sol";
import "../Utils/Address.sol";
import "../Common/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; //bytes32(uint256(0x4B437D01b575618140442A4975db38850e3f8f5f) << 96);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

contract DEIPoolLibrary {

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor() {}

    // ================ Structs ================
    // Needed to lower stack size
    struct MintFD_Params {
        uint256 deus_price_usd; 
        uint256 col_price_usd;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackDEUS_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 deus_price_usd;
        uint256 col_price_usd;
        uint256 DEUS_amount;
    }

    // ================ Functions ================

    function calcMint1t1DEI(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18 * col_price) / (1e6);
    }

    function calcMintAlgorithmicDEI(uint256 deus_price_usd, uint256 deus_amount_d18) public pure returns (uint256) {
        return (deus_amount_d18 * deus_price_usd) / (1e6);
    }

    // Must be internal because of the struct
    function calcMintFractionalDEI(MintFD_Params memory params) public pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint DEI. We do this by seeing the minimum mintable DEI based on each amount 
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the DEUS
            c_dollar_value_d18 = (params.collateral_amount * params.col_price_usd) / (1e6);

        }
        uint calculated_deus_dollar_value_d18 = ((c_dollar_value_d18 * (1e6)) / params.col_ratio) - c_dollar_value_d18;

        uint calculated_deus_needed = (calculated_deus_dollar_value_d18 * (1e6)) / params.deus_price_usd;

        return (
            c_dollar_value_d18 + calculated_deus_dollar_value_d18,
            calculated_deus_needed
        );
    }

    function calcRedeem1t1DEI(uint256 col_price_usd, uint256 DEI_amount) public pure returns (uint256) {
        return (DEI_amount * (1e6)) / col_price_usd;
    }

    // Must be internal because of the struct
    function calcBuyBackDEUS(BuybackDEUS_Params memory params) public pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible DEUS with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 deus_dollar_value_d18 = (params.DEUS_amount * (params.deus_price_usd)) / (1e6);
        require(deus_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of DEUS provided 
        uint256 collateral_equivalent_d18 = (deus_dollar_value_d18 * (1e6)) / params.col_price_usd;
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return collateral_equivalent_d18;

    }


    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = (total_supply * global_collateral_ratio) / (1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value - global_collat_value; // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }

    function calcRecollateralizeDEIInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 dei_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = (collateral_amount * col_price) / (1e6);
        uint256 effective_collateral_ratio = (global_collat_value * (1e6)) / dei_total_supply; //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio * dei_total_supply - (dei_total_supply * effective_collateral_ratio)) / (1e6);

        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return ((amount_to_recollat * (1e6)) / col_price, amount_to_recollat);

    }

}

//Dar panah khoda

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "../Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(bytes20(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

