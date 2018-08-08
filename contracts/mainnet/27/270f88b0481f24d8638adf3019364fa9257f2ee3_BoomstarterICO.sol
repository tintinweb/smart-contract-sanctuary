pragma solidity 0.4.23;

// File: minter-service/contracts/IICOInfo.sol

contract IICOInfo {
  function estimate(uint256 _wei) public constant returns (uint tokens);
  function purchasedTokenBalanceOf(address addr) public constant returns (uint256 tokens);
  function isSaleActive() public constant returns (bool active);
}

// File: minter-service/contracts/IMintableToken.sol

contract IMintableToken {
    function mint(address _to, uint256 _amount);
}

// File: contracts/oraclize/usingOraclize.sol

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// This api is currently targeted at 0.4.18, please import oraclizeAPI_pre0.4.sol or oraclizeAPI_0.4 where necessary
pragma solidity ^0.4.18;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
      return oraclize_setNetwork();
      networkID; // silence the warning and remain backwards compatible
    }
    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) public {
      return;
      myid; result; proof; // Silence compiler warnings
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }


    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
        // Convert from seconds to ledger timer ticks
        _delay *= 10; 
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly { 
            mstore(add(delay, 0x20), _delay) 
        }
        
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        
        bytes memory delay_bytes8_left = new bytes(8);
        
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }
        
        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }
    
    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = byte(1); //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;
        
        require(prefix.length == n_random_bytes);

        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;


        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

        // verify if sessionPubkeyHash was verified already, if not.. let&#39;s do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

        // Buffer too small
        require(to.length >= minLength); // Should be a better way?

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

}
// </ORACLIZE_API>

// File: mixbytes-solidity/contracts/ownership/multiowned.sol

// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

// Code taken from https://github.com/ethereum/dapp-bin/blob/master/wallet/wallet.sol
// Audit, refactoring and improvements by github.com/Eenae

// @authors:
// Gav Wood <<span class="__cf_email__" data-cfemail="197e597c6d717d7c6f377a7674">[email&#160;protected]</span>>
// inheritable "property" contract that enables methods to be protected by requiring the acquiescence of either a
// single, or, crucially, each of a number of, designated owners.
// usage:
// use modifiers onlyowner (just own owned) or onlymanyowners(hash), whereby the same hash must be provided by
// some number (specified in constructor) of the set of owners (specified in the constructor, modifiable) before the
// interior is executed.

pragma solidity ^0.4.15;


