/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity 0.6.10;

interface IERC20{
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Wallet {
    address owner;
    mapping (address => bool) verifiers;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyVerifier{
        require(verifiers[msg.sender]);
        _;
    }
    function addVerifier(address _address) external onlyOwner{
        verifiers[_address] = true;
    }
    
    function removeVerifier(address _address) external onlyOwner{
        verifiers[_address] = false;
    }
    
    function transferEth(uint256[] memory _amounts, address payable[] memory _addresses) onlyVerifier external{
        require(_amounts.length == _addresses.length);
        for(uint256 i=0; i< _addresses.length; i++){
            _addresses[i].transfer(_amounts[i]);
        }
    }
    
    function transferTokens(address _contract, uint256[] memory _amounts, address payable[] memory _addresses) onlyVerifier external{
        require(_amounts.length == _addresses.length);
        for(uint256 i=0; i< _addresses.length; i++){
            IERC20(_contract).transfer(_addresses[i], _amounts[i]);
        }
    }
    
    fallback() external payable{
        
    }
    
}