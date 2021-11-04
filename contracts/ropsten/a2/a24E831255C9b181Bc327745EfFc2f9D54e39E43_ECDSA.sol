/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ECDSA {
    
    address[] public owners;

    function verify_array(address token, address eth_address, uint amount, bytes[] memory sig) public returns (bool) {
        bytes32 invoice = ethInvoceHash(token, eth_address, amount);
        bytes32 data_hash = ethMessageHash(invoice);
        bool result = false;
        uint confirm_count = 0;
        for (uint i=0; i<sig.length; i++){
            bool isOwner = false;
            for (uint j=0; j<owners.length; j++){
                if(recover(data_hash, sig[i]) == owners[j]){
                    isOwner = true;
                    break;
                }
            }
            if(!isOwner){
                confirm_count++;
                result = false;
                break;
            } else{
                result = true;
            }
        }
        if(result){
            result = IERC20(token).transferFrom(msg.sender, address(this), amount);
            require(result, "Token transfer failed");
        }
        return result;
    }


    function add_owner(address owner) public {
        owners.push(owner);
    }
    
    function owners_count() public view returns(uint) {
        return owners.length;
    }
    
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:" and hash the result
    */
    function ethMessageHash(bytes32 message) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32"  , message)
        );
    }
 
    function ethInvoceHash(address token, address _addr, uint amount) public pure  returns (bytes32)  {
        return keccak256(abi.encodePacked(token, _addr,  amount));
    }
}