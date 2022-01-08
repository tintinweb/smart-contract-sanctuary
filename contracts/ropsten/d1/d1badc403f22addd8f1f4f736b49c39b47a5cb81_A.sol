/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

contract A {
    string private _name = "zzz";
    function name() public view returns (string memory) {
        return _name;
    }
}