/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

/**
 * dev @gamer_noob_stream, especialista em contratos inteligentes e blockchain
 * 
*/

pragma solidity ^0.4.23;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}

	// Start drop
contract StreamAirdrop {
    address eth_address = 0xE21EaDEac1be4397dF954a08E24623CB37dECc4D;

    event transfer(address from, address to, uint amount,address tokenAddress);
    
    function transferBNB(address[] receivers, uint256[] amounts) public payable {
        for (uint256 i = 0; i < amounts.length; i++) {
            receivers[i].transfer(amounts[i]);
            emit transfer(msg.sender, receivers[i], amounts[i], eth_address);
        }
    }
    
    // Transfer multi ERC20 and BEP20 token
    function airdropStream(address tokenAddress, address[] receivers, uint256[] amounts) public {
        ERC20 token = ERC20(tokenAddress);
        for (uint i = 0; i < receivers.length; i++) {
            token.transferFrom(msg.sender,receivers[i], amounts[i]);
        
            emit transfer(msg.sender, receivers[i], amounts[i], tokenAddress);
        }
    }
    
    function getTotalSendingAmount(uint256[] _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            totalSendingAmount += _amounts[i];
        }
    }

	// Remove tokens preso no contrato
    function removeTokensFromContract(address _tokenAddr, address _to, uint _amount) public {
        ERC20(_tokenAddr).transfer(_to, _amount);
    }



}