/// note: during any ownership changes all pending operations (waiting for more signatures) are cancelled
// TODO acceptOwnership
contract multiowned {

	// TYPES

    // struct for the status of a pending operation.
    struct MultiOwnedOperationPendingState {
        // count of confirmations needed
        uint yetNeeded;

        // bitmap of confirmations where owner #ownerIndex&#39;s decision corresponds to 2**ownerIndex bit
        uint ownersDone;

        // position of this operation key in m_multiOwnedPendingIndex
        uint index;
    }

	// EVENTS

    event Confirmation(address owner, bytes32 operation);
    event Revoke(address owner, bytes32 operation);
    event FinalConfirmation(address owner, bytes32 operation);

    // some others are in the case of an owner changing.
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerAdded(address newOwner);
    event OwnerRemoved(address oldOwner);

    // the last one is emitted if the required signatures change
    event RequirementChanged(uint newRequirement);

	// MODIFIERS

    // simple single-sig function modifier.
    modifier onlyowner {
        require(isOwner(msg.sender));
        _;
    }
    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations.
    modifier onlymanyowners(bytes32 _operation) {
        if (confirmAndCheck(_operation)) {
            _;
        }
        // Even if required number of confirmations has&#39;t been collected yet,
        // we can&#39;t throw here - because changes to the state have to be preserved.
        // But, confirmAndCheck itself will throw in case sender is not an owner.
    }

    modifier validNumOwners(uint _numOwners) {
        require(_numOwners > 0 && _numOwners <= c_maxOwners);
        _;
    }

    modifier multiOwnedValidRequirement(uint _required, uint _numOwners) {
        require(_required > 0 && _required <= _numOwners);
        _;
    }

    modifier ownerExists(address _address) {
        require(isOwner(_address));
        _;
    }

    modifier ownerDoesNotExist(address _address) {
        require(!isOwner(_address));
        _;
    }

    modifier multiOwnedOperationIsActive(bytes32 _operation) {
        require(isOperationActive(_operation));
        _;
    }

	// METHODS

    // constructor is given number of sigs required to do protected "onlymanyowners" transactions
    // as well as the selection of addresses capable of confirming them (msg.sender is not added to the owners!).
    function multiowned(address[] _owners, uint _required)
        public
        validNumOwners(_owners.length)
        multiOwnedValidRequirement(_required, _owners.length)
    {
        assert(c_maxOwners <= 255);

        m_numOwners = _owners.length;
        m_multiOwnedRequired = _required;

        for (uint i = 0; i < _owners.length; ++i)
        {
            address owner = _owners[i];
            // invalid and duplicate addresses are not allowed
            require(0 != owner && !isOwner(owner) /* not isOwner yet! */);

            uint currentOwnerIndex = checkOwnerIndex(i + 1 /* first slot is unused */);
            m_owners[currentOwnerIndex] = owner;
            m_ownerIndex[owner] = currentOwnerIndex;
        }

        assertOwnersAreConsistent();
    }

    /// @notice replaces an owner `_from` with another `_to`.
    /// @param _from address of owner to replace
    /// @param _to address of new owner
    // All pending operations will be canceled!
    function changeOwner(address _from, address _to)
        external
        ownerExists(_from)
        ownerDoesNotExist(_to)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_from]);
        m_owners[ownerIndex] = _to;
        m_ownerIndex[_from] = 0;
        m_ownerIndex[_to] = ownerIndex;

        assertOwnersAreConsistent();
        OwnerChanged(_from, _to);
    }

    /// @notice adds an owner
    /// @param _owner address of new owner
    // All pending operations will be canceled!
    function addOwner(address _owner)
        external
        ownerDoesNotExist(_owner)
        validNumOwners(m_numOwners + 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        m_numOwners++;
        m_owners[m_numOwners] = _owner;
        m_ownerIndex[_owner] = checkOwnerIndex(m_numOwners);

        assertOwnersAreConsistent();
        OwnerAdded(_owner);
    }

    /// @notice removes an owner
    /// @param _owner address of owner to remove
    // All pending operations will be canceled!
    function removeOwner(address _owner)
        external
        ownerExists(_owner)
        validNumOwners(m_numOwners - 1)
        multiOwnedValidRequirement(m_multiOwnedRequired, m_numOwners - 1)
        onlymanyowners(keccak256(msg.data))
    {
        assertOwnersAreConsistent();

        clearPending();
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[_owner]);
        m_owners[ownerIndex] = 0;
        m_ownerIndex[_owner] = 0;
        //make sure m_numOwners is equal to the number of owners and always points to the last owner
        reorganizeOwners();

        assertOwnersAreConsistent();
        OwnerRemoved(_owner);
    }

    /// @notice changes the required number of owner signatures
    /// @param _newRequired new number of signatures required
    // All pending operations will be canceled!
    function changeRequirement(uint _newRequired)
        external
        multiOwnedValidRequirement(_newRequired, m_numOwners)
        onlymanyowners(keccak256(msg.data))
    {
        m_multiOwnedRequired = _newRequired;
        clearPending();
        RequirementChanged(_newRequired);
    }

    /// @notice Gets an owner by 0-indexed position
    /// @param ownerIndex 0-indexed owner position
    function getOwner(uint ownerIndex) public constant returns (address) {
        return m_owners[ownerIndex + 1];
    }

    /// @notice Gets owners
    /// @return memory array of owners
    function getOwners() public constant returns (address[]) {
        address[] memory result = new address[](m_numOwners);
        for (uint i = 0; i < m_numOwners; i++)
            result[i] = getOwner(i);

        return result;
    }

    /// @notice checks if provided address is an owner address
    /// @param _addr address to check
    /// @return true if it&#39;s an owner
    function isOwner(address _addr) public constant returns (bool) {
        return m_ownerIndex[_addr] > 0;
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it&#39;s an owner
    // It&#39;s advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
    // addOwner/changeOwner and to isOwner.
    function amIOwner() external constant onlyowner returns (bool) {
        return true;
    }

    /// @notice Revokes a prior confirmation of the given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    function revoke(bytes32 _operation)
        external
        multiOwnedOperationIsActive(_operation)
        onlyowner
    {
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        var pending = m_multiOwnedPending[_operation];
        require(pending.ownersDone & ownerIndexBit > 0);

        assertOperationIsConsistent(_operation);

        pending.yetNeeded++;
        pending.ownersDone -= ownerIndexBit;

        assertOperationIsConsistent(_operation);
        Revoke(msg.sender, _operation);
    }

    /// @notice Checks if owner confirmed given operation
    /// @param _operation operation value, typically keccak256(msg.data)
    /// @param _owner an owner address
    function hasConfirmed(bytes32 _operation, address _owner)
        external
        constant
        multiOwnedOperationIsActive(_operation)
        ownerExists(_owner)
        returns (bool)
    {
        return !(m_multiOwnedPending[_operation].ownersDone & makeOwnerBitmapBit(_owner) == 0);
    }

    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation)
        private
        onlyowner
        returns (bool)
    {
        if (512 == m_multiOwnedPendingIndex.length)
            // In case m_multiOwnedPendingIndex grows too much we have to shrink it: otherwise at some point
            // we won&#39;t be able to do it because of block gas limit.
            // Yes, pending confirmations will be lost. Dont see any security or stability implications.
            // TODO use more graceful approach like compact or removal of clearPending completely
            clearPending();

        var pending = m_multiOwnedPending[_operation];

        // if we&#39;re not yet working on this operation, switch over and reset the confirmation status.
        if (! isOperationActive(_operation)) {
            // reset count of confirmations needed.
            pending.yetNeeded = m_multiOwnedRequired;
            // reset which owners have confirmed (none) - set our bitmap to 0.
            pending.ownersDone = 0;
            pending.index = m_multiOwnedPendingIndex.length++;
            m_multiOwnedPendingIndex[pending.index] = _operation;
            assertOperationIsConsistent(_operation);
        }

        // determine the bit to set for this owner.
        uint ownerIndexBit = makeOwnerBitmapBit(msg.sender);
        // make sure we (the message sender) haven&#39;t confirmed this operation previously.
        if (pending.ownersDone & ownerIndexBit == 0) {
            // ok - check if count is enough to go ahead.
            assert(pending.yetNeeded > 0);
            if (pending.yetNeeded == 1) {
                // enough confirmations: reset and run interior.
                delete m_multiOwnedPendingIndex[m_multiOwnedPending[_operation].index];
                delete m_multiOwnedPending[_operation];
                FinalConfirmation(msg.sender, _operation);
                return true;
            }
            else
            {
                // not enough: record that this owner in particular confirmed.
                pending.yetNeeded--;
                pending.ownersDone |= ownerIndexBit;
                assertOperationIsConsistent(_operation);
                Confirmation(msg.sender, _operation);
            }
        }
    }

    // Reclaims free slots between valid owners in m_owners.
    // TODO given that its called after each removal, it could be simplified.
    function reorganizeOwners() private {
        uint free = 1;
        while (free < m_numOwners)
        {
            // iterating to the first free slot from the beginning
            while (free < m_numOwners && m_owners[free] != 0) free++;

            // iterating to the first occupied slot from the end
            while (m_numOwners > 1 && m_owners[m_numOwners] == 0) m_numOwners--;

            // swap, if possible, so free slot is located at the end after the swap
            if (free < m_numOwners && m_owners[m_numOwners] != 0 && m_owners[free] == 0)
            {
                // owners between swapped slots should&#39;t be renumbered - that saves a lot of gas
                m_owners[free] = m_owners[m_numOwners];
                m_ownerIndex[m_owners[free]] = free;
                m_owners[m_numOwners] = 0;
            }
        }
    }

    function clearPending() private onlyowner {
        uint length = m_multiOwnedPendingIndex.length;
        // TODO block gas limit
        for (uint i = 0; i < length; ++i) {
            if (m_multiOwnedPendingIndex[i] != 0)
                delete m_multiOwnedPending[m_multiOwnedPendingIndex[i]];
        }
        delete m_multiOwnedPendingIndex;
    }

    function checkOwnerIndex(uint ownerIndex) private pure returns (uint) {
        assert(0 != ownerIndex && ownerIndex <= c_maxOwners);
        return ownerIndex;
    }

    function makeOwnerBitmapBit(address owner) private constant returns (uint) {
        uint ownerIndex = checkOwnerIndex(m_ownerIndex[owner]);
        return 2 ** ownerIndex;
    }

    function isOperationActive(bytes32 _operation) private constant returns (bool) {
        return 0 != m_multiOwnedPending[_operation].yetNeeded;
    }


    function assertOwnersAreConsistent() private constant {
        assert(m_numOwners > 0);
        assert(m_numOwners <= c_maxOwners);
        assert(m_owners[0] == 0);
        assert(0 != m_multiOwnedRequired && m_multiOwnedRequired <= m_numOwners);
    }

    function assertOperationIsConsistent(bytes32 _operation) private constant {
        var pending = m_multiOwnedPending[_operation];
        assert(0 != pending.yetNeeded);
        assert(m_multiOwnedPendingIndex[pending.index] == _operation);
        assert(pending.yetNeeded <= m_multiOwnedRequired);
    }


   	// FIELDS

    uint constant c_maxOwners = 250;

    // the number of owners that must confirm the same operation before it is run.
    uint public m_multiOwnedRequired;


    // pointer used to find a free slot in m_owners
    uint public m_numOwners;

    // list of owners (addresses),
    // slot 0 is unused so there are no owner which index is 0.
    // TODO could we save space at the end of the array for the common case of <10 owners? and should we?
    address[256] internal m_owners;

    // index on the list of owners to allow reverse lookup: owner address => index in m_owners
    mapping(address => uint) internal m_ownerIndex;


    // the ongoing operations.
    mapping(bytes32 => MultiOwnedOperationPendingState) internal m_multiOwnedPending;
    bytes32[] internal m_multiOwnedPendingIndex;
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/EthPriceDependent.sol

