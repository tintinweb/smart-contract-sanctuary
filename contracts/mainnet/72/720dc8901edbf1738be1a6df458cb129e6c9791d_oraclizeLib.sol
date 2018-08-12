// <ORACLIZE_API_LIB>
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

pragma solidity ^0.4.21;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public view returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public view returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external view returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() public view returns (address _addr);
}
library oraclizeLib {

    function proofType_NONE()
    public
    pure
    returns (byte) {
        return 0x00;
    }

    function proofType_TLSNotary()
    public
    pure
    returns (byte) {
        return 0x10;
    }

    function proofType_Android()
    public
    pure
    returns (byte) {
        return 0x20;
    }

    function proofType_Ledger()
    public
    pure
    returns (byte) {
        return 0x30;
    }

    function proofType_Native()
    public
    pure
    returns (byte) {
        return 0xF0;
    }

    function proofStorage_IPFS()
    public
    pure
    returns (byte) {
        return 0x01;
    }

    //OraclizeAddrResolverI constant public OAR = oraclize_setNetwork();

    function OAR()
    public
    view
    returns (OraclizeAddrResolverI) {
        return oraclize_setNetwork();
    }

    //OraclizeI constant public oraclize = OraclizeI(OAR.getAddress());

    function oraclize()
    public
    view
    returns (OraclizeI) {
        return OraclizeI(OAR().getAddress());
    }

    function oraclize_setNetwork()
    public
    view
    returns(OraclizeAddrResolverI){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            return OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            return OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            return OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            return OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            return OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            return OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            return OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
        }
    }

    function oraclize_getPrice(string datasource)
    public
    view
    returns (uint){
        return oraclize().getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit)
    public
    view
    returns (uint){
        return oraclize().getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oracle.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_query(string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oracle.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oracle.query2.value(price)(timestamp, datasource, arg1, arg2);
    }

    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oracle.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }

    // internalize w/o experimental
    function oraclize_query(string datasource, string[] argN)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN);
    }

    // internalize w/o experimental
    function oraclize_query(uint timestamp, string datasource, string[] argN)
    internal
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oracle.queryN.value(price)(timestamp, datasource, args);
    }

    // internalize w/o experimental
    function oraclize_query(string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN, gaslimit);
    }

    // internalize w/o experimental
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        OraclizeI oracle = oraclize();
        uint price = oracle.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oracle.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_cbAddress()
    public
    view
    returns (address){
        return oraclize().cbAddress();
    }

    function oraclize_setProof(byte proofP)
    public {
        return oraclize().setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(uint gasPrice)
    public {
        return oraclize().setCustomGasPrice(gasPrice);
    }

    // setting to internal doesn&#39;t cause major increase in deployment and saves gas
    // per use, for this tiny function
    function getCodeSize(address _addr)
    public
    view
    returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    // expects 0x prefix
    function parseAddr(string _a)
    public
    pure
    returns (address){
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

    function strCompare(string _a, string _b)
    public
    pure
    returns (int) {
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

    function indexOf(string _haystack, string _needle)
    public
    pure
    returns (int) {
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

    function strConcat(string _a, string _b, string _c, string _d, string _e)
    internal
    pure
    returns (string) {
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

    function strConcat(string _a, string _b, string _c, string _d)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b)
    internal
    pure
    returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a)
    public
    pure
    returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b)
    public
    pure
    returns (uint) {
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

    function uint2str(uint i)
    internal
    pure
    returns (string){
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

    function stra2cbor(string[] arr)
    internal
    pure
    returns (bytes) {
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
}
// </ORACLIZE_API_LIB>