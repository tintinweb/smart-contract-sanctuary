contract Gastoken {
    function free(uint256 value) public returns (bool success);
    function freeUpTo(uint256 value) public returns (uint256 freed);
    function freeFrom(address from, uint256 value) public returns (bool success);
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);
    function approve(address spender, uint256 value) public returns (bool success);
}
contract Livepeer {
    function multiGenerate(address _merkleMineContract, address[] _recipients, bytes _merkleProofs) public;
}

contract MultiMerkleMineWithGasToken {

    /*
     * Frees `free&#39; tokens from the Gastoken at address `gas_token&#39;.
     * The freed tokens belong to this Example contract. The gas refund can pay
     * for up to half of the gas cost of the total transaction in which this 
     * call occurs.
     */
    function burnGasAndFree(address gas_token, uint256 free, address _merkleMineContract, address[] _recipients, bytes _merkleProofs) public {
        require(Gastoken(gas_token).free(free));
        Livepeer(0x182EBF4C80B28efc45AD992ecBb9f730e31e8c7F).multiGenerate(_merkleMineContract, _recipients, _merkleProofs);
    }

    /*
     * Frees `free&#39; tokens from the Gastoken at address `gas_token&#39;.
     * The freed tokens belong to the sender. The sender must have previously 
     * allowed this Example contract to free up to `free&#39; tokens on its behalf
     * (i.e., `allowance(msg.sender, this)&#39; should be at least `free&#39;).
     * The gas refund can pay for up to half of the gas cost of the total 
     * transaction in which this call occurs.
     */
    function burnGasAndFreeFrom(address gas_token, uint256 free, address _merkleMineContract, address[] _recipients, bytes _merkleProofs) public {
        Gastoken(gas_token).approve(this, free);
        require(Gastoken(gas_token).freeFrom(msg.sender, free));
        Livepeer(0x182EBF4C80B28efc45AD992ecBb9f730e31e8c7F).multiGenerate(_merkleMineContract, _recipients, _merkleProofs);
    }

}