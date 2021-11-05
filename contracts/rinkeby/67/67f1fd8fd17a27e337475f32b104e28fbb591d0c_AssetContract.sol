/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity >=0.4.22 <0.6.0;

contract AssetContract {
    
    mapping(address => Asset[]) public tokens;
	struct Asset {
		address issuer;
		bytes32 securityRoot;
		uint256 quantity;
		uint256 mintBlock;
    }
    
    function mint(address _recipient, bytes32 _securityRoot) public payable {
        tokens[_recipient].push(
            Asset({
                issuer: msg.sender,
                securityRoot: _securityRoot,
                quantity: msg.value,
                mintBlock: block.number
            })
        );
    }
    
    function getNumberOfTokens(address _recipient) public view returns (uint) {
        return tokens[_recipient].length;
    }
    
    function transfer(address _recipient, uint256 _index) public {
        assert(tokens[msg.sender].length > _index);
        tokens[_recipient].push(tokens[msg.sender][_index]);
        burn(_index);
    }
    
    
    function burn(uint256 _index) public {
        assert(tokens[msg.sender].length > _index);
        for (uint i = _index; i < tokens[msg.sender].length - 1; i++){
            tokens[msg.sender][i] = tokens[msg.sender][i + 1];
        }
        tokens[msg.sender].length--;
    }
}