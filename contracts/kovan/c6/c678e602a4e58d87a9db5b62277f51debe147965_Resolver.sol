/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Resolver {
    struct Details {
        string name;
        string symbol;
        uint8 decimals;
        bool isToken;
    }

    function isContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function getTokenDetails(address[] memory tknAddress) public view returns (Details[] memory) {
        Details[] memory details = new Details[](tknAddress.length);
        for (uint i = 0; i < tknAddress.length; i++) {
            string memory name = "";
            string memory symbol = "";
            uint8 decimals;
            bool isToken;
            if (isContract(tknAddress[i])) {
                (bool success_name, bytes memory returnData) = tknAddress[i].staticcall(abi.encodeWithSignature("name()"));
                if (success_name) {
                    name = abi.decode(returnData, (string));
                }
                (bool success_symbol, bytes memory returnData_) = tknAddress[i].staticcall(abi.encodeWithSignature("symbol()"));
                if (success_symbol) {
                    symbol = abi.decode(returnData_, (string));
                }
                (bool success_decimals, bytes memory returnData__) = tknAddress[i].staticcall(abi.encodeWithSignature("decimals()"));
                if (success_decimals) {
                    decimals = abi.decode(returnData__, (uint8));
                }
                isToken = success_name && success_symbol && success_decimals;
            }
            
            details[i] = Details(
                name,
                symbol,
                decimals,
                isToken
            );
        }
        
        return details;
    }
}