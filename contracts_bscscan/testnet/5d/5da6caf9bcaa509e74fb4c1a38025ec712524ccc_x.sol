/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

contract x {
	mapping (uint => uint) public data;

	function write(uint _pos, uint _val) public {
		data[_pos] = _val;
	}
}