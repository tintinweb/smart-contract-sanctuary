/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity =0.5.2;


interface IComptroller {
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);
}

contract MyTest{
    
    address public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant cdai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
     
    enum Error {
        NO_ERROR,
        ERROR
    }
    
    constructor () public {}
    
    function testCompEnterMarket() public {
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;
        uint[] memory results = IComptroller(comptroller).enterMarkets(ctokens);
        
        require(results[0] == uint(Error.NO_ERROR), "IComptroller: enterMarkets ERROR");
    }
    
    function testKeccak256() public view returns (bytes32){
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
}