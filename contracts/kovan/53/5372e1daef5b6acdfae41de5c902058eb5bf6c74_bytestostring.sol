/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

contract bytestostring{
    bytes testword = new bytes(10);
    
    function setvalued() public {
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x0d);
    }
    function setvaluea() public {
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x68);
       testword.push(0x4d);
       testword.push(0x0a);
    }
    function pushSingle(bytes1 text1) external{
        testword.push(text1);
    }
    function showtransarr() public view returns(string memory){
        return string(testword);
    }
    function clear() external {
        testword = new bytes(10);
    }
}