contract EthPriceDependent is usingOraclize, multiowned {

    using SafeMath for uint256;

    event NewOraclizeQuery(string description);
    event NewETHPrice(uint price);
    event ETHPriceOutOfBounds(uint price);

    /// @notice Constructor
    /// @param _initialOwners set owners, which can control bounds and things
    ///        described in the actual sale contract, inherited from this one
    /// @param _consensus Number of votes enough to make a decision
    /// @param _production True if on mainnet and testnet
    function EthPriceDependent(address[] _initialOwners,  uint _consensus, bool _production)
        public
        multiowned(_initialOwners, _consensus)
    {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        if (!_production) {
            // Use it when testing with testrpc and etherium bridge. Don&#39;t forget to change address
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        } else {
            // Don&#39;t call this while testing as it&#39;s too long and gets in the way
            updateETHPriceInCents();
        }
    }

    /// @notice Send oraclize query.
    /// if price is received successfully - update scheduled automatically,
    /// if at any point the contract runs out of ether - updating stops and further
    /// updating will require running this function again.
    /// if price is out of bounds - updating attempts continue
    function updateETHPriceInCents() public payable {
        // prohibit running multiple instances of update
        // however don&#39;t throw any error, because it&#39;s called from __callback as well
        // and we need to let it update the price anyway, otherwise there is an attack possibility
        if ( !updateRequestExpired() ) {
            NewOraclizeQuery("Oraclize request fail. Previous one still pending");
        } else if (oraclize_getPrice("URL") > this.balance) {
            NewOraclizeQuery("Oraclize request fail. Not enough ether");
        } else {
            oraclize_query(
                m_ETHPriceUpdateInterval,
                "URL",
                "json(https://api.coinmarketcap.com/v1/ticker/ethereum/?convert=USD).0.price_usd",
                m_callbackGas
            );
            m_ETHPriceLastUpdateRequest = getTime();
            NewOraclizeQuery("Oraclize query was sent");
        }
    }

    /// @notice Called on ETH price update by Oraclize
    function __callback(bytes32 myid, string result, bytes proof) public {
        require(msg.sender == oraclize_cbAddress());

        uint newPrice = parseInt(result).mul(100);

        if (newPrice >= m_ETHPriceLowerBound && newPrice <= m_ETHPriceUpperBound) {
            m_ETHPriceInCents = newPrice;
            m_ETHPriceLastUpdate = getTime();
            NewETHPrice(m_ETHPriceInCents);
        } else {
            ETHPriceOutOfBounds(newPrice);
        }
        // continue updating anyway (if current price was out of bounds, the price might recover in the next cycle)
        updateETHPriceInCents();
    }

    /// @notice set the limit of ETH in cents, oraclize data greater than this is not accepted
    /// @param _price Price in US cents
    function setETHPriceUpperBound(uint _price)
        external
        onlymanyowners(keccak256(msg.data))
    {
        m_ETHPriceUpperBound = _price;
    }

    /// @notice set the limit of ETH in cents, oraclize data smaller than this is not accepted
    /// @param _price Price in US cents
    function setETHPriceLowerBound(uint _price)
        external
        onlymanyowners(keccak256(msg.data))
    {
        m_ETHPriceLowerBound = _price;
    }

    /// @notice set the price of ETH in cents, called in case we don&#39;t get oraclize data
    ///         for more than double the update interval
    /// @param _price Price in US cents
    function setETHPriceManually(uint _price)
        external
        onlymanyowners(keccak256(msg.data))
    {
        // allow for owners to change the price anytime if update is not running
        // but if it is, then only in case the price has expired
        require( priceExpired() || updateRequestExpired() );
        m_ETHPriceInCents = _price;
        m_ETHPriceLastUpdate = getTime();
        NewETHPrice(m_ETHPriceInCents);
    }

    /// @notice add more ether to use in oraclize queries
    function topUp() external payable {
    }

    /// @dev change gas price for oraclize calls,
    ///      should be a compromise between speed and price according to market
    /// @param _gasPrice gas price in wei
    function setOraclizeGasPrice(uint _gasPrice)
        external
        onlymanyowners(keccak256(msg.data))
    {
        oraclize_setCustomGasPrice(_gasPrice);
    }

    /// @dev change gas limit for oraclize callback
    ///      note: should be changed only in case of emergency
    /// @param _callbackGas amount of gas
    function setOraclizeGasLimit(uint _callbackGas)
        external
        onlymanyowners(keccak256(msg.data))
    {
        m_callbackGas = _callbackGas;
    }

    /// @dev Check that double the update interval has passed
    ///      since last successful price update
    function priceExpired() public view returns (bool) {
        return (getTime() > m_ETHPriceLastUpdate + 2 * m_ETHPriceUpdateInterval);
    }

    /// @dev Check that price update was requested
    ///      more than 1 update interval ago
    ///      NOTE: m_leeway seconds added to offset possible timestamp inaccuracy
    function updateRequestExpired() public view returns (bool) {
        return ( (getTime() + m_leeway) >= (m_ETHPriceLastUpdateRequest + m_ETHPriceUpdateInterval) );
    }

    /// @dev to be overridden in tests
    function getTime() internal view returns (uint) {
        return now;
    }

    // FIELDS

    /// @notice usd price of ETH in cents, retrieved using oraclize
    uint public m_ETHPriceInCents = 0;
    /// @notice unix timestamp of last update
    uint public m_ETHPriceLastUpdate;
    /// @notice unix timestamp of last update request,
    ///         don&#39;t allow requesting more than once per update interval
    uint public m_ETHPriceLastUpdateRequest;

    /// @notice lower bound of the ETH price in cents
    uint public m_ETHPriceLowerBound = 100;
    /// @notice upper bound of the ETH price in cents
    uint public m_ETHPriceUpperBound = 100000000;

    /// @dev Update ETH price in cents every 12 hours
    uint public m_ETHPriceUpdateInterval = 60*60*1;

    /// @dev offset time inaccuracy when checking update expiration date
    uint public m_leeway = 900; // 15 minutes is the limit for miners

    /// @dev set just enough gas because the rest is not refunded
    uint public m_callbackGas = 200000;
}

