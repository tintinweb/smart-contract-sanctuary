/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
@title  Flavors Chain Data
@author iceCreamMan
@notice Due to the deterministic vanity address creation process,
        the contract bytecode must not change if we want to launch
        to another chain and use the same address. This function will
        check the chainId and properly name our token without having
        to launch a contract at a different address. Most of these
        will never be used but for future expansions to new chains
        having the exact same contract address across across the 
        board with bridges already in place will be very valuable
@dev    This contract's address must be entered during the Flavors 
        Token initialization process.
*/

// libraries

/* ---------- START OF IMPORT Address.sol ---------- */





library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,`isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived,but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052,0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code,i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`,forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes,possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`,making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`,care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient,uint256 amount/*,uint256 gas*/) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls,avoid-call-value
        (bool success,) = recipient.call{ value: amount/* ,gas: gas*/}("");
        require(success,"Address: unable to send value");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason,it is bubbled up by this
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
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
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
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }

    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
/* ------------ END OF IMPORT Address.sol ---------- */


contract FlavorsChainData {
  using Address for address;

    function tokenSymbol() public pure returns (string memory _tokenSymbol){ return "FLVR";}

    /**
    @notice gets the EVM chainId
    @return _chainId the numerical chainId of the connected chain.
    */
    function chainId() public view returns (uint _chainId) {return block.chainid;}

    /**
      @notice This function provides the Flavors token with a chain specific name
      @return _tokenName => The Flavors token name, as it applies to the connected chain.
    */
    function tokenName() public view returns (string memory _tokenName) {
             if(chainId() == 1)         {return "FlavorsETH";}   // ethereum => ETH
        else if(chainId() == 2)         {return "FlavorsEXP";}   // expanse network => EXP
        else if(chainId() == 3)         {return "FlavorsROPS_testnet";}   // ropsten test => ETH
        else if(chainId() == 4)         {return "FlavorsRINK_testnet";}   // Rinkeby test net => ETH
        else if(chainId() == 5)         {return "FlavorsGOERLI_testnet";}   // Rinkeby test net => ETH
        else if(chainId() == 10)        {return "FlavorsOPT";}   // Optimistic Ethereum
        else if(chainId() == 30)        {return "FlavorsRSK";}   // RSK MainNet => RBTC
        else if(chainId() == 42)        {return "FlavorsKOVAN_testnet";}   // Kovan test net
        else if(chainId() == 50)        {return "FlavorsXinFin";}   // XinFin => XDC
        else if(chainId() == 56)        {return "FlavorsBSC";}   // binance Smart Chain => WBNB
        else if(chainId() == 59)        {return "FlavorsEOS";}   // eos mainnet => EOS
        else if(chainId() == 60)        {return "FlavorsGO";}   // GoChain => GO
        else if(chainId() == 66)        {return "FlavorsOKEx";}   // OKExChain Mainnet => OKEx
        else if(chainId() == 70)        {return "FlavorsHOO";}   // hoo => WHOO
        else if(chainId() == 78)        {return "FlavorsPETH";}   // PrimusChain mainnet => 
        else if(chainId() == 80)        {return "FlavorsRNA";}   // GeneChain => RNA
        else if(chainId() == 82)        {return "FlavorsMTR";}   // Meter Mainnet => MTR
        else if(chainId() == 86)        {return "FlavorsGATE";}   // GateChain Mainnet => GT
        else if(chainId() == 88)        {return "FlavorsTOMO";}   // TomoChain => TOMO
        else if(chainId() == 97)        {return "FlavorsBSC_testnet";}   // bsc testnet => TWBNB
        else if(chainId() == 100)       {return "FlavorsXDAI";}   // dai => xDAI
        else if(chainId() == 108)       {return "FlavorsTT";}   // ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return "FlavorsFUSE";}   // Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return "FlavorsHECO";}   // huobi eco => WHT
        else if(chainId() == 137)       {return "FlavorsPOLY";}   // poly => WMATIC
        else if(chainId() == 250)       {return "FlavorsFTM";}   // fantom => WFTM
        else if(chainId() == 256)       {return "FlavorsHECO_testnet";}   // heco test => HTT
        else if(chainId() == 269)       {return "FlavorsHPB";}   // High Performance Blockchain => 
        else if(chainId() == 321)       {return "FlavorsKCC";}   // kcc => WKCS
        else if(chainId() == 1012)      {return "FlavorsNEW";}   // Newton => NEW
        else if(chainId() == 1285)      {return "FlavorsMOVR";}   // Moonriver => MOVR
        else if(chainId() == 1287)      {return "FlavorsALPHA";}   // moonbase alpha => DEV
        else if(chainId() == 5197)      {return "FlavorsES";}   // EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return "FlavorsTOOL";}   // TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return "FlavorsBCH";}   // Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return "FlavorsNRG";}   // Energi Mainnet => NRG
        else if(chainId() == 42220)     {return "FlavorsCELO";}   // celo mainnet => CELO
        else if(chainId() == 42161)     {return "FlavorsARB";}   // Arbitrum One => AETH
        else if(chainId() == 43114)     {return "FlavorsAVA";}   // avalanche => WAVAX
        else if(chainId() == 80001)     {return "FlavorsPOLY_testnet";}   // Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return "FlavorsOLT";}   // OneLedger Mainnet => OLT
        else {return "Flavors";}
    }    

    function wrappedNative() public view returns (address) {
             if(chainId() == 1)         {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// ethereum => ETH
        else if(chainId() == 2)         {return 0x0000000000000000000000000000000000000000;}// expanse network => EXP
        else if(chainId() == 3)         {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// ropsten test => ETH
        else if(chainId() == 4)         {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// Rinkeby test net => ETH
        else if(chainId() == 5)         {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// Rinkeby test net => ETH
        else if(chainId() == 10)        {return 0x0000000000000000000000000000000000000000;}// Optimistic Ethereum
        else if(chainId() == 30)        {return 0x0000000000000000000000000000000000000000;}// RSK MainNet => RBTC
        else if(chainId() == 42)        {return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;}// Kovan test net
        else if(chainId() == 50)        {return 0x0000000000000000000000000000000000000000;}// XinFin => XDC
        else if(chainId() == 56)        {return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;}// binance Smart Chain => WBNB
        else if(chainId() == 59)        {return 0x0000000000000000000000000000000000000000;}// eos mainnet => EOS
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 66)        {return 0x0000000000000000000000000000000000000000;}// OKExChain Mainnet => OKEx
        else if(chainId() == 70)        {return 0x3EFF9D389D13D6352bfB498BCF616EF9b1BEaC87;}// hoo => WHOO
        else if(chainId() == 78)        {return 0x0000000000000000000000000000000000000000;}// PrimusChain mainnet => 
        else if(chainId() == 80)        {return 0x0000000000000000000000000000000000000000;}// GeneChain => RNA
        else if(chainId() == 82)        {return 0x0000000000000000000000000000000000000000;}// Meter Mainnet => MTR
        else if(chainId() == 86)        {return 0x0000000000000000000000000000000000000000;}// GateChain Mainnet => GT
        else if(chainId() == 88)        {return 0x0000000000000000000000000000000000000000;}// TomoChain => TOMO
        else if(chainId() == 97)        {return 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;}// bsc testnet => TWBNB
        else if(chainId() == 100)       {return 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;}// dai => xDAI
        else if(chainId() == 108)       {return 0x0000000000000000000000000000000000000000;}// ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return 0x0000000000000000000000000000000000000000;}// Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;}// huobi eco => WHT
        else if(chainId() == 137)       {return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;}// poly => WMATIC
        else if(chainId() == 250)       {return 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;}// fantom => WFTM
        else if(chainId() == 256)       {return 0x0000000000000000000000000000000000000000;}// heco test => HTT
        else if(chainId() == 269)       {return 0x0000000000000000000000000000000000000000;}// High Performance Blockchain => 
        else if(chainId() == 321)       {return 0x4446Fc4eb47f2f6586f9fAAb68B3498F86C07521;}// kcc => WKCS
        else if(chainId() == 322)       {return 0x5512Ae5E7eE55869dA7dc2a5D2F74a5Df65683B8;}// kcc => WKCS
        else if(chainId() == 1012)      {return 0x0000000000000000000000000000000000000000;}// Newton => NEW
        else if(chainId() == 1285)      {return 0x0000000000000000000000000000000000000000;}// Moonriver => MOVR
        else if(chainId() == 1287)      {return 0x0000000000000000000000000000000000000000;}// moonbase alpha => DEV
        else if(chainId() == 5197)      {return 0x0000000000000000000000000000000000000000;}// EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return 0x0000000000000000000000000000000000000000;}// TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return 0x0000000000000000000000000000000000000000;}// Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return 0x0000000000000000000000000000000000000000;}// Energi Mainnet => NRG
        else if(chainId() == 42220)     {return 0x0000000000000000000000000000000000000000;}// celo mainnet => CELO
        else if(chainId() == 42161)     {return 0x0000000000000000000000000000000000000000;}// Arbitrum One => AETH
        else if(chainId() == 43114)     {return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;}// avalanche => WAVAX
        else if(chainId() == 80001)     {return 0x0000000000000000000000000000000000000000;}// Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return 0x0000000000000000000000000000000000000000;}// OneLedger Mainnet => OLT
        // if we launch to another chain,we will have to manually update the address
        else {return 0x0000000000000000000000000000000000000000;}
    }

    function router() public view returns (address) {
             if(chainId() == 1)         {return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;}// ethereum => ETH
        else if(chainId() == 2)         {return 0x0000000000000000000000000000000000000000;}// expanse network => EXP
        else if(chainId() == 3)         {return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;}// ropsten test => ETH
        else if(chainId() == 4)         {return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;}// Rinkeby test net => ETH
        else if(chainId() == 5)         {return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;}// Gorli test net => ETH
        else if(chainId() == 42)        {return 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;}// Kovan test net
        else if(chainId() == 10)        {return 0x0000000000000000000000000000000000000000;}// Optimistic Ethereum
        else if(chainId() == 30)        {return 0x0000000000000000000000000000000000000000;}// RSK MainNet => RBTC
        else if(chainId() == 50)        {return 0x0000000000000000000000000000000000000000;}// XinFin => XDC
        else if(chainId() == 56)        {return 0x10ED43C718714eb63d5aA57B78B54704E256024E;}// binance Smart Chain => WBNB
        else if(chainId() == 59)        {return 0x0000000000000000000000000000000000000000;}// eos mainnet => EOS
        else if(chainId() == 60)        {return 0x0000000000000000000000000000000000000000;}// GoChain => GO
        else if(chainId() == 66)        {return 0x0000000000000000000000000000000000000000;}// OKExChain Mainnet => OKEx
        else if(chainId() == 70)        {return 0x0000000000000000000000000000000000000000;}// hoo => WHOO
        else if(chainId() == 78)        {return 0x0000000000000000000000000000000000000000;}// PrimusChain mainnet => 
        else if(chainId() == 80)        {return 0x0000000000000000000000000000000000000000;}// GeneChain => RNA
        else if(chainId() == 82)        {return 0x0000000000000000000000000000000000000000;}// Meter Mainnet => MTR
        else if(chainId() == 86)        {return 0x0000000000000000000000000000000000000000;}// GateChain Mainnet => GT
        else if(chainId() == 88)        {return 0x0000000000000000000000000000000000000000;}// TomoChain => TOMO
        else if(chainId() == 97)        {return 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;}// bsc testnet => TWBNB
        else if(chainId() == 100)       {return 0x0000000000000000000000000000000000000000;}// dai => xDAI
        else if(chainId() == 108)       {return 0x0000000000000000000000000000000000000000;}// ThunderCore Mainnet => TT
        else if(chainId() == 122)       {return 0x0000000000000000000000000000000000000000;}// Fuse Mainnet => FUSE
        else if(chainId() == 128)       {return 0x0000000000000000000000000000000000000000;}// huobi eco => WHT
        else if(chainId() == 137)       {return 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;}// poly => WMATIC   // quickswap router on polygon mainnet
        else if(chainId() == 250)       {return 0xF491e7B69E4244ad4002BC14e878a34207E38c29;}// fantom => WFTM
        else if(chainId() == 256)       {return 0x0000000000000000000000000000000000000000;}// heco test => HTT
        else if(chainId() == 269)       {return 0x0000000000000000000000000000000000000000;}// High Performance Blockchain => 
        else if(chainId() == 321)       {return 0xA58350d6dEE8441aa42754346860E3545cc83cdA;}// kcc => WKCS
        else if(chainId() == 322)       {return 0xc5f442007e08e3b13C9f95fA22F2a2B9369d7C8C;}// kcc => WKCS  testnet
        else if(chainId() == 1012)      {return 0x0000000000000000000000000000000000000000;}// Newton => NEW
        else if(chainId() == 1285)      {return 0x0000000000000000000000000000000000000000;}// Moonriver => MOVR
        else if(chainId() == 1287)      {return 0x0000000000000000000000000000000000000000;}// moonbase alpha => DEV
        else if(chainId() == 5197)      {return 0x0000000000000000000000000000000000000000;}// EraSwap Mainnet => OLO
        else if(chainId() == 8723)      {return 0x0000000000000000000000000000000000000000;}// TOOL Global Mainnet => OLO
        else if(chainId() == 10000)     {return 0x0000000000000000000000000000000000000000;}// Smart Bitcoin Cash => bch
        else if(chainId() == 39797)     {return 0x0000000000000000000000000000000000000000;}// Energi Mainnet => NRG
        else if(chainId() == 42220)     {return 0x0000000000000000000000000000000000000000;}// celo mainnet => CELO
        else if(chainId() == 42161)     {return 0x0000000000000000000000000000000000000000;}// Arbitrum One => AETH
        else if(chainId() == 43114)     {return 0x0000000000000000000000000000000000000000;}// avalanche => WAVAX
        else if(chainId() == 80001)     {return 0x0000000000000000000000000000000000000000;}// Matic polygon testnet Mumbai => tMATIC
        else if(chainId() == 311752642) {return 0x0000000000000000000000000000000000000000;}// OneLedger Mainnet => OLT
        // if we launch to another chain,we will have to manually update the address
        else {return 0x0000000000000000000000000000000000000000;}
    }

    
    // if someone sends us the native coin, just send it back.
    fallback() external payable { Address.sendValue(payable(msg.sender), msg.value);}
    receive() external payable { Address.sendValue(payable(msg.sender), msg.value);}
}