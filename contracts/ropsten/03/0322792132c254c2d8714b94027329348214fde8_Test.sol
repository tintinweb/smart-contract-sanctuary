/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

contract Test {
    address private owner;
    constructor (address _owner) {
        owner = _owner;
    }

    function whoOwnsMe() external view returns (address){
        return owner;
    }
}