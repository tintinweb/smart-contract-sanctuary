/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

pragma solidity >=0.6.0 <0.9.0;

contract HierarchyB{

    // uint64 public tax=10;
    // uint64 public linkCompanycent=90;
    // string public test;

    string[] public planBUser;
    uint256[] public planBposition;
    uint256 public planUserInt;
    // uint256 n1=0;
    uint256 numposition=0;

    // mapping(address => User) users;

    // struct User{
    //     string uName;
    //     uint256 uNum;
    //     uint256 position;
    // }

    function addHierarchy() public {

        planUserInt += 1;
        planBUser.push(string(bytes.concat(bytes("User"), "-", bytes(uint2str(planUserInt)))));
        planBposition.push(planUserInt);

        uint256 currentposition;

        // n1 += 1;
        numposition += 1;
        if (numposition > 2)
        {
            for (uint i = 0; i < planBposition.length; i++)
            {
                planBposition[i] -= 1;
                if(planBposition[i] == 0){
                    planBposition[i] = planUserInt;
                    
                }
            }
        }
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}