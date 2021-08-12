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
    function showtransarr() public view returns(string memory){
        return string(testword);
    }
}