// File: contracts/EthPriceDependentForICO.sol

contract EthPriceDependentForICO is EthPriceDependent {

    /// @dev overridden price lifetime logic
    function priceExpired() public view returns (bool) {
        return false;
    }

    /// @dev how long before price becomes invalid
    uint public m_ETHPriceLifetime = 60*60*12;
}

// File: contracts/IBoomstarterToken.sol

/// @title Interface of the BoomstarterToken.
interface IBoomstarterToken {
    // multiowned
    function changeOwner(address _from, address _to) external;
    function addOwner(address _owner) external;
    function removeOwner(address _owner) external;
    function changeRequirement(uint _newRequired) external;
    function getOwner(uint ownerIndex) public view returns (address);
    function getOwners() public view returns (address[]);
    function isOwner(address _addr) public view returns (bool);
    function amIOwner() external view returns (bool);
    function revoke(bytes32 _operation) external;
    function hasConfirmed(bytes32 _operation, address _owner) external view returns (bool);

    // ERC20Basic
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    // ERC20
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    // BurnableToken
    function burn(uint256 _amount) public returns (bool);

    // TokenWithApproveAndCallMethod
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public;

    // BoomstarterToken
    function setSale(address account, bool isSale) external;
    function switchToNextSale(address _newSale) external;
    function thaw() external;
    function disablePrivileged() external;

}

