pragma solidity ^0.4.20;


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

contract BetContract is usingOraclize {
  uint  maxProfit;
  uint  maxmoneypercent;
  uint public contractBalance;
  uint  oraclizeFee;
  uint  oraclizeGasLimit;
  uint minBet;
  uint onoff;
  address private owner;
  uint private orderId;

  event LogNewOraclizeQuery(string description,bytes32 queryId);
  event LogNewRandomNumber(string result,bytes32 queryId);
  event LogSendBonus(uint id,bytes32 lableId,uint playId,uint content,uint singleMoney,uint mutilple,address user,uint betTime,uint status,uint winMoney);

  mapping (address => bytes32[]) playerLableList;
  mapping (bytes32 => mapping (uint => uint[7])) betList;
  mapping (bytes32 => uint) lableCount;
  mapping (bytes32 => uint) lableTime;
  mapping (bytes32 => uint) lableStatus;
  mapping (bytes32 => uint[3]) openNumberList;
  mapping (bytes32 => string) openNumberStr;
  mapping (bytes32 => address) lableUser;

  function BetContract() public {
    owner = msg.sender;
    orderId = 0;

    onoff=1;
    minBet=1500000000000000;
    oraclizeFee=1200000000000000;
    maxmoneypercent=80;
    oraclizeGasLimit=200000;
    contractBalance = this.balance;
    maxProfit=(this.balance * maxmoneypercent)/100;
    oraclize_setCustomGasPrice(3000000000);
  }

  /*
    * uintToString
    */
   function uintToString(uint i) internal  returns (string){
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


  modifier onlyAdmin() {
      require(msg.sender == owner);
      _;
  }
  modifier onlyOraclize {
      require (msg.sender == oraclize_cbAddress());
      _;
  }

  function setGameOnoff(uint _on0ff) public onlyAdmin{
    onoff=_on0ff;
  }

  function getPlayRate(uint playId,uint level) internal pure returns (uint){
      uint result = 0;
      if(playId == 1 || playId == 2){
        
        result = 19;
      }else if(playId == 3){
        
        result = 11;
      }else if(playId == 4){
        
        result = 156;
      }else if(playId == 5){
        
        result = 26;
      }else if(playId == 6){
        
        if(level == 4 || level == 17){
          result = 53;
        }else if(level == 5 || level == 16){
          result = 21;
        }else if(level == 6 || level == 15){
          result = 17;
        }else if(level == 7 || level == 14){
          result = 13;
        }else if(level == 8 || level == 13){
          result = 9;
        }else if(level == 9 || level == 12){
          result = 8;
        }else if(level == 10 || level == 11){
          result = 7;
        }
      }else if(playId == 7){
       
        result = 6;
      }else if(playId == 8){
        
        if(level == 1){
          result = 19;
        }else if(level == 2){
          result = 28;
        }else if(level == 3){
          result = 37;
        }
      }
      return result;
    }

    function doBet(uint[] playid,uint[] betMoney,uint[] betContent,uint mutiply) public payable returns (bytes32) {
      require(onoff==1);
      require(playid.length > 0);
      require(mutiply > 0);
      require(msg.value >= minBet);

      /* checkBet(playid,betMoney,betContent,mutiply,msg.value); */

      /* uint total = 0; */
      bytes32 queryId;

        uint oraGasLimit = oraclizeGasLimit;
        if(playid.length > 1 && playid.length <= 3){
            oraGasLimit = 300000;
        }else if(playid.length > 3 && playid.length <= 5){
            oraGasLimit = 400000;
        }else if(playid.length > 5 && playid.length <= 10){
            oraGasLimit = 600000;
        }else if(playid.length > 10 && playid.length <= 15){
            oraGasLimit = 700000;
        }else if(playid.length > 15 && playid.length <= 20){
            oraGasLimit = 800000;
        }else{
            oraGasLimit = 1000000;
        }
        LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..",queryId);
        queryId = oraclize_query("URL", "json(https://api.random.org/json-rpc/1/invoke).result.random.data", &#39;\n{"jsonrpc":"2.0","method":"generateIntegers","params":{"apiKey":"8817de90-6e86-4d0d-87ec-3fd9b437f711","n":3,"min":1,"max":6,"replacement":true,"base":10},"id":1}&#39;,oraGasLimit);
      /* } */

       uint[7] tmp ;
      for(uint i=0;i<playid.length;i++){
        orderId++;
        tmp[0] =orderId;
        tmp[1] =playid[i];
        tmp[2] =betContent[i];
        tmp[3] =betMoney[i]*mutiply;
        tmp[4] =now;
        tmp[5] =0;
        tmp[6] =0;
        betList[queryId][i] =tmp;
      }
      lableTime[queryId] = now;
      lableCount[queryId] = playid.length;
      lableUser[queryId] = msg.sender;
      uint[3] memory codes = [uint(0),0,0];
      openNumberList[queryId] = codes;
      openNumberStr[queryId] ="0,0,0";
      lableStatus[queryId] = 0;

      uint index=playerLableList[msg.sender].length++;
      playerLableList[msg.sender][index]=queryId;//index:id

      return queryId;
    }

    function checkBet(uint[] playid,uint[] betMoney,uint[] betContent,uint mutiply,uint betTotal) internal{
        uint totalMoney = 0;
      uint totalWin1 = 0;
      uint totalWin2 = 0;
      uint totalWin3 = 0;
      uint rate;
      uint i;
      for(i=0;i<playid.length;i++){
        if(playid[i] >=1 && playid[i]<= 8){
          totalMoney += betMoney[i] * mutiply;
        }else{
          throw;
        }
        if(playid[i] ==1 || playid[i] ==2){
          rate = getPlayRate(playid[i],0)-10;
          totalWin1+=betMoney[i] * mutiply *rate/10;
          totalWin2+=betMoney[i] * mutiply *rate/10;
        }else if(playid[i] ==3){
          rate = getPlayRate(playid[i],0)-1;
          totalWin2+=betMoney[i] * mutiply *rate;
          totalWin3+=betMoney[i] * mutiply *rate;
        }else if(playid[i] ==4 || playid[i] ==5){
          rate = getPlayRate(playid[i],0)-1;
          totalWin3+=betMoney[i] * mutiply *rate;
        }else if(playid[i] ==6){
          rate = getPlayRate(playid[i],betContent[i])-1;
          totalWin1+=betMoney[i] * mutiply *rate;
          totalWin2+=betMoney[i] * mutiply *rate;
        }else if(playid[i] ==7){
          rate = getPlayRate(playid[i],0)-1;
          totalWin1+=betMoney[i] * mutiply *rate;
          totalWin2+=betMoney[i] * mutiply *rate;
        }else if(playid[i] ==8){
          totalWin1+=betMoney[i] * mutiply *9/10;
          totalWin2+=betMoney[i] * mutiply *18/10;
          totalWin3+=betMoney[i] * mutiply *27/10;
        }
      }
      uint maxWin=totalWin1;
      if(totalWin2 > maxWin){
        maxWin=totalWin2;
      }
      if(totalWin3 > maxWin){
        maxWin=totalWin3;
      }
      require(betTotal >= totalMoney);

      require(maxWin < maxProfit);
    }

    function __callback(bytes32 queryId, string result) public onlyOraclize {
        if (lableCount[queryId] < 1) revert();
      if (msg.sender != oraclize_cbAddress()) revert();
      LogNewRandomNumber(result,queryId);

        bytes memory tmp = bytes(result);
        uint[3] memory codes = [uint(0),0,0];

        uint k = 0;
        for (uint i=0; i<tmp.length; i++){
            if ((tmp[i] >= 48) && (tmp[i] <= 57)) {
                if(k < codes.length){
                    codes[k] = (uint(tmp[i]) - 48);
                    k++;
                }
            }
        }
        var code0=uintToString(codes[0]);
        var code1=uintToString(codes[1]);
        var code2=uintToString(codes[2]);
        openNumberList[queryId] = codes;
        openNumberStr[queryId] = strConcat(code0,",",code1,",",code2);

        
        doCheckBounds(queryId);
    }

    function doCancel(bytes32 queryId) internal {
      uint sta = lableStatus[queryId];
      require(sta == 0);
      uint[3] memory codes = openNumberList[queryId];
      require(codes[0] == 0 || codes[1] == 0 ||codes[2] == 0);

      uint totalBet = 0;
      uint len = lableCount[queryId];

      address to = lableUser[queryId];
      for(uint aa = 0 ; aa<len; aa++){
        
        if(betList[queryId][aa][5] == 0){
          totalBet+=betList[queryId][aa][3];
        }
      }

      if(totalBet > 0){
        to.transfer(totalBet);
      }
      contractBalance=this.balance;
      maxProfit=(this.balance * maxmoneypercent)/100;
      lableStatus[queryId] = 1;
    }

    function doSendBounds(bytes32 queryId) public payable {
      uint sta = lableStatus[queryId];
      require(sta == 2);

      uint totalWin = 0;
      uint len = lableCount[queryId];

      address to = lableUser[queryId];
      for(uint aa = 0 ; aa<len; aa++){
        
        if(betList[queryId][aa][5] == 2){
          totalWin+=betList[queryId][aa][6];
        }
      }

      if(totalWin > 0){
          to.transfer(totalWin);
      }
      lableStatus[queryId] = 3;
      contractBalance=this.balance;
      maxProfit=(this.balance * maxmoneypercent)/100;
    }

    
    function checkWinMoney(uint[7] storage betinfo,uint[3] codes) internal {
      uint rates;
      if(betinfo[1] ==1){
          
          if(codes[0] == codes[1] && codes[1] == codes[2]){
            betinfo[5]=1;
          }else{
            uint sum = codes[0]+codes[1]+codes[2];
            if(sum >= 4 && sum < 11){
              sum = 4;
            }else if(sum >= 11 && sum < 18){
              sum = 17;
            }else{
              sum = 0;
            }
            betinfo[5]=1;
            if(sum >0 && betinfo[2] == sum){
                betinfo[5]=2;
                rates = getPlayRate(betinfo[1],0);
                betinfo[6]=betinfo[3]*rates/10;
            }

          }
      }else if(betinfo[1] == 2){
          
          if(codes[0] == codes[1] && codes[1] == codes[2]){
            betinfo[5]=1;
          }else{
            uint sums = codes[0]+codes[1]+codes[2];
            if(sums % 2 == 0){
              sums = 2;
            }else{
              sums = 3;
            }
            betinfo[5]=1;
            if(sums == betinfo[2]){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates/10;
            }

          }

        }else if(betinfo[1] == 3){
          
          betinfo[5]=1;
          if(codes[0] == codes[1] || codes[1] == codes[2] ){
            uint tmp = 0;
            if(codes[0] == codes[1] ){
              tmp = codes[0];
            }else if(codes[1] == codes[2]){
              tmp = codes[1];
            }
            if(tmp == betinfo[2]){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates;
            }

          }
        }else if(betinfo[1] == 4){

          betinfo[5]=1;
          if(codes[0] == codes[1] && codes[1] == codes[2] ){
            if(codes[0] == betinfo[2]){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates;
            }
          }
        }else if(betinfo[1] == 5){

          betinfo[5]=1;
          if(codes[0] == codes[1] && codes[1] == codes[2] ){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates;
          }
        }else if(betinfo[1] == 6){

          if(codes[0] == codes[1] && codes[1] == codes[2]){
            betinfo[5]=1;
          }else{
            betinfo[5]=1;
            uint sum6 = codes[0]+codes[1]+codes[2];
            if(sum6 == betinfo[2]){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],sum6);
              betinfo[6]=betinfo[3]*rates;
            }
          }
        }else if(betinfo[1] == 7){

          if(codes[0] == codes[1] && codes[1] == codes[2]){
            betinfo[5]=1;
          }else{
            uint[2] memory haoma = getErbutongHao(betinfo[2]);
            bool atmp=false;
            bool btmp=false;
            for(uint ai=0;ai<codes.length;ai++){
              if(codes[ai] == haoma[0]){
                atmp = true;
                continue;
              }
              if(codes[ai] == haoma[1]){
                btmp = true;
                continue;
              }
            }
            betinfo[5]=1;
            if(atmp && btmp){
              betinfo[5]=2;
              rates = getPlayRate(betinfo[1],0);
              betinfo[6]=betinfo[3]*rates;
            }
          }
        }else if(betinfo[1] == 8){

          uint tmpp = 0;
          betinfo[5]=1;
          if(codes[0] == betinfo[2]){
            tmpp++;
          }
          if(codes[1] == betinfo[2]){
            tmpp++;
          }
          if(codes[2] == betinfo[2]){
            tmpp++;
          }
          if(tmpp > 0){
            betinfo[5]=2;
            rates = getPlayRate(betinfo[1],tmpp);
            betinfo[6]=betinfo[3]*rates/10;
          }
        }

    }

    function getErbutongHao(uint sss) internal view returns(uint[2]){
      uint[2] memory result ;
      if(sss == 12){
        result = [uint(1),2];
      }else if(sss == 13){
         result = [uint(1),3];
      }else if(sss == 14){
         result = [uint(1),4];
      }else if(sss == 15){
         result = [uint(1),5];
      }else if(sss == 16){
         result = [uint(1),6];
      }else if(sss == 23){
         result = [uint(2),3];
      }else if(sss == 24){
         result = [uint(2),4];
      }else if(sss == 25){
         result = [uint(2),5];
      }else if(sss == 26){
         result = [uint(2),6];
      }else if(sss == 34){
         result = [uint(3),4];
      }else if(sss == 35){
         result = [uint(3),5];
      }else if(sss == 36){
         result = [uint(3),6];
      }else if(sss == 45){
         result = [uint(4),5];
      }else if(sss == 46){
         result = [uint(4),6];
      }else if(sss == 56){
         result = [uint(5),6];
      }
      return (result);
    }

    function getLastBet() public view returns(string,uint[7][]){
      uint len=playerLableList[msg.sender].length;
      require(len>0);

      uint i=len-1;
      bytes32 lastLable = playerLableList[msg.sender][i];
      uint max = lableCount[lastLable];
      if(max > 50){
          max = 50;
      }
      uint[7][] memory result = new uint[7][](max) ;
      var opennum = "";
      for(uint a=0;a<max;a++){
         var ttmp =openNumberStr[lastLable];
         if(a==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }

         result[a] = betList[lastLable][a];
         if(lableStatus[lastLable] == 1){
           result[a][5]=3;
         }

      }

      return (opennum,result);
    }

    function getLableRecords(bytes32 lable) public view returns(string,uint[7][]){
      uint max = lableCount[lable];
      if(max > 50){
          max = 50;
      }
      uint[7][] memory result = new uint[7][](max) ;
      var opennum="";

      for(uint a=0;a<max;a++){
         result[a] = betList[lable][a];
         if(lableStatus[lable] == 1){
           result[a][5]=3;
         }
         var ttmp =openNumberStr[lable];
         if(a==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }
      }

      return (opennum,result);
    }

    function getAllRecords() public view returns(string,uint[7][]){
        uint len=playerLableList[msg.sender].length;
        require(len>0);

        uint max;
        bytes32 lastLable ;
        uint ss;

        for(uint i1=0;i1<len;i1++){
            ss = len-i1-1;
            lastLable = playerLableList[msg.sender][ss];
            max += lableCount[lastLable];
            if(100 < max){
              max = 100;
              break;
            }
        }

        uint[7][] memory result = new uint[7][](max) ;
        bytes32[] memory resultlable = new bytes32[](max) ;
        var opennum="";

        bool flag=false;
        uint betnums;
        uint j=0;

        for(uint ii=0;ii<len;ii++){
            ss = len-ii-1;
            lastLable = playerLableList[msg.sender][ss];
            betnums = lableCount[lastLable];
            for(uint k= 0; k<betnums; k++){
              if(j<max){
                  resultlable[j] = lastLable;
              	 var ttmp =openNumberStr[lastLable];
                 if(j==0){
                   opennum =ttmp;
                 }else{
                   opennum = strConcat(opennum,";",ttmp);
                 }
                  result[j] = betList[lastLable][k];
                  if(lableStatus[lastLable] == 1){
                    result[j][5]=3;
                  }else if(lableStatus[lastLable] == 2){
                    if(result[j][5]==2){
                      result[j][5]=4;
                    }
                  }else if(lableStatus[lastLable] == 3){
                    if(result[j][5]==2){
                      result[j][5]=5;
                    }
                  }
                  j++;
              }else{
                flag = true;
                break;
              }
            }
            if(flag){
                break;
            }
        }
        return (opennum,result);
    }

  function setoraclegasprice(uint newGas) public onlyAdmin(){
    oraclize_setCustomGasPrice(newGas * 1 wei);
  }
  function setoraclelimitgas(uint _oraclizeGasLimit) public onlyAdmin(){
    oraclizeGasLimit=(_oraclizeGasLimit);
  }

  function senttest() public payable onlyAdmin{
      contractBalance=this.balance;
      maxProfit=(this.balance*maxmoneypercent)/100;
  }

  function withdraw(uint _amount , address desaccount) public onlyAdmin{
      desaccount.transfer(_amount);
      contractBalance=this.balance;
      maxProfit=(this.balance * maxmoneypercent)/100;
  }

  function getDatas() public view returns(
    uint _maxProfit,
    uint _minBet,
    uint _contractbalance,
    uint _onoff,
    address _owner,
    uint _oraclizeFee
    ){
        _maxProfit=maxProfit;
        _minBet=minBet;
        _contractbalance=contractBalance;
        _onoff=onoff;
        _owner=owner;
        _oraclizeFee=oraclizeFee;
    }

    function getLableList() public view returns(string,bytes32[],uint[],uint[],uint){
      uint len=playerLableList[msg.sender].length;
      require(len>0);

      uint max=50;
      if(len < 50){
          max = len;
      }

      bytes32[] memory lablelist = new bytes32[](max) ;
      uint[] memory labletime = new uint[](max) ;
      uint[] memory lablestatus = new uint[](max) ;
      var opennum="";

      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          lablelist[i]=lastLable;
          labletime[i]=lableTime[lastLable];
          lablestatus[i]=lableStatus[lastLable];
          var ttmp =openNumberStr[lastLable];
         if(i==0){
           opennum =ttmp;
         }else{
           opennum = strConcat(opennum,";",ttmp);
         }
      }

      return (opennum,lablelist,labletime,lablestatus,now);
    }

    function doCheckBounds(bytes32 queryId) internal{
        uint sta = lableStatus[queryId];
        require(sta == 0 || sta == 2);
        uint[3] memory codes = openNumberList[queryId];
        require(codes[0] > 0);

        uint len = lableCount[queryId];

        uint totalWin;
        address to = lableUser[queryId];
        for(uint aa = 0 ; aa<len; aa++){

          if(sta == 0){
           if(betList[queryId][aa][5] == 0){
             checkWinMoney(betList[queryId][aa],codes);
             totalWin+=betList[queryId][aa][6];
           }
          }else if(sta == 2){
              totalWin+=betList[queryId][aa][6];
          }
        }

        lableStatus[queryId] = 2;

        if(totalWin > 0){
          if(totalWin < this.balance){
            to.transfer(totalWin);
            lableStatus[queryId] = 3;
          }else{
              LogNewOraclizeQuery("sent bouns fail.",queryId);
          }
        }else{
          lableStatus[queryId] = 3;
        }
        contractBalance=this.balance;
        maxProfit=(this.balance * maxmoneypercent)/100;
    }

    function getOpenNum(bytes32 queryId) public view returns(string){
        return openNumberStr[queryId];
    }

    function doCheckSendBounds() public payable{
        uint len=playerLableList[msg.sender].length;

      uint max=50;
      if(len < 50){
          max = len;
      }

      uint sta;
      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          sta = lableStatus[lastLable];
          if(sta == 0 || sta==2){
            doCheckBounds(lastLable);
          }
      }
    }

    function doCancelAll() public payable{
        uint len=playerLableList[msg.sender].length;

      uint max=50;
      if(len < 50){
          max = len;
      }

      uint sta;
      uint bettime;
      bytes32 lastLable ;
      for(uint i=0;i<max;i++){
          lastLable = playerLableList[msg.sender][max-i-1];
          sta = lableStatus[lastLable];
          bettime = lableTime[lastLable];
          if(sta == 0 && (now - bettime)>600){
            doCancel(lastLable);
          }
      }
    }

}