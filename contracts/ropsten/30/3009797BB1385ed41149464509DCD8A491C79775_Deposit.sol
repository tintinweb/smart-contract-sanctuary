/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

interface IE25Token {
    function totalSupply() external view returns (uint256);
    function mint(address _to, uint256 _value) external returns (bool success);
}

contract Deposit 
{
    address vault;
    address ERC20_TOKEN_ADDRESS = address(0xb5D30C2b09B239480202C0C35FFfc1295bC4a6a8);
    
    function deposit() public payable {
        uint oldTokenSupply = getReceiptTokenTotalSupply(); //this will be denominated in the smallest denomination of the new ERC20 receipt token
        uint depositValue = msg.value;
        uint oldVaultValue = calculateValueOfVault();
        uint receiptTokensOwed = (oldTokenSupply * depositValue) / oldVaultValue; //ensure arithmetic is correct and that this holds up in testing to be the right amount
        mint(msg.sender, receiptTokensOwed);
    }
    
    function mint(address recipient, uint256 value) private {
        IE25Token(ERC20_TOKEN_ADDRESS).mint(recipient, value);
    }
    
    function calculateValueOfVault() private returns (uint256 currentValueOfVault) {
        return 10000 + getReceiptTokenTotalSupply() * 50;
    }
    
    function getReceiptTokenTotalSupply() private returns (uint256 totalSupply) {
        return IE25Token(ERC20_TOKEN_ADDRESS).totalSupply();
    }
}