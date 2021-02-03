pragma solidity 0.6.11; // 5ef660b1
import "Uniswap.sol";
/* BAEX - Roulette Smart-Contract v.1.1 (© 2021 - baex.com)
    
A smart contract source code of an American Rolette game, default interface at https://baex.com/#roulette

Spin number generation in the function _spinRoulette:

uint256 spin_number = uint256(keccak256(abi.encodePacked(_bid_param,ifaceRandomSeed(seed_contract).getRandomSeed(),tx.origin.balance,tx.origin,blockhash(0)))) % 38;

Using this smart contract, you can earn from providing liquidity or play.
*/

interface ifaceBAEXToken {
    function transferOptions(address _from, address _to, uint256 _value, bool _burn_to_assets) external returns (bool);
    function issuePrice() external view returns (uint256);
	function burnPrice() external view returns (uint256);
	function collateral() external view returns (uint256);
}

interface ifaceRandomSeed {
    function getRandomSeed() external returns(uint256);
}

/* BAEX - smart-contract of BAEX options */
contract BAEXRoulette {
    // Fixed point math factor is 10^10
    uint256 constant public fmk = 10**10;
    // ALL STORED IN THIS CONTRACT BALANCES AND AMOUNTS HAVE PRECISION * 10
    uint256 constant public tfmk = 10**9;
    address constant private super_owner = 0x2B2fD898888Fa3A97c7560B5ebEeA959E1Ca161A;
    address private owner;
    
    string public name;

    // Min bid volume
    uint256 public min_bid_vol;
    // Max bid volume
    uint256 public max_bid_vol;
    
    // Size of liquidity pool
    uint256 public liquidity_pool;
    
    // Balancing factors
    uint256 public liquidity_in;
    uint256 public liquidity_ratio;
    
    uint32 public num_of_bids;
    uint256 public total_games_in;
    uint256 public total_games_out;
    
    uint256 public max_bid_k;
    uint256 public max_win_k;
    
    address baex;
    address seed_contract;
    
    mapping(address => uint256 ) public liquidity;
    mapping(uint256 => uint256) public chips;
    
    constructor() public {
		name = "BAEX - Roulette Smart-Contract";
		
		liquidity_in = 0;
		liquidity_pool = 0;
		liquidity_ratio = 1 * fmk;
		
		min_bid_vol = 25 * tfmk / 100;
		max_bid_vol = 25 * tfmk / 100;
		
		chips[1] = 25 * tfmk / 100; // 0.25 BAEX
        chips[2] = 50 * tfmk / 100; // 0.5  BAEX
        chips[3] = 1 * tfmk;
        chips[4] = 2 * tfmk;
        chips[5] = 4 * tfmk;
        chips[6] = 8 * tfmk;
        chips[7] = 16 * tfmk;
        chips[8] = 24 * tfmk;
        chips[9] = 32 * tfmk;
        chips[10] = 48 * tfmk;
        chips[12] = 64 * tfmk;
        chips[13] = 96 * tfmk;
        chips[14] = 128 * tfmk;
        chips[15] = 256 * tfmk;
        
        max_bid_k = 720;
        max_win_k = 128;
        
		owner = msg.sender;
		num_of_bids = 0;
		baex = 0x889A3a814181536822e83373b4017e1122B01932;
		seed_contract = 0x205E8C8Cd03141b136B9e4361E4F5891174CB30B;
	}
	
	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner), "You don't have permissions to call it" );
		_;
	}

	function afterChangeLiquidityPool() private {
	    if ( liquidity_pool == 0 ) {
	        liquidity_in = 0;
		    liquidity_pool = 0;
		    liquidity_ratio = 1 * fmk;
		    min_bid_vol = 25 * tfmk / 100;
		    max_bid_vol = 50 * tfmk / 100;
		    return;
	    }
        max_bid_vol = liquidity_pool / max_bid_k;
	    liquidity_ratio = liquidity_in * fmk / liquidity_pool;
	    log2(bytes20(address(this)),bytes4("LPC"),bytes32(liquidity_pool<<128));
	}
    
    function placeLiquidity(uint256 _vol) public {
        _placeLiquidity( msg.sender, _vol, true );
    }
	function _placeLiquidity(address _sender, uint256 _vol, bool _need_transfer) private {
	    require( _vol > 0, "Vol must be greater than zero" );
	    require( _vol < 10**21, "Too big volume" );
	    if ( _need_transfer ) {
	        ifaceBAEXToken(baex).transferOptions(_sender,address(this),_vol,false);
	    }
	    _vol = _vol * 10;
        uint256 in_vol = _vol;
        if ( liquidity_pool != 0 ) {
            in_vol = _vol * liquidity_ratio / fmk;
        }
        liquidity_in = liquidity_in + in_vol;
        liquidity_pool = liquidity_pool + _vol;
        liquidity[_sender] = liquidity[_sender] + in_vol;
        afterChangeLiquidityPool();
	}
	
	function balanceOf(address _sender) public view returns (uint256) {
        return liquidityBalanceOf(_sender);
    }
    
    function getMinMaxBidVol() public view returns (uint256, uint256) {
        return (min_bid_vol/10, max_bid_vol/10);
    }
    
    function liquidityBalanceOf(address _sender) public view returns (uint256) {
	    return liquidity[_sender] * fmk / liquidity_ratio / 10;
	}
	
	function withdrawLiquidity(uint256 _vol, bool _burn_to_eth) public {
	    _withdrawLiquidity( msg.sender, _vol, _burn_to_eth );
	}
	function _withdrawLiquidity(address _sender, uint256 _vol, bool _burn_to_eth) private {
	    require( _vol > 0, "Vol must be greater than zero" );
	    require( _vol < 10**21, "Too big volume" );
	    _vol = _vol * 10;
	    require( _vol <= liquidity_pool, "Not enough volume for withdrawal, please decrease volume to withdraw (1)" );
	    uint256 in_vol = _vol * liquidity_ratio / fmk;
	    uint256 in_bal = liquidity[_sender];
	    require( in_vol <= in_bal, "Not enough volume for withdrawal, please decrease volume to withdraw (2)" );
	    ifaceBAEXToken(baex).transferOptions(address(this),_sender,_vol/10,_burn_to_eth);
	    if ( liquidity_pool - _vol < 3 ) {
            liquidity[_sender] = 0;
            liquidity_pool = 0;
            liquidity_in = 0;
            liquidity_ratio = fmk;
        } else {
            if ( in_bal - in_vol < 3 ) {
	            in_vol = in_bal;
	        }
            liquidity[_sender] = in_bal - in_vol;
            liquidity_pool = liquidity_pool - _vol;
            liquidity_in = liquidity_in - in_vol;
        }
        afterChangeLiquidityPool();
	}
	
	function getChipVolume(  uint256 _chip_id  ) public view returns(uint256){
	    if ( _chip_id == 0 ) return 0;
        return chips[_chip_id];
	}
	
	function getBidVolFromParam( uint256 _bid_param ) public view returns(uint256) {
	    uint256 vol = 0;
	    uint256 cid = _bid_param >> 252;
	    vol = getChipVolume(cid);
	    for (uint i=0; i<49; i++) {
    	    _bid_param = _bid_param << 4;
    	    cid = _bid_param >> 252;
    	    vol = vol + getChipVolume(cid);
	    }
	    return vol;
	}
	
	function calcTotalResultBySpinNumberAndParam( uint256 spin_number, uint256 _bid_param ) private view returns(uint256) {
	    uint256 result = 0;
	    uint256 cid = ( _bid_param << (spin_number*4) ) >> 252;
	    result = getChipVolume( cid ) * 36;
	    if ( spin_number > 0 && spin_number < 37 ) {
    	    // from 1 to 18
    	    if ( spin_number >= 1 && spin_number <= 18 ) {
    	        cid = ( _bid_param << 38 * 4 ) >> 252;
    	    } else { // from 18 to 36
    	        cid = ( _bid_param << 39 * 4 ) >> 252;
    	    }
    	    result = result + getChipVolume( cid ) * 2;
    	    // Red 
    	    if ( (spin_number == 1) || (spin_number == 3) || (spin_number == 5) || (spin_number == 7) || (spin_number == 9) || (spin_number == 12) ||
    	        (spin_number == 14) || (spin_number == 16) || (spin_number == 18) || (spin_number == 19) || (spin_number == 21) || (spin_number == 23) ||
    	        (spin_number == 25) || (spin_number == 27) || (spin_number == 30) || (spin_number == 32) || (spin_number == 34) || (spin_number == 36) 
    	    ) { 
    	        cid = ( _bid_param << 41 * 4 ) >> 252;
    	    } else { // Black
    	        cid = ( _bid_param << 40 * 4 ) >> 252;
    	    }
    	    result = result + getChipVolume( cid ) * 2;
    	    // Even
    	    if ( spin_number % 2 == 0 ) {
    	        cid = ( _bid_param << 42 * 4 ) >> 252;
    	    } else { // Odd
    	        cid = ( _bid_param << 43 * 4 ) >> 252;
    	    }
    	    result = result + getChipVolume( cid ) * 2;
    	    // Dozen 1
    	    if ( spin_number >= 1 && spin_number <= 12 ) {
    	        cid = ( _bid_param << 44 * 4 ) >> 252;
    	    } else if ( spin_number >= 13 && spin_number <= 24 ) { // Dozen 2
    	        cid = ( _bid_param << 45 * 4 ) >> 252;
    	    } else { // Dozen 3
    	        cid = ( _bid_param << 46 * 4 ) >> 252;
    	    }
    	    result = result + getChipVolume( cid ) * 3;
    	    // Third 1
    	    if ( spin_number % 3 == 1 ) {
    	        cid = ( _bid_param << 47 * 4 ) >> 252;
    	    } else if ( spin_number % 3 == 2) { // Third 2
    	        cid = ( _bid_param << 48 * 4 ) >> 252;
    	    } else { // Third 3
    	        cid = ( _bid_param << 49 * 4 ) >> 252;
    	    }
    	    result = result + getChipVolume( cid ) * 3;
    	}
	    return result;
	}
	
	
	/**
    * @dev Spin the roullete
	* @dev uint256 _bid_param - coded as 4 bits per one field (one hex number from 0 to F, 256 bits cointains 64 hex digits) from high bits
	* @dev                      every 4 bits store ID of the chip, you can find volumes of every chip in the chips variable
    * @dev  0       - ZERO
    * @dev  1-36    - 1-36
    * @dev  37      - Double ZERO
    * @dev  38      - Numbers from 1 to 18
    * @dev  39      - Numbers from 19 to 36
    * @dev  40-41   - Black / Red
    * @dev  42-43   - Even / Odd
    * @dev  44-46   - Dozens
    * @dev  47-49   - Thirds
    * @dev  50-63   - Not used
    * @dev 
    * @dev  Example of the _bid_param :
    * @dev    0000000000000000000000000000000000000000300000500000000000000000
    * @dev    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ^     ^
    * @dev    0123456789111......................330  B     3nd                             
    * @dev              012                      560  L     D
    * @dev                                            A     O
    * @dev                                            C     Z
    * @dev                                            K     E 
    * @dev                                                  N
    * @dev
    * @dev  That's mean chip with id 3 (default volume is 1 BAEX) on BLACK
    * @dev    and chip with id 5 (default volume is 4 BAEX) on 2nd DOZEN
    * @dev 
    */
	function spinRoulette(uint256 _bid_param) public {
	    _spinRoulette(msg.sender, _bid_param);
	}
	function _spinRoulette(address _sender, uint256 _bid_param) private {
	    uint256 _vol = getBidVolFromParam( _bid_param );
	    require( tx.origin == msg.sender, "Only origin addresses can call it" );
	    require( _vol > 0, "Bid volume must be greater than zero" );
	    require( _vol < 10**21, "Too big bid volume" );
	    require( _vol >= min_bid_vol, "Your bid volume less than minimal bid volume" );
	    require( _vol <= max_bid_vol, "Your bid volume greater than maximum bid volume" );
	    require( IERC20(baex).balanceOf(_sender) >= _vol/10, "Not enough balance to place this bid" );
	    require( liquidity_pool/max_bid_k >= _vol, "Not enough liquidity in the pool" );
	    // GENERATE ROULETTE SPIN RANDOM
	    uint256 spin_number = uint256(keccak256(abi.encodePacked(_bid_param,ifaceRandomSeed(seed_contract).getRandomSeed(),tx.origin.balance,tx.origin,blockhash(0)))) % 38;
	    // ---
	    uint256 result = calcTotalResultBySpinNumberAndParam( spin_number, _bid_param );
	    require( result <= (liquidity_pool / max_win_k), "Your bid volume is too high" );
	    total_games_in = total_games_in + _vol/10;
	    ifaceBAEXToken(baex).transferOptions(_sender,address(this),_vol/10,false);
	    if ( spin_number == 37 ) {
	        ifaceBAEXToken(baex).transferOptions(address(this),owner,_vol/10,false);
	    } else {
	        liquidity_pool = liquidity_pool + _vol;
	    }
	    if ( result > 0 ) {
	        liquidity_pool = liquidity_pool - result;
	        ifaceBAEXToken(baex).transferOptions(address(this),_sender,result/10,false);
	        total_games_out = total_games_out + result/10;
	    }
	    afterChangeLiquidityPool();
	    // LOG THE RESULT OF THE SPIN
	    log3(bytes20(address(this)),bytes8("ROLL"),bytes32(uint256(msg.sender)),bytes32((spin_number<<224) | result));
	    num_of_bids++;
	}
	
	/* Admin functions */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function setTokenAddress(address _token_address) public onlyOwner {
	    baex = _token_address;
	}
	
	function setSeedContract(address _seed_contract) public onlyOwner {
	    seed_contract = _seed_contract;
	}
	
	function setMaxBidAndWin(uint256 _max_bid_k, uint256 _max_win_k) public onlyOwner {
	    max_bid_k = _max_bid_k;
	    max_win_k = _max_win_k;
	}
	
	function setChip(uint256 _chip_id, uint256 _vol) public onlyOwner {
	    chips[_chip_id] = _vol;
	    if (_chip_id == 1) {
	        min_bid_vol = _vol;
	    }
	}
	
	function onTransferTokens(address _from, address _to, uint256 _value) public returns (bool) {
	    require( msg.sender == address(baex), "You don't have permission to call it" );
	    if ( _to == address(this) ) {
	        _placeLiquidity( _from, _value, false );
	    }
	}
	
	// This function can transfer any of wrong sended ERC20 tokens to the contract exclude BAEX tokens,
	// because sendeding of the BAEX tokens to this contract is the valid operation
	function transferWrongSendedERC20FromContract(address _contract) public {
	    require( _contract != address(baex), "Transfer of BAEX token is fortradeen");
	    require( msg.sender == super_owner, "Your are not super owner");
	    IERC20(_contract).transfer( super_owner, IERC20(_contract).balanceOf(address(this)) );
	}
	
	// If someone send ETH to this contract it will send it back
	receive() external payable  {
        msg.sender.transfer(msg.value);
	}
	/*------------------*/
	
}
/* END of: Smart-contract */

// SPDX-License-Identifier: UNLICENSED