// File: mixbytes-solidity/contracts/ownership/MultiownedControlled.sol

// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.15;



/**
 * @title Contract which is owned by owners and operated by controller.
 *
 * @notice Provides a way to set up an entity (typically other contract) entitled to control actions of this contract.
 * Controller is set up by owners or during construction.
 *
 * @dev controller check is performed by onlyController modifier.
 */
contract MultiownedControlled is multiowned {

    event ControllerSet(address controller);
    event ControllerRetired(address was);
    event ControllerRetiredForever(address was);


    modifier onlyController {
        require(msg.sender == m_controller);
        _;
    }


    // PUBLIC interface

    function MultiownedControlled(address[] _owners, uint _signaturesRequired, address _controller)
        public
        multiowned(_owners, _signaturesRequired)
    {
        m_controller = _controller;
        ControllerSet(m_controller);
    }

    /// @dev sets the controller
    function setController(address _controller) external onlymanyowners(keccak256(msg.data)) {
        require(m_attaching_enabled);
        m_controller = _controller;
        ControllerSet(m_controller);
    }

    /// @dev ability for controller to step down
    function detachController() external onlyController {
        address was = m_controller;
        m_controller = address(0);
        ControllerRetired(was);
    }

    /// @dev ability for controller to step down and make this contract completely automatic (without third-party control)
    function detachControllerForever() external onlyController {
        assert(m_attaching_enabled);
        address was = m_controller;
        m_controller = address(0);
        m_attaching_enabled = false;
        ControllerRetiredForever(was);
    }


    // FIELDS

    /// @notice address of entity entitled to mint new tokens
    address public m_controller;

    bool public m_attaching_enabled = true;
}

// File: mixbytes-solidity/contracts/security/ArgumentsChecker.sol

// Copyright (C) 2017  MixBytes, LLC

// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).

pragma solidity ^0.4.15;


/// @title utility methods and modifiers of arguments validation
contract ArgumentsChecker {

    /// @dev check which prevents short address attack
    modifier payloadSizeIs(uint size) {
       require(msg.data.length == size + 4 /* function selector */);
       _;
    }

    /// @dev check that address is valid
    modifier validAddress(address addr) {
        require(addr != address(0));
        _;
    }
}

// File: zeppelin-solidity/contracts/ReentrancyGuard.sol

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="1b697e7678745b29">[email&#160;protected]</span>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }

}

// File: contracts/crowdsale/FundsRegistry.sol

/// @title registry of funds sent by investors
contract FundsRegistry is ArgumentsChecker, MultiownedControlled, ReentrancyGuard {
    using SafeMath for uint256;

    enum State {
        // gathering funds
        GATHERING,
        // returning funds to investors
        REFUNDING,
        // funds can be pulled by owners
        SUCCEEDED
    }

    event StateChanged(State _state);
    event Invested(address indexed investor, uint etherInvested, uint tokensReceived);
    event EtherSent(address indexed to, uint value);
    event RefundSent(address indexed to, uint value);


    modifier requiresState(State _state) {
        require(m_state == _state);
        _;
    }


    // PUBLIC interface

    function FundsRegistry(
        address[] _owners,
        uint _signaturesRequired,
        address _controller,
        address _token
    )
        MultiownedControlled(_owners, _signaturesRequired, _controller)
    {
        m_token = IBoomstarterToken(_token);
    }

    /// @dev performs only allowed state transitions
    function changeState(State _newState)
        external
        onlyController
    {
        assert(m_state != _newState);

        if (State.GATHERING == m_state) {   assert(State.REFUNDING == _newState || State.SUCCEEDED == _newState); }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);
    }

    /// @dev records an investment
    /// @param _investor who invested
    /// @param _tokenAmount the amount of token bought, calculation is handled by ICO
    function invested(address _investor, uint _tokenAmount)
        external
        payable
        onlyController
        requiresState(State.GATHERING)
    {
        uint256 amount = msg.value;
        require(0 != amount);
        assert(_investor != m_controller);

        // register investor
        if (0 == m_weiBalances[_investor])
            m_investors.push(_investor);

        // register payment
        totalInvested = totalInvested.add(amount);
        m_weiBalances[_investor] = m_weiBalances[_investor].add(amount);
        m_tokenBalances[_investor] = m_tokenBalances[_investor].add(_tokenAmount);

        Invested(_investor, amount, _tokenAmount);
    }

    /// @notice owners: send `value` of ether to address `to`, can be called if crowdsale succeeded
    /// @param to where to send ether
    /// @param value amount of wei to send
    function sendEther(address to, uint value)
        external
        validAddress(to)
        onlymanyowners(keccak256(msg.data))
        requiresState(State.SUCCEEDED)
    {
        require(value > 0 && this.balance >= value);
        to.transfer(value);
        EtherSent(to, value);
    }

    /// @notice owners: send `value` of tokens to address `to`, can be called if
    ///         crowdsale failed and some of the investors refunded the ether
    /// @param to where to send tokens
    /// @param value amount of token-wei to send
    function sendTokens(address to, uint value)
        external
        validAddress(to)
        onlymanyowners(keccak256(msg.data))
        requiresState(State.REFUNDING)
    {
        require(value > 0 && m_token.balanceOf(this) >= value);
        m_token.transfer(to, value);
    }

    /// @notice withdraw accumulated balance, called by payee in case crowdsale failed
    /// @dev caller should approve tokens bought during ICO to this contract
    function withdrawPayments()
        external
        nonReentrant
        requiresState(State.REFUNDING)
    {
        address payee = msg.sender;
        uint payment = m_weiBalances[payee];
        uint tokens = m_tokenBalances[payee];

        // check that there is some ether to withdraw
        require(payment != 0);
        // check that the contract holds enough ether
        require(this.balance >= payment);
        // check that the investor (payee) gives back all tokens bought during ICO
        require(m_token.allowance(payee, this) >= m_tokenBalances[payee]);

        totalInvested = totalInvested.sub(payment);
        m_weiBalances[payee] = 0;
        m_tokenBalances[payee] = 0;

        m_token.transferFrom(payee, this, tokens);

        payee.transfer(payment);
        RefundSent(payee, payment);
    }

    function getInvestorsCount() external constant returns (uint) { return m_investors.length; }

    // FIELDS

    /// @notice total amount of investments in wei
    uint256 public totalInvested;

    /// @notice state of the registry
    State public m_state = State.GATHERING;

    /// @dev balances of investors in wei
    mapping(address => uint256) public m_weiBalances;

    /// @dev balances of tokens sold to investors
    mapping(address => uint256) public m_tokenBalances;

    /// @dev list of unique investors
    address[] public m_investors;

    /// @dev token accepted for refunds
    IBoomstarterToken public m_token;
}

