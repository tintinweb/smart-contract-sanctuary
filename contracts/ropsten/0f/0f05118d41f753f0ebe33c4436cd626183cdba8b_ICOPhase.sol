pragma solidity ^0.4.25;

contract ICOPhase {
    uint256 public phasePresale_From = 1522972800;//0h 06/04/2018 GMT
    uint256 public phasePresale_To = 1523577600;//0h 13/04/2018 GMT

    uint256 public phasePublicSale1_From = 1523577600;//0h 13/04/2018 GMT
    uint256 public phasePublicSale1_To = 1524182400;//0h 20/04/2018 GMT

    uint256 public phasePublicSale2_From = 1524182400;//0h 20/04/2018 GMT
    uint256 public phasePublicSale2_To = 1524787200;//0h 27/04/2018 GMT

    uint256 public phasePublicSale3_From = 1524787200;//0h 27/04/2018 GMT
    uint256 public phasePublicSale3_To = 1526774400;//0h 20/05/2018 GMT
}

contract SP8TokenSale is ICOPhase {
    address tokenAddress; // the token address
    address public ethFundDeposit = 0x589a0819824dE6486243Cfe4DE29230bD99F510f; //the address receive ether
    
    uint public decimals = 18;
    uint256 public tokenCreationCap; // max token in ico
	uint256 public preSaleTokenSold; // total token sold in ico pre sale
	uint256 public icoTokenSold; // total token sold in ico sale
	uint256 public investorCount = 0; // number of investor
	uint256 public tokenPreSale = 100000000 * 10**decimals;//max tokens for pre-sale
    uint256 public tokenPublicSale = 400000000 * 10**decimals;//max tokens for public-sale
    uint256 public minTokenCreationCap = 200000000 * 10**decimals;//max tokens for pre-sale
	string public version = "1.0"; // current version of contract
}