// File: contracts/BoomstarterICO.sol

/// @title Boomstarter ICO contract
contract BoomstarterICO is ArgumentsChecker, ReentrancyGuard, EthPriceDependentForICO, IICOInfo, IMintableToken {

    enum IcoState { INIT, ACTIVE, PAUSED, FAILED, SUCCEEDED }

    event StateChanged(IcoState _state);
    event FundTransfer(address backer, uint amount, bool isContribution);


    modifier requiresState(IcoState _state) {
        require(m_state == _state);
        _;
    }

    /// @dev triggers some state changes based on current time
    /// @param client optional refund parameter
    /// @param payment optional refund parameter
    /// @param refundable - if false, payment is made off-chain and shouldn&#39;t be refunded
    /// note: function body could be skipped!
    modifier timedStateChange(address client, uint payment, bool refundable) {
        if (IcoState.INIT == m_state && getTime() >= getStartTime())
            changeState(IcoState.ACTIVE);

        if (IcoState.ACTIVE == m_state && getTime() >= getFinishTime()) {
            finishICO();

            if (refundable && payment > 0)
                client.transfer(payment);
            // note that execution of further (but not preceding!) modifiers and functions ends here
        } else {
            _;
        }
    }

    /// @dev automatic check for unaccounted withdrawals
    /// @param client optional refund parameter
    /// @param payment optional refund parameter
    /// @param refundable - if false, payment is made off-chain and shouldn&#39;t be refunded
    modifier fundsChecker(address client, uint payment, bool refundable) {
        uint atTheBeginning = m_funds.balance;
        if (atTheBeginning < m_lastFundsAmount) {
            changeState(IcoState.PAUSED);
            if (refundable && payment > 0)
                client.transfer(payment);     // we cant throw (have to save state), so refunding this way
            // note that execution of further (but not preceding!) modifiers and functions ends here
        } else {
            _;

            if (m_funds.balance < atTheBeginning) {
                changeState(IcoState.PAUSED);
            } else {
                m_lastFundsAmount = m_funds.balance;
            }
        }
    }

    function estimate(uint256 _wei) public view returns (uint tokens) {
        uint amount;
        (amount, ) = estimateTokensWithActualPayment(_wei);
        return amount;
    }

    function isSaleActive() public view returns (bool active) {
        return m_state == IcoState.ACTIVE && !priceExpired();
    }

    function purchasedTokenBalanceOf(address addr) public view returns (uint256 tokens) {
        return m_token.balanceOf(addr);
    }

    function estimateTokensWithActualPayment(uint256 _payment) public view returns (uint amount, uint actualPayment) {
        // amount of bought tokens
        uint tokens = _payment.mul(m_ETHPriceInCents).div(getPrice());

        if (tokens.add(m_currentTokensSold) > c_maximumTokensSold) {
            tokens = c_maximumTokensSold.sub( m_currentTokensSold );
            _payment = getPrice().mul(tokens).div(m_ETHPriceInCents);
        }

        // calculating a 20% bonus if the price of bought tokens is more than $50k
        if (_payment.mul(m_ETHPriceInCents).div(1 ether) >= 5000000) {
            tokens = tokens.add(tokens.div(5));
            // for ICO, bonus cannot exceed hard cap
            if (tokens.add(m_currentTokensSold) > c_maximumTokensSold) {
                tokens = c_maximumTokensSold.sub(m_currentTokensSold);
            }
        }

        return (tokens, _payment);
    }


    // PUBLIC interface

    /**
     * @dev constructor
     * @param _owners addresses to do administrative actions
     * @param _token address of token being sold
     * @param _updateInterval time between oraclize price updates in seconds
     * @param _production false if using testrpc/ganache, true otherwise
     */
    function BoomstarterICO(
        address[] _owners,
        address _token,
        uint _updateInterval,
        bool _production
    )
        public
        payable
        EthPriceDependent(_owners, 2, _production)
        validAddress(_token)
    {
        require(3 == _owners.length);

        m_token = IBoomstarterToken(_token);
        m_deployer = msg.sender;
        m_ETHPriceUpdateInterval = _updateInterval;
        oraclize_setCustomGasPrice(40000000);
    }

    /// @dev set addresses for ether and token storage
    ///      performed once by deployer
    /// @param _funds FundsRegistry address
    /// @param _tokenDistributor address to send remaining tokens to after ICO
    /// @param _previouslySold how much sold in previous sales in cents
    function init(address _funds, address _tokenDistributor, uint _previouslySold)
        external
        validAddress(_funds)
        validAddress(_tokenDistributor)
        onlymanyowners(keccak256(msg.data))
    {
        // can be set only once
        require(m_funds == address(0));
        m_funds = FundsRegistry(_funds);

        // calculate remaining tokens and leave 25% for manual allocation
        c_maximumTokensSold = m_token.balanceOf(this).sub( m_token.totalSupply().div(4) );

        // manually set how much should be sold taking into account previously collected
        if (_previouslySold < c_softCapUsd)
            c_softCapUsd = c_softCapUsd.sub(_previouslySold);
        else
            c_softCapUsd = 0;

        // set account that allocates the rest of tokens after ico succeeds
        m_tokenDistributor = _tokenDistributor;
    }


    // PUBLIC interface: payments

    // fallback function as a shortcut
    function() payable {
        require(0 == msg.data.length);
        buy();  // only internal call here!
    }

    /// @notice ICO participation
    function buy() public payable {     // dont mark as external!
        internalBuy(msg.sender, msg.value, true);
    }

    function mint(address client, uint256 ethers) public {
        nonEtherBuy(client, ethers);
    }


    /// @notice register investments coming in different currencies
    /// @dev can only be called by a special controller account
    /// @param client Account to send tokens to
    /// @param etherEquivalentAmount Amount of ether to use to calculate token amount
    function nonEtherBuy(address client, uint etherEquivalentAmount)
        public
    {
        require(msg.sender == m_nonEtherController);
        // just to check for input errors
        require(etherEquivalentAmount <= 70000 ether);
        internalBuy(client, etherEquivalentAmount, false);
    }

    /// @dev common buy for ether and non-ether
    /// @param client who invests
    /// @param payment how much ether
    /// @param refundable true if invested in ether - using buy()
    function internalBuy(address client, uint payment, bool refundable)
        internal
        nonReentrant
        timedStateChange(client, payment, refundable)
        fundsChecker(client, payment, refundable)
    {
        // don&#39;t allow to buy anything if price change was too long ago
        // effectively enforcing a sale pause
        require( !priceExpired() );
        require(m_state == IcoState.ACTIVE || m_state == IcoState.INIT && isOwner(client) /* for final test */);

        require((payment.mul(m_ETHPriceInCents)).div(1 ether) >= c_MinInvestmentInCents);


        uint actualPayment = payment;
        uint amount;

        (amount, actualPayment) = estimateTokensWithActualPayment(payment);


        // change ICO investment stats
        m_currentUsdAccepted = m_currentUsdAccepted.add( actualPayment.mul(m_ETHPriceInCents).div(1 ether) );
        m_currentTokensSold = m_currentTokensSold.add( amount );

        // send bought tokens to the client
        m_token.transfer(client, amount);

        assert(m_currentTokensSold <= c_maximumTokensSold);

        if (refundable) {
            // record payment if paid in ether
            m_funds.invested.value(actualPayment)(client, amount);
            FundTransfer(client, actualPayment, true);
        }

        // check if ICO must be closed early
        if (payment.sub(actualPayment) > 0) {
            assert(c_maximumTokensSold == m_currentTokensSold);
            finishICO();

            // send change
            client.transfer(payment.sub(actualPayment));
        } else if (c_maximumTokensSold == m_currentTokensSold) {
            finishICO();
        }
    }


    // PUBLIC interface: misc getters

    /// @notice get token price in cents depending on the current date
    function getPrice() public view returns (uint) {
        // skip finish date, start from the date of maximum price
        for (uint i = c_priceChangeDates.length - 2; i > 0; i--) {
            if (getTime() >= c_priceChangeDates[i]) {
              return c_tokenPrices[i];
            }
        }
        // default price is the cheapest, used for the initial test as well
        return c_tokenPrices[0];
    }

    /// @notice start time of the ICO
    function getStartTime() public view returns (uint) {
        return c_priceChangeDates[0];
    }

    /// @notice finish time of the ICO
    function getFinishTime() public view returns (uint) {
        return c_priceChangeDates[c_priceChangeDates.length - 1];
    }


    // PUBLIC interface: owners: maintenance

    /// @notice pauses ICO
    function pause()
        external
        timedStateChange(address(0), 0, true)
        requiresState(IcoState.ACTIVE)
        onlyowner
    {
        changeState(IcoState.PAUSED);
    }

    /// @notice resume paused ICO
    function unpause()
        external
        timedStateChange(address(0), 0, true)
        requiresState(IcoState.PAUSED)
        onlymanyowners(keccak256(msg.data))
    {
        changeState(IcoState.ACTIVE);
        checkTime();
    }

    /// @notice withdraw tokens if ico failed
    /// @param _to address to send tokens to
    /// @param _amount amount of tokens in token-wei
    function withdrawTokens(address _to, uint _amount)
        external
        validAddress(_to)
        requiresState(IcoState.FAILED)
        onlymanyowners(keccak256(msg.data))
    {
        require((_amount > 0) && (m_token.balanceOf(this) >= _amount));
        m_token.transfer(_to, _amount);
    }

    /// @notice In case we need to attach to existent funds
    function setFundsRegistry(address _funds)
        external
        validAddress(_funds)
        timedStateChange(address(0), 0, true)
        requiresState(IcoState.PAUSED)
        onlymanyowners(keccak256(msg.data))
    {
        m_funds = FundsRegistry(_funds);
    }

    /// @notice set non ether investment controller
    function setNonEtherController(address _controller)
        external
        validAddress(_controller)
        timedStateChange(address(0), 0, true)
        onlymanyowners(keccak256(msg.data))
    {
        m_nonEtherController = _controller;
    }

    function getNonEtherController()
        public
        view
        returns (address)
    {
        return m_nonEtherController;
    }

    /// @notice explicit trigger for timed state changes
    function checkTime()
        public
        timedStateChange(address(0), 0, true)
        onlyowner
    {
    }

    /// @notice send everything to the new (fixed) ico smart contract
    /// @param newICO address of the new smart contract
    function applyHotFix(address newICO)
        public
        validAddress(newICO)
        requiresState(IcoState.PAUSED)
        onlymanyowners(keccak256(msg.data))
    {
        EthPriceDependent next = EthPriceDependent(newICO);
        next.topUp.value(this.balance)();
        m_token.transfer(newICO, m_token.balanceOf(this));
    }

    /// @notice withdraw all ether for oraclize payments
    /// @param to Address to send ether to
    function withdrawEther(address to)
        public
        validAddress(to)
        onlymanyowners(keccak256(msg.data))
    {
        to.transfer(this.balance);
    }


    // INTERNAL functions

    function finishICO() private {
        if (m_currentUsdAccepted < c_softCapUsd) {
            changeState(IcoState.FAILED);
        } else {
            changeState(IcoState.SUCCEEDED);
        }
    }

    /// @dev performs only allowed state transitions
    function changeState(IcoState _newState) private {
        assert(m_state != _newState);

        if (IcoState.INIT == m_state) {
            assert(IcoState.ACTIVE == _newState);
        } else if (IcoState.ACTIVE == m_state) {
            assert(
                IcoState.PAUSED == _newState ||
                IcoState.FAILED == _newState ||
                IcoState.SUCCEEDED == _newState
            );
        } else if (IcoState.PAUSED == m_state) {
            assert(IcoState.ACTIVE == _newState || IcoState.FAILED == _newState);
        } else {
            assert(false);
        }

        m_state = _newState;
        StateChanged(m_state);

        // this should be tightly linked
        if (IcoState.SUCCEEDED == m_state) {
            onSuccess();
        } else if (IcoState.FAILED == m_state) {
            onFailure();
        }
    }

    function onSuccess() private {
        // allow owners to withdraw collected ether
        m_funds.changeState(FundsRegistry.State.SUCCEEDED);
        m_funds.detachController();

        // send all remaining tokens to the address responsible for dividing them into pools
        m_token.transfer(m_tokenDistributor, m_token.balanceOf(this));
    }

    function onFailure() private {
        // allow clients to get their ether back
        m_funds.changeState(FundsRegistry.State.REFUNDING);
        m_funds.detachController();
    }


    // FIELDS

    /// @notice points in time when token price grows
    ///         first one is the start time of sale
    ///         last one is the end of sale
    uint[] public c_priceChangeDates = [
        getTime(),  // deployment date: $0.8
        1534107600, // August 13th 2018, 00:00:00 (GMT +3): $1
        1534712400, // August 20th 2018, 00:00:00 (GMT +3): $1.2
        1535317200, // August 27th 2018, 00:00:00 (GMT +3): $1.4
        1535922000, // September 3rd 2018, 00:00:00 (GMT +3): $1.6
        1536526800, // September 10th 2018, 00:00:00 (GMT +3): $1.8
        1537131600, // September 17th 2018, 00:00:00 (GMT +3): $2
        1538341199  // finish: September 30th 2018, 23:59:59 (GMT +3)
    ];

    /// @notice token prices in cents during different time periods
    ///         starts of the time periods described in c_priceChangeDates
    uint[] public c_tokenPrices = [
        80,  // $0.8
        100, // $1
        120, // $1.2
        140, // $1.4
        160, // $1.6
        180, // $1.8
        200  // $2
    ];

    /// @dev state of the ICO
    IcoState public m_state = IcoState.INIT;

    /// @dev contract responsible for token accounting
    IBoomstarterToken public m_token;

    /// @dev address responsile for allocation of the tokens left if ICO succeeds
    address public m_tokenDistributor;

    /// @dev contract responsible for investments accounting
    FundsRegistry public m_funds;

    /// @dev account handling investments in different currencies
    address public m_nonEtherController;

    /// @dev last recorded funds
    uint public m_lastFundsAmount;

    /// @notice minimum investment in cents
    uint public c_MinInvestmentInCents = 500; // $5

    /// @notice current amount of tokens sold
    uint public m_currentTokensSold;

    /// @dev limit of tokens to be sold during ICO, need to leave 25% for the team
    ///      calculated from the current balance and the total supply
    uint public c_maximumTokensSold;

    /// @dev current usd accepted during ICO, in cents
    uint public m_currentUsdAccepted;

    /// @dev limit of usd to be accepted during ICO, in cents
    uint public c_softCapUsd = 300000000; // $3000000

    /// @dev save deployer for easier initialization
    address public m_deployer;

}